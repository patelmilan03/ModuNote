import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../router/app_router.dart';
import '../../../viewmodels/note_list_view_model.dart';
import '../../../widgets/mn_search_field.dart';
import 'app_bar_section.dart';
import 'filter_chip_bar.dart';

/// Loading state — pulsing skeleton boxes.
class LoadingBody extends StatelessWidget {
  const LoadingBody({super.key});

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

/// Error state — icon + retry button.
class ErrorBody extends StatelessWidget {
  const ErrorBody({super.key, required this.onRetry});

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

/// Filtered empty state (filter active, zero results) — keeps the app bar,
/// search field, and filter chip bar visible so the filter can be changed.
class FilteredEmptyState extends ConsumerWidget {
  const FilteredEmptyState({super.key});

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
        const AppBarSection(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: MNSearchField(
            onTap: () => context.go(AppRoutes.search),
          ),
        ),
        const SizedBox(height: 10),
        const FilterChipBar(),
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

/// Empty state — no notes at all (no filter active).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    return Column(
      children: [
        // App bar still visible above empty state
        const AppBarSection(),
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
