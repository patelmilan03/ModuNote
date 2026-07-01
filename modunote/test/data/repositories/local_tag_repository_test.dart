import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/core/errors/app_exception.dart';
import 'package:modunote/data/datasources/local/app_database.dart';
import 'package:modunote/data/repositories/local/local_tag_repository.dart';

import '../../util/sqlite3_test_setup.dart';

void main() {
  late bool sqliteReady;
  setUpAll(() async => sqliteReady = await ensureSqlite3());

  late AppDatabase db;
  late LocalTagRepository repo;

  setUp(() {
    if (!sqliteReady) return;
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalTagRepository(db.tagsDao);
  });
  tearDown(() async {
    if (sqliteReady) await db.close();
  });

  group('LocalTagRepository', () {
    test('insert normalises the name and returns the created tag', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      final tag = await repo.insert('  Travel  ');
      expect(tag.name, 'travel');
      expect(tag.id, isNotEmpty);

      expect((await repo.watchAll().first).map((t) => t.name), ['travel']);
    });

    test('insert rejects a blank name with ValidationException', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await expectLater(
        repo.insert('   '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('a duplicate name is wrapped as DatabaseException (UNIQUE)', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await repo.insert('travel');
      await expectLater(
        repo.insert('TRAVEL'), // normalises to the same name
        throwsA(isA<DatabaseException>()),
      );
    });

    test('findByName looks up case-insensitively; findById by id', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      final created = await repo.insert('ideas');

      expect((await repo.findByName('IDEAS'))!.id, created.id);
      expect(await repo.findByName('nope'), isNull);
      expect((await repo.findById(created.id))!.name, 'ideas');
    });

    test('delete removes the tag', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      final tag = await repo.insert('temp');
      await repo.delete(tag.id);
      expect(await repo.watchAll().first, isEmpty);
    });

    test('deleteOrphanTags removes tags not attached to any note', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await repo.insert('orphan');
      final removed = await repo.deleteOrphanTags();
      expect(removed, contains('orphan'));
      expect(await repo.watchAll().first, isEmpty);
    });

    test('getNoteCounts is empty when no tags are attached', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await repo.insert('lonely');
      expect(await repo.getNoteCounts(), isEmpty);
    });
  });
}
