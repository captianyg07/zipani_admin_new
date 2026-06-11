/// Roles stored in profiles.role. V2 model: two roles only.
enum UserRole {
  superAdmin,
  restaurantOwner,
  unknown;

  /// Maps stored text to an enum. Defaults to [unknown] so an unrecognized
  /// or missing role never silently grants access.
  static UserRole fromRaw(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      case 'restaurant_owner':
      case 'restaurantowner':
      case 'owner':
        return UserRole.restaurantOwner;
      default:
        return UserRole.unknown;
    }
  }

  String get dbValue => switch (this) {
        UserRole.superAdmin => 'super_admin',
        UserRole.restaurantOwner => 'restaurant_owner',
        UserRole.unknown => 'unknown',
      };

  String get label => switch (this) {
        UserRole.superAdmin => 'Super Admin',
        UserRole.restaurantOwner => 'Restaurant Owner',
        UserRole.unknown => 'Unknown',
      };

  /// Super admin has unrestricted, cross-restaurant access.
  bool get isSuperAdmin => this == UserRole.superAdmin;

  bool get isOwner => this == UserRole.restaurantOwner;
}
