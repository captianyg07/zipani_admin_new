import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_controller.dart';
import 'menu_item_model.dart';

class MenuPage {
  const MenuPage({required this.items, required this.totalCount});
  final List<MenuItem> items;
  final int totalCount;
}

/// Tri-state filters (null-style "all" handled by enum).
enum VegFilter { all, veg, nonVeg }

enum AvailabilityFilter { all, available, unavailable }

class MenuRepository {
  MenuRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'menu_items';
  static const _restaurantsTable = 'restaurants';

  /// Loads a map of restaurant id -> name for the dropdown and list display.
  Future<Map<int, String>> fetchRestaurantNames() async {
    final rows = await _client.from(_restaurantsTable).select('id, name');
    final map = <int, String>{};
    for (final row in rows) {
      final id = row['id'];
      if (id is int) {
        map[id] = (row['name'] ?? '') as String;
      } else {
        final parsed = int.tryParse(id.toString());
        if (parsed != null) map[parsed] = (row['name'] ?? '') as String;
      }
    }
    return map;
  }

  Future<MenuPage> fetchPage({
    required int page, // zero-based
    required int pageSize,
    String search = '',
    int? restaurantId,
    VegFilter veg = VegFilter.all,
    AvailabilityFilter availability = AvailabilityFilter.all,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = _client.from(_table).select();

    final term = search.trim();
    if (term.isNotEmpty) {
      query = query.ilike('name', '%$term%');
    }
    if (restaurantId != null) {
      query = query.eq('restaurant_id', restaurantId);
    }
    if (veg == VegFilter.veg) {
      query = query.eq('is_veg', true);
    } else if (veg == VegFilter.nonVeg) {
      query = query.eq('is_veg', false);
    }
    if (availability == AvailabilityFilter.available) {
      query = query.eq('is_available', true);
    } else if (availability == AvailabilityFilter.unavailable) {
      query = query.eq('is_available', false);
    }

    final rows = await query
        .order('id', ascending: false)
        .range(from, to)
        .count(CountOption.exact);

    final items =
        rows.data.map((e) => MenuItem.fromMap(e)).toList();

    return MenuPage(items: items, totalCount: rows.count);
  }

  Future<void> create(MenuItem item) async {
    await _client.from(_table).insert(item.toInsertMap());
  }

  Future<void> update(MenuItem item) async {
    await _client.from(_table).update(item.toInsertMap()).eq('id', item.id!);
  }

  Future<void> delete(int id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<void> setAvailable(int id, bool isAvailable) async {
    await _client
        .from(_table)
        .update({'is_available': isAvailable}).eq('id', id);
  }
}

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ref.watch(supabaseProvider));
});
