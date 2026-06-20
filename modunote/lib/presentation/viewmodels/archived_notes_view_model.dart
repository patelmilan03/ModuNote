import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/datasources/local/database_providers.dart';
import '../../data/models/note.dart';

part 'archived_notes_view_model.g.dart';

@riverpod
class ArchivedNotesViewModel extends _$ArchivedNotesViewModel {
  @override
  Stream<List<Note>> build() {
    return ref.watch(noteRepositoryProvider).watchArchived();
  }

  Future<void> restore(String id) async {
    try {
      await ref.read(noteRepositoryProvider).unarchive(id);
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
}
