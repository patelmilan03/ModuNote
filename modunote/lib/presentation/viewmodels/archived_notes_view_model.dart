import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/app_toast.dart';
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
    } catch (e) {
      _reportFailure("Couldn't restore the note.", e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await ref.read(noteRepositoryProvider).delete(id);
    } catch (e) {
      _reportFailure("Couldn't delete the note.", e);
    }
  }

  /// Keep the archive list on screen on failure (no DB change means the stream
  /// would never re-emit) and tell the user instead.
  void _reportFailure(String message, Object error) {
    debugPrint('ArchivedNotesViewModel: $message — $error');
    showErrorToast(message, dedupeKey: 'archived-mutation');
  }
}
