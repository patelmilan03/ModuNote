import 'package:drift/drift.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../datasources/local/app_database.dart';
import '../../models/note.dart';
import '../interfaces/i_note_repository.dart';

class LocalNoteRepository implements INoteRepository {
  const LocalNoteRepository(this._dao);

  final NotesDao _dao;

  // ─── Streams ────────────────────────────────────────────────────────────────

  @override
  Stream<List<Note>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toModel).toList());

  @override
  Stream<List<Note>> watchByTag(String tagId) =>
      _dao.watchByTag(tagId).map((rows) => rows.map(_toModel).toList());

  @override
  Stream<List<Note>> watchByCategory(String categoryId) =>
      _dao.watchByCategory(categoryId).map((rows) => rows.map(_toModel).toList());

  // ─── Reads ───────────────────────────────────────────────────────────────────

  @override
  Future<Note?> findById(String id) async {
    final row = await _dao.findById(id);
    return row == null ? null : _toModel(row);
  }

  @override
  Future<List<Note>> search(String query) async {
    final rows = await _dao.search(query);
    return rows.map(_toModel).toList();
  }

  // ─── Writes ──────────────────────────────────────────────────────────────────

  @override
  Future<void> insert(Note note) async {
    await _dao.insertNote(_toCompanion(note));
  }

  @override
  Future<void> update(Note note) async {
    await _dao.updateNote(_toCompanion(note));
  }

  @override
  Future<void> archive(String id) => _dao.archiveNote(id);

  @override
  Future<void> delete(String id) => _dao.deleteNote(id);

  @override
  Future<void> togglePin(String id) => _dao.togglePin(id);

  // ─── Mapping ─────────────────────────────────────────────────────────────────

  Note _toModel(NoteRow row) => Note(
        id: row.id,
        title: row.title,
        content: row.content,
        categoryId: row.categoryId,
        tagIds: row.tagIds,
        isPinned: row.isPinned,
        isArchived: row.isArchived,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        syncStatus: _parseSyncStatus(row.syncStatus),
      );

  NotesTableCompanion _toCompanion(Note note) => NotesTableCompanion(
        id: Value(note.id),
        title: Value(note.title),
        content: Value(note.content),
        categoryId: Value(note.categoryId),
        tagIds: Value(note.tagIds),
        isPinned: Value(note.isPinned),
        isArchived: Value(note.isArchived),
        createdAt: Value(note.createdAt),
        updatedAt: Value(note.updatedAt),
        syncStatus: Value(note.syncStatus.name),
      );

  SyncStatus _parseSyncStatus(String value) =>
      SyncStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => SyncStatus.local,
      );
}
