import 'package:flutter/material.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/widgets/area_chart.dart';
import '../../../../core/widgets/section_panel.dart';
import '../../data/dashboard_stats.dart';

class OrdersPanel extends StatelessWidget {
  const OrdersPanel({super.key, required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final weekOrders =
        stats.last7Days.fold<int>(0, (s, p) => s + p.orderCount);
    return SectionPanel(
      title: 'Orders overview',
      trailing: Text('Last 7 days', style: AppType.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$weekOrders', style: AppType.metric),
          const SizedBox(height: DS.s4),
          Text('Orders this week', style: AppType.small),
          const SizedBox(height: DS.s20),
          AreaChart(
            color: DS.brand,
            points: [
              for (final p in stats.last7Days)
                ChartPoint(
                    label: p.weekdayLabel, value: p.orderCount.toDouble()),
            ],
          ),
        ],
      ),
    );
  }
}
