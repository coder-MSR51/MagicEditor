
enum PropCategory {
  faceProps('Funny Face', '🐶'),
  coolThug('Cool & Vibe', '🕶️'),
  cuteAnime('Cute & Anime', '✨'),
  crowns('Crowns & FX', '👑'),
  doodles('Fun Overlays', '🎨');

  final String title;
  final String iconEmoji;
  const PropCategory(this.title, this.iconEmoji);
}

class PropDefinition {
  final String id;
  final String name;
  final PropCategory category;
  final String emoji;
  final double defaultWidth;
  final double defaultHeight;

  const PropDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.emoji,
    this.defaultWidth = 140,
    this.defaultHeight = 140,
  });
}

class PropCatalog {
  static const List<PropDefinition> all = [
    // Snapchat Funny Face
    PropDefinition(
      id: 'dog_ears',
      name: 'Dog Ears',
      category: PropCategory.faceProps,
      emoji: '🐶',
      defaultWidth: 200,
      defaultHeight: 110,
    ),
    PropDefinition(
      id: 'dog_tongue',
      name: 'Dog Tongue',
      category: PropCategory.faceProps,
      emoji: '👅',
      defaultWidth: 100,
      defaultHeight: 110,
    ),
    PropDefinition(
      id: 'cat_ears_whiskers',
      name: 'Cat Ears & Whiskers',
      category: PropCategory.faceProps,
      emoji: '🐱',
      defaultWidth: 190,
      defaultHeight: 150,
    ),
    PropDefinition(
      id: 'bunny_ears',
      name: 'Bunny Ears',
      category: PropCategory.faceProps,
      emoji: '🐰',
      defaultWidth: 170,
      defaultHeight: 150,
    ),
    PropDefinition(
      id: 'clown_face',
      name: 'Clown Nose & Wig',
      category: PropCategory.faceProps,
      emoji: '🤡',
      defaultWidth: 180,
      defaultHeight: 130,
    ),
    PropDefinition(
      id: 'pig_snout',
      name: 'Piggy Snout',
      category: PropCategory.faceProps,
      emoji: '🐽',
      defaultWidth: 100,
      defaultHeight: 90,
    ),

    // Cool & Thug
    PropDefinition(
      id: 'thug_pixel_glasses',
      name: 'Pixel Shades',
      category: PropCategory.coolThug,
      emoji: '🕶️',
      defaultWidth: 180,
      defaultHeight: 65,
    ),
    PropDefinition(
      id: 'gold_chain',
      name: 'Gold Chain',
      category: PropCategory.coolThug,
      emoji: '⛓️',
      defaultWidth: 160,
      defaultHeight: 130,
    ),
    PropDefinition(
      id: 'gentleman_mustache',
      name: 'Gentleman Monocle',
      category: PropCategory.coolThug,
      emoji: '🥸',
      defaultWidth: 150,
      defaultHeight: 110,
    ),
    PropDefinition(
      id: 'neon_shades',
      name: 'Cyberpunk Visor',
      category: PropCategory.coolThug,
      emoji: '🥽',
      defaultWidth: 180,
      defaultHeight: 70,
    ),

    // Cute & Anime
    PropDefinition(
      id: 'anime_sparkle_eyes',
      name: 'Anime Eyes',
      category: PropCategory.cuteAnime,
      emoji: '✨',
      defaultWidth: 180,
      defaultHeight: 80,
    ),
    PropDefinition(
      id: 'heart_eyes',
      name: 'Heart Eyes',
      category: PropCategory.cuteAnime,
      emoji: '😍',
      defaultWidth: 170,
      defaultHeight: 80,
    ),
    PropDefinition(
      id: 'blushing_cheeks',
      name: 'Blush Cheeks',
      category: PropCategory.cuteAnime,
      emoji: '🌸',
      defaultWidth: 190,
      defaultHeight: 60,
    ),
    PropDefinition(
      id: 'crying_tears',
      name: 'Anime Tears',
      category: PropCategory.cuteAnime,
      emoji: '😭',
      defaultWidth: 170,
      defaultHeight: 120,
    ),

    // Crowns & FX
    PropDefinition(
      id: 'angel_halo',
      name: 'Angel Halo',
      category: PropCategory.crowns,
      emoji: '😇',
      defaultWidth: 160,
      defaultHeight: 75,
    ),
    PropDefinition(
      id: 'devil_horns',
      name: 'Devil Horns',
      category: PropCategory.crowns,
      emoji: '😈',
      defaultWidth: 160,
      defaultHeight: 100,
    ),
    PropDefinition(
      id: 'gold_crown',
      name: 'Royal Crown',
      category: PropCategory.crowns,
      emoji: '👑',
      defaultWidth: 150,
      defaultHeight: 100,
    ),
    PropDefinition(
      id: 'flower_crown',
      name: 'Flower Crown',
      category: PropCategory.crowns,
      emoji: '🌺',
      defaultWidth: 180,
      defaultHeight: 90,
    ),
    PropDefinition(
      id: 'fire_flames',
      name: 'Flame Aura',
      category: PropCategory.crowns,
      emoji: '🔥',
      defaultWidth: 170,
      defaultHeight: 120,
    ),

    // Fun Overlays
    PropDefinition(
      id: 'alien_antenna',
      name: 'Alien Antenna',
      category: PropCategory.doodles,
      emoji: '👽',
      defaultWidth: 160,
      defaultHeight: 120,
    ),
    PropDefinition(
      id: 'bubble_gum',
      name: 'Bubble Gum Pop',
      category: PropCategory.doodles,
      emoji: '🫧',
      defaultWidth: 110,
      defaultHeight: 110,
    ),
    PropDefinition(
      id: 'party_hat',
      name: 'Party Hat',
      category: PropCategory.doodles,
      emoji: '🥳',
      defaultWidth: 120,
      defaultHeight: 130,
    ),
  ];
}
