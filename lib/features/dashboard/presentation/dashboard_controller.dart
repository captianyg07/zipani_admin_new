import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/current_profile_provider.dart';
import '../../auth/presentation/current_user.dart';
import '../data/dashboard_repository.dart';
import '../data/dashboard_stats.dart';

class DashboardController extends StateNotifier<AsyncValue<DashboardStats>> {
  DashboardController(this._repo, this._user) : super(const AsyncLoading()) {
    load();
  }

  final DashboardRepository _repo;
  final CurrentUser? _user;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      // Super admin -> null (global). Owner -> their restaurant ids.
      final ownerIds =
          (_user != null && _user.isOwner) ? _user.ownedRestaurantIds : null;
      final stats = await _repo.fetchStats(ownerRestaurantIds: ownerIds);
      if (mounted) state = AsyncData(stats);
    } catch (e, st) {
      if (mounted) state = AsyncError(e, st);
    }
  }
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, AsyncValue<DashboardStats>>(
        (ref) {
  // Rebuild the controller when the resolved user changes (sign in/out, role
  // resolution), so scoping is always based on the current user.
  final user = ref.watch(currentUserOrNullProvider);
  return DashboardController(ref.watch(dashboardRepositoryProvider), user);
});
