import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/background_model.dart';
import '../theme/app_theme.dart';

class BackgroundFrameWidget extends StatelessWidget {
  final Widget child;
  final ImageProvider imageProvider;
  final BackgroundType backgroundType;
  final double backgroundBlur;
  final int backgroundGradientIndex;
  final double framePadding;
  final double frameRadius;
  final String polaroidCaption;

  const BackgroundFrameWidget({
    super.key,
    required this.child,
    required this.imageProvider,
    required this.backgroundType,
    required this.backgroundBlur,
    required this.backgroundGradientIndex,
    required this.framePadding,
    required this.frameRadius,
    required this.polaroidCaption,
  });

  @override
  Widget build(BuildContext context) {
    if (backgroundType == BackgroundType.none) {
      return child;
    }

    switch (backgroundType) {
      case BackgroundType.blur:
        return _buildBlurBackground(null);
      case BackgroundType.gradient:
        return _buildGradientBackground();
      case BackgroundType.polaroid:
        return _buildPolaroidBackground();
      case BackgroundType.filmStrip:
        return _buildFilmStripBackground();
      case BackgroundType.neonBorder:
        return _buildNeonBorder();
      case BackgroundType.heartConfetti:
        return _buildBlurBackground(const _HeartConfettiPainter());
      case BackgroundType.fairySparkle:
        return _buildBlurBackground(const _FairySparklePainter());
      case BackgroundType.pastelValentine:
        return _buildBlurBackground(const _PastelValentinePainter());
      case BackgroundType.crownKey:
        return _buildBlurBackground(const _CrownKeyPainter());
      case BackgroundType.silverStars:
        return _buildBlurBackground(const _SilverStarsPainter());
      case BackgroundType.crimsonGarland:
        return _buildBlurBackground(const _CrimsonGarlandPainter());
      case BackgroundType.loveLetterDove:
        return _buildBlurBackground(const _LoveLetterDovePainter());
      case BackgroundType.floralCorners:
        return _buildBlurBackground(const _FloralCornersPainter());
      case BackgroundType.balloonCelebration:
        return _buildBlurBackground(const _BalloonCelebrationPainter());
      case BackgroundType.autumnPumpkin:
        return _buildBlurBackground(const _AutumnPumpkinPainter());
      default:
        return child;
    }
  }

  /// Builds blurred photo backdrop with optional decorative frame painter overlay (Screenshot 4)
  Widget _buildBlurBackground(CustomPainter? framePainter) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Zoomed blurred background image (Screenshot 4 top view)
        Positioned.fill(
          child: ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: math.max(6.0, backgroundBlur),
                sigmaY: math.max(6.0, backgroundBlur),
                tileMode: TileMode.mirror,
              ),
              child: Transform.scale(
                scale: 1.3,
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),

