import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// The five canonical order statuses.
///
/// Because `orders.status` is free text, we normalize whatever is stored
/// (any casing, spaces, underscores, or hyphens) to one of these. Unknown
/// values fall back to [OrderStatus.unknown] so the UI never crashes.
enum OrderStatus {
  pending,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
  unknown;

  /// Human-readable label for chips and menus.
  String get label => switch (this) {
        OrderStatus.pending => 'Pending',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.outForDelivery => 'Out For Delivery',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
        OrderStatus.unknown => 'Unknown',
      };

  /// The canonical string written back to the database on update.
  /// Uses Title Case with spaces (matches the labels above).
  String get dbValue => switch (this) {
        OrderStatus.unknown => 'Unknown',
        _ => label,
      };

  Color get color => switch (this) {
        OrderStatus.pending => AppColors.warning,
        OrderStatus.preparing => AppColors.saffronDeep,
        OrderStatus.outForDelivery => const Color(0xFF2F6FB0),
        OrderStatus.delivered => AppColors.positive,
        OrderStatus.cancelled => AppColors.danger,
        OrderStatus.unknown => AppColors.muted,
      };

  /// Statuses the admin can assign (excludes [unknown]).
  static List<OrderStatus> get assignable => const [
        OrderStatus.pending,
        OrderStatus.preparing,
        OrderStatus.outForDelivery,
        OrderStatus.delivered,
        OrderStatus.cancelled,
      ];

  /// Maps an arbitrary stored string to a canonical status.
  /// Strips case and all separators so "out_for_delivery", "Out For
  /// Delivery", and "outfordelivery" all match.
  static OrderStatus fromRaw(String? raw) {
    if (raw == null) return OrderStatus.unknown;
    final key = raw.toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');
    switch (key) {
      case 'pending':
        return OrderStatus.pending;
      case 'preparing':
      case 'inpreparation':
      case 'cooking':
        return OrderStatus.preparing;
      case 'outfordelivery':
      case 'ontheway':
      case 'dispatched':
      case 'outfordelivary': // common misspelling, just in case
        return OrderStatus.outForDelivery;
      case 'delivered':
      case 'completed':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
      case 'rejected':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.unknown;
    }
  }
}
