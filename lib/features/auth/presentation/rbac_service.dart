import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'current_profile_provider.dart';
import 'current_user.dart';

/// Centralizes authorization decisions so screens and the router don't
/// re-implement role logic. All methods are null-safe: with no resolved
/// user, every capability is denied.
class RbacService {
  const RbacService(this._user);

  final CurrentUser? _user;

  bool get isSignedIn => _user != null;
  bool get isProvisioned => _user?.isProvisioned ?? false;
  bool get isSuperAdmin => _user?.isSuperAdmin ?? false;
  bool get isOwner => _user?.isOwner ?? false;

  /// Restaurant ids the user may act on (empty for super admin — they are
  /// not constrained to a list; use [canAccessAllRestaurants]).
  List<int> get ownedRestaurantIds => _user?.ownedRestaurantIds ?? const [];

  bool get canAccessAllRestaurants => isSuperAdmin;

  bool ownsRestaurant(int restaurantId) =>
      _user?.ownsRestaurant(restaurantId) ?? false;

  // --- Feature route capabilities ---------------------------------
  // Owners get dashboard, menu, orders (their own), and offers (view).
  // Only super admins get the all-restaurants management screen.

  bool get canManageRestaurants => isSuperAdmin;
  bool get canViewDashboard => isProvisioned;
  bool get canViewMenu => isProvisioned;
  bool get canViewOrders => isProvisioned;
  bool get canViewOffers => isProvisioned;
  bool get canManageOffers => isSuperAdmin;

  /// Whether [path] is permitted for the current user.
  bool canAccessRoute(String path) {
    if (!isProvisioned) return false;
    if (isSuperAdmin) return true;
    // restaurant_owner:
    switch (path) {
      case '/dashboard':
      case '/menu':
      case '/orders':
      case '/offers':
        return true;
      default:
        return false; // /restaurants is super-admin only
    }
  }
}

final rbacProvider = Provider<RbacService>((ref) {
  return RbacService(ref.watch(currentUserOrNullProvider));
});
