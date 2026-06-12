import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/widgets/area_chart.dart';
import '../../../../core/widgets/section_panel.dart';
import '../../data/dashboard_stats.dart';

class RevenuePanel extends StatelessWidget {
  const RevenuePanel({super.key, required this.stats, required this.currency});
  final DashboardStats stats;
  final String currency;

  String _money(double v) =>
      NumberFormat.currency(symbol: currency, decimalDigits: 0).format(v);

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Revenue overview',
      trailing: Text('Last 7 days', style: AppType.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_money(stats.revenueWeek), style: AppType.metric),
          const SizedBox(height: DS.s4),
          Text('This week', style: AppType.small),
          const SizedBox(height: DS.s20),
          AreaChart(
            color: DS.violet,
            points: [
              for (final p in stats.last7Days)
                ChartPoint(label: p.weekdayLabel, value: p.revenue),
            ],
          ),
        ],
      ),
    );
  }
}
