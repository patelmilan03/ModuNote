import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/note.dart';

/// Editor top bar: back button, title field, save/sync badge, ⋮ options.
class EditorAppBar extends StatelessWidget {
  const EditorAppBar({
    super.key,
    required this.isDirty,
    required this.syncStatus,
    required this.isDark,
    required this.titleController,
    required this.onBack,
    this.onMoreTap,
  });

  final bool isDirty;
  final SyncStatus syncStatus;
  final bool isDark;
  final TextEditingController titleController;
  final VoidCallback onBack;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back,
            color: onSurface,
            onTap: onBack,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: titleController,
              style: AppTypography.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: onSurface,
              ),
              decoration: InputDecoration.collapsed(
                hintText: 'Title…',
                hintStyle: AppTypography.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark
                      ? AppColors.darkOnSurfaceMuted
                      : AppColors.lightOnSurfaceMuted,
                ),
              ),
              maxLines: 1,
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(width: 6),
          _SaveBadge(isDirty: isDirty, syncStatus: syncStatus, isDark: isDark),
          const SizedBox(width: 6),
          _CircleIconButton(
            icon: Icons.more_vert,
            color: onMoreTap != null ? onSurface : onSurface.withValues(alpha: 0.35),
            onTap: onMoreTap,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

class _SaveBadge extends StatelessWidget {
  const _SaveBadge({
    required this.isDirty,
    required this.syncStatus,
    required this.isDark,
  });

  final bool isDirty;
  final SyncStatus syncStatus;
  final bool isDark;

  static const Color _localGrey = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    final surfaceContainer = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;
    final mutedColor =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    final Color dotColor;
    final String label;

    if (isDirty) {
      dotColor = mutedColor;
      label = 'Saving…';
    } else {
      switch (syncStatus) {
        case SyncStatus.pending:
          dotColor = AppColors.accent;
          label = 'Syncing…';
        case SyncStatus.synced:
          dotColor = AppColors.savedGreen;
          label = 'Synced';
        default:
          dotColor = _localGrey;
          label = 'Local';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
