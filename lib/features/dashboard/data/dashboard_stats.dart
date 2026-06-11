import '../../orders/data/order_status.dart';

/// One day's aggregate for the 7-day charts.
class DailyPoint {
  const DailyPoint({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });

  final DateTime date;
  final double revenue;
  final int orderCount;

  /// Short weekday label (Mon, Tue, ...) for chart axes.
  String get weekdayLabel {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[(date.weekday - 1).clamp(0, 6)];
  }
}

/// All metrics shown on the dashboard, computed once per load.
class DashboardStats {
  const DashboardStats({
    this.revenueToday = 0,
    this.revenueWeek = 0,
    this.revenueMonth = 0,
    this.totalOrders = 0,
    this.ordersByStatus = const {},
    this.totalRestaurants = 0,
    this.activeRestaurants = 0,
    this.totalMenuItems = 0,
    this.availableMenuItems = 0,
    this.totalBanners = 0,
    this.activeBanners = 0,
    this.last7Days = const [],
  });

  final double revenueToday;
  final double revenueWeek;
  final double revenueMonth;

  final int totalOrders;
  final Map<OrderStatus, int> ordersByStatus;

  final int totalRestaurants;
  final int activeRestaurants;

  final int totalMenuItems;
  final int availableMenuItems;

  final int totalBanners;
  final int activeBanners;

  final List<DailyPoint> last7Days;

  int get inactiveRestaurants =>
      (totalRestaurants - activeRestaurants).clamp(0, totalRestaurants);
  int get unavailableMenuItems =>
      (totalMenuItems - availableMenuItems).clamp(0, totalMenuItems);
  int get inactiveBanners =>
      (totalBanners - activeBanners).clamp(0, totalBanners);

  int statusCount(OrderStatus s) => ordersByStatus[s] ?? 0;

  /// Largest revenue across the 7-day window (for chart scaling).
  double get maxDailyRevenue {
    var max = 0.0;
    for (final p in last7Days) {
      if (p.revenue > max) max = p.revenue;
    }
    return max;
  }

  /// Largest order count across the 7-day window (for chart scaling).
  int get maxDailyOrders {
    var max = 0;
    for (final p in last7Days) {
      if (p.orderCount > max) max = p.orderCount;
    }
    return max;
  }
}
