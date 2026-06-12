import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import '../design/typography.dart';

/// A tinted status pill: soft background + colored label.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.dense = false,
  });

  final String label;
  final Color color;
  final bool dense;

  /// Convenience for active/inactive style booleans.
  factory StatusPill.toggle({
    required bool on,
    String onLabel = 'Active',
    String offLabel = 'Inactive',
  }) {
    return StatusPill(
      label: on ? onLabel : offLabel,
      color: on ? DS.success : DS.muted,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? DS.s8 : DS.s12,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(DS.rPill),
      ),
      child: Text(label, style: AppType.pill.copyWith(color: color)),
    );
  }
}
