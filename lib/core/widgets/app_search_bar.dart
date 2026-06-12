import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import '../design/typography.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search',
    this.width,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final field = Container(
      height: 44,
      decoration: BoxDecoration(
        color: DS.canvasAlt,
        borderRadius: BorderRadius.circular(DS.rMd),
        border: Border.all(color: DS.line),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 18, color: DS.muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppType.body.copyWith(color: DS.ink),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppType.body.copyWith(color: DS.muted),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
    return width == null ? field : SizedBox(width: width, child: field);
  }
}
