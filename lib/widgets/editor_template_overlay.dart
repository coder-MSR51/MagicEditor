import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/editor_template_model.dart';

class EditorTemplateOverlay extends StatelessWidget {
  final EditorTemplate template;
  final Widget child;
  final Uint8List? imageBytes;
  final String songTitle;
  final String artistName;

  const EditorTemplateOverlay({
    super.key,
    required this.template,
    required this.child,
    this.imageBytes,
    this.songTitle = 'Golden Hour',
    this.artistName = 'JVKE • Memories Edit',
  });

  @override
  Widget build(BuildContext context) {
    if (template == EditorTemplate.none) {
      return child;
    }

    switch (template) {
      // Category 1: Vogue & Magazine
      case EditorTemplate.vogueParis:
        return _buildVogueParis();
      case EditorTemplate.vogueMinimalist:
        return _buildVogueMinimalist();
      case EditorTemplate.vogueStreetwear:
        return _buildVogueStreetwear();

      // Category 2: Retro Vinyl & Disc
      case EditorTemplate.vinylClassic:
        return _buildVinylClassic();
      case EditorTemplate.vinylSynthwave:
        return _buildVinylSynthwave();
      case EditorTemplate.vinylAcrylic:
        return _buildVinylAcrylic();

      // Category 3: Cyber HUD & Sci-Fi
      case EditorTemplate.hudCyberpunk:
        return _buildHudCyberpunk();
      case EditorTemplate.hudTelemetry:
        return _buildHudTelemetry();
      case EditorTemplate.hudJarvis:
        return _buildHudJarvis();

      // Category 4: Music Card & Player
      case EditorTemplate.musicSpotify:
        return _buildMusicSpotify();
      case EditorTemplate.musicCassette:
        return _buildMusicCassette();
      case EditorTemplate.musicSpatial:
        return _buildMusicSpatial();

      case EditorTemplate.none:
        return child;
    }
  }

