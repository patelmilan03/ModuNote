import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Rounded pastel tile with an icon, used at the top of empty states
/// (UI revamp 2026-11). [tintIndex] picks one of the five note tints.
class MNEmptyBadge extends StatelessWidget {
  const MNEmptyBadge({super.key, required this.icon, this.tintIndex = 2});

  final IconData icon;
  final int tintIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.tintOf(context, tintIndex),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, size: 32, color: Theme.of(context).colorScheme.onSurface),
    );
  }
}
