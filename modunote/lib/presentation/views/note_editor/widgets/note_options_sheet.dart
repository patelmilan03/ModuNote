import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/note.dart';

/// Bottom sheet shown from the ⋮ button in [EditorAppBar].
/// Offers AI assist, Pin/Unpin, Archive, and Delete.
class NoteOptionsSheet extends StatelessWidget {
  const NoteOptionsSheet({
    super.key,
    required this.note,
    required this.onAiAssist,
    required this.onPin,
    required this.onArchive,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onAiAssist;
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
          // Grabber
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
          OptionsRow(
            icon: Icons.auto_awesome,
            label: 'AI assist',
            color: AppColors.accent,
            onTap: onAiAssist,
          ),
          OptionsRow(
            icon: note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: note.isPinned ? 'Unpin' : 'Pin to top',
            color: variantColor,
            onTap: onPin,
          ),
          OptionsRow(
            icon: Icons.archive_outlined,
            label: 'Archive',
            color: variantColor,
            onTap: onArchive,
          ),
          OptionsRow(
            icon: Icons.delete_outline,
            label: 'Delete note',
            color: errorColor,
            onTap: onDelete,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// One icon + label row inside an editor bottom sheet. Public because it is
/// shared by [NoteOptionsSheet] and the AI tools sheet's action list.
class OptionsRow extends StatelessWidget {
  const OptionsRow({
    super.key,
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
