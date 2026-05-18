import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_select_sheet.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_pill.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../data/compare_models.dart';
import '../data/compare_repository.dart';

final compareDestinationsProvider = FutureProvider((ref) {
  return ref.read(compareRepositoryProvider).fetchDestinations();
});

class ComparePage extends ConsumerStatefulWidget {
  const ComparePage({this.initialFirstId, this.initialSecondId, super.key});

  final int? initialFirstId;
  final int? initialSecondId;

  @override
  ConsumerState<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends ConsumerState<ComparePage> {
  int? _firstId;
  int? _secondId;
  var _loading = false;
  CompareResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firstId = widget.initialFirstId;
    _secondId = widget.initialSecondId;
    if (_firstId != null && _secondId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _compare());
    }
  }

  Future<void> _compare() async {
    if (_firstId == null || _secondId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref
          .read(compareRepositoryProvider)
          .compare(_firstId!, _secondId!);
      setState(() => _result = data);
    } on AppException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = ref.watch(compareDestinationsProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const AppSectionHeader(
            icon: LucideIcons.gitCompareArrows,
            title: 'Bandingkan Destinasi',
            subtitle:
                'Letakkan dua destinasi berdampingan untuk membaca skor, sentimen, rating, dan topik dominan.',
          ),
          const SizedBox(height: 18),
          destinations.when(
            data: (items) => Column(
              children: [
                _DestinationPickButton(
                  label: 'Destinasi A',
                  value: _firstId == null
                      ? 'Pilih destinasi pertama'
                      : items
                              .where((item) => item.id == _firstId)
                              .map((item) => item.name)
                              .firstOrNull ??
                          'Destinasi A',
                  icon: LucideIcons.mapPinned,
                  onTap: () => _pickDestination(items, true),
                ),
                const SizedBox(height: 10),
                _DestinationPickButton(
                  label: 'Destinasi B',
                  value: _secondId == null
                      ? 'Pilih destinasi kedua'
                      : items
                              .where((item) => item.id == _secondId)
                              .map((item) => item.name)
                              .firstOrNull ??
                          'Destinasi B',
                  icon: LucideIcons.flag,
                  onTap: () => _pickDestination(items, false),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Bandingkan',
                        icon: LucideIcons.gitCompareArrows,
                        isLoading: _loading,
                        onPressed: _compare,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Tukar destinasi',
                      onPressed: () {
                        setState(() {
                          final oldFirst = _firstId;
                          _firstId = _secondId;
                          _secondId = oldFirst;
                        });
                        _compare();
                      },
                      icon: const Icon(LucideIcons.arrowRightLeft),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Reset compare',
                      onPressed: () {
                        setState(() {
                          _firstId = null;
                          _secondId = null;
                          _result = null;
                          _error = null;
                        });
                      },
                      icon: const Icon(LucideIcons.rotateCcw),
                    ),
                  ],
                ),
              ],
            ),
            error: (_, __) => const EmptyState(
              title: 'Destinasi gagal dimuat',
              message: 'Periksa koneksi API dan coba lagi.',
            ),
            loading: () => const LoadingSkeleton(height: 160),
          ),
          const SizedBox(height: 22),
          if (_loading)
            const LoadingSkeleton(height: 420)
          else if (_error != null)
            EmptyState(
              title: 'Compare gagal',
              message: _error!,
              icon: LucideIcons.circleAlert,
            )
          else if (_result == null)
            const EmptyState(
              title: 'Mulai dari dua destinasi',
              message: 'Pilih dua destinasi untuk melihat hasil perbandingan.',
              icon: LucideIcons.chartBar,
            )
          else
            _CompareResultView(result: _result!),
        ],
      ),
    );
  }

  Future<void> _pickDestination(List<dynamic> items, bool first) async {
    final selected = await showAppSelectSheet<int>(
      context: context,
      title: first ? 'Pilih destinasi A' : 'Pilih destinasi B',
      selectedValue: first ? _firstId : _secondId,
      searchable: true,
      searchHint: 'Cari nama destinasi atau kota',
      options: [
        for (final item in items)
          SelectOption<int>(
            value: item.id as int,
            label: item.name as String,
            subtitle: item.city as String,
            icon: LucideIcons.mapPin,
          ),
      ],
    );
    if (selected == null) return;
    setState(() {
      if (first) {
        _firstId = selected;
      } else {
        _secondId = selected;
      }
    });
    if (_firstId != null && _secondId != null) _compare();
  }
}

