import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/profile_model.dart';
import '../../auth/data/profile_repository.dart';
import 'delivery_partner_model.dart';
import 'delivery_partner_repository.dart';

/// All profiles whose role is 'delivery_partner'. Drives the "Linked Account"
/// picker in the delivery partner form. Read-only; refreshes when invalidated.
final deliveryPartnerProfilesProvider =
    FutureProvider<List<Profile>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.fetchByRole('delivery_partner');
});

/// All ACTIVE delivery partners, for the order-assignment picker and for
/// resolving partner id -> name in the orders table. Read-only.
final activeDeliveryPartnersProvider =
    FutureProvider<List<DeliveryPartner>>((ref) async {
  final repo = ref.watch(deliveryPartnerRepositoryProvider);
  // A generous page size; assignment pickers don't paginate.
  final page = await repo.fetchPage(
    page: 0,
    pageSize: 1000,
    filter: PartnerActiveFilter.active,
  );
  return page.items;
});

