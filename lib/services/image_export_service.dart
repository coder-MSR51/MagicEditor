import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'analytics_service.dart';

class ImageExportService {
  /// Captures a RenderRepaintBoundary widget into PNG bytes
  static Future<Uint8List?> captureWidgetToBytes(RenderRepaintBoundary boundary, {double pixelRatio = 3.0}) async {
    try {
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('captureWidgetToBytes error: $e');
      return null;
    }
  }

  /// Saves image bytes to user's gallery under "Photo Magic" album
  static Future<bool> saveToGallery(Uint8List imageBytes) async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: false);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: false);
      }

      await Gal.putImageBytes(
        imageBytes,
        name: 'PhotoMagic_${DateTime.now().millisecondsSinceEpoch}',
      );
      AnalyticsService.instance.logPhotoSaved();
      return true;
    } catch (e) {
      debugPrint('Gal save failed, attempting storage fallback: $e');
      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.pictures);
        final baseDir = (extDirs != null && extDirs.isNotEmpty)
            ? extDirs.first
            : await getApplicationDocumentsDirectory();
        final filePath = '${baseDir.path}/PhotoMagic_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);
        AnalyticsService.instance.logPhotoSaved();
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  /// Shares the image via native share sheet with secure temporary URI permissions
  static Future<bool> shareImage(Uint8List imageBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/PhotoMagic_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      final xFile = XFile(file.path, mimeType: 'image/png');
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Edited with Photo Magic 🪄',
          subject: 'Photo Magic Edit',
        ),
      );
      AnalyticsService.instance.logPhotoShared();
      return result.status == ShareResultStatus.success;
    } catch (e) {
      return false;
    }
  }
}
