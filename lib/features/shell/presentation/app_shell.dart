import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/user_role.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/current_profile_provider.dart';

/// Navigation destinations. [ownerVisible] controls whether a restaurant
/// owner sees the item; admins and super_admins see everything.
class NavItem {
  const NavItem(this.label, this.icon, this.route, {this.ownerVisible = false});
  final String label;
  final IconData icon;
  final String route;
  final bool ownerVisible;
}

const _allNavItems = <NavItem>[
  NavItem('Dashboard', Icons.dashboard_outlined, '/dashboard',
      ownerVisible: true),
  NavItem('Restaurants', Icons.storefront_outlined, '/restaurants'),
  NavItem('Menu', Icons.restaurant_menu_outlined, '/menu', ownerVisible: true),
  NavItem('Orders', Icons.receipt_long_outlined, '/orders', ownerVisible: true),
  NavItem('Offers', Icons.local_offer_outlined, '/offers', ownerVisible: true),
];

/// Returns the nav items visible to [role].
List<NavItem> navItemsForRole(UserRole role) {
  if (role.isSuperAdmin) return _allNavItems;
  if (role.isOwner) {
    return _allNavItems.where((n) => n.ownerVisible).toList();
  }
  return const [];
}

/// Persistent shell with sidebar + content. Wraps every authenticated screen
/// via GoRouter's ShellRoute. Responsive: rail on wide, drawer on narrow.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _selectedIndex(String location, List<NavItem> items) {
    final i = items.indexWhere((n) => location.startsWith(n.route));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final user = ref.watch(currentUserOrNullProvider);
    final role = user?.role ?? UserRole.unknown;
    final navItems = navItemsForRole(role);

    // Guard against an empty list (unknown role) so indexing is always safe.
    if (navItems.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selected = _selectedIndex(location, navItems);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final sidebar = _Sidebar(
      items: navItems,
      selected: selected,
      roleLabel: role.label,
      email: user?.email,
      onTap: (i) {
        context.go(navItems[i].route);
        if (!isWide) Navigator.of(context).maybePop();
      },
      onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
    );

    return Scaffold(
      drawer: isWide ? null : Drawer(child: sidebar),
      appBar: isWide
          ? null
          : AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              foregroundColor: AppColors.ink,
              title: Text(navItems[selected].label),
            ),
      body: Row(
        children: [
          if (isWide) SizedBox(width: 248, child: sidebar),
          Expanded(
            child: Container(
              color: AppColors.cream,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.selected,
    required this.roleLabel,
    required this.email,
    required this.onTap,
    required this.onSignOut,
  });

  final List<NavItem> items;
  final int selected;
  final String roleLabel;
  final String? email;
  final ValueChanged<int> onTap;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.saffron,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Z',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                  ),
                  const SizedBox(width: 10),
                  const Text('Zipani',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.5)),
                ],
              ),
            ),
            for (var i = 0; i < items.length; i++)
              _NavTile(
                item: items[i],
                active: i == selected,
                onTap: () => onTap(i),
              ),
            const Spacer(),
            const Divider(color: Color(0xFF2C2823), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roleLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (email != null && email!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9C938A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFB7AEA3)),
              title: const Text('Sign out',
                  style: TextStyle(color: Color(0xFFB7AEA3))),
              onTap: onSignOut,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.active, required this.onTap});

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: active ? AppColors.saffron : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(item.icon,
                    size: 20,
                    color: active ? Colors.white : const Color(0xFFB7AEA3)),
                const SizedBox(width: 13),
                Text(item.label,
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0xFFD8D1C7),
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14.5,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
