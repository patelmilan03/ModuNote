import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/note.dart';
import '../../router/app_router.dart';
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Scrollable content ─────────────────────────────────
            Positioned.fill(
              child: notesAsync.when(
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
                  onRetry: () =>
                      ref.invalidate(noteListViewModelProvider),
                ),
              ),
            ),
            // ── Floating bottom nav ────────────────────────────────
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: _BottomNav(),
              ),
            ),
            // ── FAB ───────────────────────────────────────────────
            Positioned(
              bottom: 96,
              right: 20,
              child: _Fab(
                onTap: () => context.push(AppRoutes.newNote),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data state
// ─────────────────────────────────────────────────────────────────────────────

class _DataBody extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (pinned.isEmpty && recent.isEmpty) {
      return const _EmptyState();
    }

    final children = <Widget>[
      const _AppBarSection(),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: MNSearchField(
          onTap: () => context.push(AppRoutes.search),
        ),
      ),
    ];

    if (pinned.isNotEmpty) {
      children.add(_SectionHeader(title: 'PINNED', count: pinned.length));
      for (final note in pinned) {
        children.add(const SizedBox(height: 10));
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MNNoteCard(
              note: note,
              tagNames: _tagNames(note.tagIds),
              onTap: () => context.push(AppRoutes.editNotePath(note.id)),
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
            child: MNNoteCard(
              note: note,
              tagNames: _tagNames(note.tagIds),
              onTap: () => context.push(AppRoutes.editNotePath(note.id)),
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
// App bar section
// ─────────────────────────────────────────────────────────────────────────────

class _AppBarSection extends StatelessWidget {
  const _AppBarSection();

  static const _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
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
                  'Your notes',
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
            onTap: () => GoRouter.of(context).push(AppRoutes.search),
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

// ─────────────────────────────────────────────────────────────────────────────
// Floating bottom nav
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0x59000000)
                : const Color(0x0A1C1B2E),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavTab(
            icon: Icons.article_outlined,
            activeIcon: Icons.article,
            isActive: true,
            onTap: () {},
          ),
          _NavTab(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            isActive: false,
            onTap: () => context.go(AppRoutes.search),
          ),
          _NavTab(
            icon: Icons.label_outline,
            activeIcon: Icons.label,
            isActive: false,
            onTap: () => context.go(AppRoutes.tags),
          ),
          _NavTab(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            isActive: false,
            onTap: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? cs.primaryContainer : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isActive ? activeIcon : icon,
            size: 22,
            color: isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Amber FAB
// ─────────────────────────────────────────────────────────────────────────────

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            // rgba(245,158,11,0.55) ≈ 0x8C
            BoxShadow(
              color: Color(0x8CF59E0B),
              blurRadius: 16,
              spreadRadius: -4,
              offset: Offset(0, 6),
            ),
            // rgba(28,27,46,0.12) ≈ 0x1F
            BoxShadow(
              color: Color(0x1F1C1B2E),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          size: 26,
          color: AppColors.accentOn,
        ),
      ),
    );
  }
}
