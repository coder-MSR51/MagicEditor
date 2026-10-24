import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/text_layer_model.dart';
import '../theme/app_theme.dart';

class TextOverlayWidget extends StatefulWidget {
  final List<TextLayerModel> textLayers;
  final String? selectedLayerId;
  final Function(String id) onSelectLayer;
  final Function(TextLayerModel updated) onUpdateLayer;
  final Function(String id) onDeleteLayer;
  final Function(TextLayerModel layer)? onEditLayer;

  const TextOverlayWidget({
    super.key,
    required this.textLayers,
    required this.selectedLayerId,
    required this.onSelectLayer,
    required this.onUpdateLayer,
    required this.onDeleteLayer,
    this.onEditLayer,
  });

  @override
  State<TextOverlayWidget> createState() => _TextOverlayWidgetState();
}

class _TextOverlayWidgetState extends State<TextOverlayWidget> {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (widget.selectedLayerId != null) {
          widget.onSelectLayer('');
        }
      },
      child: Stack(
        children: widget.textLayers.map((layer) {
          final isSelected = widget.selectedLayerId == layer.id;

          return Positioned(
            left: layer.position.dx,
            top: layer.position.dy,
            child: Transform.rotate(
              angle: layer.rotation,
              child: Transform.scale(
                scale: layer.scale,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Text Box container with padding so handles stay inside hit-test bounds
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (!isSelected) {
                            widget.onSelectLayer(layer.id);
                          } else {
                            widget.onEditLayer?.call(layer);
                          }
                        },
                        onDoubleTap: () {
                          widget.onEditLayer?.call(layer);
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            layer.position += details.delta;
                          });
                          widget.onUpdateLayer(layer);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: layer.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: AppTheme.primary, width: 2.0)
                                : null,
                          ),
                          child: Text(
                            layer.text,
                            style: _getGoogleFontStyle(
                              layer.fontFamily,
                              TextStyle(
                                color: layer.color,
                                fontSize: layer.fontSize,
                                fontWeight: layer.isBold ? FontWeight.bold : FontWeight.normal,
                                fontStyle: layer.isItalic ? FontStyle.italic : FontStyle.normal,
                                shadows: layer.hasShadow
                                    ? [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.8),
                                          blurRadius: 8,
                                          offset: const Offset(2, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Interactive Corner Handles (shown when selected)
                    if (isSelected) ...[
                      // 1. TOP-LEFT HANDLE: Make text small & large (scale)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: (details) {
                            setState(() {
                              // Dragging up/left (negative dx/dy) makes text larger;
                              // Dragging down/right (positive dx/dy) makes text smaller.
                              final double delta = -(details.delta.dx + details.delta.dy) * 0.015;
                              layer.scale = (layer.scale + delta).clamp(0.4, 4.0);
                            });
                            widget.onUpdateLayer(layer);
                          },
                          onTap: () {
                            // Cycle preset sizes on tap
                            setState(() {
                              if (layer.scale < 0.9) {
                                layer.scale = 1.0;
                              } else if (layer.scale < 1.4) {
                                layer.scale = 1.8;
                              } else if (layer.scale < 2.2) {
                                layer.scale = 2.6;
                              } else {
                                layer.scale = 0.7;
                              }
                            });
                            widget.onUpdateLayer(layer);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.format_size_rounded,
                              color: Colors.black,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      // 2. TOP-RIGHT HANDLE: Red Cross Delete Button
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            widget.onDeleteLayer(layer.id);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      // 3. BOTTOM-RIGHT HANDLE: Quick Edit Button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            widget.onEditLayer?.call(layer);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7928CA), // Purple accent
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
