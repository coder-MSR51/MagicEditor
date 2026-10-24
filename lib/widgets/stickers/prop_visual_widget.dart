import 'dart:math' as math;
import 'package:flutter/material.dart';

class PropVisualWidget extends StatelessWidget {
  final String propId;
  final double width;
  final double height;

  const PropVisualWidget({
    super.key,
    required this.propId,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: _PropPainter(propId),
      ),
    );
  }
}

class _PropPainter extends CustomPainter {
  final String propId;

  _PropPainter(this.propId);

  @override
  void paint(Canvas canvas, Size size) {
    switch (propId) {
      case 'dog_ears':
        _drawDogEars(canvas, size);
        break;
      case 'dog_tongue':
        _drawDogTongue(canvas, size);
        break;
      case 'cat_ears_whiskers':
        _drawCatEarsAndWhiskers(canvas, size);
        break;
      case 'bunny_ears':
        _drawBunnyEars(canvas, size);
        break;
      case 'clown_face':
        _drawClownFace(canvas, size);
        break;
      case 'pig_snout':
        _drawPigSnout(canvas, size);
        break;
      case 'thug_pixel_glasses':
        _drawThugShades(canvas, size);
        break;
      case 'gold_chain':
        _drawGoldChain(canvas, size);
        break;
      case 'gentleman_mustache':
        _drawGentlemanMustache(canvas, size);
        break;
      case 'neon_shades':
        _drawNeonVisor(canvas, size);
        break;
      case 'anime_sparkle_eyes':
        _drawAnimeEyes(canvas, size);
        break;
      case 'heart_eyes':
        _drawHeartEyes(canvas, size);
        break;
      case 'blushing_cheeks':
        _drawBlushCheeks(canvas, size);
        break;
      case 'crying_tears':
        _drawAnimeTears(canvas, size);
        break;
      case 'angel_halo':
        _drawAngelHalo(canvas, size);
        break;
      case 'devil_horns':
        _drawDevilHorns(canvas, size);
        break;
      case 'gold_crown':
        _drawGoldCrown(canvas, size);
        break;
      case 'flower_crown':
        _drawFlowerCrown(canvas, size);
        break;
      case 'fire_flames':
        _drawFlames(canvas, size);
        break;
      case 'alien_antenna':
        _drawAlienAntenna(canvas, size);
        break;
      case 'bubble_gum':
        _drawBubbleGum(canvas, size);
        break;
      case 'party_hat':
        _drawPartyHat(canvas, size);
        break;
      default:
        _drawFallback(canvas, size);
    }
  }

  void _drawDogEars(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outerPaint = Paint()
      ..color = const Color(0xFF8D5B36)
      ..style = PaintingStyle.fill;
    final innerPaint = Paint()
      ..color = const Color(0xFFFFB6C1)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Left floppy ear
    final leftPath = Path()
      ..moveTo(w * 0.15, h * 0.1)
      ..cubicTo(w * 0.0, h * 0.2, w * 0.0, h * 0.7, w * 0.08, h * 0.95)
      ..cubicTo(w * 0.14, h * 1.05, w * 0.28, h * 0.85, w * 0.28, h * 0.4)
      ..close();
    canvas.drawPath(leftPath, outerPaint);
    canvas.drawPath(leftPath, strokePaint);

    final leftInner = Path()
      ..moveTo(w * 0.14, h * 0.25)
      ..cubicTo(w * 0.05, h * 0.4, w * 0.05, h * 0.7, w * 0.10, h * 0.85)
      ..cubicTo(w * 0.14, h * 0.9, w * 0.22, h * 0.7, w * 0.22, h * 0.45)
      ..close();
    canvas.drawPath(leftInner, innerPaint);

    // Right floppy ear
    final rightPath = Path()
      ..moveTo(w * 0.85, h * 0.1)
      ..cubicTo(w * 1.0, h * 0.2, w * 1.0, h * 0.7, w * 0.92, h * 0.95)
      ..cubicTo(w * 0.86, h * 1.05, w * 0.72, h * 0.85, w * 0.72, h * 0.4)
      ..close();
    canvas.drawPath(rightPath, outerPaint);
    canvas.drawPath(rightPath, strokePaint);

    final rightInner = Path()
      ..moveTo(w * 0.86, h * 0.25)
      ..cubicTo(w * 0.95, h * 0.4, w * 0.95, h * 0.7, w * 0.90, h * 0.85)
      ..cubicTo(w * 0.86, h * 0.9, w * 0.78, h * 0.7, w * 0.78, h * 0.45)
      ..close();
    canvas.drawPath(rightInner, innerPaint);
  }

