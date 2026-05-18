import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/image_url.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_select_sheet.dart';
import '../../../core/widgets/destination_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/image_preview.dart';
import '../../../core/widgets/icon_metric_card.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../auth/data/auth_controller.dart';
import '../data/profile_models.dart';
import '../data/profile_repository.dart';

final favoritesProvider = FutureProvider<List<FavoriteDestination>>((ref) {
  return ref.read(profileRepositoryProvider).fetchFavorites();
});

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _queryController = TextEditingController();
  var _showFavorites = true;
  var _sort = 'recent';
  var _cityFilter = 'all';
  final _compareIds = <int>[];
  FavoriteDestination? _lastRemoved;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final favorites = ref.watch(favoritesProvider);

    if (!auth.isAuthenticated) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: EmptyState(
            title: 'Silakan masuk terlebih dahulu',
            message: 'Profil dan favorit tersedia setelah Anda masuk.',
            icon: LucideIcons.shieldCheck,
            action: AppButton(
              label: 'Masuk',
              icon: LucideIcons.logIn,
              onPressed: () => context.push('/login'),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ProfileHeader(
                name: auth.user?.name ?? 'Profil Saya',
                email: auth.user?.email ?? '',
                avatar: auth.user?.profilePicture,
              ),
              const SizedBox(height: 18),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Profil')),
                  ButtonSegment(value: true, label: Text('Favorit')),
                ],
                selected: {_showFavorites},
                onSelectionChanged: (value) =>
                    setState(() => _showFavorites = value.first),
              ),
              const SizedBox(height: 18),
              if (!_showFavorites)
                _ProfileForm()
              else ...[
                favorites.when(
                  data: (items) => _FavoriteStats(items: items),
                  error: (_, __) => const SizedBox.shrink(),
                  loading: () => const LoadingSkeleton(height: 112),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _queryController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Cari favorit',
                    prefixIcon: Icon(LucideIcons.search),
                  ),
                ),
                const SizedBox(height: 12),
                favorites.when(
                  data: (items) {
                    final cities = [
                      'all',
                      ...items
                          .map((item) => item.destination.city)
                          .where((city) => city.isNotEmpty)
                          .toSet(),
                    ];
                    return Row(
                      children: [
                        Expanded(
                          child: _FilterAction(
                            icon: LucideIcons.mapPin,
                            label: _cityFilter == 'all'
                                ? 'Semua kota'
                                : _cityFilter,
                            onTap: () async {
                              final value = await showAppSelectSheet<String>(
                                context: context,
                                title: 'Filter kota favorit',
                                selectedValue: _cityFilter,
                                options: [
                                  for (final city in cities)
                                    SelectOption(
                                      value: city,
                                      label:
                                          city == 'all' ? 'Semua kota' : city,
                                      icon: LucideIcons.mapPin,
                                    ),
                                ],
                              );
                              if (value != null) {
                                setState(() => _cityFilter = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FilterAction(
                            icon: LucideIcons.arrowDownWideNarrow,
                            label: _sortLabel(_sort),
                            onTap: _pickSort,
                          ),
                        ),
                      ],
                    );
                  },
                  error: (_, __) => _FilterAction(
                    icon: LucideIcons.arrowDownWideNarrow,
                    label: _sortLabel(_sort),
                    onTap: _pickSort,
                  ),
                  loading: () => const LoadingSkeleton(height: 54),
                ),
                const SizedBox(height: 16),
                favorites.when(
                  data: (items) {
                    final filtered = _filterFavorites(items);
                    if (filtered.isEmpty) {
                      return const EmptyState(
                        title: 'Belum ada favorit',
                        message: 'Simpan destinasi dari halaman detail.',
                        icon: LucideIcons.heart,
                      );
                    }
                    return Column(
                      children: [
                        for (final favorite in filtered) ...[
                          _FavoriteCard(
                            favorite: favorite,
                            selected: _compareIds.contains(
                              favorite.destination.id,
                            ),
                            onCompare: () =>
                                _toggleCompare(favorite.destination.id),
                            onRemove: () => _removeFavorite(favorite),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 90),
                      ],
                    );
                  },
                  error: (error, _) => EmptyState(
                    title: 'Favorit gagal dimuat',
                    message: error.toString(),
                    action: AppButton(
                      label: 'Muat ulang',
                      icon: LucideIcons.refreshCcw,
                      onPressed: () => ref.invalidate(favoritesProvider),
                    ),
                  ),
                  loading: () => const LoadingSkeleton(height: 300),
                ),
              ],
            ],
          ),
          if (_compareIds.length >= 2)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _CompareTray(ids: _compareIds.take(2).toList()),
            ),
        ],
      ),
    );
  }

  List<FavoriteDestination> _filterFavorites(List<FavoriteDestination> items) {
    final query = _queryController.text.trim().toLowerCase();
    final filtered = items.where((favorite) {
      final destination = favorite.destination;
      final text =
          '${destination.name} ${destination.city} ${destination.province ?? ''}'
              .toLowerCase();
      final matchesQuery = query.isEmpty || text.contains(query);
      final matchesCity =
          _cityFilter == 'all' || destination.city == _cityFilter;
      return matchesQuery && matchesCity;
    }).toList();

    filtered.sort((a, b) {
      if (_sort == 'score') {
        return (b.destination.recommendationScore ?? 0).compareTo(
          a.destination.recommendationScore ?? 0,
        );
      }
      if (_sort == 'rating') {
        return (b.destination.googleRating ?? 0).compareTo(
          a.destination.googleRating ?? 0,
        );
      }
      if (_sort == 'name') {
        return a.destination.name.compareTo(b.destination.name);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return filtered;
  }

  void _toggleCompare(int id) {
    setState(() {
      if (_compareIds.contains(id)) {
        _compareIds.remove(id);
      } else {
        if (_compareIds.length >= 2) {
          _compareIds.removeAt(0);
        }
        _compareIds.add(id);
      }
    });
  }

  Future<void> _pickSort() async {
    final value = await showAppSelectSheet<String>(
      context: context,
      title: 'Urutkan favorit',
      selectedValue: _sort,
      options: const [
        SelectOption(
            value: 'recent', label: 'Terbaru', icon: LucideIcons.clock),
        SelectOption(
            value: 'score', label: 'Skor vibe', icon: LucideIcons.sparkles),
        SelectOption(value: 'rating', label: 'Rating', icon: LucideIcons.star),
        SelectOption(
            value: 'name', label: 'Nama A-Z', icon: LucideIcons.arrowDownAZ),
      ],
    );
    if (value != null) setState(() => _sort = value);
  }

  String _sortLabel(String value) {
    return switch (value) {
      'score' => 'Skor vibe',
      'rating' => 'Rating',
      'name' => 'Nama A-Z',
      _ => 'Terbaru',
    };
  }

  Future<void> _removeFavorite(FavoriteDestination favorite) async {
    _lastRemoved = favorite;
    await ref
        .read(profileRepositoryProvider)
        .removeFavorite(favorite.destination.id);
    ref.invalidate(favoritesProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${favorite.destination.name} dihapus dari favorit'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final removed = _lastRemoved;
            if (removed == null) return;
            await ref
                .read(profileRepositoryProvider)
                .addFavorite(removed.destination.id);
            ref.invalidate(favoritesProvider);
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    this.avatar,
  });

  final String name;
  final String email;
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = resolveImageUrl(avatar);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFD0BA)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: GestureDetector(
              onTap: avatarUrl.isEmpty
                  ? null
                  : () => showImagePreview(
                        context,
                        imageUrl: avatarUrl,
                        title: 'Foto profile saat ini',
                      ),
              child: AppCachedImage(
                imageUrl: avatarUrl,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Travel profile', style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle,
                ),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _FavoriteStats extends StatelessWidget {
  const _FavoriteStats({required this.items});

  final List<FavoriteDestination> items;

  @override
  Widget build(BuildContext context) {
    final topCity = _topCity(items);
    final scored = items.where((item) {
      return (item.destination.recommendationScore ?? 0) > 0;
    }).toList();
    final averageScore = scored.isEmpty
        ? null
        : scored.fold<num>(
              0,
              (sum, item) => sum + (item.destination.recommendationScore ?? 0),
            ) /
            scored.length;
    final rated = items.where((item) {
      return (item.destination.googleRating ?? 0) > 0;
    }).toList();
    final averageRating = rated.isEmpty
        ? null
        : rated.fold<num>(
              0,
              (sum, item) => sum + (item.destination.googleRating ?? 0),
            ) /
            rated.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          icon: LucideIcons.heart,
          title: 'Ringkasan favorit',
          subtitle: 'Pola destinasi yang paling sering Anda simpan.',
        ),
        const SizedBox(height: 12),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
          ),
          children: [
            IconMetricCard(
              label: 'Favorit',
              value: items.length.toString(),
              icon: LucideIcons.heart,
            ),
            IconMetricCard(
              label: 'Kota utama',
              value: topCity,
              icon: LucideIcons.mapPin,
              color: AppColors.secondary,
            ),
            IconMetricCard(
              label: 'Skor vibe',
              value: scoreLabel(averageScore),
              icon: LucideIcons.sparkles,
              color: AppColors.primary,
            ),
            IconMetricCard(
              label: 'Rating rata-rata',
              value: ratingLabel(averageRating),
              icon: LucideIcons.star,
              color: AppColors.warning,
            ),
          ],
        ),
      ],
    );
  }

  String _topCity(List<FavoriteDestination> items) {
    final counts = <String, int>{};
    for (final item in items) {
      final city = item.destination.city;
      if (city.isNotEmpty) counts[city] = (counts[city] ?? 0) + 1;
    }
    if (counts.isEmpty) return '-';
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }
}

