import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  // ── Watch queries ──────────────────────────────────────────────────────────

  Stream<List<CategoryRow>> watchAll() {
    return (select(categoriesTable)
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch();
  }

  // ── Single-shot queries ────────────────────────────────────────────────────

  Future<List<CategoryRow>> findChildren(String parentId) {
    return (select(categoriesTable)
          ..where((t) => t.parentId.equals(parentId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<List<CategoryRow>> findRoots() {
    return (select(categoriesTable)
          ..where((t) => t.parentId.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<CategoryRow?> findById(String id) {
    return (select(categoriesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<void> insertCategory(CategoriesTableCompanion c) async {
    await into(categoriesTable).insert(c);
  }

  Future<bool> updateCategory(CategoriesTableCompanion c) async {
    final count = await (update(categoriesTable)
          ..where((t) => t.id.equals(c.id.value)))
        .write(c);
    return count > 0;
  }

  Future<int> deleteCategory(String id) {
    return (delete(categoriesTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> moveCategory(String id, String? newParentId) async {
    await (update(categoriesTable)..where((t) => t.id.equals(id))).write(
      CategoriesTableCompanion(
        parentId: newParentId != null
            ? Value(newParentId)
            : const Value.absent(),
      ),
    );
  }

  Future<void> updateSortOrder(String id, int sortOrder) async {
    await (update(categoriesTable)..where((t) => t.id.equals(id))).write(
      CategoriesTableCompanion(sortOrder: Value(sortOrder)),
    );
  }
}
