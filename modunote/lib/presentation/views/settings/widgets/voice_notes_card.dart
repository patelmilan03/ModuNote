import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'settings_icon_tile.dart';

/// "Confirm before deleting voice notes" toggle card.
class VoiceNotesCard extends StatelessWidget {
  const VoiceNotesCard({
    super.key,
    required this.isDark,
    required this.confirmDelete,
    required this.onChanged,
  });

  final bool isDark;
  final bool confirmDelete;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outline = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final surfaceContainer = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: outline),
      ),
      child: Row(
        children: [
          const SettingsIconTile(icon: Icons.mic_none_rounded, tintIndex: 0),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Confirm before deleting voice notes',
                  style: AppTypography.heading(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ask for confirmation when removing a recording.',
                  style: AppTypography.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: confirmDelete,
            onChanged: onChanged,
            // Explicit colors so BOTH states read clearly in light & dark
            // (the default off-state thumb/track was hard to see).
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.accentOn
                  : muted,
            ),
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.accentOf(context)
                  : surfaceContainer,
            ),
            trackOutlineColor: WidgetStateProperty.all(outline),
          ),
        ],
      ),
    );
  }
}
