import 'package:flutter/material.dart';

/// ── Zipani Design System · Tokens ──────────────────────────────────
/// Single source of truth for color, spacing, radius, and elevation.
/// Components read ONLY from here; screens compose components.

class DS {
  DS._();

  // ── Color · neutrals ──────────────────────────────────────────────
  static const ink = Color(0xFF15192B); // primary text
  static const inkSoft = Color(0xFF565E78); // secondary text
  static const muted = Color(0xFF939BB4); // tertiary / captions
  static const line = Color(0xFFEDEFF5); // hairlines / dividers
  static const surface = Color(0xFFFFFFFF); // cards
  static const canvas = Color(0xFFF5F6FB); // app background
  static const canvasAlt = Color(0xFFFAFBFE); // zebra / subtle fills

  // ── Color · brand ────────────────────────────────────────────────
  static const brand = Color(0xFFF15A24); // Swiggy-style orange
  static const brandDeep = Color(0xFFD8460F);
  static const brandSoft = Color(0xFFFDEDE5); // tinted brand background

  // ── Color · sidebar (deep navy) ──────────────────────────────────
  static const navy = Color(0xFF0E1730);
  static const navyRaised = Color(0xFF18233F);
  static const navyText = Color(0xFFA7AFC7);
  static const navyMuted = Color(0xFF626C8C);

  // ── Color · semantic ─────────────────────────────────────────────
  static const success = Color(0xFF1BA672);
  static const successSoft = Color(0xFFE4F6EE);
  static const warning = Color(0xFFE8A005);
  static const warningSoft = Color(0xFFFDF2DC);
  static const danger = Color(0xFFE5484D);
  static const dangerSoft = Color(0xFFFCEAEA);
  static const info = Color(0xFF3B82F6);
  static const infoSoft = Color(0xFFE7F0FE);
  static const violet = Color(0xFF7A5AF8);
  static const violetSoft = Color(0xFFEEEAFE);

  // ── Spacing scale (4-based) ───────────────────────────────────────
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;

  // ── Radii ─────────────────────────────────────────────────────────
  static const double rSm = 8;
  static const double rMd = 12;
  static const double rLg = 16;
  static const double rXl = 20;
  static const double rPill = 999;

  // ── Shadows ───────────────────────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: ink.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: ink.withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // ── Layout constants ──────────────────────────────────────────────
  static const double sidebarWidth = 252;
  static const double headerHeight = 72;
  static const double contentMaxWidth = 1320;
  static const double wideBreakpoint = 900;
}
