/// Maps 1:1 to the existing Supabase `banners` table.
/// Columns: id (int8), title (text), subtitle (text), image_url (text),
/// is_active (boolean).
class Banner {
  const Banner({
    this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.isActive = true,
  });

  final int? id; // null for not-yet-inserted banners
  final String title;
  final String? subtitle;
  final String imageUrl;
  final bool isActive;

  factory Banner.fromMap(Map<String, dynamic> map) {
    return Banner(
      id: _toInt(map['id']),
      title: (map['title'] ?? '') as String,
      subtitle: map['subtitle'] as String?,
      imageUrl: (map['image_url'] ?? '') as String,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }

  /// Payload for insert/update. Excludes id (DB-managed).
  Map<String, dynamic> toInsertMap() => {
        'title': title,
        'subtitle': subtitle,
        'image_url': imageUrl,
        'is_active': isActive,
      };

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