class _DestinationPickButton extends StatelessWidget {
  const _DestinationPickButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronDown),
          ],
        ),
      ),
    );
  }
}

class _CompareResultView extends StatelessWidget {
  const _CompareResultView({required this.result});

  final CompareResult result;

  @override
  Widget build(BuildContext context) {
    final first = result.destination1;
    final second = result.destination2;
    final winner = result.winnerId == first.id ? first : second;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3EC),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFFFD6C2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rekomendasi keputusan', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Text(
                '${winner.name} lebih kuat untuk dipilih',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 8),
              Text(
                'Selisih skor ${(result.scoreDifference.abs() * 100).toStringAsFixed(0)} poin. Gunakan sentimen dan topik dominan untuk keputusan akhir.',
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _DestinationPanel(dest: first, tone: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DestinationPanel(dest: second, tone: AppColors.secondary),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Distribusi sentimen', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            InfoPill(
                label: 'Positif',
                icon: LucideIcons.thumbsUp,
                color: AppColors.success),
            InfoPill(
                label: 'Netral',
                icon: LucideIcons.minus,
                color: AppColors.muted),
            InfoPill(
                label: 'Negatif',
                icon: LucideIcons.triangleAlert,
                color: AppColors.danger),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              barGroups: [_barGroup(0, first), _barGroup(1, second)],
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(),
                rightTitles: AxisTitles(),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Topik dominan', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        for (final dest in [first, second]) _TopicList(dest: dest),
      ],
    );
  }

  BarChartGroupData _barGroup(int x, ComparedDestination dest) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: (dest.positive + dest.neutral + dest.negative).toDouble(),
          rodStackItems: [
            BarChartRodStackItem(
              0,
              dest.positive.toDouble(),
              AppColors.success,
            ),
            BarChartRodStackItem(
              dest.positive.toDouble(),
              (dest.positive + dest.neutral).toDouble(),
              AppColors.muted,
            ),
            BarChartRodStackItem(
              (dest.positive + dest.neutral).toDouble(),
              (dest.positive + dest.neutral + dest.negative).toDouble(),
              AppColors.danger,
            ),
          ],
          width: 38,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }
}

class _DestinationPanel extends StatelessWidget {
  const _DestinationPanel({required this.dest, required this.tone});

  final ComparedDestination dest;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dest.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _PanelMetric(
            icon: LucideIcons.sparkles,
            label: 'Skor ${scoreLabel(dest.recommendationScore)}',
            color: tone,
          ),
          _PanelMetric(
            icon: LucideIcons.thumbsUp,
            label: 'Positif ${percentLabel(dest.positiveRatio)}',
            color: AppColors.success,
          ),
          _PanelMetric(
            icon: LucideIcons.star,
            label:
                'Rating ${ratingLabel(dest.userRating ?? dest.googleRating)}',
            color: AppColors.warning,
          ),
          const SizedBox(height: 10),
          if (dest.slug != null)
            TextButton(
              onPressed: () => context.push('/destination/${dest.slug}'),
              child: const Text('Detail'),
            ),
        ],
      ),
    );
  }
}

class _PanelMetric extends StatelessWidget {
  const _PanelMetric({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicList extends StatelessWidget {
  const _TopicList({required this.dest});

  final ComparedDestination dest;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dest.name, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          for (final topic in dest.topics.take(5))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(topic.name),
              trailing: Text('${topic.totalReviews} ulasan'),
            ),
        ],
      ),
    );
  }
}
