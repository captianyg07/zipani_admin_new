import 'package:flutter/material.dart';

import '../design/design_tokens.dart';

class SidebarItem {
  const SidebarItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

/// The navy navigation rail. Stateless and role-agnostic — the shell passes
/// the already-filtered [items], the [selectedIndex], and callbacks.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.roleLabel,
    required this.email,
    required this.onSignOut,
  });

  final List<SidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String roleLabel;
  final String? email;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: DS.sidebarWidth,
      color: DS.navy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand
            Padding(
              padding: const EdgeInsets.fromLTRB(DS.s24, DS.s24, DS.s24, DS.s32),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: DS.brand,
                      borderRadius: BorderRadius.circular(DS.rMd),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.restaurant_menu,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: DS.s12),
                  const Text('Zipani',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                ],
              ),
            ),
            // Nav
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: DS.s12),
                children: [
                  for (var i = 0; i < items.length; i++)
                    _NavTile(
                      item: items[i],
                      active: i == selectedIndex,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
            ),
            // User block
            Container(
              margin: const EdgeInsets.all(DS.s12),
              padding: const EdgeInsets.symmetric(
                  horizontal: DS.s12, vertical: DS.s12),
              decoration: BoxDecoration(
                color: DS.navyRaised,
                borderRadius: BorderRadius.circular(DS.rMd),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: DS.brand,
                    child: Text(
                      _initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: DS.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(roleLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        if (email != null && email!.isNotEmpty)
                          Text(email!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: DS.navyMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    splashRadius: 18,
                    icon: const Icon(Icons.logout,
                        color: DS.navyText, size: 17),
                    onPressed: onSignOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _initial {
    final s = (roleLabel.isNotEmpty ? roleLabel : (email ?? '?')).trim();
    return s.isEmpty ? '?' : s[0].toUpperCase();
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.active, required this.onTap});
  final SidebarItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DS.s4),
      child: Material(
        color: active ? DS.brand : Colors.transparent,
        borderRadius: BorderRadius.circular(DS.rMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(DS.rMd),
          hoverColor: DS.navyRaised,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: DS.s12, vertical: 11),
            child: Row(
              children: [
                Icon(item.icon,
                    size: 20,
                    color: active ? Colors.white : DS.navyText),
                const SizedBox(width: DS.s12),
                Text(item.label,
                    style: TextStyle(
                      color: active ? Colors.white : DS.navyText,
                      fontSize: 14.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
