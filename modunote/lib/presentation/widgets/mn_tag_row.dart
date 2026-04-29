import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/tag.dart';

/// Tag/category strip that sits between the Quill editor body and the toolbar.
/// Purely presentational — all state callbacks are passed from NoteEditorScreen.
/// Spec: MODUNOTE_UI_REFERENCE.md § 3.4
class MNTagRow extends StatelessWidget {
  const MNTagRow({
    super.key,
    required this.tagIds,
    required this.allTags,
    required this.categoryName,
    required this.onRemoveTag,
    required this.onAddTagTap,
    required this.onCategoryTap,
    required this.onMicTap,
    required this.isRecording,
  });

  final List<String> tagIds;
  final List<Tag> allTags;
  final String? categoryName;
  final void Function(String tagId) onRemoveTag;
  final VoidCallback onAddTagTap;
  final VoidCallback onCategoryTap;
  final VoidCallback onMicTap;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final surfaceBg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Container(
      decoration: BoxDecoration(
        color: surfaceBg,
        border: Border(top: BorderSide(color: outlineColor, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          _CategoryChip(
            label: categoryName ?? 'No category',
            onTap: onCategoryTap,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tagId in tagIds) ...[
                    _TagChip(
                      label: _resolveName(tagId),
                      onDismiss: () => onRemoveTag(tagId),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                  ],
                  _AddTagChip(onTap: onAddTagTap, isDark: isDark),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _MicButton(
            isRecording: isRecording,
            onTap: onMicTap,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  String _resolveName(String tagId) {
    try {
      return '#${allTags.firstWhere((t) => t.id == tagId).name}';
    } catch (_) {
      return '#$tagId';
    }
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceContainer = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;
    final outlineColor =
        isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final variantColor =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
    final mutedColor =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: surfaceContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: outlineColor, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 14, color: variantColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: variantColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 12, color: mutedColor),
          ],
        ),
      ),
    );
  }
}

/// Dismissible sm filled tag chip.
class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.onDismiss,
    required this.isDark,
  });

  final String label;
  final VoidCallback onDismiss;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final chipBg = isDark ? AppColors.darkChipBg : AppColors.lightChipBg;
    final chipText = isDark ? AppColors.darkChipText : AppColors.lightChipText;

    return Container(
      height: 24,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: chipText,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.08),
              ),
              child: Icon(Icons.close, size: 10, color: chipText),
            ),
          ),
        ],
      ),
    );
  }
}

/// "+ tag" outlined chip that opens the tag input dialog.
class _AddTagChip extends StatelessWidget {
  const _AddTagChip({required this.onTap, required this.isDark});

  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
    final variantColor =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: outlineStrong,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Text(
            '+ tag',
            style: AppTypography.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: variantColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.isRecording,
    required this.onTap,
    required this.isDark,
  });

  final bool isRecording;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primaryContainer = isDark
        ? AppColors.darkPrimaryContainer
        : AppColors.lightPrimaryContainer;
    final onPrimaryContainer = isDark
        ? AppColors.darkOnPrimaryContainer
        : AppColors.lightOnPrimaryContainer;
    final recordRed =
        isDark ? AppColors.darkRecordRed : AppColors.lightRecordRed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isRecording ? recordRed : primaryContainer,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isRecording
              ? [
                  BoxShadow(
                    color: recordRed.withValues(alpha: 0.15),
                    blurRadius: 0,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: isRecording
            ? Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )
            : Icon(Icons.mic, size: 20, color: onPrimaryContainer),
      ),
    );
  }
}
