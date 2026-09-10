import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
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

// Memuat daftar kota untuk filter search.
final citiesProvider = FutureProvider<List<String>>((ref) {
  return ref.read(searchRepositoryProvider).fetchCities();
});

// Memuat kategori destinasi dari backend dengan fallback lokal.
final categoriesProvider =
    FutureProvider<List<DestinationCategoryOption>>((ref) {
  return ref.read(searchRepositoryProvider).fetchCategories();
});

// Memuat riwayat search hanya untuk user login.
final searchHistoryProvider = FutureProvider<List<SearchHistoryItem>>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) return const [];
  return ref.read(searchRepositoryProvider).fetchHistory();
});

// Halaman search mobile untuk keyword, semantic, kota, kategori, dan hasil destinasi.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({this.initialQuery, super.key});

  final String? initialQuery;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _queryController = TextEditingController();
  var _semanticMode = false;
  var _semanticSort = 'hybrid';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  // Menjalankan pencarian sesuai mode dan filter aktif.
  Future<void> _search() async {
    final query = _queryController.text.trim();

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
              sort: _semanticSort,
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
      _semanticSort = 'hybrid';
      _results = [];
      _hasSearched = false;
      _error = null;
    });
    _search();
  }

  Future<void> _deleteHistoryItem(SearchHistoryItem item) async {
    final id = item.id;
    if (id == null) return;

    try {
      await ref.read(searchRepositoryProvider).deleteHistoryItem(id);
      ref.invalidate(searchHistoryProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Riwayat pencarian dihapus.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus riwayat pencarian.')),
      );
    }
  }

  Future<void> _clearHistory() async {
    try {
      await ref.read(searchRepositoryProvider).clearHistory();
      ref.invalidate(searchHistoryProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua riwayat pencarian dibersihkan.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membersihkan riwayat.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = ref.watch(citiesProvider);
    final categories = ref.watch(categoriesProvider);
    final history = ref.watch(searchHistoryProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Search TextField (gaya flat & bersih seperti halaman profil)
          TextField(
            controller: _queryController,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: _semanticMode
                  ? 'Cari makna (misal: pantai tenang)...'
                  : 'Cari destinasi, wisata, budaya...',
              prefixIcon: Icon(
                _semanticMode ? LucideIcons.sparkles : LucideIcons.search,
              ),
              suffixIcon: _queryController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        _queryController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // 2. Filter Action Row: Kategori & Kota (gaya _FilterAction seperti halaman profil)
          Row(
            children: [
              Expanded(
                child: categories.when(
                  data: (items) => _FilterAction(
                    icon: LucideIcons.layers,
                    label: _selectedCategory.isEmpty
                        ? 'Semua kategori'
                        : items
                            .firstWhere(
                              (c) => c.value == _selectedCategory,
                              orElse: () => DestinationCategoryOption(
                                value: _selectedCategory,
                                label: _selectedCategory,
                              ),
                            )
                            .label,
                    onTap: () async {
                      final value = await showAppSelectSheet<String>(
                        context: context,
                        title: 'Pilih kategori',
                        selectedValue: _selectedCategory,
                        options: [
                          const SelectOption(
                            value: '',
                            label: 'Semua kategori',
                            icon: LucideIcons.layers,
                          ),
                          for (final category in items)
                            SelectOption(
                              value: category.value,
                              label: category.label,
                              icon: LucideIcons.tag,
                            ),
                        ],
                      );
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                        _search();
                      }
                    },
                  ),
                  loading: () => const LoadingSkeleton(height: 48),
                  error: (_, __) => _FilterAction(
                    icon: LucideIcons.layers,
                    label: _selectedCategory.isEmpty
                        ? 'Semua kategori'
                        : destinationCategoryLabel(_selectedCategory),
                    onTap: () {},
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: cities.when(
                  data: (items) => _FilterAction(
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
                      if (value != null) {
                        setState(() => _selectedCity = value);
                        _search();
                      }
                    },
                  ),
                  loading: () => const LoadingSkeleton(height: 48),
                  error: (_, __) => _FilterAction(
                    icon: LucideIcons.mapPin,
                    label: _selectedCity.isEmpty ? 'Semua kota' : _selectedCity,
                    onTap: () {},
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. SegmentedButton Mode (Keyword vs Semantic)
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

          // 4. Tombol "Cari" & Reset
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

          // 5. Toggle Sort jika mode Semantic aktif
          if (_semanticMode) ...[
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'hybrid',
                  icon: Icon(LucideIcons.sparkles, size: 16),
                  label: Text('Rekomendasi'),
                ),
                ButtonSegment(
                  value: 'relevance',
                  icon: Icon(LucideIcons.target, size: 16),
                  label: Text('Paling Sesuai'),
                ),
              ],
              selected: {_semanticSort},
              onSelectionChanged: (value) {
                setState(() => _semanticSort = value.first);
                if (_hasSearched) _search();
              },
            ),
          ],
          const SizedBox(height: 14),

          // 6. Riwayat Pencarian Dropdown
          history.when(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _SearchHistoryChips(
                      items: items,
                      onSelect: (item) {
                        _queryController.text = item.keyword;
                        _search();
                      },
                      onDelete: _deleteHistoryItem,
                      onClear: _clearHistory,
                    ),
                  ),
            error: (_, __) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),

          // 7. Hasil Pencarian
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
              message: 'Coba ubah kata kunci, kota, atau kategori.',
              action: AppButton(
                label: 'Reset filter',
                icon: LucideIcons.rotateCcw,
                isSecondary: true,
                onPressed: _reset,
              ),
            )
          else if (!_hasSearched)
            const EmptyState(
              title: 'Memuat katalog destinasi',
              message:
                  'Cari “pantai tenang”, pilih kota, atau aktifkan semantic untuk hasil yang lebih kontekstual.',
              icon: LucideIcons.compass,
            )
          else ...[
            if (_results.isNotEmpty)
              InfoPill(
                label: _queryController.text.trim().isEmpty &&
                        _selectedCity.isEmpty &&
                        _selectedCategory.isEmpty
                    ? '${_results.length} destinasi tersedia'
                    : '${_results.length} destinasi ditemukan',
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
                  score: item.recommendationScore,
                  matchScore: _semanticMode &&
                          _queryController.text.trim().isNotEmpty
                      ? item.matchScore
                      : null,
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

class _SearchHistoryChips extends StatefulWidget {
  const _SearchHistoryChips({
    required this.items,
    required this.onSelect,
    required this.onDelete,
    required this.onClear,
  });

  final List<SearchHistoryItem> items;
  final ValueChanged<SearchHistoryItem> onSelect;
  final Future<void> Function(SearchHistoryItem) onDelete;
  final Future<void> Function() onClear;

  @override
  State<_SearchHistoryChips> createState() => _SearchHistoryChipsState();
}

class _SearchHistoryChipsState extends State<_SearchHistoryChips> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(LucideIcons.history, size: 16, color: AppColors.ai),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Riwayat pencarian (${widget.items.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (_expanded)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => widget.onClear(),
                      child: const Text('Bersihkan', style: TextStyle(fontSize: 12)),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in widget.items)
                    _HistoryChip(
                      item: item,
                      onSelect: () => widget.onSelect(item),
                      onDelete: item.id == null
                          ? null
                          : () {
                              widget.onDelete(item);
                            },
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({
    required this.item,
    required this.onSelect,
    this.onDelete,
  });

  final SearchHistoryItem item;
  final VoidCallback onSelect;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCool,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.history, size: 14, color: AppColors.ai),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  item.keyword,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (onDelete != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: onDelete,
                  icon: const Icon(LucideIcons.x, size: 15),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
