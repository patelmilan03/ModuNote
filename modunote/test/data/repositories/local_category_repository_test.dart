import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/core/errors/app_exception.dart';
import 'package:modunote/data/datasources/local/app_database.dart';
import 'package:modunote/data/models/category.dart';
import 'package:modunote/data/repositories/local/local_category_repository.dart';

import '../../util/sqlite3_test_setup.dart';

void main() {
  late bool sqliteReady;
  setUpAll(() async => sqliteReady = await ensureSqlite3());

  late AppDatabase db;
  late LocalCategoryRepository repo;

  setUp(() {
    if (!sqliteReady) return;
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalCategoryRepository(db.categoriesDao, db.notesDao);
  });
  tearDown(() async {
    if (sqliteReady) await db.close();
  });

  /// Builds a chain root → … of [depth] categories; returns the deepest one.
  Future<Category> chain(int depth) async {
    Category? parent;
    for (var i = 1; i <= depth; i++) {
      parent = await repo.insert(name: 'level $i', parentId: parent?.id);
    }
    return parent!;
  }

  group('LocalCategoryRepository nesting depth (max 5, root = 1)', () {
    test('a child of a depth-4 category (depth 5) is allowed', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      final level4 = await chain(4);

      final level5 = await repo.insert(name: 'level 5', parentId: level4.id);

      expect(level5.parentId, level4.id);
    });

    test('a child of a depth-5 category (depth 6) is rejected', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      final level5 = await chain(5);

      await expectLater(
        repo.insert(name: 'level 6', parentId: level5.id),
        throwsA(isA<ValidationException>()),
      );
    });

    test('move enforces the same limit', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      final level4 = await chain(4);
      final level5 = await repo.insert(name: 'level 5', parentId: level4.id);
      final loose = await repo.insert(name: 'loose');

      await repo.move(loose.id, level4.id); // becomes depth 5 — allowed
      await expectLater(
        repo.move(loose.id, level5.id), // would become depth 6
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
