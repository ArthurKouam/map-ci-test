import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Background layers
  static const Color black = Color(0xFF000000);
  static const Color surface = Color(0xFF111111);
  static const Color card = Color(0xFF1A1A1A);
  static const Color cardElevated = Color(0xFF222222);
  static const Color divider = Color(0xFF2E2E2E);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF616161);

  // Accent — orange sahélien
  static const Color accent = Color(0xFFF5A623);
  static const Color accentDark = Color(0xFFBF7A00);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFC107);

  // Button
  static const Color buttonPrimary = Color(0xFFFFFFFF);
  static const Color buttonText = Color(0xFF000000);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.black,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.surface,
        onPrimary: AppColors.buttonText,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
          headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
          labelLarge: TextStyle(color: AppColors.buttonText, fontWeight: FontWeight.w700),
        ),
      ),
      useMaterial3: true,
    );
  }
}
