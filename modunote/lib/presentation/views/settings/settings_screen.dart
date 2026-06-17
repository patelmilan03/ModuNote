import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../router/app_router.dart';

/// Settings screen — Appearance theme toggle.
/// The shell [_AppShell] provides the outer Scaffold and SafeArea;
/// this screen returns body content only (no Scaffold wrapper).
/// Spec: MODUNOTE_UI_REFERENCE.md § 3.6 | Decision: D9.5
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
      children: [
        _SettingsAppBar(isDark: isDark),
        const SizedBox(height: 16),
        _AppearanceCard(
          themeMode: themeMode,
          isDark: isDark,
          onSelectLight: () =>
              ref.read(themeModeNotifierProvider.notifier).setLight(),
          onSelectDark: () =>
              ref.read(themeModeNotifierProvider.notifier).setDark(),
        ),
      ],
    );
  }
}

// ── App bar ────────────────────────────────────────────────────────────────────

class _SettingsAppBar extends StatelessWidget {
  const _SettingsAppBar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Text(
        'Settings',
        style: AppTypography.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: onSurface,
        ),
      ),
    );
  }
}

// ── Appearance card ────────────────────────────────────────────────────────────

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({
    required this.themeMode,
    required this.isDark,
    required this.onSelectLight,
    required this.onSelectDark,
  });

  final ThemeMode themeMode;
  final bool isDark;
  final VoidCallback onSelectLight;
  final VoidCallback onSelectDark;

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Appearance',
            style: AppTypography.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how ModuNote looks on your device.',
            style: AppTypography.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: muted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ThemeTile(
                label: 'Light',
                icon: Icons.light_mode_outlined,
                isSelected: themeMode == ThemeMode.light,
                isDarkPreview: false,
                isDark: isDark,
                onTap: onSelectLight,
              ),
              const SizedBox(width: 10),
              _ThemeTile(
                label: 'Dark',
                icon: Icons.dark_mode_outlined,
                isSelected: themeMode == ThemeMode.dark,
                isDarkPreview: true,
                isDark: isDark,
                onTap: onSelectDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Theme tile ─────────────────────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDarkPreview,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDarkPreview;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
    final surfaceContainer =
        isDark ? AppColors.darkSurfaceContainer : AppColors.lightSurfaceContainer;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: isSelected ? cs.primaryContainer : surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: cs.primary, width: 2)
                : Border.all(color: outlineStrong, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniPreview(isDarkPreview: isDarkPreview),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? cs.onPrimaryContainer
                            : cs.onSurface,
                      ),
                    ),
                  ),
                  _RadioDot(isSelected: isSelected, isDark: isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini preview ───────────────────────────────────────────────────────────────

class _MiniPreview extends StatelessWidget {
  const _MiniPreview({required this.isDarkPreview});

  final bool isDarkPreview;

  @override
  Widget build(BuildContext context) {
    final cardBg =
        isDarkPreview ? AppColors.darkCard : AppColors.lightCard;
    final lineBg = isDarkPreview
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.lightSurfaceContainerHigh;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title line + accent dot
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: lineBg,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // Body line 1
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: lineBg,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          // Body line 2 (shorter)
          Container(
            height: 5,
            width: 60,
            decoration: BoxDecoration(
              color: lineBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Radio dot ─────────────────────────────────────────────────────────────────

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.isSelected, required this.isDark});

  final bool isSelected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? cs.primary : Colors.transparent,
        border: isSelected
            ? null
            : Border.all(color: outlineStrong, width: 1.5),
      ),
      child: isSelected
          ? const Center(
              child: Icon(Icons.circle, size: 8, color: Colors.white),
            )
          : null,
    );
  }
}
