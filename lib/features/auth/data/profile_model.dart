import 'user_role.dart';

/// Maps 1:1 to the `profiles` table (V2: no restaurant_id column).
/// Columns: id (uuid), email (text), role (text), created_at (timestamptz).
class Profile {
  const Profile({
    required this.id,
    this.email,
    required this.role,
    this.createdAt,
  });

  final String id; // uuid
  final String? email;
  final UserRole role;
  final DateTime? createdAt;

  bool get isSuperAdmin => role.isSuperAdmin;
  bool get isOwner => role.isOwner;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'].toString(),
      email: map['email'] as String?,
      role: UserRole.fromRaw(map['role'] as String?),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
    );
  }
}
