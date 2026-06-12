/// Maps 1:1 to the Supabase `delivery_partners` table (Phase 9.1).
/// Columns: id (bigint), user_id (uuid, nullable), name, phone,
/// vehicle_type, vehicle_number, is_active, created_at.
class DeliveryPartner {
  const DeliveryPartner({
    this.id,
    this.userId,
    required this.name,
    this.phone,
    this.vehicleType,
    this.vehicleNumber,
    this.isActive = true,
    this.createdAt,
  });

  final int? id; // null for not-yet-inserted partners
  final String? userId; // uuid string; nullable until an auth account is linked
  final String name;
  final String? phone;
  final String? vehicleType;
  final String? vehicleNumber;
  final bool isActive;
  final DateTime? createdAt;

  factory DeliveryPartner.fromMap(Map<String, dynamic> map) {
    return DeliveryPartner(
      id: _toInt(map['id']),
      userId: map['user_id']?.toString(),
      name: (map['name'] ?? '') as String,
      phone: map['phone'] as String?,
      vehicleType: map['vehicle_type'] as String?,
      vehicleNumber: map['vehicle_number'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
    );
  }

  /// Payload for insert/update. Excludes id and created_at (DB-managed).
  /// user_id is included only when set, so the DB default/NULL is preserved.
  Map<String, dynamic> toInsertMap() => {
        'name': name,
        'phone': phone,
        'vehicle_type': vehicleType,
        'vehicle_number': vehicleNumber,
        'is_active': isActive,
        if (userId != null && userId!.isNotEmpty) 'user_id': userId,
      };

  DeliveryPartner copyWith({
    String? userId,
    String? name,
    String? phone,
    String? vehicleType,
    String? vehicleNumber,
    bool? isActive,
  }) {
    return DeliveryPartner(
      id: id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
