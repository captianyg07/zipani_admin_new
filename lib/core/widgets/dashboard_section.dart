import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import '../design/typography.dart';
import 'app_card.dart';

/// A titled panel: header row (title + optional trailing action) over content.
class SectionPanel extends StatelessWidget {
  const SectionPanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(DS.s20),
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppType.h3)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: DS.s16),
          child,
        ],
      ),
    );
  }
}
