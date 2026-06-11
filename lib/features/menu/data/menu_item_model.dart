/// Maps 1:1 to the existing Supabase `menu_items` table.
/// Columns: id (int8), restaurant_id (int8), name (text), category (text),
/// price (numeric), is_veg (bool), image_url (text), is_available (bool).
class MenuItem {
  const MenuItem({
    this.id,
    required this.restaurantId,
    required this.name,
    this.category,
    this.price,
    this.isVeg = false,
    this.imageUrl,
    this.isAvailable = true,
  });

  final int? id; // null for not-yet-inserted items
  final int restaurantId;
  final String name;
  final String? category;
  final double? price;
  final bool isVeg;
  final String? imageUrl;
  final bool isAvailable;

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: _toInt(map['id']),
      restaurantId: _toInt(map['restaurant_id']) ?? 0,
      name: (map['name'] ?? '') as String,
      category: map['category'] as String?,
      price: _toDouble(map['price']),
      isVeg: (map['is_veg'] as bool?) ?? false,
      imageUrl: map['image_url'] as String?,
      isAvailable: (map['is_available'] as bool?) ?? true,
    );
  }

  /// Payload for insert/update. Excludes id (DB-managed).
  Map<String, dynamic> toInsertMap() => {
        'restaurant_id': restaurantId,
        'name': name,
        'category': category,
        'price': price,
        'is_veg': isVeg,
        'image_url': imageUrl,
        'is_available': isAvailable,
      };

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
