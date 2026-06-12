import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/design_tokens.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/current_profile_provider.dart';
import '../../features/auth/presentation/current_user.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/rbac_service.dart';
import '../../features/banners/presentation/banner_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/orders/presentation/order_list_screen.dart';
import '../../features/restaurants/presentation/restaurant_list_screen.dart';
import '../../features/delivery_partners/presentation/delivery_partners_screen.dart';
import '../../features/shell/presentation/app_shell.dart';

/// Rebuilds GoRouter redirects when auth state OR the resolved user change.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(sessionProvider) != null;
      final loc = state.matchedLocation;
      final goingToLogin = loc == '/login';

      if (!loggedIn) return goingToLogin ? null : '/login';

      final userAsync = ref.read(currentUserProvider);

      // While the profile + ownership resolve, hold on the splash.
      if (userAsync.isLoading) {
        return loc == '/splash' ? null : '/splash';
      }

      final CurrentUser? user = userAsync.asData?.value;
      final rbac = RbacService(user);

      // Signed in but not provisioned (no profile, unknown role, or an owner
      // with no restaurant assigned) -> no-access page.
      if (!rbac.isProvisioned) {
        return loc == '/no-access' ? null : '/no-access';
      }

      if (goingToLogin || loc == '/splash' || loc == '/no-access') {
        return '/dashboard';
      }

      // Per-route role guard.
      if (!rbac.canAccessRoute(loc)) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/splash', builder: (_, __) => const _SplashScreen()),
      GoRoute(path: '/no-access', builder: (_, __) => const _NoAccessScreen()),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/restaurants',
            builder: (_, __) => const RestaurantListScreen(),
          ),
          GoRoute(path: '/menu', builder: (_, __) => const MenuScreen()),
          GoRoute(
            path: '/orders',
            builder: (_, __) => const OrderListScreen(),
          ),
          GoRoute(path: '/offers', builder: (_, __) => const BannerScreen()),
          GoRoute(
            path: '/delivery-partners',
            builder: (_, __) => const DeliveryPartnersScreen(),
          ),
        ],
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: DS.canvas,
      body: Center(
        child: CircularProgressIndicator(color: DS.brand, strokeWidth: 2.5),
      ),
    );
  }
}

class _NoAccessScreen extends ConsumerWidget {
  const _NoAccessScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 40),
                const SizedBox(height: 14),
                Text('Account not provisioned',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Your account does not yet have access. A super admin needs '
                  'to assign your role and link your restaurant. Please '
                  'contact them and try again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
