import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/datasources/local/database_providers.dart';
import '../../data/models/category.dart';
import '../../data/models/note.dart';
import 'category_tree_view_model.dart';

part 'note_list_view_model.g.dart';

enum NoteFilterType { all, category, tag }

class NoteFilter {
  const NoteFilter({
    this.type = NoteFilterType.all,
    this.id,
    this.name,
  });
  final NoteFilterType type;
  final String? id;
  final String? name;
}

@riverpod
class NoteFilterNotifier extends _$NoteFilterNotifier {
  @override
  NoteFilter build() => const NoteFilter();

  void setAll() => state = const NoteFilter();

  void setCategory(String id, String name) =>
      state = NoteFilter(type: NoteFilterType.category, id: id, name: name);

  void setTag(String id, String name) =>
      state = NoteFilter(type: NoteFilterType.tag, id: id, name: name);
}

@riverpod
class NoteListViewModel extends _$NoteListViewModel {
  @override
  Stream<List<Note>> build() {
    final filter = ref.watch(noteFilterNotifierProvider);
    final repo = ref.watch(noteRepositoryProvider);

    switch (filter.type) {
      case NoteFilterType.all:
        return repo.watchAll();
      case NoteFilterType.tag:
        return repo.watchByTag(filter.id!);
      case NoteFilterType.category:
        final allCategories =
            ref.watch(categoryTreeViewModelProvider).valueOrNull ?? [];
        final ids = _collectDescendants(allCategories, filter.id!).toList();
        return repo.watchByCategoryIds(ids);
    }
  }

  /// BFS/iterative expansion: collects [rootId] and all descendant IDs
  /// from the flat adjacency-list [all].
  static Set<String> _collectDescendants(
      List<Category> all, String rootId) {
    final result = <String>{rootId};
    bool changed = true;
    while (changed) {
      changed = false;
      for (final cat in all) {
        if (cat.parentId != null &&
            result.contains(cat.parentId!) &&
            !result.contains(cat.id)) {
          result.add(cat.id);
          changed = true;
        }
      }
    }
    return result;
  }

  Future<void> archive(String id) async {
    try {
      await ref.read(noteRepositoryProvider).archive(id);
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> delete(String id) async {
    try {
      await ref.read(noteRepositoryProvider).delete(id);
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> togglePin(String id) async {
    try {
      await ref.read(noteRepositoryProvider).togglePin(id);
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
