import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_select_sheet.dart';
import '../../../core/widgets/destination_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_pill.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../auth/data/auth_controller.dart';
import '../data/search_models.dart';
import '../data/search_repository.dart';

final topicsProvider = FutureProvider<List<TopicFilter>>((ref) {
  return ref.read(searchRepositoryProvider).fetchTopics();
});

final citiesProvider = FutureProvider<List<String>>((ref) {
  return ref.read(searchRepositoryProvider).fetchCities();
});

final searchHistoryProvider = FutureProvider<List<String>>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) return const [];
  return ref.read(searchRepositoryProvider).fetchHistory();
});

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({this.initialQuery, super.key});

  final String? initialQuery;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _queryController = TextEditingController();
  var _semanticMode = false;
  var _loading = false;
  var _hasSearched = false;
  var _selectedCity = '';
  final _selectedTopics = <int>{};
  List<DestinationSummary> _results = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _queryController.text = widget.initialQuery ?? '';
    if (_queryController.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty && _selectedTopics.isEmpty && _selectedCity.isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
      _hasSearched = true;
      _error = null;
    });

    try {
      final repository = ref.read(searchRepositoryProvider);
      final results = _semanticMode && query.isNotEmpty
          ? await repository.searchSemantic(
              query: query,
              topicIds: _selectedTopics.toList(),
              city: _selectedCity,
            )
          : await repository.searchKeyword(
              query: query,
              topicIds: _selectedTopics.toList(),
              city: _selectedCity,
            );
      setState(() => _results = results);
    } on AppException catch (error) {
      setState(() {
        _results = [];
        _error = error.message;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    setState(() {
      _queryController.clear();
      _selectedTopics.clear();
      _selectedCity = '';
      _results = [];
      _hasSearched = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(topicsProvider);
    final cities = ref.watch(citiesProvider);
    final history = ref.watch(searchHistoryProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const AppSectionHeader(
            icon: LucideIcons.searchCheck,
            title: 'Cari destinasi',
            subtitle:
                'Pakai keyword atau semantic untuk menemukan vibe perjalanan.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _queryController,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Pantai tenang, wisata budaya...',
              prefixIcon: const Icon(LucideIcons.search),
              suffixIcon: IconButton(
                onPressed: _search,
                icon: const Icon(LucideIcons.arrowRight),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(LucideIcons.type),
                label: Text('Keyword'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(LucideIcons.brain),
                label: Text('Semantic'),
              ),
            ],
            selected: {_semanticMode},
            onSelectionChanged: (value) {
              setState(() => _semanticMode = value.first);
              if (_hasSearched) _search();
            },
          ),
          const SizedBox(height: 14),
          cities.when(
            data: (items) => _FilterButton(
              icon: LucideIcons.mapPin,
              label: _selectedCity.isEmpty ? 'Semua kota' : _selectedCity,
              onTap: () async {
                final value = await showAppSelectSheet<String>(
                  context: context,
                  title: 'Pilih kota',
                  selectedValue: _selectedCity,
                  searchable: true,
                  searchHint: 'Cari kota destinasi',
                  options: [
                    const SelectOption(
                      value: '',
                      label: 'Semua kota',
                      icon: LucideIcons.map,
                    ),
                    for (final city in items)
                      SelectOption(
                        value: city,
                        label: city,
                        icon: LucideIcons.mapPin,
                      ),
                  ],
                );
                if (value == null) return;
                setState(() => _selectedCity = value);
                _search();
              },
            ),
            error: (_, __) => const SizedBox.shrink(),
            loading: () => const LoadingSkeleton(height: 52),
          ),
          const SizedBox(height: 14),
          topics.when(
            data: (items) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final topic in items.take(12))
                  FilterChip(
                    label: Text(topic.name),
                    selected: _selectedTopics.contains(topic.id),
                    onSelected: (selected) {
                      setState(() {
                        selected
                            ? _selectedTopics.add(topic.id)
                            : _selectedTopics.remove(topic.id);
                      });
                      _search();
                    },
                  ),
              ],
            ),
            error: (_, __) => const SizedBox.shrink(),
            loading: () => const LoadingSkeleton(height: 56),
          ),
          const SizedBox(height: 16),
          history.when(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in items)
                        ActionChip(
                          avatar: const Icon(LucideIcons.history, size: 15),
                          label: Text(item),
                          onPressed: () {
                            _queryController.text = item;
                            _search();
                          },
                        ),
                    ],
                  ),
            error: (_, __) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
          if (history.valueOrNull?.isNotEmpty == true)
            const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cari',
                  icon: LucideIcons.search,
                  isLoading: _loading,
                  onPressed: _search,
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: _reset,
                icon: const Icon(LucideIcons.rotateCcw),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading) ...[
            const LoadingSkeleton(height: 280),
            const SizedBox(height: 16),
            const LoadingSkeleton(height: 280),
          ] else if (_error != null)
            EmptyState(
              title: 'Pencarian gagal',
              message: _error!,
              icon: LucideIcons.circleAlert,
              action: AppButton(
                label: 'Coba lagi',
                icon: LucideIcons.refreshCcw,
                onPressed: _search,
              ),
            )
          else if (_hasSearched && _results.isEmpty)
            EmptyState(
              title: 'Tidak ada hasil',
              message: 'Coba ubah kata kunci, kota, atau topik.',
              action: AppButton(
                label: 'Reset filter',
                icon: LucideIcons.rotateCcw,
                isSecondary: true,
                onPressed: _reset,
              ),
            )
          else if (!_hasSearched)
            const EmptyState(
              title: 'Mulai dari rasa perjalanan',
              message:
                  'Cari “pantai tenang”, pilih kota, atau aktifkan semantic untuk hasil yang lebih kontekstual.',
              icon: LucideIcons.compass,
            )
          else ...[
            if (_results.isNotEmpty)
              InfoPill(
                label: '${_results.length} destinasi ditemukan',
                icon: LucideIcons.listChecks,
                color: AppColors.secondary,
              ),
            const SizedBox(height: 12),
            for (final item in _results) ...[
              DestinationCard(
                destination: DestinationCardData(
                  name: item.name,
                  slug: item.slug,
                  city: item.city,
                  imageUrl: item.imageUrl,
                  positiveRatio: item.positiveRatio,
                  score: item.recommendationScore ?? item.matchScore,
                  googleRating: item.googleRating,
                  topics: item.topics.map((topic) => topic.name).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const Icon(LucideIcons.chevronDown, size: 18),
          ],
        ),
      ),
    );
  }
}
