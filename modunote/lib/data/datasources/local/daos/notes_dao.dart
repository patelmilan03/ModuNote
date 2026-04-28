import 'package:drift/drift.dart';

import '../app_database.dart';

part 'notes_dao.g.dart';

/// DAO responsible for all [NotesTable] and FTS5 search operations.
///
/// [NoteTagsTable] is included so JOIN-based tag-filter queries can be
/// expressed without crossing DAO boundaries.
@DriftAccessor(tables: [NotesTable, NoteTagsTable])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  // ── Watch queries ──────────────────────────────────────────────────────────

  /// Streams all non-archived notes ordered by pin status then recency.
  Stream<List<NoteRow>> watchAll() {
    return (select(notesTable)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Streams non-archived notes that carry [tagId] via [NoteTagsTable].
  Stream<List<NoteRow>> watchByTag(String tagId) {
    final query = select(notesTable).join([
      innerJoin(
        noteTagsTable,
        noteTagsTable.noteId.equalsExp(notesTable.id),
      ),
    ])
      ..where(noteTagsTable.tagId.equals(tagId))
      ..where(notesTable.isArchived.equals(false))
      ..orderBy([
        OrderingTerm(expression: notesTable.isPinned, mode: OrderingMode.desc),
        OrderingTerm(
            expression: notesTable.updatedAt, mode: OrderingMode.desc),
      ]);
    return query.map((row) => row.readTable(notesTable)).watch();
  }

  /// Streams non-archived notes belonging to [categoryId].
  Stream<List<NoteRow>> watchByCategory(String categoryId) {
    return (select(notesTable)
          ..where((t) =>
              t.categoryId.equals(categoryId) & t.isArchived.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
            (t) => OrderingTerm(
                expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  // ── Single-row queries ─────────────────────────────────────────────────────

  /// Returns the note with the given [id], or null if not found.
  Future<NoteRow?> findById(String id) {
    return (select(notesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ── FTS5 search ───────────────────────────────────────────────────────────

  /// Full-text searches non-archived notes using the FTS5 [notes_fts] virtual
  /// table (created in [AppDatabase.migration]).
  ///
  /// [query] is sanitised and a trailing `*` is appended for prefix matching.
  /// Returns an empty list if [query] is blank after sanitisation.
  Future<List<NoteRow>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    // Strip FTS special characters that could break MATCH syntax, then add *
    // for prefix matching so "tokyo" matches "Tokyo vlog" etc.
    final sanitised = trimmed
        .replaceAll(RegExp(r'["\(\)\-\+\*:,]'), ' ')
        .trim();
    if (sanitised.isEmpty) return [];
    final ftsQuery = '$sanitised*';

    final rows = await customSelect(
      'SELECT n.* FROM notes n '
      'INNER JOIN notes_fts ON notes_fts.rowid = n.rowid '
      'WHERE notes_fts MATCH ? '
      'AND n.is_archived = 0 '
      'ORDER BY notes_fts.rank',
      variables: [Variable.withString(ftsQuery)],
      readsFrom: {notesTable},
    ).get();

    return rows.map((row) => notesTable.map(row.data)).toList();
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Inserts a new note row. Throws if [id] already exists.
  Future<void> insertNote(NotesTableCompanion companion) async {
    await into(notesTable).insert(companion);
  }

  /// Updates an existing note row. Returns true if a row was updated.
  Future<bool> updateNote(NotesTableCompanion companion) async {
    final count = await (update(notesTable)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(companion);
    return count > 0;
  }

  /// Sets [isArchived] = true and clears the pin on the note with [id].
  Future<void> archiveNote(String id) async {
    await (update(notesTable)..where((t) => t.id.equals(id))).write(
      const NotesTableCompanion(
        isArchived: Value(true),
        isPinned: Value(false),
      ),
    );
  }

  /// Hard-deletes the note with [id]. Returns the number of rows deleted.
  Future<int> deleteNote(String id) async {
    return (delete(notesTable)..where((t) => t.id.equals(id))).go();
  }

  /// Sets the pinned state of the note with [id] to [pinned].
  Future<void> togglePin(String id, {required bool pinned}) async {
    await (update(notesTable)..where((t) => t.id.equals(id))).write(
      NotesTableCompanion(isPinned: Value(pinned)),
    );
  }

  /// Updates the denormalised [tagIds] JSON column for [id].
  ///
  /// Called exclusively by [TagsDao._syncDenormalisedTagIds] inside a
  /// transaction — callers should not invoke this directly.
  Future<void> updateTagIds(String id, List<String> tagIds) async {
    await (update(notesTable)..where((t) => t.id.equals(id))).write(
      NotesTableCompanion(tagIds: Value(tagIds)),
    );
  }
}
