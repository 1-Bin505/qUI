// lib/theme/app_theme.dart
//
// ASLive — Design Tokens & ThemeData
// ===================================
// Ported from static/css/style.css :root variables.
// All colors, text styles, spacing, and radii are centralised here
// so that every widget references a single source of truth.
//
// CSS variable mapping:
//   --bg-color        → AppColors.bgColor          (#FDF6EC)
//   --primary-tan     → AppColors.primaryTan        (#C8A96E)
//   --secondary-tan   → AppColors.secondaryTan      (#B89060)
//   --dark-brown      → AppColors.darkBrown          (#3D2B1F)
//   --card-brown      → AppColors.cardBrown          (#7A6535)
//   --card-light-tan  → AppColors.cardLightTan       (#E8D5B0)
//   --text-light      → AppColors.textLight          (#FFF8EE)
//   --text-dark       → AppColors.textDark           (#3D2B1F)
//   --status-gold     → AppColors.statusGold         (#E8B94A)
//   --error-coral     → AppColors.errorCoral         (#E07A5F)

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Color Palette
// ---------------------------------------------------------------------------
abstract final class AppColors {
  static const Color bgColor = Color(0xFFFDF6EC);
  static const Color primaryTan = Color(0xFFC8A96E);
  static const Color secondaryTan = Color(0xFFB89060);
  static const Color darkBrown = Color(0xFF3D2B1F);
  static const Color cardBrown = Color(0xFF7A6535);
  static const Color cardLightTan = Color(0xFFE8D5B0);
  static const Color textLight = Color(0xFFFFF8EE);
  static const Color textDark = Color(0xFF3D2B1F);
  static const Color statusGold = Color(0xFFE8B94A);
  static const Color errorCoral = Color(0xFFE07A5F);

  // Supplementary colours used in the web overlay / landmarks
  static const Color accentGreen = Color(0xFF7EE8A2);
  static const Color subtleGray = Color(0xFF888888);
  static const Color overlayBlack = Color(0xD1000000); // ~82% opacity
}

// ---------------------------------------------------------------------------
// Spacing (matching the CSS rem-based spacing, 1rem ≈ 16)
// ---------------------------------------------------------------------------
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ---------------------------------------------------------------------------
// Radii (matching border-radius values in CSS)
// ---------------------------------------------------------------------------
abstract final class AppRadii {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 50;
}

// ---------------------------------------------------------------------------
// ThemeData builder
// ---------------------------------------------------------------------------
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Outfit',
    scaffoldBackgroundColor: AppColors.bgColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryTan,
      brightness: Brightness.light,
      surface: AppColors.bgColor,
      onSurface: AppColors.textDark,
      primary: AppColors.primaryTan,
      onPrimary: AppColors.textLight,
      secondary: AppColors.secondaryTan,
      onSecondary: AppColors.textLight,
      error: AppColors.errorCoral,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBrown,
      foregroundColor: AppColors.textLight,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: AppColors.textLight,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.textLight,
        foregroundColor: AppColors.textDark,
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        elevation: 4,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.darkBrown,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textDark,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textDark,
        height: 1.6,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    ),
  );
}
