import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/category.dart';
import '../../../data/models/note.dart';
import '../../router/app_router.dart';
import '../../viewmodels/category_tree_view_model.dart';
import '../../viewmodels/note_list_view_model.dart';
import '../../viewmodels/tag_list_view_model.dart';
import '../../widgets/mn_note_card.dart';
import '../../widgets/mn_search_field.dart';

/// Home screen — two-section note list (Pinned + Recent).
/// Phase 4 full implementation.
class NoteListScreen extends ConsumerWidget {
  const NoteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(noteListViewModelProvider);
    final tagsAsync = ref.watch(tagListViewModelProvider);

    // Build id→name lookup; empty map while tags are loading/errored.
    final tagMap = tagsAsync.maybeWhen(
      data: (tags) => {for (final t in tags) t.id: t.name},
      orElse: () => <String, String>{},
    );

    return notesAsync.when(
      data: (notes) {
        final pinned = notes.where((n) => n.isPinned).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final recent = notes.where((n) => !n.isPinned).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return _DataBody(
          pinned: pinned,
          recent: recent,
          tagMap: tagMap,
        );
      },
      loading: () => const _LoadingBody(),
      error: (_, __) => _ErrorBody(
        onRetry: () => ref.invalidate(noteListViewModelProvider),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data state
// ─────────────────────────────────────────────────────────────────────────────

class _DataBody extends ConsumerWidget {
  const _DataBody({
    required this.pinned,
    required this.recent,
    required this.tagMap,
  });

  final List<Note> pinned;
  final List<Note> recent;
  final Map<String, String> tagMap;

  List<String> _tagNames(List<String> ids) =>
      ids.map((id) => tagMap[id]).whereType<String>().toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pinned.isEmpty && recent.isEmpty) {
      final filter = ref.watch(noteFilterNotifierProvider);
      if (filter.type == NoteFilterType.all) {
        return const _EmptyState();
      }
      return const _FilteredEmptyState();
    }

    final children = <Widget>[
      const _AppBarSection(),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: MNSearchField(
          onTap: () => context.go(AppRoutes.search),
        ),
      ),
      const SizedBox(height: 10),
      const _FilterChipBar(),
    ];

    if (pinned.isNotEmpty) {
      children.add(_SectionHeader(title: 'PINNED', count: pinned.length));
      for (final note in pinned) {
        children.add(const SizedBox(height: 10));
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SwipeableNoteCard(
              note: note,
              tagNames: _tagNames(note.tagIds),
            ),
          ),
        );
      }
    }

    if (recent.isNotEmpty) {
      if (pinned.isNotEmpty) children.add(const SizedBox(height: 10));
      children.add(const _SectionHeader(title: 'RECENT'));
      for (final note in recent) {
        children.add(const SizedBox(height: 10));
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SwipeableNoteCard(
              note: note,
              tagNames: _tagNames(note.tagIds),
            ),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 150),
      children: children,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipeable card with long-press actions
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeableNoteCard extends ConsumerWidget {
  const _SwipeableNoteCard({
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
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(noteListViewModelProvider.notifier).delete(note.id);
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

// ─────────────────────────────────────────────────────────────────────────────
// Filter chip bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChipBar extends ConsumerWidget {
  const _FilterChipBar();

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

// ─────────────────────────────────────────────────────────────────────────────
// App bar section
// ─────────────────────────────────────────────────────────────────────────────

class _AppBarSection extends StatelessWidget {
  const _AppBarSection();

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final today = _days[DateTime.now().weekday - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  today.toUpperCase(),
                  style: AppTypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ModuNote',
                  style: AppTypography.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, AppColors.accent],
              ),
            ),
            child: Center(
              child: Text(
                'MA',
                style: AppTypography.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: muted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 0.5, color: cs.outline),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Text(
              '$count',
              style: AppTypography.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading state
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 150),
      children: const [
        _SkeletonBox(height: 48, radius: 16),
        SizedBox(height: 20),
        _SkeletonBox(height: 105, radius: 20),
        SizedBox(height: 10),
        _SkeletonBox(height: 105, radius: 20),
        SizedBox(height: 10),
        _SkeletonBox(height: 80, radius: 20),
      ],
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({required this.height, required this.radius});

  final double height;
  final double radius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.65).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Could not load notes',
            style: AppTypography.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: AppTypography.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filtered empty state (filter active, zero results)
// ─────────────────────────────────────────────────────────────────────────────

class _FilteredEmptyState extends ConsumerWidget {
  const _FilteredEmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(noteFilterNotifierProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    final label = filter.type == NoteFilterType.category
        ? (filter.name ?? 'this category')
        : '#${filter.name ?? 'this tag'}';

    return Column(
      children: [
        const _AppBarSection(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: MNSearchField(
            onTap: () => context.go(AppRoutes.search),
          ),
        ),
        const SizedBox(height: 10),
        const _FilterChipBar(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 56, color: muted),
                const SizedBox(height: 16),
                Text(
                  'No notes in $label',
                  style: AppTypography.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap + to add a note here.',
                  style: AppTypography.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    return Column(
      children: [
        // App bar still visible above empty state
        const _AppBarSection(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: MNSearchField(
            onTap: () => context.go(AppRoutes.search),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.article_outlined, size: 56, color: muted),
                const SizedBox(height: 16),
                Text(
                  'No notes yet',
                  style: AppTypography.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap + to capture your first idea.',
                  style: AppTypography.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
