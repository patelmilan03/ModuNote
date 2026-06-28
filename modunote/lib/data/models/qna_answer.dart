import 'package:equatable/equatable.dart';

/// A source note a RAG answer drew from (Phase 12 Stage 2).
class Citation extends Equatable {
  const Citation({
    required this.noteId,
    required this.title,
    required this.snippet,
  });

  factory Citation.fromJson(Map<String, dynamic> json) => Citation(
        noteId: json['note_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        snippet: json['snippet'] as String? ?? '',
      );

  final String noteId;
  final String title;
  final String snippet;

  @override
  List<Object?> get props => [noteId, title, snippet];
}

/// A grounded answer to a QnA question plus the notes it cited.
class QnaAnswer extends Equatable {
  const QnaAnswer({required this.answer, this.citations = const []});

  factory QnaAnswer.fromJson(Map<String, dynamic> json) => QnaAnswer(
        answer: json['answer'] as String? ?? '',
        citations: (json['citations'] as List<dynamic>? ?? [])
            .map((c) => Citation.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  final String answer;
  final List<Citation> citations;

  @override
  List<Object?> get props => [answer, citations];
}
