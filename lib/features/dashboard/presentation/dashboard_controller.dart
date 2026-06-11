import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_repository.dart';
import '../data/dashboard_stats.dart';

class DashboardController extends StateNotifier<AsyncValue<DashboardStats>> {
  DashboardController(this._repo) : super(const AsyncLoading()) {
    load();
  }

  final DashboardRepository _repo;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      final stats = await _repo.fetchStats();
      if (mounted) state = AsyncData(stats);
    } catch (e, st) {
      if (mounted) state = AsyncError(e, st);
    }
  }
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, AsyncValue<DashboardStats>>(
        (ref) {
  return DashboardController(ref.watch(dashboardRepositoryProvider));
});
