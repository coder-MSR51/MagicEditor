import 'package:flutter/material.dart';

enum BackgroundType {
  none('None', Icons.block_rounded, 'none'),
  blur('Portrait Blur', Icons.blur_on_rounded, 'blur'),
  gradient('Gradient Backdrop', Icons.gradient_rounded, 'gradient'),
  heartConfetti('Cute Hearts', Icons.favorite_rounded, 'heart'),
  fairySparkle('Fairy Sparkles', Icons.auto_awesome_rounded, 'sparkle'),
  pastelValentine('Pastel Hearts', Icons.favorite_border_rounded, 'heart'),
  crownKey('Crown & Key', Icons.workspace_premium_rounded, 'crown'),
  silverStars('Silver Stars', Icons.star_rounded, 'sparkle'),
  crimsonGarland('Heart Chain', Icons.favorite_rounded, 'heart'),
  loveLetterDove('Dove Love Letter', Icons.mark_email_read_rounded, 'heart'),
  floralCorners('Floral Corners', Icons.local_florist_rounded, 'flower'),
  balloonCelebration('Party Balloons', Icons.celebration_rounded, 'balloon'),
  autumnPumpkin('Halloween Spooky', Icons.theater_comedy_rounded, 'pumpkin'),
  polaroid('Polaroid Frame', Icons.photo_size_select_actual_outlined, 'frame'),
  filmStrip('35mm Film Strip', Icons.movie_creation_outlined, 'frame'),
  neonBorder('Neon Cyber Frame', Icons.crop_portrait_rounded, 'frame');

  final String title;
  final IconData icon;
  final String category;
  const BackgroundType(this.title, this.icon, this.category);
}

class BackgroundGradients {
  static const List<List<Color>> presets = [
    [Color(0xFF00F0FF), Color(0xFFFF007F)], // Cyberpunk
    [Color(0xFFFF512F), Color(0xFFDD2476)], // Sunset Blaze
    [Color(0xFF7928CA), Color(0xFFFF0080)], // Neon Violet
    [Color(0xFF11998E), Color(0xFF38EF7D)], // Emerald Lush
    [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)], // Retro Sunset
    [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], // Deep Oceanic
    [Color(0xFFFFB6C1), Color(0xFFE6E6FA)], // Pastel Dream
    [Color(0xFF232526), Color(0xFF414345)], // Carbon Dark
    [Colors.white, Color(0xFFECE9E6)], // Minimalist White
  ];
}