        // 2. Dark ambient overlay for legibility
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),
        ),

        // 3. Foreground Framed Child
        Padding(
          padding: EdgeInsets.all(framePadding.clamp(10.0, 48.0)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(frameRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(frameRadius),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  child,
                  if (framePainter != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: framePainter),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientBackground() {
    final colors = BackgroundGradients.presets[
        backgroundGradientIndex % BackgroundGradients.presets.length];

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(framePadding),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(frameRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(frameRadius),
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPolaroidBackground() {
    return Container(
      color: const Color(0xFF14171E),
      alignment: Alignment.center,
      padding: EdgeInsets.all(framePadding),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: child,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              polaroidCaption.isEmpty ? 'PHOTO MAGIC' : polaroidCaption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.caveat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilmStripBackground() {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSprocketRow('KODAK 400', '▸ 12A'),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              color: Colors.black,
              child: child,
            ),
          ),
          const SizedBox(height: 6),
          _buildSprocketRow('PHOTO MAGIC', '▸ 13'),
        ],
      ),
    );
  }

  Widget _buildSprocketRow(String labelLeft, String labelRight) {
    return Container(
      height: 24,
      color: const Color(0xFF161616),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            labelLeft,
            style: const TextStyle(fontSize: 10, color: Color(0xFFFFB300), fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          Row(
            children: List.generate(
              6,
              (_) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
              ),
            ),
          ),
          Text(
            labelRight,
            style: const TextStyle(fontSize: 10, color: Color(0xFFFFB300), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonBorder() {
    return Container(
      color: AppTheme.background,
      alignment: Alignment.center,
      padding: EdgeInsets.all(framePadding),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(frameRadius),
          border: Border.all(
            color: AppTheme.primary,
            width: 3.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.7),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: AppTheme.secondary.withValues(alpha: 0.5),
              blurRadius: 36,
              spreadRadius: 6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(frameRadius - 3),
          child: child,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// DECORATIVE FRAME PAINTERS MATCHING SCREENSHOT 4
// -------------------------------------------------------------

void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  final path = Path();
  path.moveTo(center.dx, center.dy + size * 0.35);
  path.cubicTo(
    center.dx - size * 0.7, center.dy - size * 0.4,
    center.dx - size * 0.35, center.dy - size * 0.75,
    center.dx, center.dy - size * 0.25,
  );
  path.cubicTo(
    center.dx + size * 0.35, center.dy - size * 0.75,
    center.dx + size * 0.7, center.dy - size * 0.4,
    center.dx, center.dy + size * 0.35,
  );
  path.close();
  canvas.drawPath(path, paint);
}

void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  final path = Path();
  for (int i = 0; i < 4; i++) {
    final angle = i * math.pi / 2;
    final p1 = Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius);
    final p2 = Offset(center.dx + math.cos(angle + math.pi / 4) * (radius * 0.25),
        center.dy + math.sin(angle + math.pi / 4) * (radius * 0.25));
    if (i == 0) {
      path.moveTo(p1.dx, p1.dy);
    } else {
      path.lineTo(p1.dx, p1.dy);
    }
    path.lineTo(p2.dx, p2.dy);
  }
  path.close();
  canvas.drawPath(path, paint);
}

/// 1. Cute Hearts Confetti Border (Screenshot 4, Row 1, Tile 1)
class _HeartConfettiPainter extends CustomPainter {
  const _HeartConfettiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFFF2A85),
      const Color(0xFFFF6584),
      const Color(0xFFFFB6C1),
      const Color(0xFFC084FC),
      const Color(0xFFFFD166),
    ];

    final dotPaint = Paint()..style = PaintingStyle.fill;

    // Top & Bottom edges
    final stepX = size.width / 14;
    for (int i = 0; i <= 14; i++) {
      final x = i * stepX;
      final c1 = colors[i % colors.length];
      final c2 = colors[(i + 2) % colors.length];

      // Top hearts & dots
      if (i % 2 == 0) {
        _drawHeart(canvas, Offset(x, 14), 10, c1);
      } else {
        dotPaint.color = c1.withValues(alpha: 0.8);
        canvas.drawCircle(Offset(x, 14), 3, dotPaint);
      }

      // Bottom hearts & dots
      if (i % 2 == 1) {
        _drawHeart(canvas, Offset(x, size.height - 14), 10, c2);
      } else {
        dotPaint.color = c2.withValues(alpha: 0.8);
        canvas.drawCircle(Offset(x, size.height - 14), 3, dotPaint);
      }
    }

    // Left & Right edges
    final stepY = size.height / 18;
    for (int i = 1; i < 18; i++) {
      final y = i * stepY;
      final c = colors[i % colors.length];
      if (i % 2 == 0) {
        _drawHeart(canvas, Offset(14, y), 9, c);
        _drawHeart(canvas, Offset(size.width - 14, y), 9, colors[(i + 1) % colors.length]);
      } else {
        dotPaint.color = c.withValues(alpha: 0.75);
        canvas.drawCircle(Offset(14, y), 2.5, dotPaint);
        canvas.drawCircle(Offset(size.width - 14, y), 2.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. Fairy Sparkles & Glow (Screenshot 4, Row 1, Tile 2)
class _FairySparklePainter extends CustomPainter {
  const _FairySparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Subtle inner border line
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
        const Radius.circular(10),
      ),
      borderPaint,
    );

    // Crown at top center
    final crownPath = Path();
    final cx = size.width / 2;
    crownPath.moveTo(cx - 16, 22);
    crownPath.lineTo(cx - 18, 10);
    crownPath.lineTo(cx - 8, 16);
    crownPath.lineTo(cx, 8);
    crownPath.lineTo(cx + 8, 16);
    crownPath.lineTo(cx + 18, 10);
    crownPath.lineTo(cx + 16, 22);
    crownPath.close();

    final crownPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawPath(crownPath, crownPaint);

    // Sparkles and stars around frame
    final sparkPositions = [
      Offset(16, 16),
      Offset(38, 12),
      Offset(size.width - 38, 12),
      Offset(size.width - 16, 16),
      Offset(14, size.height / 3),
      Offset(size.width - 14, size.height / 3),
      Offset(14, size.height * 2 / 3),
      Offset(size.width - 14, size.height * 2 / 3),
      Offset(16, size.height - 16),
      Offset(cx - 24, size.height - 12),
      Offset(cx + 24, size.height - 12),
      Offset(size.width - 16, size.height - 16),
    ];

    for (final pos in sparkPositions) {
      _drawStar(canvas, pos, 9, Colors.white.withValues(alpha: 0.85));
      _drawHeart(canvas, Offset(pos.dx + 10, pos.dy + 4), 6, const Color(0xFFFBCFE8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Pastel Valentine Border (Screenshot 4, Row 1, Tile 3)
class _PastelValentinePainter extends CustomPainter {
  const _PastelValentinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const pinkColor = Color(0xFFFF69B4);

    final step = 26.0;
    for (double x = 12; x < size.width; x += step) {
      _drawHeart(canvas, Offset(x, 12), 8, pinkColor);
      _drawHeart(canvas, Offset(x, size.height - 12), 8, pinkColor);
    }
    for (double y = 12; y < size.height; y += step) {
      _drawHeart(canvas, Offset(12, y), 8, pinkColor);
      _drawHeart(canvas, Offset(size.width - 12, y), 8, pinkColor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. Crown, Heart & Key to My Heart (Screenshot 4, Row 2, Tile 2)
class _CrownKeyPainter extends CustomPainter {
  const _CrownKeyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFFFD700);
    const rose = Color(0xFFFF2A85);

    // Top-left Gold Crown
    final crownPath = Path();
    crownPath.moveTo(14, 30);
    crownPath.lineTo(12, 16);
    crownPath.lineTo(22, 22);
    crownPath.lineTo(30, 14);
    crownPath.lineTo(38, 22);
    crownPath.lineTo(48, 16);
    crownPath.lineTo(46, 30);
    crownPath.close();

    final goldPaint = Paint()..color = gold..style = PaintingStyle.fill;
    canvas.drawPath(crownPath, goldPaint);

    // Bottom-right Golden Key & Heart Padlock
    final keyPaint = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final kx = size.width - 36;
    final ky = size.height - 24;
    canvas.drawCircle(Offset(kx - 14, ky), 7, keyPaint);
    canvas.drawLine(Offset(kx - 7, ky), Offset(kx + 16, ky), keyPaint);
    canvas.drawLine(Offset(kx + 10, ky), Offset(kx + 10, ky + 6), keyPaint);
    canvas.drawLine(Offset(kx + 14, ky), Offset(kx + 14, ky + 8), keyPaint);

    // Bottom-left heart padlock
    _drawHeart(canvas, Offset(30, size.height - 24), 16, rose);

    // Hearts along edges
    final heartPoints = [
      Offset(68, 18),
      Offset(size.width * 0.45, 14),
      Offset(size.width * 0.72, 16),
      Offset(size.width - 24, 24),
      Offset(16, size.height * 0.4),
      Offset(size.width - 16, size.height * 0.4),
      Offset(16, size.height * 0.7),
      Offset(size.width - 16, size.height * 0.7),
      Offset(size.width * 0.35, size.height - 16),
      Offset(size.width * 0.58, size.height - 16),
    ];

    for (int i = 0; i < heartPoints.length; i++) {
      _drawHeart(canvas, heartPoints[i], 10, i.isEven ? rose : gold);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. Silver Stars & Diamonds (Screenshot 4, Row 2, Tile 3)
class _SilverStarsPainter extends CustomPainter {
  const _SilverStarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const silver = Color(0xFFF1F5F9);

    final positions = [
      Offset(18, 16),
      Offset(48, 14),
      Offset(size.width * 0.3, 14),
      Offset(size.width * 0.5, 12),
      Offset(size.width * 0.7, 14),
      Offset(size.width - 48, 14),
      Offset(size.width - 18, 16),
      Offset(14, size.height * 0.25),
      Offset(size.width - 14, size.height * 0.25),
      Offset(14, size.height * 0.5),
      Offset(size.width - 14, size.height * 0.5),
      Offset(14, size.height * 0.75),
      Offset(size.width - 14, size.height * 0.75),
      Offset(18, size.height - 16),
      Offset(size.width * 0.3, size.height - 14),
      Offset(size.width * 0.5, size.height - 12),
      Offset(size.width * 0.7, size.height - 14),
      Offset(size.width - 18, size.height - 16),
    ];

    for (int i = 0; i < positions.length; i++) {
      _drawStar(canvas, positions[i], i % 3 == 0 ? 11 : 7, silver.withValues(alpha: 0.9));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 6. Crimson Heart Garland (Screenshot 4, Row 2, Tile 4)
class _CrimsonGarlandPainter extends CustomPainter {
  const _CrimsonGarlandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const crimson = Color(0xFFE11D48);
    const ruby = Color(0xFFFF4D6D);

    final step = 20.0;
    int index = 0;
    for (double x = 12; x <= size.width - 12; x += step) {
      _drawHeart(canvas, Offset(x, 12), 9, index.isEven ? crimson : ruby);
      _drawHeart(canvas, Offset(x, size.height - 12), 9, index.isOdd ? crimson : ruby);
      index++;
    }
    for (double y = 28; y <= size.height - 28; y += step) {
      _drawHeart(canvas, Offset(12, y), 9, index.isEven ? crimson : ruby);
      _drawHeart(canvas, Offset(size.width - 12, y), 9, index.isOdd ? crimson : ruby);
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 7. Dove & Love Letter Frame (Screenshot 4, Row 2, Tile 1)
class _LoveLetterDovePainter extends CustomPainter {
  const _LoveLetterDovePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const red = Color(0xFFEF4444);

    // Top-left flying white dove silhouette
    final dovePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final dovePath = Path();
    dovePath.moveTo(16, 24);
    dovePath.cubicTo(12, 14, 26, 12, 34, 18);
    dovePath.cubicTo(40, 14, 46, 20, 42, 28);
    dovePath.cubicTo(36, 32, 28, 30, 20, 28);
    dovePath.close();
    canvas.drawPath(dovePath, dovePaint);

    // Trail of love hearts from dove
    for (int i = 0; i < 7; i++) {
      final x = 44.0 + i * 22;
      _drawHeart(canvas, Offset(x, 18 - (i % 2) * 5), 6.5, red);
    }

    // Bottom-right Red Love Letter Envelope
    final envRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width - 48, size.height - 34, 34, 22),
      const Radius.circular(4),
    );
    canvas.drawRRect(envRect, Paint()..color = red..style = PaintingStyle.fill);

    // Envelope flap lines
    final linePaint = Paint()..color = Colors.white..strokeWidth = 1.2..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width - 48, size.height - 34), Offset(size.width - 31, size.height - 20), linePaint);
    canvas.drawLine(Offset(size.width - 14, size.height - 34), Offset(size.width - 31, size.height - 20), linePaint);
    _drawHeart(canvas, Offset(size.width - 31, size.height - 20), 5, Colors.white);

    // Left & bottom hearts
    for (double y = 44; y < size.height - 20; y += 32) {
      _drawHeart(canvas, Offset(14, y), 7, red);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 8. Floral Corner Blossoms (Screenshot 4, Row 3, Tile 4)
class _FloralCornersPainter extends CustomPainter {
  const _FloralCornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const blossom = Color(0xFFFF70A6);
    const leaf = Color(0xFF4ADE80);

    void drawBouquet(Offset center) {
      final petalPaint = Paint()..color = blossom..style = PaintingStyle.fill;
      final leafPaint = Paint()..color = leaf..style = PaintingStyle.fill;

      // Leaves
      canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 8, center.dy - 8), width: 14, height: 7), leafPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 8, center.dy + 8), width: 14, height: 7), leafPaint);

      // 5 Petals
      for (int i = 0; i < 5; i++) {
        final angle = i * 2 * math.pi / 5;
        final px = center.dx + math.cos(angle) * 8;
        final py = center.dy + math.sin(angle) * 8;
        canvas.drawCircle(Offset(px, py), 6, petalPaint);
      }
      // Center bud
      canvas.drawCircle(center, 4, Paint()..color = const Color(0xFFFFD166));
    }

    drawBouquet(const Offset(22, 22));
    drawBouquet(Offset(size.width - 22, 22));
    drawBouquet(Offset(22, size.height - 22));
    drawBouquet(Offset(size.width - 22, size.height - 22));

    // Little floating flowers between corners
    _drawHeart(canvas, Offset(size.width / 2, 14), 8, blossom);
    _drawHeart(canvas, Offset(size.width / 2, size.height - 14), 8, blossom);
    _drawHeart(canvas, Offset(14, size.height / 2), 8, blossom);
    _drawHeart(canvas, Offset(size.width - 14, size.height / 2), 8, blossom);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 9. Party Balloons (Screenshot 4)
class _BalloonCelebrationPainter extends CustomPainter {
  const _BalloonCelebrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFFFF2A85),
      Color(0xFF00E5FF),
      Color(0xFFFFD700),
      Color(0xFF9D4EDD),
      Color(0xFF10B981),
    ];

    final balloonPaint = Paint()..style = PaintingStyle.fill;
    final stringPaint = Paint()..color = Colors.white54..strokeWidth = 1.0..style = PaintingStyle.stroke;

    final positions = [
      Offset(24, 24),
      Offset(48, 18),
      Offset(size.width - 48, 18),
      Offset(size.width - 24, 24),
      Offset(24, size.height - 24),
      Offset(size.width - 24, size.height - 24),
    ];

    for (int i = 0; i < positions.length; i++) {
      final pos = positions[i];
      balloonPaint.color = colors[i % colors.length];
      canvas.drawOval(Rect.fromCenter(center: pos, width: 16, height: 20), balloonPaint);
      canvas.drawLine(pos + const Offset(0, 10), pos + const Offset(4, 22), stringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 10. Halloween & Autumn Spooky Frame (Screenshot 4)
class _AutumnPumpkinPainter extends CustomPainter {
  const _AutumnPumpkinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const orange = Color(0xFFFF6F00);
    const gold = Color(0xFFFFD54F);

    void drawPumpkin(Offset center) {
      final pPaint = Paint()..color = orange..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(center: center, width: 22, height: 16), pPaint);
      canvas.drawOval(Rect.fromCenter(center: center, width: 14, height: 18), pPaint);
      // Stem
      final stemPaint = Paint()..color = const Color(0xFF2E7D32)..strokeWidth = 3;
      canvas.drawLine(center + const Offset(0, -9), center + const Offset(2, -14), stemPaint);
    }

    drawPumpkin(const Offset(24, 24));
    drawPumpkin(Offset(size.width - 24, 24));
    drawPumpkin(Offset(24, size.height - 24));
    drawPumpkin(Offset(size.width - 24, size.height - 24));

    // Golden stars in-between
    for (double x = 48; x < size.width - 40; x += 36) {
      _drawStar(canvas, Offset(x, 14), 7, gold);
      _drawStar(canvas, Offset(x, size.height - 14), 7, gold);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
