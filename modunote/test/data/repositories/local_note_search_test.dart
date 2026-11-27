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

  Note note(String id, String title) => Note(
        id: id,
        title: title,
        content: const {
          'ops': [
            {'insert': 'body\n'},
          ],
        },
        createdAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024),
      );

  group('LocalNoteRepository.search sanitising', () {
    // Queries that used to build an invalid FTS5 MATCH expression and surface
    // as a DatabaseException (error toast) instead of "no results".
    for (final q in [
      '.',
      '^',
      "'",
      '..',
      '^^',
      "'.^",
      '{',
      '}',
      '[',
      '<',
      '=',
      '!',
      '~',
      '/',
      r'\',
      '&',
      '|',
      '@',
      '#',
      r'$',
      '%',
      ';',
      '?',
      '`',
      '"',
      '*',
      '()',
      '"unterminated',
      'a ^ b',
    ]) {
      test('degenerate/special query ${q.isEmpty ? "(empty)" : q} does not throw',
          () async {
        if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
        await repo.insert(note('n1', 'Pasta Recipe'));
        await expectLater(repo.search(q), completes);
      });
    }

    test('punctuation-only queries return no results', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await repo.insert(note('n1', 'Pasta Recipe'));
      expect(await repo.search('.'), isEmpty);
      expect(await repo.search("'^."), isEmpty);
    });

    test('FTS keywords are searched as plain words, not operators', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await repo.insert(note('n1', 'Salt and pepper'));
      await repo.insert(note('n2', 'Tax Documents'));

      expect((await repo.search('and')).map((n) => n.id), ['n1']);
      await expectLater(repo.search('or'), completes);
      await expectLater(repo.search('not'), completes);
      await expectLater(repo.search('near'), completes);
    });

    test('punctuation around real words is ignored and prefix match works',
        () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await repo.insert(note('n1', 'Pasta Recipe'));
      await repo.insert(note('n2', 'Tax Documents'));

      expect((await repo.search('pas')).map((n) => n.id), ['n1']);
      expect((await repo.search("'pasta.")).map((n) => n.id), ['n1']);
      expect((await repo.search('^pasta recip')).map((n) => n.id), ['n1']);
    });
  });
}
