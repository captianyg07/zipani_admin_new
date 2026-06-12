import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import '../design/typography.dart';
import 'app_card.dart';

/// KPI card: label, big value, tinted icon chip, optional delta line.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.delta,
    this.deltaPositive = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  /// e.g. "12.5% vs yesterday". Optional.
  final String? delta;
  final bool deltaPositive;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(DS.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppType.small)),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(DS.rMd),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 19, color: accent),
              ),
            ],
          ),
          const SizedBox(height: DS.s16),
          Text(value, style: AppType.metric),
          if (delta != null) ...[
            const SizedBox(height: DS.s6),
            Row(
              children: [
                Icon(
                  deltaPositive
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 15,
                  color: deltaPositive ? DS.success : DS.danger,
                ),
                const SizedBox(width: 4),
                Text(
                  delta!,
                  style: AppType.small.copyWith(
                    color: deltaPositive ? DS.success : DS.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
