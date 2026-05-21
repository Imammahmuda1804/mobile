import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/app_startup_splash.dart';
import '../features/auth/data/auth_controller.dart';
import 'router.dart';
import 'theme/app_theme.dart';

// Menjalankan restore session sebelum app utama ditampilkan.
final appBootstrapProvider = FutureProvider<void>((ref) async {
  await Future.wait([
    ref.read(authControllerProvider.notifier).restoreSession(),
    Future<void>.delayed(const Duration(milliseconds: 900)),
  ]);
});

// Root widget yang memasang theme, router, dan startup splash.
class RanahInsightApp extends ConsumerWidget {
  const RanahInsightApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final bootstrap = ref.watch(appBootstrapProvider);

    return MaterialApp.router(
      title: 'RANAHINSIGHT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        return bootstrap.when(
          data: (_) => child ?? const SizedBox.shrink(),
          loading: () => const AppStartupSplash(),
          error: (_, __) => child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
