import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../router/app_router.dart';

/// Persistent floating pill bottom nav rendered by the GoRouter ShellRoute.
/// Never instantiated per-screen — rendered once by [_AppShell] in app_router.dart.
/// Layout: 2 tabs | center gap (FAB notch) | 2 tabs.
/// Spec: MODUNOTE_UI_REFERENCE.md § 2.5
class MNBottomNav extends StatelessWidget {
  const MNBottomNav({super.key, required this.activeIndex});

  /// 0 = Home, 1 = Explore, 2 = Tags, 3 = Settings.
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: outlineStrong, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF1C1B2E).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _NavTab(
            icon: Icons.article_outlined,
            activeIcon: Icons.article,
            label: 'Home',
            isActive: activeIndex == 0,
            onTap: () => context.go(AppRoutes.home),
          ),
          _NavTab(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            label: 'Explore',
            isActive: activeIndex == 1,
            onTap: () => context.go(AppRoutes.search),
          ),
          // Center gap — the protruding FAB sits here (rendered by _AppShell).
          const SizedBox(width: 60),
          _NavTab(
            icon: Icons.label_outline,
            activeIcon: Icons.label,
            label: 'Tags',
            isActive: activeIndex == 2,
            onTap: () => context.go(AppRoutes.tags),
          ),
          _NavTab(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Settings',
            isActive: activeIndex == 3,
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
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryContainer = isDark
        ? AppColors.darkPrimaryContainer
        : AppColors.lightPrimaryContainer;
    final onPrimaryContainer = isDark
        ? AppColors.darkOnPrimaryContainer
        : AppColors.lightOnPrimaryContainer;
    final variantColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            decoration: isActive
                ? BoxDecoration(
                    color: primaryContainer,
                    borderRadius: BorderRadius.circular(26),
                  )
                : null,
            child: Center(
              child: Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: isActive ? onPrimaryContainer : variantColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
