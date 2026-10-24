import 'package:flutter/material.dart';
import '../models/draw_model.dart';

class DrawingCanvas extends StatefulWidget {
  final List<DrawPathModel> paths;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isNeon;
  final bool isDrawingEnabled;
  final Function(DrawPathModel path) onPathDrawn;

  const DrawingCanvas({
    super.key,
    required this.paths,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.isNeon,
    required this.isDrawingEnabled,
    required this.onPathDrawn,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final List<Offset> _currentPoints = [];

  @override
  Widget build(BuildContext context) {
    if (!widget.isDrawingEnabled && widget.paths.isEmpty) {
      return const SizedBox.shrink();
    }

    final canvasWidget = CustomPaint(
      painter: _DrawingPainter(
        paths: widget.paths,
        currentPoints: _currentPoints,
        currentColor: widget.currentColor,
        currentStrokeWidth: widget.currentStrokeWidth,
        isNeon: widget.isNeon,
      ),
      size: Size.infinite,
    );

    if (!widget.isDrawingEnabled) {
      return canvasWidget;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        setState(() {
          _currentPoints.clear();
          _currentPoints.add(details.localPosition);
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _currentPoints.add(details.localPosition);
        });
      },
      onPanEnd: (details) {
        if (_currentPoints.isNotEmpty) {
          final newPath = DrawPathModel(
            points: List.from(_currentPoints),
            color: widget.currentColor,
            strokeWidth: widget.currentStrokeWidth,
            isNeon: widget.isNeon,
          );
          widget.onPathDrawn(newPath);
          setState(() {
            _currentPoints.clear();
          });
        }
      },
      child: canvasWidget,
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawPathModel> paths;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isNeon;

  _DrawingPainter({
    required this.paths,
    required this.currentPoints,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.isNeon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw completed paths
    for (final pathModel in paths) {
      _drawSinglePath(canvas, pathModel.points, pathModel.color, pathModel.strokeWidth, pathModel.isNeon);
    }

    // 2. Draw currently active path being drawn
    if (currentPoints.isNotEmpty) {
      _drawSinglePath(canvas, currentPoints, currentColor, currentStrokeWidth, isNeon);
    }
  }

  void _drawSinglePath(Canvas canvas, List<Offset> points, Color color, double strokeWidth, bool isNeon) {
    if (points.isEmpty) return;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // If neon glow enabled, draw blurred wider aura underneath
    if (isNeon) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..strokeWidth = strokeWidth * 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, glowPaint);
    }

    final mainPaint = Paint()
      ..color = isNeon ? Colors.white : color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, mainPaint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
