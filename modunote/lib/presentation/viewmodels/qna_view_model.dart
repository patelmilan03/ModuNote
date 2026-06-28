import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/qna_answer.dart';
import '../../services/remote/remote_note_service_provider.dart';

part 'qna_view_model.g.dart';

/// One question/answer exchange in the RAG QnA chat (Phase 12 Stage 2).
class QnaTurn {
  const QnaTurn({required this.question, required this.answer});

  final String question;
  final AsyncValue<QnaAnswer> answer;

  QnaTurn copyWith({AsyncValue<QnaAnswer>? answer}) =>
      QnaTurn(question: question, answer: answer ?? this.answer);
}

/// Holds the QnA conversation turns and their in-flight/answer state.
///
/// Auto-disposed: each time the QnA screen is opened it starts a fresh session.
/// The backend (RAG) does the retrieval; this VM only orchestrates calls and
/// never blocks the UI — each turn carries its own [AsyncValue].
@riverpod
class QnaViewModel extends _$QnaViewModel {
  @override
  List<QnaTurn> build() => const [];

  /// Asks a question: appends a loading turn, then resolves it with the answer
  /// or an error. Failures surface in the turn, never as a thrown exception.
  Future<void> ask(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    final index = state.length;
    state = [
      ...state,
      QnaTurn(question: trimmed, answer: const AsyncLoading()),
    ];

    try {
      final answer = await ref.read(remoteNoteServiceProvider).ask(
            question: trimmed,
          );
      _updateTurn(index, AsyncData(answer));
    } catch (error, stackTrace) {
      _updateTurn(index, AsyncError(error, stackTrace));
    }
  }

  void _updateTurn(int index, AsyncValue<QnaAnswer> answer) {
    if (index < 0 || index >= state.length) return;
    final next = [...state];
    next[index] = next[index].copyWith(answer: answer);
    state = next;
  }

  /// Clears the conversation.
  void clear() => state = const [];
}
