import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/destination_categories.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_select_sheet.dart';
import '../../../core/widgets/destination_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_pill.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../auth/data/auth_controller.dart';
import '../data/search_models.dart';
import '../data/search_repository.dart';

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
  var _selectedCategory = '';
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
    if (query.isEmpty && _selectedCity.isEmpty && _selectedCategory.isEmpty) {
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
              city: _selectedCity,
              category: _selectedCategory,
            )
          : await repository.searchKeyword(
              query: query,
              city: _selectedCity,
              category: _selectedCategory,
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
      _selectedCity = '';
      _selectedCategory = '';
      _results = [];
      _hasSearched = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cities = ref.watch(citiesProvider);
    final history = ref.watch(searchHistoryProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SearchCommandSurface(
            controller: _queryController,
            semanticMode: _semanticMode,
            selectedCategory: _selectedCategory,
            selectedCity: _selectedCity,
            cities: cities,
            onSearch: _search,
            onModeChanged: (value) {
              setState(() => _semanticMode = value);
              if (_hasSearched) _search();
            },
            onCategoryChanged: (value) {
              setState(() => _selectedCategory = value);
              _search();
            },
            onCityChanged: (value) {
              setState(() => _selectedCity = value);
              _search();
            },
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
                color: _semanticMode ? AppColors.ai : AppColors.explore,
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
                  category: item.category,
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

class _SearchCommandSurface extends StatelessWidget {
  const _SearchCommandSurface({
    required this.controller,
    required this.semanticMode,
    required this.selectedCategory,
    required this.selectedCity,
    required this.cities,
    required this.onSearch,
    required this.onModeChanged,
    required this.onCategoryChanged,
    required this.onCityChanged,
  });

  final TextEditingController controller;
  final bool semanticMode;
  final String selectedCategory;
  final String selectedCity;
  final AsyncValue<List<String>> cities;
  final VoidCallback onSearch;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onCityChanged;

  @override
  Widget build(BuildContext context) {
    final tone = semanticMode ? AppColors.ai : AppColors.explore;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: semanticMode ? AppColors.surfaceCool : AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: tone.withValues(alpha: .18)),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: .08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  semanticMode ? LucideIcons.brain : LucideIcons.searchCheck,
                  color: tone,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cari destinasi', style: AppTextStyles.sectionTitle),
                    SizedBox(height: 2),
                    Text(
                      'Temukan tempat dari nama, kota, kategori, atau vibe.',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: semanticMode
                  ? 'Contoh: pantai tenang untuk keluarga'
                  : 'Pantai tenang, wisata budaya...',
              prefixIcon: Icon(
                semanticMode ? LucideIcons.sparkles : LucideIcons.search,
              ),
              suffixIcon: IconButton(
                onPressed: onSearch,
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
            selected: {semanticMode},
            onSelectionChanged: (value) => onModeChanged(value.first),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 420;
              final categoryButton = _FilterButton(
                icon: LucideIcons.layers,
                tone: AppColors.explore,
                label: selectedCategory.isEmpty
                    ? 'Semua kategori'
                    : destinationCategoryLabel(selectedCategory),
                onTap: () async {
                  final value = await showAppSelectSheet<String>(
                    context: context,
                    title: 'Pilih kategori',
                    selectedValue: selectedCategory,
                    searchable: true,
                    searchHint: 'Cari kategori destinasi',
                    options: [
                      const SelectOption(
                        value: '',
                        label: 'Semua kategori',
                        icon: LucideIcons.layers,
                      ),
                      for (final category in destinationCategories)
                        SelectOption(
                          value: category.value,
                          label: category.label,
                          icon: LucideIcons.tag,
                        ),
                    ],
                  );
                  if (value == null) return;
                  onCategoryChanged(value);
                },
              );
              final cityButton = cities.when(
                data: (items) => _FilterButton(
                  icon: LucideIcons.mapPin,
                  tone: AppColors.ai,
                  label: selectedCity.isEmpty ? 'Semua kota' : selectedCity,
                  onTap: () async {
                    final value = await showAppSelectSheet<String>(
                      context: context,
                      title: 'Pilih kota',
                      selectedValue: selectedCity,
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
                    onCityChanged(value);
                  },
                ),
                error: (_, __) => const SizedBox.shrink(),
                loading: () => const LoadingSkeleton(height: 54),
              );

              if (!twoColumns) {
                return Column(
                  children: [
                    categoryButton,
                    const SizedBox(height: 10),
                    cityButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: categoryButton),
                  const SizedBox(width: 10),
                  Expanded(child: cityButton),
                ],
              );
            },
          ),
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
    this.tone = AppColors.explore,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color tone;

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
          border: Border.all(color: tone.withValues(alpha: .16)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: tone),
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
