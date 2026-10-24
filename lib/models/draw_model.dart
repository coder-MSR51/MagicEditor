import 'package:flutter/material.dart';

class DrawPoint {
  final Offset offset;
  final Paint paint;

  DrawPoint({
    required this.offset,
    required this.paint,
  });
}

class DrawPathModel {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isNeon;

  DrawPathModel({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isNeon = false,
  });

  DrawPathModel copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    bool? isNeon,
  }) {
    return DrawPathModel(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isNeon: isNeon ?? this.isNeon,
    );
  }
}
