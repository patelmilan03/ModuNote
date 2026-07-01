import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:modunote/core/errors/app_exception.dart';
import 'package:modunote/services/remote/remote_note_service.dart';

void main() {
  // Fixed base URL so requests are deterministic (no --dart-define). The
  // Firebase ID token isn't attached here — FirebaseAuth isn't initialised in
  // unit tests, so `_idToken()` returns null and no Authorization header is set.
  RemoteNoteService service() =>
      RemoteNoteService(baseUrl: 'https://api.test/api/v1');

  // Runs [body] with the top-level http functions routed through [handler].
  Future<T> withHandler<T>(
    Future<T> Function() body,
    Future<http.Response> Function(http.Request) handler,
  ) =>
      http.runWithClient(body, () => MockClient(handler));

  group('RemoteNoteService.assist', () {
    test('returns the result and sends the correct request + JSON body',
        () async {
      late http.Request captured;
      final result = await withHandler(
        () => service().assist(
          noteId: 'n1',
          action: 'improve',
          title: 'T',
          content: 'C',
          tags: const ['study'],
        ),
        (req) async {
          captured = req;
          return http.Response(jsonEncode({'result': 'improved text'}), 200);
        },
      );

      expect(result, 'improved text');
      expect(captured.method, 'POST');
      expect(captured.url.toString(), 'https://api.test/api/v1/notes/n1/assist');
      expect(captured.headers['Content-Type'], contains('application/json'));
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['action'], 'improve');
      expect(body['tags'], ['study']);
    });

    test('throws RemoteServiceException on a non-200 status', () async {
      expect(
        () => withHandler(
          () => service().assist(
            noteId: 'n1',
            action: 'improve',
            title: 'T',
            content: 'C',
          ),
          (_) async => http.Response('nope', 500),
        ),
        throwsA(
          isA<RemoteServiceException>().having(
            (e) => e.message,
            'message',
            contains('500'),
          ),
        ),
      );
    });

  });

  group('RemoteNoteService.ask', () {
    test('parses the QnaAnswer payload', () async {
      final answer = await withHandler(
        () => service().ask(question: 'How long to cook pasta?'),
        (_) async => http.Response(
          jsonEncode({
            'answer': '9 minutes',
            'citations': [
              {'note_id': 'n1', 'title': 'Pasta', 'snippet': '9 minutes'},
            ],
          }),
          200,
        ),
      );

      expect(answer.answer, '9 minutes');
      expect(answer.citations.single.noteId, 'n1');
    });

    test('wraps a network error as RemoteServiceException', () async {
      expect(
        () => withHandler(
          () => service().ask(question: 'q'),
          (_) async => throw Exception('connection reset'),
        ),
        throwsA(isA<RemoteServiceException>()),
      );
    });
  });

  group('RemoteNoteService.indexNote', () {
    test('returns the chunk count', () async {
      final chunks = await withHandler(
        () => service().indexNote(noteId: 'n1', title: 'T', content: 'body'),
        (_) async => http.Response(jsonEncode({'chunks_indexed': 3}), 200),
      );
      expect(chunks, 3);
    });
  });

  group('RemoteNoteService.deindexNote', () {
    test('treats 204 and 404 as success', () async {
      await withHandler(
        () => service().deindexNote(noteId: 'n1'),
        (_) async => http.Response('', 204),
      );
      await withHandler(
        () => service().deindexNote(noteId: 'n1'),
        (_) async => http.Response('', 404),
      );
      // No exception thrown == pass.
    });

    test('throws on other failure statuses', () async {
      expect(
        () => withHandler(
          () => service().deindexNote(noteId: 'n1'),
          (_) async => http.Response('', 500),
        ),
        throwsA(isA<RemoteServiceException>()),
      );
    });
  });
}
