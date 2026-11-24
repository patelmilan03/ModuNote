import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/note.dart';

/// Short relative time for a note's last edit ("Just now", "3h ago",
/// "Yesterday", "Nov 2"). Shared by the note card and Search results.
String noteTimestamp(DateTime updatedAt) {
  final now = DateTime.now();
  final diff = now.difference(updatedAt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  const mo = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final d = updatedAt;
  if (d.year == now.year) return '${mo[d.month - 1]} ${d.day}';
  return '${mo[d.month - 1]} ${d.day}, ${d.year}';
}


/// Purely presentational note card. No providers.
/// UI revamp: tinted by root category, 22 px radius, sized for the
/// two-column Home grid (title and preview up to 3 lines, 2 tags).
class MNNoteCard extends StatelessWidget {
  const MNNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.tagNames = const [],
    this.onLongPress,
    this.tintIndex,
  });

  /// Note tint index (0..4) from the note's root category, or null for a
  /// plain card. See `categoryTintIndexProvider`.
  final int? tintIndex;

  final Note note;
  final VoidCallback onTap;

  /// Resolved tag names for [note.tagIds]. Empty list shows no chip row.
  final List<String> tagNames;

  /// Optional long-press callback (e.g. opens an actions sheet).
  final VoidCallback? onLongPress;

  String _timestamp() => noteTimestamp(note.updatedAt);

  // Extracts plain-text preview from Quill Delta JSON.
  String _preview() {
    try {
      final ops = note.content['ops'] as List<dynamic>?;
      if (ops == null || ops.isEmpty) return '';
      final buf = StringBuffer();
      for (final op in ops) {
        final insert = (op as Map<String, dynamic>)['insert'];
        if (insert is String) buf.write(insert);
      }
      return buf.toString().replaceAll('\n', ' ').trim();
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    // Tinted by root category (UI revamp); no category → plain card.
    final tint = tintIndex == null ? null : AppColors.tintOf(context, tintIndex!);
    final cardBg = tint ?? AppColors.cardOf(context);
    final metaColor = tint != null ? cs.onSurfaceVariant : AppColors.mutedOf(context);
    // Pin icon: ink/cream on a light tint, the tint's stripe colour on dark.
    final pinColor = tint != null && isDark
        ? AppColors.tintStripes[tintIndex! % AppColors.tintStripes.length]
        : AppColors.accentOf(context);
    final chipBg = tint != null
        ? Colors.white.withValues(alpha: isDark ? 0.10 : 0.6)
        : (isDark ? AppColors.darkChipBg : AppColors.lightChipBg);
    final chipFg = cs.onSurface;

    final preview = _preview();
    final shownTags = tagNames.take(2).toList();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: tint == null ? Border.all(color: cs.outline) : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Meta row: pin · time ───────────────────────────────
            Row(
              children: [
                if (note.isPinned)
                  _PinPop(
                    reduceMotion: MediaQuery.of(context).disableAnimations,
                    child: Icon(Icons.push_pin_rounded,
                        size: 15, color: pinColor),
                  ),
                const Spacer(),
                Text(
                  _timestamp(),
                  style: AppTypography.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: metaColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // ── Title ───────────────────────────────────────────────
            Text(
              note.title.isEmpty ? 'Untitled' : note.title,
              style: AppTypography.heading(
                fontSize: 16.5,
                letterSpacing: -0.3,
                height: 1.2,
                color: cs.onSurface,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // ── Body preview ────────────────────────────────────────
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                preview,
                style: AppTypography.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant,
                ).copyWith(height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // ── Tag chips (max 2 in the two-column grid) ────────────
            if (shownTags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final t in shownTags)
                    _TagChip(label: '#$t', chipBg: chipBg, chipFg: chipFg),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.chipBg,
    required this.chipFg,
  });

  final String label;
  final Color chipBg;
  final Color chipFg;

  @override
  Widget build(BuildContext context) {
    // No `alignment` here: inside a Wrap it would stretch the chip full width.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: chipFg,
        ),
      ),
    );
  }
}

/// Pops the pin in with a small overshoot when a pinned card appears.
class _PinPop extends StatelessWidget {
  const _PinPop({required this.reduceMotion, required this.child});

  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.elasticOut,
      builder: (_, v, c) => Transform.scale(scale: v, child: c),
      child: child,
    );
  }
}
