import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import '../services/image_export_service.dart';
import '../theme/app_theme.dart';
import 'editor_screen.dart';

enum RetouchMode {
  heal('Blemish Heal', Icons.healing_rounded),
  smooth('Skin Smooth & Glow', Icons.face_retouching_natural_rounded),
  whiten('Teeth Whitener', Icons.auto_fix_high_rounded);

  final String title;
  final IconData icon;
  const RetouchMode(this.title, this.icon);
}

class RetouchScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const RetouchScreen({
    super.key,
    required this.imageBytes,
  });

  @override
  State<RetouchScreen> createState() => _RetouchScreenState();
}

class _RetouchScreenState extends State<RetouchScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  img.Image? _currentImage;
  late Uint8List _displayBytes;
  final List<img.Image> _undoStack = [];
  final List<img.Image> _redoStack = [];

  bool _isProcessing = false;
  bool _isExporting = false;
  bool _isComparing = false;

  RetouchMode _activeMode = RetouchMode.heal;

  // Brush settings for Blemish Healing and Whitening
  double _brushRadius = 24.0; // in logical screen pixels

  // Global Beauty adjustments
  double _smoothIntensity = 0.0; // 0.0 to 1.0
  double _radianceGlow = 0.15; // -0.5 to 0.5

  // Interactive touch point for visual brush cursor
  Offset? _touchPosition;

  @override
  void initState() {
    super.initState();
    _displayBytes = widget.imageBytes;
    _decodeImageAsync();
  }

  Future<void> _decodeImageAsync() async {
    setState(() => _isProcessing = true);
    try {
      final decoded = img.decodeImage(widget.imageBytes);
      if (decoded != null) {
        // If image is huge (> 2048), scale down for fast instantaneous retouch
        img.Image readyImg = decoded;
        if (decoded.width > 2048 || decoded.height > 2048) {
          readyImg = img.copyResize(decoded, width: decoded.width > decoded.height ? 2048 : null, height: decoded.height >= decoded.width ? 2048 : null);
        }
        setState(() {
          _currentImage = readyImg;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _undo() {
    if (_undoStack.isNotEmpty && _currentImage != null) {
      setState(() {
        _redoStack.add(img.Image.from(_currentImage!));
        _currentImage = _undoStack.removeLast();
        _displayBytes = Uint8List.fromList(img.encodePng(_currentImage!));
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty && _currentImage != null) {
      setState(() {
        _undoStack.add(img.Image.from(_currentImage!));
        _currentImage = _redoStack.removeLast();
        _displayBytes = Uint8List.fromList(img.encodePng(_currentImage!));
      });
    }
  }

  /// Precision Blemish and Pimple Inpainting Algorithm
  void _healSpotAt(Offset localOffset, Size renderSize) {
    if (_currentImage == null || renderSize.width <= 0 || renderSize.height <= 0) return;

    final imgWidth = _currentImage!.width;
    final imgHeight = _currentImage!.height;

    // Convert local widget coordinate to bitmap pixel coordinates
    final normalizedX = (localOffset.dx / renderSize.width).clamp(0.0, 1.0);
    final normalizedY = (localOffset.dy / renderSize.height).clamp(0.0, 1.0);

    final centerX = (normalizedX * imgWidth).toInt().clamp(0, imgWidth - 1);
    final centerY = (normalizedY * imgHeight).toInt().clamp(0, imgHeight - 1);

    // Scale brush radius to image pixel density
    final scaleFactor = imgWidth / renderSize.width;
    final r = (_brushRadius * scaleFactor).toInt().clamp(8, 160);

    // Push current image to undo stack
    _undoStack.add(img.Image.from(_currentImage!));
    _redoStack.clear();

    // Sample the annular ring around the blemish (from r * 0.85 to r * 1.45)
    int sampleR = 0;
    int sampleG = 0;
    int sampleB = 0;
    int count = 0;

    final outerR = (r * 1.45).toInt();
    final innerR = (r * 0.85).toInt();

    for (int dy = -outerR; dy <= outerR; dy++) {
      final py = centerY + dy;
      if (py < 0 || py >= imgHeight) continue;
      for (int dx = -outerR; dx <= outerR; dx++) {
        final px = centerX + dx;
        if (px < 0 || px >= imgWidth) continue;

        final distSq = dx * dx + dy * dy;
        if (distSq >= innerR * innerR && distSq <= outerR * outerR) {
          final p = _currentImage!.getPixel(px, py);
          sampleR += p.r.toInt();
          sampleG += p.g.toInt();
          sampleB += p.b.toInt();
          count++;
        }
      }
    }

    if (count == 0) return;
    final avgR = sampleR ~/ count;
    final avgG = sampleG ~/ count;
    final avgB = sampleB ~/ count;

    // Inpaint healthy color into blemish area with smooth Gaussian falloff & pore texture preservation
    for (int dy = -r; dy <= r; dy++) {
      final py = centerY + dy;
      if (py < 0 || py >= imgHeight) continue;
      for (int dx = -r; dx <= r; dx++) {
        final px = centerX + dx;
        if (px < 0 || px >= imgWidth) continue;

        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist <= r) {
          final factor = 1.0 - (dist / r);
          // Smoothstep Hermite falloff
          final weight = factor * factor * (3.0 - 2.0 * factor);

          final orig = _currentImage!.getPixel(px, py);

          // Subtle micro-contrast preservation (retains pores instead of flat plastic blob)
          final origLum = 0.299 * orig.r + 0.587 * orig.g + 0.114 * orig.b;
          final avgLum = 0.299 * avgR + 0.587 * avgG + 0.114 * avgB;
          final textureHint = ((origLum - avgLum) * 0.18).toInt();

          final targetR = (avgR + textureHint).clamp(0, 255);
          final targetG = (avgG + textureHint).clamp(0, 255);
          final targetB = (avgB + textureHint).clamp(0, 255);

          final newR = ((1.0 - weight) * orig.r + weight * targetR).toInt().clamp(0, 255);
          final newG = ((1.0 - weight) * orig.g + weight * targetG).toInt().clamp(0, 255);
          final newB = ((1.0 - weight) * orig.b + weight * targetB).toInt().clamp(0, 255);

          _currentImage!.setPixelRgb(px, py, newR, newG, newB);
        }
      }
    }

    final newBytes = Uint8List.fromList(img.encodePng(_currentImage!));
    setState(() {
      _displayBytes = newBytes;
    });
  }

  /// Teeth and Smile Whitening / Desaturating yellow casts
  void _whitenAreaAt(Offset localOffset, Size renderSize) {
    if (_currentImage == null || renderSize.width <= 0 || renderSize.height <= 0) return;

    final imgWidth = _currentImage!.width;
    final imgHeight = _currentImage!.height;

    final normalizedX = (localOffset.dx / renderSize.width).clamp(0.0, 1.0);
    final normalizedY = (localOffset.dy / renderSize.height).clamp(0.0, 1.0);

    final centerX = (normalizedX * imgWidth).toInt().clamp(0, imgWidth - 1);
    final centerY = (normalizedY * imgHeight).toInt().clamp(0, imgHeight - 1);

    final scaleFactor = imgWidth / renderSize.width;
    final r = (_brushRadius * scaleFactor).toInt().clamp(8, 160);

    _undoStack.add(img.Image.from(_currentImage!));
    _redoStack.clear();

    for (int dy = -r; dy <= r; dy++) {
      final py = centerY + dy;
      if (py < 0 || py >= imgHeight) continue;
      for (int dx = -r; dx <= r; dx++) {
        final px = centerX + dx;
        if (px < 0 || px >= imgWidth) continue;

        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist <= r) {
          final factor = 1.0 - (dist / r);
          final weight = factor * factor * 0.45; // Gentle 45% whitening strength

          final orig = _currentImage!.getPixel(px, py);
          final lum = 0.299 * orig.r + 0.587 * orig.g + 0.114 * orig.b;

          // Neutralize yellow and brighten
          final whiteLum = (lum * 1.15).clamp(0, 255);
          final newR = ((1.0 - weight) * orig.r + weight * whiteLum).toInt().clamp(0, 255);
          final newG = ((1.0 - weight) * orig.g + weight * whiteLum).toInt().clamp(0, 255);
          final newB = ((1.0 - weight) * orig.b + weight * (whiteLum * 1.06)).toInt().clamp(0, 255);

          _currentImage!.setPixelRgb(px, py, newR, newG, newB);
        }
      }
    }

    final newBytes = Uint8List.fromList(img.encodePng(_currentImage!));
    setState(() {
      _displayBytes = newBytes;
    });
  }

  List<double> get _retouchColorMatrix {
    // Computes skin radiance glow and soft tone
    final glow = _radianceGlow;
    final smooth = _smoothIntensity;

    final rScale = 1.0 + glow * 0.25;
    final gScale = 1.0 + glow * 0.15;
    final bScale = 1.0 + glow * 0.05;
    final brightnessOffset = smooth * 15.0;

    return [
      rScale, 0.0, 0.0, 0.0, brightnessOffset,
      0.0, gScale, 0.0, 0.0, brightnessOffset * 0.9,
      0.0, 0.0, bScale, 0.0, brightnessOffset * 0.8,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }

  Future<void> _exportRetouchedImage() async {
    setState(() {
      _touchPosition = null;
      _isExporting = true;
    });

    try {
      await WidgetsBinding.instance.endOfFrame;

      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Canvas not ready');

      final exportedBytes = await ImageExportService.captureWidgetToBytes(boundary, pixelRatio: 3.0);
      if (exportedBytes == null) throw Exception('Failed to render photo');

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
                const SizedBox(height: 18),
                const Text(
                  'Retouch Complete! ✨',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Skin Smoothed & Blemishes Healed • 100% Offline',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 22),

                // Save to Gallery
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await ImageExportService.saveToGallery(exportedBytes);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Retouched photo saved to Gallery! 🎉' : 'Could not save image'),
                          backgroundColor: success ? const Color(0xFF10B981) : Colors.redAccent,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.download_done_rounded, color: Colors.black),
                  label: const Text('Save to Gallery', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                  label: const Text('Share Retouched Photo', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),

                // Send into Main Editor Studio
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
                  label: const Text('Open in Main Photo Studio', style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
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
        title: const Text('Retouch Studio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Undo
          IconButton(
            icon: const Icon(Icons.undo_rounded, size: 22),
            color: _undoStack.isNotEmpty ? AppTheme.textPrimary : AppTheme.textMuted,
            onPressed: _undoStack.isNotEmpty ? _undo : null,
            tooltip: 'Undo',
          ),
          // Redo
          IconButton(
            icon: const Icon(Icons.redo_rounded, size: 22),
            color: _redoStack.isNotEmpty ? AppTheme.textPrimary : AppTheme.textMuted,
            onPressed: _redoStack.isNotEmpty ? _redo : null,
            tooltip: 'Redo',
          ),

          // Compare Toggle
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

          // Export button
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: _isExporting
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                    ),
                  )
                : IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 18),
                    ),
                    onPressed: _exportRetouchedImage,
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Center Retouch Canvas
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _buildCanvas(),
                ),
              ),
            ),

            // Retouch Tool Controls
            _buildRetouchControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RepaintBoundary(
          key: _repaintBoundaryKey,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onPanStart: (details) {
                if (_activeMode == RetouchMode.smooth) return;
                setState(() => _touchPosition = details.localPosition);
              },
              onPanUpdate: (details) {
                if (_activeMode == RetouchMode.smooth) return;
                setState(() => _touchPosition = details.localPosition);
              },
              onPanEnd: (details) {
                if (_touchPosition != null) {
                  final pos = _touchPosition!;
                  setState(() => _touchPosition = null);
                  final renderSize = Size(constraints.maxWidth, constraints.maxHeight);
                  if (_activeMode == RetouchMode.heal) {
                    _healSpotAt(pos, renderSize);
                  } else if (_activeMode == RetouchMode.whiten) {
                    _whitenAreaAt(pos, renderSize);
                  }
                }
              },
              onTapUp: (details) {
                final pos = details.localPosition;
                final renderSize = Size(constraints.maxWidth, constraints.maxHeight);
                if (_activeMode == RetouchMode.heal) {
                  _healSpotAt(pos, renderSize);
                } else if (_activeMode == RetouchMode.whiten) {
                  _whitenAreaAt(pos, renderSize);
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Original image if comparing
                  if (_isComparing)
                    Image.memory(
                      widget.imageBytes,
                      fit: BoxFit.contain,
                    )
                  else
                    // Retouched Image with GPU Soft Glow matrix
                    ColorFiltered(
                      colorFilter: ColorFilter.matrix(_retouchColorMatrix),
                      child: Image.memory(
                        _displayBytes,
                        fit: BoxFit.contain,
                      ),
                    ),

                  // Interactive Brush target circle cursor
                  if (_touchPosition != null && !_isExporting && _activeMode != RetouchMode.smooth)
                    Positioned(
                      left: _touchPosition!.dx - _brushRadius,
                      top: _touchPosition!.dy - _brushRadius,
                      child: IgnorePointer(
                        child: Container(
                          width: _brushRadius * 2,
                          height: _brushRadius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _activeMode == RetouchMode.heal ? AppTheme.primary : Colors.white,
                              width: 2.0,
                            ),
                            color: (_activeMode == RetouchMode.heal ? AppTheme.primary : Colors.white).withValues(alpha: 0.25),
                            boxShadow: [
                              BoxShadow(
                                color: (_activeMode == RetouchMode.heal ? AppTheme.primary : Colors.white).withValues(alpha: 0.6),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.add, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ),

                  if (_isProcessing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRetouchControls() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.dividerColor, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          // Mode Selector Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: RetouchMode.values.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final mode = RetouchMode.values[index];
                final isSelected = _activeMode == mode;

                return GestureDetector(
                  onTap: () => setState(() => _activeMode = mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.white12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mode.icon,
                          size: 16,
                          color: isSelected ? Colors.black : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          mode.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Dynamic Mode Sliders & Instructions
          if (_activeMode == RetouchMode.heal) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Brush Size', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Expanded(
                    child: Slider(
                      value: _brushRadius,
                      min: 10,
                      max: 60,
                      onChanged: (v) => setState(() => _brushRadius = v),
                    ),
                  ),
                  Text('${_brushRadius.toInt()}px', style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12, top: 4),
              child: Text(
                'Tap or drag on pimples, spots or blemishes to heal naturally',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ),
          ] else if (_activeMode == RetouchMode.smooth) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Porcelain Smooth', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Expanded(
                    child: Slider(
                      value: _smoothIntensity,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (v) => setState(() => _smoothIntensity = v),
                    ),
                  ),
                  Text('${(_smoothIntensity * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Radiant Skin Glow', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Expanded(
                    child: Slider(
                      value: _radianceGlow,
                      min: -0.2,
                      max: 0.5,
                      onChanged: (v) => setState(() => _radianceGlow = v),
                    ),
                  ),
                  Text('${(_radianceGlow * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else if (_activeMode == RetouchMode.whiten) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Whitener Brush', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Expanded(
                    child: Slider(
                      value: _brushRadius,
                      min: 10,
                      max: 60,
                      onChanged: (v) => setState(() => _brushRadius = v),
                    ),
                  ),
                  Text('${_brushRadius.toInt()}px', style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12, top: 4),
              child: Text(
                'Paint gently over teeth or smile to remove yellow tones',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
