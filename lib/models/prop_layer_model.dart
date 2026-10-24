import 'package:flutter/material.dart';

class PropLayerModel {
  final String id;
  final String propId;
  Offset position;
  double scale;
  double rotation;
  bool flipHorizontal;

  PropLayerModel({
    required this.id,
    required this.propId,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.flipHorizontal = false,
  });

  PropLayerModel copyWith({
    String? id,
    String? propId,
    Offset? position,
    double? scale,
    double? rotation,
    bool? flipHorizontal,
  }) {
    return PropLayerModel(
      id: id ?? this.id,
      propId: propId ?? this.propId,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
    );
  }
}
