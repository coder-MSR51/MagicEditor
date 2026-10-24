import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_export_service.dart';
import '../services/admob_service.dart';
import '../theme/app_theme.dart';
import 'editor_screen.dart';

enum CollageType {
  grid,
  shape,
  template,
}

enum CollageLayout {
  // Aesthetic Modern Trending Templates
  filmStripVintage('35mm Filmstrip', 3, CollageType.template, Icons.movie_filter_rounded, 'Trending'),
  vogueMagazine('Vogue Editorial', 1, CollageType.template, Icons.auto_stories_rounded, 'Magazine'),
  retroVinylRecord('Vinyl Record', 1, CollageType.template, Icons.album_rounded, 'Trending'),
  aestheticMoodboard('Washi Moodboard', 3, CollageType.template, Icons.dashboard_customize_rounded, 'Autumn'),
  cyberpunkHud('Cyber Viewfinder', 1, CollageType.template, Icons.camera_enhance_rounded, 'AI Mix'),
  minimalistArch('Minimalist Arch', 2, CollageType.template, Icons.museum_rounded, 'Autumn'),
  musicPlayerCard('Music Card', 1, CollageType.template, Icons.music_note_rounded, 'Love'),
  cinemaLetterbox('Cinema Letterbox', 2, CollageType.template, Icons.slideshow_rounded, 'Magazine'),

  birthdayPolaroid('Birthday Polaroid', 1, CollageType.template, Icons.cake_rounded, 'Trending'),
  simsPlumbob('Sims Plumbob FX', 1, CollageType.template, Icons.diamond_rounded, 'AI Mix'),
  junCalendar('Jun Calendar Note', 1, CollageType.template, Icons.calendar_month_rounded, 'Autumn'),
  starScrapbook('Star Story Scrapbook', 2, CollageType.template, Icons.auto_awesome_rounded, 'Trending'),
  scallopedBows('Scalloped Bows', 1, CollageType.template, Icons.card_giftcard_rounded, 'Love'),
  seasonOfLight('2020 Season of Light', 1, CollageType.template, Icons.auto_stories_rounded, 'Magazine'),

  // Modern Trending Collage Templates (New)
  polaroidDuo('Polaroid Duo', 2, CollageType.template, Icons.filter_frames_rounded, 'Trending'),
  modernTriptych('Gallery Triptych', 3, CollageType.template, Icons.view_column_rounded, 'Magazine'),
  editorialMosaic('Editorial Mosaic', 4, CollageType.template, Icons.dashboard_rounded, 'Magazine'),
  diagonalSplit('Diagonal Split', 2, CollageType.template, Icons.call_split_rounded, 'AI Mix'),
  storyRoll35mm('Story Roll 35mm', 4, CollageType.template, Icons.movie_creation_rounded, 'Trending'),
  minimalist5('Minimalist 5', 5, CollageType.template, Icons.auto_awesome_mosaic_rounded, 'Trending'),

  // Multi-fit 10-photo layouts (User requested: multi fit main 10 image ka collage banane ka option)
  tenGrid('10-Photo 2x5 Grid', 10, CollageType.grid, Icons.grid_view_rounded, 'Multi-fit'),
  tenHeroCenter('10-Photo Hero Center', 10, CollageType.grid, Icons.dashboard_customize_rounded, 'Multi-fit'),
  tenHeroTop('10-Photo 2 Top + 8 Grid', 10, CollageType.grid, Icons.view_quilt_rounded, 'Multi-fit'),
  tenMasonry('10-Photo 3-4-3 Masonry', 10, CollageType.grid, Icons.view_comfy_rounded, 'Multi-fit'),

  // Classic Grids
  fourGrid('2x2 Grid', 4, CollageType.grid, Icons.grid_view_rounded, 'All'),
  twoVertical('2-Side Split', 2, CollageType.grid, Icons.view_column_rounded, 'All'),
  twoHorizontal('2-Stack Split', 2, CollageType.grid, Icons.view_stream_rounded, 'All'),
  threeHeroTop('1 Top + 2 Bottom', 3, CollageType.grid, Icons.table_rows_rounded, 'All'),
  threeHeroBottom('2 Top + 1 Bottom', 3, CollageType.grid, Icons.table_rows_outlined, 'All'),
  threeColumns('3 Columns', 3, CollageType.grid, Icons.view_week_rounded, 'All'),
  fourHeroLeft('Hero + 3 Right', 4, CollageType.grid, Icons.view_sidebar_rounded, 'All'),
  fourHeroTop('Hero + 3 Bottom', 4, CollageType.grid, Icons.subtitles_rounded, 'All'),
  sixGrid('2x3 Grid', 6, CollageType.grid, Icons.view_module_rounded, 'All');

  final String title;
  final int photoCount;
  final CollageType type;
  final IconData icon;
  final String category;

  const CollageLayout(this.title, this.photoCount, this.type, this.icon, [this.category = 'All']);
}

enum CollageBottomTab {
  shapes('Templates', Icons.auto_awesome_mosaic_rounded),
  layout('Layout', Icons.grid_on_rounded),
  ratio('Ratio', Icons.aspect_ratio_rounded),
  margin('Margin', Icons.tune_rounded),
  background('Background', Icons.color_lens_rounded);

  final String label;
  final IconData icon;
  const CollageBottomTab(this.label, this.icon);
}

class CollageScreen extends StatefulWidget {
  final List<Uint8List>? initialImages;
  final CollageLayout? initialLayout;
  final CollageBottomTab? initialTab;

  const CollageScreen({
    super.key,
    this.initialImages,
    this.initialLayout,
    this.initialTab,
  });

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();

  late CollageLayout _activeLayout;
  late CollageBottomTab _activeTab;
  final Map<int, Uint8List> _cellImages = {};
  int? _swapSourceIndex;

  DateTime _calendarNoteDate = DateTime(2026, 6, 15);
  int _seasonYear = 2020;

  static const List<String> _monthNamesShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // Track individually unlocked VIP templates for this editing session
  final Set<CollageLayout> _unlockedVipTemplates = {};

  bool _isVip(CollageLayout layout) {
    return layout == CollageLayout.filmStripVintage ||
        layout == CollageLayout.vogueMagazine ||
        layout == CollageLayout.retroVinylRecord ||
        layout == CollageLayout.cyberpunkHud ||
        layout == CollageLayout.musicPlayerCard ||
        layout == CollageLayout.cinemaLetterbox ||
        layout == CollageLayout.aestheticMoodboard ||
        layout == CollageLayout.junCalendar ||
        layout == CollageLayout.tenHeroCenter ||
        layout == CollageLayout.tenHeroTop ||
        layout == CollageLayout.twoVertical ||
        layout == CollageLayout.fourHeroLeft;
  }

  String _templateCategory = 'All';

  // Aspect ratio control
  double _aspectRatio = 1.0;
  String _aspectRatioLabel = '1:1';

  // Canvas adjustments
  double _outerMargin = 12.0;
  double _spacing = 8.0;
  final double _cornerRadius = 14.0;
  Color _backgroundColor = Colors.white;
  Gradient? _backgroundGradient;
  Uint8List? _backgroundImageBytes;
  double _backgroundBlur = 0.0;
  bool get _hasCustomBackground =>
      _backgroundImageBytes != null ||
      _backgroundGradient != null ||
      _backgroundColor != Colors.white;

  /// Whether current layout is a dedicated template or artistic shape
  bool get _isTemplate =>
      _activeLayout.type == CollageType.template ||
      _activeLayout.type == CollageType.shape;

  /// Dynamic bottom tabs: Ratio is completely disconnected from Templates
  List<CollageBottomTab> get _visibleTabs {
    if (_isTemplate) {
      // Templates preserve their dedicated authentic aspect ratio. Ratio is disconnected.
      return [
        CollageBottomTab.shapes,
        CollageBottomTab.layout,
        CollageBottomTab.background,
      ];
    } else {
      // Regular collage / grids: Layout, Ratio, Margin, Background, and Templates switcher
      return [
        CollageBottomTab.layout,
        CollageBottomTab.ratio,
        CollageBottomTab.margin,
        CollageBottomTab.background,
        CollageBottomTab.shapes,
      ];
    }
  }

  final bool _isLoading = false;
  bool _isExporting = false;

  // Manual image positioning & zoom controllers per cell
  final Map<int, TransformationController> _cellControllers = {};
  final Map<int, Size> _imageSizes = {};
  final Map<int, BoxFit> _cellFitModes = {};
  final Map<int, int> _cellRotations = {};
  final Map<int, bool> _cellFlips = {};

  TransformationController _getCellController(int index) {
    return _cellControllers.putIfAbsent(index, () => TransformationController());
  }

  BoxFit _getCellFitMode(int index) {
    return _cellFitModes[index] ??
        (_activeLayout.type == CollageType.template ? BoxFit.contain : BoxFit.cover);
  }

  void _cacheImageSize(int index, Uint8List bytes) {
    ui.instantiateImageCodec(bytes).then((codec) {
      codec.getNextFrame().then((frame) {
        if (mounted) {
          setState(() {
            _imageSizes[index] = Size(
              frame.image.width.toDouble(),
              frame.image.height.toDouble(),
            );
          });
        }
      });
    }).catchError((e) {
      debugPrint('[CollageScreen] Error decoding image size: $e');
    });
  }

