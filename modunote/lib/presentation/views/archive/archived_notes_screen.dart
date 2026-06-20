import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/note.dart';
import '../../router/app_router.dart';
import '../../viewmodels/archived_notes_view_model.dart';
import '../../viewmodels/tag_list_view_model.dart';
import '../../widgets/mn_note_card.dart';

/// Archived notes screen — full-screen, outside the ShellRoute.
/// Swipe right to restore, swipe left to delete permanently.
class ArchivedNotesScreen extends ConsumerWidget {
  const ArchivedNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(archivedNotesViewModelProvider);
    final tagsAsync = ref.watch(tagListViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tagMap = tagsAsync.maybeWhen(
      data: (tags) => {for (final t in tags) t.id: t.name},
      orElse: () => <String, String>{},
    );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ArchiveAppBar(isDark: isDark),
            Expanded(
              child: archivedAsync.when(
                data: (notes) => notes.isEmpty
                    ? _EmptyArchive(isDark: isDark)
                    : _NotesList(
                        notes: notes,
                        tagMap: tagMap,
                        isDark: isDark,
                      ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(archivedNotesViewModelProvider),
                    child: const Text('Retry'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────

class _ArchiveAppBar extends StatelessWidget {
  const _ArchiveAppBar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: onSurface),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          Text(
            'Archived',
            style: AppTypography.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(swipe to restore or delete)',
            style: AppTypography.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notes list ───────────────────────────────────────────────────────────────

class _NotesList extends ConsumerWidget {
  const _NotesList({
    required this.notes,
    required this.tagMap,
    required this.isDark,
  });

  final List<Note> notes;
  final Map<String, String> tagMap;
  final bool isDark;

  List<String> _tagNames(List<String> ids) =>
      ids.map((id) => tagMap[id]).whereType<String>().toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorColor = Theme.of(context).colorScheme.error;
    final restoreColor =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final note = notes[i];
        return Dismissible(
          key: ValueKey(note.id),
          // Springs back — Drift stream removes the card naturally.
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              // Swipe right → restore
              await ref
                  .read(archivedNotesViewModelProvider.notifier)
                  .restore(note.id);
            } else {
              // Swipe left → delete (confirm first)
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete permanently?'),
                  content:
                      const Text('This note will be gone forever.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        'Delete',
                        style: TextStyle(color: errorColor),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref
                    .read(archivedNotesViewModelProvider.notifier)
                    .delete(note.id);
              }
            }
            return false;
          },
          background: _SwipeBg(
            alignment: Alignment.centerLeft,
            color: restoreColor.withValues(alpha: 0.15),
            icon: Icons.restore,
            iconColor: restoreColor,
          ),
          secondaryBackground: _SwipeBg(
            alignment: Alignment.centerRight,
            color: errorColor.withValues(alpha: 0.15),
            icon: Icons.delete_forever_outlined,
            iconColor: errorColor,
          ),
          child: MNNoteCard(
            note: note,
            tagNames: _tagNames(note.tagIds),
            onTap: () => context.push(AppRoutes.editNotePath(note.id)),
          ),
        );
      },
    );
  }
}

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

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyArchive extends StatelessWidget {
  const _EmptyArchive({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.archive_outlined, size: 52, color: muted),
          const SizedBox(height: 16),
          Text(
            'No archived notes',
            style: AppTypography.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Archived notes will appear here.',
            style: AppTypography.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}
