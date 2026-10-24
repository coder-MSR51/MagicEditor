import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'image_export_service.dart';

/// Data model representing a photo securely hidden in the Private Vault
class VaultPhoto {
  final String id;
  final String fileName;
  final String? originalName;
  final String? originalUri;
  final DateTime dateAdded;
  final int sizeBytes;

  VaultPhoto({
    required this.id,
    required this.fileName,
    this.originalName,
    this.originalUri,
    required this.dateAdded,
    required this.sizeBytes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'originalName': originalName,
        'originalUri': originalUri,
        'dateAdded': dateAdded.toIso8601String(),
        'sizeBytes': sizeBytes,
      };

  factory VaultPhoto.fromJson(Map<String, dynamic> json) => VaultPhoto(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        originalName: json['originalName'] as String?,
        originalUri: json['originalUri'] as String?,
        dateAdded: DateTime.tryParse(json['dateAdded'] as String? ?? '') ?? DateTime.now(),
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      );
}

class PrivateVaultService {
  static const MethodChannel _channel = MethodChannel('com.photo.magic.editor/vault');

  static const String _vaultDirName = '.private_vault';
  static const String _manifestFileName = 'vault_manifest.json';
  static const String _securityFileName = 'vault_security.json';
  static const String _saltPrefix = 'PhotoMagic_VaultSalt_998_';

