import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_controller.dart';
import 'order_model.dart';
import 'order_status.dart';

class OrderPage {
  const OrderPage({required this.items, required this.totalCount});
  final List<Order> items;
  final int totalCount;
}

class OrderRepository {
  OrderRepository(this._client);
  final SupabaseClient _client;

  static const _ordersTable = 'orders';
  static const _itemsTable = 'order_items';

  /// Known stored spellings per canonical status, used to build a
  /// case-insensitive OR filter (since status is free text).
  static const Map<OrderStatus, List<String>> _statusAliases = {
    OrderStatus.pending: ['pending'],
    OrderStatus.preparing: ['preparing', 'in preparation', 'cooking'],
    OrderStatus.outForDelivery: [
      'out for delivery',
      'out_for_delivery',
      'on the way',
      'dispatched',
    ],
    OrderStatus.delivered: ['delivered', 'completed'],
    OrderStatus.cancelled: ['cancelled', 'canceled', 'rejected'],
  };

  Future<OrderPage> fetchPage({
    required int page,
    required int pageSize,
    String search = '',
    OrderStatus? status,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = _client.from(_ordersTable).select();

    final term = search.trim();
    if (term.isNotEmpty) {
      query = query.ilike('customer_name', '%$term%');
    }

    if (status != null && status != OrderStatus.unknown) {
      final aliases = _statusAliases[status] ?? [status.dbValue];
      // Build: status.ilike.alias1,status.ilike.alias2,...
      final orExpr =
          aliases.map((a) => 'status.ilike.${_escape(a)}').join(',');
      query = query.or(orExpr);
    }

    final rows = await query
        .order('created_at', ascending: false)
        .range(from, to)
        .count(CountOption.exact);

    final items = rows.data.map((e) => Order.fromMap(e)).toList();
    return OrderPage(items: items, totalCount: rows.count);
  }

  /// Loads line items for a single order.
  Future<List<OrderItem>> fetchItems(int orderId) async {
    final rows = await _client
        .from(_itemsTable)
        .select()
        .eq('order_id', orderId)
        .order('id', ascending: true);
    return rows.map((e) => OrderItem.fromMap(e)).toList();
  }

  Future<void> updateStatus(int orderId, OrderStatus status) async {
    await _client
        .from(_ordersTable)
        .update({'status': status.dbValue}).eq('id', orderId);
  }

  /// Assigns (or reassigns) an order to a delivery partner and stamps the
  /// assignment time. Phase 9.4.
  Future<void> assignPartner(int orderId, int deliveryPartnerId) async {
    await _client.from(_ordersTable).update({
      'delivery_partner_id': deliveryPartnerId,
      'assigned_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', orderId);
  }

  /// Clears an order's delivery partner assignment.
  Future<void> unassignPartner(int orderId) async {
    await _client.from(_ordersTable).update({
      'delivery_partner_id': null,
      'assigned_at': null,
    }).eq('id', orderId);
  }

  /// PostgREST `or` values are comma/paren-sensitive; keep aliases simple.
  /// Spaces are fine inside ilike patterns, so minimal escaping is needed.
  String _escape(String value) => value.replaceAll(',', '');
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(supabaseProvider));
});
