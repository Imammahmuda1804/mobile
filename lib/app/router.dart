import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/compare/presentation/compare_page.dart';
import '../features/destination_detail/presentation/destination_detail_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/routes/presentation/route_builder_page.dart';
import '../features/routes/presentation/route_detail_page.dart';
import '../features/routes/presentation/routes_page.dart';
import '../features/search/presentation/search_page.dart';

// Router utama untuk tab shell, detail, auth, dan deep link query.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => NoTransitionPage(
              child: SearchPage(initialQuery: state.uri.queryParameters['q']),
            ),
          ),
          GoRoute(
            path: '/destinations',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SearchPage()),
          ),
          GoRoute(
            path: '/compare',
            pageBuilder: (context, state) => NoTransitionPage(
              child: ComparePage(
                initialFirstId: int.tryParse(
                  state.uri.queryParameters['d1'] ?? '',
                ),
                initialSecondId: int.tryParse(
                  state.uri.queryParameters['d2'] ?? '',
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/routes',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RoutesPage()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfilePage()),
          ),
          GoRoute(
            path: '/favorites',
            redirect: (_, __) => '/profile?tab=favorites',
          ),
        ],
      ),
      GoRoute(
        path: '/destination/:slug',
        builder: (context, state) =>
            DestinationDetailPage(slug: state.pathParameters['slug'] ?? ''),
      ),
      GoRoute(
        path: '/route/:shareSlug',
        builder: (context, state) =>
            RouteDetailPage(shareSlug: state.pathParameters['shareSlug'] ?? ''),
      ),
      GoRoute(
        path: '/routes/new',
        builder: (context, state) => RouteBuilderPage(
          initialDestinationId: int.tryParse(
            state.uri.queryParameters['destinationId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/routes/me',
        builder: (context, state) => const MyRoutesPage(),
      ),
      GoRoute(
        path: '/routes/saved',
        builder: (context, state) => const SavedRoutesPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
    ],
  );
});

// Shell utama yang menampilkan brand bar dan bottom navigation.
class MainShell extends StatelessWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  static const _tabs = [
    _ShellTab('/', 'Beranda', LucideIcons.house),
    _ShellTab('/destinations', 'Destinasi', LucideIcons.mapPinned),
    /*  _ShellTab('/routes', 'Rute', LucideIcons.route), */
    _ShellTab('/compare', 'Bandingkan', LucideIcons.gitCompareArrows),
    _ShellTab('/profile', 'Profil', LucideIcons.userRound),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _tabs.lastIndexWhere(
      (tab) =>
          tab.path == '/' ? location == '/' : location.startsWith(tab.path),
    );

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (index) => context.go(_tabs[index].path),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.icon, fill: 1),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}