  /// Returns the hidden private directory for vault photos
  static Future<Directory> _getVaultDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/$_vaultDirName');
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
      // Create .nomedia file so Android Media Scanner ignores all photos in this folder
      final noMediaFile = File('${vaultDir.path}/.nomedia');
      if (!await noMediaFile.exists()) {
        await noMediaFile.writeAsString('');
      }
    }
    return vaultDir;
  }

  /// Hashes a PIN using SHA-256 with salt
  static String _hashPin(String pin) {
    final bytes = utf8.encode('$_saltPrefix$pin');
    return sha256.convert(bytes).toString();
  }

  /// Checks if the user has already configured a password / PIN
  static Future<bool> isPasswordSet() async {
    try {
      final vaultDir = await _getVaultDir();
      final securityFile = File('${vaultDir.path}/$_securityFileName');
      if (!await securityFile.exists()) return false;
      final content = await securityFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return (data['pinHash'] as String?)?.isNotEmpty ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sets or updates the vault password / PIN
  static Future<void> setPassword(String pin) async {
    final vaultDir = await _getVaultDir();
    final securityFile = File('${vaultDir.path}/$_securityFileName');
    final hash = _hashPin(pin);
    final data = {
      'pinHash': hash,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await securityFile.writeAsString(jsonEncode(data));
  }

  /// Verifies if the entered PIN matches the saved PIN
  static Future<bool> verifyPassword(String pin) async {
    try {
      final vaultDir = await _getVaultDir();
      final securityFile = File('${vaultDir.path}/$_securityFileName');
      if (!await securityFile.exists()) return false;
      final content = await securityFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final savedHash = data['pinHash'] as String?;
      return savedHash == _hashPin(pin);
    } catch (_) {
      return false;
    }
  }

  /// Reads all vault photos from manifest
  static Future<List<VaultPhoto>> getPhotos() async {
    try {
      final vaultDir = await _getVaultDir();
      final manifestFile = File('${vaultDir.path}/$_manifestFileName');
      if (!await manifestFile.exists()) return [];

      final content = await manifestFile.readAsString();
      final List<dynamic> list = jsonDecode(content) as List<dynamic>;
      final photos = list
          .map((item) => VaultPhoto.fromJson(item as Map<String, dynamic>))
          .toList();

      // Filter out any entries where file was accidentally missing
      final validPhotos = <VaultPhoto>[];
      for (final p in photos) {
        final f = File('${vaultDir.path}/${p.fileName}');
        if (await f.exists()) {
          validPhotos.add(p);
        }
      }

      // Sort newest first
      validPhotos.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      return validPhotos;
    } catch (_) {
      return [];
    }
  }

  /// Saves updated photos list to manifest
  static Future<void> _saveManifest(List<VaultPhoto> photos) async {
    final vaultDir = await _getVaultDir();
    final manifestFile = File('${vaultDir.path}/$_manifestFileName');
    final jsonList = photos.map((p) => p.toJson()).toList();
    await manifestFile.writeAsString(jsonEncode(jsonList));
  }

  /// Checks and requests media and storage permissions on device
  static Future<bool> checkAndRequestPermissions() async {
    try {
      final bool? res = await _channel.invokeMethod('checkAndRequestPermissions');
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Picks photos using native gallery which preserves original MediaStore URIs
  static Future<List<Map<String, dynamic>>?> pickNativePhotos() async {
    try {
      final List<dynamic>? res = await _channel.invokeMethod('pickPhotosForVault');
      if (res != null) {
        return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return null;
    }
  }

  /// Hides a list of native picked images into the private vault
  static Future<List<VaultPhoto>> hideNativePhotos(List<Map<String, dynamic>> nativeItems) async {
    final vaultDir = await _getVaultDir();
    final currentPhotos = await getPhotos();
    final newlyAdded = <VaultPhoto>[];

    for (int i = 0; i < nativeItems.length; i++) {
      final item = nativeItems[i];
      try {
        final tempPath = item['tempPath'] as String?;
        final originalUri = item['uri'] as String?;
        final originalName = item['name'] as String?;
        final sizeBytes = (item['size'] as num?)?.toInt() ?? 0;

        Uint8List? bytes;
        if (tempPath != null) {
          final tempFile = File(tempPath);
          if (await tempFile.exists()) {
            bytes = await tempFile.readAsBytes();
            try {
              await tempFile.delete();
            } catch (_) {}
          }
        }

        if (bytes == null || bytes.isEmpty) continue;

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final id = 'pv_${timestamp}_$i';
        final fileName = '$id.bin';
        final targetFile = File('${vaultDir.path}/$fileName');

        await targetFile.writeAsBytes(bytes);

        final newPhoto = VaultPhoto(
          id: id,
          fileName: fileName,
          originalName: originalName,
          originalUri: originalUri,
          dateAdded: DateTime.now(),
          sizeBytes: bytes.isNotEmpty ? bytes.length : sizeBytes,
        );

        newlyAdded.add(newPhoto);
        currentPhotos.insert(0, newPhoto);
      } catch (e) {
        // Continue with next photo if one fails
      }
    }

    await _saveManifest(currentPhotos);
    return newlyAdded;
  }

  /// Requests deleting the original photos from the system gallery
  static Future<bool> deleteFromGallery({
    required List<String> uris,
    List<Map<String, dynamic>> fallbackItems = const [],
  }) async {
    try {
      final bool? res = await _channel.invokeMethod('deleteFromGallery', {
        'uris': uris,
        'items': fallbackItems,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Hides a list of picked images into the private vault (fallback)
  static Future<List<VaultPhoto>> hidePhotos(List<XFile> files) async {
    final vaultDir = await _getVaultDir();
    final currentPhotos = await getPhotos();
    final newlyAdded = <VaultPhoto>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      try {
        final bytes = await file.readAsBytes();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final id = 'pv_${timestamp}_$i';
        final fileName = '$id.bin';
        final targetFile = File('${vaultDir.path}/$fileName');

        await targetFile.writeAsBytes(bytes);

        // Try deleting local file directly if accessible
        try {
          final sourceFile = File(file.path);
          if (await sourceFile.exists()) {
            await sourceFile.delete();
          }
        } catch (_) {}

        final newPhoto = VaultPhoto(
          id: id,
          fileName: fileName,
          originalName: file.name,
          dateAdded: DateTime.now(),
          sizeBytes: bytes.length,
        );

        newlyAdded.add(newPhoto);
        currentPhotos.insert(0, newPhoto);
      } catch (e) {
        // Continue with next photo if one fails
      }
    }

    await _saveManifest(currentPhotos);
    return newlyAdded;
  }

  /// Reads image bytes of a vault photo
  static Future<Uint8List?> getPhotoBytes(VaultPhoto photo) async {
    try {
      final vaultDir = await _getVaultDir();
      final file = File('${vaultDir.path}/${photo.fileName}');
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Moves a photo back to public device gallery and removes it from the private vault
  static Future<bool> moveToGallery(VaultPhoto photo) async {
    try {
      final bytes = await getPhotoBytes(photo);
      if (bytes == null) return false;

      // 1. Export back to user's public device gallery
      final saved = await ImageExportService.saveToGallery(bytes);
      if (!saved) return false;

      // 2. Remove file from vault
      final vaultDir = await _getVaultDir();
      final file = File('${vaultDir.path}/${photo.fileName}');
      if (await file.exists()) {
        await file.delete();
      }

      // 3. Remove from manifest
      final currentPhotos = await getPhotos();
      currentPhotos.removeWhere((p) => p.id == photo.id);
      await _saveManifest(currentPhotos);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Permanently deletes a photo from the vault
  static Future<bool> deletePhoto(VaultPhoto photo) async {
    try {
      final vaultDir = await _getVaultDir();
      final file = File('${vaultDir.path}/${photo.fileName}');
      if (await file.exists()) {
        await file.delete();
      }

      final currentPhotos = await getPhotos();
      currentPhotos.removeWhere((p) => p.id == photo.id);
      await _saveManifest(currentPhotos);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clears all photos from the vault
  static Future<void> clearAllPhotos() async {
    try {
      final vaultDir = await _getVaultDir();
      final currentPhotos = await getPhotos();
      for (final p in currentPhotos) {
        final f = File('${vaultDir.path}/${p.fileName}');
        if (await f.exists()) {
          await f.delete();
        }
      }
      await _saveManifest([]);
    } catch (_) {}
  }
}
