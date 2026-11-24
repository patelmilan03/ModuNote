import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Back arrow + "Settings" heading. Settings is a pushed screen (opened from
/// the Home avatar) since the UI revamp, so it carries its own back button.
class SettingsAppBar extends StatelessWidget {
  const SettingsAppBar({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return Padding(
      // Pull the back arrow into the 20 px gutter so the title aligns
      // with the cards below.
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Row(
        children: [
          Transform.translate(
            offset: const Offset(-10, 0),
            child: IconButton(
              onPressed: () => context.canPop() ? context.pop() : null,
              icon: Icon(Icons.arrow_back_rounded, color: onSurface, size: 26),
              tooltip: 'Back',
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(44, 44),
              ),
            ),
          ),
          const SizedBox(width: 0),
          Text(
            'Settings',
            style: AppTypography.heading(
              fontSize: 30,
              letterSpacing: -0.5,
              color: onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
