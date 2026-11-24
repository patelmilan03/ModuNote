import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;

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

/// Maps every category id → the note-tint index of its ROOT category
/// (UI revamp 2026-11). Roots are ordered by `sortOrder` then `createdAt`
/// and take tints 0..4 in turn, so a whole folder family shares one colour.
/// Notes with no category get no tint (plain card). Empty while loading.
@riverpod
Map<String, int> categoryTintIndex(Ref ref) {
  final cats = ref.watch(categoryTreeViewModelProvider).valueOrNull;
  if (cats == null || cats.isEmpty) return const {};
  return buildCategoryTintIndex(cats);
}

/// Pure helper behind [categoryTintIndex] — exposed for tests.
Map<String, int> buildCategoryTintIndex(List<Category> cats) {
  final byId = {for (final c in cats) c.id: c};
  final roots = cats.where((c) => c.isRoot).toList()
    ..sort((a, b) {
      final o = a.sortOrder.compareTo(b.sortOrder);
      return o != 0 ? o : a.createdAt.compareTo(b.createdAt);
    });
  final rootIndex = {for (var i = 0; i < roots.length; i++) roots[i].id: i};

  String rootOf(Category c) {
    var cur = c;
    var guard = 0; // cycle guard — max depth is 5
    while (cur.parentId != null && guard++ < 10) {
      final parent = byId[cur.parentId];
      if (parent == null) break;
      cur = parent;
    }
    return cur.id;
  }

  return {
    for (final c in cats)
      if (rootIndex[rootOf(c)] != null) c.id: rootIndex[rootOf(c)]!,
  };
}
