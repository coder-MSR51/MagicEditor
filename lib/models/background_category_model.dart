import 'package:flutter/material.dart';

class BackgroundCategoryItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final String? badge;

  const BackgroundCategoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    this.badge,
  });
}

class CategoryWallpaperItem {
  final String id;
  final String title;
  final String categoryId;
  final String categoryTitle;
  final String assetPath;
  final List<Color>? gradientColors;

  const CategoryWallpaperItem({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryTitle,
    required this.assetPath,
    this.gradientColors,
  });
}

class BackgroundCategoriesData {
  static const List<CategoryWallpaperItem> marvelWallpapers = [
    CategoryWallpaperItem(
      id: 'marvel_spiderman',
      title: 'Spider-Man Sky',
      categoryId: 'marvel',
      categoryTitle: 'Marvel',
      assetPath: 'assets/backgrounds/marvel_spiderman.png',
      gradientColors: [Color(0xFFE62429), Color(0xFF0F172A)],
    ),
    CategoryWallpaperItem(
      id: 'marvel_ironman',
      title: 'Iron Man Repulsor',
      categoryId: 'marvel',
      categoryTitle: 'Marvel',
      assetPath: 'assets/backgrounds/marvel_ironman.png',
      gradientColors: [Color(0xFFDC2626), Color(0xFFFBBF24)],
    ),
    CategoryWallpaperItem(
      id: 'marvel_thor_hammer',
      title: 'Thor Mjolnir',
      categoryId: 'marvel',
      categoryTitle: 'Marvel',
      assetPath: 'assets/backgrounds/marvel_thor_hammer.png',
      gradientColors: [Color(0xFF475569), Color(0xFF94A3B8)],
    ),
    CategoryWallpaperItem(
      id: 'marvel_thanos',
      title: 'Thanos Titan',
      categoryId: 'marvel',
      categoryTitle: 'Marvel',
      assetPath: 'assets/backgrounds/marvel_thanos.png',
      gradientColors: [Color(0xFF581C87), Color(0xFFF59E0B)],
    ),
    CategoryWallpaperItem(
      id: 'marvel_captain_shield',
      title: 'Captain America Shield',
      categoryId: 'marvel',
      categoryTitle: 'Marvel',
      assetPath: 'assets/backgrounds/marvel_captain_shield.jpg',
      gradientColors: [Color(0xFF1D4ED8), Color(0xFFDC2626)],
    ),
  ];

  static const List<CategoryWallpaperItem> natureWallpapers = [
    CategoryWallpaperItem(
      id: 'nature_cherry_blossom_river',
      title: 'Blossom River',
      categoryId: 'nature',
      categoryTitle: 'Nature & Landscapes',
      assetPath: 'assets/backgrounds/nature_cherry_blossom_river.jpg',
      gradientColors: [Color(0xFFF472B6), Color(0xFF38BDF8)],
    ),
    CategoryWallpaperItem(
      id: 'nature_redwood_forest',
      title: 'Redwood Canopy',
      categoryId: 'nature',
      categoryTitle: 'Nature & Landscapes',
      assetPath: 'assets/backgrounds/nature_redwood_forest.jpg',
      gradientColors: [Color(0xFF065F46), Color(0xFF0284C7)],
    ),
    CategoryWallpaperItem(
      id: 'nature_ocean_beach',
      title: 'Turquoise Coast',
      categoryId: 'nature',
      categoryTitle: 'Nature & Landscapes',
      assetPath: 'assets/backgrounds/nature_ocean_beach.png',
      gradientColors: [Color(0xFF0284C7), Color(0xFF0F766E)],
    ),
    CategoryWallpaperItem(
      id: 'nature_mountain_valley',
      title: 'Yosemite Valley',
      categoryId: 'nature',
      categoryTitle: 'Nature & Landscapes',
      assetPath: 'assets/backgrounds/nature_mountain_valley.jpg',
      gradientColors: [Color(0xFF15803D), Color(0xFFCA8A04)],
    ),
    CategoryWallpaperItem(
      id: 'nature_dew_drops_bokeh',
      title: 'Dewdrop Bokeh',
      categoryId: 'nature',
      categoryTitle: 'Nature & Landscapes',
      assetPath: 'assets/backgrounds/nature_dew_drops_bokeh.png',
      gradientColors: [Color(0xFF10B981), Color(0xFFFACC15)],
    ),
  ];

