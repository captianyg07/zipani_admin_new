/// Roles stored in profiles.role.
enum UserRole {
  superAdmin,
  restaurantOwner,
  deliveryPartner,
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
      case 'delivery_partner':
      case 'deliverypartner':
        return UserRole.deliveryPartner;
      default:
        return UserRole.unknown;
    }
  }

  String get dbValue => switch (this) {
        UserRole.superAdmin => 'super_admin',
        UserRole.restaurantOwner => 'restaurant_owner',
        UserRole.deliveryPartner => 'delivery_partner',
        UserRole.unknown => 'unknown',
      };

  String get label => switch (this) {
        UserRole.superAdmin => 'Super Admin',
        UserRole.restaurantOwner => 'Restaurant Owner',
        UserRole.deliveryPartner => 'Delivery Partner',
        UserRole.unknown => 'Unknown',
      };

  /// Super admin has unrestricted, cross-restaurant access.
  bool get isSuperAdmin => this == UserRole.superAdmin;

  bool get isOwner => this == UserRole.restaurantOwner;

  bool get isDeliveryPartner => this == UserRole.deliveryPartner;
}
