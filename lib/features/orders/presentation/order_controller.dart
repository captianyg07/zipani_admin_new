import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/order_model.dart';
import '../data/order_repository.dart';
import '../data/order_status.dart';

class OrderListState {
  const OrderListState({
    this.page = 0,
    this.pageSize = 10,
    this.search = '',
    this.status,
    this.items = const [],
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
  });

  final int page;
  final int pageSize;
  final String search;

  /// null = all statuses.
  final OrderStatus? status;
  final List<Order> items;
  final int totalCount;
  final bool isLoading;
  final String? error;

  int get totalPages =>
      totalCount == 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;
  bool get hasPrev => page > 0;
  bool get hasNext => page < totalPages - 1;

  OrderListState copyWith({
    int? page,
    String? search,
    Object? status = _sentinel,
    List<Order>? items,
    int? totalCount,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return OrderListState(
      page: page ?? this.page,
      pageSize: pageSize,
      search: search ?? this.search,
      status: status == _sentinel ? this.status : status as OrderStatus?,
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

class OrderListController extends StateNotifier<OrderListState> {
  OrderListController(this._repo) : super(const OrderListState()) {
    load();
  }

  final OrderRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.fetchPage(
        page: state.page,
        pageSize: state.pageSize,
        search: state.search,
        status: state.status,
      );
      if (result.items.isEmpty && state.page > 0) {
        state = state.copyWith(page: state.page - 1);
        return load();
      }
      state = state.copyWith(
        items: result.items,
        totalCount: result.totalCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _readable(e));
    }
  }

  void setSearch(String value) {
    state = state.copyWith(search: value, page: 0);
    load();
  }

  void setStatus(OrderStatus? status) {
    state = state.copyWith(status: status, page: 0);
    load();
  }

  void nextPage() {
    if (!state.hasNext) return;
    state = state.copyWith(page: state.page + 1);
    load();
  }

  void prevPage() {
    if (!state.hasPrev) return;
    state = state.copyWith(page: state.page - 1);
    load();
  }

  /// Updates status, then reloads the page. Returns an error message on
  /// failure (null on success).
  Future<String?> updateStatus(int orderId, OrderStatus status) async {
    try {
      await _repo.updateStatus(orderId, status);
      await load();
      return null;
    } catch (e) {
      return _readable(e);
    }
  }

  /// Assign or reassign a rider to an order. Phase 9.4.
  Future<String?> assignPartner(int orderId, int deliveryPartnerId) async {
    try {
      await _repo.assignPartner(orderId, deliveryPartnerId);
      await load();
      return null;
    } catch (e) {
      return _readable(e);
    }
  }

  /// Remove a rider assignment from an order.
  Future<String?> unassignPartner(int orderId) async {
    try {
      await _repo.unassignPartner(orderId);
      await load();
      return null;
    } catch (e) {
      return _readable(e);
    }
  }

  String _readable(Object e) =>
      'Something went wrong. Please try again.\n${e.toString()}';
}

final orderListControllerProvider =
    StateNotifierProvider<OrderListController, OrderListState>((ref) {
  return OrderListController(ref.watch(orderRepositoryProvider));
});

/// Loads line items for a specific order (used by the detail dialog).
final orderItemsProvider =
    FutureProvider.family<List<OrderItem>, int>((ref, orderId) async {
  return ref.watch(orderRepositoryProvider).fetchItems(orderId);
});
