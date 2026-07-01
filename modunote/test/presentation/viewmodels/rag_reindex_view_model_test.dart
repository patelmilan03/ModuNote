import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modunote/data/datasources/local/database_providers.dart';
import 'package:modunote/data/models/note.dart';
import 'package:modunote/data/models/tag.dart';
import 'package:modunote/presentation/viewmodels/rag_reindex_view_model.dart';
import 'package:modunote/services/remote/remote_note_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../util/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNoteRepository noteRepo;
  late MockTagRepository tagRepo;
  late MockRemoteNoteService service;

  // Note tagged 'study' → in the default scope {study, notes, research}.
  final inScope = Note(
    id: 'a',
    title: 'Study note',
    content: const {
      'ops': [
        {'insert': 'mitochondria\n'},
      ],
    },
    tagIds: const ['t1'],
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
  );
  // Note tagged 'random' → not in scope, must be skipped.
  final outOfScope = Note(
    id: 'b',
    title: 'Other',
    content: const {'ops': []},
    tagIds: const ['t2'],
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
  );
  final tags = [
    Tag(id: 't1', name: 'study', createdAt: DateTime.utc(2024)),
    Tag(id: 't2', name: 'random', createdAt: DateTime.utc(2024)),
  ];

  setUpAll(() => registerFallbackValue(<String>[]));

  setUp(() {
    SharedPreferences.setMockInitialValues({}); // → default scope
    noteRepo = MockNoteRepository();
    tagRepo = MockTagRepository();
    service = MockRemoteNoteService();
    when(() => noteRepo.watchAll())
        .thenAnswer((_) => Stream.value([inScope, outOfScope]));
    when(() => tagRepo.watchAll()).thenAnswer((_) => Stream.value(tags));
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      noteRepositoryProvider.overrideWithValue(noteRepo),
      tagRepositoryProvider.overrideWithValue(tagRepo),
      remoteNoteServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('RagReindex.reindexAll', () {
    test('indexes only notes whose tags are in scope', () async {
      when(() => service.indexNote(
            noteId: any(named: 'noteId'),
            title: any(named: 'title'),
            content: any(named: 'content'),
            tags: any(named: 'tags'),
          )).thenAnswer((_) async => 1);

      final container = makeContainer();
      final result =
          await container.read(ragReindexProvider.notifier).reindexAll();

      expect(result.ok, 1);
      expect(result.fail, 0);
      // Only the in-scope note is pushed, with resolved tag names + plain text.
      verify(() => service.indexNote(
            noteId: 'a',
            title: 'Study note',
            content: 'mitochondria',
            tags: ['study'],
          )).called(1);
      verifyNever(() => service.indexNote(
            noteId: 'b',
            title: any(named: 'title'),
            content: any(named: 'content'),
            tags: any(named: 'tags'),
          ));
    });

    test('counts per-note failures without throwing', () async {
      when(() => service.indexNote(
            noteId: any(named: 'noteId'),
            title: any(named: 'title'),
            content: any(named: 'content'),
            tags: any(named: 'tags'),
          )).thenThrow(Exception('502'));

      final container = makeContainer();
      final result =
          await container.read(ragReindexProvider.notifier).reindexAll();

      expect(result.ok, 0);
      expect(result.fail, 1);
    });

    test('returns (0,0) when no note carries a scope tag', () async {
      when(() => noteRepo.watchAll())
          .thenAnswer((_) => Stream.value([outOfScope]));

      final container = makeContainer();
      final result =
          await container.read(ragReindexProvider.notifier).reindexAll();

      expect(result, (ok: 0, fail: 0));
      verifyNever(() => service.indexNote(
            noteId: any(named: 'noteId'),
            title: any(named: 'title'),
            content: any(named: 'content'),
            tags: any(named: 'tags'),
          ));
    });
  });
}