  // ==========================================
  // 1. VOGUE PARIS HAUTE COUTURE
  // ==========================================
  Widget _buildVogueParis() {
    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.center,
      children: [
        child,

        // Subtle gradient shading for text readability
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.70),
                  ],
                  stops: const [0.0, 0.22, 0.75, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Golden Hairline Outer Border
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.55), width: 1.0),
              ),
            ),
          ),
        ),

        // Top Masthead: VOGUE
        Positioned(
          top: 18,
          left: 18,
          right: 18,
          child: IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'V O G U E',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 8,
                      shadows: [
                        const Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2)),
                        Shadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.7), blurRadius: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 0.6),
                    ),
                    child: Text(
                      'PARIS • MILAN • NEW YORK • TOKYO • ISSUE N° 42',
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE5C07B),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Editorial Side Blurbs
        Positioned(
          left: 20,
          top: 110,
          child: IgnorePointer(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE NEW\nELEGANCE',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      shadows: [const Shadow(color: Colors.black, blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'FALL / WINTER 2026\nSPECIAL EDITORIAL',
                    style: GoogleFonts.montserrat(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE5C07B),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          right: 20,
          top: 150,
          child: IgnorePointer(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ICONIC\nSILHOUETTES',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      shadows: [const Shadow(color: Colors.black, blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MINIMALISM REDEFINED',
                    style: GoogleFonts.montserrat(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom Footer: Barcode & Pricing
        Positioned(
          bottom: 18,
          left: 20,
          right: 20,
          child: IgnorePointer(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Barcode Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(24, (i) {
                            final widths = [1.0, 2.0, 1.0, 3.0, 1.5, 2.5, 1.0, 2.0];
                            final w = widths[i % widths.length];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 0.7),
                              width: w,
                              height: 18,
                              color: Colors.black,
                            );
                          }),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '0 71486 02345 6',
                          style: TextStyle(
                            fontSize: 6.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Price & Issue info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$12.00 US / £9.50 UK',
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                      Text(
                        'EXCLUSIVE COLLECTOR ISSUE',
                        style: GoogleFonts.montserrat(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD4AF37),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. HARPER'S MINIMALIST GALLERY POSTER
  // ==========================================
  Widget _buildVogueMinimalist() {
    return Container(
      color: const Color(0xFFF6F4EE), // Warm Gallery Ivory
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          // Header archive tag
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EXHIBITION ARCHIVE // N° 08',
                    style: GoogleFonts.inter(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'SEOUL • COPENHAGEN • PARIS',
                    style: GoogleFonts.inter(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Central Photo Canvas with subtle border
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            ),
          ),

          // Footer Typography
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'M O D E R N I S M',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F2937),
                      letterSpacing: 5,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 16, height: 1, color: Colors.black26),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          'VOL. 08 • 35MM CONTEMPORARY STUDY • CURATED MOMENTS',
                          style: GoogleFonts.inter(
                            fontSize: 6.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4B5563),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Container(width: 16, height: 1, color: Colors.black26),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. Y2K TOKYO STREETWEAR ZINE
  // ==========================================
  Widget _buildVogueStreetwear() {
    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.center,
      children: [
        child,

        // Distressed / Cyber Vignette
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFF0055), width: 2.0),
                gradient: RadialGradient(
                  radius: 0.95,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.50),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Top Masthead: NEO CULTURE
        Positioned(
          top: 14,
          left: 14,
          right: 14,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: const Color(0xFFFF0055),
                        child: Text(
                          'LIMITED ISSUE',
                          style: GoogleFonts.robotoMono(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '東京ストリートスタイル // SHIBUYA',
                        style: GoogleFonts.notoSans(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00F0FF),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'NEO CULTURE',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3,
                      shadows: [
                        const Shadow(color: Color(0xFFFF0055), offset: Offset(-2, 2)),
                        const Shadow(color: Color(0xFF00F0FF), offset: Offset(2, -1)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Floating Badges
        Positioned(
          left: 16,
          bottom: 70,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: -0.06,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
                ),
                child: Text(
                  '★ 100% RAW FOOTAGE ★',
                  style: GoogleFonts.robotoMono(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),

        Positioned(
          right: 14,
          top: 110,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
                color: Colors.black87,
              ),
              child: const Text(
                '01/500\nEDITION',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00F0FF),
                ),
              ),
            ),
          ),
        ),

        // Bottom Warning Hazard Tape
        Positioned(
          bottom: 12,
          left: 14,
          right: 14,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                border: Border.all(color: const Color(0xFFFF0055), width: 1),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '/// CAUTION: OVERDRIVE ///',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF0055),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'VERIFIED GEN-Z AUTHENTIC',
                      style: GoogleFonts.robotoMono(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 4. 33 RPM CLASSIC GATEFOLD VINYL
  // ==========================================
  Widget _buildVinylClassic() {
    return Container(
      color: const Color(0xFF121214),
      padding: const EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Vinyl Record sliding out to the right
          Positioned(
            right: 4,
            child: SizedBox(
              width: 170,
              height: 170,
              child: CustomPaint(
                painter: _RealisticVinylPainter(
                  grooveColor: const Color(0xFF1E2024),
                  rimColor: const Color(0xFF2A2D34),
                ),
                child: Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                      gradient: const RadialGradient(
                        colors: [Color(0xFF8B0000), Color(0xFF4A0000)],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF121214),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Album Jacket / Sleeve holding the photo
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.80,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 16,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      child,

                      // Ring-wear circular imprint
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 28),
                            ),
                          ),
                        ),
                      ),

                      // Vintage Top Badge
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: const Color(0xFFD4AF37), width: 0.6),
                          ),
                          child: const Text(
                            'STEREO LP • 33⅓ RPM',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. NEON SYNTHWAVE 45 RPM
  // ==========================================
  Widget _buildVinylSynthwave() {
    return Container(
      color: const Color(0xFF0B0616),
      child: Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.center,
        children: [
          child,

          // Cyber Grid and Neon Glow overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF007F).withValues(alpha: 0.25),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Central Neon Vinyl Grooves Ring
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                      width: 2.0,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF007F).withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top Neon Header
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SIDE A // 45 RPM',
                      style: GoogleFonts.orbitron(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00F0FF),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'SYNTHWAVE 1984',
                      style: GoogleFonts.orbitron(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF007F),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Track Badge
          Positioned(
            bottom: 14,
            left: 14,
            right: 14,
            child: IgnorePointer(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00F0FF), width: 1),
                    ),
                    child: Text(
                      'MIDNIGHT MEMORIES [03:42]',
                      style: GoogleFonts.orbitron(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. CLEAR ACRYLIC PICTURE DISC
  // ==========================================
  Widget _buildVinylAcrylic() {
    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.center,
      children: [
        child,

        // Transparent Vinyl Grooves Overlay
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _AcrylicGroovesPainter(),
            ),
          ),
        ),

        // Center Aluminum Spindle Hub
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.75),
                  border: Border.all(color: Colors.white70, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black87, blurRadius: 10),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'PICTURE DISC\n33 RPM',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 6,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Corner Clamps
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'LTD. EDITION 12" LP',
              style: TextStyle(fontSize: 7, color: Colors.white70, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 7. CYBERPUNK 2077 NIGHT CITY HUD
  // ==========================================
  Widget _buildHudCyberpunk() {
    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.center,
      children: [
        child,

        // Top Status Bar
        Positioned(
          top: 14,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'REC ● OPTICAL: 4.8X',
                        style: GoogleFonts.orbitron(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00F0FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'BIO_METRICS: STABLE [99.8%]',
                    style: GoogleFonts.orbitron(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Center Targeting Reticle
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _CyberReticlePainter(color: const Color(0xFF00F0FF)),
                ),
              ),
            ),
          ),
        ),

        // Facial Focus Brackets
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Container(
                width: 180,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.35), width: 1),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    color: const Color(0xFF00F0FF),
                    child: const Text(
                      'LOCK 99.8%',
                      style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bottom Diagnostic Stream
        Positioned(
          bottom: 14,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SECTOR: NIGHT CITY // 04\nSYS_MEM: 0x7FFF5FBFFD04',
                    style: GoogleFonts.robotoMono(
                      fontSize: 7,
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'BATTERY: [████████░░] 82%\nSIGNAL: 5G QUANTUM',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.robotoMono(
                      fontSize: 7,
                      color: Colors.amberAccent,
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

  // ==========================================
  // 8. NASA SPACE TELEMETRY
  // ==========================================
  Widget _buildHudTelemetry() {
    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.center,
      children: [
        child,

        // Precision 360 Degree Radar Compass
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _RadarCompassPainter(),
                ),
              ),
            ),
          ),
        ),

        // Top Telemetry Bar
        Positioned(
          top: 14,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORBITAL TELEMETRY // LUNAR 09',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'ALT: 420.5 KM • VEL: 7.66 KM/S',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 7.5,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'NASA / VOYAGER',
                      style: GoogleFonts.shareTechMono(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom Coordinates & Sensor Info
        Positioned(
          bottom: 14,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LAT: 28°36\'48"N  LONG: 77°12\'04"E\nHEADING: 312° NW • ELEV: +14.2°',
                    style: GoogleFonts.shareTechMono(
                      fontSize: 7.5,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'F/1.2 • 1/8000s • ISO 50\n35MM RAW DNG SENSOR',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.shareTechMono(
                      fontSize: 7.5,
                      color: Colors.white70,
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

  // ==========================================
  // 9. IRON MECH JARVIS HUD
  // ==========================================
  Widget _buildHudJarvis() {
    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.center,
      children: [
        child,

        // Corner Hexagonal Energy Grid
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _HexShieldPainter(),
            ),
          ),
        ),

        // Center Arc-Reactor Power Ring
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.6), width: 1.5),
                ),
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.45), width: 1.0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Top Status Header
        Positioned(
          top: 14,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'JARVIS // TACTICAL HUD',
                    style: GoogleFonts.orbitron(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFB300),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'ENERGY: 100% NOMINAL',
                    style: GoogleFonts.orbitron(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00E5FF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom Combat Calipers
        Positioned(
          bottom: 14,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ARMOR SHIELD: 100%\nTHREAT LEVEL: 0.0',
                    style: GoogleFonts.orbitron(
                      fontSize: 7.5,
                      color: const Color(0xFFFFB300),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'OBJECT MATCH FOUND\nTRACKING ACTIVE',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.orbitron(
                      fontSize: 7.5,
                      color: const Color(0xFF00E5FF),
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

  // ==========================================
  // 10. SPOTIFY FROSTED GLASS PLAYER
  // ==========================================
  Widget _buildMusicSpotify() {
    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.center,
      children: [
        child,

        // Floating Frosted Glass Acrylic Player Card at Bottom
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Song Title & Artist + Heart
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              songTitle.isNotEmpty ? songTitle : 'Golden Hour',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              artistName.isNotEmpty ? artistName : 'JVKE • Memories Edit',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.favorite_rounded, color: Color(0xFF1DB954), size: 18),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Scrubber Bar
                  Row(
                    children: [
                      const Text('1:24', style: TextStyle(fontSize: 8.5, color: Colors.white54)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: 0.38,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1DB954),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('3:45', style: TextStyle(fontSize: 8.5, color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Media Controls
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.shuffle_rounded, color: Colors.white54, size: 15),
                        SizedBox(width: 14),
                        Icon(Icons.skip_previous_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 14),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0xFF1DB954),
                          child: Icon(Icons.pause_rounded, color: Colors.black, size: 18),
                        ),
                        SizedBox(width: 14),
                        Icon(Icons.skip_next_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 14),
                        Icon(Icons.repeat_rounded, color: Colors.white54, size: 15),
                      ],
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

  // ==========================================
  // 11. 90s VINTAGE CASSETTE MIXTAPE
  // ==========================================
  Widget _buildMusicCassette() {
    return Container(
      color: const Color(0xFF1E1B18),
      padding: const EdgeInsets.all(12),
      child: Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.center,
        children: [
          // Cassette Housing
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2B2623),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4A423D), width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                // Top Tape Label
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF6EE), // Cream paper sticker
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          songTitle.isNotEmpty ? 'SIDE A • ${songTitle.toUpperCase()}' : 'SIDE A • OUR MEMORIES \'26',
                          style: GoogleFonts.caveat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '90 MIN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Center Window displaying the photo with Dual Spools
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black54, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          child,

                          // Dual Tape Spools Left & Right
                          Positioned(
                            left: 14,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: const Icon(Icons.star_outline_rounded, size: 20, color: Colors.black87),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 14,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: const Icon(Icons.star_outline_rounded, size: 20, color: Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Tape Specs
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'TYPE II • HIGH BIAS (CrO2) • DOLBY NR SYSTEM',
                      style: GoogleFonts.inter(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white38,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 12. APPLE SPATIAL AUDIO MASTER CARD
  // ==========================================
  Widget _buildMusicSpatial() {
    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.center,
      children: [
        child,

        // Floating Apple Music Spatial Audio Card at Bottom
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badges: Lossless & Spatial Audio (FittedBox ensures 0 overflow)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAppleBadge('LOSSLESS AUDIO'),
                        const SizedBox(width: 5),
                        _buildAppleBadge('APPLE DIGITAL MASTER'),
                        const SizedBox(width: 5),
                        _buildAppleBadge('SPATIAL AUDIO'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),

                  // Song & Artist
                  Text(
                    songTitle.isNotEmpty ? songTitle : 'Midnight Memories (Spatial Mix)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artistName.isNotEmpty ? '🎧 $artistName' : '🎧 Listening on AirPods Max',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9.5, color: Colors.white60),
                  ),
                  const SizedBox(height: 7),

                  // Soundwave Barcode (FittedBox ensures 0 overflow)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(28, (i) {
                        final heights = [6.0, 12.0, 18.0, 8.0, 14.0, 22.0, 10.0, 16.0];
                        final h = heights[i % heights.length];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.2),
                          width: 2.5,
                          height: h,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
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

  Widget _buildAppleBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 6.5,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ==========================================
// CUSTOM PAINTERS FOR HIGH-PERFORMANCE FX
// ==========================================

class _RealisticVinylPainter extends CustomPainter {
  final Color grooveColor;
  final Color rimColor;

  _RealisticVinylPainter({required this.grooveColor, required this.rimColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer Vinyl Disc Body
    final bodyPaint = Paint()..color = grooveColor;
    canvas.drawCircle(center, radius, bodyPaint);

    // Subtle micro-grooves
    final groovePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double r = radius * 0.45; r < radius * 0.95; r += 5.0) {
      canvas.drawCircle(center, r, groovePaint);
    }

    // Outer Rim
    final rimPaint = Paint()
      ..color = rimColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AcrylicGroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) * 0.48;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (double r = maxR * 0.35; r < maxR; r += 7.0) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CyberReticlePainter extends CustomPainter {
  final Color color;
  _CyberReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * 0.7, ringPaint);

    final crossPaint = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    canvas.drawLine(Offset(center.dx - radius - 8, center.dy), Offset(center.dx + radius + 8, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius - 8), Offset(center.dx, center.dy + radius + 8), crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final paint = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(center, r * 0.5, paint);

    // Crosshairs
    canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - r), Offset(center.dx, center.dy + r), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HexShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double hexSize = 22.0;
    for (double y = 0; y < size.height * 0.25; y += hexSize * 1.5) {
      for (double x = 0; x < size.width; x += hexSize * 1.732) {
        _drawHex(canvas, Offset(x, y), hexSize, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i) * math.pi / 180;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
