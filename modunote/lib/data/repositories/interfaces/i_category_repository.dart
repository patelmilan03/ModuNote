import '../../models/category.dart';

/// Contract for category (folder) persistence operations.
abstract interface class ICategoryRepository {
  /// Streams all categories. Consumers build the tree from the flat list.
  Stream<List<Category>> watchAll();

  /// Returns direct children of [parentId], ordered by sortOrder.
  Future<List<Category>> findChildren(String parentId);

  /// Returns root categories (parentId IS NULL), ordered by sortOrder.
  Future<List<Category>> findRoots();

  /// Returns a single category by [id], or null.
  Future<Category?> findById(String id);

  /// Persists a new category.
  Future<Category> insert({
    required String name,
    String? parentId,
    int sortOrder = 0,
  });

  /// Updates name and/or sortOrder of an existing category.
  Future<Category> update(Category category);

  /// Deletes a category. Behaviour when children exist is implementation-defined
  /// (Phase 8 will add cascade / re-parent policy).
  Future<void> delete(String id);

  /// Moves [id] under [newParentId] (null = promote to root).
  Future<void> move(String id, String? newParentId);

  /// Updates the [sortOrder] of the category with [id].
  Future<void> updateSortOrder(String id, int sortOrder);
}
