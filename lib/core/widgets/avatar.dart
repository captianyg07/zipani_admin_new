import 'package:flutter/material.dart';

import '../design/design_tokens.dart';

/// Initial-based avatar (image support optional via [imageUrl]).
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.label,
    this.imageUrl,
    this.size = 36,
    this.background = DS.brand,
  });

  final String label;
  final String? imageUrl;
  final double size;
  final Color background;

  String get _initial {
    final s = label.trim();
    return s.isEmpty ? '?' : s[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
