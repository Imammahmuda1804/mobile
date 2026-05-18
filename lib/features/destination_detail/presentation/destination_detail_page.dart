import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/image_url.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/image_preview.dart';
import '../../../core/widgets/icon_metric_card.dart';
import '../../../core/widgets/info_pill.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../auth/data/auth_controller.dart';
import '../../search/data/search_models.dart';
import '../data/destination_models.dart';
import '../data/destination_repository.dart';

final destinationDetailProvider =
    FutureProvider.family<DestinationDetail, String>((ref, slug) {
  return ref.read(destinationRepositoryProvider).fetchBySlug(slug);
});

class DestinationDetailPage extends ConsumerStatefulWidget {
  const DestinationDetailPage({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<DestinationDetailPage> createState() =>
      _DestinationDetailPageState();
}

class _DestinationDetailPageState extends ConsumerState<DestinationDetailPage> {
  bool? _isFavorite;
  int? _favoriteCheckedFor;

  Future<void> _checkFavorite(DestinationDetail destination) async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated || _favoriteCheckedFor == destination.id) return;
    _favoriteCheckedFor = destination.id;

    try {
      final value = await ref
          .read(destinationRepositoryProvider)
          .checkFavorite(destination.id);
      if (mounted) setState(() => _isFavorite = value);
    } catch (_) {
      if (mounted) setState(() => _isFavorite = false);
    }
  }

