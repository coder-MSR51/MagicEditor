import 'package:flutter/material.dart';
import '../models/background_model.dart';
import '../theme/app_theme.dart';

class FrameSelectorBar extends StatefulWidget {
  final BackgroundType selectedType;
  final double blurAmount;
  final double paddingAmount;
  final double radiusAmount;
  final Function(BackgroundType) onTypeChanged;
  final Function(double) onBlurChanged;
  final Function(double) onPaddingChanged;
  final Function(double) onRadiusChanged;
  final VoidCallback onDone;

  const FrameSelectorBar({
    super.key,
    required this.selectedType,
    required this.blurAmount,
    required this.paddingAmount,
    required this.radiusAmount,
    required this.onTypeChanged,
    required this.onBlurChanged,
    required this.onPaddingChanged,
    required this.onRadiusChanged,
    required this.onDone,
  });

  @override
  State<FrameSelectorBar> createState() => _FrameSelectorBarState();
}

class _FrameSelectorBarState extends State<FrameSelectorBar> {
  String _activeCategory = 'all'; // 'all', 'heart', 'sparkle', 'balloon', 'pumpkin', 'frame'

  final List<BackgroundType> _allFrames = [
    BackgroundType.none,
    BackgroundType.heartConfetti,
    BackgroundType.fairySparkle,
    BackgroundType.pastelValentine,
    BackgroundType.crownKey,
    BackgroundType.silverStars,
    BackgroundType.crimsonGarland,
    BackgroundType.loveLetterDove,
    BackgroundType.floralCorners,
    BackgroundType.balloonCelebration,
    BackgroundType.autumnPumpkin,
    BackgroundType.polaroid,
    BackgroundType.filmStrip,
    BackgroundType.neonBorder,
    BackgroundType.blur,
    BackgroundType.gradient,
  ];

  List<BackgroundType> get _filteredFrames {
    if (_activeCategory == 'all') return _allFrames;
    return _allFrames.where((f) => f.category == _activeCategory || f == BackgroundType.none).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141720),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top Category Icons Strip matching Screenshot 4
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12, width: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category Icons
                Row(
                  children: [
                    _buildCategoryIcon('all', Icons.grid_view_rounded, Colors.white70),
                    const SizedBox(width: 8),
                    _buildCategoryIcon('heart', Icons.favorite_rounded, const Color(0xFFFF2A85)),
                    const SizedBox(width: 8),
                    _buildCategoryIcon('balloon', Icons.celebration_rounded, const Color(0xFFFFD700)),
                    const SizedBox(width: 8),
                    _buildCategoryIcon('pumpkin', Icons.theater_comedy_rounded, const Color(0xFFFF6F00)),
                    const SizedBox(width: 8),
                    _buildCategoryIcon('sparkle', Icons.auto_awesome_rounded, const Color(0xFF00E5FF)),
                    const SizedBox(width: 8),
                    _buildCategoryIcon('frame', Icons.crop_square_rounded, const Color(0xFFC084FC)),
                  ],
                ),

                // Checkmark / Done Button on the Right (Screenshot 4)
                GestureDetector(
                  onTap: widget.onDone,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.black, size: 20),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 2. Grid of Decorative Frames (Screenshot 4: 4 columns of cards with dark preview squares)
          SizedBox(
            height: 140,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: _filteredFrames.length,
              itemBuilder: (context, index) {
                final frame = _filteredFrames[index];
                final isSelected = widget.selectedType == frame;

                return GestureDetector(
                  onTap: () => widget.onTypeChanged(frame),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF232734),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.white12,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Miniature Decorative Border Preview
                        _buildFramePreviewIcon(frame),

                        // Title Label at bottom
                        Positioned(
                          bottom: 4,
                          left: 2,
                          right: 2,
                          child: Text(
                            frame.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppTheme.primary : Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Fine-tuning Slider (Blur & Padding when frame is active)
          if (widget.selectedType != BackgroundType.none) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.blur_on_rounded, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Text('Backdrop Blur', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppTheme.primary,
                        inactiveTrackColor: Colors.white12,
                        thumbColor: AppTheme.primary,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 2.5,
                      ),
                      child: Slider(
                        value: widget.blurAmount,
                        min: 0,
                        max: 30,
                        onChanged: widget.onBlurChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(String category, IconData icon, Color activeColor) {
    final isSelected = _activeCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          size: 19,
          color: isSelected ? activeColor : Colors.white54,
        ),
      ),
    );
  }

  Widget _buildFramePreviewIcon(BackgroundType type) {
    if (type == BackgroundType.none) {
      return const Icon(Icons.block_rounded, size: 24, color: Colors.white38);
    }

    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF181B24),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getFrameColor(type).withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          type.icon,
          size: 20,
          color: _getFrameColor(type),
        ),
      ),
    );
  }

  Color _getFrameColor(BackgroundType type) {
    switch (type.category) {
      case 'heart':
        return const Color(0xFFFF2A85);
      case 'sparkle':
        return const Color(0xFF00E5FF);
      case 'crown':
        return const Color(0xFFFFD700);
      case 'balloon':
        return const Color(0xFFFFC107);
      case 'pumpkin':
        return const Color(0xFFFF6F00);
      case 'flower':
        return const Color(0xFFFF70A6);
      case 'frame':
        return const Color(0xFF9D4EDD);
      default:
        return AppTheme.primary;
    }
  }
}
