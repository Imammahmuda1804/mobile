import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/info_pill.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/utils/formatters.dart';
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
              const SizedBox(height: 24),
              const _BentoActionGrid(),
              const SizedBox(height: 20),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 12),
                  leading: const Icon(
                    LucideIcons.brainCircuit,
                    color: AppColors.ai,
                  ),
                  title: const Text(
                    'Bagaimana rekomendasi bekerja',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Lihat sinyal sentimen dan topik yang digunakan.',
                    style: AppTextStyles.body,
                  ),
                  children: const [
                    _SignalCards(),
                    SizedBox(height: 14),
                    _InsightPanel(),
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
      (LucideIcons.usersRound, 'Tempat keluarga'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/sumbar-tourism-bg.jpg',
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
              padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Temukan perjalanan yang terasa tepat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      height: 1.03,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Cari destinasi Sumatera Barat melalui sentimen dan topik ulasan.',
                    style: TextStyle(
                      color: Color(0xFFE2E8F0),
                      height: 1.45,
                      fontWeight: FontWeight.w600,
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
        borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.$4.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(10),
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
                        style: const TextStyle(fontWeight: FontWeight.w700),
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
        borderRadius: BorderRadius.circular(12),
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
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111927),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                LucideIcons.mapPinned,
                color: AppColors.explore,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Lanjutkan perjalanan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Buka rute tersimpan, tandai lokasi yang sudah dikunjungi, lalu lanjut ke tujuan berikutnya.',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              /* Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.go('/routes/saved'),
                  icon: const Icon(LucideIcons.mapPinned, size: 18),
                  label: const Text('Rute tersimpan'),
                ),
              ), */
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Bandingkan destinasi',
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x55FFFFFF)),
                ),
                onPressed: () => context.go('/compare'),
                icon: const Icon(LucideIcons.gitCompareArrows),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Cari destinasi',
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x55FFFFFF)),
                ),
                onPressed: () => context.go('/search'),
                icon: const Icon(LucideIcons.search),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationSection extends StatefulWidget {
  const _RecommendationSection({required this.items});

  final List<DestinationSummary> items;

  @override
  State<_RecommendationSection> createState() => _RecommendationSectionState();
}

class _RecommendationSectionState extends State<_RecommendationSection> {
  late final PageController _controller;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: .88);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (widget.items.isEmpty) return;
    final targetIndex = index.clamp(0, widget.items.length - 1).toInt();
    _controller.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const _RecommendationError();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 430,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (value) => setState(() => _activeIndex = value),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final isActive = index == _activeIndex;
              return AnimatedScale(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                scale: isActive ? 1 : .98,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == widget.items.length - 1 ? 0 : 12,
                  ),
                  child: _TimecardDestination(
                    item: item,
                    index: index,
                    total: widget.items.length,
                    active: isActive,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: (_activeIndex + 1) / widget.items.length,
                  backgroundColor: AppColors.surfaceWarm,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.explore),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(_activeIndex + 1).toString().padLeft(2, '0')}/${widget.items.length.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: 'Destinasi sebelumnya',
              onPressed:
                  _activeIndex == 0 ? null : () => _goTo(_activeIndex - 1),
              icon: const Icon(LucideIcons.chevronLeft),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Destinasi berikutnya',
              onPressed: _activeIndex >= widget.items.length - 1
                  ? null
                  : () => _goTo(_activeIndex + 1),
              icon: const Icon(LucideIcons.chevronRight),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimecardDestination extends StatelessWidget {
  const _TimecardDestination({
    required this.item,
    required this.index,
    required this.total,
    required this.active,
  });

  final DestinationSummary item;
  final int index;
  final int total;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final description = item.description?.trim().isNotEmpty == true
        ? item.description!.trim()
        : 'Deskripsi destinasi belum tersedia.';

    return GestureDetector(
      onTap: () => context.push('/destination/${item.slug}'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Color(active ? 0x33111927 : 0x1A111927),
              blurRadius: active ? 28 : 16,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              item.imageUrl.isEmpty
                  ? Image.asset(
                      'assets/images/media1.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _HeroImageFallback(),
                    )
                  : Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _HeroImageFallback(),
                    ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x22111927),
                      Color(0x77111927),
                      Color(0xF2111927),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: 18,
                right: 18,
                child: Row(
                  children: [
                    InfoPill(
                      label:
                          '${(index + 1).toString().padLeft(2, '0')}/${total.toString().padLeft(2, '0')}',
                      icon: LucideIcons.flame,
                      background: Colors.white,
                      color: AppColors.explore,
                    ),
                    const Spacer(),
                    InfoPill(
                      label: ratingLabel(item.googleRating),
                      icon: LucideIcons.star,
                      background: Colors.white,
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.city.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFD6C8),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 31,
                        height: .96,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        InfoPill(
                          label: 'Positif ${percentLabel(item.positiveRatio)}',
                          icon: LucideIcons.trendingUp,
                          background: AppColors.surfaceSuccess,
                          color: AppColors.success,
                        ),
                        InfoPill(
                          label: 'Skor ${scoreLabel(item.recommendationScore)}',
                          icon: LucideIcons.sparkles,
                          background: AppColors.surfaceCool,
                          color: AppColors.ai,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.text,
                                height: 1.35,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            LucideIcons.arrowRight,
                            color: AppColors.explore,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        borderRadius: BorderRadius.circular(16),
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