  Future<void> _toggleFavorite(DestinationDetail destination) async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      context.push('/login');
      return;
    }

    final repository = ref.read(destinationRepositoryProvider);
    final current = _isFavorite ?? false;
    setState(() => _isFavorite = !current);
    try {
      current
          ? await repository.removeFavorite(destination.id)
          : await repository.addFavorite(destination.id);
    } catch (_) {
      setState(() => _isFavorite = current);
    }
  }

  Future<void> _openExternal(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(destinationDetailProvider(widget.slug));

    return Scaffold(
      body: detail.when(
        data: (destination) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _checkFavorite(destination),
          );
          return _DetailContent(
            destination: destination,
            isFavorite: _isFavorite,
            onFavorite: () => _toggleFavorite(destination),
            onMaps: () => _openExternal(destination.googleMapsUrl),
            onTrailer: () => _openExternal(destination.youtubeUrl),
          );
        },
        error: (error, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: EmptyState(
              title: 'Detail gagal dimuat',
              message: error.toString(),
              icon: LucideIcons.circleAlert,
            ),
          ),
        ),
        loading: () => const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: LoadingSkeleton(height: 520),
          ),
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.destination,
    required this.onFavorite,
    required this.onMaps,
    required this.onTrailer,
    this.isFavorite,
  });

  final DestinationDetail destination;
  final VoidCallback onFavorite;
  final VoidCallback onMaps;
  final VoidCallback onTrailer;
  final bool? isFavorite;

  @override
  Widget build(BuildContext context) {
    final gallery = [
      if (destination.imageUrl.isNotEmpty) destination.imageUrl,
      ...destination.images,
    ];

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 330,
          pinned: true,
          leading: IconButton.filledTonal(
            tooltip: 'Kembali',
            onPressed: () => context.pop(),
            icon: const Icon(LucideIcons.arrowLeft),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                AppCachedImage(
                  imageUrl: destination.imageUrl,
                  borderRadius: BorderRadius.zero,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC0F172A)],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 26,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final topic in destination.topics.take(3))
                            InfoPill(
                              label: topic.name,
                              icon: LucideIcons.sparkles,
                              background: Colors.white,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        destination.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 17,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${destination.city}, ${destination.province}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList.list(
            children: [
              _MetricGrid(destination: destination),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: destination.googleMapsUrl.isEmpty
                          ? 'Maps belum tersedia'
                          : 'Google Maps',
                      icon: LucideIcons.navigation,
                      onPressed:
                          destination.googleMapsUrl.isEmpty ? null : onMaps,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: IconButton.filledTonal(
                      tooltip: 'Simpan favorit',
                      onPressed: onFavorite,
                      icon: Icon(
                        LucideIcons.heart,
                        color: (isFavorite ?? false) ? Colors.red : null,
                      ),
                    ),
                  ),
                ],
              ),
              if (destination.youtubeUrl?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                AppButton(
                  label: 'Buka trailer destinasi',
                  icon: LucideIcons.play,
                  isSecondary: true,
                  onPressed: onTrailer,
                ),
              ],
              const SizedBox(height: 26),
              const AppSectionHeader(
                icon: LucideIcons.badgeCheck,
                title: 'Kenapa cocok dikunjungi',
                subtitle: 'Ringkasan keputusan dari rating, vibe, dan akses.',
              ),
              const SizedBox(height: 12),
              _DecisionCards(destination: destination),
              const SizedBox(height: 14),
              _ExpandableDescription(
                text: destination.description.isEmpty
                    ? 'Deskripsi destinasi belum tersedia.'
                    : destination.description,
              ),
              const SizedBox(height: 26),
              const AppSectionHeader(
                icon: LucideIcons.sparkles,
                title: 'Peta Topik',
                subtitle:
                    'Ketuk topik untuk melihat ulasan terkait dan baca arah sentimennya.',
              ),
              const SizedBox(height: 12),
              _TopicInsightSection(destination: destination),
              const SizedBox(height: 26),
              const AppSectionHeader(
                icon: LucideIcons.images,
                title: 'Galeri',
                subtitle: 'Foto singkat untuk membaca suasana lokasi.',
              ),
              const SizedBox(height: 12),
              if (gallery.isEmpty)
                const EmptyState(
                  title: 'Belum ada foto',
                  message: 'Foto tambahan untuk destinasi ini belum tersedia.',
                  icon: LucideIcons.image,
                )
              else
                _GallerySection(gallery: gallery),
              const SizedBox(height: 26),
              const AppSectionHeader(
                icon: LucideIcons.messagesSquare,
                title: 'Cerita wisatawan',
                subtitle:
                    'Ulasan singkat dari pengguna yang pernah berkunjung.',
              ),
              const SizedBox(height: 12),
              for (final review in destination.userReviews.take(5))
                _ReviewTile(review: review),
              if (destination.userReviews.isEmpty)
                const EmptyState(
                  title: 'Belum ada ulasan',
                  message: 'Jadilah yang pertama membagikan pengalaman.',
                  icon: LucideIcons.messageSquare,
                ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Tulis ulasan',
                icon: LucideIcons.star,
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => _ReviewForm(destinationId: destination.id),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.destination});

  final DestinationDetail destination;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact ? 2 : 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: compact ? 1.2 : .9,
          ),
          children: [
            IconMetricCard(
              label: 'Skor AI',
              value: scoreLabel(destination.recommendationScore),
              icon: LucideIcons.sparkles,
              color: AppColors.primary,
            ),
            IconMetricCard(
              label: 'Sentimen positif',
              value: percentLabel(destination.positiveRatio),
              icon: LucideIcons.thumbsUp,
              color: AppColors.success,
            ),
            IconMetricCard(
              label: 'Rating Google',
              value: ratingLabel(destination.googleRating),
              helper: destination.googleReviewCount == null
                  ? null
                  : '${destination.googleReviewCount!.round()} review',
              icon: LucideIcons.star,
              color: AppColors.warning,
            ),
            IconMetricCard(
              label: 'Rating ulasan terolah',
              value: ratingLabel(destination.scrapedAverageRating),
              helper: destination.scrapedReviewCount == null
                  ? null
                  : '${destination.scrapedReviewCount} ulasan',
              icon: LucideIcons.chartNoAxesColumn,
              color: AppColors.secondary,
            ),
            IconMetricCard(
              label: 'Rating RanahInsight',
              value: ratingLabel(destination.averageUserRating),
              helper: '${destination.totalUserReviews} ulasan user',
              icon: LucideIcons.usersRound,
              color: AppColors.primary,
            ),
            IconMetricCard(
              label: 'Review user',
              value: destination.totalUserReviews > 0
                  ? destination.totalUserReviews.toString()
                  : destination.userReviews.length.toString(),
              icon: LucideIcons.messageSquareText,
              color: AppColors.secondary,
            ),
          ],
        );
      },
    );
  }
}

class _DecisionCards extends StatelessWidget {
  const _DecisionCards({required this.destination});

  final DestinationDetail destination;

