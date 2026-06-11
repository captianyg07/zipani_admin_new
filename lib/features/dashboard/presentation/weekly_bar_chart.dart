import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A single bar's data: its axis label, normalized height, and a display
/// string shown above the bar.
class BarDatum {
  const BarDatum({
    required this.axisLabel,
    required this.fraction, // 0..1, caller pre-normalizes
    required this.valueLabel,
  });

  final String axisLabel;
  final double fraction;
  final String valueLabel;
}

/// A lightweight bar chart built with plain widgets (no chart package).
/// The caller supplies already-normalized bar data, so this widget contains
/// no metric-specific logic.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.bars,
    required this.barColor,
  });

  final List<BarDatum> bars;
  final Color barColor;

  static const double _trackHeight = 140;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final b in bars)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      b.valueLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: (_trackHeight * b.fraction.clamp(0.0, 1.0))
                          .clamp(2.0, _trackHeight),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      b.axisLabel,
                      style:
                          const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
