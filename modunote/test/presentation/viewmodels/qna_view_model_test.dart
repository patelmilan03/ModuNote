import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modunote/data/models/qna_answer.dart';
import 'package:modunote/presentation/viewmodels/qna_view_model.dart';
import 'package:modunote/services/remote/remote_note_service_provider.dart';

import '../../util/mocks.dart';

void main() {
  late MockRemoteNoteService service;

  setUp(() => service = MockRemoteNoteService());

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [remoteNoteServiceProvider.overrideWithValue(service)],
    );
    addTearDown(c.dispose);
    // Keep the auto-dispose VM alive across the test.
    final sub = c.listen(qnaViewModelProvider, (_, __) {});
    addTearDown(sub.close);
    return c;
  }

  group('QnaViewModel', () {
    test('starts with no turns', () {
      final container = makeContainer();
      expect(container.read(qnaViewModelProvider), isEmpty);
    });

    test('ask appends a loading turn then resolves it with the answer',
        () async {
      final completer = Completer<QnaAnswer>();
      when(() => service.ask(question: any(named: 'question')))
          .thenAnswer((_) => completer.future);

      final container = makeContainer();
      final future =
          container.read(qnaViewModelProvider.notifier).ask('How long?');

      // Mid-flight: one turn, loading.
      final loading = container.read(qnaViewModelProvider);
      expect(loading, hasLength(1));
      expect(loading.single.question, 'How long?');
      expect(loading.single.answer.isLoading, isTrue);

      completer.complete(
        const QnaAnswer(answer: '9 minutes', citations: []),
      );
      await future;

      final done = container.read(qnaViewModelProvider).single;
      expect(done.answer.value?.answer, '9 minutes');
    });

    test('trims the question and ignores a blank one', () async {
      when(() => service.ask(question: any(named: 'question')))
          .thenAnswer((_) async => const QnaAnswer(answer: 'a'));

      final container = makeContainer();
      await container.read(qnaViewModelProvider.notifier).ask('   ');

      expect(container.read(qnaViewModelProvider), isEmpty);
      verifyNever(() => service.ask(question: any(named: 'question')));
    });

    test('captures a service failure as AsyncError on the turn', () async {
      when(() => service.ask(question: any(named: 'question')))
          .thenThrow(Exception('network down'));

      final container = makeContainer();
      await container.read(qnaViewModelProvider.notifier).ask('Q');

      final turn = container.read(qnaViewModelProvider).single;
      expect(turn.answer.hasError, isTrue);
    });

    test('clear empties the conversation', () async {
      when(() => service.ask(question: any(named: 'question')))
          .thenAnswer((_) async => const QnaAnswer(answer: 'a'));

      final container = makeContainer();
      await container.read(qnaViewModelProvider.notifier).ask('Q');
      expect(container.read(qnaViewModelProvider), hasLength(1));

      container.read(qnaViewModelProvider.notifier).clear();
      expect(container.read(qnaViewModelProvider), isEmpty);
    });
  });
}
