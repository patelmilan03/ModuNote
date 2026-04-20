import '../../models/category.dart';

/// Contract for category (folder) persistence operations.
abstract interface class ICategoryRepository {
  /// Streams all categories.
  /// Consumers are responsible for building the tree from the flat list.
  Stream<List<Category>> watchAll();

  /// Returns direct children of [parentId] (pass null for root-level).
  Future<List<Category>> findChildren(String? parentId);

  /// Returns a single category by [id], or null.
  Future<Category?> findById(String id);

  /// Persists a new category.
  Future<void> insert(Category category);

  /// Updates name and/or sortOrder of an existing category.
  Future<void> update(Category category);

  /// Deletes a category.
  /// Behaviour when children exist is determined by the implementation
  /// (to be decided in Phase 8 — either cascade or re-parent to grandparent).
  Future<void> delete(String id);

  /// Moves [categoryId] under a new [parentId] (null = promote to root).
  Future<void> move({required String categoryId, required String? newParentId});
}
