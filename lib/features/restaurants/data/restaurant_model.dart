/// Maps 1:1 to the existing Supabase `restaurants` table.
/// Columns: id, created_at, name, category, rating, delivery_time,
/// is_veg, image_url, is_active.
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    this.category,
    this.rating,
    this.deliveryTime,
    this.isVeg = false,
    this.imageUrl,
    this.isActive = true,
    this.createdAt,
  });

  final dynamic id; // int or uuid — kept dynamic to match unknown PK type
  final String name;
  final String? category;
  final double? rating;
  final String? deliveryTime;
  final bool isVeg;
  final String? imageUrl;
  final bool isActive;
  final DateTime? createdAt;

  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'],
      name: (map['name'] ?? '') as String,
      category: map['category'] as String?,
      rating: _toDouble(map['rating']),
      deliveryTime: map['delivery_time']?.toString(),
      isVeg: (map['is_veg'] as bool?) ?? false,
      imageUrl: map['image_url'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
    );
  }

  /// Payload for insert/update. Excludes id and created_at (DB-managed).
  Map<String, dynamic> toInsertMap() => {
        'name': name,
        'category': category,
        'rating': rating,
        'delivery_time': deliveryTime,
        'is_veg': isVeg,
        'image_url': imageUrl,
        'is_active': isActive,
      };

  Restaurant copyWith({
    String? name,
    String? category,
    double? rating,
    String? deliveryTime,
    bool? isVeg,
    String? imageUrl,
    bool? isActive,
  }) {
    return Restaurant(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      isVeg: isVeg ?? this.isVeg,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
