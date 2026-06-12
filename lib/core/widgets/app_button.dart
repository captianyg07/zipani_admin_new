import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import '../design/typography.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expand = false,
    this.height = 46,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      AppButtonVariant.primary => (DS.brand, Colors.white, null),
      AppButtonVariant.secondary => (DS.surface, DS.ink, DS.line),
      AppButtonVariant.ghost => (Colors.transparent, DS.inkSoft, null),
      AppButtonVariant.danger => (DS.danger, Colors.white, null),
    };

    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(DS.rMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(DS.rMd),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: border == null
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(DS.rMd),
                    border: Border.all(color: border),
                  ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(label,
                    style: AppType.bodyStrong
                        .copyWith(color: fg, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
