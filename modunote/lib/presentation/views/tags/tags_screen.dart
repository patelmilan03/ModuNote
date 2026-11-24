import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/category.dart';
import '../../../data/models/tag.dart';
import '../../router/app_router.dart';
import '../../viewmodels/category_tree_view_model.dart';
import '../../viewmodels/note_list_view_model.dart';
import '../../viewmodels/tag_list_view_model.dart';
import '../../widgets/mn_empty_badge.dart';
import '../../widgets/mn_skeletons.dart';

/// Tags tab (UI revamp 2026-11): tag bubbles sized by note count, then a
/// Folders card listing the category tree. Tapping a bubble or a folder
/// filters Home by it; long-pressing a bubble deletes the tag.
class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagListViewModelProvider);
    final countsAsync = ref.watch(tagNoteCountsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TagsAppBar(
          tagCount: tagsAsync.valueOrNull?.length ?? 0,
          isDark: isDark,
          onAdd: () => _showAddTagDialog(context, ref, isDark),
        ),
        Expanded(
          child: tagsAsync.when(
            data: (tags) => _buildTagList(
              context,
              ref,
              tags,
              countsAsync.valueOrNull ?? {},
              isDark,
            ),
            loading: () => Skeletonizer(
              enabled: true,
              child: _buildTagList(
                context,
                ref,
                skeletonTags(),
                const {},
                isDark,
              ),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Failed to load tags',
                    style: AppTypography.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkOnSurface
                          : AppColors.lightOnSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(tagListViewModelProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagList(
    BuildContext context,
    WidgetRef ref,
    List<Tag> tags,
    Map<String, int> counts,
    bool isDark,
  ) {
    final cats = ref.watch(categoryTreeViewModelProvider).valueOrNull ?? const [];
    if (tags.isEmpty && cats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MNEmptyBadge(icon: Icons.sell_outlined, tintIndex: 1),
              const SizedBox(height: 16),
              Text(
                'No tags yet',
                style: AppTypography.heading(
                  fontSize: 19,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap + to create your first tag.',
                style: AppTypography.inter(
                  fontSize: 13.5,
                  color: AppColors.mutedOf(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Biggest first, so the bubble cloud reads from the top.
    final sorted = [...tags]
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    final maxCount =
        counts.values.isEmpty ? 1 : max(1, counts.values.reduce(max));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 150),
      children: [
        if (sorted.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < sorted.length; i++)
                _TagBubble(
                  tag: sorted[i],
                  count: counts[sorted[i].id] ?? 0,
                  maxCount: maxCount,
                  tintIndex: i,
                  onTap: () {
                    ref
                        .read(noteFilterNotifierProvider.notifier)
                        .setTag(sorted[i].id, sorted[i].name);
                    context.go(AppRoutes.home);
                  },
                  onLongPress: () =>
                      _confirmDelete(context, ref, sorted[i], isDark),
                ),
            ],
          ),
        if (cats.isNotEmpty) ...[
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(
              'FOLDERS',
              style: AppTypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.mutedOf(context),
              ),
            ),
          ),
          _FoldersCard(
            categories: cats,
            counts: ref.watch(categoryNoteCountsProvider).valueOrNull ??
                const {},
            tintIndex: ref.watch(categoryTintIndexProvider),
            onTap: (c) {
              ref
                  .read(noteFilterNotifierProvider.notifier)
                  .setCategory(c.id, c.name);
              context.go(AppRoutes.home);
            },
          ),
        ],
      ],
    );
  }

  void _showAddTagDialog(BuildContext context, WidgetRef ref, bool isDark) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'New tag',
          style: AppTypography.heading(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(hintText: 'e.g. photography'),
          onSubmitted: (value) {
            Navigator.of(ctx).pop();
            final name = value.trim();
            if (name.isNotEmpty) {
              ref.read(tagListViewModelProvider.notifier).insert(name);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              Navigator.of(ctx).pop();
              if (name.isNotEmpty) {
                ref.read(tagListViewModelProvider.notifier).insert(name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Tag tag, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete "#${tag.name}"?',
          style: AppTypography.heading(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
          ),
        ),
        content: Text(
          'This tag will be removed from all notes.',
          style: AppTypography.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: isDark
                ? AppColors.darkOnSurfaceVariant
                : AppColors.lightOnSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(tagListViewModelProvider.notifier).delete(tag.id);
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkRecordRed
                    : AppColors.lightRecordRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── App Bar ───────────────────────────────────────────────────────────────────

class _TagsAppBar extends StatelessWidget {
  const _TagsAppBar({
    required this.tagCount,
    required this.isDark,
    required this.onAdd,
  });

  final int tagCount;
  final bool isDark;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tags',
                  style: AppTypography.heading(
                    fontSize: 34,
                    letterSpacing: -0.8,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tagCount == 1 ? '1 tag' : '$tagCount tags',
                  style: AppTypography.inter(
                    fontSize: 13,
                    color: AppColors.mutedOf(context),
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'New tag',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.add_rounded, size: 24, color: cs.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tag bubble ─────────────────────────────────────────────────────────────

/// Circle sized 64–128 px by the tag's share of the busiest tag's count.
class _TagBubble extends StatelessWidget {
  const _TagBubble({
    required this.tag,
    required this.count,
    required this.maxCount,
    required this.tintIndex,
    required this.onTap,
    required this.onLongPress,
  });

  final Tag tag;
  final int count;
  final int maxCount;
  final int tintIndex;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  static const double _min = 64;
  static const double _max = 128;

  @override
  Widget build(BuildContext context) {
    final size = _min + (_max - _min) * (count / maxCount).clamp(0.0, 1.0);
    final fg = Theme.of(context).colorScheme.onSurface;

    return Semantics(
      button: true,
      label: '#${tag.name}, $count notes',
      hint: 'Long press to delete',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.tintOf(context, tintIndex),
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#${tag.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  fontSize: size > 90 ? 12.5 : 11,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              Text(
                '$count',
                style: AppTypography.heading(
                  fontSize: size > 90 ? 18 : 15,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Folders card ───────────────────────────────────────────────────────────

/// White card listing the category tree depth-first, children indented.
class _FoldersCard extends StatelessWidget {
  const _FoldersCard({
    required this.categories,
    required this.counts,
    required this.tintIndex,
    required this.onTap,
  });

  final List<Category> categories;
  final Map<String, int> counts;
  final Map<String, int> tintIndex;
  final ValueChanged<Category> onTap;

  List<(Category, int)> _flatten() {
    final children = <String?, List<Category>>{};
    for (final c in categories) {
      (children[c.parentId] ??= []).add(c);
    }
    for (final list in children.values) {
      list.sort((a, b) {
        final o = a.sortOrder.compareTo(b.sortOrder);
        return o != 0 ? o : a.createdAt.compareTo(b.createdAt);
      });
    }
    final out = <(Category, int)>[];
    void walk(String? parent, int depth) {
      if (depth > 5) return; // max depth is 5; also guards cycles
      for (final c in children[parent] ?? const <Category>[]) {
        out.add((c, depth));
        walk(c.id, depth + 1);
      }
    }

    walk(null, 0);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rows = _flatten();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => onTap(rows[i].$1),
                child: Container(
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(top: BorderSide(color: cs.outline)),
                  ),
                  padding: EdgeInsets.fromLTRB(
                      16 + 22.0 * rows[i].$2.clamp(0, 3), 12, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: tintIndex[rows[i].$1.id] == null
                              ? cs.surfaceContainer
                              : AppColors.tintOf(
                                  context, tintIndex[rows[i].$1.id]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.folder_outlined,
                            size: 18, color: cs.onSurface),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rows[i].$1.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '${counts[rows[i].$1.id] ?? 0}',
                        style: AppTypography.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedOf(context),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.mutedOf(context)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
