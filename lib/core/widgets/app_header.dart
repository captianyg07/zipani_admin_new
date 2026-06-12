import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import '../design/typography.dart';
import 'avatar.dart';

/// Top header bar: page title + optional subtitle on the left, optional
/// actions, and a user chip on the right. Used by the shell on every screen.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.userName,
    this.userSubtitle,
    this.actions = const [],
    this.onMenu,
  });

  final String title;
  final String? subtitle;
  final String? userName;
  final String? userSubtitle;
  final List<Widget> actions;

  /// Hamburger callback on narrow layouts (null hides it).
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: DS.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: DS.s24),
      decoration: const BoxDecoration(
        color: DS.surface,
        border: Border(bottom: BorderSide(color: DS.line)),
      ),
      child: Row(
        children: [
          if (onMenu != null) ...[
            IconButton(
              icon: const Icon(Icons.menu, color: DS.ink),
              onPressed: onMenu,
            ),
            const SizedBox(width: DS.s8),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.h1, overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Text(subtitle!,
                      style: AppType.small, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          for (final a in actions) ...[
            const SizedBox(width: DS.s12),
            a,
          ],
          if (userName != null) ...[
            const SizedBox(width: DS.s20),
            Container(width: 1, height: 32, color: DS.line),
            const SizedBox(width: DS.s16),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(userName!, style: AppType.bodyStrong),
                    if (userSubtitle != null)
                      Text(userSubtitle!, style: AppType.small),
                  ],
                ),
                const SizedBox(width: DS.s12),
                AppAvatar(label: userName!, size: 38),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
