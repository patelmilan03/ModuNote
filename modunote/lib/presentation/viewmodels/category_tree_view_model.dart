import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/datasources/local/database_providers.dart';
import '../../data/models/category.dart';

part 'category_tree_view_model.g.dart';

/// Exposes a flat list of all categories.
/// Consumers build the display tree from [Category.parentId] adjacency links.
@riverpod
class CategoryTreeViewModel extends _$CategoryTreeViewModel {
  @override
  Stream<List<Category>> build() {
    return ref.watch(categoryRepositoryProvider).watchAll();
  }

  Future<Category> insert({
    required String name,
    String? parentId,
    int sortOrder = 0,
  }) async {
    try {
      return await ref.read(categoryRepositoryProvider).insert(
            name: name,
            parentId: parentId,
            sortOrder: sortOrder,
          );
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> move(String id, String? newParentId) async {
    try {
      await ref.read(categoryRepositoryProvider).move(id, newParentId);
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> delete(String id) async {
    try {
      await ref.read(categoryRepositoryProvider).delete(id);
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
