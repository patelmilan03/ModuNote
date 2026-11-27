import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modunote/core/errors/app_exception.dart';
import 'package:modunote/data/datasources/local/database_providers.dart';
import 'package:modunote/data/models/note.dart';
import 'package:modunote/presentation/viewmodels/note_list_view_model.dart';

import '../../util/mocks.dart';

void main() {
  // The view-models report failures through the app-wide toast helper, which
  // looks up a global navigator key (a no-op when no app is mounted).
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('NoteFilterNotifier', () {
    test('keeps the filter while no screen is watching it', () async {
      // The Tags tab sets the filter, then navigates to Home. Nothing watches
      // the filter in between, so it must not auto-dispose back to "all".
      final container = ProviderContainer(
        overrides: [noteRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      container.read(noteFilterNotifierProvider.notifier).setTag('t1', 'ideas');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final filter = container.read(noteFilterNotifierProvider);
      expect(filter.type, NoteFilterType.tag);
      expect(filter.id, 't1');
    });
  });

  group('NoteListViewModel mutations', () {
    test('a failed archive keeps the streamed list on screen', () async {
      when(() => repo.watchAll()).thenAnswer((_) => Stream.value([note('n1')]));
      when(() => repo.archive(any()))
          .thenThrow(const DatabaseException('archive failed'));

      final container = makeContainer();
      await container.read(noteListViewModelProvider.future);

      await container.read(noteListViewModelProvider.notifier).archive('n1');

      final state = container.read(noteListViewModelProvider);
      expect(state.hasError, isFalse,
          reason: 'a failed mutation made no DB change, so nothing would '
              're-emit the list after an error state');
      expect(state.valueOrNull?.map((n) => n.id), ['n1']);
    });

    test('a failed delete or pin with a raw error also keeps the list',
        () async {
      when(() => repo.watchAll()).thenAnswer((_) => Stream.value([note('n1')]));
      when(() => repo.delete(any())).thenThrow(StateError('boom'));
      when(() => repo.togglePin(any())).thenThrow(StateError('boom'));

      final container = makeContainer();
      await container.read(noteListViewModelProvider.future);
      final vm = container.read(noteListViewModelProvider.notifier);

      await vm.delete('n1');
      await vm.togglePin('n1');

      final state = container.read(noteListViewModelProvider);
      expect(state.hasError, isFalse);
      expect(state.valueOrNull?.map((n) => n.id), ['n1']);
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