  @override
  Widget build(BuildContext context) {
    final topTopic = destination.topics.isEmpty
        ? 'Vibe belum terbaca'
        : destination.topics.first.name;
    final access = destination.googleMapsUrl.isEmpty
        ? 'Maps belum tersedia'
        : 'Akses lokasi tersedia';

    final items = [
      (LucideIcons.star, 'Rating trust', ratingLabel(destination.googleRating)),
      (LucideIcons.sparkles, 'Vibe dominan', topTopic),
      (
        LucideIcons.messageSquareText,
        'Social proof',
        '${destination.userReviews.length} cerita'
      ),
      (LucideIcons.navigation, 'Akses', access),
    ];

    return Column(
      children: [
        for (final item in items) ...[
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(item.$1, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        item.$3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.text});

  final String text;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 5,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: AppTextStyles.body,
        ),
        if (widget.text.length > 220)
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
                _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown),
            label: Text(_expanded ? 'Tampilkan ringkas' : 'Baca selengkapnya'),
          ),
      ],
    );
  }
}

class _TopicInsightSection extends StatefulWidget {
  const _TopicInsightSection({required this.destination});

  final DestinationDetail destination;

  @override
  State<_TopicInsightSection> createState() => _TopicInsightSectionState();
}

class _TopicInsightSectionState extends State<_TopicInsightSection> {
  var _filter = 'all';
  var _showAllTopics = false;