  void _toggleCellFitMode(int index) {
    final currentMode = _getCellFitMode(index);
    final nextMode = currentMode == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
    setState(() {
      _cellFitModes[index] = nextMode;
      _cellControllers[index]?.value = Matrix4.identity();
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              nextMode == BoxFit.contain ? Icons.fit_screen_rounded : Icons.crop_free_rounded,
              color: const Color(0xFF00F0FF),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                nextMode == BoxFit.contain
                    ? 'Fit Mode: Entire photo fitted without cropping'
                    : 'Fill Mode: Photo fills the frame (Drag & pinch to adjust)',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E2638),
      ),
    );
  }

  void _rotateCellImage(int index) {
    setState(() {
      _cellRotations[index] = ((_cellRotations[index] ?? 0) + 1) % 4;
      _cellControllers[index]?.value = Matrix4.identity();
    });
  }

  void _flipCellImage(int index) {
    setState(() {
      _cellFlips[index] = !(_cellFlips[index] ?? false);
    });
  }

  void _resetCellTransform(int index) {
    setState(() {
      _cellControllers[index]?.value = Matrix4.identity();
      _cellRotations[index] = 0;
      _cellFlips[index] = false;
    });
  }

  @override
  void dispose() {
    for (final controller in _cellControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  final List<Color> _bgColors = [
    Colors.white,
    const Color(0xFFF3F4F6),
    const Color(0xFF18181B),
    Colors.black,
    const Color(0xFFFFF0F5),
    const Color(0xFFFFE4E6),
    const Color(0xFFFEF3C7),
    const Color(0xFFE0E7FF),
    const Color(0xFFF3E8FF),
    const Color(0xFFDCFCE7),
    const Color(0xFFCFFAFE),
    const Color(0xFFFFEDD5),
    const Color(0xFFFF2A85),
    const Color(0xFF8B5CF6),
    const Color(0xFF00F0FF),
    const Color(0xFF10B981),
  ];

  final List<Gradient> _bgGradients = [
    const LinearGradient(colors: [Color(0xFFFF9A9E), Color(0xFFFAD0C4)]),
    const LinearGradient(colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)]),
    const LinearGradient(colors: [Color(0xFF84FAB0), Color(0xFF8FD3F4)]),
    const LinearGradient(colors: [Color(0xFFFF512F), Color(0xFFDD2476)]),
    const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)]),
    const LinearGradient(colors: [Color(0xFF232526), Color(0xFF414345)]),
    const LinearGradient(colors: [Color(0xFFFA709A), Color(0xFFFEE140)]),
    const LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)]),
    const LinearGradient(colors: [Color(0xFF43E97B), Color(0xFF38F9D7)]),
    const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
  ];

  Future<void> _pickBackgroundImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 3840, maxHeight: 3840);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _backgroundImageBytes = bytes;
          _backgroundGradient = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Background photo applied! You can adjust blur below.'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick background image: $e')),
        );
      }
    }
  }

  void _useBlurredFirstPhotoAsBackground() {
    if (_cellImages.isNotEmpty) {
      final firstKey = _cellImages.keys.first;
      setState(() {
        _backgroundImageBytes = _cellImages[firstKey];
        _backgroundBlur = 12.0;
        _backgroundGradient = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('First photo applied as blurred background! ✨'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 photo first!'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  void _clearBackgroundImage() {
    setState(() {
      _backgroundImageBytes = null;
      _backgroundBlur = 0.0;
    });
  }

  void _openCustomColorPicker() {
    Color pickerColor = _backgroundColor;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pick Background Color', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (c) => pickerColor = c,
            paletteType: PaletteType.hsvWithHue,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() {
                _backgroundColor = pickerColor;
                _backgroundGradient = null;
                _backgroundImageBytes = null;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Select', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static CollageLayout getOptimalCollageLayout(
    int imageCount, {
    CollageLayout? preferredLayout,
    bool preferTemplate = false,
  }) {
    if (preferredLayout != null && preferredLayout.photoCount == imageCount) {
      return preferredLayout;
    }
    if (preferTemplate) {
      switch (imageCount) {
        case 1:
          return CollageLayout.vogueMagazine;
        case 2:
          return CollageLayout.cinemaLetterbox;
        case 3:
          return CollageLayout.filmStripVintage;
        case 5:
          return CollageLayout.sixGrid;
        default:
          break;
      }
    }
    switch (imageCount) {
      case 1:
        return CollageLayout.vogueMagazine;
      case 2:
        return CollageLayout.twoVertical;
      case 3:
        return CollageLayout.threeHeroTop;
      case 4:
        return CollageLayout.fourGrid;
      case 5:
        return CollageLayout.sixGrid;
      case 6:
        return CollageLayout.sixGrid;
      default:
        if (imageCount >= 7) {
          return CollageLayout.tenGrid;
        }
        return CollageLayout.fourGrid;
    }
  }

  @override
  void initState() {
    super.initState();
    final defaultLayout = (widget.initialTab == CollageBottomTab.shapes)
        ? CollageLayout.filmStripVintage
        : CollageLayout.fourGrid;

    CollageLayout candidateLayout;
    if (widget.initialImages != null && widget.initialImages!.isNotEmpty) {
      if (widget.initialLayout != null && widget.initialLayout!.photoCount == widget.initialImages!.length) {
        candidateLayout = widget.initialLayout!;
      } else {
        candidateLayout = getOptimalCollageLayout(
          widget.initialImages!.length,
          preferredLayout: widget.initialLayout,
          preferTemplate: widget.initialTab == CollageBottomTab.shapes,
        );
      }
    } else {
      candidateLayout = widget.initialLayout ?? defaultLayout;
    }

    _activeLayout = (_isVip(candidateLayout) && !_unlockedVipTemplates.contains(candidateLayout))
        ? defaultLayout
        : candidateLayout;
    _activeTab = widget.initialTab ??
        (_isTemplate ? CollageBottomTab.shapes : CollageBottomTab.layout);

    if (widget.initialImages != null && widget.initialImages!.isNotEmpty) {
      for (int i = 0; i < widget.initialImages!.length; i++) {
        _cellImages[i] = widget.initialImages![i];
        _cacheImageSize(i, widget.initialImages![i]);
      }
    }
  }

  Uint8List? _getImageForIndex(int index) => _cellImages[index];

  Future<void> _pickAdditionalImages() async {
    try {
      AdMobService.instance.isPhotoPickerActive = true;
      final files = await _picker.pickMultiImage(maxWidth: 3840, maxHeight: 3840);
      if (files.isNotEmpty) {
        final newImages = <Uint8List>[];
        for (final file in files) {
          newImages.add(await file.readAsBytes());
        }
        setState(() {
          if (_cellImages.isEmpty) {
            _activeLayout = getOptimalCollageLayout(newImages.length);
            for (int i = 0; i < newImages.length; i++) {
              if (i < _activeLayout.photoCount) {
                _cellImages[i] = newImages[i];
              }
            }
          } else {
            int imgIdx = 0;
            // 1. Fill empty slots first
            for (int i = 0; i < _activeLayout.photoCount && imgIdx < newImages.length; i++) {
              if (!_cellImages.containsKey(i)) {
                _cellImages[i] = newImages[imgIdx++];
              }
            }
            // 2. If user picked more photos, fill subsequent slots
            for (int i = 0; i < _activeLayout.photoCount && imgIdx < newImages.length; i++) {
              _cellImages[i] = newImages[imgIdx++];
            }
          }
        });
        for (final entry in _cellImages.entries) {
          if (!_imageSizes.containsKey(entry.key)) {
            _cacheImageSize(entry.key, entry.value);
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${newImages.length} photos! Hold & drag to swap positions.'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open photos: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      AdMobService.instance.isPhotoPickerActive = false;
    }
  }

  Future<void> _pickMultipleImagesStartingAt(int startingIndex) async {
    try {
      AdMobService.instance.isPhotoPickerActive = true;
      final files = await _picker.pickMultiImage(
        maxWidth: 3840,
        maxHeight: 3840,
        imageQuality: 100,
      );
      if (files.isNotEmpty) {
        final newImages = <Uint8List>[];
        for (final file in files) {
          newImages.add(await file.readAsBytes());
        }

        setState(() {
          int slot = startingIndex;
          for (final img in newImages) {
            if (slot < _activeLayout.photoCount) {
              _cellImages[slot] = img;
              slot++;
            } else {
              break;
            }
          }
        });
        for (final entry in _cellImages.entries) {
          if (!_imageSizes.containsKey(entry.key)) {
            _cacheImageSize(entry.key, entry.value);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Added ${newImages.length} photos! Long-press & drag to rearrange.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick photos: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      AdMobService.instance.isPhotoPickerActive = false;
    }
  }

  void _showUnlockVipDialog(CollageLayout layout) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB703).withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  'Unlock ${layout.title}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Watch a short video ad to unlock ${layout.title} for this session!\n(Each VIP template unlocks individually with its own ad)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.3),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 12),
                            Text('Preparing video ad...'),
                          ],
                        ),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Color(0xFF1E293B),
                      ),
                    );
                    AdMobService.instance.showRewardedAd(
                      onUserEarnedReward: (reward) {
                        if (!mounted) return;
                        setState(() {
                          _unlockedVipTemplates.add(layout);
                          _activeLayout = layout;
                        });
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 ${layout.title} unlocked!'),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onFailed: () {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Video ad could not be loaded. Please check your internet connection and try again.'),
                            backgroundColor: Color(0xFFE11D48),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.black),
                  label: const Text('Watch Video & Unlock (Free)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB703),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Maybe Later', style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _swapOrMoveCellImages(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    final fromImg = _cellImages[fromIndex];
    if (fromImg == null) return;

    setState(() {
      _swapSourceIndex = null;
      final toImg = _cellImages[toIndex];
      _cellImages[toIndex] = fromImg;
      if (toImg != null) {
        _cellImages[fromIndex] = toImg;
      } else {
        _cellImages.remove(fromIndex);
      }

      // Swap transformation matrix states so user's manual adjustments move with the photo
      final fromCtrl = _cellControllers[fromIndex];
      final toCtrl = _cellControllers[toIndex];
      if (fromCtrl != null && toCtrl != null) {
        final temp = Matrix4.copy(fromCtrl.value);
        fromCtrl.value = Matrix4.copy(toCtrl.value);
        toCtrl.value = temp;
      }

      // Swap sizing, fit modes, rotation, and flips
      final tempSize = _imageSizes[fromIndex];
      if (_imageSizes.containsKey(toIndex)) {
        _imageSizes[fromIndex] = _imageSizes[toIndex]!;
      } else {
        _imageSizes.remove(fromIndex);
      }
      if (tempSize != null) {
        _imageSizes[toIndex] = tempSize;
      } else {
        _imageSizes.remove(toIndex);
      }

      final tempFit = _cellFitModes[fromIndex];
      if (_cellFitModes.containsKey(toIndex)) {
        _cellFitModes[fromIndex] = _cellFitModes[toIndex]!;
      } else {
        _cellFitModes.remove(fromIndex);
      }
      if (tempFit != null) {
        _cellFitModes[toIndex] = tempFit;
      } else {
        _cellFitModes.remove(toIndex);
      }

      final tempRot = _cellRotations[fromIndex];
      if (_cellRotations.containsKey(toIndex)) {
        _cellRotations[fromIndex] = _cellRotations[toIndex]!;
      } else {
        _cellRotations.remove(fromIndex);
      }
      if (tempRot != null) {
        _cellRotations[toIndex] = tempRot;
      } else {
        _cellRotations.remove(toIndex);
      }

      final tempFlip = _cellFlips[fromIndex];
      if (_cellFlips.containsKey(toIndex)) {
        _cellFlips[fromIndex] = _cellFlips[toIndex]!;
      } else {
        _cellFlips.remove(fromIndex);
      }
      if (tempFlip != null) {
        _cellFlips[toIndex] = tempFlip;
      } else {
        _cellFlips.remove(toIndex);
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _cellImages[fromIndex] != null
                    ? 'Swapped Slot ${fromIndex + 1} and Slot ${toIndex + 1}!'
                    : 'Moved photo to Slot ${toIndex + 1}!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickCalendarDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _calendarNoteDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(2050),
      helpText: 'SELECT CALENDAR DATE',
      confirmText: 'SET DATE',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1D4ED8),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _calendarNoteDate = picked;
      });
    }
  }

  Future<void> _pickSeasonYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_seasonYear, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime(2050),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SELECT SEASON YEAR',
      confirmText: 'SET YEAR',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0284C7),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _seasonYear = picked.year;
      });
    }
  }

  Future<void> _pickImageForCell(int cellIndex) async {
    final hasExistingImage = _getImageForIndex(cellIndex) != null;
    final requiresMultiple = _activeLayout.photoCount > 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isFitMode = _getCellFitMode(cellIndex) == BoxFit.contain;
          final rotation = _cellRotations[cellIndex] ?? 0;
          final isFlipped = _cellFlips[cellIndex] ?? false;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          hasExistingImage
                              ? 'Adjust Photo (Slot ${cellIndex + 1})'
                              : 'Select Photo (Slot ${cellIndex + 1})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hasExistingImage)
                          TextButton.icon(
                            onPressed: () {
                              _resetCellTransform(cellIndex);
                              setSheetState(() {});
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Position reset to center'),
                                  duration: Duration(milliseconds: 700),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFF00F0FF)),
                            label: const Text('Reset', style: TextStyle(color: Color(0xFF00F0FF), fontSize: 12)),
                          ),
                      ],
                    ),
                  ),

                  if (hasExistingImage) ...[
                    const SizedBox(height: 12),
                    // Fit vs Fill segmented mode
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2638),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _cellFitModes[cellIndex] = BoxFit.contain;
                                    _cellControllers[cellIndex]?.value = Matrix4.identity();
                                  });
                                  setSheetState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isFitMode ? const Color(0xFF00F0FF) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.fit_screen_rounded,
                                        size: 16,
                                        color: isFitMode ? Colors.black : Colors.white70,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Fit (Entire Photo)',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: isFitMode ? Colors.black : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _cellFitModes[cellIndex] = BoxFit.cover;
                                    _cellControllers[cellIndex]?.value = Matrix4.identity();
                                  });
                                  setSheetState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !isFitMode ? const Color(0xFF00F0FF) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.crop_free_rounded,
                                        size: 16,
                                        color: !isFitMode ? Colors.black : Colors.white70,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Fill (Fill Frame)',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: !isFitMode ? Colors.black : Colors.white70,
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
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        isFitMode
                            ? '✨ Entire photo is displayed without cropping with ambient blurred background.'
                            : '📐 Photo fills the frame. Drag and pinch to adjust position and zoom.',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Rotate & Flip buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _rotateCellImage(cellIndex);
                                setSheetState(() {});
                              },
                              icon: const Icon(Icons.rotate_right_rounded, size: 16, color: Colors.white),
                              label: Text('Rotate (${rotation * 90}°)', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _flipCellImage(cellIndex);
                                setSheetState(() {});
                              },
                              icon: const Icon(Icons.flip_rounded, size: 16, color: Colors.white),
                              label: Text(isFlipped ? 'Flipped' : 'Flip', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white12, height: 20),
                  ],

                  if (requiresMultiple)
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFF2A85), Color(0xFF7928CA)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.collections_rounded, color: Colors.white, size: 20),
                      ),
                      title: const Text('Pick Multiple Photos at Once', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('Select multiple photos from gallery (layout has ${_activeLayout.photoCount} slots)', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _pickMultipleImagesStartingAt(cellIndex);
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
                    title: Text(hasExistingImage ? 'Change This Photo from Gallery' : 'Choose Single Photo from Gallery', style: const TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      AdMobService.instance.isPhotoPickerActive = true;
                      try {
                        final file = await _picker.pickImage(source: ImageSource.gallery);
                        if (file != null) {
                          final bytes = await file.readAsBytes();
                          _replaceCellImage(cellIndex, bytes);
                        }
                      } finally {
                        AdMobService.instance.isPhotoPickerActive = false;
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.secondary),
                    title: const Text('Take a Photo', style: TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      AdMobService.instance.isPhotoPickerActive = true;
                      try {
                        final file = await _picker.pickImage(source: ImageSource.camera);
                        if (file != null) {
                          final bytes = await file.readAsBytes();
                          _replaceCellImage(cellIndex, bytes);
                        }
                      } finally {
                        AdMobService.instance.isPhotoPickerActive = false;
                      }
                    },
                  ),
                  if (hasExistingImage)
                    ListTile(
                      leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      title: const Text('Remove Photo', style: TextStyle(color: Colors.redAccent)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _removeCellImage(cellIndex);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _replaceCellImage(int index, Uint8List bytes) {
    setState(() {
      _cellImages[index] = bytes;
      _cellControllers[index]?.value = Matrix4.identity();
      _cellRotations[index] = 0;
      _cellFlips[index] = false;
    });
    _cacheImageSize(index, bytes);
  }

  void _removeCellImage(int index) {
    setState(() {
      _cellImages.remove(index);
      _cellControllers[index]?.value = Matrix4.identity();
      _imageSizes.remove(index);
      _cellRotations.remove(index);
      _cellFlips.remove(index);
      _cellFitModes.remove(index);
    });
  }

  List<int> get _missingCellIndices {
    final missing = <int>[];
    for (int i = 0; i < _activeLayout.photoCount; i++) {
      if (_cellImages[i] == null) {
        missing.add(i);
      }
    }
    return missing;
  }

  Future<void> _exportCollage() async {
    // Validation: Block saving until EVERY required part has an image selected
    final missing = _missingCellIndices;
    if (missing.isNotEmpty) {
      final selectedCount = _activeLayout.photoCount - missing.length;
      final totalCount = _activeLayout.photoCount;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E2638),
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFF4D4D), width: 1.5),
          ),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4D).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFFF4D4D), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please select photos for all slots!',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Every slot must have an image before saving ($selectedCount/$totalCount selected).',
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Add Image',
            textColor: const Color(0xFF00F0FF),
            onPressed: () {
              _pickImageForCell(missing.first);
            },
          ),
        ),
      );
      return;
    }

    setState(() {
      _swapSourceIndex = null;
      _isExporting = true;
    });

    try {
      await WidgetsBinding.instance.endOfFrame;

      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Collage canvas not ready');

      final exportedBytes = await ImageExportService.captureWidgetToBytes(boundary, pixelRatio: 3.0);
      if (exportedBytes == null) throw Exception('Failed to render collage');

      // Direct save to gallery now that all required images are confirmed present!
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

      _showExportBottomSheet(exportedBytes, alreadySaved: savedSuccess);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportBottomSheet(Uint8List exportedBytes, {bool alreadySaved = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  alreadySaved ? 'Saved to Gallery! ✨' : 'Collage Ready! ✨',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 20),

                // Save to Gallery button
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await ImageExportService.saveToGallery(exportedBytes);
                    if (success) {
                      AdMobService.instance.showInterstitialAd();
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Collage saved to Gallery!' : 'Could not save collage'),
                          backgroundColor: success ? const Color(0xFF10B981) : Colors.redAccent,
                        ),
                      );
                    }
                  },
                  icon: Icon(alreadySaved ? Icons.check_circle_rounded : Icons.download_done_rounded, color: Colors.black),
                  label: Text(alreadySaved ? 'Saved in Gallery (Tap to Save Again)' : 'Save Lossless to Gallery', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),

                // Share
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ImageExportService.shareImage(exportedBytes);
                  },
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  label: const Text('Share Collage', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),

                // Open in Main Editor Studio
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditorScreen(imageBytes: exportedBytes)),
                    );
                  },
                  icon: const Icon(Icons.auto_fix_high_rounded, color: AppTheme.secondary, size: 18),
                  label: const Text('Edit Further in Studio', style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Template'),
        actions: [
          // Export Button
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: _isExporting
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)))
                : IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                    ),
                    onPressed: _exportCollage,
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                if (_activeLayout.photoCount > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 2, left: 16, right: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: _pickAdditionalImages,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF2A85), Color(0xFF7928CA)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF2A85).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.collections_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    _cellImages.length < _activeLayout.photoCount
                                        ? 'Pick Multi-Photos (${_cellImages.length}/${_activeLayout.photoCount})'
                                        : 'Add / Change Photos',
                                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_activeLayout == CollageLayout.junCalendar) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _pickCalendarDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E2E),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.edit_calendar_rounded, color: Color(0xFF00F0FF), size: 14),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Date: ${_monthNamesShort[_calendarNoteDate.month - 1]} ${_calendarNoteDate.day}, ${_calendarNoteDate.year}',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (_activeLayout == CollageLayout.seasonOfLight) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _pickSeasonYear,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E2E),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF00F0FF), size: 14),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Year: $_seasonYear',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (_cellImages.length >= 2) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                if (_swapSourceIndex != null) {
                                  setState(() => _swapSourceIndex = null);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _swapSourceIndex != null
                                      ? const Color(0xFF00384D)
                                      : const Color(0xFF1E1E2E),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _swapSourceIndex != null
                                        ? const Color(0xFF00F0FF)
                                        : const Color(0xFF00F0FF).withValues(alpha: 0.45),
                                    width: _swapSourceIndex != null ? 1.5 : 1.0,
                                  ),
                                  boxShadow: [
                                    if (_swapSourceIndex != null)
                                      BoxShadow(
                                        color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                                        blurRadius: 10,
                                      ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.swap_horiz_rounded,
                                      color: const Color(0xFF00F0FF),
                                      size: 15,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _swapSourceIndex != null
                                          ? 'Swapping Slot ${_swapSourceIndex! + 1} • Tap another photo to swap'
                                          : 'Drag ⇄ handle or tap to swap',
                                      style: TextStyle(
                                        color: _swapSourceIndex != null ? const Color(0xFF00F0FF) : Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_swapSourceIndex != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00F0FF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded, size: 10, color: Colors.black),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                // Collage Canvas Area with dynamic Aspect Ratio
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Disconnect Ratio from Templates:
                          // Templates preserve their dedicated authentic 1:1 design.
                          // Ratio is only applied to regular Collage Grids.
                          final effectiveRatio = _isTemplate ? 1.0 : _aspectRatio;

                          final maxW = constraints.maxWidth;
                          final maxH = constraints.maxHeight;
                          double canvasW, canvasH;
                          if (maxW / maxH > effectiveRatio) {
                            canvasH = maxH;
                            canvasW = maxH * effectiveRatio;
                          } else {
                            canvasW = maxW;
                            canvasH = maxW / effectiveRatio;
                          }

                          final isTransparent = _backgroundImageBytes == null &&
                              _backgroundGradient == null &&
                              _backgroundColor == Colors.transparent;

                          return RepaintBoundary(
                            key: _repaintBoundaryKey,
                            child: Container(
                              width: canvasW,
                              height: canvasH,
                              decoration: BoxDecoration(
                                color: (isTransparent || (_isTemplate && !_hasCustomBackground))
                                    ? Colors.transparent
                                    : (_backgroundImageBytes == null && _backgroundGradient == null ? _backgroundColor : null),
                                gradient: _backgroundImageBytes == null ? _backgroundGradient : null,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  if (!_isExporting)
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  // Checkerboard backdrop in editor when transparent background is chosen
                                  if (isTransparent && !_isExporting)
                                    const Positioned.fill(
                                      child: CustomPaint(
                                        painter: _CheckerboardPainter(),
                                      ),
                                    ),

                                  // Background Image Layer (if user set one)
                                  if (_backgroundImageBytes != null)
                                    Positioned.fill(
                                      child: ImageFiltered(
                                        imageFilter: _backgroundBlur > 0
                                            ? ui.ImageFilter.blur(sigmaX: _backgroundBlur, sigmaY: _backgroundBlur)
                                            : ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                                        child: Image.memory(
                                          _backgroundImageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),

                                  // Subtle contrast scrim over background image if present
                                  if (_backgroundImageBytes != null)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withValues(alpha: 0.12),
                                      ),
                                    ),

                                  // Collage Layout Content Layer with padding
                                  Positioned.fill(
                                    child: Padding(
                                      padding: EdgeInsets.all(_isTemplate ? 0 : _outerMargin),
                                      child: _buildCollageLayout(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Bottom Control Sheet with Tabs (matching Screenshots 1, 2 & 3)
                _buildCollageControls(),
              ],
            ),
    );
  }

  Widget _buildCollageLayout() {
    switch (_activeLayout) {
      // Aesthetic Modern Templates
      case CollageLayout.filmStripVintage:
        return _buildFilmStripVintage();
      case CollageLayout.vogueMagazine:
        return _buildVogueMagazine();
      case CollageLayout.retroVinylRecord:
        return _buildRetroVinylRecord();
      case CollageLayout.aestheticMoodboard:
        return _buildAestheticMoodboard();
      case CollageLayout.cyberpunkHud:
        return _buildCyberpunkHud();
      case CollageLayout.minimalistArch:
        return _buildMinimalistArch();
      case CollageLayout.musicPlayerCard:
        return _buildMusicPlayerCard();
      case CollageLayout.cinemaLetterbox:
        return _buildCinemaLetterbox();

      case CollageLayout.birthdayPolaroid:
        return _buildBirthdayPolaroid();
      case CollageLayout.simsPlumbob:
        return _buildSimsPlumbob();
      case CollageLayout.junCalendar:
        return _buildJunCalendar();
      case CollageLayout.starScrapbook:
        return _buildStarScrapbook();
      case CollageLayout.scallopedBows:
        return _buildScallopedBows();
      case CollageLayout.seasonOfLight:
        return _buildSeasonOfLight();

      // Modern Trending Collage Templates
      case CollageLayout.polaroidDuo:
        return _buildPolaroidDuo();
      case CollageLayout.modernTriptych:
        return _buildModernTriptych();
      case CollageLayout.editorialMosaic:
        return _buildEditorialMosaic();
      case CollageLayout.diagonalSplit:
        return _buildDiagonalSplit();
      case CollageLayout.storyRoll35mm:
        return _buildStoryRoll35mm();
      case CollageLayout.minimalist5:
        return _buildMinimalist5();

      // Multi-fit 10-image Layouts (User requested: multi fit main 10 image ka collage banane ka option)
      case CollageLayout.tenGrid:
        return _buildTenGrid();
      case CollageLayout.tenHeroCenter:
        return _buildTenHeroCenter();
      case CollageLayout.tenHeroTop:
        return _buildTenHeroTop();
      case CollageLayout.tenMasonry:
        return _buildTenMasonry();

      // Classic Grids
      case CollageLayout.fourGrid:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildCell(0)),
                  SizedBox(width: _spacing),
                  Expanded(child: _buildCell(1)),
                ],
              ),
            ),
            SizedBox(height: _spacing),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildCell(2)),
                  SizedBox(width: _spacing),
                  Expanded(child: _buildCell(3)),
                ],
              ),
            ),
          ],
        );

      case CollageLayout.twoVertical:
        return Row(
          children: [
            Expanded(child: _buildCell(0)),
            SizedBox(width: _spacing),
            Expanded(child: _buildCell(1)),
          ],
        );

      case CollageLayout.twoHorizontal:
        return Column(
          children: [
            Expanded(child: _buildCell(0)),
            SizedBox(height: _spacing),
            Expanded(child: _buildCell(1)),
          ],
        );

      case CollageLayout.threeHeroTop:
        return Column(
          children: [
            Expanded(flex: 3, child: _buildCell(0)),
            SizedBox(height: _spacing),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(child: _buildCell(1)),
                  SizedBox(width: _spacing),
                  Expanded(child: _buildCell(2)),
                ],
              ),
            ),
          ],
        );

      case CollageLayout.threeHeroBottom:
        return Column(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(child: _buildCell(0)),
                  SizedBox(width: _spacing),
                  Expanded(child: _buildCell(1)),
                ],
              ),
            ),
            SizedBox(height: _spacing),
            Expanded(flex: 3, child: _buildCell(2)),
          ],
        );

      case CollageLayout.threeColumns:
        return Row(
          children: [
            Expanded(child: _buildCell(0)),
            SizedBox(width: _spacing),
            Expanded(child: _buildCell(1)),
            SizedBox(width: _spacing),
            Expanded(child: _buildCell(2)),
          ],
        );

      case CollageLayout.fourHeroLeft:
        return Row(
          children: [
            Expanded(flex: 2, child: _buildCell(0)),
            SizedBox(width: _spacing),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(child: _buildCell(1)),
                  SizedBox(height: _spacing),
                  Expanded(child: _buildCell(2)),
                  SizedBox(height: _spacing),
                  Expanded(child: _buildCell(3)),
                ],
              ),
            ),
          ],
        );

      case CollageLayout.fourHeroTop:
        return Column(
          children: [
            Expanded(flex: 2, child: _buildCell(0)),
            SizedBox(height: _spacing),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(child: _buildCell(1)),
                  SizedBox(width: _spacing),
                  Expanded(child: _buildCell(2)),
                  SizedBox(width: _spacing),
                  Expanded(child: _buildCell(3)),
                ],
              ),
            ),
          ],
        );

      case CollageLayout.sixGrid:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildCell(0)),
                  SizedBox(width: _spacing),
                  Expanded(child: _buildCell(1)),
                  SizedBox(width: _spacing),
                  Expanded(child: _buildCell(2)),
                ],
              ),
            ),
            SizedBox(height: _spacing),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildCell(3)),
                  SizedBox(width: _spacing),
                  Expanded(child: _buildCell(4)),
                  SizedBox(width: _spacing),
                  Expanded(child: _buildCell(5)),
                ],
              ),
            ),
          ],
        );
    }
  }

  // --- Aesthetic Template Builders (Screenshots 2 & 3) ---

  /// 1. Vintage 35mm Filmstrip (Trending, 3 photos)
  Widget _buildFilmStripVintage() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : const Color(0xFF121316),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        children: [
          // Top Sprocket Holes & Film Code
          _buildSprocketRow(isTop: true),
          const SizedBox(height: 8),

          // 3 Frames side by side
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildFilmFrame(0, '24')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilmFrame(1, '24A')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilmFrame(2, '25')),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Bottom Sprocket Holes & DX Barcode
          _buildSprocketRow(isTop: false),
        ],
      ),
    );
  }

  Widget _buildSprocketRow({required bool isTop}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isTop)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('▶ 24A', style: TextStyle(color: Color(0xFFFFB703), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                Text('DX CODE 0184-24', style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 1.5, fontFamily: 'monospace')),
                Text('▶ 25', style: TextStyle(color: Color(0xFFFFB703), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(10, (index) {
            return Container(
              width: 14,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(2.5),
              ),
            );
          }),
        ),
        if (isTop)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('KODAK SAFETY FILM', style: TextStyle(color: Color(0xFFFFB703), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontFamily: 'monospace')),
                Text('ISO 400 / 27°', style: TextStyle(color: Colors.white60, fontSize: 8, letterSpacing: 1, fontFamily: 'monospace')),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilmFrame(int index, String frameNum) {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _buildCell(index),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'FRAME $frameNum',
          style: const TextStyle(color: Color(0xFFFFB703), fontSize: 8, letterSpacing: 1, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  /// 2. Vogue Editorial Cover (Magazine, 1 photo)
  Widget _buildVogueMagazine() {
    return Stack(
      children: [
        // Main full bleed image
        Positioned.fill(child: _buildCell(0)),

        // Gradient overlays for top and bottom legibility
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.28, 0.68, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.60),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.70),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Editorial Masthead: V O G U E (FittedBox ensures it NEVER wraps across lines)
        Positioned(
          top: 10,
          left: 14,
          right: 14,
          child: IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 48,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      'VOGUE',
                      maxLines: 1,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 14,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.black.withValues(alpha: 0.7), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 14,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('OCTOBER 2026', style: TextStyle(color: Colors.white70, fontSize: 8.5, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                        SizedBox(width: 12),
                        Text('•', style: TextStyle(color: Colors.white38, fontSize: 8)),
                        SizedBox(width: 12),
                        Text('SPECIAL EDITION', style: TextStyle(color: Colors.white70, fontSize: 8.5, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                        SizedBox(width: 12),
                        Text('•', style: TextStyle(color: Colors.white38, fontSize: 8)),
                        SizedBox(width: 12),
                        Text('\$12.00 US', style: TextStyle(color: Colors.white70, fontSize: 8.5, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(height: 0.8, color: Colors.white24),
              ],
            ),
          ),
        ),

        // Left Headlines - positioned at lower-left, clear of subject's face
        Positioned(
          left: 14,
          bottom: 50,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(3)),
                  child: const Text('EXCLUSIVE', style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 3),
                Text(
                  'TIMELESS\nELEGANCE',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.05,
                    shadows: [Shadow(color: Colors.black.withValues(alpha: 0.85), blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 2),
                const Text('The New Silhouette', style: TextStyle(color: Colors.white70, fontSize: 8.5, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ),

        // Bottom Barcode & Footer Headline - Guaranteed 0-overflow layout
        Positioned(
          left: 12,
          right: 12,
          bottom: 8,
          child: IgnorePointer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Barcode Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('||| || |||| | |||', style: TextStyle(fontFamily: 'monospace', fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1)),
                      Text('0 74470 12895', style: TextStyle(fontFamily: 'monospace', fontSize: 6, color: Colors.black87, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                // Right Headline: Flexible + FittedBox ensures ZERO overflow
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'PURE ART & SOUL',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: const Color(0xFFFFD700),
                            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 4)],
                          ),
                        ),
                      ),
                      const Text(
                        'COLLECTOR’S ISSUE',
                        style: TextStyle(color: Colors.white70, fontSize: 7.5, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 3. Vinyl Album & Disc (Trending, 1 photo)
  Widget _buildRetroVinylRecord() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : const Color(0xFF111218),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.album_rounded, color: Color(0xFFFF6B6B), size: 18),
                  SizedBox(width: 6),
                  Text('NOW SPINNING', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF6B6B), width: 0.8),
                ),
                child: const Text('HI-FI STEREO', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vinyl Record & Album Cover
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Black grooved vinyl disc peeking out to the right
                Positioned(
                  right: 4,
                  top: 20,
                  bottom: 20,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0A0A0C),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.7), blurRadius: 18, offset: const Offset(4, 4)),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Concentric vinyl grooves
                          Container(margin: const EdgeInsets.all(12), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white10, width: 1.2))),
                          Container(margin: const EdgeInsets.all(24), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white10, width: 1.2))),
                          Container(margin: const EdgeInsets.all(36), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white12, width: 1.2))),
                          // Center vinyl label
                          Container(
                            width: 65,
                            height: 65,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [Color(0xFFFFB703), Color(0xFFFB8500)]),
                            ),
                            child: Center(
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF111218)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Square Album Cover (Photo Cell 0)
                Positioned(
                  left: 6,
                  top: 10,
                  bottom: 10,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 16, offset: const Offset(2, 6)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildCell(0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Player bar at bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.music_note_rounded, color: Color(0xFFFFB703), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Track 01 • Midnight Melody', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('SIDE A • 33⅓ RPM', style: TextStyle(color: Colors.white54, fontSize: 9)),
                    ],
                  ),
                ),
                const Icon(Icons.play_circle_filled_rounded, color: Color(0xFFFF6B6B), size: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Washi Tape Moodboard (Autumn, 3 photos)
  Widget _buildAestheticMoodboard() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : const Color(0xFFF7F2EB),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Header note
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('memories & moments', style: GoogleFonts.caveat(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF5D4037))),
              Row(
                children: const [
                  Icon(Icons.spa_rounded, color: Color(0xFF8D6E63), size: 16),
                  SizedBox(width: 4),
                  Text('AUTUMN 2026', style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: Color(0xFF8D6E63), fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Top 2 Polaroids
          Expanded(
            flex: 5,
            child: Row(
              children: [
                // Polaroid 1 with washi tape
                Expanded(
                  child: Transform.rotate(
                    angle: -0.04,
                    child: _buildPolaroidScrap(0, 'Golden hour ✨', const Color(0xFFF472B6)),
                  ),
                ),
                const SizedBox(width: 10),
                // Polaroid 2 with washi tape
                Expanded(
                  child: Transform.rotate(
                    angle: 0.05,
                    child: _buildPolaroidScrap(1, 'Happy soul 🌿', const Color(0xFF34D399)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Bottom wide polaroid
          Expanded(
            flex: 4,
            child: Transform.rotate(
              angle: -0.015,
              child: _buildPolaroidScrap(2, 'cherish every second 🤍', const Color(0xFF60A5FA), isWide: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolaroidScrap(int index, String caption, Color tapeColor, {bool isWide = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(1, 4)),
            ],
          ),
          padding: EdgeInsets.fromLTRB(8, 8, 8, isWide ? 6 : 8),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: _buildCell(index),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: GoogleFonts.caveat(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF4A3E3D)),
              ),
            ],
          ),
        ),
        // Washi tape sticker on top
        Positioned(
          top: -6,
          left: 20,
          child: Container(
            width: 44,
            height: 14,
            decoration: BoxDecoration(
              color: tapeColor.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 3),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 2. Birthday Celebration Polaroid (Screenshot 3)
  Widget _buildBirthdayPolaroid() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : const Color(0xFFFFF1F2),
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: _buildCell(0))),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Birthday', style: GoogleFonts.dancingScript(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFFE11D48))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(12)),
                  child: Text('5.13', style: GoogleFonts.caveat(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFBE123C))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Sims Plumbob & Tag Capsules (Screenshot 2)
  Widget _buildSimsPlumbob() {
    return Stack(
      children: [
        Positioned.fill(child: _buildCell(0)),
        Positioned(
          top: 18,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.8), blurRadius: 20, spreadRadius: 4),
                ],
              ),
              child: const Icon(Icons.diamond_rounded, color: Color(0xFF22C55E), size: 34),
            ),
          ),
        ),
        Positioned(
          top: 70,
          left: 18,
          child: _buildSimsTag('📸 Take photos', const Color(0xFF3B82F6)),
        ),
        Positioned(
          bottom: 60,
          right: 18,
          child: _buildSimsTag('☕ Coffee break', const Color(0xFFEC4899)),
        ),
        Positioned(
          bottom: 24,
          left: 20,
          child: _buildSimsTag('🚀 Start a company', const Color(0xFF10B981)),
        ),
      ],
    );
  }

  Widget _buildSimsTag(String text, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// 4. Jun Calendar Polaroid with Paperclip (Screenshot 2)
  Widget _buildJunCalendar() {
    final monthName = _monthNamesShort[_calendarNoteDate.month - 1];

    return Container(
      color: _hasCustomBackground ? Colors.transparent : const Color(0xFFF0FDF4),
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 14, offset: const Offset(0, 5)),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildCell(0)),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _pickCalendarDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(monthName, style: GoogleFonts.dancingScript(fontSize: 30, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8))),
                                  Text(
                                    '${_calendarNoteDate.year}',
                                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                              if (!_isExporting) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.edit_calendar_rounded, size: 12, color: Color(0xFF1D4ED8)),
                                      SizedBox(width: 3),
                                      Text('Change', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          _buildCalendarWeekRow(_calendarNoteDate),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Positioned(
              top: 6,
              left: 20,
              child: Icon(Icons.attach_file_rounded, color: Colors.blueGrey, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarWeekRow(DateTime selectedDate) {
    const daysHeader = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(7, (i) {
            return SizedBox(
              width: 15,
              child: Text(
                daysHeader[i],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 7.5, color: Colors.black54, fontWeight: FontWeight.bold),
              ),
            );
          }),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(7, (i) {
            final dayDate = startOfWeek.add(Duration(days: i));
            final isSelected = dayDate.day == selectedDate.day &&
                dayDate.month == selectedDate.month &&
                dayDate.year == selectedDate.year;

            return Container(
              width: 15,
              height: 15,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF1D4ED8) : Colors.transparent,
              ),
              child: Text(
                '${dayDate.day}',
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black45,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// 5. Star Story Scrapbook (Screenshot 3)
  Widget _buildStarScrapbook() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : const Color(0xFF881337),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                child: Text('Always', style: GoogleFonts.specialElite(fontSize: 13, color: const Color(0xFF881337), fontWeight: FontWeight.bold)),
              ),
              const Row(
                children: [
                  Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 18),
                  Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildCell(0))),
                const SizedBox(width: 8),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildCell(1))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
              child: const Text('STORY • Cherished', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  /// 6. Scalloped Ribbon & Bows (Screenshot 3)
  Widget _buildScallopedBows() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : const Color(0xFFF8FAFC),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _PinstripePainter())),
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.84,
              heightFactor: 0.84,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFF43F5E), width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: _buildCell(0),
                ),
              ),
            ),
          ),
          const Positioned(top: 14, left: 0, right: 0, child: Center(child: Icon(Icons.bookmark_added_rounded, color: Color(0xFFF43F5E), size: 28))),
        ],
      ),
    );
  }

  /// 5. Cyberpunk Y2K Viewfinder (AI Mix, 1 photo)
  Widget _buildCyberpunkHud() {
    return Stack(
      children: [
        // Camera cell
        Positioned.fill(child: _buildCell(0)),

        // Cyberpunk HUD overlay
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top HUD row: REC indicator & FPS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF0055),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('● REC  [00:24:18]', style: TextStyle(color: Color(0xFFFF0055), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF00F0FF), width: 0.8),
                        ),
                        child: const Text('4K 60FPS', style: TextStyle(color: Color(0xFF00F0FF), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      ),
                    ],
                  ),

                  // Center targeting reticle
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.5), width: 1),
                      ),
                      child: const Center(
                        child: Icon(Icons.add_rounded, color: Color(0xFF00F0FF), size: 20),
                      ),
                    ),
                  ),

                  // Bottom HUD row: Telemetry info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('ISO 800  F/1.8  1/250s', style: TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'monospace')),
                      Text('CYBER_SYS // ACTV', style: TextStyle(color: Color(0xFF00F0FF), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // 4 Neon Cyber Corner Brackets
        Positioned(
          top: 8,
          left: 8,
          child: _buildHudCorner(top: true, left: true),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _buildHudCorner(top: true, left: false),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: _buildHudCorner(top: false, left: true),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: _buildHudCorner(top: false, left: false),
        ),
      ],
    );
  }

  Widget _buildHudCorner({required bool top, required bool left}) {
    return IgnorePointer(
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: Color(0xFF00F0FF), width: 2.5) : BorderSide.none,
            bottom: !top ? const BorderSide(color: Color(0xFF00F0FF), width: 2.5) : BorderSide.none,
            left: left ? const BorderSide(color: Color(0xFF00F0FF), width: 2.5) : BorderSide.none,
            right: !left ? const BorderSide(color: Color(0xFF00F0FF), width: 2.5) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// 6. Mediterranean Arch Gallery (Autumn, 2 photos)
  Widget _buildMinimalistArch() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : const Color(0xFFEBE6DF),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        children: [
          // Header
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'M E M O I R E S',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 5,
                color: const Color(0xFF4E4138),
              ),
            ),
          ),
          const SizedBox(height: 2),
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'ARCHITECTURAL HARMONY • VOL. II',
              style: TextStyle(fontSize: 8, letterSpacing: 2, color: Color(0xFF8C7B70), fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),

          // Two Roman Arches
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildArchCard(0, '01')),
                const SizedBox(width: 10),
                Expanded(child: _buildArchCard(1, '02')),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Footer Quote
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '“Simplicity is the ultimate sophistication”',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF5C4E44),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchCard(int index, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(90), bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 5)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(85), bottom: Radius.circular(12)),
              child: _buildCell(index),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 12, height: 1, color: const Color(0xFF8C7B70)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF4E4138))),
              ),
              Container(width: 12, height: 1, color: const Color(0xFF8C7B70)),
            ],
          ),
        ],
      ),
    );
  }

  /// 7. Glassmorphism Music Card (Love, 1 photo)
  Widget _buildMusicPlayerCard() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : const Color(0xFF13151F),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1D2030),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            // Soundwave header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 13),
                Text('PLAYING FROM PLAYLIST', style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                Icon(Icons.more_horiz_rounded, color: Colors.white54, size: 16),
              ],
            ),
            const SizedBox(height: 8),

            // Album Artwork (Cell 0)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFF2A85).withValues(alpha: 0.22), blurRadius: 16, spreadRadius: 1),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildCell(0),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Title & Heart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Golden Hour', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Favorite Melody • Studio Cut', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
                const Icon(Icons.favorite_rounded, color: Color(0xFFFF2A85), size: 20),
              ],
            ),
            const SizedBox(height: 6),

            // Scrubber Bar
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 3.5,
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
                  child: Row(
                    children: [
                      Container(
                        width: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFFFF2A85)]),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('1:45', style: TextStyle(color: Colors.white38, fontSize: 8.5)),
                    Text('3:20', style: TextStyle(color: Colors.white38, fontSize: 8.5)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Icon(Icons.shuffle_rounded, color: Colors.white38, size: 16),
                Icon(Icons.skip_previous_rounded, color: Colors.white, size: 22),
                Icon(Icons.play_circle_fill_rounded, color: Color(0xFF00F0FF), size: 34),
                Icon(Icons.skip_next_rounded, color: Colors.white, size: 22),
                Icon(Icons.repeat_rounded, color: Colors.white38, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 8. Cinematic 2.39:1 Letterbox Dual Story (Magazine, 2 photos)
  Widget _buildCinemaLetterbox() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          // Slate Header
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('35MM PANAVISION • 24 FPS', style: TextStyle(color: Colors.white54, fontSize: 8.5, letterSpacing: 1.5, fontFamily: 'monospace')),
                SizedBox(width: 20),
                Text('DIRECTOR\'S CUT', style: TextStyle(color: Color(0xFFFFD700), fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontFamily: 'monospace')),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // First Widescreen Frame (Index 0)
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _buildCell(0),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3)),
                    child: const Text('SCENE 24 // TAKE 01', style: TextStyle(color: Color(0xFFFFD700), fontSize: 8, fontFamily: 'monospace')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle divider bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '« Some moments are too beautiful to forget in a lifetime... »',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFFFEB3B),
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Second Widescreen Frame (Index 1)
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _buildCell(1),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3)),
                    child: const Text('SCENE 25 // GOLDEN HOUR', style: TextStyle(color: Color(0xFFFFD700), fontSize: 8, fontFamily: 'monospace')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 9. 2020 Season of Light Magazine (Screenshot 2)
  Widget _buildSeasonOfLight() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : const Color(0xFFF5F5F0),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _pickSeasonYear,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('$_seasonYear', style: GoogleFonts.bebasNeue(fontSize: 32, letterSpacing: 2, color: const Color(0xFF0284C7))),
                if (!_isExporting) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit_calendar_rounded, size: 12, color: Color(0xFF0284C7)),
                        SizedBox(width: 3),
                        Text('Change Year', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text('Season of Light', style: GoogleFonts.cormorantGaramond(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black87)),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: _buildCell(0),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('12 months,\nendless possibilities.', style: TextStyle(fontSize: 9, color: Colors.black54)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(border: Border.all(color: Colors.black26), borderRadius: BorderRadius.circular(2)),
                child: const Text('|||| ||| ||||||', style: TextStyle(fontSize: 9, letterSpacing: 1.5, fontFamily: 'monospace')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Modern 1. Polaroid Duo (2 Photos with angled frames, washi tape & shadows)
  Widget _buildPolaroidDuo() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : const Color(0xFF141722),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardW = constraints.maxWidth * 0.62;
          final cardH = constraints.maxHeight * 0.68;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Background subtle dot matrix pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15,
                  child: CustomPaint(painter: _PinstripePainter()),
                ),
              ),

              // Card 1: Tilted Left (-5 degrees)
              Positioned(
                left: constraints.maxWidth * 0.06,
                top: constraints.maxHeight * 0.08,
                child: Transform.rotate(
                  angle: -0.09,
                  child: Container(
                    width: cardW,
                    height: cardH,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 36),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBFBFB),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: _buildCell(0),
                          ),
                        ),
                        // Label bottom
                        Positioned(
                          left: 4,
                          bottom: -28,
                          child: Text(
                            'MEMORIES // 01',
                            style: GoogleFonts.caveat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Washi tape for Card 1
              Positioned(
                left: constraints.maxWidth * 0.22,
                top: constraints.maxHeight * 0.05,
                child: Transform.rotate(
                  angle: -0.06,
                  child: Container(
                    width: 55,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD166).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Card 2: Tilted Right (+6 degrees), overlapping Card 1
              Positioned(
                right: constraints.maxWidth * 0.06,
                bottom: constraints.maxHeight * 0.07,
                child: Transform.rotate(
                  angle: 0.10,
                  child: Container(
                    width: cardW,
                    height: cardH,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 36),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: _buildCell(1),
                          ),
                        ),
                        // Label bottom
                        Positioned(
                          left: 4,
                          bottom: -28,
                          child: Text(
                            'TOGETHER // 02',
                            style: GoogleFonts.caveat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Washi tape for Card 2
              Positioned(
                right: constraints.maxWidth * 0.24,
                bottom: constraints.maxHeight * 0.69,
                child: Transform.rotate(
                  angle: 0.08,
                  child: Container(
                    width: 55,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF476F).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2),
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

  /// Modern 2. Gallery Triptych (3 vertical exhibition columns with thin borders & museum plate numbers)
  Widget _buildModernTriptych() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : const Color(0xFF10131B),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        children: [
          // Museum Exhibition Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GALLERY TRIPTYCH',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                  color: Colors.white,
                ),
              ),
              Text(
                'STUDIO ARCHIVE • 2026',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 3 Columns
          Expanded(
            child: Row(
              children: List.generate(3, (i) {
                final labels = ['PLATE 01', 'PLATE 02', 'PLATE 03'];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == 2 ? 0 : 8,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _buildCell(i),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          labels[i],
                          style: GoogleFonts.spaceMono(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          // Subtle minimal caption bottom
          Text(
            'Fine Art Collection • Curated Triple Exposure Series',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  /// Modern 3. Editorial Mosaic (Asymmetric high-fashion editorial: 1 tall hero + 3 asymmetric right slots)
  Widget _buildEditorialMosaic() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : const Color(0xFF0F1117),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Left Tall Hero Photo (Flex 11)
                Expanded(
                  flex: 11,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildCell(0),
                  ),
                ),
                const SizedBox(width: 8),
                // Right Asymmetric Stack (Flex 10)
                Expanded(
                  flex: 10,
                  child: Column(
                    children: [
                      // Top horizontal photo (Flex 5)
                      Expanded(
                        flex: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildCell(1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Bottom 2 square photos (Flex 6)
                      Expanded(
                        flex: 6,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _buildCell(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _buildCell(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Footer editorial metadata
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EDITORIAL MOSAIC // VOL. 04',
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: Colors.white70,
                ),
              ),
              Text(
                'MAGIC STUDIO ARCHIVE',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: const Color(0xFF00F0FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Modern 4. Diagonal Duo Split (2 Photos split with modern diagonal divider & badges)
  Widget _buildDiagonalSplit() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : Colors.black,
      child: Stack(
        children: [
          // Photo 0 (Top / Left)
          Positioned.fill(
            child: ClipPath(
              clipper: _DiagonalSplitClipper(isTopLeft: true),
              child: _buildCell(0),
            ),
          ),

          // Photo 1 (Bottom / Right)
          Positioned.fill(
            child: ClipPath(
              clipper: _DiagonalSplitClipper(isTopLeft: false),
              child: _buildCell(1),
            ),
          ),

          // Diagonal Divider Line
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DiagonalLinePainter(),
              ),
            ),
          ),

          // Floating Aesthetic Badges
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'PERSPECTIVE A',
                style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ),
          ),

          Positioned(
            bottom: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'PERSPECTIVE B',
                style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Modern 5. Story Roll 35mm (4 Photos in an authentic vertical 35mm film roll with sprocket holes & frame codes)
  Widget _buildStoryRoll35mm() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : const Color(0xFF0A0A0E),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Left Film Sprocket Strip
          Container(
            width: 20,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(14, (i) {
                return Container(
                  width: 10,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),

          // 4 Film Frames
          Expanded(
            child: Column(
              children: List.generate(4, (i) {
                final frameLabels = ['▷ 21A • KODAK 400', '▷ 22A • TX-400', '▷ 23A • SAFETY FILM', '▷ 24A • 35MM ISO 400'];
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141418),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: _buildCell(i),
                          ),
                        ),
                        // Film stamp watermark
                        Positioned(
                          right: 6,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              frameLabels[i],
                              style: const TextStyle(
                                color: Color(0xFFFFB703),
                                fontSize: 7,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Right Film Sprocket Strip
          Container(
            width: 20,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(14, (i) {
                return Container(
                  width: 10,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// Modern 6. Minimalist 5 (1 Wide Hero on top + 4 curated gallery squares below)
  Widget _buildMinimalist5() {
    return Container(
      color: _hasCustomBackground ? Colors.transparent : const Color(0xFF0F121C),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Top Wide Cinematic Hero (Flex 12)
          Expanded(
            flex: 12,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildCell(0),
            ),
          ),
          const SizedBox(height: 8),

          // Bottom 4 Curated Squares (Flex 8)
          Expanded(
            flex: 8,
            child: Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 3 ? 0 : 8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildCell(i + 1),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),

          // Minimalist Bottom Metadata
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COLLECTION № 05',
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Colors.white70,
                ),
              ),
              Text(
                'MAGIC STUDIO GALLERY',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Multi-fit 10-Image Layouts ---

  /// 10. Multi-fit 10-Photo 2x5 Grid (User requested: multi fit main 10 image ka collage banane ka option)
  Widget _buildTenGrid() {
    return Column(
      children: List.generate(5, (row) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: row == 4 ? 0 : _spacing),
            child: Row(
              children: [
                Expanded(child: _buildCell(row * 2)),
                SizedBox(width: _spacing),
                Expanded(child: _buildCell(row * 2 + 1)),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// 11. Multi-fit 10-Photo Hero Center (1 Large Hero + 9 around it)
  Widget _buildTenHeroCenter() {
    return Column(
      children: [
        // Top 3
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(child: _buildCell(0)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(1)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(2)),
            ],
          ),
        ),
        SizedBox(height: _spacing),
        // Middle Row: Left 2 + Center Hero + Right 2
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(child: _buildCell(3)),
                    SizedBox(height: _spacing),
                    Expanded(child: _buildCell(4)),
                  ],
                ),
              ),
              SizedBox(width: _spacing),
              Expanded(
                flex: 2,
                child: _buildCell(5), // Large Center Hero
              ),
              SizedBox(width: _spacing),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(child: _buildCell(6)),
                    SizedBox(height: _spacing),
                    Expanded(child: _buildCell(7)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _spacing),
        // Bottom 2
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(child: _buildCell(8)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(9)),
            ],
          ),
        ),
      ],
    );
  }

  /// 12. Multi-fit 10-Photo 2 Top Hero + 8 Grid
  Widget _buildTenHeroTop() {
    return Column(
      children: [
        // 2 Top Hero photos
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(child: _buildCell(0)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(1)),
            ],
          ),
        ),
        SizedBox(height: _spacing),
        // 8 Grid photos below in 2 rows of 4
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(child: _buildCell(2)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(3)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(4)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(5)),
            ],
          ),
        ),
        SizedBox(height: _spacing),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(child: _buildCell(6)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(7)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(8)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(9)),
            ],
          ),
        ),
      ],
    );
  }

  /// 13. Multi-fit 10-Photo 3-4-3 Masonry
  Widget _buildTenMasonry() {
    return Column(
      children: [
        // Row 1: 3 photos
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildCell(0)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(1)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(2)),
            ],
          ),
        ),
        SizedBox(height: _spacing),
        // Row 2: 4 photos
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildCell(3)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(4)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(5)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(6)),
            ],
          ),
        ),
        SizedBox(height: _spacing),
        // Row 3: 3 photos
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildCell(7)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(8)),
              SizedBox(width: _spacing),
              Expanded(child: _buildCell(9)),
            ],
          ),
        ),
      ],
    );
  }

  // --- Cell Builders (Safe Indexing) ---

  /// Interactive movable & zoomable photo inside collage / template cell
  Widget _buildInteractiveCellImage({
    required int index,
    required Uint8List bytes,
  }) {
    final controller = _getCellController(index);
    final fitMode = _getCellFitMode(index);
    final isFit = fitMode == BoxFit.contain;
    final rotation = _cellRotations[index] ?? 0;
    final isFlipped = _cellFlips[index] ?? false;
    final isSwappedDimensions = rotation % 2 == 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cachedSize = _imageSizes[index];
        double childWidth = constraints.maxWidth;
        double childHeight = constraints.maxHeight;

        if (cachedSize != null && cachedSize.width > 0 && cachedSize.height > 0) {
          final imgW = isSwappedDimensions ? cachedSize.height : cachedSize.width;
          final imgH = isSwappedDimensions ? cachedSize.width : cachedSize.height;
          final imgAspect = imgW / imgH;
          final frameAspect = constraints.maxWidth / constraints.maxHeight;

          if (isFit) {
            // FIT MODE: Entire photo fits inside frame without getting cut off
            if (imgAspect > frameAspect) {
              childWidth = constraints.maxWidth;
              childHeight = constraints.maxWidth / imgAspect;
            } else {
              childHeight = constraints.maxHeight;
              childWidth = constraints.maxHeight * imgAspect;
            }
          } else {
            // FILL MODE: Covers frame completely, full image data preserved for panning
            if (imgAspect > frameAspect) {
              childHeight = constraints.maxHeight;
              childWidth = constraints.maxHeight * imgAspect;
            } else {
              childWidth = constraints.maxWidth;
              childHeight = constraints.maxWidth / imgAspect;
            }
          }
        }

        final photoWidget = SizedBox(
          width: childWidth,
          height: childHeight,
          child: RotatedBox(
            quarterTurns: rotation,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(isFlipped ? -1.0 : 1.0, 1.0, 1.0),
              child: Image.memory(
                bytes,
                fit: BoxFit.fill,
                gaplessPlayback: true,
              ),
            ),
          ),
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // Ambient frosted blur background when in Fit mode so letterboxing/pillarboxing looks stunning
            if (isFit) ...[
              ClipRect(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Transform.scale(
                    scale: 1.25,
                    child: RotatedBox(
                      quarterTurns: rotation,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(isFlipped ? -1.0 : 1.0, 1.0, 1.0),
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ],

            // Interactive viewer for panning, zooming, and positioning
            GestureDetector(
              onTap: () {
                if (_swapSourceIndex != null) {
                  if (_swapSourceIndex == index) {
                    setState(() => _swapSourceIndex = null);
                  } else {
                    _swapOrMoveCellImages(_swapSourceIndex!, index);
                  }
                }
              },
              onDoubleTap: () {
                setState(() {
                  controller.value = Matrix4.identity();
                });
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Position reset to center'),
                    duration: Duration(milliseconds: 700),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: InteractiveViewer(
                transformationController: controller,
                minScale: 0.5,
                maxScale: 5.0,
                boundaryMargin: EdgeInsets.all(
                  math.max(constraints.maxWidth, constraints.maxHeight) * 1.5,
                ),
                panEnabled: true,
                scaleEnabled: true,
                clipBehavior: Clip.hardEdge,
                child: Center(
                  child: photoWidget,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Dedicated Swap Handle Badge: Drag directly to swap or tap to enter swap mode
  Widget _buildSwapHandleBadge(int index, Uint8List imgBytes, {bool isCircle = false}) {
    if (_isExporting || _activeLayout.photoCount <= 1) {
      return const SizedBox.shrink();
    }

    final isSwapSource = _swapSourceIndex == index;

    return Draggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        elevation: 16,
        child: Container(
          width: 95,
          height: 95,
          decoration: BoxDecoration(
            borderRadius: isCircle ? BorderRadius.circular(48) : BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF00F0FF), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.55),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(imgBytes, fit: BoxFit.cover),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.white70),
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            if (_swapSourceIndex == index) {
              _swapSourceIndex = null;
            } else {
              _swapSourceIndex = index;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: isSwapSource
                ? const Color(0xFF00F0FF)
                : Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSwapSource ? Colors.white : Colors.white24,
              width: 1,
            ),
            boxShadow: [
              if (isSwapSource)
                BoxShadow(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.65),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: 13,
                color: isSwapSource ? Colors.black : const Color(0xFF00F0FF),
              ),
              const SizedBox(width: 3),
              Text(
                isSwapSource ? 'Swapping' : 'Swap',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSwapSource ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int index) {
    final imgBytes = _getImageForIndex(index);
    final isFitMode = _getCellFitMode(index) == BoxFit.contain;

    final cellWidget = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_cornerRadius),
        color: AppTheme.surfaceLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: imgBytes != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                _buildInteractiveCellImage(index: index, bytes: imgBytes),
                if (!_isExporting) ...[
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _buildSwapHandleBadge(index, imgBytes),
                  ),
                  // Quick Fit / Fill toggle button on bottom-left
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggleCellFitMode(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFitMode ? const Color(0xFF00F0FF) : Colors.white30,
                            width: 1,
                          ),
                          boxShadow: [
                            if (isFitMode)
                              BoxShadow(
                                color: const Color(0xFF00F0FF).withValues(alpha: 0.45),
                                blurRadius: 6,
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFitMode ? Icons.fit_screen_rounded : Icons.crop_free_rounded,
                              size: 13,
                              color: isFitMode ? const Color(0xFF00F0FF) : Colors.white,
                            ),
                            const SizedBox(width: 3.5),
                            Text(
                              isFitMode ? 'Fit' : 'Fill',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isFitMode ? const Color(0xFF00F0FF) : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Edit / Adjust button on bottom-right
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _pickImageForCell(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30, width: 1),
                        ),
                        child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            )
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_swapSourceIndex != null) {
                  _swapOrMoveCellImages(_swapSourceIndex!, index);
                } else {
                  _pickImageForCell(index);
                }
              },
              child: _buildEmptyPlaceholder(),
            ),
    );

    return _wrapWithDraggableAndTarget(
      index: index,
      cellChild: cellWidget,
    );
  }




  Widget _wrapWithDraggableAndTarget({
    required int index,
    required Widget cellChild,
    CustomClipper<Path>? shapeClipper,
    bool isCircle = false,
  }) {
    // Drag & drop is active when layout requires > 1 photo and not exporting
    if (_isExporting || _activeLayout.photoCount <= 1) {
      return cellChild;
    }

    final imgBytes = _getImageForIndex(index);
    final isSwapSource = _swapSourceIndex == index;

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) {
        _swapOrMoveCellImages(details.data, index);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Stack(
          fit: StackFit.expand,
          children: [
            cellChild,

            // Active Drop Overlay when dragging another photo over this slot
            if (isHovered)
              Positioned.fill(
                child: shapeClipper != null
                    ? ClipPath(
                        clipper: shapeClipper,
                        child: _buildHoverIndicator(hasImage: imgBytes != null),
                      )
                    : (isCircle
                        ? ClipOval(child: _buildHoverIndicator(hasImage: imgBytes != null))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(_cornerRadius),
                            child: _buildHoverIndicator(hasImage: imgBytes != null),
                          )),
              ),

            // Highlight glowing border when this slot is marked as swap source
            if (isSwapSource)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: isCircle ? null : BorderRadius.circular(_cornerRadius),
                      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                      border: Border.all(
                        color: const Color(0xFF00F0FF),
                        width: 3.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHoverIndicator({required bool hasImage}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
        border: Border.all(color: const Color(0xFF00F0FF), width: 3),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasImage ? Icons.swap_horiz_rounded : Icons.move_down_rounded,
                color: const Color(0xFF00F0FF),
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                hasImage ? 'Drop to Swap' : 'Drop Here',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    if (_isExporting) {
      return Container(color: Colors.transparent);
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        borderRadius: BorderRadius.circular(_cornerRadius),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFF2A85).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFFF2A85), size: 18),
            ),
            const SizedBox(height: 5),
            const Text(
              'Add Photo',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  // --- Bottom Control Panel Matching Screenshots 2 & 3 ---

  Widget _buildCollageControls() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),

            // Top Tab Navigation Bar (Templates, Layout, Ratio, Margin, Background, Save)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _visibleTabs.map((tab) {
                          final isSelected = _activeTab == tab;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _activeTab = tab;
                                if (tab == CollageBottomTab.shapes && !_isTemplate) {
                                  _activeLayout = CollageLayout.filmStripVintage;
                                } else if (tab == CollageBottomTab.layout && _isTemplate) {
                                  _activeLayout = CollageLayout.fourGrid;
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primary : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    tab.icon,
                                    size: 15,
                                    color: isSelected ? AppTheme.primary : Colors.white60,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tab.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? AppTheme.primary : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Quick Checkmark / Export Button in tab bar
                  IconButton(
                    tooltip: 'Save Collage',
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                    ),
                    onPressed: _exportCollage,
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 12),

            // Tab Content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildActiveTabContent(),
            ),

            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      // 1. Templates Tab (Screenshots 2 & 3: category pills + template cards)
      case CollageBottomTab.shapes:
        final allTemplates = CollageLayout.values.where((l) => l.type == CollageType.template || l.type == CollageType.shape).toList();
        final filteredTemplates = _templateCategory == 'All'
            ? allTemplates
            : allTemplates.where((l) => l.category == _templateCategory).toList();

        final categories = ['All', 'Trending', 'AI Mix', 'Autumn', 'Love', 'Magazine'];

        return Column(
          key: const ValueKey('templates_tab'),
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sub-category Filter Pills (Screenshots 2 & 3)
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _templateCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _templateCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.white12,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.black : Colors.white70,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Template cards horizontal gallery
            SizedBox(
              height: 80,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: filteredTemplates.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final layout = filteredTemplates[index];
                  final isSelected = _activeLayout == layout;
                  final isVipTemplate = _isVip(layout);
                  final isLocked = isVipTemplate && !_unlockedVipTemplates.contains(layout);

                  return GestureDetector(
                    onTap: () {
                      if (isLocked) {
                        _showUnlockVipDialog(layout);
                        return;
                      }
                      setState(() {
                        _activeLayout = layout;
                        if (_activeTab == CollageBottomTab.ratio) {
                          _activeTab = CollageBottomTab.shapes;
                        }
                      });
                    },
                    child: Container(
                      width: 90,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00B0FF).withValues(alpha: 0.25) : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00B0FF) : Colors.white12,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                layout.icon,
                                color: isSelected ? const Color(0xFF00B0FF) : Colors.white70,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                layout.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          if (isLocked)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFB703).withValues(alpha: 0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'VIP',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 0.5,
                                  ),
                                ),
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
        );

      // 2. Grids & Multi-fit Tab
      case CollageBottomTab.layout:
        final grids = CollageLayout.values.where((l) => l.type == CollageType.grid).toList();
        return SizedBox(
          key: const ValueKey('layout_tab'),
          height: 78,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: grids.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final layout = grids[index];
              final isSelected = _activeLayout == layout;
              final isVipLayout = _isVip(layout);
              final isLocked = isVipLayout && !_unlockedVipTemplates.contains(layout);

              return GestureDetector(
                onTap: () {
                  if (isLocked) {
                    _showUnlockVipDialog(layout);
                    return;
                  }
                  setState(() => _activeLayout = layout);
                },
                child: Container(
                  width: 96,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withValues(alpha: 0.25) : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.white12,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            layout.icon,
                            color: isSelected ? AppTheme.primary : Colors.white70,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            layout.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      if (isLocked)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFB703).withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );

      // 3. Aspect Ratio Tab
      case CollageBottomTab.ratio:
        final ratios = [
          {'label': '1:1', 'value': 1.0},
          {'label': '4:5 (Insta)', 'value': 4 / 5},
          {'label': '9:16 (Story)', 'value': 9 / 16},
          {'label': '16:9 (Reel)', 'value': 16 / 9},
          {'label': '3:4', 'value': 3 / 4},
          {'label': '2:3', 'value': 2 / 3},
        ];

        return SizedBox(
          key: const ValueKey('ratio_tab'),
          height: 64,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: ratios.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final r = ratios[index];
              final isSelected = _aspectRatioLabel == r['label'];

              return ChoiceChip(
                label: Text(r['label'] as String),
                selected: isSelected,
                selectedColor: AppTheme.primary,
                backgroundColor: AppTheme.surfaceLight,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _aspectRatio = r['value'] as double;
                      _aspectRatioLabel = r['label'] as String;
                    });
                  }
                },
              );
            },
          ),
        );

      // 4. Margins & Spacing Tab
      case CollageBottomTab.margin:
        return Padding(
          key: const ValueKey('margin_tab'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Margin', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppTheme.primary,
                        inactiveTrackColor: Colors.white12,
                        thumbColor: AppTheme.primary,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 2,
                      ),
                      child: Slider(
                        value: _outerMargin,
                        min: 0,
                        max: 28,
                        onChanged: (v) => setState(() => _outerMargin = v),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Spacing', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppTheme.secondary,
                        inactiveTrackColor: Colors.white12,
                        thumbColor: AppTheme.secondary,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 2,
                      ),
                      child: Slider(
                        value: _spacing,
                        min: 0,
                        max: 20,
                        onChanged: (v) => setState(() => _spacing = v),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      // 5. Background Palette & Image Tab
      case CollageBottomTab.background:
        return Padding(
          key: const ValueKey('bg_tab'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action Buttons: Pick Image, Blur 1st Photo, Custom Color, Clear Image
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // 1. Pick Image Button
                    GestureDetector(
                      onTap: _pickBackgroundImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.35), blurRadius: 6),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Photo BG', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 2. Blur 1st Photo as Background
                    GestureDetector(
                      onTap: _useBlurredFirstPhotoAsBackground,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27273A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.blur_on_rounded, color: Color(0xFF00F0FF), size: 16),
                            SizedBox(width: 6),
                            Text('Blur 1st Photo', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 3. Custom Color Picker Dialog
                    GestureDetector(
                      onTap: _openCustomColorPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27273A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.colorize_rounded, color: Color(0xFFFF2A85), size: 16),
                            SizedBox(width: 6),
                            Text('Color Picker', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 4. Transparent Background Option
                    Builder(
                      builder: (context) {
                        final isTransparentActive = _backgroundImageBytes == null &&
                            _backgroundGradient == null &&
                            _backgroundColor == Colors.transparent;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _backgroundColor = Colors.transparent;
                              _backgroundGradient = null;
                              _backgroundImageBytes = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isTransparentActive
                                  ? AppTheme.primary.withValues(alpha: 0.2)
                                  : const Color(0xFF27273A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isTransparentActive ? AppTheme.primary : Colors.white24,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.grid_4x4_rounded, color: Color(0xFF00E5FF), size: 16),
                                SizedBox(width: 6),
                                Text('Transparent', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    if (_backgroundImageBytes != null) ...[
                      const SizedBox(width: 8),
                      // 5. Remove Image Button
                      GestureDetector(
                        onTap: _clearBackgroundImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close_rounded, color: Colors.redAccent, size: 15),
                              SizedBox(width: 4),
                              Text('Remove BG', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Background Blur Slider if background image is active
              if (_backgroundImageBytes != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.blur_linear_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text('Blur: ${_backgroundBlur.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppTheme.primary,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: AppTheme.primary,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 2,
                        ),
                        child: Slider(
                          value: _backgroundBlur,
                          min: 0,
                          max: 25,
                          onChanged: (v) => setState(() => _backgroundBlur = v),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),

              // Horizontal Color Palette & Gradient Swatches
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Transparent Swatch
                    Builder(
                      builder: (context) {
                        final isSelected = _backgroundImageBytes == null &&
                            _backgroundGradient == null &&
                            _backgroundColor == Colors.transparent;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _backgroundColor = Colors.transparent;
                              _backgroundGradient = null;
                              _backgroundImageBytes = null;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : Colors.white24,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 6)]
                                  : null,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                const Positioned.fill(
                                  child: CustomPaint(
                                    painter: _CheckerboardPainter(squareSize: 5.5),
                                  ),
                                ),
                                if (isSelected)
                                  const Center(
                                    child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Solid Colors
                    ..._bgColors.map((color) {
                      final isSelected = _backgroundImageBytes == null && _backgroundColor == color && _backgroundGradient == null;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _backgroundColor = color;
                            _backgroundGradient = null;
                            _backgroundImageBytes = null;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : Colors.white24,
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 6)]
                                : null,
                          ),
                        ),
                      );
                    }),

                    // Gradients
                    ..._bgGradients.map((gradient) {
                      final isSelected = _backgroundImageBytes == null && _backgroundGradient == gradient;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _backgroundGradient = gradient;
                            _backgroundImageBytes = null;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: gradient,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : Colors.white24,
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 6)]
                                : null,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}

// --- Custom Geometry Clippers for Creative Shapes ---

class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.5, h * 0.95);
    path.cubicTo(w * 0.05, h * 0.65, 0, h * 0.35, 0, h * 0.22);
    path.cubicTo(0, h * 0.04, w * 0.22, 0, w * 0.5, h * 0.22);
    path.cubicTo(w * 0.78, 0, w, h * 0.04, w, h * 0.22);
    path.cubicTo(w, h * 0.35, w * 0.95, h * 0.65, w * 0.5, h * 0.95);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class RotatedHeartClipper extends CustomClipper<Path> {
  final double angleRadians;
  RotatedHeartClipper(this.angleRadians);

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;

    final heartPath = Path();
    heartPath.moveTo(cx, cy + 0.46 * h);
    heartPath.cubicTo(cx - 0.45 * w, cy + 0.15 * h, cx - 0.45 * w, cy - 0.25 * h, cx - 0.22 * w, cy - 0.44 * h);
    heartPath.cubicTo(cx - 0.10 * w, cy - 0.48 * h, cx - 0.02 * w, cy - 0.35 * h, cx, cy - 0.22 * h);
    heartPath.cubicTo(cx + 0.02 * w, cy - 0.35 * h, cx + 0.10 * w, cy - 0.48 * h, cx + 0.22 * w, cy - 0.44 * h);
    heartPath.cubicTo(cx + 0.45 * w, cy - 0.25 * h, cx + 0.45 * w, cy + 0.15 * h, cx, cy + 0.46 * h);
    heartPath.close();

    final matrix = Matrix4.identity()
      ..multiply(Matrix4.translationValues(cx, cy, 0.0))
      ..rotateZ(angleRadians)
      ..multiply(Matrix4.translationValues(-cx, -cy, 0.0));

    return heartPath.transform(matrix.storage);
  }

  @override
  bool shouldReclip(RotatedHeartClipper oldClipper) => oldClipper.angleRadians != angleRadians;
}

class RotatedPetalClipper extends CustomClipper<Path> {
  final double angleRadians;
  RotatedPetalClipper(this.angleRadians);

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;

    final path = Path();
    path.moveTo(cx, cy + 0.45 * h);
    path.cubicTo(cx - 0.35 * w, cy + 0.15 * h, cx - 0.35 * w, cy - 0.25 * h, cx, cy - 0.45 * h);
    path.cubicTo(cx + 0.35 * w, cy - 0.25 * h, cx + 0.35 * w, cy + 0.15 * h, cx, cy + 0.45 * h);
    path.close();

    final matrix = Matrix4.identity()
      ..multiply(Matrix4.translationValues(cx, cy, 0.0))
      ..rotateZ(angleRadians)
      ..multiply(Matrix4.translationValues(-cx, -cy, 0.0));

    return path.transform(matrix.storage);
  }

  @override
  bool shouldReclip(RotatedPetalClipper oldClipper) => oldClipper.angleRadians != angleRadians;
}




class _PinstripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 2.0;

    for (double x = 0; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CheckerboardPainter extends CustomPainter {
  final double squareSize;

  const _CheckerboardPainter({
    this.squareSize = 10.0,
  });

  static const Color color1 = Color(0xFF2E3344);
  static const Color color2 = Color(0xFF1F2330);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isEven = ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiagonalSplitClipper extends CustomClipper<Path> {
  final bool isTopLeft;
  _DiagonalSplitClipper({required this.isTopLeft});

  @override
  Path getClip(Size size) {
    final path = Path();
    if (isTopLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(0, size.height);
      path.close();
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _DiagonalSplitClipper oldClipper) => oldClipper.isTopLeft != isTopLeft;
}

class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
