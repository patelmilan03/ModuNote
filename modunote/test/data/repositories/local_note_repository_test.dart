import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/data/datasources/local/app_database.dart';
import 'package:modunote/data/models/note.dart';
import 'package:modunote/data/repositories/local/local_note_repository.dart';

import '../../util/sqlite3_test_setup.dart';

void main() {
  late bool sqliteReady;
  setUpAll(() async => sqliteReady = await ensureSqlite3());

  late AppDatabase db;
  late LocalNoteRepository repo;

  setUp(() {
    if (!sqliteReady) return;
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalNoteRepository(db.notesDao);
  });
  tearDown(() async {
    if (sqliteReady) await db.close();
  });

  Note note(String id, {String title = 'Title', bool pinned = false}) => Note(
        id: id,
        title: title,
        content: {
          'ops': [
            {'insert': 'body of $id\n'},
          ],
        },
        isPinned: pinned,
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 1),
      );

  group('LocalNoteRepository', () {
    test('insert is readable via watchAll and findById (round-trips fields)',
        () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await repo.insert(note('n1', title: 'First'));

      final all = await repo.watchAll().first;
      expect(all, hasLength(1));
      expect(all.single.id, 'n1');
      expect(all.single.title, 'First');
      expect(all.single.content, {
        'ops': [
          {'insert': 'body of n1\n'},
        ],
      });
      expect(all.single.syncStatus, SyncStatus.local);

      final found = await repo.findById('n1');
      expect(found, isNotNull);
      expect(found!.title, 'First');
      expect(await repo.findById('missing'), isNull);
    });

    test('update changes persisted fields', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await repo.insert(note('n1', title: 'Old'));
      final updated = (await repo.findById('n1'))!.copyWith(title: 'New');
      await repo.update(updated);

      expect((await repo.findById('n1'))!.title, 'New');
    });

    test('togglePin flips the pinned flag', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await repo.insert(note('n1'));
      expect((await repo.findById('n1'))!.isPinned, isFalse);

      await repo.togglePin('n1');
      expect((await repo.findById('n1'))!.isPinned, isTrue);

      await repo.togglePin('n1');
      expect((await repo.findById('n1'))!.isPinned, isFalse);
    });

    test('archive hides from watchAll and shows in watchArchived; unarchive '
        'restores', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await repo.insert(note('n1'));

      await repo.archive('n1');
      expect(await repo.watchAll().first, isEmpty);
      expect((await repo.watchArchived().first).map((n) => n.id), ['n1']);

      await repo.unarchive('n1');
      expect((await repo.watchAll().first).map((n) => n.id), ['n1']);
      expect(await repo.watchArchived().first, isEmpty);
    });

    test('delete removes the note', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await repo.insert(note('n1'));
      await repo.delete('n1');
      expect(await repo.findById('n1'), isNull);
      expect(await repo.watchAll().first, isEmpty);
    });

    test('FTS search matches on title', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await repo.insert(note('n1', title: 'Pasta Recipe'));
      await repo.insert(note('n2', title: 'Tax Documents'));

      final hits = await repo.search('pasta');
      expect(hits.map((n) => n.id), ['n1']);
    });
  });
}
