import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'typography.dart';

/// Builds the global ThemeData from design tokens. No DialogTheme slot
/// (version-fragile); dialogs get their shape locally via AppDialog.
class AppThemeData {
  static ThemeData build() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: DS.canvas,
      colorScheme: base.colorScheme.copyWith(
        primary: DS.brand,
        onPrimary: Colors.white,
        surface: DS.surface,
        onSurface: DS.ink,
        error: DS.danger,
      ),
      textTheme: base.textTheme.copyWith(
        displaySmall: AppType.display,
        headlineSmall: AppType.h1,
        titleLarge: AppType.h2,
        titleMedium: AppType.h3,
        bodyMedium: AppType.body,
        bodySmall: AppType.small,
        labelLarge: AppType.eyebrow,
      ),
      dividerColor: DS.line,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DS.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: _border(DS.line),
        enabledBorder: _border(DS.line),
        focusedBorder: _border(DS.brand, width: 1.5),
        errorBorder: _border(DS.danger),
        focusedErrorBorder: _border(DS.danger, width: 1.5),
        hintStyle: const TextStyle(color: DS.muted, fontSize: 14),
        labelStyle: const TextStyle(color: DS.muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DS.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DS.rMd)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: DS.surface,
        elevation: 10,
        shadowColor: DS.ink.withOpacity(0.12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rMd)),
        textStyle: AppType.body.copyWith(color: DS.ink),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rMd)),
      ),
    );
  }

  static OutlineInputBorder _border(Color c, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(DS.rMd),
        borderSide: BorderSide(color: c, width: width),
      );
}
