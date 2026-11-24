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

/// Live map of categoryId → number of active notes in it OR any descendant
/// (matches Home's hierarchical category filter). Feeds the Tags screen's
/// Folders card.
@riverpod
Stream<Map<String, int>> categoryNoteCounts(Ref ref) {
  final cats = ref.watch(categoryTreeViewModelProvider).valueOrNull ?? const [];
  return ref
      .watch(noteRepositoryProvider)
      .watchAll()
      .map((notes) => buildCategoryNoteCounts(cats, notes.map((n) => n.categoryId)));
}

/// Pure helper behind [categoryNoteCounts] — exposed for tests. Each note
/// counts once for its own category and once for every ancestor.
Map<String, int> buildCategoryNoteCounts(
    List<Category> cats, Iterable<String?> noteCategoryIds) {
  final byId = {for (final c in cats) c.id: c};
  final counts = <String, int>{};
  for (final id in noteCategoryIds) {
    var cur = id == null ? null : byId[id];
    var guard = 0; // cycle guard — max depth is 5
    while (cur != null && guard++ < 10) {
      counts[cur.id] = (counts[cur.id] ?? 0) + 1;
      cur = cur.parentId == null ? null : byId[cur.parentId];
    }
  }
  return counts;
}
