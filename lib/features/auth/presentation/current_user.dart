import '../data/profile_model.dart';
import '../data/user_role.dart';

/// The fully-resolved signed-in user: their profile plus, for owners, the
/// set of restaurant ids they own. This is the object the app reads for all
/// role and ownership decisions.
class CurrentUser {
  const CurrentUser({
    required this.profile,
    required this.ownedRestaurantIds,
  });

  final Profile profile;
  final List<int> ownedRestaurantIds;

  String get id => profile.id;
  UserRole get role => profile.role;
  String? get email => profile.email;

  bool get isSuperAdmin => profile.isSuperAdmin;
  bool get isOwner => profile.isOwner;

  /// An owner is only usable once they own at least one restaurant.
  bool get isProvisioned =>
      isSuperAdmin || (isOwner && ownedRestaurantIds.isNotEmpty);

  /// True if this user may act on the given restaurant.
  bool ownsRestaurant(int restaurantId) =>
      isSuperAdmin || ownedRestaurantIds.contains(restaurantId);

  /// The single restaurant for a typical owner; null for super admins or
  /// owners with zero/multiple restaurants (callers handle those cases).
  int? get primaryRestaurantId =>
      ownedRestaurantIds.length == 1 ? ownedRestaurantIds.first : null;
}