  static const List<CategoryWallpaperItem> flowerWallpapers = [
    CategoryWallpaperItem(
      id: 'flowers_peonies_bouquet',
      title: 'Pink Peonies',
      categoryId: 'flowers',
      categoryTitle: 'Flowers',
      assetPath: 'assets/backgrounds/flowers_peonies_bouquet.png',
      gradientColors: [Color(0xFFFB7185), Color(0xFFF43F5E)],
    ),
    CategoryWallpaperItem(
      id: 'flowers_babys_breath',
      title: 'Pastel Baby\'s Breath',
      categoryId: 'flowers',
      categoryTitle: 'Flowers',
      assetPath: 'assets/backgrounds/flowers_babys_breath.png',
      gradientColors: [Color(0xFF818CF8), Color(0xFFF472B6)],
    ),
    CategoryWallpaperItem(
      id: 'flowers_marigold_field',
      title: 'Golden Marigold',
      categoryId: 'flowers',
      categoryTitle: 'Flowers',
      assetPath: 'assets/backgrounds/flowers_marigold_field.jpg',
      gradientColors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    ),
    CategoryWallpaperItem(
      id: 'flowers_tulips_sky',
      title: 'Skyward Tulips',
      categoryId: 'flowers',
      categoryTitle: 'Flowers',
      assetPath: 'assets/backgrounds/flowers_tulips_sky.png',
      gradientColors: [Color(0xFFE11D48), Color(0xFF38BDF8)],
    ),
  ];

  static const List<CategoryWallpaperItem> luxuryWallpapers = [
    CategoryWallpaperItem(
      id: 'luxury_mclaren_orange',
      title: 'McLaren Supercar',
      categoryId: 'luxury',
      categoryTitle: 'Luxury & Textures',
      assetPath: 'assets/backgrounds/luxury_mclaren_orange.png',
      gradientColors: [Color(0xFFEA580C), Color(0xFFF97316)],
    ),
    CategoryWallpaperItem(
      id: 'luxury_lexus_white',
      title: 'Lexus Executive',
      categoryId: 'luxury',
      categoryTitle: 'Luxury & Textures',
      assetPath: 'assets/backgrounds/luxury_lexus_white.jpg',
      gradientColors: [Color(0xFF475569), Color(0xFFCBD5E1)],
    ),
    CategoryWallpaperItem(
      id: 'luxury_typewriter_pink',
      title: 'Vintage Typewriter',
      categoryId: 'luxury',
      categoryTitle: 'Luxury & Textures',
      assetPath: 'assets/backgrounds/luxury_typewriter_pink.png',
      gradientColors: [Color(0xFFEC4899), Color(0xFFBE185D)],
    ),
    CategoryWallpaperItem(
      id: 'luxury_classic_columns',
      title: 'Neoclassic Columns',
      categoryId: 'luxury',
      categoryTitle: 'Luxury & Textures',
      assetPath: 'assets/backgrounds/luxury_classic_columns.png',
      gradientColors: [Color(0xFFD97706), Color(0xFF92400E)],
    ),
    CategoryWallpaperItem(
      id: 'luxury_palace_facade',
      title: 'Heritage Palace',
      categoryId: 'luxury',
      categoryTitle: 'Luxury & Textures',
      assetPath: 'assets/backgrounds/luxury_palace_facade.png',
      gradientColors: [Color(0xFFB45309), Color(0xFF334155)],
    ),
  ];

