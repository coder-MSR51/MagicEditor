import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_export_service.dart';
import '../services/admob_service.dart';
import '../theme/app_theme.dart';
import '../models/background_category_model.dart';

class BackgroundItem {
  final String id;
  final String title;
  final String category;
  final String? assetPath;
  final List<Color>? gradientColors;
  final String? patternType;

  const BackgroundItem({
    required this.id,
    required this.title,
    required this.category,
    this.assetPath,
    this.gradientColors,
    this.patternType,
  });
}

enum CutoutMaskMode {
  none,
  rounded,
  circle,
  heart,
  star,
  diamond,
  hexagon,
  octagon,
  oval,
  arch,
  shield,
  flower,
  softVignette,
  blendScreen,
}

class CutoutShapeItem {
  final CutoutMaskMode mode;
  final String label;
  final IconData icon;

  const CutoutShapeItem({
    required this.mode,
    required this.label,
    required this.icon,
  });
}


/// Interactive photo layer data model for multi-photo support
class ForegroundPhotoLayer {
  final String id;
  Uint8List bytes;
  Offset position;
  double scale;
  double rotation;
  double opacity;
  bool flipHorizontal;
  CutoutMaskMode maskMode;

  ForegroundPhotoLayer({
    required this.id,
    required this.bytes,
    this.position = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.flipHorizontal = false,
    this.maskMode = CutoutMaskMode.none,
  });
}

class BackgroundStudioScreen extends StatefulWidget {
  final List<Uint8List>? initialForegroundBytesList;
  final Uint8List? initialForegroundBytes;
  final String? initialCategoryName;
  final List<Color>? initialGradientColors;
  final Uint8List? customBackgroundBytes;
  final String? initialBackgroundAssetPath;
  final String? initialBackgroundTitle;

  const BackgroundStudioScreen({
    super.key,
    this.initialForegroundBytesList,
    this.initialForegroundBytes,
    this.initialCategoryName,
    this.initialGradientColors,
    this.customBackgroundBytes,
    this.initialBackgroundAssetPath,
    this.initialBackgroundTitle,
  });

  @override
  State<BackgroundStudioScreen> createState() => _BackgroundStudioScreenState();
}

