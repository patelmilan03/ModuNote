import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/data/datasources/local/app_database.dart';
import 'package:modunote/data/models/note.dart';
import 'package:modunote/data/repositories/local/local_note_repository.dart';
import 'package:modunote/data/repositories/local/local_tag_repository.dart';

import '../../util/sqlite3_test_setup.dart';

void main() {
  late bool sqliteReady;
  setUpAll(() async => sqliteReady = await ensureSqlite3());

  late AppDatabase db;
  late LocalTagRepository tags;
  late LocalNoteRepository notes;

  setUp(() {
    if (!sqliteReady) return;
    db = AppDatabase(NativeDatabase.memory());
    tags = LocalTagRepository(db.tagsDao);
    notes = LocalNoteRepository(db.notesDao);
  });
  tearDown(() async {
    if (sqliteReady) await db.close();
  });

  Note note(String id) => Note(
        id: id,
        title: id,
        content: const {'ops': []},
        createdAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024),
      );

  group('LocalTagRepository.delete cascade', () {
    test('removes note_tags rows and the tag from every note.tagIds',
        () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      final keep = await tags.insert('keep');
      final drop = await tags.insert('drop');
      await notes.insert(note('n1'));
      await notes.insert(note('n2'));
      await tags.addTagToNote('n1', keep.id);
      await tags.addTagToNote('n1', drop.id);
      await tags.addTagToNote('n2', drop.id);

      await tags.delete(drop.id);

      expect(await tags.findById(drop.id), isNull);
      // Join rows are gone: no counts for the deleted tag, no tag for notes.
      expect(await tags.getNoteCounts(), {keep.id: 1});
      expect((await tags.findByNote('n1')).map((t) => t.id), [keep.id]);
      expect(await tags.findByNote('n2'), isEmpty);
      // Denormalised JSON column is refreshed too.
      expect((await notes.findById('n1'))!.tagIds, [keep.id]);
      expect((await notes.findById('n2'))!.tagIds, isEmpty);
    });

    test('watchByTag no longer returns notes for a deleted tag', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      final drop = await tags.insert('drop');
      await notes.insert(note('n1'));
      await tags.addTagToNote('n1', drop.id);
      expect((await notes.watchByTag(drop.id).first).map((n) => n.id), ['n1']);

      await tags.delete(drop.id);

      expect(await notes.watchByTag(drop.id).first, isEmpty);
    });

    test('deleting an unattached tag still works', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      final tag = await tags.insert('temp');
      await tags.delete(tag.id);
      expect(await tags.watchAll().first, isEmpty);
    });
  });
}
