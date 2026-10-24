import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/prop_item.dart';
import '../../models/prop_layer_model.dart';
import '../../theme/app_theme.dart';
import 'prop_visual_widget.dart';

class PropOverlayWidget extends StatefulWidget {
  final List<PropLayerModel> propLayers;
  final String? selectedLayerId;
  final Function(String id) onSelectLayer;
  final Function(PropLayerModel updated) onUpdateLayer;
  final Function(String id) onDeleteLayer;

  const PropOverlayWidget({
    super.key,
    required this.propLayers,
    required this.selectedLayerId,
    required this.onSelectLayer,
    required this.onUpdateLayer,
    required this.onDeleteLayer,
  });

  @override
  State<PropOverlayWidget> createState() => _PropOverlayWidgetState();
}

class _PropOverlayWidgetState extends State<PropOverlayWidget> {
  PropDefinition _findDefinition(String propId) {
    return PropCatalog.all.firstWhere(
      (p) => p.id == propId,
      orElse: () => PropCatalog.all.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: widget.propLayers.map((layer) {
        final isSelected = widget.selectedLayerId == layer.id;
        final def = _findDefinition(layer.propId);

        return Positioned(
          left: layer.position.dx,
          top: layer.position.dy,
          child: GestureDetector(
            onTap: () => widget.onSelectLayer(layer.id),
            onPanUpdate: (details) {
              setState(() {
                layer.position += details.delta;
              });
              widget.onUpdateLayer(layer);
            },
            child: Transform.rotate(
              angle: layer.rotation,
              child: Transform.scale(
                scale: layer.scale,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppTheme.primary, width: 1.5)
                        : null,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Visual Prop Content
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(layer.flipHorizontal ? math.pi : 0),
                        child: PropVisualWidget(
                          propId: layer.propId,
                          width: def.defaultWidth,
                          height: def.defaultHeight,
                        ),
                      ),

                      // Interactive Handles when selected
                      if (isSelected) ...[
                        // Delete Button (Top Left)
                        Positioned(
                          top: -16,
                          left: -16,
                          child: GestureDetector(
                            onTap: () => widget.onDeleteLayer(layer.id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),

                        // Flip Horizontal Button (Top Right)
                        Positioned(
                          top: -16,
                          right: -16,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                layer.flipHorizontal = !layer.flipHorizontal;
                              });
                              widget.onUpdateLayer(layer);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF7928CA),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.flip_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),

                        // Rotate & Scale Handle (Bottom Right)
                        Positioned(
                          bottom: -16,
                          right: -16,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                layer.scale = (layer.scale + details.delta.dx * 0.01).clamp(0.4, 3.5);
                                layer.rotation += details.delta.dy * 0.02;
                              });
                              widget.onUpdateLayer(layer);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.sync_rounded, size: 14, color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
