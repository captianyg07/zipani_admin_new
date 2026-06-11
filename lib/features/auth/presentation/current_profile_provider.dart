import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';
import 'auth_controller.dart';
import 'current_user.dart';

/// Resolves the signed-in user's full context (profile + owned restaurants).
/// Returns null when signed out. Re-fetches when the auth session changes.
final currentUserProvider = FutureProvider<CurrentUser?>((ref) async {
  ref.watch(authStateProvider); // rebuild on sign in / out / refresh

  final session = ref.watch(sessionProvider);
  if (session == null) return null;

  final repo = ref.watch(profileRepositoryProvider);
  final profile = await repo.fetchById(session.user.id);
  if (profile == null) return null;

  // Owners need their owned restaurant ids; super admins do not.
  final ownedIds = profile.isOwner
      ? await repo.fetchOwnedRestaurantIds(session.user.id)
      : <int>[];

  return CurrentUser(profile: profile, ownedRestaurantIds: ownedIds);
});

/// Synchronous best-effort accessor. Null while loading, on error, or signed
/// out.
final currentUserOrNullProvider = Provider<CurrentUser?>((ref) {
  return ref.watch(currentUserProvider).asData?.value;
});
