import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 34 px rounded pastel tile behind a Settings row icon (UI revamp 2026-11).
class SettingsIconTile extends StatelessWidget {
  const SettingsIconTile({super.key, required this.icon, required this.tintIndex});

  final IconData icon;
  final int tintIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.tintOf(context, tintIndex),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
    );
  }
}
