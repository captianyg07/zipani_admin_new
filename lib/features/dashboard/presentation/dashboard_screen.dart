import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../orders/data/order_status.dart';
import '../data/dashboard_stats.dart';
import 'dashboard_controller.dart';
import 'weekly_bar_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // Currency symbol used across revenue figures (INR assumed for V1).
  static const _currency = '\u20B9';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardControllerProvider);
    final notifier = ref.read(dashboardControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OVERVIEW',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text('Dashboard',
                        style: Theme.of(context).textTheme.displaySmall),
                  ],
                ),
              ),
              if (!async.isLoading)
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: notifier.load,
                  icon: const Icon(Icons.refresh, color: AppColors.muted),
                ),
            ],
          ),
          const SizedBox(height: 24),
          async.when(
            loading: () => const SizedBox(
              height: 320,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _ErrorPanel(message: e.toString(), onRetry: notifier.load),
            data: (stats) => _DashboardBody(stats: stats, currency: _currency),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.stats, required this.currency});
  final DashboardStats stats;
  final String currency;

  String _money(double v) {
    final f = NumberFormat.currency(symbol: currency, decimalDigits: 0);
    return f.format(v);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Revenue ---
        const _SectionTitle('Revenue'),
        _CardGrid(children: [
          _StatCard(label: 'Today', value: _money(stats.revenueToday), icon: Icons.today_outlined),
          _StatCard(label: 'This week', value: _money(stats.revenueWeek), icon: Icons.date_range_outlined),
          _StatCard(label: 'This month', value: _money(stats.revenueMonth), icon: Icons.calendar_month_outlined),
        ]),
        const SizedBox(height: 28),

        // --- Orders ---
        const _SectionTitle('Orders'),
        _CardGrid(children: [
          _StatCard(label: 'Total orders', value: '${stats.totalOrders}', icon: Icons.receipt_long_outlined),
          _StatCard(label: 'Pending', value: '${stats.statusCount(OrderStatus.pending)}', icon: Icons.pending_actions_outlined, accent: OrderStatus.pending.color),
          _StatCard(label: 'Preparing', value: '${stats.statusCount(OrderStatus.preparing)}', icon: Icons.soup_kitchen_outlined, accent: OrderStatus.preparing.color),
          _StatCard(label: 'Out for delivery', value: '${stats.statusCount(OrderStatus.outForDelivery)}', icon: Icons.delivery_dining_outlined, accent: OrderStatus.outForDelivery.color),
          _StatCard(label: 'Delivered', value: '${stats.statusCount(OrderStatus.delivered)}', icon: Icons.check_circle_outline, accent: OrderStatus.delivered.color),
          _StatCard(label: 'Cancelled', value: '${stats.statusCount(OrderStatus.cancelled)}', icon: Icons.cancel_outlined, accent: OrderStatus.cancelled.color),
        ]),
        const SizedBox(height: 28),

        // --- Charts ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ChartCard(
              title: 'Revenue · last 7 days',
              child: WeeklyBarChart(
                barColor: AppColors.saffron,
                bars: [
                  for (final p in stats.last7Days)
                    BarDatum(
                      axisLabel: p.weekdayLabel,
                      fraction: stats.maxDailyRevenue <= 0 ? 0 : p.revenue / stats.maxDailyRevenue,
                      valueLabel: p.revenue == 0 ? '' : _money(p.revenue),
                    ),
                ],
              ),
            )),
            const SizedBox(width: 16),
            Expanded(child: _ChartCard(
              title: 'Orders · last 7 days',
              child: WeeklyBarChart(
                barColor: const Color(0xFF2F6FB0),
                bars: [
                  for (final p in stats.last7Days)
                    BarDatum(
                      axisLabel: p.weekdayLabel,
                      fraction: stats.maxDailyOrders <= 0 ? 0 : p.orderCount / stats.maxDailyOrders,
                      valueLabel: p.orderCount == 0 ? '' : '${p.orderCount}',
                    ),
                ],
              ),
            )),
          ],
        ),
        const SizedBox(height: 28),

        // --- Restaurants ---
        const _SectionTitle('Restaurants'),
        _CardGrid(children: [
          _StatCard(label: 'Total', value: '${stats.totalRestaurants}', icon: Icons.storefront_outlined),
          _StatCard(label: 'Active', value: '${stats.activeRestaurants}', icon: Icons.check_circle_outline, accent: AppColors.positive),
          _StatCard(label: 'Inactive', value: '${stats.inactiveRestaurants}', icon: Icons.do_not_disturb_on_outlined, accent: AppColors.muted),
        ]),
        const SizedBox(height: 28),

        // --- Menu ---
        const _SectionTitle('Menu items'),
        _CardGrid(children: [
          _StatCard(label: 'Total', value: '${stats.totalMenuItems}', icon: Icons.restaurant_menu_outlined),
          _StatCard(label: 'Available', value: '${stats.availableMenuItems}', icon: Icons.check_circle_outline, accent: AppColors.positive),
          _StatCard(label: 'Unavailable', value: '${stats.unavailableMenuItems}', icon: Icons.do_not_disturb_on_outlined, accent: AppColors.muted),
        ]),
        const SizedBox(height: 28),

        // --- Banners ---
        const _SectionTitle('Banners'),
        _CardGrid(children: [
          _StatCard(label: 'Total', value: '${stats.totalBanners}', icon: Icons.local_offer_outlined),
          _StatCard(label: 'Active', value: '${stats.activeBanners}', icon: Icons.check_circle_outline, accent: AppColors.positive),
        ]),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1100 ? 4 : c.maxWidth >= 700 ? 3 : c.maxWidth >= 460 ? 2 : 1;
        final spacing = 16.0;
        final width = (c.maxWidth - (cols - 1) * spacing) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final a = accent ?? AppColors.saffronDeep;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: a.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: a),
          ),
          const SizedBox(height: 16),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 36),
          const SizedBox(height: 12),
          Text('Could not load dashboard', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
