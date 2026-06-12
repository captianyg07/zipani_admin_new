import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../data/dashboard_stats.dart';

/// Top KPI strip. Reads only existing DashboardStats fields.
class KpiRow extends StatelessWidget {
  const KpiRow({super.key, required this.stats, required this.currency});
  final DashboardStats stats;
  final String currency;

  String _money(double v) =>
      NumberFormat.currency(symbol: currency, decimalDigits: 0).format(v);

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      MetricCard(
        label: 'Revenue this month',
        value: _money(stats.revenueMonth),
        icon: Icons.account_balance_wallet_outlined,
        accent: DS.brand,
      ),
      MetricCard(
        label: 'Total orders',
        value: '${stats.totalOrders}',
        icon: Icons.receipt_long_outlined,
        accent: DS.violet,
      ),
      MetricCard(
        label: 'Restaurants',
        value: '${stats.totalRestaurants}',
        icon: Icons.storefront_outlined,
        accent: DS.info,
      ),
      MetricCard(
        label: 'Menu items',
        value: '${stats.totalMenuItems}',
        icon: Icons.restaurant_menu_outlined,
        accent: DS.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1000
            ? 4
            : c.maxWidth >= 640
                ? 2
                : 1;
        const gap = DS.s16;
        final w = (c.maxWidth - (cols - 1) * gap) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final card in cards) SizedBox(width: w, child: card)],
        );
      },
    );
  }
}
