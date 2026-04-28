import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/datasources/local/database_providers.dart';
import '../../data/models/tag.dart';

part 'tag_list_view_model.g.dart';

@riverpod
class TagListViewModel extends _$TagListViewModel {
  @override
  Stream<List<Tag>> build() {
    return ref.watch(tagRepositoryProvider).watchAll();
  }

  /// Creates a new tag from [name]. Returns the created [Tag].
  /// Name is normalised (lowercase) by the repository before insert.
  Future<Tag> insert(String name) async {
    try {
      return await ref.read(tagRepositoryProvider).insert(name);
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await ref.read(tagRepositoryProvider).delete(id);
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
