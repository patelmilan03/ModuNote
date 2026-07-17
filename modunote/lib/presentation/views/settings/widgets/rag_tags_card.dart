import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../data/models/tag.dart';
import '../../../viewmodels/rag_reindex_view_model.dart';
import '../../../viewmodels/rag_settings_view_model.dart';
import '../../../viewmodels/tag_list_view_model.dart';

/// Lets the user choose which tags mark a note for "Ask your notes" indexing.
class RagTagsCard extends ConsumerWidget {
  const RagTagsCard({super.key, required this.isDark});

  final bool isDark;

  /// Adds a trigger tag by picking from the user's EXISTING tags only — no
  /// free-text creation (a trigger tag matching no real tag can never index
  /// anything). Lists tags from [tagListViewModelProvider] minus those already
  /// selected.
  Future<void> _pickExistingTag(
      BuildContext context, WidgetRef ref, List<Tag> allTags) async {
    if (allTags.isEmpty) {
      // Rate-limited (see app_toast) so rapid taps don't stack toasts.
      showInfoToast('Create some tags on your notes first.');
      return;
    }
    final scope = ref.read(ragIndexTagsProvider);
    if (allTags.every((t) => scope.contains(t.name))) {
      showInfoToast('All your tags are already in the scope.');
      return;
    }

    // useRootNavigator so the sheet renders ABOVE the floating bottom bar.
    // The sheet is self-contained (multi-add): tapping a tag adds it to the
    // scope and the remaining tags reflow, so no return value is needed.
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TagPickerSheet(allTags: allTags, isDark: isDark),
    );
  }

  /// Re-indexes every existing note that carries a scope tag, then reports the
  /// outcome via an app-wide toast.
  Future<void> _reindexAll(WidgetRef ref) async {
    final result = await ref.read(ragReindexProvider.notifier).reindexAll();
    if (result.ok == 0 && result.fail == 0) {
      showInfoToast('No notes match your scope tags yet.');
    } else if (result.fail == 0) {
      showSuccessToast(
        'Indexed ${result.ok} note${result.ok == 1 ? '' : 's'} for AI search.',
      );
    } else {
      showErrorToast(
        '${result.ok} indexed, ${result.fail} failed — check connection.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(ragIndexTagsProvider).toList()..sort();
    // Watch (not read) so the tag list stays alive + populated on this screen;
    // a bare read of this auto-dispose provider returns AsyncLoading (empty).
    final allTags =
        ref.watch(tagListViewModelProvider).valueOrNull ?? const <Tag>[];
    final isReindexing = ref.watch(ragReindexProvider);
    final cs = Theme.of(context).colorScheme;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outline = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: outline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: muted),
              const SizedBox(width: 10),
              Text(
                'Ask your notes — scope',
                style: AppTypography.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Notes with any of these tags are indexed for AI answers. '
            'Reopen a note after changing tags here to apply the change.',
            style: AppTypography.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: muted,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags)
                _TriggerTagChip(
                  label: tag,
                  isDark: isDark,
                  onRemove: () =>
                      ref.read(ragIndexTagsProvider.notifier).removeTag(tag),
                ),
              _AddTriggerTagChip(
                isDark: isDark,
                onTap: () => _pickExistingTag(context, ref, allTags),
              ),
            ],
          ),
          if (tags.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'No tags selected — no notes will be indexed for QnA.',
              style: AppTypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: muted,
              ),
            ),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: isReindexing ? null : () => _reindexAll(ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isReindexing)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimaryContainer,
                      ),
                    )
                  else
                    Icon(Icons.sync, size: 18, color: cs.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    isReindexing
                        ? 'Re-indexing…'
                        : 'Re-index all notes now',
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TriggerTagChip extends StatelessWidget {
  const _TriggerTagChip({
    required this.label,
    required this.isDark,
    required this.onRemove,
  });

  final String label;
  final bool isDark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$label',
            style: AppTypography.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 15, color: cs.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _AddTriggerTagChip extends StatelessWidget {
  const _AddTriggerTagChip({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: outlineStrong, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 15, color: muted),
            const SizedBox(width: 4),
            Text(
              'add tag',
              style: AppTypography.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing the user's existing tags to add to the RAG scope.
/// Self-contained multi-add: tapping a tag adds it to the scope immediately,
/// the tag disappears from the list, and the remaining tags reflow. Dismiss by
/// swiping down or tapping the backdrop.
class _TagPickerSheet extends ConsumerWidget {
  const _TagPickerSheet({required this.allTags, required this.isDark});

  final List<Tag> allTags;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(ragIndexTagsProvider);
    final available = allTags.where((t) => !scope.contains(t.name)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final chipBg = isDark ? AppColors.darkChipBg : AppColors.lightChipBg;
    final chipText = isDark ? AppColors.darkChipText : AppColors.lightChipText;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: outlineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add tags to the scope',
                  style: AppTypography.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: available.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'All your tags are in the scope.',
                          style: AppTypography.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: muted,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in available)
                            GestureDetector(
                              onTap: () => ref
                                  .read(ragIndexTagsProvider.notifier)
                                  .addTag(tag.name),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: chipBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add,
                                        size: 14, color: chipText),
                                    const SizedBox(width: 4),
                                    Text(
                                      '#${tag.name}',
                                      style: AppTypography.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: chipText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
