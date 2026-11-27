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

  Note note(String id, {String title = 'title'}) => Note(
        id: id,
        title: title,
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

  group('NoteEditorViewModel.save', () {
    test('keeps the previous note readable while the write is in flight',
        () async {
      final existing = note('n1');
      when(() => noteRepo.findById('n1')).thenAnswer((_) async => existing);
      final gate = Completer<void>();
      when(() => noteRepo.update(any())).thenAnswer((_) => gate.future);

      final container = makeContainer();
      final provider = noteEditorViewModelProvider(noteId: 'n1');
      final sub = container.listen(provider, (_, __) {});
      addTearDown(sub.close);
      await container.read(provider.future);

      final saving =
          container.read(provider.notifier).save(note('n1', title: 'edited'));

      final mid = container.read(provider);
      expect(mid.isLoading, isTrue);
      expect(mid.valueOrNull, existing,
          reason: 'mutations that early-return on null would drop edits');

      gate.complete();
      await saving;
      expect(container.read(provider).valueOrNull?.title, 'edited');
    });

    test('an edit that lands mid-save is not dropped', () async {
      final existing = note('n1');
      when(() => noteRepo.findById('n1')).thenAnswer((_) async => existing);
      final gate = Completer<void>();
      when(() => noteRepo.update(any())).thenAnswer((_) => gate.future);
      when(() => tagRepo.addTagToNote(any(), any())).thenAnswer((_) async {});

      final container = makeContainer();
      final provider = noteEditorViewModelProvider(noteId: 'n1');
      final sub = container.listen(provider, (_, __) {});
      addTearDown(sub.close);
      await container.read(provider.future);

      final saving = container.read(provider.notifier).save(existing);
      await container.read(provider.notifier).addTag('t1');
      gate.complete();
      await saving;

      verify(() => tagRepo.addTagToNote('n1', 't1')).called(1);
    });
  });
}
