import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/quill_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/note.dart';
import '../../../../services/remote/remote_note_service_provider.dart';
import 'note_options_sheet.dart';

class _AiAction {
  const _AiAction(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

const List<_AiAction> _kAiActions = [
  _AiAction('improve', 'Improve', Icons.auto_fix_high),
  _AiAction('humanize', 'Humanize', Icons.record_voice_over_outlined),
  _AiAction('paraphrase', 'Paraphrase', Icons.short_text),
  _AiAction('script', 'Format as script', Icons.movie_outlined),
  _AiAction('critique', 'Critique', Icons.rate_review_outlined),
  _AiAction('summary', 'Summarise', Icons.notes_outlined),
];

/// Bottom sheet of Groq-powered writing actions. Calls the backend and lets the
/// user Insert / Replace / Copy the result. Spec: PHASE_12_PLAN.md Stage 1.
class AiToolsSheet extends ConsumerStatefulWidget {
  const AiToolsSheet({
    super.key,
    required this.note,
    required this.tagNames,
    required this.onInsert,
    required this.onReplace,
    required this.onInsertSummary,
    this.contentOverride,
  });

  final Note note;
  final List<String> tagNames;

  /// When set, the AI acts on this text instead of the note body (e.g. a voice
  /// transcript being paraphrased).
  final String? contentOverride;
  final void Function(String text) onInsert;
  final void Function(String text) onReplace;
  final void Function(String summary) onInsertSummary;

  @override
  ConsumerState<AiToolsSheet> createState() => _AiToolsSheetState();
}

class _AiToolsSheetState extends ConsumerState<AiToolsSheet> {
  _AiAction? _action;
  bool _loading = false;
  String? _result;
  bool _failed = false;

  Future<void> _run(_AiAction action) async {
    setState(() {
      _action = action;
      _loading = true;
      _result = null;
      _failed = false;
    });
    final svc = ref.read(remoteNoteServiceProvider);
    final content =
        widget.contentOverride ?? plainTextFromDelta(widget.note.content);
    try {
      final out = action.id == 'summary'
          ? await svc.summariseNote(
              noteId: widget.note.id,
              title: widget.note.title,
              content: content,
            )
          : await svc.assist(
              noteId: widget.note.id,
              action: action.id,
              title: widget.note.title,
              content: content,
              tags: widget.tagNames,
            );
      if (mounted) {
        setState(() {
          _result = out;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  void _reset() => setState(() {
        _action = null;
        _result = null;
        _failed = false;
      });

  void _copy(String text) {
    final messenger = ScaffoldMessenger.of(context);
    Clipboard.setData(ClipboardData(text: text));
    Navigator.of(context).pop();
    messenger.showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final variantColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: outlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    _action == null ? 'AI assist' : _action!.label,
                    style: AppTypography.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
            ),
            _buildBody(isDark, onSurface, variantColor),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark, Color onSurface, Color variantColor) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 2.5),
              const SizedBox(height: 14),
              Text(
                'Thinking…',
                style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: variantColor),
              ),
            ],
          ),
        ),
      );
    }

    if (_failed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI request failed — try again.',
              style: AppTypography.inter(
                  fontSize: 14, fontWeight: FontWeight.w500, color: onSurface),
            ),
            const SizedBox(height: 12),
            _AiSheetButton(
              label: 'Back',
              icon: Icons.arrow_back,
              filled: false,
              isDark: isDark,
              onTap: _reset,
            ),
          ],
        ),
      );
    }

    if (_result != null) {
      final isSummary = _action?.id == 'summary';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SelectableText(
                _result!,
                style: AppTypography.inter(
                    fontSize: 14, fontWeight: FontWeight.w400, color: onSurface),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isSummary)
                  _AiSheetButton(
                    label: 'Insert as quote',
                    icon: Icons.format_quote,
                    filled: true,
                    isDark: isDark,
                    onTap: () {
                      widget.onInsertSummary(_result!);
                      Navigator.of(context).pop();
                    },
                  )
                else ...[
                  _AiSheetButton(
                    label: 'Insert',
                    icon: Icons.south,
                    filled: true,
                    isDark: isDark,
                    onTap: () {
                      widget.onInsert(_result!);
                      Navigator.of(context).pop();
                    },
                  ),
                  _AiSheetButton(
                    label: 'Replace',
                    icon: Icons.swap_horiz,
                    filled: false,
                    isDark: isDark,
                    onTap: () {
                      widget.onReplace(_result!);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
                _AiSheetButton(
                  label: 'Copy',
                  icon: Icons.copy_outlined,
                  filled: false,
                  isDark: isDark,
                  onTap: () => _copy(_result!),
                ),
                _AiSheetButton(
                  label: 'Back',
                  icon: Icons.arrow_back,
                  filled: false,
                  isDark: isDark,
                  onTap: _reset,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Action list
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final action in _kAiActions)
          OptionsRow(
            icon: action.icon,
            label: action.label,
            color: onSurface,
            onTap: () => _run(action),
          ),
      ],
    );
  }
}

class _AiSheetButton extends StatelessWidget {
  const _AiSheetButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final variantColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final fg = filled ? AppColors.accentOn : variantColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: filled
              ? null
              : Border.all(
                  color: variantColor.withValues(alpha: 0.4), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
