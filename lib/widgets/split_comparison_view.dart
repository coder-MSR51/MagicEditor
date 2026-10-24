import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplitComparisonView extends StatefulWidget {
  final Widget originalChild;
  final Widget editedChild;
  final bool isComparing;

  const SplitComparisonView({
    super.key,
    required this.originalChild,
    required this.editedChild,
    this.isComparing = false,
  });

  @override
  State<SplitComparisonView> createState() => _SplitComparisonViewState();
}

class _SplitComparisonViewState extends State<SplitComparisonView> {
  double _splitPercent = 0.5;

  @override
  Widget build(BuildContext context) {
    if (!widget.isComparing) {
      return widget.editedChild;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final splitX = width * _splitPercent;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Right: Edited child
            widget.editedChild,

            // Left: Original child clipped
            ClipRect(
              clipper: _SplitClipper(splitX: splitX),
              child: widget.originalChild,
            ),

            // Vertical Divider Bar
            Positioned(
              left: splitX - 1.5,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.2),
                      AppTheme.primary,
                      AppTheme.primary.withValues(alpha: 0.2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

            // Draggable Handle
            Positioned(
              left: splitX - 18,
              top: height / 2 - 18,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _splitPercent = ((details.localPosition.dx + splitX - 18) / width)
                        .clamp(0.05, 0.95);
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.compare_arrows_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // "BEFORE" Badge (Top Left)
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'ORIGINAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            // "AFTER" Badge (Top Right)
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.6)),
                ),
                child: const Text(
                  'EDITED',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  final double splitX;
  _SplitClipper({required this.splitX});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, splitX, size.height);
  }

  @override
  bool shouldReclip(_SplitClipper oldClipper) => oldClipper.splitX != splitX;
}
