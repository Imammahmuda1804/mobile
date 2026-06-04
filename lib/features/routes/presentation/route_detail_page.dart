import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/config/env.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../auth/data/auth_controller.dart';
import '../data/route_models.dart';
import '../data/routes_repository.dart';
import 'routes_page.dart';

final routeDetailProvider =
    FutureProvider.family<TravelRoute, String>((ref, slug) {
  return ref.read(routesRepositoryProvider).fetchByShareSlug(slug);
});

class RouteDetailPage extends ConsumerWidget {
  const RouteDetailPage({required this.shareSlug, super.key});

  final String shareSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(routeDetailProvider(shareSlug));
    final auth = ref.watch(authControllerProvider);
    final savedRoutes = ref.watch(savedRoutesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Detail rute')),
      body: route.when(
        data: (item) {
          final savedIds =
              savedRoutes.valueOrNull?.map((route) => route.id).toSet() ??
                  const <int>{};
          final isSaved = savedIds.contains(item.id);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(item.title, style: AppTextStyles.title),
              const SizedBox(height: 8),
              Text(
                item.description ??
                    '${item.stops.length} destinasi dalam rute.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: !auth.isAuthenticated
                    ? 'Login untuk simpan'
                    : isSaved
                        ? 'Tersimpan - hapus'
                        : 'Simpan rute',
                icon: isSaved ? LucideIcons.bookmarkCheck : LucideIcons.heart,
                isSecondary: isSaved,
                onPressed: () async {
                  if (!auth.isAuthenticated) {
                    context.push('/login');
                    return;
                  }
                  if (isSaved) {
                    await ref
                        .read(routesRepositoryProvider)
                        .unsaveRoute(item.id);
                    ref.invalidate(savedRoutesProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rute dihapus dari simpanan'),
                        ),
                      );
                    }
                    return;
                  }
                  await ref.read(routesRepositoryProvider).saveRoute(item.id);
                  ref.invalidate(savedRoutesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rute disimpan')),
                    );
                  }
                },
              ),
              if (item.visibility != 'private') ...[
                const SizedBox(height: 10),
                AppButton(
                  label: 'Salin link rute',
                  icon: LucideIcons.link,
                  isSecondary: true,
                  onPressed: () => _copyRouteLink(context, item),
                ),
                if (item.visibility == 'link_only') ...[
                  const SizedBox(height: 12),
                  _LinkOnlyInfoCard(route: item),
                ],
              ],
              if (isSaved) ...[
                const SizedBox(height: 10),
                AppButton(
                  label: 'Gunakan rute tersimpan',
                  icon: LucideIcons.mapPinned,
                  isSecondary: true,
                  onPressed: () => context.push('/routes/saved'),
                ),
              ],
              const SizedBox(height: 20),
              for (final stop in item.stops) ...[
                _StopTile(stop: stop),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
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

class _StopTile extends StatelessWidget {
  const _StopTile({required this.stop});

  final RouteStop stop;

  Future<void> _openMaps() async {
    final destination = stop.destination;
    final url = destination?.googleMapsUrl ??
        (destination?.latitude != null && destination?.longitude != null
            ? 'https://www.google.com/maps/search/?api=1&query=${destination!.latitude},${destination.longitude}'
            : null);
    if (url == null) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final destination = stop.destination;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: Text('${stop.stopOrder}'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination?.name ?? 'Destinasi',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${destination?.city ?? '-'} • ${stop.distanceToNextKm?.toStringAsFixed(1) ?? '-'} km ke stop berikutnya',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: _openMaps,
            icon: const Icon(LucideIcons.navigation),
          ),
        ],
      ),
    );
  }
}

class _LinkOnlyInfoCard extends StatelessWidget {
  const _LinkOnlyInfoCard({required this.route});

  final TravelRoute route;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCool,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.link, color: AppColors.ai),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rute link only',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rute ini tidak tampil di katalog publik. Orang lain hanya bisa membuka jika menerima link: ${_routeShareUrl(route)}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _copyRouteLink(BuildContext context, TravelRoute route) async {
  await Clipboard.setData(ClipboardData(text: _routeShareUrl(route)));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Link rute disalin')),
  );
}

String _routeShareUrl(TravelRoute route) {
  return '${Env.webBaseUrl}/routes/${route.shareSlug}';
}