  void _drawDogTongue(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final tonguePaint = Paint()
      ..color = const Color(0xFFFF5277)
      ..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..color = const Color(0xFFD62246)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final tonguePath = Path()
      ..moveTo(w * 0.25, 0)
      ..lineTo(w * 0.75, 0)
      ..cubicTo(w * 0.85, h * 0.4, w * 0.90, h * 0.8, w * 0.5, h * 1.0)
      ..cubicTo(w * 0.10, h * 0.8, w * 0.15, h * 0.4, w * 0.25, 0)
      ..close();

    canvas.drawPath(tonguePath, tonguePaint);

    // Center line
    final linePath = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.5, h * 0.75);
    canvas.drawPath(linePath, shadowPaint);
  }

  void _drawCatEarsAndWhiskers(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cat ears
    final earOuter = Paint()..color = const Color(0xFF222222);
    final earInner = Paint()..color = const Color(0xFFFF8DA1);

    // Left ear
    final lEar = Path()
      ..moveTo(w * 0.05, h * 0.45)
      ..lineTo(w * 0.18, 0)
      ..lineTo(w * 0.38, h * 0.35)
      ..close();
    canvas.drawPath(lEar, earOuter);

    final lEarIn = Path()
      ..moveTo(w * 0.10, h * 0.38)
      ..lineTo(w * 0.18, h * 0.08)
      ..lineTo(w * 0.32, h * 0.30)
      ..close();
    canvas.drawPath(lEarIn, earInner);

    // Right ear
    final rEar = Path()
      ..moveTo(w * 0.95, h * 0.45)
      ..lineTo(w * 0.82, 0)
      ..lineTo(w * 0.62, h * 0.35)
      ..close();
    canvas.drawPath(rEar, earOuter);

    final rEarIn = Path()
      ..moveTo(w * 0.90, h * 0.38)
      ..lineTo(w * 0.82, h * 0.08)
      ..lineTo(w * 0.68, h * 0.30)
      ..close();
    canvas.drawPath(rEarIn, earInner);

    // Pink nose
    final nosePaint = Paint()..color = const Color(0xFFFF5277);
    final nosePath = Path()
      ..moveTo(w * 0.45, h * 0.68)
      ..lineTo(w * 0.55, h * 0.68)
      ..lineTo(w * 0.50, h * 0.75)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // Whiskers
    final whiskerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Left whiskers
    canvas.drawLine(Offset(w * 0.40, h * 0.70), Offset(w * 0.10, h * 0.65), whiskerPaint);
    canvas.drawLine(Offset(w * 0.40, h * 0.73), Offset(w * 0.08, h * 0.74), whiskerPaint);
    canvas.drawLine(Offset(w * 0.40, h * 0.76), Offset(w * 0.12, h * 0.83), whiskerPaint);

    // Right whiskers
    canvas.drawLine(Offset(w * 0.60, h * 0.70), Offset(w * 0.90, h * 0.65), whiskerPaint);
    canvas.drawLine(Offset(w * 0.60, h * 0.73), Offset(w * 0.92, h * 0.74), whiskerPaint);
    canvas.drawLine(Offset(w * 0.60, h * 0.76), Offset(w * 0.88, h * 0.83), whiskerPaint);
  }

  void _drawBunnyEars(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outer = Paint()..color = Colors.white;
    final inner = Paint()..color = const Color(0xFFFFB6C1);

    // Left tall bunny ear
    final lEar = Path()
      ..moveTo(w * 0.25, h * 0.95)
      ..cubicTo(w * 0.05, h * 0.6, w * 0.1, h * 0.05, w * 0.32, 0)
      ..cubicTo(w * 0.48, h * 0.05, w * 0.45, h * 0.6, w * 0.38, h * 0.95)
      ..close();
    canvas.drawPath(lEar, outer);

    final lIn = Path()
      ..moveTo(w * 0.27, h * 0.85)
      ..cubicTo(w * 0.15, h * 0.55, w * 0.18, h * 0.15, w * 0.32, h * 0.08)
      ..cubicTo(w * 0.42, h * 0.15, w * 0.40, h * 0.55, w * 0.35, h * 0.85)
      ..close();
    canvas.drawPath(lIn, inner);

    // Right tall bunny ear
    final rEar = Path()
      ..moveTo(w * 0.75, h * 0.95)
      ..cubicTo(w * 0.95, h * 0.6, w * 0.9, h * 0.05, w * 0.68, 0)
      ..cubicTo(w * 0.52, h * 0.05, w * 0.55, h * 0.6, w * 0.62, h * 0.95)
      ..close();
    canvas.drawPath(rEar, outer);

    final rIn = Path()
      ..moveTo(w * 0.73, h * 0.85)
      ..cubicTo(w * 0.85, h * 0.55, w * 0.82, h * 0.15, w * 0.68, h * 0.08)
      ..cubicTo(w * 0.58, h * 0.15, w * 0.60, h * 0.55, w * 0.65, h * 0.85)
      ..close();
    canvas.drawPath(rIn, inner);
  }

  void _drawClownFace(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Colorful curly afro wig clusters on sides
    final colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple];
    for (int i = 0; i < 6; i++) {
      final p = Paint()..color = colors[i];
      // Left wig curls
      canvas.drawCircle(Offset(w * 0.15 + (i % 2) * 15, h * 0.2 + i * 15), 18, p);
      // Right wig curls
      canvas.drawCircle(Offset(w * 0.85 - (i % 2) * 15, h * 0.2 + i * 15), 18, p);
    }

    // Red clown nose in center
    final nosePaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(Offset(w * 0.5, h * 0.65), 24, nosePaint);

    // White shine highlight on nose
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.46, h * 0.60), 6, shinePaint);
  }

  void _drawPigSnout(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final snoutPaint = Paint()..color = const Color(0xFFFF9BB2);
    final nostrilPaint = Paint()..color = const Color(0xFFC75D74);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(h * 0.45)),
      snoutPaint,
    );

    // Two oval nostrils
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.35, h * 0.5), width: w * 0.18, height: h * 0.45),
      nostrilPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.65, h * 0.5), width: w * 0.18, height: h * 0.45),
      nostrilPaint,
    );
  }

  void _drawThugShades(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()..color = Colors.black;
    final glint = Paint()..color = Colors.white;

    // 8-bit stepped pixel glasses frame
    final leftLens = Rect.fromLTWH(w * 0.05, h * 0.15, w * 0.40, h * 0.7);
    final rightLens = Rect.fromLTWH(w * 0.55, h * 0.15, w * 0.40, h * 0.7);
    final bridge = Rect.fromLTWH(w * 0.42, h * 0.35, w * 0.16, h * 0.25);

    canvas.drawRect(leftLens, p);
    canvas.drawRect(rightLens, p);
    canvas.drawRect(bridge, p);

    // Pixel glints (white blocks)
    final step = w * 0.05;
    canvas.drawRect(Rect.fromLTWH(w * 0.08, h * 0.25, step, step), glint);
    canvas.drawRect(Rect.fromLTWH(w * 0.08 + step, h * 0.25 + step, step, step), glint);
    canvas.drawRect(Rect.fromLTWH(w * 0.58, h * 0.25, step, step), glint);
    canvas.drawRect(Rect.fromLTWH(w * 0.58 + step, h * 0.25 + step, step, step), glint);
  }

  void _drawGoldChain(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final chainPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(w * 0.1, 0)
      ..cubicTo(w * 0.15, h * 0.8, w * 0.85, h * 0.8, w * 0.9, 0);

    canvas.drawPath(path, chainPaint);

    // Dollar sign pendant
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '💰',
        style: TextStyle(fontSize: 34),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(w * 0.5 - 17, h * 0.65));
  }

  void _drawGentlemanMustache(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Monocle on right side
    final monoclePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(w * 0.75, h * 0.3), 22, monoclePaint);
    canvas.drawLine(Offset(w * 0.92, h * 0.3), Offset(w * 0.92, h * 0.85), monoclePaint..strokeWidth = 2);

    // Handlebar mustache
    final mPaint = Paint()..color = const Color(0xFF2B221B);
    final mPath = Path()
      ..moveTo(w * 0.5, h * 0.70)
      ..cubicTo(w * 0.35, h * 0.55, w * 0.15, h * 0.65, w * 0.05, h * 0.5)
      ..cubicTo(w * 0.12, h * 0.85, w * 0.38, h * 0.88, w * 0.5, h * 0.80)
      ..cubicTo(w * 0.62, h * 0.88, w * 0.88, h * 0.85, w * 0.95, h * 0.5)
      ..cubicTo(w * 0.85, h * 0.65, w * 0.65, h * 0.55, w * 0.5, h * 0.70)
      ..close();
    canvas.drawPath(mPath, mPaint);
  }

  void _drawNeonVisor(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final glow = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final visor = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00F0FF), Color(0xFFFF007F)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.15, w, h * 0.7), const Radius.circular(16));
    canvas.drawRRect(rrect, glow);
    canvas.drawRRect(rrect, visor);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.1, h * 0.5), Offset(w * 0.9, h * 0.5), line);
  }

  void _drawAnimeEyes(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void drawOneEye(Offset center, double radius) {
      // Base dark violet iris
      final iris = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF8A2BE2), Color(0xFF19053B)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, iris);

      // Star shine
      final star = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(center.dx - radius * 0.3, center.dy - radius * 0.3), radius * 0.35, star);
      canvas.drawCircle(Offset(center.dx + radius * 0.35, center.dy + radius * 0.3), radius * 0.18, star);
    }

    drawOneEye(Offset(w * 0.25, h * 0.5), h * 0.42);
    drawOneEye(Offset(w * 0.75, h * 0.5), h * 0.42);
  }

  void _drawHeartEyes(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void drawHeart(Offset center, double s) {
      final p = Paint()
        ..color = const Color(0xFFFF1744)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
      final path = Path();
      path.moveTo(center.dx, center.dy + s * 0.4);
      path.cubicTo(center.dx - s, center.dy - s * 0.2, center.dx - s * 0.5, center.dy - s * 0.8, center.dx, center.dy - s * 0.3);
      path.cubicTo(center.dx + s * 0.5, center.dy - s * 0.8, center.dx + s, center.dy - s * 0.2, center.dx, center.dy + s * 0.4);
      path.close();
      canvas.drawPath(path, p);
    }

    drawHeart(Offset(w * 0.25, h * 0.5), h * 0.5);
    drawHeart(Offset(w * 0.75, h * 0.5), h * 0.5);
  }

  void _drawBlushCheeks(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final blush = Paint()
      ..color = const Color(0xFFFF69B4).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.2, h * 0.5), width: w * 0.28, height: h * 0.7), blush);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.8, h * 0.5), width: w * 0.28, height: h * 0.7), blush);
  }

  void _drawAnimeTears(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tear = Paint()
      ..color = const Color(0xFF00B0FF).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    void drawCascade(double x) {
      final p = Path()
        ..moveTo(x, 0)
        ..lineTo(x - 12, h)
        ..lineTo(x + 12, h)
        ..close();
      canvas.drawPath(p, tear);
    }

    drawCascade(w * 0.25);
    drawCascade(w * 0.75);
  }

  void _drawAngelHalo(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final glow = Paint()
      ..color = const Color(0xFFFFEA00).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final ring = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;

    final rect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.5), width: w * 0.85, height: h * 0.55);
    canvas.drawOval(rect, glow);
    canvas.drawOval(rect, ring);
  }

  void _drawDevilHorns(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final hornPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xFF8B0000), Color(0xFFFF0055)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Left horn
    final lHorn = Path()
      ..moveTo(w * 0.25, h * 0.95)
      ..cubicTo(w * 0.22, h * 0.5, w * 0.05, h * 0.3, w * 0.08, 0)
      ..cubicTo(w * 0.22, h * 0.2, w * 0.35, h * 0.5, w * 0.38, h * 0.95)
      ..close();
    canvas.drawPath(lHorn, hornPaint);

    // Right horn
    final rHorn = Path()
      ..moveTo(w * 0.75, h * 0.95)
      ..cubicTo(w * 0.78, h * 0.5, w * 0.95, h * 0.3, w * 0.92, 0)
      ..cubicTo(w * 0.78, h * 0.2, w * 0.65, h * 0.5, w * 0.62, h * 0.95)
      ..close();
    canvas.drawPath(rHorn, hornPaint);
  }

  void _drawGoldCrown(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final crown = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFEA00), Color(0xFFFF9800)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path()
      ..moveTo(0, h * 0.9)
      ..lineTo(w, h * 0.9)
      ..lineTo(w * 0.95, h * 0.2)
      ..lineTo(w * 0.72, h * 0.6)
      ..lineTo(w * 0.5, 0)
      ..lineTo(w * 0.28, h * 0.6)
      ..lineTo(w * 0.05, h * 0.2)
      ..close();

    canvas.drawPath(path, crown);

    // Rubies
    final ruby = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(Offset(w * 0.5, h * 0.15), 6, ruby);
    canvas.drawCircle(Offset(w * 0.08, h * 0.28), 5, ruby);
    canvas.drawCircle(Offset(w * 0.92, h * 0.28), 5, ruby);
  }

  void _drawFlowerCrown(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final colors = [const Color(0xFFFFB6C1), const Color(0xFFE6E6FA), const Color(0xFFFFF0F5), const Color(0xFFFFD1DC)];
    for (int i = 0; i < 7; i++) {
      final cx = w * 0.12 + i * (w * 0.13);
      final cy = h * 0.5 + math.sin(i * 0.8) * 8;
      final p = Paint()..color = colors[i % colors.length];

      // Petals
      for (int a = 0; a < 5; a++) {
        final angle = a * (math.pi * 2 / 5);
        canvas.drawCircle(Offset(cx + math.cos(angle) * 9, cy + math.sin(angle) * 9), 7, p);
      }
      // Yellow center
      canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = const Color(0xFFFFD700));
    }
  }

  void _drawFlames(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outerFlame = Paint()
      ..color = const Color(0xFFFF3D00).withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
    final innerFlame = Paint()..color = const Color(0xFFFFEA00);

    final path = Path()
      ..moveTo(0, h)
      ..cubicTo(w * 0.15, h * 0.4, w * 0.25, h * 0.1, w * 0.35, 0)
      ..cubicTo(w * 0.45, h * 0.5, w * 0.55, h * 0.2, w * 0.65, 0)
      ..cubicTo(w * 0.75, h * 0.4, w * 0.85, h * 0.1, w, h)
      ..close();

    canvas.drawPath(path, outerFlame);

    final innerPath = Path()
      ..moveTo(w * 0.15, h)
      ..cubicTo(w * 0.3, h * 0.6, w * 0.4, h * 0.4, w * 0.5, h * 0.25)
      ..cubicTo(w * 0.6, h * 0.4, w * 0.7, h * 0.6, w * 0.85, h)
      ..close();
    canvas.drawPath(innerPath, innerFlame);
  }

  void _drawAlienAntenna(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final neon = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final bulb = Paint()
      ..color = const Color(0xFF00E676)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6);

    // Left stem
    final lStem = Path()
      ..moveTo(w * 0.3, h)
      ..cubicTo(w * 0.2, h * 0.5, w * 0.1, h * 0.3, w * 0.15, h * 0.15);
    canvas.drawPath(lStem, neon);
    canvas.drawCircle(Offset(w * 0.15, h * 0.15), 12, bulb);

    // Right stem
    final rStem = Path()
      ..moveTo(w * 0.7, h)
      ..cubicTo(w * 0.8, h * 0.5, w * 0.9, h * 0.3, w * 0.85, h * 0.15);
    canvas.drawPath(rStem, neon);
    canvas.drawCircle(Offset(w * 0.85, h * 0.15), 12, bulb);
  }

  void _drawBubbleGum(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gum = Paint()
      ..color = const Color(0xFFFF4081).withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.45, gum);

    // Bubble shine
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.35, h * 0.35), width: w * 0.2, height: h * 0.12),
      shine,
    );
  }

  void _drawPartyHat(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final hat = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF007F), Color(0xFF7928CA), Color(0xFF00DFD8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path()
      ..moveTo(w * 0.1, h * 0.95)
      ..lineTo(w * 0.9, h * 0.95)
      ..lineTo(w * 0.5, h * 0.1)
      ..close();
    canvas.drawPath(path, hat);

    // Pom pom
    canvas.drawCircle(Offset(w * 0.5, h * 0.08), 10, Paint()..color = const Color(0xFFFFD700));
  }

  void _drawFallback(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.cyan;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 3, p);
  }

  @override
  bool shouldRepaint(covariant _PropPainter oldDelegate) => oldDelegate.propId != propId;
}
