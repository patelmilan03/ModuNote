import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/category.dart';
import '../../../viewmodels/category_tree_view_model.dart';
import '../../../viewmodels/note_list_view_model.dart';
import '../../../viewmodels/tag_list_view_model.dart';

/// Horizontal filter chip bar: "All" + one chip per category + one per tag.
class FilterChipBar extends ConsumerWidget {
  const FilterChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(noteFilterNotifierProvider);
    final tagsAsync = ref.watch(tagListViewModelProvider);
    final categoriesAsync = ref.watch(categoryTreeViewModelProvider);

    final tags = tagsAsync.valueOrNull ?? [];
    final categories = categoriesAsync.valueOrNull ?? <Category>[];

    if (tags.isEmpty && categories.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final chipBg = isDark ? AppColors.darkChipBg : AppColors.lightChipBg;
    final chipText = isDark ? AppColors.darkChipText : AppColors.lightChipText;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    final isAll = filter.type == NoteFilterType.all;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // "All" chip
          _FilterChip(
            label: 'All',
            isSelected: isAll,
            selectedBg: cs.primaryContainer,
            selectedFg: cs.onPrimaryContainer,
            defaultBg: chipBg,
            defaultFg: chipText,
            onTap: () =>
                ref.read(noteFilterNotifierProvider.notifier).setAll(),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(width: 6),
            for (final cat in categories) ...[
              _FilterChip(
                label: cat.name,
                isSelected: filter.type == NoteFilterType.category &&
                    filter.id == cat.id,
                selectedBg: cs.primaryContainer,
                selectedFg: cs.onPrimaryContainer,
                defaultBg: chipBg,
                defaultFg: chipText,
                prefix: Icons.folder_outlined,
                prefixColor: muted,
                onTap: () => ref
                    .read(noteFilterNotifierProvider.notifier)
                    .setCategory(cat.id, cat.name),
              ),
              const SizedBox(width: 6),
            ],
          ],
          if (tags.isNotEmpty) ...[
            for (final tag in tags) ...[
              _FilterChip(
                label: '#${tag.name}',
                isSelected: filter.type == NoteFilterType.tag &&
                    filter.id == tag.id,
                selectedBg: cs.primaryContainer,
                selectedFg: cs.onPrimaryContainer,
                defaultBg: chipBg,
                defaultFg: chipText,
                onTap: () => ref
                    .read(noteFilterNotifierProvider.notifier)
                    .setTag(tag.id, tag.name),
              ),
              const SizedBox(width: 6),
            ],
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.selectedBg,
    required this.selectedFg,
    required this.defaultBg,
    required this.defaultFg,
    required this.onTap,
    this.prefix,
    this.prefixColor,
  });

  final String label;
  final bool isSelected;
  final Color selectedBg;
  final Color selectedFg;
  final Color defaultBg;
  final Color defaultFg;
  final VoidCallback onTap;
  final IconData? prefix;
  final Color? prefixColor;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? selectedBg : defaultBg;
    final fg = isSelected ? selectedFg : defaultFg;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prefix != null) ...[
              Icon(prefix, size: 13, color: isSelected ? fg : prefixColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
