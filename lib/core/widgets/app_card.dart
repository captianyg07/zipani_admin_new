import 'package:flutter/material.dart';

import '../design/design_tokens.dart';

/// The single card surface every screen composes from.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DS.s20),
    this.radius = DS.rLg,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: DS.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: DS.shadowSm,
      ),
      child: child,
    );
  }
}
