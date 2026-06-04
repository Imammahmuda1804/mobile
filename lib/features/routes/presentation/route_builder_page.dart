import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ranahinsight_mobile/core/widgets/empty_state.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_select_sheet.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../search/data/search_models.dart';
import '../../search/data/search_repository.dart';
import '../data/routes_repository.dart';
import 'routes_page.dart';

final routeBuilderDestinationsProvider =
    FutureProvider<List<DestinationSummary>>((ref) {
  return ref.read(searchRepositoryProvider).searchKeyword(limit: 100);
});

class RouteBuilderPage extends ConsumerStatefulWidget {
  const RouteBuilderPage({this.initialDestinationId, super.key});

  final int? initialDestinationId;

  @override
  ConsumerState<RouteBuilderPage> createState() => _RouteBuilderPageState();
}

class _RouteBuilderPageState extends ConsumerState<RouteBuilderPage> {
  final _titleController = TextEditingController();
  final Set<int> _selectedIds = {};
  String _visibility = 'private';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initialId = widget.initialDestinationId;
    if (initialId != null) _selectedIds.add(initialId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty || _selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi judul dan pilih destinasi.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final route = await ref.read(routesRepositoryProvider).createRoute(
            title: _titleController.text.trim(),
            destinationIds: _selectedIds.toList(),
            visibility: _visibility,
          );
      ref.invalidate(myRoutesProvider);
      if (mounted) context.go('/route/${route.shareSlug}');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat rute: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = ref.watch(routeBuilderDestinationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Buat rute')),
      body: destinations.when(
        data: (items) {
          final selectedDestinations =
              items.where((item) => _selectedIds.contains(item.id)).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _RouteBuilderHero(),
              const SizedBox(height: 18),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul rute',
                  prefixIcon: Icon(LucideIcons.route),
                ),
              ),
              const SizedBox(height: 14),
              _SelectFieldButton(
                icon: LucideIcons.eye,
                label: 'Visibilitas',
                value: _visibilityLabel(_visibility),
                onTap: _selectVisibility,
              ),
              const SizedBox(height: 10),
              _VisibilityInfoCard(visibility: _visibility),
              const SizedBox(height: 14),
              _SelectFieldButton(
                icon: LucideIcons.mapPin,
                label: 'Destinasi',
                value: _selectedIds.isEmpty
                    ? 'Pilih destinasi'
                    : '${_selectedIds.length} destinasi dipilih',
                onTap: items.isEmpty ? null : () => _selectDestination(items),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const EmptyState(
                  title: 'Destinasi belum tersedia',
                  message:
                      'Pastikan backend aktif agar daftar destinasi bisa dipilih.',
                  icon: LucideIcons.mapPin,
                )
              else if (selectedDestinations.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFFFD0BA)),
                  ),
                  child: const Text(
                    'Pilih destinasi dari tombol di atas. Anda bisa menambahkan beberapa destinasi sebelum menyimpan.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800,
                      height: 1.45,
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SelectedRouteHeader(),
                    const SizedBox(height: 10),
                    for (final entry in selectedDestinations.indexed) ...[
                      _SelectedDestinationTile(
                        order: entry.$1 + 1,
                        title: entry.$2.name,
                        subtitle: entry.$2.city,
                        onRemove: () => setState(
                          () => _selectedIds.remove(entry.$2.id),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              const SizedBox(height: 20),
              AppButton(
                label: _saving ? 'Menyimpan...' : 'Simpan dan auto sort',
                icon: LucideIcons.sparkles,
                onPressed: _saving ? null : _save,
              ),
            ],
          );
        },
        error: (error, _) => EmptyState(
          title: 'Destinasi gagal dimuat',
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

  Future<void> _selectVisibility() async {
    final value = await showAppSelectSheet<String>(
      context: context,
      title: 'Pilih visibilitas',
      selectedValue: _visibility,
      options: const [
        SelectOption(
          value: 'private',
          label: 'Private',
          subtitle: 'Hanya terlihat oleh Anda',
          icon: LucideIcons.lock,
        ),
        SelectOption(
          value: 'public',
          label: 'Public',
          subtitle: 'Tampil di katalog rute publik',
          icon: LucideIcons.globe,
        ),
        SelectOption(
          value: 'link_only',
          label: 'Link only',
          subtitle: 'Bisa dibuka oleh orang yang punya tautan',
          icon: LucideIcons.link,
        ),
      ],
    );
    if (value == null) return;
    setState(() => _visibility = value);
  }

  Future<void> _selectDestination(List<DestinationSummary> items) async {
    final available =
        items.where((item) => !_selectedIds.contains(item.id)).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua destinasi sudah masuk rute.')),
      );
      return;
    }

    final value = await showAppSelectSheet<int>(
      context: context,
      title: 'Tambah destinasi',
      searchable: true,
      searchHint: 'Cari destinasi',
      options: [
        for (final item in available)
          SelectOption<int>(
            value: item.id,
            label: item.name,
            subtitle: item.city,
            icon: LucideIcons.mapPin,
          ),
      ],
    );
    if (value == null) return;
    setState(() => _selectedIds.add(value));
  }
}

String _visibilityLabel(String value) {
  return switch (value) {
    'public' => 'Public',
    'link_only' => 'Link only',
    _ => 'Private',
  };
}

class _RouteBuilderHero extends StatelessWidget {
  const _RouteBuilderHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD0BA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.explore,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.route, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rancang urutan wisata', style: AppTextStyles.title),
                SizedBox(height: 6),
                Text(
                  'Pilih destinasi, tentukan visibilitas, lalu sistem akan mengurutkan rute berdasarkan jarak.',
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

class _VisibilityInfoCard extends StatelessWidget {
  const _VisibilityInfoCard({required this.visibility});

  final String visibility;

  @override
  Widget build(BuildContext context) {
    final meta = switch (visibility) {
      'public' => (
          icon: LucideIcons.globe,
          title: 'Public',
          body: 'Rute tampil di katalog publik dan bisa disimpan user lain.',
          color: AppColors.surfaceSuccess,
          border: const Color(0xFFBBF7D0),
        ),
      'link_only' => (
          icon: LucideIcons.link,
          title: 'Link only',
          body:
              'Rute tidak tampil di katalog. Setelah dibuat, buka detail rute untuk menyalin link dan membagikannya.',
          color: AppColors.surfaceCool,
          border: const Color(0xFFBAE6FD),
        ),
      _ => (
          icon: LucideIcons.lock,
          title: 'Private',
          body: 'Rute hanya masuk ke daftar rute Anda dan tidak dibagikan.',
          color: AppColors.surfaceWarm,
          border: const Color(0xFFFFD0BA),
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: meta.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: meta.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(meta.icon, color: AppColors.ai, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  meta.body,
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

class _SelectedRouteHeader extends StatelessWidget {
  const _SelectedRouteHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(LucideIcons.listOrdered, size: 18, color: AppColors.explore),
        SizedBox(width: 8),
        Text(
          'Itinerary terpilih',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _SelectFieldButton extends StatelessWidget {
  const _SelectFieldButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 18, color: AppColors.explore),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronDown, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDestinationTile extends StatelessWidget {
  const _SelectedDestinationTile({
    required this.order,
    required this.title,
    required this.subtitle,
    required this.onRemove,
  });

  final int order;
  final String title;
  final String subtitle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.explore,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '$order',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(LucideIcons.x),
            color: AppColors.negative,
          ),
        ],
      ),
    );
  }
}
