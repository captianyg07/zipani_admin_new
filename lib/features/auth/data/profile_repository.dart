import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../presentation/auth_controller.dart';
import 'profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  /// Fetches the profile for the given user id, or null if none exists.
  Future<Profile?> fetchById(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return Profile.fromMap(row);
  }

  /// Restaurant ids owned by the given user (via restaurants.owner_user_id).
  /// Drives owner scoping for menus, orders, and analytics.
  Future<List<int>> fetchOwnedRestaurantIds(String userId) async {
    final rows = await _client
        .from('restaurants')
        .select('id')
        .eq('owner_user_id', userId);

    final ids = <int>[];
    for (final row in rows) {
      final id = row['id'];
      if (id is int) {
        ids.add(id);
      } else {
        final parsed = int.tryParse(id.toString());
        if (parsed != null) ids.add(parsed);
      }
    }
    return ids;
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseProvider));
});
