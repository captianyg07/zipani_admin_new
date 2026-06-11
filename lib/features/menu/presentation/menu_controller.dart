import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/menu_item_model.dart';
import '../data/menu_repository.dart';

class MenuListState {
  const MenuListState({
    this.page = 0,
    this.pageSize = 10,
    this.search = '',
    this.restaurantId,
    this.veg = VegFilter.all,
    this.availability = AvailabilityFilter.all,
    this.items = const [],
    this.totalCount = 0,
    this.restaurantNames = const {},
    this.isLoading = false,
    this.error,
  });

  final int page;
  final int pageSize;
  final String search;
  final int? restaurantId;
  final VegFilter veg;
  final AvailabilityFilter availability;
  final List<MenuItem> items;
  final int totalCount;
  final Map<int, String> restaurantNames;
  final bool isLoading;
  final String? error;

  int get totalPages =>
      totalCount == 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;
  bool get hasPrev => page > 0;
  bool get hasNext => page < totalPages - 1;

  String restaurantName(int id) => restaurantNames[id] ?? 'Unknown restaurant';

  MenuListState copyWith({
    int? page,
    String? search,
    Object? restaurantId = _sentinel,
    VegFilter? veg,
    AvailabilityFilter? availability,
    List<MenuItem>? items,
    int? totalCount,
    Map<int, String>? restaurantNames,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return MenuListState(
      page: page ?? this.page,
      pageSize: pageSize,
      search: search ?? this.search,
      restaurantId: restaurantId == _sentinel
          ? this.restaurantId
          : restaurantId as int?,
      veg: veg ?? this.veg,
      availability: availability ?? this.availability,
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      restaurantNames: restaurantNames ?? this.restaurantNames,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

class MenuController extends StateNotifier<MenuListState> {
  MenuController(this._repo) : super(const MenuListState()) {
    _init();
  }

  final MenuRepository _repo;

  Future<void> _init() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final names = await _repo.fetchRestaurantNames();
      state = state.copyWith(restaurantNames: names);
      await load();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _readable(e));
    }
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.fetchPage(
        page: state.page,
        pageSize: state.pageSize,
        search: state.search,
        restaurantId: state.restaurantId,
        veg: state.veg,
        availability: state.availability,
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

  void setRestaurant(int? id) {
    state = state.copyWith(restaurantId: id, page: 0);
    load();
  }

  void setVeg(VegFilter veg) {
    state = state.copyWith(veg: veg, page: 0);
    load();
  }

  void setAvailability(AvailabilityFilter a) {
    state = state.copyWith(availability: a, page: 0);
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

  Future<String?> create(MenuItem item) => _mutate(() => _repo.create(item));
  Future<String?> update(MenuItem item) => _mutate(() => _repo.update(item));
  Future<String?> delete(int id) => _mutate(() => _repo.delete(id));
  Future<String?> toggleAvailable(MenuItem item) =>
      _mutate(() => _repo.setAvailable(item.id!, !item.isAvailable));

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

final menuControllerProvider =
    StateNotifierProvider<MenuController, MenuListState>((ref) {
  return MenuController(ref.watch(menuRepositoryProvider));
});
