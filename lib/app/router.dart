import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/widgets/app_logo.dart';
import 'theme/app_colors.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/compare/presentation/compare_page.dart';
import '../features/destination_detail/presentation/destination_detail_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/search/presentation/search_page.dart';

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
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  static const _tabs = [
    _ShellTab('/', 'Beranda', LucideIcons.house),
    _ShellTab('/search', 'Cari', LucideIcons.search),
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
      body: Column(
        children: [
          const _MobileBrandBar(),
          Expanded(child: child),
        ],
      ),
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

class _MobileBrandBar extends StatelessWidget {
  const _MobileBrandBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const AppLogo(size: 34),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EC),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFFFD0BA)),
              ),
              child: const Row(
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'AI Travel',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
