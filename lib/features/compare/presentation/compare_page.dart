import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

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

// Memuat daftar destinasi untuk picker compare.
final compareDestinationsProvider = FutureProvider((ref) {
  return ref.read(compareRepositoryProvider).fetchDestinations();
});

// Halaman compare mobile untuk memilih dua destinasi dan melihat hasil analitik.
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

  // Meminta hasil compare saat dua destinasi sudah dipilih.
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
            Icon(icon, color: AppColors.ai),
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
    final summary = result.summary ??
        '${winner.name} lebih kuat untuk dipilih berdasarkan skor rekomendasi, sentimen, dan rating.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCool,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.ai.withValues(alpha: .18)),
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
              Text(summary, style: AppTextStyles.body),
              if (result.bestFor.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final label in result.bestFor)
                      InfoPill(
                        label: label,
                        icon: LucideIcons.sparkles,
                        color: AppColors.ai,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _DestinationPanel(dest: first, tone: AppColors.explore),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DestinationPanel(dest: second, tone: AppColors.ai),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Faktor utama', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        _FactorCards(first: first, second: second),
        const SizedBox(height: 20),
        const Text('Yang unggul', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        _SignalCards(first: first, second: second, risk: false),
        const SizedBox(height: 20),
        const Text('Yang perlu diwaspadai', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        _SignalCards(first: first, second: second, risk: true),
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
                color: AppColors.positive),
            InfoPill(
                label: 'Netral',
                icon: LucideIcons.minus,
                color: AppColors.neutral),
            InfoPill(
                label: 'Negatif',
                icon: LucideIcons.triangleAlert,
                color: AppColors.negative),
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
              AppColors.positive,
            ),
            BarChartRodStackItem(
              dest.positive.toDouble(),
              (dest.positive + dest.neutral).toDouble(),
              AppColors.neutral,
            ),
            BarChartRodStackItem(
              (dest.positive + dest.neutral).toDouble(),
              (dest.positive + dest.neutral + dest.negative).toDouble(),
              AppColors.negative,
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
            color: AppColors.positive,
          ),
          _PanelMetric(
            icon: LucideIcons.star,
            label:
                'Rating ${ratingLabel(dest.userRating ?? dest.googleRating)}',
            color: AppColors.neutral,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (dest.slug != null)
                TextButton(
                  onPressed: () => context.push('/destination/${dest.slug}'),
                  child: const Text('Detail'),
                ),
              if (_mapsUri(dest) != null)
                TextButton.icon(
                  onPressed: () => _openMaps(dest),
                  icon: const Icon(LucideIcons.navigation, size: 16),
                  label: const Text('Maps'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FactorCards extends StatelessWidget {
  const _FactorCards({required this.first, required this.second});

  final ComparedDestination first;
  final ComparedDestination second;

  static const _labels = {
    'access': 'Akses',
    'cost_value': 'Biaya/value',
    'cleanliness': 'Kebersihan',
    'facilities': 'Fasilitas',
    'crowd': 'Keramaian',
    'view_activity': 'Pemandangan',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in _labels.entries) ...[
          _FactorRow(
            label: entry.value,
            firstName: first.name,
            secondName: second.name,
            firstValue: _factor(first, entry.key),
            secondValue: _factor(second, entry.key),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  num _factor(ComparedDestination dest, String key) {
    return dest.decisionFactors[key] ??
        (((dest.recommendationScore ?? 0.5) + (dest.positiveRatio ?? 0.5)) *
            50);
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({
    required this.label,
    required this.firstName,
    required this.secondName,
    required this.firstValue,
    required this.secondValue,
  });

  final String label;
  final String firstName;
  final String secondName;
  final num firstValue;
  final num secondValue;

  @override
  Widget build(BuildContext context) {
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _FactorBar(name: firstName, value: firstValue, color: AppColors.explore),
          const SizedBox(height: 8),
          _FactorBar(name: secondName, value: secondValue, color: AppColors.ai),
        ],
      ),
    );
  }
}

class _FactorBar extends StatelessWidget {
  const _FactorBar({
    required this.name,
    required this.value,
    required this.color,
  });

  final String name;
  final num value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = (value.clamp(4, 100) as num).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              value.round().toString(),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: width / 100,
            minHeight: 7,
            backgroundColor: AppColors.background,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SignalCards extends StatelessWidget {
  const _SignalCards({
    required this.first,
    required this.second,
    required this.risk,
  });

  final ComparedDestination first;
  final ComparedDestination second;
  final bool risk;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SignalCard(dest: first, risk: risk),
        const SizedBox(height: 10),
        _SignalCard(dest: second, risk: risk),
      ],
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.dest, required this.risk});

  final ComparedDestination dest;
  final bool risk;

  @override
  Widget build(BuildContext context) {
    final items = (risk ? dest.risks : dest.highlights).isNotEmpty
        ? (risk ? dest.risks : dest.highlights)
        : dest.topics.take(3).map((topic) => topic.name).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: risk ? AppColors.surfaceDanger : AppColors.surfaceSuccess,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: risk
              ? AppColors.negative.withValues(alpha: .2)
              : AppColors.positive.withValues(alpha: .2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dest.name, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              risk ? 'Risiko khusus belum terlihat.' : 'Highlight belum cukup.',
              style: AppTextStyles.body,
            )
          else
            for (final item in items.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      risk ? LucideIcons.triangleAlert : LucideIcons.circleCheck,
                      size: 16,
                      color: risk ? AppColors.negative : AppColors.positive,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontWeight: FontWeight.w800),
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

Uri? _mapsUri(ComparedDestination dest) {
  final url = dest.googleMapsUrl;
  if (url != null && url.isNotEmpty) return Uri.tryParse(url);
  if (dest.latitude != null && dest.longitude != null) {
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${dest.latitude},${dest.longitude}',
    );
  }
  return null;
}

Future<void> _openMaps(ComparedDestination dest) async {
  final uri = _mapsUri(dest);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
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
