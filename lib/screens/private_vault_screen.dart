import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/private_vault_service.dart';
import '../services/image_export_service.dart';
import '../widgets/vault_pin_dialog.dart';

class PrivateVaultScreen extends StatefulWidget {
  final bool autoOpenPickerOnStart;

  const PrivateVaultScreen({
    super.key,
    this.autoOpenPickerOnStart = false,
  });

  @override
  State<PrivateVaultScreen> createState() => _PrivateVaultScreenState();
}

class _PrivateVaultScreenState extends State<PrivateVaultScreen> {
  final ImagePicker _picker = ImagePicker();
  List<VaultPhoto> _photos = [];
  bool _isLoading = true;
  bool _isProcessingAction = false;
  String _processingMessage = '';

  // In-memory thumbnail cache to avoid re-reading disk unnecessarily
  final Map<String, Uint8List> _bytesCache = {};

  @override
  void initState() {
    super.initState();
    _loadPhotos();

    if (widget.autoOpenPickerOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickAndHidePhotos();
      });
    }
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    final photos = await PrivateVaultService.getPhotos();
    if (mounted) {
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    }
  }

  Future<Uint8List?> _getOrLoadBytes(VaultPhoto photo) async {
    if (_bytesCache.containsKey(photo.id)) {
      return _bytesCache[photo.id];
    }
    final bytes = await PrivateVaultService.getPhotoBytes(photo);
    if (bytes != null) {
      _bytesCache[photo.id] = bytes;
    }
    return bytes;
  }

  Future<void> _pickAndHidePhotos() async {
    try {
      List<VaultPhoto> added = [];
      final List<String> urisToDelete = [];
      final List<Map<String, dynamic>> fallbackItems = [];

      // 1. First attempt native gallery picker which preserves original MediaStore URIs
      final nativeItems = await PrivateVaultService.pickNativePhotos();
      if (nativeItems != null) {
        // Native picker was used
        if (nativeItems.isEmpty) {
          // User closed or cancelled gallery picker
          return;
        }

        setState(() {
          _isProcessingAction = true;
          _processingMessage = 'Securing ${nativeItems.length} photo(s) into private vault...';
        });

        added = await PrivateVaultService.hideNativePhotos(nativeItems);
        for (final item in nativeItems) {
          final uri = item['uri'] as String?;
          if (uri != null && uri.isNotEmpty) {
            urisToDelete.add(uri);
          }
          fallbackItems.add({
            'name': item['name'] ?? '',
            'size': item['size'] ?? 0,
          });
        }
      } else {
        // Fallback to ImagePicker only if native picker threw an exception (unsupported)
        final List<XFile> pickedFiles = await _picker.pickMultiImage();
        if (pickedFiles.isEmpty) return;

        setState(() {
          _isProcessingAction = true;
          _processingMessage = 'Securing ${pickedFiles.length} photo(s) into private vault...';
        });

        added = await PrivateVaultService.hidePhotos(pickedFiles);
        for (final f in pickedFiles) {
          fallbackItems.add({
            'name': f.name,
            'size': await f.length(),
            'path': f.path,
          });
        }
      }

      if (added.isEmpty) {
        if (mounted) setState(() => _isProcessingAction = false);
        return;
      }

      // 2. Request removing the original photo(s) from the system gallery
      setState(() {
        _processingMessage = 'Removing original photo(s) from gallery...';
      });

      final deletedFromGallery = await PrivateVaultService.deleteFromGallery(
        uris: urisToDelete,
        fallbackItems: fallbackItems,
      );

      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
        await _loadPhotos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1E2638),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF00F0FF), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      deletedFromGallery
                          ? '${added.length} photo(s) hidden in Vault & removed from Gallery! 🔒'
                          : '${added.length} photo(s) hidden in Vault! (Gallery delete skipped)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingAction = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to hide photos: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _movePhotoToGallery(VaultPhoto photo) async {
    setState(() {
      _isProcessingAction = true;
      _processingMessage = 'Moving photo to public gallery...';
    });

    final success = await PrivateVaultService.moveToGallery(photo);
    _bytesCache.remove(photo.id);

    if (mounted) {
      setState(() => _isProcessingAction = false);
      await _loadPhotos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF132D25),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF00FF88), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    success
                        ? 'Photo moved to Gallery successfully! 🎉'
                        : 'Could not move photo to gallery.',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _deletePhotoPermanently(VaultPhoto photo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161A26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Photo?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'This photo will be permanently deleted from the vault.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2A55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessingAction = true;
      _processingMessage = 'Deleting photo...';
    });

    await PrivateVaultService.deletePhoto(photo);
    _bytesCache.remove(photo.id);

    if (mounted) {
      setState(() => _isProcessingAction = false);
      await _loadPhotos();
    }
  }

  void _openPhotoDetail(VaultPhoto photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PrivatePhotoDetailScreen(
          photo: photo,
          getPhotoBytes: () => _getOrLoadBytes(photo),
          onMoveToGallery: () async {
            Navigator.pop(context);
            await _movePhotoToGallery(photo);
          },
          onDelete: () async {
            Navigator.pop(context);
            await _deletePhotoPermanently(photo);
          },
        ),
      ),
    );
  }

  void _showVaultMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131722),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF00F0FF)),
                title: const Text('Hide Photos from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Pick confidential photos to encrypt and hide', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndHidePhotos();
                },
              ),
              ListTile(
                leading: const Icon(Icons.pin_rounded, color: Color(0xFFFF8A00)),
                title: const Text('Change Security PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Update your 4-digit vault passcode', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final changed = await VaultPinDialog.show(context, mode: VaultPinMode.change);
                  if (changed == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Security PIN changed successfully! 🔐')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_rounded, color: Color(0xFFFF2A85)),
                title: const Text('Lock Vault Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Exit and secure with PIN immediately', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Pop back to home screen
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10141F),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFF00F0FF), size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private Vault',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_photos.length} hidden photo${_photos.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add Photos',
            icon: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF00F0FF)),
            onPressed: _pickAndHidePhotos,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
            onPressed: _showVaultMenu,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                )
              : _photos.isEmpty
                  ? _buildEmptyState()
                  : _buildPhotosGrid(),

          // Processing Action Overlay
          if (_isProcessingAction)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF00F0FF)),
                      const SizedBox(height: 16),
                      Text(
                        _processingMessage,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _photos.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF00F0FF),
              foregroundColor: Colors.black,
              elevation: 4,
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 22),
              label: const Text(
                'Hide Photos',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
              ),
              onPressed: _pickAndHidePhotos,
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00F0FF).withValues(alpha: 0.2),
                    const Color(0xFFFF2A85).withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Icon(Icons.lock_rounded, size: 48, color: Color(0xFF00F0FF)),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Vault is Empty',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Photos you hide here are encrypted and stored in a private secure directory away from public gallery apps.\n\nYou can move them back to gallery anytime!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white60,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
              ),
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 22),
              label: const Text(
                'Select Photos to Hide',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              onPressed: _pickAndHidePhotos,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosGrid() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Top Security Note Banner
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF131826),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF26334D)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded, color: Color(0xFF00F0FF), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap any photo to view full size or tap "Move to Gallery" to make it public again.',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Photos Grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final photo = _photos[index];
                return _buildPhotoTile(photo);
              },
              childCount: _photos.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoTile(VaultPhoto photo) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: const Color(0xFF181D2B),
        child: InkWell(
          onTap: () => _openPhotoDetail(photo),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo Thumbnail
              FutureBuilder<Uint8List?>(
                future: _getOrLoadBytes(photo),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    );
                  }
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00F0FF)),
                    ),
                  );
                },
              ),

              // Gradient Shade at Bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Quick "Move to Gallery" Action Pill
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _movePhotoToGallery(photo),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_rounded, color: Colors.black, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'To Gallery',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fullscreen photo viewer with pinch-to-zoom and direct "Move to Gallery" action
class _PrivatePhotoDetailScreen extends StatelessWidget {
  final VaultPhoto photo;
  final Future<Uint8List?> Function() getPhotoBytes;
  final VoidCallback onMoveToGallery;
  final VoidCallback onDelete;

  const _PrivatePhotoDetailScreen({
    required this.photo,
    required this.getPhotoBytes,
    required this.onMoveToGallery,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Private Photo',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${photo.dateAdded.day}/${photo.dateAdded.month}/${photo.dateAdded.year}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () async {
              final bytes = await getPhotoBytes();
              if (bytes != null) {
                await ImageExportService.shareImage(bytes);
              }
            },
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4D4D)),
            onPressed: onDelete,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<Uint8List?>(
        future: getPhotoBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF)));
          }
          final bytes = snapshot.data!;
          return Stack(
            children: [
              // Zoomable Image
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Bottom Sticky Action Bar: Direct "Move to Gallery" Button
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131724).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Direct "Move to Gallery" Primary Button
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F0FF),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.drive_file_move_rounded, size: 20),
                            label: const Text(
                              'Move to Gallery',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                            ),
                            onPressed: onMoveToGallery,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Quick Delete Icon Button
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFFF2A55).withValues(alpha: 0.18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: const Icon(Icons.delete_rounded, color: Color(0xFFFF4D4D), size: 22),
                          tooltip: 'Delete Permanently',
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
