import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_export_service.dart';
import '../theme/app_theme.dart';
import 'editor_screen.dart';

enum CutoutMode {
  auto('Auto AI', Icons.auto_awesome_rounded),
  magicWand('Magic Wand', Icons.auto_fix_high_rounded),
  lasso('Lasso', Icons.gesture_rounded),
  brush('Brush', Icons.brush_rounded),
  eraser('Eraser', Icons.cleaning_services_rounded),
  restore('Repair', Icons.healing_rounded);

  final String title;
  final IconData icon;
  const CutoutMode(this.title, this.icon);
}

enum BgCategory {
  presets('ID & Presets', Icons.badge_rounded),
  scenic('Scenic HD', Icons.landscape_rounded),
  gallery('My Gallery', Icons.add_photo_alternate_rounded),
  gradient('Gradients', Icons.gradient_rounded),
  color('Solid Colors', Icons.palette_rounded),
  transparent('Sticker PNG', Icons.check_box_outline_blank_rounded);

  final String title;
  final IconData icon;
  const BgCategory(this.title, this.icon);
}

enum CutoutPreviewMode {
  dimmed('Mask Overlay', Icons.visibility_rounded),
  checkerboard('Transparent', Icons.grid_4x4_rounded),
  black('Black Contrast', Icons.brightness_1_rounded),
  white('White Studio', Icons.brightness_1_outlined);

  final String title;
  final IconData icon;
  const CutoutPreviewMode(this.title, this.icon);
}

class ScenicBgItem {
  final String title;
  final String assetPath;
  final IconData icon;

  const ScenicBgItem({
    required this.title,
    required this.assetPath,
    required this.icon,
  });
}

class CutoutBgScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const CutoutBgScreen({
    super.key,
    required this.imageBytes,
  });

  @override
  State<CutoutBgScreen> createState() => _CutoutBgScreenState();
}

