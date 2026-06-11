import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/restaurant_model.dart';
import '../data/restaurant_repository.dart';

/// Immutable query + data state for the restaurant list.
class RestaurantListState {
  const RestaurantListState({
    this.page = 0,
    this.pageSize = 10,
    this.search = '',
    this.filter = ActiveFilter.all,
    this.items = const [],
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
  });

  final int page;
  final int pageSize;
  final String search;
  final ActiveFilter filter;
  final List<Restaurant> items;
  final int totalCount;
  final bool isLoading;
  final String? error;

  int get totalPages =>
      totalCount == 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;
  bool get hasPrev => page > 0;
  bool get hasNext => page < totalPages - 1;

  RestaurantListState copyWith({
    int? page,
    String? search,
    ActiveFilter? filter,
    List<Restaurant>? items,
    int? totalCount,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return RestaurantListState(
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

class RestaurantListController extends StateNotifier<RestaurantListState> {
  RestaurantListController(this._repo) : super(const RestaurantListState()) {
    load();
  }

  final RestaurantRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.fetchPage(
        page: state.page,
        pageSize: state.pageSize,
        search: state.search,
        filter: state.filter,
      );
      // If the current page is now empty (e.g. after a delete) and we're past
      // page 0, step back one page and reload.
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

  void setFilter(ActiveFilter filter) {
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

  Future<String?> create(Restaurant r) => _mutate(() => _repo.create(r));
  Future<String?> update(Restaurant r) => _mutate(() => _repo.update(r));
  Future<String?> delete(dynamic id) => _mutate(() => _repo.delete(id));
  Future<String?> toggleActive(Restaurant r) =>
      _mutate(() => _repo.setActive(r.id, !r.isActive));

  /// Runs a mutation, reloads on success, and returns an error message on
  /// failure (null on success) so the UI can surface it.
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

final restaurantListControllerProvider = StateNotifierProvider<
    RestaurantListController, RestaurantListState>((ref) {
  return RestaurantListController(ref.watch(restaurantRepositoryProvider));
});
