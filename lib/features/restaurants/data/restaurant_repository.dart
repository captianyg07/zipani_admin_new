import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_controller.dart';
import 'restaurant_model.dart';

/// Result of a paginated query: the page rows plus the total matching count.
class RestaurantPage {
  const RestaurantPage({required this.items, required this.totalCount});
  final List<Restaurant> items;
  final int totalCount;
}

/// Optional active/inactive filter.
enum ActiveFilter { all, active, inactive }

class RestaurantRepository {
  RestaurantRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'restaurants';

  /// Server-side search (by name), filter, and pagination.
  Future<RestaurantPage> fetchPage({
    required int page, // zero-based
    required int pageSize,
    String search = '',
    ActiveFilter filter = ActiveFilter.all,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    // Build the filtered query first, then apply ordering + range.
    var query = _client.from(_table).select();

    final term = search.trim();
    if (term.isNotEmpty) {
      query = query.ilike('name', '%$term%');
    }
    if (filter == ActiveFilter.active) {
      query = query.eq('is_active', true);
    } else if (filter == ActiveFilter.inactive) {
      query = query.eq('is_active', false);
    }

    final rows = await query
        .order('created_at', ascending: false)
        .range(from, to)
        .count(CountOption.exact);

    final data = rows.data;
    final items = data
        .map((e) => Restaurant.fromMap(e as Map<String, dynamic>))
        .toList();

    return RestaurantPage(items: items, totalCount: rows.count);
  }

  Future<void> create(Restaurant r) async {
    await _client.from(_table).insert(r.toInsertMap());
  }

  Future<void> update(Restaurant r) async {
    await _client.from(_table).update(r.toInsertMap()).eq('id', r.id);
  }

  Future<void> delete(dynamic id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<void> setActive(dynamic id, bool isActive) async {
    await _client.from(_table).update({'is_active': isActive}).eq('id', id);
  }
}

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepository(ref.watch(supabaseProvider));
});
