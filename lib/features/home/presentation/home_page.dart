import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/destination_card.dart';
import '../../../core/widgets/info_pill.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../search/data/search_models.dart';
import '../data/home_repository.dart';

// Memuat destinasi rekomendasi untuk home.
final homeTrendingProvider = FutureProvider((ref) {
  return ref.read(homeRepositoryProvider).fetchTrending();
});

class _HeroImageFallback extends StatelessWidget {
  const _HeroImageFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF2D82B5),
            Color(0xFFFF7B54),
          ],
        ),
      ),
    );
  }
}

// Halaman home mobile dengan hero, prompt, insight, dan rekomendasi.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch([String? prompt]) {
    final query = (prompt ?? _searchController.text).trim();
    if (query.isEmpty) return;
    context.go('/search?q=${Uri.encodeComponent(query)}');
  }

  @override
  Widget build(BuildContext context) {
    final trending = ref.watch(homeTrendingProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _HeroLanding(
            controller: _searchController,
            onSearch: _startSearch,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          sliver: SliverList.list(
            children: [
              const AppSectionHeader(
                icon: LucideIcons.radar,
                title: 'Trip signal',
                subtitle:
                    'Tiga sinyal utama untuk membaca destinasi tanpa membuka banyak ulasan.',
              ),
              const SizedBox(height: 14),
              const _SignalCards(),
              const SizedBox(height: 24),
              const _InsightPanel(),
              const SizedBox(height: 24),
              const _BentoActionGrid(),
              const SizedBox(height: 28),
              const AppSectionHeader(
                icon: LucideIcons.flame,
                title: 'Rekomendasi pilihan',
                subtitle:
                    'Destinasi dengan skor, sentimen, dan topik yang kuat.',
              ),
              const SizedBox(height: 14),
              trending.when(
                data: (items) => _RecommendationSection(items: items),
                error: (_, __) => const _RecommendationError(),
                loading: () => const Column(
                  children: [
                    LoadingSkeleton(height: 260),
                    SizedBox(height: 16),
                    LoadingSkeleton(height: 260),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroLanding extends StatelessWidget {
  const _HeroLanding({
    required this.controller,
    required this.onSearch,
  });

  final TextEditingController controller;
  final void Function([String? prompt]) onSearch;

  @override
  Widget build(BuildContext context) {
    final prompts = [
      (LucideIcons.waves, 'Pantai tenang'),
      (LucideIcons.utensils, 'Kuliner lokal'),
      (LucideIcons.landmark, 'Wisata budaya'),
      (LucideIcons.usersRound, 'Tempat keluarga'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/auth-bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _HeroImageFallback(),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x99111927),
                      Color(0xC5111927),
                      Color(0xFF111927),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppLogo(size: 34, textColor: Colors.white),
                  const SizedBox(height: 26),
                  const InfoPill(
                    label: 'AI Tourism Intelligence',
                    icon: LucideIcons.sparkles,
                    color: AppColors.ai,
                    background: Colors.white,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pilih destinasi dari rasa perjalanan yang Anda cari',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 39,
                      height: .98,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'RANAHINSIGHT membaca pola ulasan, memetakan vibe, dan mengarahkan Anda ke destinasi Sumatera Barat yang paling cocok.',
                    style: TextStyle(
                      color: Color(0xFFE2E8F0),
                      height: 1.55,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _HeroSearchBar(controller: controller, onSearch: onSearch),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final prompt in prompts)
                        ActionChip(
                          avatar: Icon(prompt.$1, size: 16),
                          label: Text(prompt.$2),
                          onPressed: () => onSearch(prompt.$2),
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Mulai eksplorasi',
                          icon: LucideIcons.search,
                          onPressed: onSearch,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 58,
                        height: 54,
                        child: IconButton.filledTonal(
                          tooltip: 'Bandingkan destinasi',
                          onPressed: () => context.go('/compare'),
                          icon: const Icon(LucideIcons.gitCompareArrows),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _HeroSignalLine(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSearchBar extends StatelessWidget {
  const _HeroSearchBar({
    required this.controller,
    required this.onSearch,
  });

  final TextEditingController controller;
  final void Function([String? prompt]) onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x33FFFFFF), width: 2),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.compass, color: AppColors.explore),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSearch(),
              decoration: const InputDecoration(
                hintText: 'Coba: keluarga dan alam',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton.filled(
            onPressed: onSearch,
            icon: const Icon(LucideIcons.arrowRight),
          ),
        ],
      ),
    );
  }
}

class _HeroSignalLine extends StatelessWidget {
  const _HeroSignalLine();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _HeroSignalPill(
          icon: LucideIcons.sparkles,
          label: 'AI membaca ulasan',
        ),
        _HeroSignalPill(
          icon: LucideIcons.mapPinned,
          label: 'Fokus Sumatera Barat',
        ),
        _HeroSignalPill(
          icon: LucideIcons.gitCompareArrows,
          label: 'Bisa dibandingkan',
        ),
      ],
    );
  }
}

class _HeroSignalPill extends StatelessWidget {
  const _HeroSignalPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalCards extends StatelessWidget {
  const _SignalCards();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        LucideIcons.sparkles,
        'AI sentiment',
        'Membaca nada positif, netral, dan negatif dari ulasan.',
        AppColors.ai,
      ),
      (
        LucideIcons.chartBar,
        'Topic modelling',
        'Mengubah banyak komentar menjadi peta topik perjalanan.',
        AppColors.ai,
      ),
      (
        LucideIcons.mapPinned,
        'Fokus lokal',
        'Dibangun untuk eksplorasi destinasi Sumatera Barat.',
        AppColors.explore,
      ),
    ];

    return Column(
      children: [
        for (final item in items) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.$4.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(item.$1, color: item.$4),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(item.$3, style: AppTextStyles.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCool,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.ai.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            icon: LucideIcons.brainCircuit,
            title: 'Baca pola ulasan',
            subtitle: 'Rasa perjalanan diringkas menjadi sinyal keputusan.',
          ),
          const SizedBox(height: 18),
          const _SentimentMeter(
            label: 'Positif',
            value: 'Kuat',
            width: .82,
            color: AppColors.positive,
          ),
          const SizedBox(height: 14),
          const _SentimentMeter(
            label: 'Netral',
            value: 'Seimbang',
            width: .48,
            color: AppColors.ai,
          ),
          const SizedBox(height: 14),
          const _SentimentMeter(
            label: 'Perlu dicek',
            value: 'Rendah',
            width: .28,
            color: AppColors.muted,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              InfoPill(label: 'Budaya', icon: LucideIcons.landmark),
              InfoPill(label: 'Alam', icon: LucideIcons.leaf),
              InfoPill(label: 'Kuliner', icon: LucideIcons.utensils),
              InfoPill(label: 'Keluarga', icon: LucideIcons.usersRound),
            ],
          ),
        ],
      ),
    );
  }
}

class _SentimentMeter extends StatelessWidget {
  const _SentimentMeter({
    required this.label,
    required this.value,
    required this.width,
    required this.color,
  });

  final String label;
  final String value;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: width,
            backgroundColor: Colors.white,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _BentoActionGrid extends StatelessWidget {
  const _BentoActionGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BentoCard(
          icon: LucideIcons.compass,
          title: 'Temukan destinasi yang cocok',
          body:
              'Mulai dari mood perjalanan, lalu biarkan sistem membaca destinasi yang paling relevan.',
          color: const Color(0xFF111927),
          foreground: Colors.white,
          action: AppButton(
            label: 'Cari sekarang',
            icon: LucideIcons.search,
            onPressed: () => context.go('/search'),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniBentoCard(
                icon: LucideIcons.gitCompareArrows,
                title: 'Bandingkan vibe',
                color: AppColors.explore,
                onTap: () => context.go('/compare'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniBentoCard(
                icon: LucideIcons.heart,
                title: 'Simpan pilihan',
                color: AppColors.ai,
                onTap: () => context.go('/profile'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.foreground,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Color foreground;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.explore, size: 32),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              color: foreground,
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              color: foreground.withValues(alpha: .72),
              height: 1.55,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          action,
        ],
      ),
    );
  }
}

class _MiniBentoCard extends StatelessWidget {
  const _MiniBentoCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Ink(
        height: 154,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({required this.items});

  final List<DestinationSummary> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _RecommendationError();
    }

    return Column(
      children: [
        _FeaturedDestination(item: items.first),
        const SizedBox(height: 16),
        for (final item in items.skip(1).take(5)) ...[
          DestinationCard(
            destination: DestinationCardData(
              name: item.name,
              slug: item.slug,
              city: item.city,
              imageUrl: item.imageUrl,
              positiveRatio: item.positiveRatio,
              score: item.recommendationScore,
              googleRating: item.googleRating,
              topics: item.topics.map((topic) => topic.name).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _FeaturedDestination extends StatelessWidget {
  const _FeaturedDestination({required this.item});

  final DestinationSummary item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () => context.push('/destination/${item.slug}'),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.imageUrl.isEmpty
                        ? Image.asset(
                            'assets/images/media1.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _HeroImageFallback(),
                          )
                        : Image.network(item.imageUrl, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xAA0F172A)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      bottom: 14,
                      child: InfoPill(
                        label: 'Pilihan kuat',
                        icon: LucideIcons.flame,
                        background: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      InfoPill(label: item.city, icon: LucideIcons.mapPin),
                      InfoPill(
                        label:
                            'Skor ${item.recommendationScore == null ? 'N/A' : (item.recommendationScore! * 100).round()}',
                        icon: LucideIcons.sparkles,
                        color: AppColors.ai,
                      ),
                    ],
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

class _RecommendationError extends StatelessWidget {
  const _RecommendationError();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.wifiOff, color: AppColors.explore),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Rekomendasi belum bisa dimuat. Periksa koneksi API lalu coba lagi.',
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
