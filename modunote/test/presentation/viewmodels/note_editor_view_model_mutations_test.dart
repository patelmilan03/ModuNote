import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modunote/data/datasources/local/database_providers.dart';
import 'package:modunote/data/models/note.dart';
import 'package:modunote/presentation/viewmodels/note_editor_view_model.dart';

import '../../util/mocks.dart';

void main() {
  late MockNoteRepository noteRepo;
  late MockTagRepository tagRepo;

  Note note(String id) => Note(
        id: id,
        title: 'title',
        content: const {'ops': []},
        createdAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024),
      );

  setUp(() {
    noteRepo = MockNoteRepository();
    tagRepo = MockTagRepository();
  });

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        noteRepositoryProvider.overrideWithValue(noteRepo),
        tagRepositoryProvider.overrideWithValue(tagRepo),
      ]);

  final provider = noteEditorViewModelProvider(noteId: 'n1');

  Future<ProviderContainer> loaded(Note existing) async {
    when(() => noteRepo.findById('n1')).thenAnswer((_) async => existing);
    final container = makeContainer();
    addTearDown(container.dispose);
    final sub = container.listen(provider, (_, __) {});
    addTearDown(sub.close);
    await container.read(provider.future);
    return container;
  }

  group('NoteEditorViewModel tag/pin mutations', () {
    test('addTag refreshes state from the repository', () async {
      final existing = note('n1');
      final container = await loaded(existing);
      when(() => tagRepo.addTagToNote(any(), any())).thenAnswer((_) async {});
      when(() => noteRepo.findById('n1'))
          .thenAnswer((_) async => existing.copyWith(tagIds: const ['t1']));

      await container.read(provider.notifier).addTag('t1');

      expect(container.read(provider).valueOrNull?.tagIds, ['t1']);
    });

    test('removeTag on a note deleted mid-mutation keeps the last known note',
        () async {
      final existing = note('n1');
      final container = await loaded(existing);
      when(() => tagRepo.removeTagFromNote(any(), any()))
          .thenAnswer((_) async {});
      when(() => noteRepo.findById('n1')).thenAnswer((_) async => null);

      await container.read(provider.notifier).removeTag('t1');

      expect(container.read(provider).valueOrNull, existing);
    });

    test('togglePin keeps the last known note when the note vanished',
        () async {
      final existing = note('n1');
      final container = await loaded(existing);
      when(() => noteRepo.togglePin(any())).thenAnswer((_) async {});
      when(() => noteRepo.findById('n1')).thenAnswer((_) async => null);

      await container.read(provider.notifier).togglePin('n1');

      expect(container.read(provider).valueOrNull, existing);
    });

    test('does not write state when the editor is disposed mid-await',
        () async {
      final existing = note('n1');
      when(() => noteRepo.findById('n1')).thenAnswer((_) async => existing);
      final gate = Completer<void>();
      when(() => tagRepo.addTagToNote(any(), any()))
          .thenAnswer((_) => gate.future);

      final container = makeContainer();
      addTearDown(container.dispose);
      final sub = container.listen(provider, (_, __) {});
      await container.read(provider.future);

      final pending = container.read(provider.notifier).addTag('t1');
      sub.close(); // editor popped → auto-dispose
      await container.pump();
      gate.complete();

      await expectLater(pending, completes);
    });
  });
}
