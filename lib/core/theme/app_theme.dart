import 'package:flutter/material.dart';

/// Zipani visual identity.
/// Saffron accent over a deep ink neutral — warm, food-forward, and
/// distinct from the default blue admin dashboard.
class AppColors {
  static const ink = Color(0xFF1A1714); // near-black, warm
  static const inkSoft = Color(0xFF433E38);
  static const saffron = Color(0xFFE8821E); // primary accent
  static const saffronDeep = Color(0xFFC96A0F);
  static const cream = Color(0xFFFBF7F1); // page background
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFE7E0D6);
  static const muted = Color(0xFF8A8178);

  // Status accents for orders (mapped later in business-logic phase).
  static const positive = Color(0xFF2E7D52);
  static const warning = Color(0xFFD9A21B);
  static const danger = Color(0xFFC0392B);
}

class AppTheme {
  static ThemeData get light {
    const accent = AppColors.saffron;
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.danger,
      ),
      textTheme: _textTheme(base.textTheme),
      dividerColor: AppColors.line,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _border(AppColors.line),
        enabledBorder: _border(AppColors.line),
        focusedBorder: _border(accent, width: 1.6),
        errorBorder: _border(AppColors.danger),
        labelStyle: const TextStyle(color: AppColors.muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color c, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c, width: width),
      );

  static TextTheme _textTheme(TextTheme t) => t.copyWith(
        displaySmall: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.5,
        ),
        headlineSmall: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.3,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyMedium: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
        labelLarge: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
          letterSpacing: 0.6,
        ),
      );
}
