import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/datasources/local/database_providers.dart';
import '../../data/models/note.dart';

part 'note_editor_view_model.g.dart';

@riverpod
class NoteEditorViewModel extends _$NoteEditorViewModel {
  // True until the first successful insert; flipped to false after that.
  bool _isNew = false;

  @override
  Future<Note?> build({String? noteId}) async {
    _isNew = noteId == null;
    if (noteId == null) return null;
    return ref.read(noteRepositoryProvider).findById(noteId);
  }

  Future<void> save(Note note) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(noteRepositoryProvider);
      if (_isNew) {
        await repo.insert(note);
        _isNew = false;
      } else {
        await repo.update(note);
      }
      state = AsyncData(note);
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
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
      final updated = await ref.read(noteRepositoryProvider).findById(current.id);
      state = AsyncData(updated);
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> removeTag(String tagId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      await ref.read(tagRepositoryProvider).removeTagFromNote(current.id, tagId);
      final updated = await ref.read(noteRepositoryProvider).findById(current.id);
      state = AsyncData(updated);
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
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
}
