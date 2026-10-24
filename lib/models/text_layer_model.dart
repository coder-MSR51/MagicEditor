import 'package:flutter/material.dart';

class TextLayerModel {
  final String id;
  String text;
  Offset position;
  double scale;
  double rotation;
  double fontSize;
  Color color;
  Color? backgroundColor;
  String fontFamily;
  bool hasShadow;
  bool isBold;
  bool isItalic;

  TextLayerModel({
    required this.id,
    required this.text,
    this.position = const Offset(100, 150),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.fontSize = 28.0,
    this.color = Colors.white,
    this.backgroundColor,
    this.fontFamily = 'Montserrat',
    this.hasShadow = true,
    this.isBold = true,
    this.isItalic = false,
  });

  TextLayerModel copyWith({
    String? id,
    String? text,
    Offset? position,
    double? scale,
    double? rotation,
    double? fontSize,
    Color? color,
    Color? backgroundColor,
    String? fontFamily,
    bool? hasShadow,
    bool? isBold,
    bool? isItalic,
  }) {
    return TextLayerModel(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontFamily: fontFamily ?? this.fontFamily,
      hasShadow: hasShadow ?? this.hasShadow,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
    );
  }
}
