import 'package:drift/drift.dart' as drift;

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../models/category.dart';
import '../../repositories/interfaces/i_category_repository.dart';
import '../../datasources/local/app_database.dart';
import '../../datasources/local/daos/categories_dao.dart';

/// Local Drift implementation of [ICategoryRepository].
///
/// Hierarchy constraints enforced here:
/// - Max depth of 5 (root = depth 1).  Checked by [_assertDepthAllowed]
///   before any insert or move.
/// - Self-referential FK integrity (a category cannot be its own ancestor).
///   Enforced by [_assertNoCycle] before any move.
///
/// Deletion policy (cascade vs re-parent) is deferred to Phase 8;
/// [delete] currently only removes a leaf category and throws if the
/// category has children.
class LocalCategoryRepository implements ICategoryRepository {
  final CategoriesDao _categoriesDao;

  /// Maximum nesting depth (root counts as depth 1).
  static const int _maxDepth = 5;

  const LocalCategoryRepository(this._categoriesDao);

  // ── Watch streams ──────────────────────────────────────────────────────────

  @override
  Stream<List<Category>> watchAll() {
    return _categoriesDao
        .watchAll()
        .map((rows) => rows.map(_rowToCategory).toList());
  }

  // ── Single-shot reads ──────────────────────────────────────────────────────

  @override
  Future<List<Category>> findChildren(String parentId) async {
    try {
      final rows = await _categoriesDao.findChildren(parentId);
      return rows.map(_rowToCategory).toList();
    } on Exception catch (e) {
      throw DatabaseException(
        'Failed to find children of category: $parentId',
        cause: e,
      );
    }
  }

  @override
  Future<List<Category>> findRoots() async {
    try {
      final rows = await _categoriesDao.findRoots();
      return rows.map(_rowToCategory).toList();
    } on Exception catch (e) {
      throw DatabaseException(
        'Failed to find root categories',
        cause: e,
      );
    }
  }

  @override
  Future<Category?> findById(String id) async {
    try {
      final row = await _categoriesDao.findById(id);
      return row == null ? null : _rowToCategory(row);
    } on Exception catch (e) {
      throw DatabaseException(
        'Failed to find category by id: $id',
        cause: e,
      );
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  @override
  Future<Category> insert({
    required String name,
    String? parentId,
    int sortOrder = 0,
  }) async {
    if (name.trim().isEmpty) {
      throw const ValidationException('Category name cannot be blank');
    }

    if (parentId != null) {
      await _assertDepthAllowed(parentId);
    }

    try {
      final now = DateTime.now().toUtc();
      final category = Category(
        id: UuidGenerator.generate(),
        name: name.trim(),
        parentId: parentId,
        sortOrder: sortOrder,
        createdAt: now,
      );
      await _categoriesDao.insertCategory(
        CategoriesTableCompanion.insert(
          id: category.id,
          name: category.name,
          parentId: parentId != null
              ? drift.Value(parentId)
              : const drift.Value.absent(),
          sortOrder: category.sortOrder == 0
              ? const drift.Value.absent()
              : drift.Value(category.sortOrder),
          createdAt: category.createdAt,
        ),
      );
      return category;
    } on ValidationException {
      rethrow;
    } on Exception catch (e) {
      throw DatabaseException(
        'Failed to insert category: "$name"',
        cause: e,
      );
    }
  }

  @override
  Future<Category> update(Category category) async {
    if (category.name.trim().isEmpty) {
      throw const ValidationException('Category name cannot be blank');
    }

    try {
      await _categoriesDao.updateCategory(
        CategoriesTableCompanion(
          id: drift.Value(category.id),
          name: drift.Value(category.name.trim()),
          sortOrder: drift.Value(category.sortOrder),
        ),
      );
      return category;
    } on Exception catch (e) {
      throw DatabaseException(
        'Failed to update category: ${category.id}',
        cause: e,
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      // Phase 8 will add cascade / re-parent logic.
      // For now: only leaf categories may be deleted.
      final children = await _categoriesDao.findChildren(id);
      if (children.isNotEmpty) {
        throw const ValidationException(
          'Cannot delete a category that has children. '
          'Move or delete children first.',
        );
      }
      await _categoriesDao.deleteCategory(id);
    } on ValidationException {
      rethrow;
    } on Exception catch (e) {
      throw DatabaseException(
        'Failed to delete category: $id',
        cause: e,
      );
    }
  }

  @override
  Future<void> move(String id, String? newParentId) async {
    if (newParentId != null) {
      await _assertDepthAllowed(newParentId);
      await _assertNoCycle(id, newParentId);
    }

    try {
      await _categoriesDao.moveCategory(id, newParentId);
    } on ValidationException {
      rethrow;
    } on Exception catch (e) {
      throw DatabaseException(
        'Failed to move category $id to parent $newParentId',
        cause: e,
      );
    }
  }

  @override
  Future<void> updateSortOrder(String id, int sortOrder) async {
    try {
      await _categoriesDao.updateSortOrder(id, sortOrder);
    } on Exception catch (e) {
      throw DatabaseException(
        'Failed to update sort order for category: $id',
        cause: e,
      );
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Walks up the ancestor chain from [parentId] to determine the current
  /// depth of [parentId], then throws a [ValidationException] if inserting
  /// a child would exceed [_maxDepth].
  Future<void> _assertDepthAllowed(String parentId) async {
    int depth = 1; // depth of parentId itself
    String? current = parentId;
    while (current != null) {
      final row = await _categoriesDao.findById(current);
      if (row == null) break;
      depth++;
      current = row.parentId;
      if (depth >= _maxDepth) {
        throw const ValidationException(
          'Maximum category nesting depth ($_maxDepth) reached.',
        );
      }
    }
  }

  /// Walks the descendant tree of [id] to ensure [newParentId] is not among
  /// its descendants, which would create a cycle.
  Future<void> _assertNoCycle(String id, String newParentId) async {
    final descendants = await _collectDescendantIds(id);
    if (descendants.contains(newParentId)) {
      throw const ValidationException(
        'Cannot move a category into one of its own descendants.',
      );
    }
  }

  /// Returns the flat set of all descendant ids for [id] (BFS).
  Future<Set<String>> _collectDescendantIds(String id) async {
    final result = <String>{};
    final queue = <String>[id];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final children = await _categoriesDao.findChildren(current);
      for (final child in children) {
        result.add(child.id);
        queue.add(child.id);
      }
    }
    return result;
  }

  // ── Mapping ────────────────────────────────────────────────────────────────

  Category _rowToCategory(CategoryRow row) => Category(
        id: row.id,
        name: row.name,
        parentId: row.parentId,
        sortOrder: row.sortOrder,
        createdAt: row.createdAt,
      );
}
