import 'package:drift/drift.dart';

import '../../../core/errors/app_exception.dart';
import '../../models/note.dart';
import '../../repositories/interfaces/i_note_repository.dart';
import '../../datasources/local/app_database.dart';
import '../../datasources/local/daos/notes_dao.dart';

/// Local Drift implementation of [INoteRepository].
///
/// All public methods delegate to [NotesDao] and map between [NoteRow]
/// (Drift data class) and [Note] (domain model).
///
/// Drift exceptions are caught at every DAO call site and wrapped in
/// [DatabaseException] before surfacing to the ViewModel layer.
class LocalNoteRepository implements INoteRepository {
  final NotesDao _notesDao;

  const LocalNoteRepository(this._notesDao);

  // ── Watch streams ──────────────────────────────────────────────────────────

  @override
  Stream<List<Note>> watchAll() {
    return _notesDao
        .watchAll()
        .map((rows) => rows.map(_rowToNote).toList());
  }

  @override
  Stream<List<Note>> watchByTag(String tagId) {
    return _notesDao
        .watchByTag(tagId)
        .map((rows) => rows.map(_rowToNote).toList());
  }

  @override
  Stream<List<Note>> watchByCategory(String categoryId) {
    return _notesDao
        .watchByCategory(categoryId)
        .map((rows) => rows.map(_rowToNote).toList());
  }

  // ── Single-shot reads ──────────────────────────────────────────────────────

  @override
  Future<Note?> findById(String id) async {
    try {
      final row = await _notesDao.findById(id);
      return row == null ? null : _rowToNote(row);
    } on Exception catch (e) {
      throw DatabaseException(
        'Failed to find note by id: $id',
        cause: e,
      );
    }
  }

  @override
  Future<List<Note>> search(String query) async {
    try {
      final rows = await _notesDao.search(query);
      return rows.map(_rowToNote).toList();
    } on Exception catch (e) {
      throw DatabaseException(
        'Full-text search failed for query: "$query"',
        cause: e,
      );
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  @override
  Future<Note> insert(Note note) async {
    try {
      final companion = _noteToCompanion(note);
      await _notesDao.insertNote(companion);
      return note;
    } on Exception catch (e) {
      throw DatabaseException(
        'Failed to insert note: ${note.id}',
        cause: e,
      );
    }
  }

  @override
  Future<Note> update(Note note) async {
    try {
      final companion = _noteToCompanion(note);
      await _notesDao.updateNote(companion);
      return note;
    } on Exception catch (e) {
      throw DatabaseException(
        'Failed to update note: ${note.id}',
        cause: e,
      );
    }
  }

  @override
  Future<void> archive(String id) async {
    try {
      await _notesDao.archiveNote(id);
    } on Exception catch (e) {
      throw DatabaseException(
        'Failed to archive note: $id',
        cause: e,
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _notesDao.deleteNote(id);
    } on Exception catch (e) {
      throw DatabaseException(
        'Failed to delete note: $id',
        cause: e,
      );
    }
  }

  @override
  Future<Note?> togglePin(String id) async {
    try {
      final existing = await _notesDao.findById(id);
      if (existing == null) return null;
      final newPinned = !existing.isPinned;
      await _notesDao.togglePin(id, pinned: newPinned);
      final updated = await _notesDao.findById(id);
      return updated == null ? null : _rowToNote(updated);
    } on Exception catch (e) {
      throw DatabaseException(
        'Failed to toggle pin for note: $id',
        cause: e,
      );
    }
  }

  // ── Mapping helpers ────────────────────────────────────────────────────────

  /// Converts a [NoteRow] from Drift into the domain [Note] model.
  Note _rowToNote(NoteRow row) => Note(
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

  /// Converts a domain [Note] model into a [NotesTableCompanion] for Drift.
  NotesTableCompanion _noteToCompanion(Note note) => NotesTableCompanion.insert(
        id: note.id,
        title: note.title,
        content: note.content,
        categoryId: Value(note.categoryId),
        tagIds: Value(note.tagIds),
        isPinned: Value(note.isPinned),
        isArchived: Value(note.isArchived),
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
        syncStatus: Value(note.syncStatus.name),
      );

  /// Parses the string [value] into a [SyncStatus] enum, defaulting to
  /// [SyncStatus.local] for unknown values to guard against schema drift.
  SyncStatus _parseSyncStatus(String value) =>
      SyncStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => SyncStatus.local,
      );
}
