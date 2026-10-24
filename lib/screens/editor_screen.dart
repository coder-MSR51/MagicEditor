import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import '../models/editor_state.dart';
import '../models/prop_layer_model.dart';
import '../models/text_layer_model.dart';
import '../services/image_export_service.dart';
import '../services/admob_service.dart';
import '../theme/app_theme.dart';
import '../utils/filter_presets.dart';
import '../widgets/adjustment_slider_bar.dart';
import '../widgets/background_frame_widget.dart';
import '../widgets/background_selector_bar.dart';
import '../widgets/crop_overlay_widget.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/filter_selector_bar.dart';
import '../widgets/frame_selector_bar.dart';
import '../widgets/split_comparison_view.dart';
import '../widgets/stickers/prop_overlay_widget.dart';
import '../widgets/stickers/prop_picker_sheet.dart';
import '../widgets/text_overlay_widget.dart';
import '../models/editor_template_model.dart';
import '../widgets/editor_template_overlay.dart';

enum EditorTab {
  template,
  original,
  cropRatio,
  frame,
  text,
  adjust,
  filters,
  props,
  background,
  doodle,
}

class EditorScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final EditorTemplate? initialTemplate;

  const EditorScreen({
    super.key,
    required this.imageBytes,
    this.initialTemplate,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // State & History
  late Uint8List _currentImageBytes;
  final List<Uint8List> _imageUndoStack = [];
  final List<Uint8List> _imageRedoStack = [];
  late EditorState _currentState;
  final List<EditorState> _undoStack = [];
  final List<EditorState> _redoStack = [];

  // Active Tool Tab
  EditorTab _activeTab = EditorTab.filters;

  // Comparison mode
  bool _isComparing = false;

  // Crop state
  Rect _normalizedCropRect = const Rect.fromLTWH(0, 0, 1, 1);
  double? _cropTargetAspectRatio;
  Size _imageSize = const Size(1000, 1000);
  bool _isProcessingCrop = false;

  // Drawing settings
  Color _drawColor = AppTheme.primary;
  double _drawStrokeWidth = 4.0;
  bool _isNeon = false;

  // Selected Text Layer
  String? _selectedTextId;

  // Selected Prop Layer
  String? _selectedPropId;

  // Selected Template Category
  EditorTemplateCategory _selectedTemplateCategory = EditorTemplateCategory.all;

  // Exporting state
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _currentImageBytes = widget.imageBytes;
    if (widget.initialTemplate != null && widget.initialTemplate != EditorTemplate.none) {
      _currentState = EditorState.initial().copyWith(
        activeTemplate: widget.initialTemplate,
      );
      _activeTab = EditorTab.template;
      _selectedTemplateCategory = widget.initialTemplate!.category;
    } else {
      _currentState = EditorState.initial();
    }
    _loadImageSize();
  }

  void _loadImageSize() {
    decodeImageFromList(_currentImageBytes).then((info) {
      if (mounted) {
        setState(() {
          _imageSize = Size(info.width.toDouble(), info.height.toDouble());
        });
      }
    });
  }

  void _pushHistory(EditorState newState) {
    setState(() {
      _undoStack.add(_currentState);
      _redoStack.clear();
      _currentState = newState;
    });
  }

  bool get _hasAnyEdits => _currentState.hasChanges || _imageUndoStack.isNotEmpty;
  bool get _canUndo => _imageUndoStack.isNotEmpty || _undoStack.isNotEmpty;
  bool get _canRedo => _imageRedoStack.isNotEmpty || _redoStack.isNotEmpty;

  void _undo() {
    if (_imageUndoStack.isNotEmpty) {
      setState(() {
        _imageRedoStack.add(_currentImageBytes);
        _currentImageBytes = _imageUndoStack.removeLast();
        _normalizedCropRect = const Rect.fromLTWH(0, 0, 1, 1);
        _cropTargetAspectRatio = null;
      });
      _loadImageSize();
    } else if (_undoStack.isNotEmpty) {
      setState(() {
        _redoStack.add(_currentState);
        _currentState = _undoStack.removeLast();
      });
    }
  }

  void _redo() {
    if (_imageRedoStack.isNotEmpty) {
      setState(() {
        _imageUndoStack.add(_currentImageBytes);
        _currentImageBytes = _imageRedoStack.removeLast();
        _normalizedCropRect = const Rect.fromLTWH(0, 0, 1, 1);
        _cropTargetAspectRatio = null;
      });
      _loadImageSize();
    } else if (_redoStack.isNotEmpty) {
      setState(() {
        _undoStack.add(_currentState);
        _currentState = _redoStack.removeLast();
      });
    }
  }

  Future<void> _applyCrop() async {
    // If not modified (almost 0, 0, 1, 1), do nothing
    if ((_normalizedCropRect.left <= 0.005) &&
        (_normalizedCropRect.top <= 0.005) &&
        (_normalizedCropRect.right >= 0.995) &&
        (_normalizedCropRect.bottom >= 0.995)) {
      return;
    }

    setState(() => _isProcessingCrop = true);

    try {
      final rect = _normalizedCropRect;
      Uint8List? newBytes;

      // 1. Fast GPU / Skia native crop via dart:ui (< 80ms)
      try {
        final codec = await ui.instantiateImageCodec(_currentImageBytes);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;

        final imgW = uiImage.width.toDouble();
        final imgH = uiImage.height.toDouble();

        final srcX = (rect.left * imgW).clamp(0.0, imgW - 1.0);
        final srcY = (rect.top * imgH).clamp(0.0, imgH - 1.0);
        final srcW = (rect.width * imgW).clamp(1.0, imgW - srcX);
        final srcH = (rect.height * imgH).clamp(1.0, imgH - srcY);

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, srcW, srcH));
        final paint = Paint()..filterQuality = FilterQuality.high;

        canvas.drawImageRect(
          uiImage,
          Rect.fromLTWH(srcX, srcY, srcW, srcH),
          Rect.fromLTWH(0, 0, srcW, srcH),
          paint,
        );

        final picture = recorder.endRecording();
        final croppedUiImage = await picture.toImage(srcW.round(), srcH.round());
        final byteData = await croppedUiImage.toByteData(format: ui.ImageByteFormat.png);

        croppedUiImage.dispose();
        picture.dispose();
        uiImage.dispose();

        if (byteData != null) {
          newBytes = byteData.buffer.asUint8List();
        }
      } catch (uiErr) {
        debugPrint('dart:ui crop failed, attempting isolate fallback: $uiErr');
      }

      // 2. Isolate fallback if dart:ui couldn't encode
      newBytes ??= await compute(_cropFallbackInIsolate, {
        'bytes': _currentImageBytes,
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height,
      });

      if (newBytes != null && mounted) {
        setState(() {
          _imageUndoStack.add(_currentImageBytes);
          _imageRedoStack.clear();
          _currentImageBytes = newBytes!;
          _normalizedCropRect = const Rect.fromLTWH(0, 0, 1, 1);
          _cropTargetAspectRatio = null;
        });
        _loadImageSize();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text('Cropped successfully!'),
                ],
              ),
              duration: Duration(milliseconds: 900),
              backgroundColor: AppTheme.surface,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Crop error: $e');
    } finally {
      if (mounted) setState(() => _isProcessingCrop = false);
    }
  }

  static Uint8List? _cropFallbackInIsolate(Map<String, dynamic> params) {
    try {
      final bytes = params['bytes'] as Uint8List;
      final left = params['left'] as double;
      final top = params['top'] as double;
      final width = params['width'] as double;
      final height = params['height'] as double;

      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final cropX = (left * decoded.width).round().clamp(0, decoded.width - 1);
      final cropY = (top * decoded.height).round().clamp(0, decoded.height - 1);
      final cropW = (width * decoded.width).round().clamp(1, decoded.width - cropX);
      final cropH = (height * decoded.height).round().clamp(1, decoded.height - cropY);

      final cropped = img.copyCrop(
        decoded,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      return Uint8List.fromList(img.encodeJpg(cropped, quality: 96));
    } catch (e) {
      return null;
    }
  }

  List<double> get _activeColorMatrix {
    return FilterPresets.calculateCombinedMatrix(
      filterMatrix: _currentState.filter.matrix,
      filterIntensity: _currentState.filterIntensity,
      brightness: _currentState.brightness,
      contrast: _currentState.contrast,
      saturation: _currentState.saturation,
      warmth: _currentState.warmth,
      tint: _currentState.tint,
    );
  }

  Future<void> _exportImage() async {
    // 1. If on Original tab or if no edits were made, export pristine bytes directly without rendering delay!
    final bool isOriginalOnly = _activeTab == EditorTab.original ||
        (!_currentState.hasChanges && _imageUndoStack.isEmpty);

    if (isOriginalOnly) {
      final exportBytes = _activeTab == EditorTab.original ? widget.imageBytes : _currentImageBytes;
      _showExportBottomSheet(exportBytes, isOriginal: true);
      return;
    }

    setState(() {
      _selectedTextId = null;
      _selectedPropId = null;
      _isExporting = true;
    });

    try {
      // Allow frame to render without selection handles
      await WidgetsBinding.instance.endOfFrame;

      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      Uint8List? exportedBytes;

      if (boundary != null) {
        exportedBytes = await ImageExportService.captureWidgetToBytes(boundary, pixelRatio: 3.0);
      }

      // Safe fallback if boundary capture didn't produce bytes
      exportedBytes ??= _currentImageBytes;

      if (!mounted) return;
      _showExportBottomSheet(exportedBytes, isOriginal: false);
    } catch (e) {
      debugPrint('Export capture error: $e');
      if (mounted) {
        // Fallback to current image bytes so user can still save
        _showExportBottomSheet(_currentImageBytes, isOriginal: false);
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showExportBottomSheet(Uint8List exportedBytes, {bool isOriginal = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                const SizedBox(height: 18),
                Text(
                  isOriginal ? 'Photo Ready to Save! 📸' : 'Magic Edit Ready! ✨',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isOriginal
                      ? '100% Original High-Resolution & No Watermark'
                      : '100% High-Resolution & No Watermark',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Save to Gallery
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 22),
                    label: const Text(
                      'Save to Gallery',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      final success = await ImageExportService.saveToGallery(exportedBytes);
                      if (success) {
                        AdMobService.instance.showInterstitialAd();
                      }
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Saved to Gallery in "Photo Magic" album! 🎉'
                                : 'Failed to save. Please check storage permission.',
                          ),
                          backgroundColor: success ? Colors.green : Colors.redAccent,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Share to Social Media
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 20, color: AppTheme.primary),
                    label: const Text(
                      'Share to Instagram / WhatsApp',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await ImageExportService.shareImage(exportedBytes);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  TextStyle _getGoogleFontStyle(String fontFamily, TextStyle baseStyle) {
    switch (fontFamily.toLowerCase()) {
      case 'poppins':
        return GoogleFonts.poppins(textStyle: baseStyle);
      case 'inter':
        return GoogleFonts.inter(textStyle: baseStyle);
      case 'orbitron':
        return GoogleFonts.orbitron(textStyle: baseStyle);
      case 'pacifico':
        return GoogleFonts.pacifico(textStyle: baseStyle);
      case 'oswald':
        return GoogleFonts.oswald(textStyle: baseStyle);
      case 'dancing script':
      case 'dancingscript':
        return GoogleFonts.dancingScript(textStyle: baseStyle);
      case 'cinzel':
        return GoogleFonts.cinzel(textStyle: baseStyle);
      case 'anton':
        return GoogleFonts.anton(textStyle: baseStyle);
      case 'caveat':
        return GoogleFonts.caveat(textStyle: baseStyle);
      case 'bebas neue':
      case 'bebasneue':
        return GoogleFonts.bebasNeue(textStyle: baseStyle);
      default:
        return GoogleFonts.montserrat(textStyle: baseStyle);
    }
  }

  void _addNewTextLayer() {
    _showEditTextDialog(null);
  }

  void _showEditTextDialog([TextLayerModel? layer]) {
    final isNew = layer == null;
    final textController = TextEditingController(text: isNew ? '' : layer.text);
    Color selectedColor = isNew ? Colors.white : layer.color;
    String selectedFont = isNew ? AppTheme.fontStyleNotifier.value : layer.fontFamily;
    double selectedScale = isNew ? 1.0 : layer.scale;

    const availableFonts = [
      {'name': 'Poppins', 'tag': 'Modern'},
      {'name': 'Inter', 'tag': 'Clean'},
      {'name': 'Cinzel', 'tag': 'Luxury'},
      {'name': 'Dancing Script', 'tag': 'Cursive'},
      {'name': 'Orbitron', 'tag': 'Futuristic'},
      {'name': 'Pacifico', 'tag': 'Casual'},
      {'name': 'Oswald', 'tag': 'Bold'},
      {'name': 'Bebas Neue', 'tag': 'Poster'},
      {'name': 'Caveat', 'tag': 'Script'},
      {'name': 'Montserrat', 'tag': 'Clean'},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(isNew ? 'Add Text Sticker' : 'Edit Text Sticker', style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dynamic live preview text field
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selectedColor == Colors.black ? Colors.white38 : selectedColor.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: textController,
                        autofocus: isNew,
                        textAlign: TextAlign.center,
                        style: _getGoogleFontStyle(
                          selectedFont,
                          TextStyle(
                            color: selectedColor,
                            fontSize: (18 * selectedScale).clamp(15.0, 32.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter text here...',
                          hintStyle: _getGoogleFontStyle(
                            selectedFont,
                            const TextStyle(color: Colors.white38, fontSize: 16),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Font Style Selector Horizontal Strip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Font Style', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                        Text(selectedFont, style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableFonts.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final f = availableFonts[idx];
                          final fontName = f['name']!;
                          final isSelected = selectedFont.toLowerCase() == fontName.toLowerCase();
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() => selectedFont = fontName);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primary : Colors.white12,
                                  width: isSelected ? 1.6 : 1.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                fontName,
                                style: _getGoogleFontStyle(
                                  fontName,
                                  TextStyle(
                                    color: isSelected ? AppTheme.primary : Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Text Size Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Text Size', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text(
                          '${(selectedScale * 100).round()}%',
                          style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: selectedScale.clamp(0.5, 3.5),
                      min: 0.5,
                      max: 3.5,
                      activeColor: AppTheme.primary,
                      inactiveColor: Colors.white24,
                      onChanged: (val) => setDialogState(() => selectedScale = val),
                    ),
                    const SizedBox(height: 8),

                    // Dropdown for full font list
                    DropdownButtonFormField<String>(
                      initialValue: availableFonts.any((f) => f['name']!.toLowerCase() == selectedFont.toLowerCase())
                          ? availableFonts.firstWhere((f) => f['name']!.toLowerCase() == selectedFont.toLowerCase())['name']
                          : 'Montserrat',
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceLight,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: availableFonts.map((f) {
                        final name = f['name']!;
                        final tag = f['tag']!;
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Row(
                            children: [
                              Text(
                                name,
                                style: _getGoogleFontStyle(
                                  name,
                                  const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '($tag)',
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedFont = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Color Palette Quick Picks
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Color', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Colors.white,
                        Colors.black,
                        AppTheme.primary,
                        AppTheme.secondary,
                        AppTheme.accent,
                        Colors.yellowAccent,
                        Colors.orangeAccent,
                        Colors.greenAccent,
                      ].map((col) {
                        final isChosen = selectedColor == col;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = col),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isChosen ? Colors.white : Colors.white24,
                                width: isChosen ? 2.5 : 1.0,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                if (!isNew)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                    label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    onPressed: () {
                      final list = _currentState.textLayers.where((l) => l.id != layer.id).toList();
                      _pushHistory(_currentState.copyWith(textLayers: list));
                      setState(() => _selectedTextId = null);
                      Navigator.pop(dialogContext);
                    },
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final enteredText = textController.text.trim();
                    if (isNew) {
                      if (enteredText.isNotEmpty) {
                        final newId = 'text_${DateTime.now().millisecondsSinceEpoch}';
                        final newLayer = TextLayerModel(
                          id: newId,
                          text: enteredText,
                          color: selectedColor,
                          fontFamily: selectedFont,
                          scale: selectedScale,
                          position: const Offset(80, 160),
                        );
                        _pushHistory(
                          _currentState.copyWith(
                            textLayers: [..._currentState.textLayers, newLayer],
                          ),
                        );
                        setState(() {
                          _selectedTextId = newId;
                        });
                      }
                    } else {
                      final updated = layer.copyWith(
                        text: enteredText.isEmpty ? layer.text : enteredText,
                        color: selectedColor,
                        fontFamily: selectedFont,
                        scale: selectedScale,
                      );
                      final updatedList = _currentState.textLayers.map((l) => l.id == layer.id ? updated : l).toList();
                      _pushHistory(_currentState.copyWith(textLayers: updatedList));
                    }
                    Navigator.pop(dialogContext);
                  },
                  child: Text(isNew ? 'Add' : 'Apply', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasAnyEdits,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldLeave = await _showDiscardDialog();
        if (shouldLeave && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildTopBar(),
        body: SafeArea(
          bottom: true,
          child: Column(
            children: [
              // 1. Center Image Canvas with Edge-to-Edge Responsive layout
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildCanvas(),
                  ),
                ),
              ),

              // 2. Active Tab Control Panel
              _buildToolControls(),

              // 3. Bottom Navigation Tool Bar
              _buildBottomTabBar(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () async {
          if (!_hasAnyEdits) {
            Navigator.pop(context);
          } else {
            final shouldLeave = await _showDiscardDialog();
            if (shouldLeave && mounted) Navigator.pop(context);
          }
        },
      ),
      title: const Text('Photo Magic'),
      actions: [
        // Undo
        IconButton(
          icon: const Icon(Icons.undo_rounded, size: 22),
          color: _canUndo ? AppTheme.textPrimary : AppTheme.textMuted,
          onPressed: _canUndo ? _undo : null,
          tooltip: 'Undo',
        ),

        // Redo
        IconButton(
          icon: const Icon(Icons.redo_rounded, size: 22),
          color: _canRedo ? AppTheme.textPrimary : AppTheme.textMuted,
          onPressed: _canRedo ? _redo : null,
          tooltip: 'Redo',
        ),

        // Before/After Split Compare Toggle
        GestureDetector(
          onTapDown: (_) => setState(() => _isComparing = true),
          onTapUp: (_) => setState(() => _isComparing = false),
          onTapCancel: () => setState(() => _isComparing = false),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isComparing ? AppTheme.primary : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isComparing ? AppTheme.primary : Colors.white12,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.compare_rounded,
                  size: 16,
                  color: _isComparing ? Colors.black : Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'COMPARE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _isComparing ? Colors.black : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Export Button
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: _isExporting
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primary, size: 24),
                  tooltip: 'Export',
                  onPressed: _exportImage,
                ),
        ),
      ],
    );
  }

  Widget _buildCanvas() {
    // Child representing original unedited image
    final originalWidget = Image.memory(
      _currentImageBytes,
      fit: BoxFit.contain,
    );

    if (_isComparing || _activeTab == EditorTab.original) {
      return RepaintBoundary(
        key: _repaintBoundaryKey,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              originalWidget,
              if (!_isExporting)
                Positioned(
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary, width: 1.2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_rounded, color: AppTheme.primary, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'ORIGINAL PHOTO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Child representing edited image
    final editedWidget = Transform.rotate(
      angle: _currentState.rotationAngle * (math.pi / 180),
      child: Transform.flip(
        flipX: _currentState.flipHorizontal,
        flipY: _currentState.flipVertical,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Filter & Color Matrix Render
            ColorFiltered(
              colorFilter: ColorFilter.matrix(_activeColorMatrix),
              child: Image.memory(
                _currentImageBytes,
                fit: BoxFit.contain,
              ),
            ),

            // Vignette Overlay
            if (_currentState.vignette > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 0.85,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: _currentState.vignette * 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Film Grain Overlay (Simulated with subtle dotted texture)
            if (_currentState.grain > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: _currentState.grain * 0.45,
                    child: CustomPaint(
                      painter: _FilmGrainPainter(),
                    ),
                  ),
                ),
              ),

            // Drawing Layer
            Positioned.fill(
              child: DrawingCanvas(
                paths: _currentState.drawPaths,
                currentColor: _drawColor,
                currentStrokeWidth: _drawStrokeWidth,
                isNeon: _isNeon,
                isDrawingEnabled: _activeTab == EditorTab.doodle,
                onPathDrawn: (newPath) {
                  _pushHistory(
                    _currentState.copyWith(
                      drawPaths: [..._currentState.drawPaths, newPath],
                    ),
                  );
                },
              ),
            ),

            // Text Overlays Layer
            Positioned.fill(
              child: TextOverlayWidget(
                textLayers: _currentState.textLayers,
                selectedLayerId: _selectedTextId,
                onSelectLayer: (id) {
                  setState(() => _selectedTextId = id.isEmpty ? null : id);
                },
                onEditLayer: (layer) {
                  _showEditTextDialog(layer);
                },
                onUpdateLayer: (updated) {
                  final list = _currentState.textLayers.map((l) => l.id == updated.id ? updated : l).toList();
                  _pushHistory(_currentState.copyWith(textLayers: list));
                },
                onDeleteLayer: (id) {
                  final list = _currentState.textLayers.where((l) => l.id != id).toList();
                  _pushHistory(_currentState.copyWith(textLayers: list));
                  setState(() => _selectedTextId = null);
                },
              ),
            ),

            // Snapchat Funny Face Props & Creative Overlays Layer
            Positioned.fill(
              child: PropOverlayWidget(
                propLayers: _currentState.propLayers,
                selectedLayerId: _selectedPropId,
                onSelectLayer: (id) {
                  setState(() => _selectedPropId = id);
                },
                onUpdateLayer: (updated) {
                  final list = _currentState.propLayers.map((p) => p.id == updated.id ? updated : p).toList();
                  _pushHistory(_currentState.copyWith(propLayers: list));
                },
                onDeleteLayer: (id) {
                  final list = _currentState.propLayers.where((p) => p.id != id).toList();
                  _pushHistory(_currentState.copyWith(propLayers: list));
                  setState(() => _selectedPropId = null);
                },
              ),
            ),

            // Interactive Crop Overlay with White Border Line
            if (_activeTab == EditorTab.cropRatio)
              Positioned.fill(
                child: CropOverlayWidget(
                  cropRect: _normalizedCropRect,
                  onCropChanged: (newRect) {
                    _normalizedCropRect = newRect;
                  },
                  onApplyCrop: _applyCrop,
                  targetAspectRatio: _cropTargetAspectRatio,
                  imageSize: _imageSize,
                ),
              ),
          ],
        ),
      ),
    );

    // Apply Crop Aspect Ratio if selected
    Widget wrappedCanvas = SplitComparisonView(
      originalChild: originalWidget,
      editedChild: editedWidget,
      isComparing: _isComparing,
    );

    if (_currentState.cropAspectRatio != null) {
      wrappedCanvas = AspectRatio(
        aspectRatio: _currentState.cropAspectRatio!,
        child: wrappedCanvas,
      );
    }

    // Apply Background Frame & Backdrop if active
    wrappedCanvas = BackgroundFrameWidget(
      imageProvider: MemoryImage(_currentImageBytes),
      backgroundType: _currentState.backgroundType,
      backgroundBlur: _currentState.backgroundBlur,
      backgroundGradientIndex: _currentState.backgroundGradientIndex,
      framePadding: _currentState.framePadding,
      frameRadius: _currentState.frameRadius,
      polaroidCaption: _currentState.polaroidCaption,
      child: wrappedCanvas,
    );

    // Apply Dedicated Editor Template Overlay if active
    if (_currentState.activeTemplate != EditorTemplate.none) {
      wrappedCanvas = EditorTemplateOverlay(
        template: _currentState.activeTemplate,
        imageBytes: _currentImageBytes,
        songTitle: _currentState.songTitle,
        artistName: _currentState.artistName,
        child: wrappedCanvas,
      );
    }

    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: wrappedCanvas,
      ),
    );
  }

  Widget _buildToolControls() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.dividerColor, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_activeTab == EditorTab.template) _buildTemplateControlBar(),

          if (_activeTab == EditorTab.original)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: AppTheme.surface,
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Previewing Original Image',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => setState(() => _activeTab = EditorTab.adjust),
                    child: const Text(
                      'Back to Edit',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          if (_activeTab == EditorTab.frame)
            FrameSelectorBar(
              selectedType: _currentState.backgroundType,
              blurAmount: _currentState.backgroundBlur,
              paddingAmount: _currentState.framePadding,
              radiusAmount: _currentState.frameRadius,
              onTypeChanged: (type) {
                _pushHistory(_currentState.copyWith(backgroundType: type));
              },
              onBlurChanged: (v) => setState(() => _currentState = _currentState.copyWith(backgroundBlur: v)),
              onPaddingChanged: (v) => setState(() => _currentState = _currentState.copyWith(framePadding: v)),
              onRadiusChanged: (v) => setState(() => _currentState = _currentState.copyWith(frameRadius: v)),
              onDone: () => setState(() => _activeTab = EditorTab.adjust),
            ),

          if (_activeTab == EditorTab.cropRatio) _buildCropAndTransformBar(),

          if (_activeTab == EditorTab.text) _buildTextControlBar(),

          if (_activeTab == EditorTab.adjust)
            AdjustmentSliderBar(
              brightness: _currentState.brightness,
              contrast: _currentState.contrast,
              saturation: _currentState.saturation,
              warmth: _currentState.warmth,
              tint: _currentState.tint,
              vignette: _currentState.vignette,
              grain: _currentState.grain,
              onBrightnessChanged: (v) => setState(() => _currentState = _currentState.copyWith(brightness: v)),
              onContrastChanged: (v) => setState(() => _currentState = _currentState.copyWith(contrast: v)),
              onSaturationChanged: (v) => setState(() => _currentState = _currentState.copyWith(saturation: v)),
              onWarmthChanged: (v) => setState(() => _currentState = _currentState.copyWith(warmth: v)),
              onTintChanged: (v) => setState(() => _currentState = _currentState.copyWith(tint: v)),
              onVignetteChanged: (v) => setState(() => _currentState = _currentState.copyWith(vignette: v)),
              onGrainChanged: (v) => setState(() => _currentState = _currentState.copyWith(grain: v)),
            ),

          if (_activeTab == EditorTab.filters)
            FilterSelectorBar(
              currentFilter: _currentState.filter,
              filterIntensity: _currentState.filterIntensity,
              thumbnailBytes: _currentImageBytes,
              onSelectFilter: (preset) {
                _pushHistory(
                  _currentState.copyWith(
                    filter: preset,
                    filterIntensity: 1.0,
                  ),
                );
              },
              onIntensityChanged: (intensity) {
                setState(() {
                  _currentState = _currentState.copyWith(filterIntensity: intensity);
                });
              },
            ),

          if (_activeTab == EditorTab.props) _buildPropControlBar(),

          if (_activeTab == EditorTab.background)
            BackgroundSelectorBar(
              selectedType: _currentState.backgroundType,
              blurAmount: _currentState.backgroundBlur,
              gradientIndex: _currentState.backgroundGradientIndex,
              paddingAmount: _currentState.framePadding,
              radiusAmount: _currentState.frameRadius,
              polaroidCaption: _currentState.polaroidCaption,
              onTypeChanged: (type) {
                _pushHistory(_currentState.copyWith(backgroundType: type));
              },
              onBlurChanged: (v) => setState(() => _currentState = _currentState.copyWith(backgroundBlur: v)),
              onGradientChanged: (idx) => _pushHistory(_currentState.copyWith(backgroundGradientIndex: idx)),
              onPaddingChanged: (v) => setState(() => _currentState = _currentState.copyWith(framePadding: v)),
              onRadiusChanged: (v) => setState(() => _currentState = _currentState.copyWith(frameRadius: v)),
              onCaptionChanged: (cap) => setState(() => _currentState = _currentState.copyWith(polaroidCaption: cap)),
            ),

          if (_activeTab == EditorTab.doodle) _buildDoodleControlBar(),
        ],
      ),
    );
  }

  Widget _buildPropControlBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_reaction_outlined, size: 18),
              label: const Text('Add Face Prop / FX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: _showPropPickerSheet,
            ),
          ),
          if (_currentState.propLayers.isNotEmpty) ...[
            const SizedBox(width: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Clear', style: TextStyle(fontSize: 13)),
              onPressed: () {
                _pushHistory(_currentState.copyWith(propLayers: []));
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showPropPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => PropPickerSheet(
        onSelectProp: (propDef) {
          final newProp = PropLayerModel(
            id: 'prop_${DateTime.now().millisecondsSinceEpoch}',
            propId: propDef.id,
            position: const Offset(80, 100),
          );
          _pushHistory(
            _currentState.copyWith(
              propLayers: [..._currentState.propLayers, newProp],
            ),
          );
          setState(() => _selectedPropId = newProp.id);
        },
      ),
    );
  }

  Widget _buildCropAndTransformBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action row: Reset, Hint, and Apply Crop
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  setState(() {
                    _normalizedCropRect = const Rect.fromLTWH(0, 0, 1, 1);
                    _cropTargetAspectRatio = null;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  'Slide white lines to crop',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                icon: _isProcessingCrop
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.check_rounded, size: 18, color: Colors.black),
                label: const Text('Apply Crop', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: _isProcessingCrop ? null : _applyCrop,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Aspect Ratio Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRatioButton('Free', null),
                _buildRatioButton('1:1 (Square)', 1.0),
                _buildRatioButton('4:5 (Insta)', 4 / 5),
                _buildRatioButton('9:16 (Story)', 9 / 16),
                _buildRatioButton('16:9 (Landscape)', 16 / 9),
                _buildRatioButton('3:2', 3 / 2),
                _buildRatioButton('4:3', 4 / 3),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Transform Tools (Rotate & Flip)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.rotate_right_rounded, size: 18, color: AppTheme.primary),
                label: const Text('Rotate 90°', style: TextStyle(color: Colors.white, fontSize: 12)),
                onPressed: () {
                  final nextRotation = (_currentState.rotationAngle + 90) % 360;
                  _pushHistory(_currentState.copyWith(rotationAngle: nextRotation));
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.flip_rounded, size: 18, color: AppTheme.primary),
                label: const Text('Flip H', style: TextStyle(color: Colors.white, fontSize: 12)),
                onPressed: () {
                  _pushHistory(_currentState.copyWith(flipHorizontal: !_currentState.flipHorizontal));
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.swap_vert_rounded, size: 18, color: AppTheme.primary),
                label: const Text('Flip V', style: TextStyle(color: Colors.white, fontSize: 12)),
                onPressed: () {
                  _pushHistory(_currentState.copyWith(flipVertical: !_currentState.flipVertical));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatioButton(String label, double? ratio) {
    final isSelected = _cropTargetAspectRatio == ratio;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppTheme.primary,
        backgroundColor: AppTheme.surfaceLight,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 11,
        ),
        onSelected: (_) {
          setState(() {
            _cropTargetAspectRatio = ratio;
            if (ratio != null) {
              _normalizedCropRect = CropOverlayWidget.calculateRectForAspectRatio(
                targetRatio: ratio,
                imageWidth: _imageSize.width,
                imageHeight: _imageSize.height,
              );
            }
          });
        },
      ),
    );
  }

  Widget _buildTextControlBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Text Sticker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: _addNewTextLayer,
            ),
          ),
          if (_currentState.textLayers.isNotEmpty) ...[
            const SizedBox(width: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Clear', style: TextStyle(fontSize: 13)),
              onPressed: () {
                _pushHistory(_currentState.copyWith(textLayers: []));
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDoodleControlBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Neon Glow Switch
              FilterChip(
                label: const Text('Neon Glow'),
                avatar: Icon(Icons.auto_awesome, size: 14, color: _isNeon ? Colors.black : AppTheme.primary),
                selected: _isNeon,
                selectedColor: AppTheme.primary,
                backgroundColor: AppTheme.surfaceLight,
                labelStyle: TextStyle(
                  color: _isNeon ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                onSelected: (val) => setState(() => _isNeon = val),
              ),
              const SizedBox(width: 12),

              // Stroke Width Slider
              const Icon(Icons.line_weight_rounded, size: 16, color: AppTheme.textSecondary),
              Expanded(
                child: Slider(
                  value: _drawStrokeWidth,
                  min: 2.0,
                  max: 18.0,
                  onChanged: (val) => setState(() => _drawStrokeWidth = val),
                ),
              ),

              // Clear Drawing
              if (_currentState.drawPaths.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                  tooltip: 'Clear Drawing',
                  onPressed: () {
                    _pushHistory(_currentState.copyWith(drawPaths: []));
                  },
                ),
            ],
          ),

          // Color Palette Swatches
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                AppTheme.primary,
                AppTheme.secondary,
                AppTheme.accent,
                Colors.yellowAccent,
                Colors.greenAccent,
                Colors.white,
                Colors.black,
              ].map((c) {
                final isSelected = _drawColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _drawColor = c),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white24,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateControlBar() {
    final filteredTemplates = _selectedTemplateCategory == EditorTemplateCategory.all
        ? EditorTemplate.values
        : [
            EditorTemplate.none,
            ...EditorTemplate.allTemplates.where((t) => t.category == _selectedTemplateCategory),
          ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Category Filter Chips (All, Vogue, Vinyl, Cyber HUD, Music Card)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: EditorTemplateCategory.values.map((cat) {
                final isSelected = _selectedTemplateCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      cat.icon,
                      size: 14,
                      color: isSelected ? Colors.black : AppTheme.primary,
                    ),
                    label: Text(cat.label),
                    selected: isSelected,
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surfaceLight,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedTemplateCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Music Customizer Bar (Spotify Glass, Spatial Audio, 90s Cassette)
          if (_currentState.activeTemplate == EditorTemplate.musicSpotify ||
              _currentState.activeTemplate == EditorTemplate.musicSpatial ||
              _currentState.activeTemplate == EditorTemplate.musicCassette) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: InkWell(
                onTap: _showMusicInfoEditDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D2818), Color(0xFF143825)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.7), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1DB954).withValues(alpha: 0.18),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954).withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.music_note_rounded, color: Color(0xFF1DB954), size: 16),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'NOW PLAYING: ',
                                  style: TextStyle(
                                    color: Color(0xFF1DB954),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _currentState.songTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _currentState.artistName,
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_rounded, color: Colors.black, size: 12),
                            SizedBox(width: 3.5),
                            Text(
                              'Change Song',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // 2. Horizontal Scrollable List of Templates
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: filteredTemplates.length,
              itemBuilder: (context, index) {
                final tmpl = filteredTemplates[index];
                final isSelected = _currentState.activeTemplate == tmpl;

                return GestureDetector(
                  onTap: () {
                    _pushHistory(
                      _currentState.copyWith(activeTemplate: tmpl),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 82,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.12)
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.white12,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: tmpl.gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: tmpl.gradient.first.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(tmpl.icon, color: Colors.white, size: 22),
                            ),
                            if (isSelected)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 11,
                                    color: Colors.black,
                                  ),
                                ),
                              )
                            else if (tmpl.badge != 'Raw')
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: tmpl.gradient.first, width: 0.6),
                                  ),
                                  child: Text(
                                    tmpl.badge,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tmpl.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primary : Colors.white,
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        Text(
                          tmpl.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primary.withValues(alpha: 0.8) : AppTheme.textMuted,
                            fontSize: 8,
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
      ),
    );
  }

  void _showMusicInfoEditDialog() {
    final titleController = TextEditingController(text: _currentState.songTitle);
    final artistController = TextEditingController(text: _currentState.artistName);

    final popularSongs = [
      {'title': 'Golden Hour', 'artist': 'JVKE • Memories Edit'},
      {'title': 'Starboy', 'artist': 'The Weeknd • Daft Punk'},
      {'title': 'Die With A Smile', 'artist': 'Bruno Mars & Lady Gaga'},
      {'title': 'As It Was', 'artist': 'Harry Styles'},
      {'title': 'Tum Hi Ho', 'artist': 'Arijit Singh • Aashiqui 2'},
      {'title': 'Espresso', 'artist': 'Sabrina Carpenter'},
      {'title': 'Until I Found You', 'artist': 'Stephen Sanchez'},
      {'title': 'Perfect', 'artist': 'Ed Sheeran'},
      {'title': 'Night Changes', 'artist': 'One Direction • FOUR'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 18,
                right: 18,
                top: 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF141822),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 20),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.music_note_rounded, color: Color(0xFF1DB954), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customize Music Info',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Add your favorite song & artist to your photo',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Song Title Input
                  const Text('Song Title', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      hintText: 'e.g. Starboy, Golden Hour, Tum Hi Ho...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      prefixIcon: const Icon(Icons.audiotrack_rounded, color: Color(0xFF1DB954), size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                        onPressed: () {
                          titleController.clear();
                          setModalState(() {});
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1DB954), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),

                  const SizedBox(height: 12),

                  // Artist Name Input
                  const Text('Artist / Subtitle', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: artistController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      hintText: 'e.g. The Weeknd, JVKE, Arijit Singh...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.white54, size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                        onPressed: () {
                          artistController.clear();
                          setModalState(() {});
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1DB954), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),

                  const SizedBox(height: 14),

                  // Quick Popular Song Chips
                  const Text(
                    'Quick Presets:',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: popularSongs.map((s) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            side: const BorderSide(color: Colors.white12),
                            label: Text(
                              '${s['title']} • ${s['artist']}',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                            onPressed: () {
                              setModalState(() {
                                titleController.text = s['title']!;
                                artistController.text = s['artist']!;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        foregroundColor: Colors.black,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_rounded, color: Colors.black, size: 20),
                      label: const Text(
                        'Apply to Template',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        final newTitle = titleController.text.trim();
                        final newArtist = artistController.text.trim();
                        _pushHistory(
                          _currentState.copyWith(
                            songTitle: newTitle.isNotEmpty ? newTitle : 'Golden Hour',
                            artistName: newArtist.isNotEmpty ? newArtist : 'JVKE • Memories Edit',
                          ),
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF1DB954),
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              'Music updated: ${newTitle.isNotEmpty ? newTitle : 'Golden Hour'} 🎵',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
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

  Widget _buildBottomTabBar() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.dividerColor, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavTab(EditorTab.template, Icons.auto_awesome_mosaic_rounded, 'Template'),
          _buildNavTab(EditorTab.original, Icons.photo_outlined, 'Original'),
          _buildNavTab(EditorTab.cropRatio, Icons.crop_rotate_rounded, 'Crop'),
          _buildNavTab(EditorTab.frame, Icons.filter_frames_rounded, 'Frame'),
          _buildNavTab(EditorTab.text, Icons.text_fields_rounded, 'Text'),
          _buildNavTab(EditorTab.adjust, Icons.tune_rounded, 'Adjust'),
          _buildSaveNavTab(),
        ],
      ),
    );
  }

  Widget _buildSaveNavTab() {
    return Expanded(
      child: InkWell(
        onTap: _exportImage,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.download_rounded,
                  size: 20,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Save',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab(EditorTab tab, IconData icon, String label) {
    final isSelected = (_activeTab == tab) ||
        (tab == EditorTab.original && _activeTab == EditorTab.filters);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (_activeTab == EditorTab.cropRatio && tab != EditorTab.cropRatio) {
            if ((_normalizedCropRect.left > 0.005) ||
                (_normalizedCropRect.top > 0.005) ||
                (_normalizedCropRect.right < 0.995) ||
                (_normalizedCropRect.bottom < 0.995)) {
              _applyCrop();
            }
          }
          if (tab == EditorTab.original) {
            setState(() {
              if (_activeTab == EditorTab.filters) {
                _currentState = _currentState.copyWith(
                  filter: FilterPresets.all.first,
                  filterIntensity: 1.0,
                );
              } else {
                _activeTab = EditorTab.filters;
              }
            });
          } else {
            setState(() => _activeTab = tab);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showDiscardDialog() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard edits?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You have unsaved edits. Are you sure you want to go back?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing', style: TextStyle(color: AppTheme.primary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return res ?? false;
  }
}

class _FilmGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    final random = math.Random(42); // Seeded for consistency
    final dotsCount = (size.width * size.height * 0.0006).toInt();

    for (int i = 0; i < dotsCount; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      paint.color = Colors.white.withValues(alpha: random.nextDouble() * 0.6);
      canvas.drawCircle(Offset(dx, dy), 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
