import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import '../design/typography.dart';

/// A compact styled dropdown for filters and forms.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.width,
  });

  final T? value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final field = Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DS.canvasAlt,
        borderRadius: BorderRadius.circular(DS.rMd),
        border: Border.all(color: DS.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: hint == null
              ? null
              : Text(hint!, style: AppType.body.copyWith(color: DS.muted)),
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 18, color: DS.muted),
          style: AppType.body.copyWith(color: DS.ink),
          borderRadius: BorderRadius.circular(DS.rMd),
          items: [
            for (final it in items)
              DropdownMenuItem<T>(
                value: it.value,
                child: Text(it.label, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
    return width == null ? field : SizedBox(width: width, child: field);
  }
}

class DropdownItem<T> {
  const DropdownItem(this.value, this.label);
  final T value;
  final String label;
}