  static const List<CategoryWallpaperItem> loveWallpapers = [
    CategoryWallpaperItem(
      id: 'love_confetti_hearts',
      title: 'Confetti Hearts',
      categoryId: 'romantic',
      categoryTitle: 'Love & Romantic',
      assetPath: 'assets/backgrounds/love_confetti_hearts.png',
      gradientColors: [Color(0xFFFF2A55), Color(0xFFF43F5E)],
    ),
    CategoryWallpaperItem(
      id: 'love_candy_frame',
      title: 'Candy Heart Frame',
      categoryId: 'romantic',
      categoryTitle: 'Love & Romantic',
      assetPath: 'assets/backgrounds/love_candy_frame.png',
      gradientColors: [Color(0xFFF472B6), Color(0xFFFB7185)],
    ),
    CategoryWallpaperItem(
      id: 'love_pink_hearts_border',
      title: 'Sweetheart Border',
      categoryId: 'romantic',
      categoryTitle: 'Love & Romantic',
      assetPath: 'assets/backgrounds/love_pink_hearts_border.png',
      gradientColors: [Color(0xFFBE185D), Color(0xFFFDA4AF)],
    ),
    CategoryWallpaperItem(
      id: 'love_cyan_hearts',
      title: 'Cyan Hearts Pattern',
      categoryId: 'romantic',
      categoryTitle: 'Love & Romantic',
      assetPath: 'assets/backgrounds/love_cyan_hearts.png',
      gradientColors: [Color(0xFF06B6D4), Color(0xFF38BDF8)],
    ),
    CategoryWallpaperItem(
      id: 'love_black_hearts_white',
      title: 'Obsidian Hearts',
      categoryId: 'romantic',
      categoryTitle: 'Love & Romantic',
      assetPath: 'assets/backgrounds/love_black_hearts_white.png',
      gradientColors: [Color(0xFF1E293B), Color(0xFF475569)],
    ),
  ];

  static List<CategoryWallpaperItem> getWallpapersForCategory(String categoryId) {
    if (categoryId == 'marvel') {
      return marvelWallpapers;
    } else if (categoryId == 'nature') {
      return natureWallpapers;
    } else if (categoryId == 'flowers') {
      return flowerWallpapers;
    } else if (categoryId == 'luxury') {
      return luxuryWallpapers;
    } else if (categoryId == 'romantic') {
      return loveWallpapers;
    }
    return [];
  }

  static const List<BackgroundCategoryItem> categories = [
    BackgroundCategoryItem(
      id: 'marvel',
      title: 'Marvel',
      subtitle: 'Spider-Man, Iron Man, Thor, Thanos & Cap Shield',
      icon: Icons.bolt_rounded,
      gradientColors: [Color(0xFFE62429), Color(0xFF8B0000), Color(0xFF1E0203)],
      badge: '5 HD',
    ),
    BackgroundCategoryItem(
      id: 'nature',
      title: 'Nature & Landscapes',
      subtitle: 'Blossom river, redwoods, turquoise coast & Yosemite',
      icon: Icons.landscape_rounded,
      gradientColors: [Color(0xFF10B981), Color(0xFF047857), Color(0xFF022C22)],
      badge: '5 HD',
    ),
    BackgroundCategoryItem(
      id: 'flowers',
      title: 'Flowers',
      subtitle: 'Pink peonies, baby\'s breath, marigolds & tulips',
      icon: Icons.local_florist_rounded,
      gradientColors: [Color(0xFFEC4899), Color(0xFFBE123C), Color(0xFF4C0519)],
      badge: '4 HD',
    ),
    BackgroundCategoryItem(
      id: 'luxury',
      title: 'Luxury & Textures',
      subtitle: 'McLaren supercar, Lexus sedan, neoclassical & palace',
      icon: Icons.diamond_rounded,
      gradientColors: [Color(0xFFF59E0B), Color(0xFFB45309), Color(0xFF291003)],
      badge: '5 HD',
    ),
    BackgroundCategoryItem(
      id: 'romantic',
      title: 'Love & Romantic',
      subtitle: 'Confetti hearts, candy frame, cyan & obsidian hearts',
      icon: Icons.favorite_rounded,
      gradientColors: [Color(0xFFFF2A55), Color(0xFFBE185D), Color(0xFF500724)],
      badge: '5 HD',
    ),
  ];
}
