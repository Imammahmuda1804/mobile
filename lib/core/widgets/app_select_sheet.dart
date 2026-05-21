import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';

class SelectOption<T> {
  const SelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

Future<T?> showAppSelectSheet<T>({
  required BuildContext context,
  required String title,
  required List<SelectOption<T>> options,
  T? selectedValue,
  bool searchable = false,
  String searchHint = 'Cari pilihan',
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return SafeArea(
        child: _AppSelectSheetContent<T>(
          title: title,
          options: options,
          selectedValue: selectedValue,
          searchable: searchable,
          searchHint: searchHint,
        ),
      );
    },
  );
}

class _AppSelectSheetContent<T> extends StatefulWidget {
  const _AppSelectSheetContent({
    required this.title,
    required this.options,
    required this.searchable,
    required this.searchHint,
    this.selectedValue,
  });

  final String title;
  final List<SelectOption<T>> options;
  final T? selectedValue;
  final bool searchable;
  final String searchHint;

  @override
  State<_AppSelectSheetContent<T>> createState() =>
      _AppSelectSheetContentState<T>();
}

class _AppSelectSheetContentState<T> extends State<_AppSelectSheetContent<T>> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final options = query.isEmpty
        ? widget.options
        : widget.options.where((option) {
            return '${option.label} ${option.subtitle ?? ''}'
                .toLowerCase()
                .contains(query);
          }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * .78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            if (widget.searchable) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(LucideIcons.search),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Flexible(
              child: options.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Tidak ada pilihan yang cocok.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final selected = option.value == widget.selectedValue;
                        return _SelectOptionTile<T>(
                          option: option,
                          selected: selected,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectOptionTile<T> extends StatelessWidget {
  const _SelectOptionTile({
    required this.option,
    required this.selected,
  });

  final SelectOption<T> option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceWarm : AppColors.background,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        minVerticalPadding: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? const Color(0xFFFFD0BA) : AppColors.border,
          ),
        ),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: selected ? AppColors.explore : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            option.icon ?? LucideIcons.circle,
            size: 17,
            color: selected ? Colors.white : AppColors.explore,
          ),
        ),
        title: Text(
          option.label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: option.subtitle == null
            ? null
            : Text(
                option.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: selected
            ? const Icon(LucideIcons.check, color: AppColors.explore)
            : null,
        onTap: () => Navigator.of(context).pop(option.value),
      ),
    );
  }
}
