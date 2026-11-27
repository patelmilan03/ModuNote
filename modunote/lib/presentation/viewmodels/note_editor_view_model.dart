import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/local/database_providers.dart';
import '../../data/models/note.dart';

part 'note_editor_view_model.g.dart';

@riverpod
class NoteEditorViewModel extends _$NoteEditorViewModel {
  // True until the first successful insert; flipped to false after that.
  bool _isNew = false;

  // Riverpod 2 has no `ref.mounted`: track disposal ourselves so async
  // continuations never write [state] on a disposed notifier.
  bool _alive = true;

  @override
  Future<Note?> build({String? noteId}) async {
    _isNew = noteId == null;
    _alive = true;
    ref.onDispose(() => _alive = false);
    if (noteId == null) return null;
    return ref.read(noteRepositoryProvider).findById(noteId);
  }

  Future<void> save(Note note) async {
    // Keep the previous note readable while the write is in flight: addTag /
    // removeTag / setCategory / togglePin bail out on a null valueOrNull, so a
    // bare AsyncLoading would silently drop an edit that lands mid-save.
    state = const AsyncLoading<Note?>().copyWithPrevious(state);
    try {
      final repo = ref.read(noteRepositoryProvider);
      if (_isNew) {
        await repo.insert(note);
        _isNew = false;
      } else {
        await repo.update(note);
      }
      state = AsyncData(note);
    } catch (e, st) {
      debugPrint('NoteEditorViewModel: save failed — $e');
      if (_alive) state = AsyncError(e, st);
    }
  }

  Future<void> updateTitle(String title) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await save(current.copyWith(title: title, updatedAt: DateTime.now()));
  }

  Future<void> updateContent(Map<String, dynamic> content) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await save(current.copyWith(content: content, updatedAt: DateTime.now()));
  }

  Future<void> addTag(String tagId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      await ref.read(tagRepositoryProvider).addTagToNote(current.id, tagId);
      await _reload(current.id);
    } catch (e, st) {
      if (_alive) state = AsyncError(e, st);
    }
  }

  Future<void> removeTag(String tagId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      await ref.read(tagRepositoryProvider).removeTagFromNote(current.id, tagId);
      await _reload(current.id);
    } catch (e, st) {
      if (_alive) state = AsyncError(e, st);
    }
  }

  // Note.copyWith cannot clear a nullable field (null means "keep old value").
  // Construct the Note directly so categoryId: null is honoured.
  Future<void> setCategory(String? categoryId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = Note(
      id: current.id,
      title: current.title,
      content: current.content,
      categoryId: categoryId,
      tagIds: current.tagIds,
      isPinned: current.isPinned,
      isArchived: current.isArchived,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: current.syncStatus,
    );
    await save(updated);
  }

  Future<void> togglePin(String noteId) async {
    try {
      await ref.read(noteRepositoryProvider).togglePin(noteId);
      await _reload(noteId);
    } catch (e, st) {
      if (_alive) state = AsyncError(e, st);
    }
  }

  /// Re-reads [noteId] after a repository mutation and publishes it.
  ///
  /// Skips the write when the editor was popped during the await (writing
  /// [state] on a disposed notifier throws) and when the note no longer exists
  /// (e.g. deleted concurrently) — publishing `AsyncData(null)` would blank
  /// the view-model, so the last known note is kept instead.
  Future<void> _reload(String noteId) async {
    final updated = await ref.read(noteRepositoryProvider).findById(noteId);
    if (!_alive || updated == null) return;
    state = AsyncData(updated);
  }

  Future<void> archive(String noteId) async {
    try {
      await ref.read(noteRepositoryProvider).archive(noteId);
    } catch (e, st) {
      if (_alive) state = AsyncError(e, st);
    }
  }

  Future<void> delete(String noteId) async {
    try {
      await ref.read(noteRepositoryProvider).delete(noteId);
    } catch (e, st) {
      if (_alive) state = AsyncError(e, st);
    }
  }

  /// Pushes the note to Firestore via [SyncedNoteRepository.syncNote].
  /// Updates ViewModel state with the new [SyncStatus] and returns it.
  /// Called from [NoteEditorScreen._onBack] after the final local save.
  Future<SyncStatus> syncNote(String noteId) async {
    try {
      final newStatus =
          await ref.read(syncedNoteRepositoryProvider).syncNote(noteId);
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(syncStatus: newStatus));
      }
      return newStatus;
    } catch (_) {
      return SyncStatus.local;
    }
  }
}
