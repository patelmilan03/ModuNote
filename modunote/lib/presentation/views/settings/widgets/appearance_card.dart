import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Appearance card — Light / Dark / System theme tiles with mini previews.
class AppearanceCard extends StatelessWidget {
  const AppearanceCard({
    super.key,
    required this.themeMode,
    required this.isDark,
    required this.onSelectLight,
    required this.onSelectDark,
    required this.onSelectSystem,
  });

  final ThemeMode themeMode;
  final bool isDark;
  final VoidCallback onSelectLight;
  final VoidCallback onSelectDark;
  final VoidCallback onSelectSystem;

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
                previewType: _PreviewType.light,
                isDark: isDark,
                onTap: onSelectLight,
              ),
              const SizedBox(width: 8),
              _ThemeTile(
                label: 'Dark',
                icon: Icons.dark_mode_outlined,
                isSelected: themeMode == ThemeMode.dark,
                previewType: _PreviewType.dark,
                isDark: isDark,
                onTap: onSelectDark,
              ),
              const SizedBox(width: 8),
              _ThemeTile(
                label: 'System',
                icon: Icons.brightness_auto_outlined,
                isSelected: themeMode == ThemeMode.system,
                previewType: _PreviewType.system,
                isDark: isDark,
                onTap: onSelectSystem,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Theme tile ─────────────────────────────────────────────────────────────────

enum _PreviewType { light, dark, system }

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.previewType,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final _PreviewType previewType;
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
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
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
              _MiniPreview(previewType: previewType),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.plusJakartaSans(
                        fontSize: 12,
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
  const _MiniPreview({required this.previewType});

  final _PreviewType previewType;

  @override
  Widget build(BuildContext context) {
    if (previewType == _PreviewType.system) {
      return _SystemMiniPreview();
    }
    final isDarkPreview = previewType == _PreviewType.dark;
    final cardBg =
        isDarkPreview ? AppColors.darkCard : AppColors.lightCard;
    final lineBg = isDarkPreview
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.lightSurfaceContainerHigh;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: lineBg,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: lineBg,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 5,
            width: 40,
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

class _SystemMiniPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: Container(
                color: AppColors.lightCard,
                child: const Center(
                  child: Icon(Icons.light_mode_outlined,
                      size: 18, color: AppColors.lightPrimary),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.darkCard,
                child: const Center(
                  child: Icon(Icons.dark_mode_outlined,
                      size: 18, color: AppColors.darkPrimary),
                ),
              ),
            ),
          ],
        ),
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
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? cs.primary : Colors.transparent,
        border: isSelected
            ? null
            : Border.all(color: outlineStrong, width: 1.5),
      ),
      child: isSelected
          ? const Center(
              child: Icon(Icons.circle, size: 7, color: Colors.white),
            )
          : null,
    );
  }
}