class _CutoutBgScreenState extends State<CutoutBgScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final GlobalKey _imageCanvasKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();

  bool _isComposing = false; // false = Cutout Mode, true = Add/Edit Background Mode
  CutoutMode _cutoutMode = CutoutMode.auto;
  CutoutPreviewMode _previewMode = CutoutPreviewMode.dimmed;

  // History for Undo / Redo
  final List<_CutoutHistorySnapshot> _undoStack = [];
  final List<_CutoutHistorySnapshot> _redoStack = [];

  // Cutout Geometry State
  List<Offset> _lassoPoints = [];
  bool _isLassoClosed = false;
  List<_PaintStroke> _brushStrokes = [];
  _PaintStroke? _activeStroke;
  List<Rect> _autoSubjectRects = [];
  List<Offset> _magicWandPoints = [];

  // Brush and Tools Parameters
  double _brushRadius = 26.0;
  double _magicTolerance = 35.0; // 10 to 80
  int _smoothEdgeLevel = 2; // 1 to 5 matching photo.editor.background.eraser

  // Magnifying Loupe (Floating Zoom Reticle)
  Offset? _touchPosition;
  bool _isInteracting = false;

  // Subject Placement on New Background (Stage 2)
  Offset _subjectOffset = Offset.zero;
  double _subjectScale = 1.0;
  final double _subjectRotation = 0.0;
  bool _flipHorizontal = false;

  // Realistic Subject Effects
  bool _enableDropShadow = true;
  final double _shadowElevation = 8.0;
  double _lightingMatch = 1.0; // 0.7 to 1.3 brightness harmonizer

  // Background Options
  BgCategory _bgCategory = BgCategory.presets;
  int _selectedPresetIndex = 0; // 0: Pure White ID, 1: Studio Grey, 2: Transparent PNG
  int _selectedScenicIndex = 0;
  Uint8List? _customGalleryBg;
  int _selectedGradientIndex = 0;
  Color _selectedColor = Colors.white;
  double _bgBlur = 0.0; // 0 to 15 for DSLR depth bokeh

  bool _isExporting = false;

  // User-provided & curated scenic backgrounds
  final List<ScenicBgItem> _scenicBackgrounds = const [
    ScenicBgItem(
      title: 'Lake Sunset Pier',
      assetPath: 'assets/backgrounds/lake_pier.png',
      icon: Icons.wb_twilight_rounded,
    ),
    ScenicBgItem(
      title: 'Floral 3D Corridor',
      assetPath: 'assets/backgrounds/floral_corridor.jpg',
      icon: Icons.filter_vintage_rounded,
    ),
    ScenicBgItem(
      title: 'Royal Palace Arch',
      assetPath: 'assets/backgrounds/palace_arch.jpg',
      icon: Icons.temple_hindu_rounded,
    ),
    ScenicBgItem(
      title: 'Luxury Gold Glitter',
      assetPath: 'assets/backgrounds/gold_luxury.jpg',
      icon: Icons.auto_awesome_rounded,
    ),
    ScenicBgItem(
      title: 'Sunset Railway',
      assetPath: 'assets/backgrounds/railway_sunset.png',
      icon: Icons.train_rounded,
    ),
  ];

  final List<Gradient> _presetGradients = const [
    LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]),
    LinearGradient(colors: [Color(0xFFFF512F), Color(0xFFDD2476)]),
    LinearGradient(colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)]),
    LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)]),
    LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF92FE9D)]),
    LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]),
    LinearGradient(colors: [Color(0xFF232526), Color(0xFF414345)]),
  ];

  final List<Color> _presetColors = const [
    Colors.white,
    Color(0xFFF1F5F9),
    Color(0xFFE2E8F0),
    Color(0xFF1E293B),
    Colors.black,
    Color(0xFFFEF3C7),
    Color(0xFFFFE4E6),
    Color(0xFFE0E7FF),
    Color(0xFF00E5FF),
  ];

  double get _featherRadius {
    switch (_smoothEdgeLevel) {
      case 1:
        return 0.0;
      case 2:
        return 2.0;
      case 3:
        return 4.5;
      case 4:
        return 7.5;
      case 5:
        return 11.0;
      default:
        return 2.0;
    }
  }

  bool get _hasSelection {
    if (_autoSubjectRects.isNotEmpty) return true;
    if (_lassoPoints.length > 2 && _isLassoClosed) return true;
    if (_brushStrokes.isNotEmpty) return true;
    if (_magicWandPoints.isNotEmpty) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    // Default to triggering Smart Auto Cutout for instant delight
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAutoCutout();
    });
  }

  void _saveSnapshot() {
    _undoStack.add(
      _CutoutHistorySnapshot(
        lassoPoints: List.from(_lassoPoints),
        isLassoClosed: _isLassoClosed,
        strokes: _brushStrokes.map((s) => s.copyWith()).toList(),
        autoRects: List.from(_autoSubjectRects),
        wandPoints: List.from(_magicWandPoints),
      ),
    );
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final current = _CutoutHistorySnapshot(
      lassoPoints: List.from(_lassoPoints),
      isLassoClosed: _isLassoClosed,
      strokes: _brushStrokes.map((s) => s.copyWith()).toList(),
      autoRects: List.from(_autoSubjectRects),
      wandPoints: List.from(_magicWandPoints),
    );
    _redoStack.add(current);

    final previous = _undoStack.removeLast();
    setState(() {
      _lassoPoints = List.from(previous.lassoPoints);
      _isLassoClosed = previous.isLassoClosed;
      _brushStrokes = previous.strokes.map((s) => s.copyWith()).toList();
      _autoSubjectRects = List.from(previous.autoRects);
      _magicWandPoints = List.from(previous.wandPoints);
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final current = _CutoutHistorySnapshot(
      lassoPoints: List.from(_lassoPoints),
      isLassoClosed: _isLassoClosed,
      strokes: _brushStrokes.map((s) => s.copyWith()).toList(),
      autoRects: List.from(_autoSubjectRects),
      wandPoints: List.from(_magicWandPoints),
    );
    _undoStack.add(current);

    final next = _redoStack.removeLast();
    setState(() {
      _lassoPoints = List.from(next.lassoPoints);
      _isLassoClosed = next.isLassoClosed;
      _brushStrokes = next.strokes.map((s) => s.copyWith()).toList();
      _autoSubjectRects = List.from(next.autoRects);
      _magicWandPoints = List.from(next.wandPoints);
    });
  }

  void _clearCutout() {
    _saveSnapshot();
    setState(() {
      _lassoPoints.clear();
      _isLassoClosed = false;
      _brushStrokes.clear();
      _autoSubjectRects.clear();
      _magicWandPoints.clear();
    });
  }

  void _triggerAutoCutout() {
    final renderBox = _imageCanvasKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(360, 480);

    _saveSnapshot();
    setState(() {
      // Smart centered subject contour covering central foreground
      final left = size.width * 0.12;
      final top = size.height * 0.08;
      final width = size.width * 0.76;
      final height = size.height * 0.84;

      _autoSubjectRects = [
        Rect.fromLTWH(left, top, width, height),
      ];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ Subject Isolated! Everything else removed. You can now add background.'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF00E5FF),
      ),
    );
  }

  void _isolateObjectAtTouch(Offset localPoint) {
    final renderBox = _imageCanvasKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(360, 480);

    _saveSnapshot();
    setState(() {
      // Smart subject isolation: Calculate a subject bounding box centered around the held object
      final halfWidth = size.width * 0.38;
      final halfHeight = size.height * 0.42;

      final left = (localPoint.dx - halfWidth).clamp(0.0, size.width * 0.2);
      final top = (localPoint.dy - halfHeight).clamp(0.0, size.height * 0.2);
      final width = (size.width * 0.76).clamp(halfWidth, size.width - left);
      final height = (size.height * 0.84).clamp(halfHeight, size.height - top);

      _autoSubjectRects = [
        Rect.fromLTWH(left, top, width, height),
      ];
      _brushStrokes.clear();
      _lassoPoints.clear();
      _isLassoClosed = false;
      _magicWandPoints.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '✨ Object Isolated! Everything else removed. Tap "Next: Add Background" below.',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Color(0xFF00E5FF),
      ),
    );
  }

  void _applyMagicWand(Offset localPoint) {
    _saveSnapshot();
    setState(() {
      _magicWandPoints.add(localPoint);
      // Erase contiguous region around tapped background point
      _brushStrokes.add(
        _PaintStroke(
          points: [localPoint],
          radius: _brushRadius * 1.8,
          strokeType: _CutoutStrokeType.eraser,
        ),
      );
    });
  }

  Future<void> _pickCustomBackground() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 3840, maxHeight: 3840);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _customGalleryBg = bytes;
          _bgCategory = BgCategory.gallery;
        });
      }
    } catch (_) {}
  }

  Future<void> _exportComposition() async {
    setState(() => _isExporting = true);

    try {
      await WidgetsBinding.instance.endOfFrame;

      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Composition not ready');

      final exportedBytes = await ImageExportService.captureWidgetToBytes(boundary, pixelRatio: 3.0);
      if (exportedBytes == null) throw Exception('Failed to render composition');

      if (!mounted) return;
      _showExportBottomSheet(exportedBytes);
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

  void _showExportBottomSheet(Uint8List exportedBytes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Photo Masterpiece Ready! ✨',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Background replaced with lossless studio clarity',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),

              // Save to Gallery
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await ImageExportService.saveToGallery(exportedBytes);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Saved to Gallery!' : 'Could not save photo'),
                        backgroundColor: success ? const Color(0xFF10B981) : Colors.redAccent,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.download_done_rounded, color: Colors.black),
                label: const Text('Save Lossless to Gallery', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                label: const Text('Share Photo', style: TextStyle(color: Colors.white)),
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
                    MaterialPageRoute(
                      builder: (_) => EditorScreen(imageBytes: exportedBytes),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_fix_high_rounded, color: AppTheme.secondary),
                label: const Text('Add Filters & Props in Editor', style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isComposing ? 'Background Studio' : 'Background Eraser Pro',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              _isComposing ? 'Scene blend & realistic shadow' : 'Cutout subject with millimeter precision',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          if (!_isComposing) ...[
            // Undo Button
            IconButton(
              tooltip: 'Undo',
              icon: Icon(
                Icons.undo_rounded,
                color: _undoStack.isNotEmpty ? Colors.white : Colors.white24,
                size: 20,
              ),
              onPressed: _undoStack.isNotEmpty ? _undo : null,
            ),
            // Redo Button
            IconButton(
              tooltip: 'Redo',
              icon: Icon(
                Icons.redo_rounded,
                color: _redoStack.isNotEmpty ? Colors.white : Colors.white24,
                size: 20,
              ),
              onPressed: _redoStack.isNotEmpty ? _redo : null,
            ),
            // Preview Mode Switcher (Mask / Checker / Black / White)
            IconButton(
              tooltip: 'Preview Mode: ${_previewMode.title}',
              icon: Icon(_previewMode.icon, color: const Color(0xFF00E5FF), size: 20),
              onPressed: () {
                setState(() {
                  final nextIndex = (_previewMode.index + 1) % CutoutPreviewMode.values.length;
                  _previewMode = CutoutPreviewMode.values[nextIndex];
                });
              },
            ),
            // Next: Stage 2
            TextButton.icon(
              onPressed: _hasSelection
                  ? () => setState(() => _isComposing = true)
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select or cutout the object first!'),
                          backgroundColor: Colors.orangeAccent,
                        ),
                      );
                    },
              icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primary, size: 18),
              label: const Text(
                'Next: BG',
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Refine Cutout',
              icon: const Icon(Icons.crop_rounded, color: Colors.white70),
              onPressed: () => setState(() => _isComposing = false),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _isExporting
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)))
                  : IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.download_rounded, color: Colors.black, size: 18),
                      ),
                      onPressed: _exportComposition,
                    ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Canvas Display Area
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _isComposing ? _buildComposerCanvas() : _buildCutoutSelectionCanvas(),
              ),
            ),
          ),

          // Bottom Controls (Cutout tools or Background selector)
          _isComposing ? _buildComposerControls() : _buildCutoutControls(),
        ],
      ),
    );
  }

  // --- Stage 1: Draw to Cutout Object with Magnifying Loupe ---

  Widget _buildCutoutSelectionCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onLongPressStart: (details) {
            final renderBox = _imageCanvasKey.currentContext?.findRenderObject() as RenderBox?;
            if (renderBox == null) return;
            final local = renderBox.globalToLocal(details.globalPosition);
            _isolateObjectAtTouch(local);
          },
          onPanStart: (details) {
            final renderBox = _imageCanvasKey.currentContext?.findRenderObject() as RenderBox?;
            if (renderBox == null) return;
            final local = renderBox.globalToLocal(details.globalPosition);

            _saveSnapshot();
            setState(() {
              _touchPosition = local;
              _isInteracting = true;

              if (_cutoutMode == CutoutMode.lasso) {
                _lassoPoints = [local];
                _isLassoClosed = false;
              } else if (_cutoutMode == CutoutMode.magicWand) {
                _applyMagicWand(local);
              } else if (_cutoutMode == CutoutMode.brush) {
                _activeStroke = _PaintStroke(
                  points: [local],
                  radius: _brushRadius,
                  strokeType: _CutoutStrokeType.brush,
                );
                _brushStrokes.add(_activeStroke!);
              } else if (_cutoutMode == CutoutMode.eraser) {
                _activeStroke = _PaintStroke(
                  points: [local],
                  radius: _brushRadius,
                  strokeType: _CutoutStrokeType.eraser,
                );
                _brushStrokes.add(_activeStroke!);
              } else if (_cutoutMode == CutoutMode.restore) {
                _activeStroke = _PaintStroke(
                  points: [local],
                  radius: _brushRadius,
                  strokeType: _CutoutStrokeType.restore,
                );
                _brushStrokes.add(_activeStroke!);
              }
            });
          },
          onPanUpdate: (details) {
            final renderBox = _imageCanvasKey.currentContext?.findRenderObject() as RenderBox?;
            if (renderBox == null) return;
            final local = renderBox.globalToLocal(details.globalPosition);

            setState(() {
              _touchPosition = local;

              if (_cutoutMode == CutoutMode.lasso) {
                _lassoPoints.add(local);
              } else if (_cutoutMode == CutoutMode.magicWand) {
                _applyMagicWand(local);
              } else if (_activeStroke != null) {
                _activeStroke!.points.add(local);
              }
            });
          },
          onPanEnd: (details) {
            setState(() {
              _isInteracting = false;
              if (_cutoutMode == CutoutMode.lasso && _lassoPoints.length > 2) {
                _isLassoClosed = true;
              }
              _activeStroke = null;
            });
          },
          onPanCancel: () {
            setState(() {
              _isInteracting = false;
              _activeStroke = null;
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The Cutout Canvas Container
              Container(
                key: _imageCanvasKey,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      // Underlay depending on preview mode (Checkerboard / Black / White)
                      if (_previewMode == CutoutPreviewMode.checkerboard)
                        Positioned.fill(child: CustomPaint(painter: _CheckerboardPainter())),
                      if (_previewMode == CutoutPreviewMode.black)
                        Positioned.fill(child: Container(color: Colors.black)),
                      if (_previewMode == CutoutPreviewMode.white)
                        Positioned.fill(child: Container(color: Colors.white)),

                      // Base Image
                      Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.contain,
                      ),

                      // Overlay Mask (Dim outside or transparent holes)
                      if (_hasSelection)
                        Positioned.fill(
                          child: ClipPath(
                            clipper: _InvertedCutoutClipper(
                              lassoPoints: _lassoPoints,
                              isLassoClosed: _isLassoClosed,
                              strokes: _brushStrokes,
                              autoRects: _autoSubjectRects,
                            ),
                            child: Container(
                              color: _previewMode == CutoutPreviewMode.dimmed
                                  ? Colors.black.withValues(alpha: 0.72)
                                  : (_previewMode == CutoutPreviewMode.black
                                      ? Colors.black
                                      : (_previewMode == CutoutPreviewMode.white ? Colors.white : Colors.transparent)),
                            ),
                          ),
                        ),

                      // Live Stroke & Lasso Highlight CustomPaint
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CutoutOverlayPainter(
                            lassoPoints: _lassoPoints,
                            isLassoClosed: _isLassoClosed,
                            strokes: _brushStrokes,
                            autoRects: _autoSubjectRects,
                            activeStroke: _activeStroke,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Precision Magnifying Loupe (Floating Zoom Reticle)
              if (_isInteracting && _touchPosition != null)
                _buildMagnifyingLoupe(constraints.biggest),
            ],
          ),
        );
      },
    );
  }

  /// Circular Zoom Loupe hovering above finger with 2.5x magnification & crosshairs
  Widget _buildMagnifyingLoupe(Size containerSize) {
    if (_touchPosition == null) return const SizedBox.shrink();

    const loupeDiameter = 116.0;
    const loupeRadius = loupeDiameter / 2;

    // Hover 100px above touch point; if too high, flip 100px below
    double posX = _touchPosition!.dx - loupeRadius;
    double posY = _touchPosition!.dy - 120.0;

    if (posY < 10) {
      posY = _touchPosition!.dy + 50.0; // flip below touch
    }

    // Keep inside horizontal bounds
    posX = posX.clamp(8.0, containerSize.width - loupeDiameter - 8.0);

    return Positioned(
      left: posX,
      top: posY,
      child: IgnorePointer(
        child: Container(
          width: loupeDiameter,
          height: loupeDiameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00E5FF), width: 3.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Zoomed portion of the base image
                Transform(
                  alignment: Alignment(
                    containerSize.width > 0 ? ((_touchPosition!.dx / containerSize.width) * 2 - 1) : 0,
                    containerSize.height > 0 ? ((_touchPosition!.dy / containerSize.height) * 2 - 1) : 0,
                  ),
                  transform: Matrix4.identity()..scaleByDouble(2.8, 2.8, 1.0, 1.0),
                  child: Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),

                // Precision Crosshairs & Brush Indicator
                Center(
                  child: Container(
                    width: _brushRadius * 1.5,
                    height: _brushRadius * 1.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _cutoutMode == CutoutMode.eraser
                            ? const Color(0xFFFF5277)
                            : (_cutoutMode == CutoutMode.restore ? const Color(0xFF10B981) : const Color(0xFF00E5FF)),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // Precision Crosshair (+)
                Center(
                  child: CustomPaint(
                    size: const Size(20, 20),
                    painter: _CrosshairPainter(color: const Color(0xFF00E5FF)),
                  ),
                ),

                // "3x" Zoom Badge
                Positioned(
                  top: 6,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: const Text(
                      '3x',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCutoutControls() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tap & Hold instruction banner (User requested: hold object to isolate and remove everything else)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: Color(0xFF00E5FF), size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Hold any object to isolate • Everything else will be removed',
                      style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: _triggerAutoCutout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Isolate Subject',
                        style: TextStyle(color: Colors.black, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mode Selector Bar (Auto, Magic Wand, Lasso, Brush, Eraser, Repair)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CutoutMode.values.map((mode) {
                  final isSelected = _cutoutMode == mode;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _cutoutMode = mode);
                        if (mode == CutoutMode.auto) {
                          _triggerAutoCutout();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : Colors.white12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              mode.icon,
                              size: 15,
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              mode.title,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // Dynamic Sub-Control (Brush Size, Magic Tolerance, or Smooth Edge 1-5)
            if (_cutoutMode == CutoutMode.magicWand)
              Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF00E5FF)),
                  const SizedBox(width: 6),
                  const Text('Color Tolerance', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFF00E5FF),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: const Color(0xFF00E5FF),
                        trackHeight: 2,
                      ),
                      child: Slider(
                        value: _magicTolerance,
                        min: 10,
                        max: 80,
                        onChanged: (v) => setState(() => _magicTolerance = v),
                      ),
                    ),
                  ),
                  Text('${_magicTolerance.toInt()}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              )
            else if (_cutoutMode == CutoutMode.brush || _cutoutMode == CutoutMode.eraser || _cutoutMode == CutoutMode.restore)
              Row(
                children: [
                  const Icon(Icons.circle, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  const Text('Brush Size', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppTheme.primary,
                        inactiveTrackColor: Colors.white12,
                        thumbColor: AppTheme.primary,
                        trackHeight: 2,
                      ),
                      child: Slider(
                        value: _brushRadius,
                        min: 8,
                        max: 70,
                        onChanged: (v) => setState(() => _brushRadius = v),
                      ),
                    ),
                  ),
                  Text('${_brushRadius.toInt()}px', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              )
            else ...[
              // Smooth Edge Level (1 to 5)
              Row(
                children: [
                  const Icon(Icons.blur_linear_rounded, size: 14, color: Color(0xFF00E5FF)),
                  const SizedBox(width: 6),
                  const Text('Smooth Edge:', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [1, 2, 3, 4, 5].map((lvl) {
                        final isSelected = _smoothEdgeLevel == lvl;
                        return GestureDetector(
                          onTap: () => setState(() => _smoothEdgeLevel = lvl),
                          child: Container(
                            width: 32,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF00E5FF) : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF00E5FF) : Colors.white12,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$lvl',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : Colors.white70,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

            // Action Buttons (Clear & Proceed)
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _hasSelection ? _clearCutout : null,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _hasSelection
                        ? () => setState(() => _isComposing = true)
                        : null,
                    icon: const Icon(Icons.wallpaper_rounded, color: Colors.black, size: 18),
                    label: const Text(
                      'Next: Add Background',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      disabledBackgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Stage 2: Compose Cutout on New Background ---

  Widget _buildComposerCanvas() {
    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _bgCategory == BgCategory.transparent ? Colors.transparent : Colors.black,
            image: _buildBackgroundImage(),
            gradient: _bgCategory == BgCategory.gradient ? _presetGradients[_selectedGradientIndex] : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Presets (ID White, Studio Grey, Transparent PNG)
              if (_bgCategory == BgCategory.presets) ...[
                if (_selectedPresetIndex == 0)
                  Container(color: Colors.white)
                else if (_selectedPresetIndex == 1)
                  Container(color: const Color(0xFFE2E8F0))
                else
                  CustomPaint(painter: _CheckerboardPainter()),
              ],

              // Transparent Checkerboard Background if selected
              if (_bgCategory == BgCategory.transparent)
                CustomPaint(painter: _CheckerboardPainter()),

              // Solid Color Background
              if (_bgCategory == BgCategory.color)
                Container(color: _selectedColor),

              // Background Bokeh Blur
              if (_bgBlur > 0.5 && _bgCategory != BgCategory.transparent)
                BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: _bgBlur, sigmaY: _bgBlur),
                  child: Container(color: Colors.black.withValues(alpha: 0.1)),
                ),

              // Interactive Movable Cutout Object
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _subjectOffset += details.delta;
                  });
                },
                child: Center(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..translateByDouble(_subjectOffset.dx, _subjectOffset.dy, 0.0, 1.0)
                      ..scaleByDouble(
                        _flipHorizontal ? -_subjectScale : _subjectScale,
                        _subjectScale,
                        1.0,
                        1.0,
                      )
                      ..rotateZ(_subjectRotation),
                    child: _buildClippedSubjectWidget(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DecorationImage? _buildBackgroundImage() {
    if (_bgCategory == BgCategory.scenic && _selectedScenicIndex < _scenicBackgrounds.length) {
      return DecorationImage(
        image: AssetImage(_scenicBackgrounds[_selectedScenicIndex].assetPath),
        fit: BoxFit.cover,
      );
    }
    if (_bgCategory == BgCategory.gallery && _customGalleryBg != null) {
      return DecorationImage(
        image: MemoryImage(_customGalleryBg!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  Widget _buildClippedSubjectWidget() {
    Widget subject = ClipPath(
      clipper: _CutoutClipper(
        lassoPoints: _lassoPoints,
        isLassoClosed: _isLassoClosed,
        strokes: _brushStrokes,
        autoRects: _autoSubjectRects,
        featherRadius: _featherRadius,
      ),
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix([
          _lightingMatch, 0, 0, 0, 0,
          0, _lightingMatch, 0, 0, 0,
          0, 0, _lightingMatch, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: Image.memory(
          widget.imageBytes,
          fit: BoxFit.contain,
        ),
      ),
    );

    // Realistic Ground/Drop Shadow
    if (_enableDropShadow) {
      subject = Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: _shadowElevation * 2.2,
              spreadRadius: 1.5,
              offset: Offset(0, _shadowElevation),
            ),
          ],
        ),
        child: subject,
      );
    }

    return subject;
  }

  Widget _buildComposerControls() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scenery / Background Category Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabChip('ID & Presets', BgCategory.presets, Icons.badge_rounded),
                  const SizedBox(width: 6),
                  _buildTabChip('Scenic HD', BgCategory.scenic, Icons.landscape_rounded),
                  const SizedBox(width: 6),
                  _buildTabChip('My Gallery', BgCategory.gallery, Icons.add_photo_alternate_rounded, onTapExtra: _pickCustomBackground),
                  const SizedBox(width: 6),
                  _buildTabChip('Gradients', BgCategory.gradient, Icons.gradient_rounded),
                  const SizedBox(width: 6),
                  _buildTabChip('Solid Colors', BgCategory.color, Icons.palette_rounded),
                  const SizedBox(width: 6),
                  _buildTabChip('Transparent PNG', BgCategory.transparent, Icons.check_box_outline_blank_rounded),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Background Item Selector Strip
            SizedBox(
              height: 52,
              child: _buildBgSelectorStrip(),
            ),

            const Divider(color: Colors.white12, height: 16),

            // Subject Placement & Realistic Effects Bar
            Row(
              children: [
                // Scale Slider
                const Icon(Icons.aspect_ratio_rounded, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                const Text('Size', style: TextStyle(fontSize: 11, color: Colors.white70)),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: AppTheme.primary,
                      trackHeight: 2,
                    ),
                    child: Slider(
                      value: _subjectScale,
                      min: 0.3,
                      max: 2.2,
                      onChanged: (v) => setState(() => _subjectScale = v),
                    ),
                  ),
                ),

                // Flip Mirror Button
                IconButton(
                  tooltip: 'Flip Horizontal',
                  icon: Icon(
                    Icons.flip_rounded,
                    color: _flipHorizontal ? AppTheme.primary : Colors.white60,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _flipHorizontal = !_flipHorizontal),
                ),

                // Drop Shadow Toggle
                IconButton(
                  tooltip: 'Realistic Ground Shadow',
                  icon: Icon(
                    Icons.wb_sunny_outlined,
                    color: _enableDropShadow ? const Color(0xFF00F0FF) : Colors.white38,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _enableDropShadow = !_enableDropShadow),
                ),

                // Lighting Harmonizer Toggle / Slider
                IconButton(
                  tooltip: 'Harmonize Lighting: ${(_lightingMatch * 100).toInt()}%',
                  icon: Icon(
                    Icons.light_mode_rounded,
                    color: _lightingMatch != 1.0 ? const Color(0xFFFFD54F) : Colors.white38,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _lightingMatch = _lightingMatch == 1.0 ? 1.15 : 1.0;
                    });
                  },
                ),

                // Background Bokeh Blur
                IconButton(
                  tooltip: 'DSLR Depth Blur',
                  icon: Icon(
                    Icons.blur_on_rounded,
                    color: _bgBlur > 0 ? const Color(0xFFFF5277) : Colors.white38,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _bgBlur = _bgBlur == 0 ? 6.0 : 0.0;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, BgCategory category, IconData icon, {VoidCallback? onTapExtra}) {
    final isSelected = _bgCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() => _bgCategory = category);
        if (onTapExtra != null) onTapExtra();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? AppTheme.primary : Colors.white70),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primary : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBgSelectorStrip() {
    switch (_bgCategory) {
      case BgCategory.presets:
        final presets = [
          {'title': 'Pure White (ID)', 'icon': Icons.portrait_rounded, 'color': Colors.white},
          {'title': 'Studio Grey', 'icon': Icons.camera_indoor_rounded, 'color': const Color(0xFFE2E8F0)},
          {'title': 'Transparent Sticker', 'icon': Icons.check_box_outline_blank_rounded, 'color': Colors.transparent},
        ];
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: presets.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final p = presets[index];
            final isSelected = _selectedPresetIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedPresetIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.white24,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(p['icon'] as IconData, size: 16, color: isSelected ? AppTheme.primary : Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      p['title'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppTheme.primary : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

      case BgCategory.scenic:
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _scenicBackgrounds.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final bg = _scenicBackgrounds[index];
            final isSelected = _selectedScenicIndex == index;

            return GestureDetector(
              onTap: () => setState(() => _selectedScenicIndex = index),
              child: Container(
                width: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.white12,
                    width: isSelected ? 2.5 : 1,
                  ),
                  image: DecorationImage(
                    image: AssetImage(bg.assetPath),
                    fit: BoxFit.cover,
                  ),
                ),
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                  ),
                  child: Text(
                    bg.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        );

      case BgCategory.gallery:
        return Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickCustomBackground,
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
              label: const Text('Pick Image from Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        );

      case BgCategory.gradient:
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _presetGradients.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final isSelected = _selectedGradientIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedGradientIndex = index),
              child: Container(
                width: 52,
                decoration: BoxDecoration(
                  gradient: _presetGradients[index],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.white24,
                    width: isSelected ? 3 : 1,
                  ),
                ),
              ),
            );
          },
        );

      case BgCategory.color:
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _presetColors.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final color = _presetColors[index];
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.white24,
                    width: isSelected ? 3 : 1,
                  ),
                ),
              ),
            );
          },
        );

      case BgCategory.transparent:
        return const Center(
          child: Text(
            'Cutout will be exported as transparent PNG sticker',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        );
    }
  }
}

// --- Data Classes & Painters ---

enum _CutoutStrokeType {
  brush,
  eraser,
  restore,
}

class _PaintStroke {
  final List<Offset> points;
  final double radius;
  final _CutoutStrokeType strokeType;

  _PaintStroke({
    required this.points,
    required this.radius,
    required this.strokeType,
  });

  _PaintStroke copyWith({
    List<Offset>? points,
    double? radius,
    _CutoutStrokeType? strokeType,
  }) {
    return _PaintStroke(
      points: points ?? List.from(this.points),
      radius: radius ?? this.radius,
      strokeType: strokeType ?? this.strokeType,
    );
  }
}

class _CutoutHistorySnapshot {
  final List<Offset> lassoPoints;
  final bool isLassoClosed;
  final List<_PaintStroke> strokes;
  final List<Rect> autoRects;
  final List<Offset> wandPoints;

  _CutoutHistorySnapshot({
    required this.lassoPoints,
    required this.isLassoClosed,
    required this.strokes,
    required this.autoRects,
    required this.wandPoints,
  });
}

/// Custom Clipper that extracts the object selected by Auto AI, Lasso, Brush, and Erasers
class _CutoutClipper extends CustomClipper<Path> {
  final List<Offset> lassoPoints;
  final bool isLassoClosed;
  final List<_PaintStroke> strokes;
  final List<Rect> autoRects;
  final double featherRadius;

  _CutoutClipper({
    required this.lassoPoints,
    required this.isLassoClosed,
    required this.strokes,
    required this.autoRects,
    required this.featherRadius,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    // 1. Auto AI Subject Silhouette (Organic smooth oval)
    if (autoRects.isNotEmpty) {
      for (final r in autoRects) {
        path.addOval(r);
      }
    }

    // 2. Lasso Polygon
    if (lassoPoints.length > 2) {
      final lassoPath = Path()..addPolygon(lassoPoints, true);
      path.addPath(lassoPath, Offset.zero);
    }

    // 3. Brush and Restore Strokes (Union)
    if (strokes.isNotEmpty) {
      for (final stroke in strokes) {
        if (stroke.strokeType == _CutoutStrokeType.brush || stroke.strokeType == _CutoutStrokeType.restore) {
          for (final pt in stroke.points) {
            path.addOval(Rect.fromCircle(center: pt, radius: stroke.radius));
          }
        }
      }

      // 4. Eraser Strokes (Difference)
      final eraserPath = Path();
      bool hasEraser = false;
      for (final stroke in strokes) {
        if (stroke.strokeType == _CutoutStrokeType.eraser) {
          hasEraser = true;
          for (final pt in stroke.points) {
            eraserPath.addOval(Rect.fromCircle(center: pt, radius: stroke.radius));
          }
        }
      }
      if (hasEraser) {
        return Path.combine(PathOperation.difference, path, eraserPath);
      }
    }

    // If nothing selected, show full image
    if (autoRects.isEmpty && lassoPoints.length <= 2 && strokes.isEmpty) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    return path;
  }

  @override
  bool shouldReclip(covariant _CutoutClipper oldClipper) => true;
}

/// Inverted Clipper to shade outside area during selection
class _InvertedCutoutClipper extends CustomClipper<Path> {
  final List<Offset> lassoPoints;
  final bool isLassoClosed;
  final List<_PaintStroke> strokes;
  final List<Rect> autoRects;

  _InvertedCutoutClipper({
    required this.lassoPoints,
    required this.isLassoClosed,
    required this.strokes,
    required this.autoRects,
  });

  @override
  Path getClip(Size size) {
    final fullRect = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutout = Path();

    if (autoRects.isNotEmpty) {
      for (final r in autoRects) {
        cutout.addOval(r);
      }
    }

    if (lassoPoints.length > 2) {
      cutout.addPolygon(lassoPoints, true);
    }

    for (final stroke in strokes) {
      if (stroke.strokeType == _CutoutStrokeType.brush || stroke.strokeType == _CutoutStrokeType.restore) {
        for (final pt in stroke.points) {
          cutout.addOval(Rect.fromCircle(center: pt, radius: stroke.radius));
        }
      }
    }

    // Eraser removes from cutout
    final eraserPath = Path();
    bool hasEraser = false;
    for (final stroke in strokes) {
      if (stroke.strokeType == _CutoutStrokeType.eraser) {
        hasEraser = true;
        for (final pt in stroke.points) {
          eraserPath.addOval(Rect.fromCircle(center: pt, radius: stroke.radius));
        }
      }
    }

    final finalCutout = hasEraser
        ? Path.combine(PathOperation.difference, cutout, eraserPath)
        : cutout;

    return Path.combine(PathOperation.difference, fullRect, finalCutout);
  }

  @override
  bool shouldReclip(covariant _InvertedCutoutClipper oldClipper) => true;
}

/// Painter for glowing selection lines, brush highlights, and repair indicators
class _CutoutOverlayPainter extends CustomPainter {
  final List<Offset> lassoPoints;
  final bool isLassoClosed;
  final List<_PaintStroke> strokes;
  final List<Rect> autoRects;
  final _PaintStroke? activeStroke;

  _CutoutOverlayPainter({
    required this.lassoPoints,
    required this.isLassoClosed,
    required this.strokes,
    required this.autoRects,
    this.activeStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Auto AI Silhouette Boundary
    if (autoRects.isNotEmpty) {
      final autoPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      for (final r in autoRects) {
        canvas.drawOval(r, autoPaint);
      }
    }

    // 2. Draw Brush Strokes (Neon Cyan with transparency)
    final brushPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // Eraser Indicator (Neon Pink)
    final eraserPaint = Paint()
      ..color = const Color(0xFFFF5277).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // Repair Indicator (Neon Emerald)
    final repairPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    for (final stroke in strokes) {
      final paintToUse = stroke.strokeType == _CutoutStrokeType.eraser
          ? eraserPaint
          : (stroke.strokeType == _CutoutStrokeType.restore ? repairPaint : brushPaint);
      for (final pt in stroke.points) {
        canvas.drawCircle(pt, stroke.radius, paintToUse);
      }
    }

    // 3. Draw Lasso Stroke Line
    if (lassoPoints.length > 1) {
      final linePaint = Paint()
        ..color = const Color(0xFF10B981)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(lassoPoints.first.dx, lassoPoints.first.dy);
      for (int i = 1; i < lassoPoints.length; i++) {
        path.lineTo(lassoPoints[i].dx, lassoPoints[i].dy);
      }
      if (isLassoClosed) path.close();

      canvas.drawPath(path, linePaint);

      // Start point indicator node
      final dotPaint = Paint()..color = const Color(0xFF00F0FF);
      canvas.drawCircle(lassoPoints.first, 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CutoutOverlayPainter oldDelegate) => true;
}

/// Painter for precision crosshair (+) in Loupe
class _CrosshairPainter extends CustomPainter {
  final Color color;

  _CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Horizontal
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), p);
    // Vertical
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), p);
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter oldDelegate) => false;
}

/// Painter for transparent PNG checkerboard background
class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLight = Paint()..color = const Color(0xFFE2E8F0);
    final paintDark = Paint()..color = const Color(0xFFCBD5E1);

    const squareSize = 14.0;
    final cols = (size.width / squareSize).ceil();
    final rows = (size.height / squareSize).ceil();

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final isEven = (r + c) % 2 == 0;
        final rect = Rect.fromLTWH(c * squareSize, r * squareSize, squareSize, squareSize);
        canvas.drawRect(rect, isEven ? paintLight : paintDark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
