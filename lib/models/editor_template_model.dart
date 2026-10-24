import 'package:flutter/material.dart';

enum EditorTemplateCategory {
  all('All', Icons.auto_awesome_rounded),
  vogue('Vogue & Magazine', Icons.auto_stories_rounded),
  vinyl('Retro Vinyl Disc', Icons.album_rounded),
  hud('Cyber HUD', Icons.camera_enhance_rounded),
  music('Music Card', Icons.music_note_rounded);

  final String label;
  final IconData icon;
  const EditorTemplateCategory(this.label, this.icon);
}

enum EditorTemplate {
  none(
    id: 'none',
    title: 'Original',
    subtitle: 'No Template',
    category: EditorTemplateCategory.all,
    icon: Icons.block_rounded,
    gradient: [Color(0xFF475569), Color(0xFF1E293B)],
    badge: 'Raw',
  ),

  // --- Category 1: Vogue & Magazine Editorial ---
  vogueParis(
    id: 'vogue_paris',
    title: 'Vogue Paris',
    subtitle: 'Haute Couture',
    category: EditorTemplateCategory.vogue,
    icon: Icons.auto_stories_rounded,
    gradient: [Color(0xFFD97706), Color(0xFFF59E0B)],
    badge: 'Magazine',
  ),
  vogueMinimalist(
    id: 'vogue_minimalist',
    title: 'Harper Minimal',
    subtitle: 'Gallery Poster',
    category: EditorTemplateCategory.vogue,
    icon: Icons.museum_rounded,
    gradient: [Color(0xFF64748B), Color(0xFF94A3B8)],
    badge: 'Editorial',
  ),
  vogueStreetwear(
    id: 'vogue_streetwear',
    title: 'Y2K Streetwear',
    subtitle: 'Tokyo Neo Zine',
    category: EditorTemplateCategory.vogue,
    icon: Icons.local_fire_department_rounded,
    gradient: [Color(0xFFEF4444), Color(0xFFF97316)],
    badge: 'Trending',
  ),

  // --- Category 2: Retro Vinyl & Disc ---
  vinylClassic(
    id: 'vinyl_classic',
    title: '33 RPM Classic',
    subtitle: 'Gatefold Vinyl',
    category: EditorTemplateCategory.vinyl,
    icon: Icons.album_rounded,
    gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    badge: 'Vinyl',
  ),
  vinylSynthwave(
    id: 'vinyl_synthwave',
    title: 'Neon Synthwave',
    subtitle: '45 RPM Cyber Disc',
    category: EditorTemplateCategory.vinyl,
    icon: Icons.radio_rounded,
    gradient: [Color(0xFFEC4899), Color(0xFF06B6D4)],
    badge: 'Neon FX',
  ),
  vinylAcrylic(
    id: 'vinyl_acrylic',
    title: 'Acrylic Disc',
    subtitle: 'Clear Collector LP',
    category: EditorTemplateCategory.vinyl,
    icon: Icons.disc_full_rounded,
    gradient: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
    badge: 'Indie',
  ),

  // --- Category 3: Cyber HUD & Sci-Fi ---
  hudCyberpunk(
    id: 'hud_cyberpunk',
    title: 'Cyberpunk 2077',
    subtitle: 'Night City Optics',
    category: EditorTemplateCategory.hud,
    icon: Icons.camera_enhance_rounded,
    gradient: [Color(0xFF06B6D4), Color(0xFF10B981)],
    badge: 'Sci-Fi',
  ),
  hudTelemetry(
    id: 'hud_telemetry',
    title: 'NASA Telemetry',
    subtitle: 'Deep Space Orbit',
    category: EditorTemplateCategory.hud,
    icon: Icons.satellite_alt_rounded,
    gradient: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
    badge: 'Space',
  ),
  hudJarvis(
    id: 'hud_jarvis',
    title: 'Iron Mech HUD',
    subtitle: 'Titanium Combat',
    category: EditorTemplateCategory.hud,
    icon: Icons.shield_rounded,
    gradient: [Color(0xFFEAB308), Color(0xFFEF4444)],
    badge: 'Armor',
  ),

  // --- Category 4: Music Card & Player ---
  musicSpotify(
    id: 'music_spotify',
    title: 'Spotify Glass',
    subtitle: 'Frosted Now Playing',
    category: EditorTemplateCategory.music,
    icon: Icons.music_note_rounded,
    gradient: [Color(0xFF10B981), Color(0xFF059669)],
    badge: 'Spotify',
  ),
  musicCassette(
    id: 'music_cassette',
    title: '90s Cassette',
    subtitle: 'Awesome Mixtape',
    category: EditorTemplateCategory.music,
    icon: Icons.album_outlined,
    gradient: [Color(0xFFF97316), Color(0xFFEAB308)],
    badge: 'Vintage',
  ),
  musicSpatial(
    id: 'music_spatial',
    title: 'Spatial Audio',
    subtitle: 'Lossless Master',
    category: EditorTemplateCategory.music,
    icon: Icons.graphic_eq_rounded,
    gradient: [Color(0xFFA855F7), Color(0xFFEC4899)],
    badge: 'Master',
  );

  final String id;
  final String title;
  final String subtitle;
  final EditorTemplateCategory category;
  final IconData icon;
  final List<Color> gradient;
  final String badge;

  const EditorTemplate({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.gradient,
    required this.badge,
  });

  static List<EditorTemplate> get allTemplates =>
      EditorTemplate.values.where((t) => t != EditorTemplate.none).toList();
}
