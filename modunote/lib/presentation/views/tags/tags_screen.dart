import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/tag.dart';
import '../../viewmodels/tag_list_view_model.dart';

/// Tags management screen.
/// Shows all tags with note-count density bars.
/// Spec: MODUNOTE_UI_REFERENCE.md § 3.3
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
            loading: () =>
                const Center(child: CircularProgressIndicator()),
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
    if (tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No tags yet',
              style: AppTypography.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap + to create your first tag',
              style: AppTypography.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.darkOnSurfaceMuted
                    : AppColors.lightOnSurfaceMuted,
              ),
            ),
          ],
        ),
      );
    }

    final maxCount =
        counts.values.isEmpty ? 1 : max(1, counts.values.reduce(max));
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outlineColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 150),
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: outlineColor, width: 0.5),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              for (int i = 0; i < tags.length; i++)
                _TagRow(
                  tag: tags[i],
                  noteCount: counts[tags[i].id] ?? 0,
                  maxCount: maxCount,
                  showDivider: i < tags.length - 1,
                  isDark: isDark,
                  onDelete: () => _confirmDelete(context, ref, tags[i], isDark),
                ),
            ],
          ),
        ),
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
          style: AppTypography.plusJakartaSans(
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
          style: AppTypography.plusJakartaSans(
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
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final mutedColor =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final primaryContainer = isDark
        ? AppColors.darkPrimaryContainer
        : AppColors.lightPrimaryContainer;
    final onPrimaryContainer = isDark
        ? AppColors.darkOnPrimaryContainer
        : AppColors.lightOnPrimaryContainer;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tags',
                  style: AppTypography.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tagCount == 1 ? '1 tag' : '$tagCount tags',
                  style: AppTypography.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.add, size: 20, color: onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tag Row ────────────────────────────────────────────────────────────────────

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tag,
    required this.noteCount,
    required this.maxCount,
    required this.showDivider,
    required this.isDark,
    required this.onDelete,
  });

  final Tag tag;
  final int noteCount;
  final int maxCount;
  final bool showDivider;
  final bool isDark;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final outlineColor =
        isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final chipBg = isDark ? AppColors.darkChipBg : AppColors.lightChipBg;
    final chipText = isDark ? AppColors.darkChipText : AppColors.lightChipText;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final mutedColor =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final surfaceContainer = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final densityFraction = noteCount / maxCount;

    return GestureDetector(
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: outlineColor, width: 0.5))
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          children: [
            // Hash icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '#',
                  style: AppTypography.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: chipText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + density bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tag.name,
                    style: AppTypography.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (_, constraints) => Stack(
                      children: [
                        // Track
                        Container(
                          height: 3,
                          width: constraints.maxWidth,
                          decoration: BoxDecoration(
                            color: surfaceContainer,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Fill
                        Container(
                          height: 3,
                          width: constraints.maxWidth * densityFraction,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Count badge
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              decoration: BoxDecoration(
                color: surfaceContainer,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$noteCount',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 16, color: mutedColor),
          ],
        ),
      ),
    );
  }
}

