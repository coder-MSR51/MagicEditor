import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

class AppTheme {
  static const Color background = Color(0xFF090B10);
  static const Color surface = Color(0xFF111520);
  static const Color surfaceLight = Color(0xFF1A2130);
  static const Color cardColor = Color(0xFF161C2A);
  static const Color primary = Color(0xFF00E5FF); // Electric Cyan
  static const Color secondary = Color(0xFF9D4EDD); // Electric Violet
  static const Color accent = Color(0xFFFF007F); // Neon Rose
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color dividerColor = Color(0xFF263248);

  static const String _fontPrefFileName = 'app_font_preference.txt';
  static final ValueNotifier<String> fontStyleNotifier = ValueNotifier('Poppins');

  /// Loads saved font style from internal storage on app startup
  static Future<void> initSavedFont() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fontPrefFileName');
      if (await file.exists()) {
        final saved = (await file.readAsString()).trim();
        if (saved.isNotEmpty) {
          final matched = textStyles.firstWhere(
            (s) => (s['name'] ?? '').toLowerCase() == saved.toLowerCase(),
            orElse: () => textStyles.first,
          );
          fontStyleNotifier.value = matched['name']!;
          debugPrint('[AppTheme] Restored persistent font style: ${fontStyleNotifier.value}');
        }
      }
    } catch (e) {
      debugPrint('[AppTheme] Error loading saved font: $e');
    }
  }

  /// Permanently saves and updates the active font style
  static Future<void> setFontStyle(String fontName) async {
    fontStyleNotifier.value = fontName;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fontPrefFileName');
      await file.writeAsString(fontName.trim());
      debugPrint('[AppTheme] Saved persistent font style: $fontName');
    } catch (e) {
      debugPrint('[AppTheme] Error persisting font: $e');
    }
  }

  static const List<Map<String, String>> textStyles = [
    {
      'name': 'Poppins',
      'label': 'Modern & Rounded',
      'category': 'Geometric Sans',
      'sample': 'Magic Editor ✨ Create Stunning Art',
    },
    {
      'name': 'Inter',
      'label': 'Clean & Minimal',
      'category': 'Modern Sans',
      'sample': 'Magic Editor ✨ Create Stunning Art',
    },
    {
      'name': 'Cinzel',
      'label': 'Luxury & Elegance',
      'category': 'Classic Serif',
      'sample': 'Magic Editor ✨ Create Stunning Art',
    },
    {
      'name': 'Dancing Script',
      'label': 'Artistic & Handwriting',
      'category': 'Creative Script',
      'sample': 'Magic Editor ✨ Create Stunning Art',
    },
    {
      'name': 'Orbitron',
      'label': 'Futuristic & Sci-Fi',
      'category': 'Tech Display',
      'sample': 'Magic Editor ✨ Create Stunning Art',
    },
  ];

  static TextStyle getFontStyle(String fontName, {TextStyle? textStyle}) {
    final styleWithFallback = (textStyle ?? const TextStyle()).copyWith(
      fontFamilyFallback: const ['Roboto', 'sans-serif'],
    );
    switch (fontName.toLowerCase()) {
      case 'inter':
        return GoogleFonts.inter(textStyle: styleWithFallback);
      case 'cinzel':
        return GoogleFonts.cinzel(textStyle: styleWithFallback);
      case 'dancing script':
      case 'dancingscript':
        return GoogleFonts.dancingScript(textStyle: styleWithFallback);
      case 'orbitron':
        return GoogleFonts.orbitron(textStyle: styleWithFallback);
      case 'poppins':
      default:
        return GoogleFonts.poppins(textStyle: styleWithFallback);
    }
  }

  static ThemeData getThemeWithFont([String? fontName]) {
    final font = fontName ?? fontStyleNotifier.value;
    final base = darkTheme;
    TextTheme themedText;
    try {
      switch (font.toLowerCase()) {
        case 'inter':
          themedText = GoogleFonts.interTextTheme(base.textTheme);
          break;
        case 'cinzel':
          themedText = GoogleFonts.cinzelTextTheme(base.textTheme);
          break;
        case 'dancing script':
        case 'dancingscript':
          themedText = GoogleFonts.dancingScriptTextTheme(base.textTheme);
          break;
        case 'orbitron':
          themedText = GoogleFonts.orbitronTextTheme(base.textTheme);
          break;
        case 'poppins':
        default:
          themedText = GoogleFonts.poppinsTextTheme(base.textTheme);
          break;
      }
    } catch (_) {
      themedText = base.textTheme;
    }

    return base.copyWith(
      textTheme: themedText,
    );
  }

  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      primaryColor: const Color(0xFF2563EB),
      cardColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2563EB),
        secondary: Color(0xFF7C3AED),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF0F172A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        ),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Color(0xFF2563EB),
        inactiveTrackColor: Color(0xFFE2E8F0),
        thumbColor: Color(0xFF2563EB),
        trackHeight: 3,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false,
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surfaceLight,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.2),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
    );
  }


}
