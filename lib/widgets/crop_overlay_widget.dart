import 'dart:math' as math;
import 'package:flutter/material.dart';

enum CropHandle {
  none,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
  inside,
}

class CropOverlayWidget extends StatefulWidget {
  final Rect cropRect; // Normalized (0.0 to 1.0)
  final Function(Rect newRect) onCropChanged;
  final VoidCallback? onApplyCrop;
  final double? targetAspectRatio; // width / height in image pixels, or null for free
  final Size imageSize;

  const CropOverlayWidget({
    super.key,
    required this.cropRect,
    required this.onCropChanged,
    this.onApplyCrop,
    this.targetAspectRatio,
    required this.imageSize,
  });

  static Rect calculateRectForAspectRatio({
    required double targetRatio,
    required double imageWidth,
    required double imageHeight,
  }) {
    if (imageWidth <= 0 || imageHeight <= 0) {
      return const Rect.fromLTWH(0, 0, 1, 1);
    }
    final imageAspect = imageWidth / imageHeight;
    final normalizedTargetAspect = targetRatio / imageAspect;

    double w, h;
    if (normalizedTargetAspect >= 1.0) {
      w = 0.92;
      h = w / normalizedTargetAspect;
      if (h > 0.92) {
        h = 0.92;
        w = h * normalizedTargetAspect;
      }
    } else {
      h = 0.92;
      w = h * normalizedTargetAspect;
      if (w > 0.92) {
        w = 0.92;
        h = w / normalizedTargetAspect;
      }
    }
    final left = (1.0 - w) / 2;
    final top = (1.0 - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  @override
  State<CropOverlayWidget> createState() => _CropOverlayWidgetState();
}

class _CropOverlayWidgetState extends State<CropOverlayWidget> {
  CropHandle _activeHandle = CropHandle.none;
  bool _isDragging = false;
  late Rect _currentRect;

  @override
  void initState() {
    super.initState();
    _currentRect = widget.cropRect;
  }

  @override
  void didUpdateWidget(covariant CropOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && widget.cropRect != oldWidget.cropRect) {
      _currentRect = widget.cropRect;
    }
  }

  CropHandle _hitTestHandle(Offset touch, Rect screenRect) {
    const cornerHitRadius = 38.0;
    const edgeHitTolerance = 28.0;

    // Check corners first (highest priority)
    if ((touch - screenRect.topLeft).distance <= cornerHitRadius) {
      return CropHandle.topLeft;
    }
    if ((touch - screenRect.topRight).distance <= cornerHitRadius) {
      return CropHandle.topRight;
    }
    if ((touch - screenRect.bottomLeft).distance <= cornerHitRadius) {
      return CropHandle.bottomLeft;
    }
    if ((touch - screenRect.bottomRight).distance <= cornerHitRadius) {
      return CropHandle.bottomRight;
    }

    // Check edges
    if ((touch.dy - screenRect.top).abs() <= edgeHitTolerance &&
        touch.dx >= screenRect.left - 14 &&
        touch.dx <= screenRect.right + 14) {
      return CropHandle.top;
    }
    if ((touch.dy - screenRect.bottom).abs() <= edgeHitTolerance &&
        touch.dx >= screenRect.left - 14 &&
        touch.dx <= screenRect.right + 14) {
      return CropHandle.bottom;
    }
    if ((touch.dx - screenRect.left).abs() <= edgeHitTolerance &&
        touch.dy >= screenRect.top - 14 &&
        touch.dy <= screenRect.bottom + 14) {
      return CropHandle.left;
    }
    if ((touch.dx - screenRect.right).abs() <= edgeHitTolerance &&
        touch.dy >= screenRect.top - 14 &&
        touch.dy <= screenRect.bottom + 14) {
      return CropHandle.right;
    }

    // Inside box -> Pan whole crop box
    if (screenRect.contains(touch)) {
      return CropHandle.inside;
    }

    return CropHandle.none;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: () => widget.onApplyCrop?.call(),
          onPanStart: (details) {
            final screenRect = Rect.fromLTRB(
              _currentRect.left * size.width,
              _currentRect.top * size.height,
              _currentRect.right * size.width,
              _currentRect.bottom * size.height,
            );
            _activeHandle = _hitTestHandle(details.localPosition, screenRect);
            if (_activeHandle != CropHandle.none) {
              setState(() => _isDragging = true);
            }
          },
          onPanUpdate: (details) {
            if (_activeHandle == CropHandle.none || size.width <= 0 || size.height <= 0) return;

            final dx = details.delta.dx / size.width;
            final dy = details.delta.dy / size.height;

            const minNormalizedSize = 0.08; // Min 8% of image dimension

            double left = _currentRect.left;
            double top = _currentRect.top;
            double right = _currentRect.right;
            double bottom = _currentRect.bottom;

            switch (_activeHandle) {
              case CropHandle.inside:
                final curW = right - left;
                final curH = bottom - top;
                left = (left + dx).clamp(0.0, 1.0 - curW);
                right = left + curW;
                top = (top + dy).clamp(0.0, 1.0 - curH);
                bottom = top + curH;
                break;

              case CropHandle.left:
                left = (left + dx).clamp(0.0, right - minNormalizedSize);
                break;

              case CropHandle.right:
                right = (right + dx).clamp(left + minNormalizedSize, 1.0);
                break;

              case CropHandle.top:
                top = (top + dy).clamp(0.0, bottom - minNormalizedSize);
                break;

              case CropHandle.bottom:
                bottom = (bottom + dy).clamp(top + minNormalizedSize, 1.0);
                break;

              case CropHandle.topLeft:
                left = (left + dx).clamp(0.0, right - minNormalizedSize);
                top = (top + dy).clamp(0.0, bottom - minNormalizedSize);
                break;

              case CropHandle.topRight:
                right = (right + dx).clamp(left + minNormalizedSize, 1.0);
                top = (top + dy).clamp(0.0, bottom - minNormalizedSize);
                break;

              case CropHandle.bottomLeft:
                left = (left + dx).clamp(0.0, right - minNormalizedSize);
                bottom = (bottom + dy).clamp(top + minNormalizedSize, 1.0);
                break;

              case CropHandle.bottomRight:
                right = (right + dx).clamp(left + minNormalizedSize, 1.0);
                bottom = (bottom + dy).clamp(top + minNormalizedSize, 1.0);
                break;

              case CropHandle.none:
                break;
            }

            // If an aspect ratio is locked, adjust adjacent edge on corner drags
            if (widget.targetAspectRatio != null && widget.imageSize.height > 0) {
              final imageAspect = widget.imageSize.width / widget.imageSize.height;
              final targetNormAspect = widget.targetAspectRatio! / imageAspect;

              if (_activeHandle == CropHandle.topLeft ||
                  _activeHandle == CropHandle.topRight ||
                  _activeHandle == CropHandle.bottomLeft ||
                  _activeHandle == CropHandle.bottomRight) {
                final curW = right - left;
                final curH = curW / targetNormAspect;

                if (_activeHandle == CropHandle.bottomRight) {
                  if (top + curH <= 1.0) {
                    bottom = top + curH;
                  } else {
                    bottom = 1.0;
                    right = left + (bottom - top) * targetNormAspect;
                  }
                } else if (_activeHandle == CropHandle.bottomLeft) {
                  if (top + curH <= 1.0) {
                    bottom = top + curH;
                  } else {
                    bottom = 1.0;
                    left = right - (bottom - top) * targetNormAspect;
                  }
                } else if (_activeHandle == CropHandle.topRight) {
                  if (bottom - curH >= 0.0) {
                    top = bottom - curH;
                  } else {
                    top = 0.0;
                    right = left + (bottom - top) * targetNormAspect;
                  }
                } else if (_activeHandle == CropHandle.topLeft) {
                  if (bottom - curH >= 0.0) {
                    top = bottom - curH;
                  } else {
                    top = 0.0;
                    left = right - (bottom - top) * targetNormAspect;
                  }
                }
              }
            }

            _currentRect = Rect.fromLTRB(left, top, right, bottom);
            setState(() {});
            widget.onCropChanged(_currentRect);
          },
          onPanEnd: (_) {
            setState(() {
              _activeHandle = CropHandle.none;
              _isDragging = false;
            });
            widget.onCropChanged(_currentRect);
          },
          onPanCancel: () {
            setState(() {
              _activeHandle = CropHandle.none;
              _isDragging = false;
            });
          },
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: _CropPainter(
                cropRect: _currentRect,
                isDragging: _isDragging,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CropPainter extends CustomPainter {
  final Rect cropRect;
  final bool isDragging;

  _CropPainter({
    required this.cropRect,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final screenRect = Rect.fromLTRB(
      cropRect.left * size.width,
      cropRect.top * size.height,
      cropRect.right * size.width,
      cropRect.bottom * size.height,
    );

    // 1. Shaded semi-transparent dark mask over the separated area outside the crop box
    final maskPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final maskPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(screenRect);

    canvas.drawPath(maskPath, maskPaint);

    // 2. Crisp White Border Line
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(screenRect, borderPaint);

    // 3. Rule of Thirds Grid inside crop box
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDragging ? 0.6 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final thirdW = screenRect.width / 3;
    final thirdH = screenRect.height / 3;

    // Vertical third lines
    canvas.drawLine(
      Offset(screenRect.left + thirdW, screenRect.top),
      Offset(screenRect.left + thirdW, screenRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(screenRect.left + thirdW * 2, screenRect.top),
      Offset(screenRect.left + thirdW * 2, screenRect.bottom),
      gridPaint,
    );

    // Horizontal third lines
    canvas.drawLine(
      Offset(screenRect.left, screenRect.top + thirdH),
      Offset(screenRect.right, screenRect.top + thirdH),
      gridPaint,
    );
    canvas.drawLine(
      Offset(screenRect.left, screenRect.top + thirdH * 2),
      Offset(screenRect.right, screenRect.top + thirdH * 2),
      gridPaint,
    );

    // 4. White Corner Brackets (L-shapes)
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.square;

    final cornerLen = math.min(22.0, math.min(screenRect.width, screenRect.height) / 3);

    // Top-Left
    canvas.drawLine(
      Offset(screenRect.left - 1, screenRect.top + cornerLen),
      Offset(screenRect.left - 1, screenRect.top - 1),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(screenRect.left - 1, screenRect.top - 1),
      Offset(screenRect.left + cornerLen, screenRect.top - 1),
      cornerPaint,
    );

    // Top-Right
    canvas.drawLine(
      Offset(screenRect.right + 1 - cornerLen, screenRect.top - 1),
      Offset(screenRect.right + 1, screenRect.top - 1),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(screenRect.right + 1, screenRect.top - 1),
      Offset(screenRect.right + 1, screenRect.top + cornerLen),
      cornerPaint,
    );

    // Bottom-Left
    canvas.drawLine(
      Offset(screenRect.left - 1, screenRect.bottom + 1 - cornerLen),
      Offset(screenRect.left - 1, screenRect.bottom + 1),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(screenRect.left - 1, screenRect.bottom + 1),
      Offset(screenRect.left + cornerLen, screenRect.bottom + 1),
      cornerPaint,
    );

    // Bottom-Right
    canvas.drawLine(
      Offset(screenRect.right + 1 - cornerLen, screenRect.bottom + 1),
      Offset(screenRect.right + 1, screenRect.bottom + 1),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(screenRect.right + 1, screenRect.bottom + 1),
      Offset(screenRect.right + 1, screenRect.bottom + 1 - cornerLen),
      cornerPaint,
    );

    // 5. White Edge Center Bars
    final edgePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final edgeLen = math.min(18.0, math.min(screenRect.width, screenRect.height) / 4);

    // Top Center
    canvas.drawLine(
      Offset(screenRect.center.dx - edgeLen / 2, screenRect.top - 1),
      Offset(screenRect.center.dx + edgeLen / 2, screenRect.top - 1),
      edgePaint,
    );

    // Bottom Center
    canvas.drawLine(
      Offset(screenRect.center.dx - edgeLen / 2, screenRect.bottom + 1),
      Offset(screenRect.center.dx + edgeLen / 2, screenRect.bottom + 1),
      edgePaint,
    );

    // Left Center
    canvas.drawLine(
      Offset(screenRect.left - 1, screenRect.center.dy - edgeLen / 2),
      Offset(screenRect.left - 1, screenRect.center.dy + edgeLen / 2),
      edgePaint,
    );

    // Right Center
    canvas.drawLine(
      Offset(screenRect.right + 1, screenRect.center.dy - edgeLen / 2),
      Offset(screenRect.right + 1, screenRect.center.dy + edgeLen / 2),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect || oldDelegate.isDragging != isDragging;
  }
}
