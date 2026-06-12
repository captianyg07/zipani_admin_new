import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/widgets/dashboard_section.dart';
import '../../data/dashboard_stats.dart';

/// Top-line outlet summary. The data layer (DashboardStats) does not expose
/// per-restaurant revenue, so this panel summarizes what IS available —
/// restaurant counts and this-period revenue — rather than fabricating a
/// per-outlet leaderboard. (Building a true leaderboard would require a
/// provider change, which is out of scope for the UI redesign.)
class TopRestaurantsPanel extends StatelessWidget {
  const TopRestaurantsPanel({
    super.key,
    required this.stats,
    required this.currency,
  });

  final DashboardStats stats;
  final String currency;

  String _money(double v) =>
      NumberFormat.currency(symbol: currency, decimalDigits: 0).format(v);

  @override
  Widget build(BuildContext context) {
    final rows = <_M>[
      _M('Active restaurants', '${stats.activeRestaurants}', DS.success,
          Icons.storefront_outlined),
      _M('Inactive restaurants', '${stats.inactiveRestaurants}', DS.muted,
          Icons.do_not_disturb_on_outlined),
      _M('Available menu items', '${stats.availableMenuItems}', DS.info,
          Icons.check_circle_outline),
      _M('Revenue this month', _money(stats.revenueMonth), DS.brand,
          Icons.payments_outlined),
    ];

    return SectionPanel(
      title: 'Outlets overview',
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: DS.s20, color: DS.line),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: rows[i].color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(DS.rMd),
                  ),
                  alignment: Alignment.center,
                  child: Icon(rows[i].icon, size: 18, color: rows[i].color),
                ),
                const SizedBox(width: DS.s12),
                Expanded(child: Text(rows[i].label, style: AppType.body)),
                Text(rows[i].value, style: AppType.bodyStrong),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _M {
  const _M(this.label, this.value, this.color, this.icon);
  final String label;
  final String value;
  final Color color;
  final IconData icon;
}
