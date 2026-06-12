import 'package:flutter/material.dart';

import '../design/app_theme_data.dart';
import '../design/design_tokens.dart';

/// Back-compat shim. Older screens reference `AppColors.*` and
/// `AppTheme.cardDecoration()`. These now map onto the new design tokens (DS)
/// so existing references keep compiling while the redesign rolls out.
/// New code should import core/design/* directly.
class AppColors {
  static const ink = DS.ink;
  static const inkSoft = DS.inkSoft;
  static const muted = DS.muted;
  static const surface = DS.surface;
  static const cream = DS.canvas;
  static const line = DS.line;
  static const saffron = DS.brand;
  static const saffronDeep = DS.brandDeep;
  static const positive = DS.success;
  static const warning = DS.warning;
  static const danger = DS.danger;
  static const info = DS.info;
  static const purple = DS.violet;
  // sidebar + chip tokens kept for any lingering references
  static const sidebar = DS.navy;
  static const sidebarHover = DS.navyRaised;
  static const sidebarText = DS.navyText;
  static const sidebarMuted = DS.navyMuted;
  static const chipPurple = DS.violetSoft;
  static const chipRed = DS.dangerSoft;
  static const chipAmber = DS.warningSoft;
  static const chipBlue = DS.infoSoft;
  static const chipGreen = DS.successSoft;
}

class AppTheme {
  static ThemeData get light => AppThemeData.build();

  static BoxDecoration cardDecoration({double radius = DS.rLg}) =>
      BoxDecoration(
        color: DS.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: DS.shadowSm,
      );
}
