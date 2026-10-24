import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AdjustmentType {
  brightness,
  contrast,
  saturation,
  warmth,
  tint,
  vignette,
  grain,
}

class AdjustmentSliderBar extends StatefulWidget {
  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final double tint;
  final double vignette;
  final double grain;

  final Function(double val) onBrightnessChanged;
  final Function(double val) onContrastChanged;
  final Function(double val) onSaturationChanged;
  final Function(double val) onWarmthChanged;
  final Function(double val) onTintChanged;
  final Function(double val) onVignetteChanged;
  final Function(double val) onGrainChanged;

  const AdjustmentSliderBar({
    super.key,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.warmth,
    required this.tint,
    required this.vignette,
    required this.grain,
    required this.onBrightnessChanged,
    required this.onContrastChanged,
    required this.onSaturationChanged,
    required this.onWarmthChanged,
    required this.onTintChanged,
    required this.onVignetteChanged,
    required this.onGrainChanged,
  });

  @override
  State<AdjustmentSliderBar> createState() => _AdjustmentSliderBarState();
}

class _AdjustmentSliderBarState extends State<AdjustmentSliderBar> {
  AdjustmentType _selectedType = AdjustmentType.brightness;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slider Control Area
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _buildActiveSlider(),
        ),

        // Horizontal Tool Tabs
        SizedBox(
          height: 64,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _buildTab(AdjustmentType.brightness, Icons.brightness_6_rounded, 'Brightness'),
              _buildTab(AdjustmentType.contrast, Icons.contrast_rounded, 'Contrast'),
              _buildTab(AdjustmentType.saturation, Icons.palette_rounded, 'Saturation'),
              _buildTab(AdjustmentType.warmth, Icons.wb_sunny_rounded, 'Warmth'),
              _buildTab(AdjustmentType.tint, Icons.invert_colors_rounded, 'Tint'),
              _buildTab(AdjustmentType.vignette, Icons.vignette_rounded, 'Vignette'),
              _buildTab(AdjustmentType.grain, Icons.grain_rounded, 'Grain'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(AdjustmentType type, IconData icon, String label) {
    final isSelected = _selectedType == type;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSlider() {
    double value;
    double min;
    double max;
    String displayVal;
    Function(double) onChanged;
    VoidCallback onReset;

    switch (_selectedType) {
      case AdjustmentType.brightness:
        value = widget.brightness;
        min = -0.6;
        max = 0.6;
        displayVal = '${(value * 166).toInt()}';
        onChanged = widget.onBrightnessChanged;
        onReset = () => widget.onBrightnessChanged(0.0);
        break;
      case AdjustmentType.contrast:
        value = widget.contrast;
        min = 0.3;
        max = 1.8;
        displayVal = '${((value - 1.0) * 100).toInt()}';
        onChanged = widget.onContrastChanged;
        onReset = () => widget.onContrastChanged(1.0);
        break;
      case AdjustmentType.saturation:
        value = widget.saturation;
        min = 0.0;
        max = 2.0;
        displayVal = '${((value - 1.0) * 100).toInt()}';
        onChanged = widget.onSaturationChanged;
        onReset = () => widget.onSaturationChanged(1.0);
        break;
      case AdjustmentType.warmth:
        value = widget.warmth;
        min = -0.8;
        max = 0.8;
        displayVal = '${(value * 125).toInt()}';
        onChanged = widget.onWarmthChanged;
        onReset = () => widget.onWarmthChanged(0.0);
        break;
      case AdjustmentType.tint:
        value = widget.tint;
        min = -0.8;
        max = 0.8;
        displayVal = '${(value * 125).toInt()}';
        onChanged = widget.onTintChanged;
        onReset = () => widget.onTintChanged(0.0);
        break;
      case AdjustmentType.vignette:
        value = widget.vignette;
        min = 0.0;
        max = 1.0;
        displayVal = '${(value * 100).toInt()}%';
        onChanged = widget.onVignetteChanged;
        onReset = () => widget.onVignetteChanged(0.0);
        break;
      case AdjustmentType.grain:
        value = widget.grain;
        min = 0.0;
        max = 1.0;
        displayVal = '${(value * 100).toInt()}%';
        onChanged = widget.onGrainChanged;
        onReset = () => widget.onGrainChanged(0.0);
        break;
    }

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.textMuted),
          tooltip: 'Reset',
          onPressed: onReset,
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            displayVal,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
