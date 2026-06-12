import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/delivery_partner_model.dart';
import '../data/delivery_partner_repository.dart';

/// Immutable query + data state for the delivery partner list.
class DeliveryPartnerListState {
  const DeliveryPartnerListState({
    this.page = 0,
    this.pageSize = 10,
    this.search = '',
    this.filter = PartnerActiveFilter.all,
    this.items = const [],
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
  });

  final int page;
  final int pageSize;
  final String search;
  final PartnerActiveFilter filter;
  final List<DeliveryPartner> items;
  final int totalCount;
  final bool isLoading;
  final String? error;

  int get totalPages =>
      totalCount == 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;
  bool get hasPrev => page > 0;
  bool get hasNext => page < totalPages - 1;

  DeliveryPartnerListState copyWith({
    int? page,
    String? search,
    PartnerActiveFilter? filter,
    List<DeliveryPartner>? items,
    int? totalCount,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return DeliveryPartnerListState(
      page: page ?? this.page,
      pageSize: pageSize,
      search: search ?? this.search,
      filter: filter ?? this.filter,
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

class DeliveryPartnerController
    extends StateNotifier<DeliveryPartnerListState> {
  DeliveryPartnerController(this._repo)
      : super(const DeliveryPartnerListState()) {
    load();
  }

  final DeliveryPartnerRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.fetchPage(
        page: state.page,
        pageSize: state.pageSize,
        search: state.search,
        filter: state.filter,
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

  void setFilter(PartnerActiveFilter filter) {
    state = state.copyWith(filter: filter, page: 0);
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

  Future<String?> create(DeliveryPartner p) => _mutate(() => _repo.create(p));
  Future<String?> update(DeliveryPartner p) => _mutate(() => _repo.update(p));
  Future<String?> delete(int id) => _mutate(() => _repo.delete(id));
  Future<String?> toggleActive(DeliveryPartner p) =>
      _mutate(() => _repo.setActive(p.id!, !p.isActive));

  Future<String?> _mutate(Future<void> Function() action) async {
    try {
      await action();
      await load();
      return null;
    } catch (e) {
      return _readable(e);
    }
  }

  String _readable(Object e) =>
      'Something went wrong. Please try again.\n${e.toString()}';
}

final deliveryPartnerControllerProvider = StateNotifierProvider<
    DeliveryPartnerController, DeliveryPartnerListState>((ref) {
  return DeliveryPartnerController(
      ref.watch(deliveryPartnerRepositoryProvider));
});