class _BackgroundStudioScreenState extends State<BackgroundStudioScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();

  // Background state
  late BackgroundItem _selectedBackground;
  Uint8List? _customBackgroundBytes;

  // Multi-Photo Layers state (allows adding unlimited photos without removing previous ones)
  final List<ForegroundPhotoLayer> _photoLayers = [];
  int _selectedLayerIndex = 0;

  ForegroundPhotoLayer? get _activeLayer {
    if (_photoLayers.isEmpty) return null;
    if (_selectedLayerIndex < 0 || _selectedLayerIndex >= _photoLayers.length) {
      return _photoLayers.last;
    }
    return _photoLayers[_selectedLayerIndex];
  }

  // Selection Box visibility & Saving state
  bool _isSelected = true;
  bool _isSaving = false;

  // Canvas Framing Aspect Ratio (defaults to generous 3:4 for large, wide viewing area)
  double _canvasAspectRatio = 3 / 4;
  String _aspectRatioLabel = '3:4';

  void _toggleAspectRatio() {
    setState(() {
      if (_canvasAspectRatio == 3 / 4) {
        _canvasAspectRatio = 4 / 5;
        _aspectRatioLabel = '4:5';
      } else if (_canvasAspectRatio == 4 / 5) {
        _canvasAspectRatio = 1 / 1;
        _aspectRatioLabel = '1:1';
      } else if (_canvasAspectRatio == 1 / 1) {
        _canvasAspectRatio = 9 / 16;
        _aspectRatioLabel = '9:16';
      } else {
        _canvasAspectRatio = 3 / 4;
        _aspectRatioLabel = '3:4';
      }
    });
  }

  // Gesture tracking (Supports 2-finger zoom in/out & 360° smooth rotation)
  Offset? _dragStartOffset;
  Offset? _initialPositionOnDrag;
  double? _initialScaleOnPinch;
  double? _initialRotationOnPinch;
  // Available Cutout Shapes List (All 14 shapes individual items matching user request)
  static const List<CutoutShapeItem> _shapesList = [
    CutoutShapeItem(mode: CutoutMaskMode.none, label: 'Original', icon: Icons.crop_original_rounded),
    CutoutShapeItem(mode: CutoutMaskMode.rounded, label: 'Rounded', icon: Icons.rounded_corner_rounded),
    CutoutShapeItem(mode: CutoutMaskMode.circle, label: 'Circle', icon: Icons.circle_outlined),
    CutoutShapeItem(mode: CutoutMaskMode.heart, label: 'Heart', icon: Icons.favorite_rounded),
    CutoutShapeItem(mode: CutoutMaskMode.star, label: 'Star', icon: Icons.star_rounded),
    CutoutShapeItem(mode: CutoutMaskMode.diamond, label: 'Diamond', icon: Icons.diamond_rounded),
    CutoutShapeItem(mode: CutoutMaskMode.hexagon, label: 'Hexagon', icon: Icons.hexagon_outlined),
    CutoutShapeItem(mode: CutoutMaskMode.octagon, label: 'Octagon', icon: Icons.stop_rounded),
    CutoutShapeItem(mode: CutoutMaskMode.oval, label: 'Oval', icon: Icons.egg_outlined),
    CutoutShapeItem(mode: CutoutMaskMode.arch, label: 'Arch', icon: Icons.meeting_room_outlined),
    CutoutShapeItem(mode: CutoutMaskMode.shield, label: 'Shield', icon: Icons.shield_outlined),
    CutoutShapeItem(mode: CutoutMaskMode.flower, label: 'Flower', icon: Icons.local_florist_rounded),
    CutoutShapeItem(mode: CutoutMaskMode.softVignette, label: 'Vignette', icon: Icons.blur_on_rounded),
    CutoutShapeItem(mode: CutoutMaskMode.blendScreen, label: 'Blend', icon: Icons.filter_vintage_rounded),
  ];

  // Available Backgrounds Library - 5 Curated Categories with HD Wallpapers
  static final List<BackgroundItem> _allBackgrounds = [
    for (final wp in BackgroundCategoriesData.marvelWallpapers)
      BackgroundItem(
        id: wp.id,
        title: wp.title,
        category: 'Marvel',
        assetPath: wp.assetPath,
        gradientColors: wp.gradientColors,
      ),
    for (final wp in BackgroundCategoriesData.natureWallpapers)
      BackgroundItem(
        id: wp.id,
        title: wp.title,
        category: 'Nature & Landscapes',
        assetPath: wp.assetPath,
        gradientColors: wp.gradientColors,
      ),
    for (final wp in BackgroundCategoriesData.flowerWallpapers)
      BackgroundItem(
        id: wp.id,
        title: wp.title,
        category: 'Flowers',
        assetPath: wp.assetPath,
        gradientColors: wp.gradientColors,
      ),
    for (final wp in BackgroundCategoriesData.luxuryWallpapers)
      BackgroundItem(
        id: wp.id,
        title: wp.title,
        category: 'Luxury & Textures',
        assetPath: wp.assetPath,
        gradientColors: wp.gradientColors,
      ),
    for (final wp in BackgroundCategoriesData.loveWallpapers)
      BackgroundItem(
        id: wp.id,
        title: wp.title,
        category: 'Love & Romantic',
        assetPath: wp.assetPath,
        gradientColors: wp.gradientColors,
      ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.customBackgroundBytes != null) {
      _customBackgroundBytes = widget.customBackgroundBytes;
      _selectedBackground = const BackgroundItem(
        id: 'custom_initial',
        title: 'Custom Photo',
        category: 'Custom',
      );
    } else if (widget.initialBackgroundAssetPath != null) {
      _selectedBackground = BackgroundItem(
        id: 'initial_asset',
        title: widget.initialBackgroundTitle ?? 'Marvel Wallpaper',
        category: widget.initialCategoryName ?? 'Marvel',
        assetPath: widget.initialBackgroundAssetPath,
        gradientColors: widget.initialGradientColors,
      );
    } else if (widget.initialCategoryName != null && widget.initialGradientColors != null) {
      final categoryItems = _allBackgrounds.where((b) => b.category == widget.initialCategoryName).toList();
      if (categoryItems.isNotEmpty) {
        _selectedBackground = categoryItems[0];
      } else {
        _selectedBackground = BackgroundItem(
          id: 'cat_${widget.initialCategoryName}',
          title: widget.initialCategoryName!,
          category: widget.initialCategoryName!,
          gradientColors: widget.initialGradientColors!,
        );
      }
    } else {
      _selectedBackground = _allBackgrounds.isNotEmpty
          ? _allBackgrounds[0]
          : const BackgroundItem(
              id: 'marvel',
              title: 'Marvel',
              category: 'Marvel',
              gradientColors: [Color(0xFFE62429), Color(0xFF8B0000), Color(0xFF1E0203)],
            );
    }

    // Load initial foreground photos if provided
    if (widget.initialForegroundBytesList != null && widget.initialForegroundBytesList!.isNotEmpty) {
      for (int i = 0; i < widget.initialForegroundBytesList!.length; i++) {
        final bytes = widget.initialForegroundBytesList![i];
        final offsetStagger = i == 0 ? Offset.zero : Offset((i * 20.0) % 60, (i * 20.0) % 60);
        _photoLayers.add(
          ForegroundPhotoLayer(
            id: 'init_${DateTime.now().millisecondsSinceEpoch}_$i',
            bytes: bytes,
            position: offsetStagger,
            scale: 1.0,
            rotation: 0.0,
            opacity: 1.0,
          ),
        );
      }
      _selectedLayerIndex = _photoLayers.length - 1;
    } else if (widget.initialForegroundBytes != null) {
      _photoLayers.add(
        ForegroundPhotoLayer(
          id: 'init_single_${DateTime.now().millisecondsSinceEpoch}',
          bytes: widget.initialForegroundBytes!,
          position: Offset.zero,
          scale: 1.0,
          rotation: 0.0,
          opacity: 1.0,
        ),
      );
      _selectedLayerIndex = 0;
    }

    // If no initial photos, prompt user to select photos from gallery
    if (_photoLayers.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickForegroundPhotos(append: true);
      });
    }
  }

  /// Pick multiple or single photos from gallery.
  /// When append is true, does NOT remove previously added photos!
  Future<void> _pickForegroundPhotos({bool append = true}) async {
    try {
      AdMobService.instance.isPhotoPickerActive = true;
      List<XFile> pickedFiles = [];

      try {
        pickedFiles = await _picker.pickMultiImage(
          maxWidth: 3840,
          maxHeight: 3840,
          imageQuality: 100,
        );
      } catch (_) {
        // Fallback to single image pick if multi-pick is unsupported
        final single = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 3840,
          maxHeight: 3840,
          imageQuality: 100,
        );
        if (single != null) {
          pickedFiles = [single];
        }
      }

      if (pickedFiles.isNotEmpty) {
        final List<ForegroundPhotoLayer> newLayers = [];
        for (int i = 0; i < pickedFiles.length; i++) {
          final bytes = await pickedFiles[i].readAsBytes();
          // First/single photo is centered at Offset.zero, subsequent images stagger gently
          final offsetStagger = (_photoLayers.isEmpty && i == 0)
              ? Offset.zero
              : Offset(((_photoLayers.length + i) * 20.0) % 60, ((_photoLayers.length + i) * 20.0) % 60);
          newLayers.add(
            ForegroundPhotoLayer(
              id: 'layer_${DateTime.now().millisecondsSinceEpoch}_$i',
              bytes: bytes,
              position: offsetStagger,
              scale: 1.0,
              rotation: 0.0,
              opacity: 1.0,
            ),
          );
        }

        setState(() {
          if (!append) {
            _photoLayers.clear();
          }
          _photoLayers.addAll(newLayers);
          _selectedLayerIndex = _photoLayers.length - 1;
          _isSelected = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open image: $e')),
        );
      }
    } finally {
      AdMobService.instance.isPhotoPickerActive = false;
    }
  }

  Future<void> _pickCustomBackground() async {
    try {
      AdMobService.instance.isPhotoPickerActive = true;
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 3840,
        maxHeight: 3840,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _customBackgroundBytes = bytes;
          _selectedBackground = const BackgroundItem(
            id: 'custom_gallery',
            title: 'Custom Gallery',
            category: 'Custom',
          );
        });
      }
    } catch (_) {
    } finally {
      AdMobService.instance.isPhotoPickerActive = false;
    }
  }

  Future<void> _exportComposition() async {
    try {
      setState(() {
        _isSaving = true;
        _isSelected = false; // Hide bounding box during export!
      });

      await Future.delayed(const Duration(milliseconds: 120));

      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Canvas not ready');

      final exportedBytes = await ImageExportService.captureWidgetToBytes(boundary, pixelRatio: 3.0);
      if (exportedBytes == null) throw Exception('Failed to render image');

      final savedSuccess = await ImageExportService.saveToGallery(exportedBytes);
      if (!mounted) return;

      if (savedSuccess) {
        AdMobService.instance.showInterstitialAd();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saved to Gallery successfully! ✨',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSelected = true;
        });
      }
    }
  }

  void _showBackgroundSelectorSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141722),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        final categories = BackgroundCategoriesData.categories;

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        const Expanded(
                          child: Text(
                            'Background Categories',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primary, size: 24),
                          tooltip: 'Custom Background',
                          onPressed: () {
                            Navigator.pop(ctx);
                            _pickCustomBackground();
                          },
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white12, height: 1),

                  // 8 Clickable Categories (with Marvel Wallpapers gallery)
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, catIdx) {
                        final cat = categories[catIdx];
                        final isChosen = _selectedBackground.category == cat.title;
                        final wallpapers = BackgroundCategoriesData.getWallpapersForCategory(cat.id);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (wallpapers.isNotEmpty) {
                                  final firstWp = wallpapers.first;
                                  setState(() {
                                    _selectedBackground = BackgroundItem(
                                      id: firstWp.id,
                                      title: firstWp.title,
                                      category: cat.title,
                                      assetPath: firstWp.assetPath,
                                      gradientColors: firstWp.gradientColors,
                                    );
                                    _customBackgroundBytes = null;
                                  });
                                } else {
                                  setState(() {
                                    _selectedBackground = BackgroundItem(
                                      id: cat.id,
                                      title: cat.title,
                                      category: cat.title,
                                      gradientColors: cat.gradientColors,
                                    );
                                    _customBackgroundBytes = null;
                                  });
                                }
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFF1E2333),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    duration: const Duration(seconds: 2),
                                    content: Row(
                                      children: [
                                        Icon(cat.icon, color: cat.gradientColors.first, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            wallpapers.isNotEmpty
                                                ? '${cat.title} background applied! ⚡'
                                                : '${cat.title} category applied ✨ Wallpapers updating soon!',
                                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                height: 72,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cat.gradientColors.first.withValues(alpha: isChosen ? 0.45 : 0.22),
                                      const Color(0xFF161A26),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isChosen ? AppTheme.primary : cat.gradientColors.first.withValues(alpha: 0.3),
                                    width: isChosen ? 2.0 : 1.0,
                                  ),
                                  boxShadow: isChosen
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primary.withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: cat.gradientColors,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(cat.icon, color: Colors.white, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  cat.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14.5,
                                                    fontWeight: isChosen ? FontWeight.w800 : FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              if (cat.badge != null) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: cat.gradientColors.first,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    cat.badge!,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            cat.subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isChosen)
                                      const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20)
                                    else
                                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                                  ],
                                ),
                              ),
                            ),

                            // If category has wallpapers (Marvel), show horizontal wallpaper thumbnails
                            if (wallpapers.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 116,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: wallpapers.length,
                                  separatorBuilder: (context, idx) => const SizedBox(width: 10),
                                  itemBuilder: (context, wpIdx) {
                                    final wp = wallpapers[wpIdx];
                                    final isWpActive = _selectedBackground.id == wp.id || _selectedBackground.assetPath == wp.assetPath;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedBackground = BackgroundItem(
                                            id: wp.id,
                                            title: wp.title,
                                            category: cat.title,
                                            assetPath: wp.assetPath,
                                            gradientColors: wp.gradientColors,
                                          );
                                          _customBackgroundBytes = null;
                                        });
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).clearSnackBars();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: const Color(0xFF1E2333),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            duration: const Duration(seconds: 2),
                                            content: Row(
                                              children: [
                                                const Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 20),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    '${wp.title} wallpaper applied! ⚡',
                                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 86,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isWpActive ? AppTheme.primary : Colors.white24,
                                            width: isWpActive ? 2.5 : 1.0,
                                          ),
                                          boxShadow: isWpActive
                                              ? [
                                                  BoxShadow(
                                                    color: AppTheme.primary.withValues(alpha: 0.45),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.asset(
                                              wp.assetPath,
                                              fit: BoxFit.cover,
                                            ),
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.black.withValues(alpha: 0.85),
                                                    ],
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                  ),
                                                ),
                                                child: Text(
                                                  wp.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (isWpActive)
                                              Positioned(
                                                top: 6,
                                                right: 6,
                                                child: Container(
                                                  padding: const EdgeInsets.all(2.5),
                                                  decoration: const BoxDecoration(
                                                    color: AppTheme.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.check, size: 10, color: Colors.black),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }



  Widget _buildFallbackGradient(List<Color>? colors, [String? pattern]) {
    final grad = colors ?? [const Color(0xFF1E293B), const Color(0xFF0F172A)];
    IconData iconData = Icons.auto_awesome_rounded;
    if (pattern != null) {
      if (pattern == 'pool') {
        iconData = Icons.pool_rounded;
      } else if (pattern == 'palace' || pattern == 'archway') {
        iconData = Icons.account_balance_rounded;
      } else if (pattern == 'meadow' || pattern == 'hills') {
        iconData = Icons.landscape_rounded;
      } else if (pattern == 'blooms') {
        iconData = Icons.local_florist_rounded;
      } else if (pattern == 'clouds' || pattern == 'storm_cloud') {
        iconData = Icons.cloud_rounded;
      } else if (pattern == 'sunlit' || pattern == 'retro_sun') {
        iconData = Icons.wb_sunny_rounded;
      } else if (pattern == 'rain_leaves' || pattern == 'dew_drops') {
        iconData = Icons.water_drop_rounded;
      } else if (pattern == 'umbrellas') {
        iconData = Icons.beach_access_rounded;
      } else if (pattern == 'retro_glow' || pattern == 'retro_star') {
        iconData = Icons.star_rounded;
      } else if (pattern == 'retro_grid') {
        iconData = Icons.grid_view_rounded;
      } else if (pattern == 'bubble') {
        iconData = Icons.bubble_chart_rounded;
      } else if (pattern == 'silk' || pattern == 'glass') {
        iconData = Icons.texture_rounded;
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(
        child: Icon(
          iconData,
          color: Colors.white24,
          size: 26,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar matching Screenshot 1
            _buildTopActionBar(),

            // Stable Background + Movable Foreground Photo Canvas (Large area)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: AspectRatio(
                    aspectRatio: _canvasAspectRatio,
                    child: RepaintBoundary(
                      key: _repaintBoundaryKey,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isSelected = !_isSelected);
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.center,
                            children: [
                              // 1. Stable Fixed Background Layer
                              _buildStableBackgroundLayer(),

                              // 2. Interactive Movable Foreground Photo Layers
                              for (int i = 0; i < _photoLayers.length; i++)
                                _buildInteractiveLayer(i),

                              // Empty State Prompt if no photo yet
                              if (_photoLayers.isEmpty)
                                Center(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                                    label: const Text('Add Your Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                                    onPressed: () => _pickForegroundPhotos(append: true),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Tools & Opacity Slider matching Screenshot 1
            _buildBottomControlBar(),
          ],
        ),
      ),
    );
  }

  /// 1. Top Action Bar matching Screenshot 1 (Close, Undo, Redo, Eraser, Checkmark Save)
  Widget _buildTopActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
            onPressed: () => Navigator.pop(context),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Change Background Quick Pill
              GestureDetector(
                onTap: _showBackgroundSelectorSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wallpaper_rounded, color: AppTheme.primary, size: 15),
                      const SizedBox(width: 5),
                      Text(
                        _selectedBackground.title,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Canvas Aspect Ratio Switcher (3:4, 4:5, 1:1, 9:16)
              GestureDetector(
                onTap: _toggleAspectRatio,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.aspect_ratio_rounded, color: Colors.amberAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _aspectRatioLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Save / Done Checkmark Button
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                  tooltip: 'Save Image',
                  onPressed: _exportComposition,
                ),
        ],
      ),
    );
  }

  /// 2. Stable Fixed Background Layer (Always stays rock-solid behind)
  Widget _buildStableBackgroundLayer() {
    if (_customBackgroundBytes != null) {
      return Image.memory(
        _customBackgroundBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (_selectedBackground.assetPath != null) {
      return Image.asset(
        _selectedBackground.assetPath!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildFallbackGradient(_selectedBackground.gradientColors),
      );
    }

    return _buildFallbackGradient(_selectedBackground.gradientColors, _selectedBackground.patternType);
  }

  /// 3. Interactive Movable Foreground Photo Layer with Bounding Box
  Widget _buildInteractiveLayer(int layerIndex) {
    if (layerIndex >= _photoLayers.length) return const SizedBox.shrink();
    final layer = _photoLayers[layerIndex];
    final isLayerSelected = _isSelected && _selectedLayerIndex == layerIndex;

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
          final finalPos = center + layer.position;

          // Responsive prominent foreground sizing (Occupies ~74% of the canvas)
          final photoWidth = (constraints.maxWidth * 0.74).clamp(240.0, 360.0);
          final photoHeight = (constraints.maxHeight * 0.74).clamp(300.0, 480.0);
          final halfW = (photoWidth / 2) * layer.scale;
          final halfH = (photoHeight / 2) * layer.scale;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: finalPos.dx - halfW,
                top: finalPos.dy - halfH,
                child: GestureDetector(
                  onScaleStart: (details) {
                    _dragStartOffset = details.focalPoint;
                    _initialPositionOnDrag = layer.position;
                    _initialScaleOnPinch = layer.scale;
                    _initialRotationOnPinch = layer.rotation;
                    setState(() {
                      _selectedLayerIndex = layerIndex;
                      _isSelected = true;
                    });
                  },
                  onScaleUpdate: (details) {
                    if (_dragStartOffset == null) return;
                    final delta = details.focalPoint - _dragStartOffset!;

                    setState(() {
                      // Pan: Move image anywhere
                      layer.position = (_initialPositionOnDrag ?? Offset.zero) + delta;

                      // 2-Finger Zoom in / Zoom out
                      if (_initialScaleOnPinch != null) {
                        layer.scale = (_initialScaleOnPinch! * details.scale).clamp(0.15, 6.0);
                      }

                      // 2-Finger 360° Smooth Rotation
                      if (_initialRotationOnPinch != null) {
                        layer.rotation = _initialRotationOnPinch! + details.rotation;
                      }
                    });
                  },
                  onScaleEnd: (details) {
                    _dragStartOffset = null;
                    _initialPositionOnDrag = null;
                    _initialScaleOnPinch = null;
                    _initialRotationOnPinch = null;
                  },
                  child: Transform.rotate(
                    angle: layer.rotation,
                    child: Transform.flip(
                      flipX: layer.flipHorizontal,
                      child: Opacity(
                        opacity: layer.opacity.clamp(0.0, 1.0),
                        child: Container(
                          width: photoWidth * layer.scale,
                          height: photoHeight * layer.scale,
                          decoration: isLayerSelected
                              ? BoxDecoration(
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black38, blurRadius: 10),
                                  ],
                                )
                              : null,
                          child: Stack(
                            clipBehavior: Clip.none,
                            fit: StackFit.expand,
                            children: [
                              // Masked / Cropped foreground photo
                              _buildMaskedPhoto(layer),

                              // Bounding Box Controls matching Screenshot 1
                              if (isLayerSelected) ...[
                                // Top-Left: Close (X) button for this specific layer
                                Positioned(
                                  left: -12,
                                  top: -12,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _photoLayers.removeAt(layerIndex);
                                        if (_selectedLayerIndex >= _photoLayers.length) {
                                          _selectedLayerIndex = math.max(0, _photoLayers.length - 1);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black87,
                                        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)],
                                      ),
                                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),

                                // Top-Right rotate icon removed in favor of 2-finger 360° gesture

                                // Bottom-Right: Resize Handle
                                Positioned(
                                  right: -12,
                                  bottom: -12,
                                  child: GestureDetector(
                                    onPanUpdate: (d) {
                                      setState(() {
                                        layer.scale = (layer.scale + (d.delta.dx + d.delta.dy) * 0.005).clamp(0.25, 4.0);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black87,
                                        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)],
                                      ),
                                      child: const Icon(Icons.open_in_full_rounded, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),

                                // Corner & Edge White Dots matching Screenshot 1
                                Positioned(
                                  top: -4,
                                  left: halfW - 4,
                                  child: _buildHandleDot(),
                                ),
                                Positioned(
                                  bottom: -4,
                                  left: halfW - 4,
                                  child: _buildHandleDot(),
                                ),
                                Positioned(
                                  left: -4,
                                  top: halfH - 4,
                                  child: _buildHandleDot(),
                                ),
                                Positioned(
                                  right: -4,
                                  top: halfH - 4,
                                  child: _buildHandleDot(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildHandleDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black54, width: 1.0),
      ),
    );
  }

  Widget _buildMaskedPhoto(ForegroundPhotoLayer layer) {
    final imageWidget = Image.memory(
      layer.bytes,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );

    switch (layer.maskMode) {
      case CutoutMaskMode.none:
        return imageWidget;
      case CutoutMaskMode.rounded:
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: imageWidget,
        );
      case CutoutMaskMode.circle:
        return ClipOval(child: imageWidget);
      case CutoutMaskMode.heart:
        return ClipPath(
          clipper: HeartClipper(),
          child: imageWidget,
        );
      case CutoutMaskMode.star:
        return ClipPath(
          clipper: StarClipper(),
          child: imageWidget,
        );
      case CutoutMaskMode.diamond:
        return ClipPath(
          clipper: DiamondClipper(),
          child: imageWidget,
        );
      case CutoutMaskMode.hexagon:
        return ClipPath(
          clipper: HexagonClipper(),
          child: imageWidget,
        );
      case CutoutMaskMode.octagon:
        return ClipPath(
          clipper: OctagonClipper(),
          child: imageWidget,
        );
      case CutoutMaskMode.oval:
        return ClipOval(child: imageWidget);
      case CutoutMaskMode.arch:
        return ClipPath(
          clipper: ArchClipper(),
          child: imageWidget,
        );
      case CutoutMaskMode.shield:
        return ClipPath(
          clipper: ShieldClipper(),
          child: imageWidget,
        );
      case CutoutMaskMode.flower:
        return ClipPath(
          clipper: FlowerClipper(),
          child: imageWidget,
        );
      case CutoutMaskMode.softVignette:
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ShaderMask(
            shaderCallback: (bounds) {
              return RadialGradient(
                center: Alignment.center,
                radius: 0.85,
                colors: [Colors.black, Colors.black.withValues(alpha: 0.0)],
                stops: const [0.7, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: imageWidget,
          ),
        );
      case CutoutMaskMode.blendScreen:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.screen),
            child: imageWidget,
          ),
        );
    }
  }

  /// 4. Bottom Controls matching Screenshot 1 (Layer switcher + Opacity slider + Individual Shapes Strip + Tools row)
  Widget _buildBottomControlBar() {
    final active = _activeLayer;
    final activeOpacity = active?.opacity ?? 1.0;
    final activeMask = active?.maskMode ?? CutoutMaskMode.none;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F121A),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.8)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Multi-Photo Layer Switcher (Shown when multiple photos exist)
          if (_photoLayers.length > 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.layers_rounded, color: AppTheme.primary, size: 14),
                  const SizedBox(width: 6),
                  const Text(
                    'Selected Layer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_selectedLayerIndex + 1} of ${_photoLayers.length}',
                    style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _photoLayers.length,
                itemBuilder: (context, i) {
                  final isLayerActive = _selectedLayerIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedLayerIndex = i;
                      _isSelected = true;
                    }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLayerActive ? AppTheme.primary : Colors.white24,
                          width: isLayerActive ? 2.0 : 1.0,
                        ),
                        boxShadow: isLayerActive
                            ? [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(
                          _photoLayers[i].bytes,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Opacity Slider Bar matching Screenshot 1
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Opacity',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.5,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: activeOpacity,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (v) {
                        if (active != null) {
                          setState(() => active.opacity = v);
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${(activeOpacity * 100).toInt()}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Individual Shapes Strip (All shapes individually added as requested)
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.interests_rounded, color: AppTheme.primary, size: 14),
                const SizedBox(width: 6),
                const Text(
                  'Cutout Shapes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_shapesList.length} Shapes',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _shapesList.length,
              itemBuilder: (context, index) {
                final shape = _shapesList[index];
                final isSelected = activeMask == shape.mode;

                return GestureDetector(
                  onTap: () {
                    if (active != null) {
                      setState(() => active.maskMode = shape.mode);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withValues(alpha: 0.22) : const Color(0xFF191E2B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.white12,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          shape.icon,
                          color: isSelected ? AppTheme.primary : Colors.white70,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shape.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 6),

          // Tools Action Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                // 1. Add Photos (Appends without removing previous ones)
                _buildToolItem(
                  icon: Icons.add_photo_alternate_rounded,
                  label: 'Add Photos',
                  onTap: () => _pickForegroundPhotos(append: true),
                ),

                // 2. Choose Background
                _buildToolItem(
                  icon: Icons.wallpaper_rounded,
                  label: 'Background',
                  isActive: true,
                  onTap: _showBackgroundSelectorSheet,
                ),

                // 3. Flip Horizontal
                _buildToolItem(
                  icon: Icons.flip_rounded,
                  label: 'Flip',
                  onTap: () {
                    if (active != null) {
                      setState(() => active.flipHorizontal = !active.flipHorizontal);
                    }
                  },
                ),

                // 4. Rotate 90
                _buildToolItem(
                  icon: Icons.rotate_right_rounded,
                  label: 'Rotate 90°',
                  onTap: () {
                    if (active != null) {
                      setState(() => active.rotation += math.pi / 2);
                    }
                  },
                ),

                // 5. Reset Position & Scale (Center)
                _buildToolItem(
                  icon: Icons.center_focus_strong_rounded,
                  label: 'Center',
                  onTap: () {
                    if (active != null) {
                      setState(() {
                        active.position = Offset.zero;
                        active.scale = 1.0;
                        active.rotation = 0.0;
                      });
                    }
                  },
                ),

                // 6. Delete Active Photo
                if (_photoLayers.isNotEmpty)
                  _buildToolItem(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete Photo',
                    onTap: () {
                      setState(() {
                        _photoLayers.removeAt(_selectedLayerIndex);
                        if (_selectedLayerIndex >= _photoLayers.length) {
                          _selectedLayerIndex = math.max(0, _photoLayers.length - 1);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF0D9488) : const Color(0xFF1E2430),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? AppTheme.primary : Colors.white12,
                ),
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.white70,
                size: 22,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primary : Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Clippers for all Cutout Shapes
class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(width / 2, height * 0.85);
    path.cubicTo(
      width * 0.05, height * 0.55,
      0, height * 0.28,
      width * 0.25, height * 0.12,
    );
    path.cubicTo(
      width * 0.42, height * 0.02,
      width / 2, height * 0.22,
      width / 2, height * 0.22,
    );
    path.cubicTo(
      width / 2, height * 0.22,
      width * 0.58, height * 0.02,
      width * 0.75, height * 0.12,
    );
    path.cubicTo(
      width, height * 0.28,
      width * 0.95, height * 0.55,
      width / 2, height * 0.85,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class StarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerRadius = math.min(cx, cy);
    final innerRadius = outerRadius * 0.45;
    const points = 5;
    const step = math.pi / points;
    double angle = -math.pi / 2;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      angle += step;
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DiamondClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height / 2);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class OctagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final cutX = w * 0.29;
    final cutY = h * 0.29;

    path.moveTo(cutX, 0);
    path.lineTo(w - cutX, 0);
    path.lineTo(w, cutY);
    path.lineTo(w, h - cutY);
    path.lineTo(w - cutX, h);
    path.lineTo(cutX, h);
    path.lineTo(0, h - cutY);
    path.lineTo(0, cutY);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final radius = w / 2;

    path.moveTo(0, h);
    path.lineTo(0, radius);
    path.arcToPoint(
      Offset(w, radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(w, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ShieldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, 0);
    path.lineTo(w, 0);
    path.lineTo(w, h * 0.6);
    path.quadraticBezierTo(w * 0.85, h * 0.88, w * 0.5, h);
    path.quadraticBezierTo(w * 0.15, h * 0.88, 0, h * 0.6);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class FlowerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.min(cx, cy);
    const petals = 8;
    const totalPoints = 180;

    for (int i = 0; i <= totalPoints; i++) {
      final theta = (i / totalPoints) * 2 * math.pi;
      final r = maxR * (0.75 + 0.25 * math.cos(petals * theta));
      final x = cx + r * math.cos(theta);
      final y = cy + r * math.sin(theta);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
