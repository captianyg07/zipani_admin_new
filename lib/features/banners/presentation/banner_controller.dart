import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/banner_model.dart';
import '../data/banner_repository.dart';

class BannerListState {
  const BannerListState({
    this.page = 0,
    this.pageSize = 10,
    this.search = '',
    this.filter = BannerActiveFilter.all,
    this.items = const [],
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
  });

  final int page;
  final int pageSize;
  final String search;
  final BannerActiveFilter filter;
  final List<Banner> items;
  final int totalCount;
  final bool isLoading;
  final String? error;

  int get totalPages =>
      totalCount == 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;
  bool get hasPrev => page > 0;
  bool get hasNext => page < totalPages - 1;

  BannerListState copyWith({
    int? page,
    String? search,
    BannerActiveFilter? filter,
    List<Banner>? items,
    int? totalCount,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return BannerListState(
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

class BannerController extends StateNotifier<BannerListState> {
  BannerController(this._repo) : super(const BannerListState()) {
    load();
  }

  final BannerRepository _repo;

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

  void setFilter(BannerActiveFilter filter) {
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

  Future<String?> create(Banner b) => _mutate(() => _repo.create(b));
  Future<String?> update(Banner b) => _mutate(() => _repo.update(b));
  Future<String?> delete(int id) => _mutate(() => _repo.delete(id));
  Future<String?> toggleActive(Banner b) =>
      _mutate(() => _repo.setActive(b.id!, !b.isActive));

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

final bannerControllerProvider =
    StateNotifierProvider<BannerController, BannerListState>((ref) {
  return BannerController(ref.watch(bannerRepositoryProvider));
});
