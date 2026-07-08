import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/qna_answer.dart';
import '../../router/app_router.dart';
import '../../viewmodels/qna_view_model.dart';

/// RAG QnA screen (Phase 12 Stage 2) — ask questions about indexed notes.
/// Full-screen route outside the shell; pushed from the Home "Ask your notes"
/// card. Chat-style: question bubbles + grounded answer bubbles with citation
/// chips that deep-link to the source note.
class QnaScreen extends ConsumerStatefulWidget {
  const QnaScreen({super.key});

  @override
  ConsumerState<QnaScreen> createState() => _QnaScreenState();
}

class _QnaScreenState extends ConsumerState<QnaScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    _controller.clear();
    FocusScope.of(context).unfocus();
    ref.read(qnaViewModelProvider.notifier).ask(question);
    _scrollToBottomSoon();
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final turns = ref.watch(qnaViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-scroll when a new turn or answer lands.
    ref.listen(qnaViewModelProvider, (_, __) => _scrollToBottomSoon());

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(hasTurns: turns.isNotEmpty),
            Expanded(
              child: turns.isEmpty
                  ? const _QnaEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: turns.length,
                      itemBuilder: (_, i) => _TurnView(turn: turns[i]),
                    ),
            ),
            _InputBar(controller: _controller, onSend: _send),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  const _Header({required this.hasTurns});

  final bool hasTurns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
            tooltip: 'Back',
          ),
          Expanded(
            child: Text(
              'Ask your notes',
              style: AppTypography.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: cs.onSurface,
              ),
            ),
          ),
          if (hasTurns)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () =>
                  ref.read(qnaViewModelProvider.notifier).clear(),
              tooltip: 'Clear conversation',
            ),
        ],
      ),
    );
  }
}

// ─── One Q/A turn ───────────────────────────────────────────────────────────

class _TurnView extends StatelessWidget {
  const _TurnView({required this.turn});

  final QnaTurn turn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        _QuestionBubble(text: turn.question),
        const SizedBox(height: 8),
        turn.answer.when(
          loading: () => const _AnswerBubble(child: _ThinkingRow()),
          error: (error, _) =>
              _AnswerBubble(child: _ErrorContent(error: error)),
          data: (answer) => _AnswerBubble(child: _AnswerContent(answer: answer)),
        ),
      ],
    );
  }
}

class _QuestionBubble extends StatelessWidget {
  const _QuestionBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: AppTypography.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: cs.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _AnswerBubble extends StatelessWidget {
  const _AnswerBubble({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outline =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: outline, width: 0.5),
        ),
        child: child,
      ),
    );
  }
}

class _AnswerContent extends StatelessWidget {
  const _AnswerContent({required this.answer});

  final QnaAnswer answer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnswerText(answer.answer),
        if (answer.citations.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final citation in answer.citations)
                _CitationChip(citation: citation),
            ],
          ),
        ],
      ],
    );
  }
}

/// Error bubble that names the failing source instead of a generic
/// "unavailable": maps the [RemoteServiceException] status to a headline and
/// shows the backend's `detail` (or the network cause) underneath, so the
/// developer/user can tell a Groq/provider failure from an auth problem, a
/// rate limit, or an unreachable server — straight from the UI.
class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.error});

  final Object error;

  String get _headline {
    final e = error;
    if (e is! RemoteServiceException) {
      return 'Something went wrong while asking. Try again.';
    }
    final code = e.statusCode;
    if (code == null) {
      return "Couldn't reach the AI server — it may be waking up, or your "
          'connection blocked the request. Try again in a minute.';
    }
    if (code == 401 || code == 403) {
      return 'The AI server rejected the sign-in. Sign out and back in, '
          'then try again.';
    }
    if (code == 429) {
      return 'The AI is rate-limited right now. Wait a moment and retry.';
    }
    if (code == 502) {
      return 'An AI provider behind the server failed:';
    }
    if (code >= 500) {
      return 'The AI server hit an internal error (HTTP $code).';
    }
    return 'The AI request failed (HTTP $code).';
  }

  /// The backend's `detail` message, else the network-layer cause — whichever
  /// exists names the actual source of the failure.
  String? get _source {
    final e = error;
    if (e is! RemoteServiceException) return null;
    final text = e.detail ?? e.cause?.toString();
    if (text == null || text.trim().isEmpty) return null;
    return text.length > 220 ? '${text.substring(0, 220)}…' : text;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final source = _source;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 16, color: cs.error),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _headline,
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ).copyWith(height: 1.45),
              ),
            ),
          ],
        ),
        if (source != null) ...[
          const SizedBox(height: 6),
          Text(
            source,
            style: AppTypography.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: cs.onSurfaceVariant,
            ).copyWith(height: 1.4),
          ),
        ],
      ],
    );
  }
}

class _AnswerText extends StatelessWidget {
  const _AnswerText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: AppTypography.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: cs.onSurface,
      ).copyWith(height: 1.45),
    );
  }
}

class _CitationChip extends StatelessWidget {
  const _CitationChip({required this.citation});

  final Citation citation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = citation.title.trim().isEmpty
        ? 'Untitled note'
        : citation.title.trim();
    return GestureDetector(
      onTap: () => context.push(AppRoutes.editNotePath(citation.noteId)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 13,
              color: cs.onSecondaryContainer,
            ),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingRow extends StatelessWidget {
  const _ThinkingRow();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Text(
          'Searching your notes…',
          style: AppTypography.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Empty state ────────────────────────────────────────────────────────────

class _QnaEmptyState extends StatelessWidget {
  const _QnaEmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 52, color: muted),
            const SizedBox(height: 16),
            Text(
              'Ask anything about your notes',
              textAlign: TextAlign.center,
              style: AppTypography.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Answers come from notes tagged #study, #notes, or #research. '
              'Tag and reopen a few notes to index them.',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: muted,
              ).copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Input bar ──────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg =
        isDark ? AppColors.darkSurfaceContainer : AppColors.lightSurfaceContainer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: AppTypography.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Ask a question…',
                filled: true,
                fillColor: fieldBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: cs.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSend,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 22,
                  color: cs.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
