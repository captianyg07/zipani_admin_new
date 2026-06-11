import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../orders/data/order_model.dart';
import '../../orders/data/order_status.dart';
import 'dashboard_stats.dart';

class DashboardRepository {
  DashboardRepository(this._client);
  final SupabaseClient _client;

  /// Loads everything the dashboard needs and computes aggregates.
  Future<DashboardStats> fetchStats() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    // Monday-based week start.
    final startOfWeek =
        startOfToday.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    // 7-day chart window: today and the previous 6 days.
    final windowStart = startOfToday.subtract(const Duration(days: 6));

    // --- Simple counts (head request, no rows transferred) ---
    final totalRestaurants = await _count('restaurants');
    final activeRestaurants =
        await _count('restaurants', activeColumn: 'is_active', active: true);
    final totalMenuItems = await _count('menu_items');
    final availableMenuItems = await _count('menu_items',
        activeColumn: 'is_available', active: true);
    final totalBanners = await _count('banners');
    final activeBanners =
        await _count('banners', activeColumn: 'is_active', active: true);
    final totalOrders = await _count('orders');

    // --- Orders: fetch fields needed for revenue + status + charts ---
    // Pull this month's orders (covers today, week, month, and the 7-day
    // window which is always within the current or previous month edge).
    // To be safe for the 7-day window crossing a month boundary, fetch from
    // the earlier of windowStart and startOfMonth.
    final ordersFrom =
        windowStart.isBefore(startOfMonth) ? windowStart : startOfMonth;

    final orderRows = await _client
        .from('orders')
        .select('total_amount, status, created_at')
        .gte('created_at', ordersFrom.toIso8601String());

    final orders = orderRows.map((e) => Order.fromMap(e)).toList();

    // --- Status breakdown over ALL orders (consistent with Total Orders) ---
    // Fetch just the status column for every order; lightweight at V1 scale.
    final statusRows = await _client.from('orders').select('status');
    final statusCounts = <OrderStatus, int>{};
    for (final row in statusRows) {
      final s = OrderStatus.fromRaw(row['status'] as String?);
      statusCounts.update(s, (v) => v + 1, ifAbsent: () => 1);
    }

    // --- Revenue rollups (exclude cancelled from revenue) ---
    double revToday = 0, revWeek = 0, revMonth = 0;

    // Daily buckets for the 7-day charts.
    final dailyRevenue = <DateTime, double>{};
    final dailyOrders = <DateTime, int>{};
    for (var i = 0; i < 7; i++) {
      final d = windowStart.add(Duration(days: i));
      dailyRevenue[d] = 0;
      dailyOrders[d] = 0;
    }

    for (final o in orders) {
      final created = o.createdAt;
      final amount = o.totalAmount ?? 0;
      final isCancelled = o.status == OrderStatus.cancelled;

      if (created == null) continue;
      final day = DateTime(created.year, created.month, created.day);

      if (!isCancelled) {
        if (!created.isBefore(startOfToday)) revToday += amount;
        if (!created.isBefore(startOfWeek)) revWeek += amount;
        if (!created.isBefore(startOfMonth)) revMonth += amount;
      }

      // Chart buckets (count all orders incl. cancelled; revenue excl.).
      if (dailyOrders.containsKey(day)) {
        dailyOrders[day] = (dailyOrders[day] ?? 0) + 1;
        if (!isCancelled) {
          dailyRevenue[day] = (dailyRevenue[day] ?? 0) + amount;
        }
      }
    }

    final last7 = <DailyPoint>[];
    for (var i = 0; i < 7; i++) {
      final d = windowStart.add(Duration(days: i));
      last7.add(DailyPoint(
        date: d,
        revenue: dailyRevenue[d] ?? 0,
        orderCount: dailyOrders[d] ?? 0,
      ));
    }

    return DashboardStats(
      revenueToday: revToday,
      revenueWeek: revWeek,
      revenueMonth: revMonth,
      totalOrders: totalOrders,
      ordersByStatus: statusCounts,
      totalRestaurants: totalRestaurants,
      activeRestaurants: activeRestaurants,
      totalMenuItems: totalMenuItems,
      availableMenuItems: availableMenuItems,
      totalBanners: totalBanners,
      activeBanners: activeBanners,
      last7Days: last7,
    );
  }

  /// Returns an exact row count, optionally filtered by a boolean column.
  /// Uses a head request so no row data is transferred.
  Future<int> _count(
    String table, {
    String? activeColumn,
    bool? active,
  }) async {
    if (activeColumn != null && active != null) {
      return _client
          .from(table)
          .select()
          .eq(activeColumn, active)
          .count(CountOption.exact)
          .then((r) => r.count);
    }
    return _client
        .from(table)
        .select()
        .count(CountOption.exact)
        .then((r) => r.count);
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(supabaseProvider));
});
