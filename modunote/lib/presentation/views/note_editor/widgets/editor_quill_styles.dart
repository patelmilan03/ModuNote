import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Quill body styles for the revamp: Inter 15 body, Bricolage headings,
/// rounded checklist boxes and a coral-ruled quote block.
DefaultStyles buildEditorStyles(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final onSurface = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
  final variant =
      isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
  final coral = AppColors.accentOf(context);

  final body = AppTypography.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: onSurface,
  ).copyWith(height: 1.5);
  const none = HorizontalSpacing(0, 0);

  DefaultTextBlockStyle heading(double size) => DefaultTextBlockStyle(
        AppTypography.heading(
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          height: 1.2,
          color: onSurface,
        ),
        none,
        const VerticalSpacing(16, 4),
        VerticalSpacing.zero,
        null,
      );

  return DefaultStyles(
    paragraph: DefaultTextBlockStyle(
        body, none, const VerticalSpacing(2, 2), VerticalSpacing.zero, null),
    h1: heading(24),
    h2: heading(19),
    h3: heading(16),
    lists: DefaultListBlockStyle(
      body,
      none,
      const VerticalSpacing(4, 4),
      const VerticalSpacing(0, 6),
      null,
      _MNCheckboxBuilder(isDark: isDark),
    ),
    quote: DefaultTextBlockStyle(
      body.copyWith(
        fontStyle: FontStyle.italic,
        fontSize: 14,
        color: variant,
      ),
      const HorizontalSpacing(14, 0),
      const VerticalSpacing(10, 10),
      const VerticalSpacing(4, 4),
      BoxDecoration(
        color: onSurface.withValues(alpha: 0.05),
        border: Border(left: BorderSide(color: coral, width: 4)),
      ),
    ),
  );
}

/// 22 px rounded checkbox: ink fill + cream tick when done (inverted in dark
/// mode), a soft outline when open. The fill animates in.
class _MNCheckboxBuilder implements QuillCheckboxBuilder {
  const _MNCheckboxBuilder({required this.isDark});

  final bool isDark;

  @override
  Widget build({
    required BuildContext context,
    required bool isChecked,
    required ValueChanged<bool> onChanged,
  }) {
    final fill = isDark ? AppColors.cream : AppColors.ink;
    final tick = isDark ? AppColors.darkBg : AppColors.lightBg;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      checked: isChecked,
      label: 'Checklist item',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!isChecked),
        // Quill gives the leading slot 2 × font size (30 px) of width.
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isChecked ? fill : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: isChecked ? fill : fill.withValues(alpha: 0.4),
                width: 1.8,
              ),
            ),
            child: AnimatedScale(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              scale: isChecked ? 1 : 0,
              child: Icon(Icons.check_rounded, size: 16, color: tick),
            ),
          ),
        ),
      ),
    );
  }
}
