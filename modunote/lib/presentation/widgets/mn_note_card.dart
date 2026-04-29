import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/note.dart';

/// Purely presentational note card. No providers.
/// Spec: MODUNOTE_UI_REFERENCE.md § 2.3
class MNNoteCard extends StatelessWidget {
  const MNNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.tagNames = const [],
  });

  final Note note;
  final VoidCallback onTap;

  /// Resolved tag names for [note.tagIds]. Empty list shows no chip row.
  final List<String> tagNames;

  String _timestamp() {
    final now = DateTime.now();
    final diff = now.difference(note.updatedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const mo = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = note.updatedAt;
    if (d.year == now.year) return '${mo[d.month - 1]} ${d.day}';
    return '${mo[d.month - 1]} ${d.day}, ${d.year}';
  }

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

    final cardBg = note.isPinned
        ? (isDark ? AppColors.darkCard : AppColors.lightPinTint)
        : (isDark ? AppColors.darkCard : AppColors.lightCard);

    // rgba(245,158,11,0.35) ≈ 0x59
    final borderColor = note.isPinned
        ? const Color(0x59F59E0B)
        : cs.outline;

    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final chipBg =
        isDark ? AppColors.darkChipBg : AppColors.lightChipBg;
    final chipFg =
        isDark ? AppColors.darkChipText : AppColors.lightChipText;

    final preview = _preview();
    final shownTags = tagNames.take(3).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header row ──────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.isPinned) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.push_pin,
                      size: 14,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    note.title.isEmpty ? 'Untitled' : note.title,
                    style: AppTypography.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _timestamp(),
                    style: AppTypography.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: muted,
                    ),
                  ),
                ),
              ],
            ),
            // ── Body preview ────────────────────────────────────────
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                preview,
                style: AppTypography.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // ── Tag chips ───────────────────────────────────────────
            if (shownTags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: shownTags
                    .map(
                      (name) => _TagChip(
                        label: '#$name',
                        chipBg: chipBg,
                        chipFg: chipFg,
                      ),
                    )
                    .toList(),
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
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
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
