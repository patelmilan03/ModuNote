import 'package:drift/drift.dart';

import '../../datasources/local/app_database.dart';
import '../../models/category.dart';
import '../interfaces/i_category_repository.dart';

class LocalCategoryRepository implements ICategoryRepository {
  const LocalCategoryRepository(this._dao);

  final CategoriesDao _dao;

  // ─── Streams ────────────────────────────────────────────────────────────────

  @override
  Stream<List<Category>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toModel).toList());

  // ─── Reads ───────────────────────────────────────────────────────────────────

  @override
  Future<List<Category>> findChildren(String? parentId) async {
    final rows = await _dao.findChildren(parentId);
    return rows.map(_toModel).toList();
  }

  @override
  Future<Category?> findById(String id) async {
    final row = await _dao.findById(id);
    return row == null ? null : _toModel(row);
  }

  // ─── Writes ──────────────────────────────────────────────────────────────────

  @override
  Future<void> insert(Category category) async {
    await _dao.insertCategory(CategoriesTableCompanion(
      id: Value(category.id),
      name: Value(category.name),
      parentId: Value(category.parentId),
      sortOrder: Value(category.sortOrder),
      createdAt: Value(category.createdAt),
    ));
  }

  @override
  Future<void> update(Category category) async {
    await _dao.updateCategory(CategoriesTableCompanion(
      id: Value(category.id),
      name: Value(category.name),
      parentId: Value(category.parentId),
      sortOrder: Value(category.sortOrder),
    ));
  }

  @override
  Future<void> delete(String id) => _dao.deleteCategory(id);

  @override
  Future<void> move({
    required String categoryId,
    required String? newParentId,
  }) =>
      _dao.moveCategory(categoryId: categoryId, newParentId: newParentId);

  // ─── Mapping ─────────────────────────────────────────────────────────────────

  Category _toModel(CategoryRow row) => Category(
        id: row.id,
        name: row.name,
        parentId: row.parentId,
        sortOrder: row.sortOrder,
        createdAt: row.createdAt,
      );
}
