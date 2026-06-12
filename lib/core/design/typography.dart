import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// ── Typography scale ──────────────────────────────────────────────
/// Named roles, intentional weights. Numbers (metrics) use tabular-ish
/// heavy weights for a dashboard feel.
class AppType {
  AppType._();

  static const display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: DS.ink,
    letterSpacing: -0.6,
    height: 1.1,
  );

  static const h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: DS.ink,
    letterSpacing: -0.4,
  );

  static const h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: DS.ink,
    letterSpacing: -0.2,
  );

  static const h3 = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    color: DS.ink,
  );

  /// Big metric number on KPI cards.
  static const metric = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: DS.ink,
    letterSpacing: -0.5,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: DS.inkSoft,
    height: 1.45,
  );

  static const bodyStrong = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: DS.ink,
  );

  static const small = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: DS.muted,
  );

  /// Uppercase eyebrow / section overline.
  static const eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: DS.muted,
    letterSpacing: 0.9,
  );

  /// Table column header.
  static const tableHead = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: DS.muted,
    letterSpacing: 0.4,
  );

  static const pill = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );
}
