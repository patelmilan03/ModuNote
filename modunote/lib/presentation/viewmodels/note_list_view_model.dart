import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/datasources/local/database_providers.dart';
import '../../data/models/note.dart';

part 'note_list_view_model.g.dart';

@riverpod
class NoteListViewModel extends _$NoteListViewModel {
  @override
  Stream<List<Note>> build() {
    return ref.watch(noteRepositoryProvider).watchAll();
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
