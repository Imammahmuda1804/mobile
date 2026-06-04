import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../auth/data/auth_controller.dart';
import '../data/route_models.dart';
import '../data/routes_repository.dart';

final publicRoutesProvider = FutureProvider<List<TravelRoute>>((ref) {
  return ref.read(routesRepositoryProvider).fetchPublicRoutes();
});

final myRoutesProvider = FutureProvider<List<TravelRoute>>((ref) {
  return ref.read(routesRepositoryProvider).fetchMyRoutes();
});

final savedRoutesProvider = FutureProvider<List<TravelRoute>>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) return const [];
  return ref.read(routesRepositoryProvider).fetchSavedRoutes();
});

final savedRouteProgressProvider =
    FutureProvider.family<SavedRouteProgress, int>((ref, routeId) {
  return ref.read(routesRepositoryProvider).fetchSavedRouteProgress(routeId);
});

class RoutesPage extends ConsumerWidget {
  const RoutesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = ref.watch(publicRoutesProvider);
    final savedRoutes = ref.watch(savedRoutesProvider);
    final savedIds =
        savedRoutes.valueOrNull?.map((route) => route.id).toSet() ??
            const <int>{};
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(publicRoutesProvider);
            ref.invalidate(savedRoutesProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _RoutesHero(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Buat',
                      icon: LucideIcons.plus,
                      onPressed: () => context.push('/routes/new'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'Disimpan',
                      icon: LucideIcons.bookmarkCheck,
                      isSecondary: true,
                      onPressed: () => context.push('/routes/saved'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Rute saya',
                icon: LucideIcons.folderKanban,
                isSecondary: true,
                onPressed: () => context.push('/routes/me'),
              ),
              const SizedBox(height: 20),
              routes.when(
                data: (items) => items.isEmpty
                    ? const EmptyState(
                        title: 'Belum ada rute publik',
                        message: 'Rute yang dibagikan akan muncul di sini.',
                        icon: LucideIcons.route,
                      )
                    : Column(
                        children: [
                          for (final route in items) ...[
                            _RouteCatalogCard(
                              route: route,
                              isSaved: savedIds.contains(route.id),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ],
                      ),
                error: (error, _) => EmptyState(
                  title: 'Rute gagal dimuat',
                  message: error.toString(),
                  icon: LucideIcons.circleAlert,
                ),
                loading: () => const LoadingSkeleton(height: 420),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyRoutesPage extends ConsumerWidget {
  const MyRoutesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = ref.watch(myRoutesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rute saya')),
      body: routes.when(
        data: (items) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppButton(
              label: 'Buat rute baru',
              icon: LucideIcons.plus,
              onPressed: () => context.push('/routes/new'),
            ),
            const SizedBox(height: 18),
            if (items.isEmpty)
              const EmptyState(
                title: 'Belum ada rute',
                message: 'Buat rute dari destinasi favorit Anda.',
                icon: LucideIcons.route,
              )
            else
              for (final route in items) ...[
                _RouteCard(route: route),
                const SizedBox(height: 14),
              ],
          ],
        ),
        error: (error, _) => EmptyState(
          title: 'Rute gagal dimuat',
          message: error.toString(),
          icon: LucideIcons.circleAlert,
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: LoadingSkeleton(height: 420),
        ),
      ),
    );
  }
}

class SavedRoutesPage extends ConsumerWidget {
  const SavedRoutesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = ref.watch(savedRoutesProvider);
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rute tersimpan')),
      body: !auth.isAuthenticated
          ? EmptyState(
              title: 'Login untuk melihat rute',
              message: 'Rute yang Anda simpan akan tersimpan lintas perangkat.',
              icon: LucideIcons.lockKeyhole,
              action: AppButton(
                label: 'Login',
                icon: LucideIcons.logIn,
                onPressed: () => context.push('/login'),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(savedRoutesProvider),
              child: routes.when(
                data: (items) => ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _SavedRoutesHero(total: items.length),
                    const SizedBox(height: 18),
                    if (items.isEmpty)
                      const EmptyState(
                        title: 'Belum ada rute tersimpan',
                        message:
                            'Simpan rute publik untuk mulai mencatat perjalanan.',
                        icon: LucideIcons.bookmark,
                      )
                    else
                      for (final route in items) ...[
                        _SavedRouteTrackerCard(route: route),
                        const SizedBox(height: 16),
                      ],
                  ],
                ),
                error: (error, _) => EmptyState(
                  title: 'Rute tersimpan gagal dimuat',
                  message: error.toString(),
                  icon: LucideIcons.circleAlert,
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: LoadingSkeleton(height: 420),
                ),
              ),
            ),
    );
  }
}

class _RoutesHero extends StatelessWidget {
  const _RoutesHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFD3C1)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.route, color: AppColors.primary),
          SizedBox(height: 12),
          Text('Rute wisata siap pakai', style: AppTextStyles.title),
          SizedBox(height: 8),
          Text(
            'Simpan route publik atau buat itinerary pribadi dari destinasi favorit.',
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class _SavedRoutesHero extends StatelessWidget {
  const _SavedRoutesHero({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCool,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.ai,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.mapPinned, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$total rute tersimpan', style: AppTextStyles.title),
                const SizedBox(height: 4),
                const Text(
                  'Tandai stop yang sudah dikunjungi dan lihat tujuan berikutnya.',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCatalogCard extends StatelessWidget {
  const _RouteCatalogCard({required this.route, required this.isSaved});

  final TravelRoute route;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    final firstImage = route.stops.isNotEmpty
        ? route.stops.first.destination?.imageUrl ?? ''
        : '';
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push('/route/${route.shareSlug}'),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AppCachedImage(
                    imageUrl: firstImage,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                  ),
                ),
                if (isSaved)
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: _SavedBadge(),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${route.stops.length} stop - ${route.totalDistanceKm?.toStringAsFixed(1) ?? '-'} km',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800,
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

class _SavedBadge extends StatelessWidget {
  const _SavedBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSuccess,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.bookmarkCheck,
              size: 14,
              color: AppColors.success,
            ),
            SizedBox(width: 5),
            Text(
              'Tersimpan',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedRouteTrackerCard extends ConsumerWidget {
  const _SavedRouteTrackerCard({required this.route});

  final TravelRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(savedRouteProgressProvider(route.id));
    final firstImage = route.stops.isNotEmpty
        ? route.stops.first.destination?.imageUrl ?? ''
        : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 8,
                child: AppCachedImage(
                  imageUrl: firstImage,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        LucideIcons.bookmarkCheck,
                        size: 14,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Rute tersimpan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: progress.when(
              data: (item) => _SavedRouteTrackerContent(
                route: route,
                progress: item,
              ),
              error: (error, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route.title, style: AppTextStyles.title),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              loading: () => const LoadingSkeleton(height: 220),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedRouteTrackerContent extends ConsumerWidget {
  const _SavedRouteTrackerContent({
    required this.route,
    required this.progress,
  });

  final TravelRoute route;
  final SavedRouteProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitedIds = progress.visitedStopIds;
    final totalStops = route.stops.length;
    final visitedCount =
        route.stops.where((stop) => visitedIds.contains(stop.id)).length;
    final nextStop = _nextPendingStop(route.stops, visitedIds);
    final ratio = totalStops == 0 ? 0.0 : visitedCount / totalStops;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route.title, style: AppTextStyles.title),
                  const SizedBox(height: 6),
                  Text(
                    nextStop == null
                        ? 'Semua stop sudah dikunjungi.'
                        : 'Selanjutnya: ${nextStop.destination?.name ?? 'Destinasi'}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Hapus dari simpanan',
              onPressed: () async {
                await ref.read(routesRepositoryProvider).unsaveRoute(route.id);
                ref.invalidate(savedRoutesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rute dihapus dari simpanan')),
                  );
                }
              },
              icon: const Icon(LucideIcons.bookmarkX),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.success),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$visitedCount/$totalStops dikunjungi',
          style: const TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        for (final stop in route.stops) ...[
          _ProgressStopTile(
            routeId: route.id,
            stop: stop,
            isVisited: visitedIds.contains(stop.id),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        AppButton(
          label: 'Lihat detail rute',
          icon: LucideIcons.eye,
          isSecondary: true,
          onPressed: () => context.push('/route/${route.shareSlug}'),
        ),
      ],
    );
  }
}

class _ProgressStopTile extends ConsumerWidget {
  const _ProgressStopTile({
    required this.routeId,
    required this.stop,
    required this.isVisited,
  });

  final int routeId;
  final RouteStop stop;
  final bool isVisited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destination = stop.destination;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isVisited ? AppColors.surfaceSuccess : AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isVisited ? const Color(0xFFBBF7D0) : const Color(0xFFFFD3C1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    isVisited ? AppColors.success : AppColors.primary,
                foregroundColor: Colors.white,
                child: Icon(
                  isVisited ? LucideIcons.check : LucideIcons.mapPin,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination?.name ?? 'Destinasi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${destination?.city ?? '-'} - stop ${stop.stopOrder}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: stop.id == 0
                      ? null
                      : () async {
                          if (isVisited) {
                            await ref
                                .read(routesRepositoryProvider)
                                .resetStopProgress(
                                  routeId: routeId,
                                  routeStopId: stop.id,
                                );
                          } else {
                            await ref
                                .read(routesRepositoryProvider)
                                .markStopVisited(
                                  routeId: routeId,
                                  routeStopId: stop.id,
                                );
                          }
                          ref.invalidate(savedRouteProgressProvider(routeId));
                        },
                  icon: Icon(
                    isVisited ? LucideIcons.rotateCcw : LucideIcons.check,
                    size: 16,
                  ),
                  label: Text(isVisited ? 'Batal' : 'Dikunjungi'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Buka Maps',
                onPressed: () => _openStopMaps(stop),
                icon: const Icon(LucideIcons.navigation),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route});

  final TravelRoute route;

  @override
  Widget build(BuildContext context) {
    final firstImage = route.stops.isNotEmpty
        ? route.stops.first.destination?.imageUrl ?? ''
        : '';
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () => context.push('/route/${route.shareSlug}'),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: AppCachedImage(
                imageUrl: firstImage,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${route.stops.length} stop - ${route.totalDistanceKm?.toStringAsFixed(1) ?? '-'} km',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800,
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

RouteStop? _nextPendingStop(List<RouteStop> stops, Set<int> visitedIds) {
  for (final stop in stops) {
    if (!visitedIds.contains(stop.id)) return stop;
  }
  return null;
}

Future<void> _openStopMaps(RouteStop stop) async {
  final destination = stop.destination;
  final url = destination?.googleMapsUrl ??
      (destination?.latitude != null && destination?.longitude != null
          ? 'https://www.google.com/maps/search/?api=1&query=${destination!.latitude},${destination.longitude}'
          : null);
  if (url == null) return;
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