class _FilterAction extends StatelessWidget {
  const _FilterAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _saving = false;
  var _uploading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final avatarUrl = resolveImageUrl(user?.profilePicture);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Data profil', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: GestureDetector(
                    onTap: avatarUrl.isEmpty
                        ? null
                        : () => showImagePreview(
                              context,
                              imageUrl: avatarUrl,
                              title: 'Foto profile saat ini',
                            ),
                    child: AppCachedImage(
                      imageUrl: avatarUrl,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(user?.email ?? '-', style: AppTextStyles.body),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama',
                prefixIcon: Icon(LucideIcons.user),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(LucideIcons.mail),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password baru (opsional)',
                prefixIcon: Icon(LucideIcons.lock),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, style: AppTextStyles.body),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Simpan profil',
                    icon: LucideIcons.save,
                    isLoading: _saving,
                    onPressed: _saving ? null : _saveProfile,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: IconButton.filledTonal(
                    tooltip: 'Upload foto profil',
                    onPressed: _uploading ? null : _pickAvatar,
                    icon: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.camera),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Keluar',
              icon: LucideIcons.logOut,
              isSecondary: true,
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || email.isEmpty) {
      setState(() => _message = 'Nama dan email wajib diisi.');
      return;
    }

    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final user = await ref.read(profileRepositoryProvider).updateProfile(
            name: name,
            email: email,
            password: _passwordController.text.trim(),
          );
      ref.read(authControllerProvider.notifier).updateUser(user);
      _passwordController.clear();
      setState(() => _message = 'Profil berhasil diperbarui.');
    } catch (_) {
      setState(() => _message = 'Profil gagal diperbarui.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (image == null) return;

    setState(() {
      _uploading = true;
      _message = null;
    });
    try {
      final user =
          await ref.read(profileRepositoryProvider).uploadAvatar(image);
      ref.read(authControllerProvider.notifier).updateUser(user);
      setState(() => _message = 'Foto profil berhasil diperbarui.');
    } catch (_) {
      setState(() => _message = 'Upload foto profil gagal.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.favorite,
    required this.selected,
    required this.onCompare,
    required this.onRemove,
  });

  final FavoriteDestination favorite;
  final bool selected;
  final VoidCallback onCompare;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final destination = favorite.destination;
    return Column(
      children: [
        DestinationCard(
          destination: DestinationCardData(
            name: destination.name,
            slug: destination.slug,
            city: destination.city,
            imageUrl: destination.imageUrl,
            positiveRatio: destination.positiveRatio,
            score: destination.recommendationScore,
            topics: destination.topics.map((topic) => topic.name).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCompare,
                icon: Icon(
                  selected ? LucideIcons.check : LucideIcons.gitCompareArrows,
                ),
                label: Text(selected ? 'Dipilih' : 'Bandingkan'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onRemove,
              icon: const Icon(LucideIcons.trash2, color: AppColors.danger),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompareTray extends StatelessWidget {
  const _CompareTray({required this.ids});

  final List<int> ids;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD6C2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '2 destinasi siap dibandingkan',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          FilledButton(
            onPressed: () => context.go('/compare?d1=${ids[0]}&d2=${ids[1]}'),
            child: const Text('Compare'),
          ),
        ],
      ),
    );
  }
}
