import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/note.dart';

/// Editor header block (UI revamp 2026-11): a panel in the note's category
/// tint with a 30 px bottom radius. Holds back · save pill · more, the 30 px
/// title, and [bottom] (the category / tag chips).
class EditorAppBar extends StatelessWidget {
  const EditorAppBar({
    super.key,
    required this.isDirty,
    required this.syncStatus,
    required this.isDark,
    required this.titleController,
    required this.onBack,
    required this.tint,
    this.onMoreTap,
    this.bottom,
  });

  final bool isDirty;
  final SyncStatus syncStatus;
  final bool isDark;
  final TextEditingController titleController;
  final VoidCallback onBack;

  /// Panel colour: the root category's tint, or the surface container when
  /// the note has no category.
  final Color tint;
  final VoidCallback? onMoreTap;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final muted = isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final titleStyle = AppTypography.heading(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      height: 1.1,
      color: onSurface,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
          8, MediaQuery.paddingOf(context).top + 6, 8, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleIconButton(
                icon: Icons.arrow_back_rounded,
                color: onSurface,
                onTap: onBack,
                tooltip: 'Back',
              ),
              const Spacer(),
              _SaveBadge(
                  isDirty: isDirty, syncStatus: syncStatus, isDark: isDark),
              const Spacer(),
              _CircleIconButton(
                icon: Icons.more_horiz_rounded,
                color: onMoreTap != null
                    ? onSurface
                    : onSurface.withValues(alpha: 0.35),
                onTap: onMoreTap,
                tooltip: 'Note options',
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: TextField(
              controller: titleController,
              style: titleStyle,
              decoration: InputDecoration.collapsed(
                hintText: 'Title',
                hintStyle: titleStyle.copyWith(color: muted),
              ),
              minLines: 1,
              maxLines: 3,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          if (bottom != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: bottom,
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
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 26, color: color),
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        disabledForegroundColor: color,
      ),
    );
  }
}

/// "Saved" pill: a dot plus a short label for the save / sync state.
class _SaveBadge extends StatelessWidget {
  const _SaveBadge({
    required this.isDirty,
    required this.syncStatus,
    required this.isDark,
  });

  final bool isDirty;
  final SyncStatus syncStatus;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final mutedColor =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final green = isDark ? AppColors.darkSavedGreen : AppColors.savedGreen;

    final Color dotColor;
    final String label;

    if (isDirty) {
      dotColor = mutedColor;
      label = 'Saving…';
    } else {
      switch (syncStatus) {
        case SyncStatus.pending:
          dotColor = AppColors.accentOf(context);
          label = 'Syncing…';
        case SyncStatus.synced:
          dotColor = green;
          label = 'Synced';
        default:
          // Saved on this device (not backed up to the cloud yet).
          dotColor = green;
          label = 'Saved';
      }
    }

    return Semantics(
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 11),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cream.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: dotColor),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
