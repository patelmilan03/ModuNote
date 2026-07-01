import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/data/models/qna_answer.dart';

void main() {
  group('Citation.fromJson', () {
    test('parses a full payload', () {
      final c = Citation.fromJson(const {
        'note_id': 'n1',
        'title': 'Pasta',
        'snippet': 'cook for 9 minutes',
      });
      expect(c.noteId, 'n1');
      expect(c.title, 'Pasta');
      expect(c.snippet, 'cook for 9 minutes');
    });

    test('falls back to empty strings for missing/null keys', () {
      final c = Citation.fromJson(const {'note_id': null});
      expect(c.noteId, '');
      expect(c.title, '');
      expect(c.snippet, '');
    });

    test('value equality', () {
      const a = Citation(noteId: 'n1', title: 't', snippet: 's');
      const b = Citation(noteId: 'n1', title: 't', snippet: 's');
      expect(a, equals(b));
    });
  });

  group('QnaAnswer.fromJson', () {
    test('parses answer + nested citations', () {
      final a = QnaAnswer.fromJson(const {
        'answer': 'You cook pasta for 9 minutes.',
        'citations': [
          {'note_id': 'n1', 'title': 'Pasta', 'snippet': '9 minutes'},
        ],
      });
      expect(a.answer, 'You cook pasta for 9 minutes.');
      expect(a.citations, hasLength(1));
      expect(a.citations.single.noteId, 'n1');
    });

    test('defaults to empty answer + empty citations when keys absent', () {
      final a = QnaAnswer.fromJson(const {});
      expect(a.answer, '');
      expect(a.citations, isEmpty);
    });

    test('handles a null citations list', () {
      final a = QnaAnswer.fromJson(const {'answer': 'hi', 'citations': null});
      expect(a.answer, 'hi');
      expect(a.citations, isEmpty);
    });

    test('value equality includes citations', () {
      const a = QnaAnswer(
        answer: 'x',
        citations: [Citation(noteId: 'n', title: 't', snippet: 's')],
      );
      const b = QnaAnswer(
        answer: 'x',
        citations: [Citation(noteId: 'n', title: 't', snippet: 's')],
      );
      expect(a, equals(b));
    });
  });
}
