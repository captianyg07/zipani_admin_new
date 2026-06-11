import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_controller.dart';
import 'banner_model.dart';

class BannerPage {
  const BannerPage({required this.items, required this.totalCount});
  final List<Banner> items;
  final int totalCount;
}

enum BannerActiveFilter { all, active, inactive }

class BannerRepository {
  BannerRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'banners';

  /// Server-side search (by title), filter, and pagination with exact count.
  Future<BannerPage> fetchPage({
    required int page, // zero-based
    required int pageSize,
    String search = '',
    BannerActiveFilter filter = BannerActiveFilter.all,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = _client.from(_table).select();

    final term = search.trim();
    if (term.isNotEmpty) {
      query = query.ilike('title', '%$term%');
    }
    if (filter == BannerActiveFilter.active) {
      query = query.eq('is_active', true);
    } else if (filter == BannerActiveFilter.inactive) {
      query = query.eq('is_active', false);
    }

    final rows = await query
        .order('id', ascending: false)
        .range(from, to)
        .count(CountOption.exact);

    final items = rows.data.map((e) => Banner.fromMap(e)).toList();

    return BannerPage(items: items, totalCount: rows.count);
  }

  Future<void> create(Banner b) async {
    await _client.from(_table).insert(b.toInsertMap());
  }

  Future<void> update(Banner b) async {
    await _client.from(_table).update(b.toInsertMap()).eq('id', b.id!);
  }

  Future<void> delete(int id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<void> setActive(int id, bool isActive) async {
    await _client.from(_table).update({'is_active': isActive}).eq('id', id);
  }
}

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepository(ref.watch(supabaseProvider));
});
