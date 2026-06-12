import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../../auth/data/user_role.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/current_profile_provider.dart';

/// Nav destination + whether a restaurant owner can see it. Super admin sees
/// all. Title is shown in the header for that route.
class _Dest {
  const _Dest(this.label, this.icon, this.route,
      {this.ownerVisible = false, String? title})
      : title = title ?? label;
  final String label;
  final IconData icon;
  final String route;
  final bool ownerVisible;
  final String title;
}

const _all = <_Dest>[
  _Dest('Dashboard', Icons.grid_view_rounded, '/dashboard',
      ownerVisible: true),
  _Dest('Restaurants', Icons.storefront_outlined, '/restaurants'),
  _Dest('Menu', Icons.restaurant_menu_outlined, '/menu', ownerVisible: true),
  _Dest('Orders', Icons.receipt_long_outlined, '/orders', ownerVisible: true),
  _Dest('Offers', Icons.campaign_outlined, '/offers', ownerVisible: true),
];

List<_Dest> _destsFor(UserRole role) {
  if (role.isSuperAdmin) return _all;
  if (role.isOwner) return _all.where((d) => d.ownerVisible).toList();
  return const [];
}

/// New shell: navy sidebar + top header + scrollable content region.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final user = ref.watch(currentUserOrNullProvider);
    final role = user?.role ?? UserRole.unknown;
    final dests = _destsFor(role);

    if (dests.isEmpty) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: DS.brand, strokeWidth: 2.5)),
      );
    }

    var selected = dests.indexWhere((d) => location.startsWith(d.route));
    if (selected < 0) selected = 0;
    final isWide = MediaQuery.sizeOf(context).width >= DS.wideBreakpoint;

    final sidebar = AppSidebar(
      items: [for (final d in dests) SidebarItem(d.label, d.icon, d.route)],
      selectedIndex: selected,
      roleLabel: role.label,
      email: user?.email,
      onSelect: (i) {
        context.go(dests[i].route);
        if (!isWide) Navigator.of(context).maybePop();
      },
      onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
    );

    Widget content(BuildContext ctx) => Column(
          children: [
            AppHeader(
              title: dests[selected].title,
              subtitle: _subtitleFor(role),
              userName: role.label,
              userSubtitle: user?.email,
              onMenu: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
            ),
            Expanded(
              child: Container(
                color: DS.canvas,
                child: child,
              ),
            ),
          ],
        );

    return Scaffold(
      drawer: isWide ? null : Drawer(child: sidebar),
      body: Row(
        children: [
          if (isWide) sidebar,
          Expanded(
            child: Builder(builder: (ctx) => content(ctx)),
          ),
        ],
      ),
    );
  }

  String _subtitleFor(UserRole role) {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}
