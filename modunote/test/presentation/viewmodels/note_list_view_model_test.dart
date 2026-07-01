import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modunote/core/errors/app_exception.dart';
import 'package:modunote/data/datasources/local/database_providers.dart';
import 'package:modunote/data/models/note.dart';
import 'package:modunote/presentation/viewmodels/note_list_view_model.dart';

import '../../util/mocks.dart';

void main() {
  late MockNoteRepository repo;

  Note note(String id) => Note(
        id: id,
        title: id,
        content: const {'ops': []},
        createdAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024),
      );

  setUp(() => repo = MockNoteRepository());

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    final sub = c.listen(noteListViewModelProvider, (_, __) {});
    addTearDown(sub.close);
    return c;
  }

  group('NoteListViewModel filtering', () {
    test('the default (all) filter streams from watchAll', () async {
      when(() => repo.watchAll()).thenAnswer((_) => Stream.value([note('n1')]));

      final container = makeContainer();
      final value = await container.read(noteListViewModelProvider.future);

      expect(value.map((n) => n.id), ['n1']);
      verify(() => repo.watchAll()).called(1);
      verifyNever(() => repo.watchByTag(any()));
    });

    test('a tag filter switches the stream to watchByTag', () async {
      when(() => repo.watchAll()).thenAnswer((_) => Stream.value(<Note>[]));
      when(() => repo.watchByTag('t1'))
          .thenAnswer((_) => Stream.value([note('tagged')]));

      final container = makeContainer();
      // Resolve the initial (all) build, then change the filter.
      await container.read(noteListViewModelProvider.future);
      container.read(noteFilterNotifierProvider.notifier).setTag('t1', 'ideas');

      final value = await container.read(noteListViewModelProvider.future);
      expect(value.map((n) => n.id), ['tagged']);
      verify(() => repo.watchByTag('t1')).called(1);
    });
  });

  group('NoteListViewModel mutations', () {
    test('archive surfaces an AppException as AsyncError', () async {
      when(() => repo.watchAll()).thenAnswer((_) => Stream.value([note('n1')]));
      when(() => repo.archive(any()))
          .thenThrow(const DatabaseException('archive failed'));

      final container = makeContainer();
      await container.read(noteListViewModelProvider.future);

      await container.read(noteListViewModelProvider.notifier).archive('n1');

      expect(container.read(noteListViewModelProvider).hasError, isTrue);
    });

    test('togglePin delegates to the repository on the happy path', () async {
      when(() => repo.watchAll()).thenAnswer((_) => Stream.value([note('n1')]));
      when(() => repo.togglePin(any())).thenAnswer((_) async {});

      final container = makeContainer();
      await container.read(noteListViewModelProvider.future);

      await container.read(noteListViewModelProvider.notifier).togglePin('n1');

      verify(() => repo.togglePin('n1')).called(1);
      expect(container.read(noteListViewModelProvider).hasError, isFalse);
    });
  });
}
