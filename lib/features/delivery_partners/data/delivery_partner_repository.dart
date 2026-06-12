import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_controller.dart';
import 'delivery_partner_model.dart';

/// A page of results plus the total matching count.
class DeliveryPartnerPage {
  const DeliveryPartnerPage({required this.items, required this.totalCount});
  final List<DeliveryPartner> items;
  final int totalCount;
}

/// Optional active/inactive filter.
enum PartnerActiveFilter { all, active, inactive }

class DeliveryPartnerRepository {
  DeliveryPartnerRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'delivery_partners';

  /// Server-side search (by name or phone), filter, and pagination.
  Future<DeliveryPartnerPage> fetchPage({
    required int page, // zero-based
    required int pageSize,
    String search = '',
    PartnerActiveFilter filter = PartnerActiveFilter.all,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = _client.from(_table).select();

    final term = search.trim();
    if (term.isNotEmpty) {
      // name ILIKE term OR phone ILIKE term
      query = query.or('name.ilike.%$term%,phone.ilike.%$term%');
    }
    if (filter == PartnerActiveFilter.active) {
      query = query.eq('is_active', true);
    } else if (filter == PartnerActiveFilter.inactive) {
      query = query.eq('is_active', false);
    }

    final rows = await query
        .order('created_at', ascending: false)
        .range(from, to)
        .count(CountOption.exact);

    final items = rows.data
        .map((e) => DeliveryPartner.fromMap(e as Map<String, dynamic>))
        .toList();

    return DeliveryPartnerPage(items: items, totalCount: rows.count);
  }

  Future<void> create(DeliveryPartner p) async {
    await _client.from(_table).insert(p.toInsertMap());
  }

  Future<void> update(DeliveryPartner p) async {
    final id = p.id;
    if (id == null) {
      throw StateError('Cannot update a delivery partner without an id.');
    }
    await _client.from(_table).update(p.toInsertMap()).eq('id', id);
  }

  Future<void> delete(int id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<void> setActive(int id, bool isActive) async {
    await _client.from(_table).update({'is_active': isActive}).eq('id', id);
  }
}

final deliveryPartnerRepositoryProvider =
    Provider<DeliveryPartnerRepository>((ref) {
  return DeliveryPartnerRepository(ref.watch(supabaseProvider));
});
