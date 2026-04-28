import 'package:drift/drift.dart';

import '../app_database.dart';

part 'tags_dao.g.dart';

/// DAO responsible for [TagsTable] and the [NoteTagsTable] join table.
///
/// [setTagsForNote] is the primary write path for the note-tag relationship.
/// It runs atomically and keeps the denormalised [NoteRow.tagIds] column in
/// sync with [NoteTagsTable] via [_syncDenormalisedTagIds].
@DriftAccessor(tables: [TagsTable, NoteTagsTable])
class TagsDao extends DatabaseAccessor<AppDatabase> with _$TagsDaoMixin {
  TagsDao(super.db);

  // ── Watch queries ──────────────────────────────────────────────────────────

  /// Streams all tags ordered alphabetically by name.
  Stream<List<TagRow>> watchAll() {
    return (select(tagsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  // ── Single-shot queries ────────────────────────────────────────────────────

  /// Returns tags whose name starts with [prefix] (case-insensitive via
  /// lowercase normalisation applied at the repository layer).
  Future<List<TagRow>> searchByPrefix(String prefix) {
    if (prefix.isEmpty) return Future.value([]);
    return (select(tagsTable)
          ..where((t) => t.name.like('$prefix%'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Returns the tag with the exact [name], or null if not found.
  Future<TagRow?> findByName(String name) {
    return (select(tagsTable)..where((t) => t.name.equals(name)))
        .getSingleOrNull();
  }

  /// Returns the tag with the given [id], or null if not found.
  Future<TagRow?> findById(String id) {
    return (select(tagsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Returns all tags attached to [noteId] via [NoteTagsTable].
  Future<List<TagRow>> findByNote(String noteId) {
    final query = select(tagsTable).join([
      innerJoin(
        noteTagsTable,
        noteTagsTable.tagId.equalsExp(tagsTable.id),
      ),
    ])..where(noteTagsTable.noteId.equals(noteId));
    return query.map((row) => row.readTable(tagsTable)).get();
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Inserts a new tag. The name must already be lowercase-normalised by the
  /// repository layer. Throws on duplicate name (UNIQUE constraint).
  Future<void> insertTag(TagsTableCompanion companion) async {
    await into(tagsTable).insert(companion);
  }

  /// Hard-deletes the tag with [id]. Returns the row count (0 or 1).
  Future<int> deleteTag(String id) async {
    return (delete(tagsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Inserts a single [noteId]–[tagId] pair into [NoteTagsTable].
  /// Uses `InsertMode.insertOrIgnore` so calling this twice is idempotent.
  Future<void> addTagToNote(String noteId, String tagId) async {
    await db.transaction(() async {
      await into(noteTagsTable).insert(
        NoteTagsTableCompanion.insert(noteId: noteId, tagId: tagId),
        mode: InsertMode.insertOrIgnore,
      );
      await _syncDenormalisedTagIds(noteId);
    });
  }

  /// Removes the [noteId]–[tagId] pair from [NoteTagsTable].
  Future<void> removeTagFromNote(String noteId, String tagId) async {
    await db.transaction(() async {
      await (delete(noteTagsTable)
            ..where(
              (t) => t.noteId.equals(noteId) & t.tagId.equals(tagId),
            ))
          .go();
      await _syncDenormalisedTagIds(noteId);
    });
  }

  /// Atomically replaces all tags on [noteId] with [tagIds].
  ///
  /// Transaction steps:
  /// 1. Delete all existing rows in [NoteTagsTable] for [noteId].
  /// 2. Insert new rows for each tag id in [tagIds].
  /// 3. Sync the denormalised [NoteRow.tagIds] column via
  ///    [_syncDenormalisedTagIds].
  Future<void> setTagsForNote(String noteId, List<String> tagIds) async {
    await db.transaction(() async {
      await (delete(noteTagsTable)
            ..where((t) => t.noteId.equals(noteId)))
          .go();
      for (final tagId in tagIds) {
        await into(noteTagsTable).insert(
          NoteTagsTableCompanion.insert(noteId: noteId, tagId: tagId),
          mode: InsertMode.insertOrIgnore,
        );
      }
      await _syncDenormalisedTagIds(noteId);
    });
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Rebuilds the denormalised `tag_ids` TEXT column on the matching note row
  /// by reading the current state of [NoteTagsTable] and delegating to
  /// [NotesDao.updateTagIds].
  ///
  /// Always called inside an existing transaction.
  Future<void> _syncDenormalisedTagIds(String noteId) async {
    final pairs = await (select(noteTagsTable)
          ..where((t) => t.noteId.equals(noteId)))
        .get();
    final ids = pairs.map((r) => r.tagId).toList();
    await db.notesDao.updateTagIds(noteId, ids);
  }
}
