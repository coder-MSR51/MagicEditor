
class FilterPreset {
  final String id;
  final String name;
  final String category;
  final List<double> matrix;

  const FilterPreset({
    required this.id,
    required this.name,
    required this.category,
    required this.matrix,
  });
}

class FilterPresets {
  // Identity matrix (No filter)
  static const List<double> identityMatrix = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  // --- 15 User-Requested Studio Effects ---
  static const FilterPreset effectHdr = FilterPreset(
    id: 'hdr',
    name: 'HDR',
    category: 'Pro FX',
    matrix: [
      1.35, -0.05, -0.05, 0, 10,
      -0.05, 1.35, -0.05, 0, 10,
      -0.05, -0.05, 1.35, 0, 10,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset effectCinematic = FilterPreset(
    id: 'cinematic',
    name: 'Cinematic',
    category: 'Pro FX',
    matrix: [
      1.30, -0.05, -0.10, 0, 20,
      0.00, 1.15, 0.05, 0, 5,
      -0.10, 0.15, 1.35, 0, 25,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset effectFilm = FilterPreset(
    id: 'film',
    name: 'Film',
    category: 'Pro FX',
    matrix: [
      1.18, 0.04, -0.02, 0, 12,
      0.02, 1.12, 0.02, 0, 8,
      -0.04, 0.02, 0.96, 0, -6,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset effectPolaroid = FilterPreset(
    id: 'poloroid',
    name: 'Polaroid',
    category: 'Pro FX',
    matrix: [
      1.12, 0.08, 0.00, 0, 24,
      0.02, 1.08, 0.05, 0, 20,
      0.00, 0.05, 0.90, 0, 30,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset effectSuperCharacter = FilterPreset(
    id: 'super_character',
    name: 'Super Character',
    category: 'Pro FX',
    matrix: [
      1.42, -0.12, -0.10, 0, 15,
      -0.08, 1.40, -0.12, 0, 15,
      -0.10, -0.10, 1.45, 0, 18,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset effectWarm = FilterPreset(
    id: 'warm',
    name: 'Warm',
    category: 'Pro FX',
    matrix: [
      1.28, 0.12, 0.00, 0, 32,
      0.04, 1.10, 0.04, 0, 16,
      -0.12, -0.04, 0.82, 0, -10,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset effectOld1 = FilterPreset(
    id: 'old1',
    name: 'Old 1',
    category: 'Pro FX',
    matrix: [
      0.43, 0.84, 0.20, 0, 20,
      0.34, 0.68, 0.16, 0, 10,
      0.21, 0.42, 0.10, 0, -15,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset effectOld2 = FilterPreset(
    id: 'old2',
    name: 'Old 2',
    category: 'Pro FX',
    matrix: [
      1.10, 0.08, 0.00, 0, 35,
      0.05, 1.02, 0.00, 0, 25,
      0.00, 0.04, 0.80, 0, 40,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset effectFuture1 = FilterPreset(
    id: 'future1',
    name: 'Future 1',
    category: 'Pro FX',
    matrix: [
      1.35, -0.15, 0.20, 0, 28,
      -0.15, 1.10, 0.25, 0, -10,
      0.18, 0.10, 1.45, 0, 35,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset effectFuture2 = FilterPreset(
    id: 'future2',
    name: 'Future 2',
    category: 'Pro FX',
    matrix: [
      1.15, -0.20, 0.35, 0, 20,
      -0.10, 1.25, -0.10, 0, 10,
      0.30, -0.05, 1.40, 0, 40,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset effectGalaxy = FilterPreset(
    id: 'galaxy',
    name: 'Galaxy',
    category: 'Pro FX',
    matrix: [
      1.15, -0.10, 0.25, 0, 18,
      -0.08, 0.95, 0.20, 0, -5,
      0.25, 0.15, 1.50, 0, 38,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset effectSky = FilterPreset(
    id: 'sky',
    name: 'Sky',
    category: 'Pro FX',
    matrix: [
      0.90, 0.00, 0.10, 0, -10,
      0.00, 1.05, 0.15, 0, 5,
      -0.05, 0.10, 1.55, 0, 35,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset effectNature = FilterPreset(
    id: 'nature',
    name: 'Nature',
    category: 'Pro FX',
    matrix: [
      0.92, 0.05, 0.00, 0, -8,
      0.04, 1.35, 0.06, 0, 20,
      -0.04, 0.08, 0.95, 0, -5,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset effectWater = FilterPreset(
    id: 'water',
    name: 'Water',
    category: 'Pro FX',
    matrix: [
      0.88, 0.02, 0.12, 0, -12,
      0.02, 1.22, 0.22, 0, 12,
      0.05, 0.18, 1.48, 0, 28,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset effectWoody = FilterPreset(
    id: 'woody',
    name: 'Woody',
    category: 'Pro FX',
    matrix: [
      1.25, 0.15, -0.08, 0, 22,
      0.10, 1.08, -0.05, 0, 12,
      -0.12, -0.05, 0.78, 0, -15,
      0, 0, 0, 1, 0,
    ],
  );

  /// Dedicated list of the 15 effects requested for Apply Effects Studio
  static final List<FilterPreset> effects = [
    const FilterPreset(
      id: 'original',
      name: 'Original',
      category: 'Pro FX',
      matrix: identityMatrix,
    ),
    effectHdr,
    effectCinematic,
    effectFilm,
    effectPolaroid,
    effectSuperCharacter,
    effectWarm,
    effectOld1,
    effectOld2,
    effectFuture1,
    effectFuture2,
    effectGalaxy,
    effectSky,
    effectNature,
    effectWater,
    effectWoody,
  ];

  static final List<FilterPreset> all = [
    const FilterPreset(
      id: 'original',
      name: 'Original',
      category: 'Natural',
      matrix: identityMatrix,
    ),
    effectHdr,
    effectCinematic,
    effectFilm,
    effectPolaroid,
    effectSuperCharacter,
    effectWarm,
    effectOld1,
    effectOld2,
    effectFuture1,
    effectFuture2,
    effectGalaxy,
    effectSky,
    effectNature,
    effectWater,
    effectWoody,
    const FilterPreset(
      id: 'golden_retro',
      name: 'Retro 90s',
      category: 'Vintage',
      matrix: [
        1.15, 0.05, 0.00, 0, 15,
        0.05, 1.05, 0.00, 0, 10,
        0.00, 0.05, 0.85, 0, -10,
        0.00, 0.00, 0.00, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'cyberpunk',
      name: 'Cyberpunk',
      category: 'Moody',
      matrix: [
        1.30, -0.10, 0.10, 0, 20,
        -0.10, 1.15, 0.15, 0, -5,
        0.10, 0.10, 1.40, 0, 30,
        0.00, 0.00, 0.00, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'film_noir',
      name: 'Film Noir',
      category: 'B&W',
      matrix: [
        0.33 * 1.4, 0.59 * 1.4, 0.11 * 1.4, 0, -30,
        0.33 * 1.4, 0.59 * 1.4, 0.11 * 1.4, 0, -30,
        0.33 * 1.4, 0.59 * 1.4, 0.11 * 1.4, 0, -30,
        0, 0, 0, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'teal_orange',
      name: 'Teal & Orange',
      category: 'Cinematic',
      matrix: [
        1.35, -0.05, -0.10, 0, 25,
        0.00, 1.10, 0.10, 0, 5,
        -0.15, 0.20, 1.30, 0, 20,
        0.00, 0.00, 0.00, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'vintage_sepia',
      name: 'Antique Sepia',
      category: 'Vintage',
      matrix: [
        0.393, 0.769, 0.189, 0, 0,
        0.349, 0.686, 0.168, 0, 0,
        0.272, 0.534, 0.131, 0, 0,
        0, 0, 0, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'emerald_breeze',
      name: 'Emerald Lush',
      category: 'Nature',
      matrix: [
        0.90, 0.05, 0.00, 0, -10,
        0.05, 1.25, 0.10, 0, 15,
        0.00, 0.10, 1.05, 0, 5,
        0.00, 0.00, 0.00, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'sunset_glow',
      name: 'Sunset Glow',
      category: 'Warm',
      matrix: [
        1.30, 0.10, 0.00, 0, 25,
        0.05, 1.05, 0.05, 0, 10,
        -0.10, 0.00, 0.90, 0, -5,
        0.00, 0.00, 0.00, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'cold_midnight',
      name: 'Midnight Blue',
      category: 'Moody',
      matrix: [
        0.85, 0.00, 0.10, 0, -15,
        0.05, 0.95, 0.15, 0, -5,
        0.10, 0.20, 1.35, 0, 25,
        0.00, 0.00, 0.00, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'matte_fade',
      name: 'Matte Film',
      category: 'Moody',
      matrix: [
        0.95, 0.05, 0.05, 0, 20,
        0.05, 0.95, 0.05, 0, 20,
        0.05, 0.05, 0.95, 0, 25,
        0.00, 0.00, 0.00, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'silver_monochrome',
      name: 'Silver B&W',
      category: 'B&W',
      matrix: [
        0.30, 0.59, 0.11, 0, 10,
        0.30, 0.59, 0.11, 0, 10,
        0.30, 0.59, 0.11, 0, 10,
        0, 0, 0, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'vivid_pop',
      name: 'Vivid Pop',
      category: 'Vibrant',
      matrix: [
        1.25, -0.10, -0.05, 0, 5,
        -0.05, 1.25, -0.05, 0, 5,
        -0.05, -0.10, 1.25, 0, 5,
        0.00, 0.00, 0.00, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'rose_pastel',
      name: 'Rose Pastel',
      category: 'Warm',
      matrix: [
        1.15, 0.05, 0.05, 0, 20,
        0.00, 1.00, 0.05, 0, 10,
        0.10, 0.00, 1.10, 0, 15,
        0.00, 0.00, 0.00, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'thermal_cam',
      name: 'Thermal FX',
      category: 'Sci-Fi / FX',
      matrix: [
        1.9, -0.4, -0.2, 0, 50,
        -0.3, 1.5, -0.4, 0, -20,
        -0.5, -0.5, 2.2, 0, 30,
        0.0, 0.0, 0.0, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'night_vision',
      name: 'Night Vision',
      category: 'Sci-Fi / FX',
      matrix: [
        0.1, 0.2, 0.1, 0, -50,
        0.2, 1.8, 0.2, 0, 40,
        0.1, 0.2, 0.1, 0, -50,
        0.0, 0.0, 0.0, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'matrix_digital',
      name: 'Matrix Code',
      category: 'Sci-Fi / FX',
      matrix: [
        0.0, 0.1, 0.0, 0, -40,
        0.1, 1.9, 0.1, 0, 30,
        0.0, 0.1, 0.2, 0, -30,
        0.0, 0.0, 0.0, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'hologram_cyan',
      name: 'Hologram',
      category: 'Sci-Fi / FX',
      matrix: [
        0.1, 0.2, 0.1, 0, -40,
        0.1, 1.4, 0.3, 0, 30,
        0.2, 0.3, 1.8, 0, 50,
        0.0, 0.0, 0.0, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'vhs_glitch',
      name: 'VHS Retro',
      category: 'Vintage',
      matrix: [
        1.4, -0.1, 0.1, 0, 25,
        0.0, 0.9, 0.2, 0, -10,
        -0.2, 0.2, 1.4, 0, 20,
        0.0, 0.0, 0.0, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'golden_hour',
      name: 'Golden Hour',
      category: 'Warm',
      matrix: [
        1.35, 0.15, -0.1, 0, 30,
        0.05, 1.15, 0.0, 0, 15,
        -0.2, -0.1, 0.85, 0, -20,
        0.0, 0.0, 0.0, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'tokyo_neon',
      name: 'Tokyo Neon',
      category: 'Trendy',
      matrix: [
        1.4, -0.1, 0.2, 0, 35,
        -0.2, 1.0, 0.3, 0, -15,
        0.1, -0.1, 1.5, 0, 40,
        0.0, 0.0, 0.0, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'pastel_dream',
      name: 'Pastel Dream',
      category: 'Aesthetic',
      matrix: [
        1.05, 0.1, 0.1, 0, 30,
        0.05, 1.05, 0.1, 0, 30,
        0.1, 0.05, 1.15, 0, 35,
        0.0, 0.0, 0.0, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'nordic_fog',
      name: 'Nordic Fog',
      category: 'Aesthetic',
      matrix: [
        0.8, 0.1, 0.1, 0, 10,
        0.1, 0.85, 0.1, 0, 15,
        0.1, 0.15, 1.1, 0, 30,
        0.0, 0.0, 0.0, 1, 0,
      ],
    ),
    const FilterPreset(
      id: 'y2k_flash',
      name: 'Y2K Flash',
      category: 'Trendy',
      matrix: [
        1.3, -0.05, -0.05, 0, 20,
        -0.05, 1.25, -0.05, 0, 20,
        -0.05, -0.05, 1.3, 0, 20,
        0.0, 0.0, 0.0, 1, 0,
      ],
    ),
  ];

  static List<String> get categories => [
    'All',
    'Trendy',
    'Sci-Fi / FX',
    'Vintage',
    'Aesthetic',
    'Warm',
    'Moody',
    'B&W',
  ];

  /// Interpolates between identity matrix and preset matrix based on intensity (0.0 to 1.0)
  static List<double> getBlendedMatrix(List<double> presetMatrix, double intensity) {
    if (intensity <= 0.0) return identityMatrix;
    if (intensity >= 1.0) return presetMatrix;

    final blended = List<double>.filled(20, 0.0);
    for (int i = 0; i < 20; i++) {
      blended[i] = identityMatrix[i] + (presetMatrix[i] - identityMatrix[i]) * intensity;
    }
    return blended;
  }

  /// Calculates a combined color matrix combining adjustments (brightness, contrast, saturation, warmth)
  /// and the active filter preset.
  static List<double> calculateCombinedMatrix({
    required List<double> filterMatrix,
    required double filterIntensity,
    required double brightness,   // -1.0 to 1.0 (default 0)
    required double contrast,     // 0.0 to 2.0 (default 1.0)
    required double saturation,   // 0.0 to 2.0 (default 1.0)
    required double warmth,       // -1.0 to 1.0 (default 0)
    required double tint,         // -1.0 to 1.0 (default 0)
  }) {
    final base = getBlendedMatrix(filterMatrix, filterIntensity);

    // Apply brightness (add to offset)
    final bOffset = brightness * 100.0;

    // Apply contrast
    final cScale = contrast;
    final cOffset = 128.0 * (1.0 - contrast);

    // Apply warmth (more red/yellow or blue)
    final rWarmth = warmth * 25.0;
    final bWarmth = -warmth * 25.0;

    // Apply tint (green/magenta)
    final gTint = -tint * 25.0;
    final mTint = tint * 25.0;

    // Calculate luminance saturation coefficients
    final s = saturation;
    const lr = 0.2126;
    const lg = 0.7152;
    const lb = 0.0722;

    final sr = (1.0 - s) * lr;
    final sg = (1.0 - s) * lg;
    final sb = (1.0 - s) * lb;

    // Construct adjusted matrix
    return [
      (base[0] * (sr + s) + base[1] * sg + base[2] * sb) * cScale,
      (base[0] * sr + base[1] * (sg + s) + base[2] * sb) * cScale,
      (base[0] * sr + base[1] * sg + base[2] * (sb + s)) * cScale,
      0,
      base[4] + bOffset + cOffset + rWarmth + mTint,

      (base[5] * (sr + s) + base[6] * sg + base[7] * sb) * cScale,
      (base[5] * sr + base[6] * (sg + s) + base[7] * sb) * cScale,
      (base[5] * sr + base[6] * sg + base[7] * (sb + s)) * cScale,
      0,
      base[9] + bOffset + cOffset + gTint,

      (base[10] * (sr + s) + base[11] * sg + base[12] * sb) * cScale,
      (base[10] * sr + base[11] * (sg + s) + base[12] * sb) * cScale,
      (base[10] * sr + base[11] * sg + base[12] * (sb + s)) * cScale,
      0,
      base[14] + bOffset + cOffset + bWarmth,

      0, 0, 0, 1, 0,
    ];
  }
}
