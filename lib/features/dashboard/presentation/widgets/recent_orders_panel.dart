import 'package:flutter/material.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/widgets/dashboard_section.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../orders/data/order_status.dart';
import '../../data/dashboard_stats.dart';

/// Orders activity summary. The dashboard data layer (DashboardStats) does not
/// expose individual recent orders, so rather than fabricate a fake order feed
/// this panel shows the live per-status counts the stats DO provide. The full
/// recent-orders list lives on the Orders screen, where the data exists.
class RecentOrdersPanel extends StatelessWidget {
  const RecentOrdersPanel({super.key, required this.stats});
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

    return SectionPanel(
      title: 'Order activity',
      trailing: Text('${stats.totalOrders} total', style: AppType.small),
      child: Column(
        children: [
          for (var i = 0; i < order.length; i++) ...[
            if (i > 0) const Divider(height: DS.s20, color: DS.line),
            Row(
              children: [
                StatusPill(label: order[i].label, color: order[i].color),
                const Spacer(),
                Text('${stats.statusCount(order[i])}',
                    style: AppType.bodyStrong),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