  void _setFilter(String value) {
    setState(() {
      _filter = value;
      _showAllTopics = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topics = widget.destination.topics.where((topic) {
      if (_filter == 'all') return true;
      return _topicTone(widget.destination.topicSentiments[topic.id]).key ==
          _filter;
    }).toList();
    final visibleTopics =
        _showAllTopics ? topics : topics.take(4).toList(growable: false);
    final hiddenCount = topics.length - visibleTopics.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TopicLegend(),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _TopicFilterChip(
                label: 'Semua',
                icon: LucideIcons.layers,
                selected: _filter == 'all',
                onTap: () => _setFilter('all'),
              ),
              _TopicFilterChip(
                label: 'Positif',
                icon: LucideIcons.thumbsUp,
                selected: _filter == 'positive',
                onTap: () => _setFilter('positive'),
              ),
              _TopicFilterChip(
                label: 'Seimbang',
                icon: LucideIcons.scale,
                selected: _filter == 'balanced',
                onTap: () => _setFilter('balanced'),
              ),
              _TopicFilterChip(
                label: 'Perlu dicek',
                icon: LucideIcons.triangleAlert,
                selected: _filter == 'negative',
                onTap: () => _setFilter('negative'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (topics.isEmpty)
          const EmptyState(
            title: 'Topik tidak ditemukan',
            message: 'Tidak ada topik dengan filter sentimen ini.',
            icon: LucideIcons.filterX,
          )
        else ...[
          for (final topic in visibleTopics) ...[
            _TopicInsightCard(
              topic: topic,
              breakdown: widget.destination.topicSentiments[topic.id],
              onTap: () => _showTopicReviews(
                context,
                destination: widget.destination,
                topic: topic,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (topics.length > 4)
            OutlinedButton.icon(
              onPressed: () => setState(() => _showAllTopics = !_showAllTopics),
              icon: Icon(
                _showAllTopics ? LucideIcons.chevronUp : LucideIcons.listPlus,
              ),
              label: Text(
                _showAllTopics
                    ? 'Tampilkan lebih sedikit'
                    : 'Lihat $hiddenCount topik lainnya',
              ),
            ),
        ],
      ],
    );
  }
}

class _TopicLegend extends StatelessWidget {
  const _TopicLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD0BA)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legenda sentimen topik',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoPill(
                label: 'Positif: mayoritas ulasan bernada baik',
                icon: LucideIcons.thumbsUp,
                color: AppColors.success,
              ),
              InfoPill(
                label: 'Seimbang: sentimen relatif campur',
                icon: LucideIcons.scale,
                color: AppColors.secondary,
              ),
              InfoPill(
                label: 'Perlu dicek: negatif lebih menonjol',
                icon: LucideIcons.triangleAlert,
                color: AppColors.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicFilterChip extends StatelessWidget {
  const _TopicFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        selectedColor: const Color(0xFFFFE8DC),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? const Color(0xFFFFB38F) : AppColors.border,
        ),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.text,
          fontWeight: FontWeight.w900,
        ),
        label: Text(label),
        avatar: Icon(
          icon,
          size: 16,
          color: selected ? AppColors.primary : AppColors.muted,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _TopicInsightCard extends StatelessWidget {
  const _TopicInsightCard({
    required this.topic,
    required this.onTap,
    this.breakdown,
  });

  final DestinationTopic topic;
  final TopicSentimentBreakdown? breakdown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = _topicTone(breakdown);
    final total = breakdown?.total ?? 0;
    final positive = breakdown?.positive ?? 0;
    final neutral = breakdown?.neutral ?? 0;
    final negative = breakdown?.negative ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tone.color.withValues(alpha: .35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tone.color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(tone.icon, color: tone.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        total == 0
                            ? 'Sentimen topik belum cukup data'
                            : '$total ulasan terkait topik ini',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
                InfoPill(
                  label: tone.label,
                  icon: tone.icon,
                  color: tone.color,
                ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Row(
                  children: [
                    _SentimentSegment(
                      count: positive,
                      total: total,
                      color: AppColors.success,
                    ),
                    _SentimentSegment(
                      count: neutral,
                      total: total,
                      color: AppColors.secondary,
                    ),
                    _SentimentSegment(
                      count: negative,
                      total: total,
                      color: AppColors.danger,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$positive positif • $neutral netral • $negative negatif',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SentimentSegment extends StatelessWidget {
  const _SentimentSegment({
    required this.count,
    required this.total,
    required this.color,
  });

  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: count == 0 ? 1 : count,
      child: Container(
        height: 10,
        color: count == 0 ? color.withValues(alpha: .15) : color,
      ),
    );
  }
}

({String key, String label, IconData icon, Color color}) _topicTone(
  TopicSentimentBreakdown? breakdown,
) {
  if (breakdown == null || breakdown.total == 0) {
    return (
      key: 'balanced',
      label: 'Belum cukup data',
      icon: LucideIcons.circleHelp,
      color: AppColors.muted,
    );
  }

  final values = [breakdown.positive, breakdown.neutral, breakdown.negative]
    ..sort();
  final diff = values.last - values[values.length - 2];
  if (diff <= 1) {
    return (
      key: 'balanced',
      label: 'Seimbang',
      icon: LucideIcons.scale,
      color: AppColors.secondary,
    );
  }
  if (breakdown.negative > breakdown.positive &&
      breakdown.negative > breakdown.neutral) {
    return (
      key: 'negative',
      label: 'Perlu dicek',
      icon: LucideIcons.triangleAlert,
      color: AppColors.danger,
    );
  }
  if (breakdown.positive >= breakdown.neutral) {
    return (
      key: 'positive',
      label: 'Positif',
      icon: LucideIcons.thumbsUp,
      color: AppColors.success,
    );
  }
  return (
    key: 'balanced',
    label: 'Seimbang',
    icon: LucideIcons.scale,
    color: AppColors.secondary,
  );
}

class _GallerySection extends StatefulWidget {
  const _GallerySection({required this.gallery});

  final List<String> gallery;

  @override
  State<_GallerySection> createState() => _GallerySectionState();
}

class _GallerySectionState extends State<_GallerySection> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final items = widget.gallery;
    final selected = _selectedIndex.clamp(0, items.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => showImagePreview(
            context,
            imageUrl: items[selected],
            showHeader: false,
          ),
          child: Ink(
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x220F172A),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppCachedImage(
                    imageUrl: items[selected],
                    borderRadius: BorderRadius.circular(28),
                  ),
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
                    right: 14,
                    bottom: 14,
                    child: Row(
                      children: [
                        InfoPill(
                          label: 'Foto ${selected + 1}/${items.length}',
                          icon: LucideIcons.images,
                          background: Colors.white,
                        ),
                        const Spacer(),
                        const InfoPill(
                          label: 'Preview',
                          icon: LucideIcons.expand,
                          background: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final selectedThumb = index == selected;
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _selectedIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selectedThumb ? 92 : 76,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color:
                        selectedThumb ? const Color(0xFFFFE8DC) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selectedThumb
                          ? const Color(0xFFFFB38F)
                          : AppColors.border,
                      width: selectedThumb ? 2 : 1,
                    ),
                  ),
                  child: AppCachedImage(
                    imageUrl: items[index],
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final UserReview review;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = resolveImageUrl(review.userAvatar);
    final reviewText = review.reviewText?.trim() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: avatarUrl.isEmpty
                  ? null
                  : () => showImagePreview(
                        context,
                        imageUrl: avatarUrl,
                        showHeader: false,
                      ),
              child: SizedBox(
                width: 44,
                height: 44,
                child: avatarUrl.isEmpty
                    ? CircleAvatar(
                        backgroundColor: const Color(0xFFFFE8DC),
                        child: Text(
                          review.userName.isEmpty ? 'P' : review.userName[0],
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    : AppCachedImage(
                        imageUrl: avatarUrl,
                        borderRadius: BorderRadius.circular(16),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Icon(
                          LucideIcons.star,
                          size: 14,
                          color: i <= review.rating
                              ? AppColors.warning
                              : AppColors.border,
                        ),
                      const SizedBox(width: 8),
                      Flexible(child: Text(dateLabel(review.createdAt))),
                    ],
                  ),
                  if (reviewText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      reviewText,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showTopicReviews(
  BuildContext context, {
  required DestinationDetail destination,
  required DestinationTopic topic,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TopicReviewsSheet(
      destinationId: destination.id,
      topic: topic,
    ),
  );
}

class _TopicReviewsSheet extends ConsumerStatefulWidget {
  const _TopicReviewsSheet({
    required this.destinationId,
    required this.topic,
  });

  final int destinationId;
  final DestinationTopic topic;

  @override
  ConsumerState<_TopicReviewsSheet> createState() => _TopicReviewsSheetState();
}

class _TopicReviewsSheetState extends ConsumerState<_TopicReviewsSheet> {
  late final Future<List<ScrapedTopicReview>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(destinationRepositoryProvider).fetchReviewsByTopic(
          destinationId: widget.destinationId,
          topicId: widget.topic.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * .78,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                icon: LucideIcons.messagesSquare,
                title: 'Ulasan topik ${widget.topic.name}',
                subtitle:
                    'Cuplikan ulasan wisatawan yang berkaitan dengan topik ini.',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<ScrapedTopicReview>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LoadingSkeleton(height: 260);
                    }
                    if (snapshot.hasError) {
                      return EmptyState(
                        title: 'Ulasan topik gagal dimuat',
                        message: snapshot.error.toString(),
                        icon: LucideIcons.circleAlert,
                      );
                    }
                    final reviews = snapshot.data ?? const [];
                    if (reviews.isEmpty) {
                      return const EmptyState(
                        title: 'Belum ada ulasan topik',
                        message:
                            'Topik ini belum memiliki ulasan yang bisa ditampilkan.',
                        icon: LucideIcons.messageSquare,
                      );
                    }
                    return ListView.separated(
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _TopicReviewTile(review: reviews[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicReviewTile extends StatelessWidget {
  const _TopicReviewTile({required this.review});

  final ScrapedTopicReview review;

  @override
  Widget build(BuildContext context) {
    final sentiment = review.sentiment?.toLowerCase() ?? '';
    final sentimentColor = switch (sentiment) {
      'positive' || 'positif' => AppColors.success,
      'negative' || 'negatif' => AppColors.danger,
      _ => AppColors.muted,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.userRound, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.reviewerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (sentiment.isNotEmpty)
                InfoPill(
                  label: sentiment,
                  icon: LucideIcons.sparkles,
                  color: sentimentColor,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  LucideIcons.star,
                  size: 14,
                  color: i <= (review.rating ?? 0).round()
                      ? AppColors.warning
                      : AppColors.border,
                ),
              const SizedBox(width: 8),
              Flexible(child: Text(dateLabel(review.reviewDate))),
              if (review.likesCount > 0) ...[
                const SizedBox(width: 8),
                const Icon(LucideIcons.thumbsUp, size: 14),
                const SizedBox(width: 3),
                Text(review.likesCount.toString()),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.reviewText.isEmpty
                ? 'Ulasan ini tidak memiliki teks.'
                : review.reviewText,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({required this.destinationId});

  final int destinationId;

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  final _controller = TextEditingController();
  var _rating = 5;
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      Navigator.of(context).pop();
      context.push('/login');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(destinationRepositoryProvider).submitReview(
            destinationId: widget.destinationId,
            rating: _rating,
            reviewText: _controller.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _error = 'Ulasan gagal dikirim. Coba lagi.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tulis ulasan', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 1; i <= 5; i++)
                  _RatingStarButton(
                    value: i,
                    selected: i <= _rating,
                    onTap: () => setState(() => _rating = i),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Rating $_rating dari 5',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Bagikan pengalaman Anda',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 14),
            AppButton(
              label: 'Kirim ulasan',
              icon: LucideIcons.send,
              isLoading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingStarButton extends StatelessWidget {
  const _RatingStarButton({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$value bintang',
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF7D6) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? const Color(0xFFF5C542) : AppColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x33F59E0B),
                      blurRadius: 14,
                      offset: Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              selected ? Icons.star_rounded : Icons.star_border_rounded,
              size: 32,
              color: selected ? AppColors.warning : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
