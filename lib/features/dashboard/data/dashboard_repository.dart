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
  ///
  /// [ownerRestaurantIds] controls scoping:
  ///   - null  -> super admin: global metrics across all restaurants.
  ///   - list  -> restaurant owner: metrics limited to the owned restaurant
  ///              ids. An empty list yields zeroes (owner with no restaurant).
  ///
  /// RLS already constrains what each user can read; these filters are the
  /// app-side half of defense in depth and keep the numbers consistent.
  Future<DashboardStats> fetchStats({List<int>? ownerRestaurantIds}) async {
    final isOwner = ownerRestaurantIds != null;

    // Owner with zero restaurants: nothing to show.
    if (isOwner && ownerRestaurantIds.isEmpty) {
      return const DashboardStats();
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final windowStart = startOfToday.subtract(const Duration(days: 6));

    // --- Counts (head requests, no rows transferred) ---
    final totalRestaurants = await _countRestaurants(ownerRestaurantIds);
    final activeRestaurants =
        await _countRestaurants(ownerRestaurantIds, activeOnly: true);
    final totalMenuItems = await _countByRestaurant('menu_items', ownerRestaurantIds);
    final availableMenuItems = await _countByRestaurant(
        'menu_items', ownerRestaurantIds,
        boolColumn: 'is_available');
    final totalOrders = await _countByRestaurant('orders', ownerRestaurantIds);

    // Banners are platform-wide (not restaurant-scoped). Owners do not get
    // banner metrics in the UI, but we still populate them harmlessly.
    final totalBanners = await _count('banners');
    final activeBanners =
        await _count('banners', boolColumn: 'is_active', boolValue: true);

    // --- Orders for revenue + charts (current window) ---
    final ordersFrom =
        windowStart.isBefore(startOfMonth) ? windowStart : startOfMonth;

    var windowQuery = _client
        .from('orders')
        .select('total_amount, status, created_at, restaurant_id')
        .gte('created_at', ordersFrom.toIso8601String());
    if (isOwner) {
      windowQuery = windowQuery.inFilter('restaurant_id', ownerRestaurantIds);
    }
    final orderRows = await windowQuery;
    final orders = orderRows.map((e) => Order.fromMap(e)).toList();

    // --- Status breakdown over all (scoped) orders ---
    var statusQuery = _client.from('orders').select('status');
    if (isOwner) {
      statusQuery = statusQuery.inFilter('restaurant_id', ownerRestaurantIds);
    }
    final statusRows = await statusQuery;
    final statusCounts = <OrderStatus, int>{};
    for (final row in statusRows) {
      final s = OrderStatus.fromRaw(row['status'] as String?);
      statusCounts.update(s, (v) => v + 1, ifAbsent: () => 1);
    }

    // --- Revenue rollups (exclude cancelled) + chart buckets ---
    double revToday = 0, revWeek = 0, revMonth = 0;
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

  // --- count helpers --------------------------------------------------

  /// Counts restaurants, scoped to [ownerIds] when non-null.
  Future<int> _countRestaurants(List<int>? ownerIds,
      {bool activeOnly = false}) async {
    var q = _client.from('restaurants').select();
    if (ownerIds != null) {
      q = q.inFilter('id', ownerIds);
    }
    if (activeOnly) {
      q = q.eq('is_active', true);
    }
    final r = await q.count(CountOption.exact);
    return r.count;
  }

  /// Counts rows in a table that has a restaurant_id column, scoped to
  /// [ownerIds] when non-null, optionally requiring a boolean column = true.
  Future<int> _countByRestaurant(
    String table,
    List<int>? ownerIds, {
    String? boolColumn,
  }) async {
    var q = _client.from(table).select();
    if (ownerIds != null) {
      q = q.inFilter('restaurant_id', ownerIds);
    }
    if (boolColumn != null) {
      q = q.eq(boolColumn, true);
    }
    final r = await q.count(CountOption.exact);
    return r.count;
  }

  /// Unscoped count (used for platform-wide tables like banners).
  Future<int> _count(
    String table, {
    String? boolColumn,
    bool? boolValue,
  }) async {
    var q = _client.from(table).select();
    if (boolColumn != null && boolValue != null) {
      q = q.eq(boolColumn, boolValue);
    }
    final r = await q.count(CountOption.exact);
    return r.count;
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(supabaseProvider));
});
