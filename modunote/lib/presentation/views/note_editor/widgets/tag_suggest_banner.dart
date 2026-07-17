import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Dismissible banner of AI-suggested tags shown above the tag row.
/// Tapping a chip adds the tag; the × dismisses the banner.
class TagSuggestBanner extends StatelessWidget {
  const TagSuggestBanner({
    super.key,
    required this.suggestions,
    required this.isDark,
    required this.onAccept,
    required this.onDismiss,
  });

  final List<String> suggestions;
  final bool isDark;
  final void Function(String name) onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final variantColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final surfaceContainer = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.auto_awesome, size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested tags',
                  style: AppTypography.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: variantColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final name in suggestions)
                      GestureDetector(
                        onTap: () => onAccept(name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.40),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add,
                                  size: 13, color: AppColors.accent),
                              const SizedBox(width: 3),
                              Text(
                                name,
                                style: AppTypography.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close, size: 16, color: variantColor),
            ),
          ),
        ],
      ),
    );
  }
}
