import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modunote/data/datasources/local/database_providers.dart';
import 'package:modunote/data/models/note.dart';
import 'package:modunote/presentation/viewmodels/note_editor_view_model.dart';
import 'package:modunote/presentation/viewmodels/search_view_model.dart';

import '../../util/mocks.dart';

/// A raw, non-[AppException] error (e.g. a platform/Drift error a repository
/// failed to wrap) must land in view-model state, not escape as an unhandled
/// async error.
void main() {
  late MockNoteRepository noteRepo;
  late MockTagRepository tagRepo;

  Note note(String id) => Note(
        id: id,
        title: id,
        content: const {'ops': []},
        createdAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024),
      );

  setUpAll(() => registerFallbackValue(note('fallback')));

  setUp(() {
    noteRepo = MockNoteRepository();
    tagRepo = MockTagRepository();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      noteRepositoryProvider.overrideWithValue(noteRepo),
      tagRepositoryProvider.overrideWithValue(tagRepo),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('NoteEditorViewModel with a non-AppException error', () {
    final provider = noteEditorViewModelProvider(noteId: 'n1');

    Future<ProviderContainer> loaded() async {
      when(() => noteRepo.findById('n1')).thenAnswer((_) async => note('n1'));
      final container = makeContainer();
      final sub = container.listen(provider, (_, __) {});
      addTearDown(sub.close);
      await container.read(provider.future);
      return container;
    }

    test('save() surfaces a StateError as AsyncError instead of throwing',
        () async {
      when(() => noteRepo.update(any())).thenThrow(StateError('boom'));
      final container = await loaded();

      await container.read(provider.notifier).save(note('n1'));

      expect(container.read(provider).hasError, isTrue);
      expect(container.read(provider).error, isA<StateError>());
    });

    test('addTag() surfaces a StateError as AsyncError instead of throwing',
        () async {
      when(() => tagRepo.addTagToNote(any(), any())).thenThrow(StateError('x'));
      final container = await loaded();

      await container.read(provider.notifier).addTag('t1');

      expect(container.read(provider).error, isA<StateError>());
    });

    test('togglePin() surfaces a StateError as AsyncError', () async {
      when(() => noteRepo.togglePin(any())).thenThrow(StateError('x'));
      final container = await loaded();

      await container.read(provider.notifier).togglePin('n1');

      expect(container.read(provider).error, isA<StateError>());
    });
  });

  group('SearchViewModel with a non-AppException error', () {
    test('a raw error becomes the results AsyncError', () async {
      when(() => noteRepo.search(any())).thenThrow(StateError('fts exploded'));
      final container = makeContainer();
      final sub = container.listen(searchViewModelProvider, (_, __) {});
      addTearDown(sub.close);

      container.read(searchViewModelProvider.notifier).setQuery('pasta');
      await Future<void>.delayed(const Duration(milliseconds: 600));

      final results = container.read(searchViewModelProvider).results;
      expect(results.hasError, isTrue);
      expect(results.error, isA<StateError>());
    });
  });
}
