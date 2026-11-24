import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../router/app_router.dart';

/// Persistent floating dock rendered by the GoRouter ShellRoute (Nav A,
/// UI revamp 2026-11). Never instantiated per-screen — rendered once by
/// `_AppShell` in app_router.dart, beside the separate capture button.
///
/// 4 tabs: Notes · Ask · Search · Tags. Settings lives behind the Home avatar.
/// Inactive tabs are icon-only; the active tab is a cream pill with an ink
/// icon + label that grows in (width + colour animate, 280 ms, slight
/// overshoot). Light dock = ink, dark dock = #2B2639.
class MNBottomNav extends StatelessWidget {
  const MNBottomNav({super.key, required this.activeIndex});

  /// 0 = Notes, 1 = Ask, 2 = Search, 3 = Tags.
  final int activeIndex;

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.dockOf(context),
        borderRadius: BorderRadius.circular(height / 2),
        border: isDark
            ? Border.all(color: AppColors.darkOutline, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _DockTab(
            icon: Icons.sticky_note_2_outlined,
            activeIcon: Icons.sticky_note_2_rounded,
            label: 'Notes',
            isActive: activeIndex == 0,
            onTap: () => context.go(AppRoutes.home),
          ),
          _DockTab(
            icon: Icons.auto_awesome_outlined,
            activeIcon: Icons.auto_awesome,
            label: 'Ask',
            isActive: activeIndex == 1,
            onTap: () => context.go(AppRoutes.qna),
          ),
          _DockTab(
            icon: Icons.search_rounded,
            activeIcon: Icons.search_rounded,
            label: 'Search',
            isActive: activeIndex == 2,
            onTap: () => context.go(AppRoutes.search),
          ),
          _DockTab(
            icon: Icons.sell_outlined,
            activeIcon: Icons.sell_rounded,
            label: 'Tags',
            isActive: activeIndex == 3,
            onTap: () => context.go(AppRoutes.tags),
          ),
        ],
      ),
    );
  }
}

class _DockTab extends StatelessWidget {
  const _DockTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion ? Duration.zero : _duration;
    final inactive = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkOnSurfaceVariant
        : const Color(0xFFCFC8DD);

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutBack,
          height: 48,
          constraints: const BoxConstraints(minWidth: 48),
          padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.cream : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: isActive ? AppColors.ink : inactive,
              ),
              AnimatedSize(
                duration: duration,
                curve: Curves.easeOutCubic,
                child: isActive
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          label,
                          style: AppTypography.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
