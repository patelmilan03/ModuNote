import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/note.dart';
import '../../../router/app_router.dart';
import '../../../viewmodels/note_list_view_model.dart';
import '../../../viewmodels/tag_list_view_model.dart';
import '../../../widgets/mn_note_card.dart';

/// Swipeable note card: swipe left = archive, swipe right = pin toggle (both
/// spring back — the Drift stream updates the list). Long-press opens the
/// pin/archive/delete actions sheet.
class SwipeableNoteCard extends ConsumerWidget {
  const SwipeableNoteCard({
    super.key,
    required this.note,
    required this.tagNames,
  });

  final Note note;
  final List<String> tagNames;

  void _showActionsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteActionsSheet(
        note: note,
        onPin: () {
          Navigator.of(context).pop();
          ref.read(noteListViewModelProvider.notifier).togglePin(note.id);
        },
        onArchive: () {
          Navigator.of(context).pop();
          ref.read(noteListViewModelProvider.notifier).archive(note.id);
        },
        onDelete: () {
          Navigator.of(context).pop();
          _confirmDelete(context, ref);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(noteListViewModelProvider.notifier).delete(note.id);
              // Clean up any tags orphaned by deleting this note.
              await ref.read(tagListViewModelProvider.notifier).pruneOrphans();
            },
            child: Text(
              'Delete',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey(note.id),
      // Always spring back — the Drift stream removes/updates the card.
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe left → archive
          ref.read(noteListViewModelProvider.notifier).archive(note.id);
        } else {
          // Swipe right → pin toggle
          ref.read(noteListViewModelProvider.notifier).togglePin(note.id);
        }
        return false;
      },
      background: _SwipeBg(
        alignment: Alignment.centerLeft,
        color: AppColors.accent.withValues(alpha: 0.15),
        icon: note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
        iconColor: AppColors.accent,
      ),
      secondaryBackground: _SwipeBg(
        alignment: Alignment.centerRight,
        color: (isDark
                ? AppColors.darkRecordRed
                : AppColors.lightRecordRed)
            .withValues(alpha: 0.15),
        icon: Icons.archive_outlined,
        iconColor:
            isDark ? AppColors.darkRecordRed : AppColors.lightRecordRed,
      ),
      child: MNNoteCard(
        note: note,
        tagNames: tagNames,
        onTap: () => context.push(AppRoutes.editNotePath(note.id)),
        onLongPress: () => _showActionsSheet(context, ref),
      ),
    );
  }
}

// Swipe reveal background
class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  final AlignmentGeometry alignment;
  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }
}

// Long-press actions bottom sheet
class _NoteActionsSheet extends StatelessWidget {
  const _NoteActionsSheet({
    required this.note,
    required this.onPin,
    required this.onArchive,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onPin;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final variantColor =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
    final errorColor = Theme.of(context).colorScheme.error;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: outlineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Text(
              note.title.isEmpty ? 'Untitled' : note.title,
              style: AppTypography.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          _ActionTile(
            icon: note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: note.isPinned ? 'Unpin' : 'Pin to top',
            color: variantColor,
            onTap: onPin,
          ),
          _ActionTile(
            icon: Icons.archive_outlined,
            label: 'Archive',
            color: variantColor,
            onTap: onArchive,
          ),
          _ActionTile(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: errorColor,
            onTap: onDelete,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTypography.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
