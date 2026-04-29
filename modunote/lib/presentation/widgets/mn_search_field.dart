import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Non-editable search affordance. Tap navigates to the search screen.
/// Spec: MODUNOTE_UI_REFERENCE.md § 2.2
class MNSearchField extends StatelessWidget {
  const MNSearchField({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: muted),
            const SizedBox(width: 10),
            Text(
              'Search notes, tags…',
              style: AppTypography.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
