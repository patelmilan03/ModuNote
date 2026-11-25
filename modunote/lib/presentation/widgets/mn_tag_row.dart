import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/tag.dart';

/// Category + tag chips, wrapped, inside the tinted editor header.
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
    this.maxTagsReached = false,
  });

  final List<String> tagIds;
  final List<Tag> allTags;
  final String? categoryName;
  final void Function(String tagId) onRemoveTag;
  final VoidCallback onAddTagTap;
  final VoidCallback onCategoryTap;
  final bool maxTagsReached;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _CategoryChip(
          label: categoryName ?? 'No category',
          onTap: onCategoryTap,
          isDark: isDark,
        ),
        for (final tagId in tagIds)
          _TagChip(
            label: _resolveName(tagId),
            tagName: _rawName(tagId),
            onDismiss: () => onRemoveTag(tagId),
            isDark: isDark,
          ),
        _AddTagChip(
          onTap: maxTagsReached ? null : onAddTagTap,
          isDark: isDark,
          disabled: maxTagsReached,
        ),
      ],
    );
  }

  String _rawName(String tagId) {
    for (final t in allTags) {
      if (t.id == tagId) return t.name;
    }
    return tagId;
  }

  String _resolveName(String tagId) => '#${_rawName(tagId)}';
}

/// Chip fill on the tinted editor header: white over light tints, a faint
/// cream wash over dark ones.
Color _chipFill(bool isDark, {required bool strong}) => isDark
    ? AppColors.cream.withValues(alpha: strong ? 0.14 : 0.09)
    : Colors.white.withValues(alpha: strong ? 0.8 : 0.6);

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
    final fg = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return Semantics(
      button: true,
      label: 'Category: $label',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _chipFill(isDark, strong: true),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_outlined, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dismissible tag chip, in the tag's own colour.
class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.tagName,
    required this.onDismiss,
    required this.isDark,
  });

  final String label;
  final String tagName;
  final VoidCallback onDismiss;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return Container(
      height: 32,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: AppColors.tagTintOf(context, tagName),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.tagStripeOf(tagName)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          Semantics(
            button: true,
            label: 'Remove $label',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: SizedBox(
                width: 26,
                height: 32,
                child: Icon(Icons.close_rounded,
                    size: 14, color: fg.withValues(alpha: 0.6)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed "+ tag" chip that opens the tag input sheet.
/// When [disabled] is true the chip renders at reduced opacity and ignores taps.
class _AddTagChip extends StatelessWidget {
  const _AddTagChip({
    required this.onTap,
    required this.isDark,
    this.disabled = false,
  });

  final VoidCallback? onTap;
  final bool isDark;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: 'Add tag',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Opacity(
          opacity: disabled ? 0.4 : 1.0,
          child: CustomPaint(
            painter: _DashedPillPainter(color: fg.withValues(alpha: 0.4)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
              child: Text(
                '+ tag',
                style: AppTypography.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a 1.5 px dashed pill outline (Flutter borders can't dash).
class _DashedPillPainter extends CustomPainter {
  const _DashedPillPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 1.5;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const dash = 4.0, gap = 3.0;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPillPainter old) => old.color != color;
}
