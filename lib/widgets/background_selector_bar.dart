import 'package:flutter/material.dart';
import '../models/background_model.dart';
import '../theme/app_theme.dart';

class BackgroundSelectorBar extends StatefulWidget {
  final BackgroundType selectedType;
  final double blurAmount;
  final int gradientIndex;
  final double paddingAmount;
  final double radiusAmount;
  final String polaroidCaption;
  final Function(BackgroundType) onTypeChanged;
  final Function(double) onBlurChanged;
  final Function(int) onGradientChanged;
  final Function(double) onPaddingChanged;
  final Function(double) onRadiusChanged;
  final Function(String) onCaptionChanged;

  const BackgroundSelectorBar({
    super.key,
    required this.selectedType,
    required this.blurAmount,
    required this.gradientIndex,
    required this.paddingAmount,
    required this.radiusAmount,
    required this.polaroidCaption,
    required this.onTypeChanged,
    required this.onBlurChanged,
    required this.onGradientChanged,
    required this.onPaddingChanged,
    required this.onRadiusChanged,
    required this.onCaptionChanged,
  });

  @override
  State<BackgroundSelectorBar> createState() => _BackgroundSelectorBarState();
}

class _BackgroundSelectorBarState extends State<BackgroundSelectorBar> {
  late TextEditingController _captionController;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.polaroidCaption);
  }

  @override
  void didUpdateWidget(covariant BackgroundSelectorBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.polaroidCaption != _captionController.text) {
      _captionController.text = widget.polaroidCaption;
      _captionController.selection = TextSelection.collapsed(offset: _captionController.text.length);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Background type chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: BackgroundType.values.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final type = BackgroundType.values[index];
                final isSelected = widget.selectedType == type;

                return GestureDetector(
                  onTap: () => widget.onTypeChanged(type),
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
                          type.icon,
                          size: 16,
                          color: isSelected ? Colors.black : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          type.title,
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

          // Contextual controls depending on type
          if (widget.selectedType == BackgroundType.blur) ...[
            _buildSliderRow('Blur Intensity', widget.blurAmount, 5, 35, (v) => widget.onBlurChanged(v)),
            _buildSliderRow('Frame Padding', widget.paddingAmount, 0, 48, (v) => widget.onPaddingChanged(v)),
            _buildSliderRow('Corner Roundness', widget.radiusAmount, 0, 32, (v) => widget.onRadiusChanged(v)),
          ] else if (widget.selectedType == BackgroundType.gradient) ...[
            // Gradient dots
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: BackgroundGradients.presets.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final colors = BackgroundGradients.presets[index];
                  final isSelected = widget.gradientIndex == index;

                  return GestureDetector(
                    onTap: () => widget.onGradientChanged(index),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: colors),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _buildSliderRow('Frame Padding', widget.paddingAmount, 0, 48, (v) => widget.onPaddingChanged(v)),
            _buildSliderRow('Corner Roundness', widget.radiusAmount, 0, 32, (v) => widget.onRadiusChanged(v)),
          ] else if (widget.selectedType == BackgroundType.polaroid) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _captionController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  hintText: 'Enter Polaroid Caption...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: widget.onCaptionChanged,
              ),
            ),
            const SizedBox(height: 6),
            _buildSliderRow('Polaroid Margin', widget.paddingAmount, 8, 40, (v) => widget.onPaddingChanged(v)),
          ] else if (widget.selectedType == BackgroundType.neonBorder) ...[
            _buildSliderRow('Border Spacing', widget.paddingAmount, 8, 48, (v) => widget.onPaddingChanged(v)),
            _buildSliderRow('Corner Roundness', widget.radiusAmount, 0, 32, (v) => widget.onRadiusChanged(v)),
          ],
        ],
      ),
    );
  }

  Widget _buildSliderRow(String title, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.primary,
                inactiveTrackColor: Colors.white12,
                thumbColor: AppTheme.primary,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                trackHeight: 3,
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toInt().toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
