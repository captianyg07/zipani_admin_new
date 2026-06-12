import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/widgets/state_views.dart';
import 'dashboard_controller.dart';
import 'widgets/kpi_row.dart';
import 'widgets/orders_panel.dart';
import 'widgets/recent_orders_panel.dart';
import 'widgets/revenue_panel.dart';
import 'widgets/status_breakdown_panel.dart';
import 'widgets/top_restaurants_panel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _currency = '\u20B9';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardControllerProvider);
    final notifier = ref.read(dashboardControllerProvider.notifier);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(DS.s24),
        child: LoadingState(height: 360),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(DS.s24),
        child: ErrorState(
          title: 'Could not load dashboard',
          message: e.toString(),
          onRetry: notifier.load,
        ),
      ),
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(DS.s24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: DS.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KpiRow(stats: stats, currency: _currency),
                const SizedBox(height: DS.s20),
                // Analytics row: revenue + orders charts side by side.
                LayoutBuilder(
                  builder: (context, c) {
                    final stack = c.maxWidth < 880;
                    final revenue =
                        RevenuePanel(stats: stats, currency: _currency);
                    final orders = OrdersPanel(stats: stats);
                    if (stack) {
                      return Column(
                        children: [
                          revenue,
                          const SizedBox(height: DS.s20),
                          orders,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: revenue),
                        const SizedBox(width: DS.s20),
                        Expanded(child: orders),
                      ],
                    );
                  },
                ),
                const SizedBox(height: DS.s20),
                LayoutBuilder(
                  builder: (context, c) {
                    final stack = c.maxWidth < 880;
                    final recent = RecentOrdersPanel(stats: stats);
                    final top = TopRestaurantsPanel(
                        stats: stats, currency: _currency);
                    if (stack) {
                      return Column(children: [
                        recent,
                        const SizedBox(height: DS.s20),
                        top,
                      ]);
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: recent),
                        const SizedBox(width: DS.s20),
                        Expanded(child: top),
                      ],
                    );
                  },
                ),
                const SizedBox(height: DS.s20),
                StatusBreakdownPanel(stats: stats),
                const SizedBox(height: DS.s24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
