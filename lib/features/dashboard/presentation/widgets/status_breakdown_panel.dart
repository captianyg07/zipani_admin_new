import 'package:flutter/material.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/widgets/section_panel.dart';
import '../../../orders/data/order_status.dart';
import '../../data/dashboard_stats.dart';

/// Breakdown of orders by status, as a labelled bar list. Reads the existing
/// ordersByStatus map and OrderStatus.color/label (order_status.dart untouched).
class StatusBreakdownPanel extends StatelessWidget {
  const StatusBreakdownPanel({super.key, required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    const order = [
      OrderStatus.pending,
      OrderStatus.preparing,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
      OrderStatus.cancelled,
    ];
    final total = stats.totalOrders == 0 ? 1 : stats.totalOrders;

    return SectionPanel(
      title: 'Orders by status',
      child: Column(
        children: [
          for (final s in order) ...[
            _StatusBar(
              label: s.label,
              count: stats.statusCount(s),
              fraction: stats.statusCount(s) / total,
              color: s.color,
            ),
            const SizedBox(height: DS.s16),
          ],
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.label,
    required this.count,
    required this.fraction,
    required this.color,
  });

  final String label;
  final int count;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppType.bodyStrong)),
            Text('$count', style: AppType.bodyStrong),
          ],
        ),
        const SizedBox(height: DS.s8),
        ClipRRect(
          borderRadius: BorderRadius.circular(DS.rPill),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: DS.line,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
