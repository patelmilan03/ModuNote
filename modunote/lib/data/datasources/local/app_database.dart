import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/notes_table.dart';
import 'tables/tags_table.dart';
import 'tables/note_tags_table.dart';
import 'tables/categories_table.dart';
import 'tables/audio_records_table.dart';
import 'daos/notes_dao.dart';
import 'daos/tags_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/audio_records_dao.dart';

export 'tables/notes_table.dart';
export 'tables/tags_table.dart';
export 'tables/note_tags_table.dart';
export 'tables/categories_table.dart';
export 'tables/audio_records_table.dart';
export 'daos/notes_dao.dart';
export 'daos/tags_dao.dart';
export 'daos/categories_dao.dart';
export 'daos/audio_records_dao.dart';

part 'app_database.g.dart';

/// The single Drift database for ModuNote.
///
/// Schema version: 1
///
/// Tables: notes, tags, note_tags, categories, audio_records
/// FTS5:   notes_fts (content table over notes, kept in sync by 3 triggers)
///
/// DAOs are exposed as [late final] fields so ViewModels can reach them via
/// the repository layer without accessing this class directly.
///
/// Migration strategy:
/// - onCreate: creates all tables, the FTS5 virtual table, and its three
///   triggers (insert / update / delete).
/// - onUpgrade: empty for schema version 1; real migrations added in Phase 10.
@DriftDatabase(
  tables: [
    NotesTable,
    TagsTable,
    NoteTagsTable,
    CategoriesTable,
    AudioRecordsTable,
  ],
  daos: [NotesDao, TagsDao, CategoriesDao, AudioRecordsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  /// Creates the platform-appropriate [QueryExecutor] backed by SQLite via
  /// drift_flutter.  File name: [modunote.db].
  static QueryExecutor createExecutor() =>
      driftDatabase(name: 'modunote.db');

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createFtsVirtualTableAndTriggers();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // No-op for schema version 1.
          // Add versioned migration steps here in Phase 10.
        },
      );

  // ── DAOs ───────────────────────────────────────────────────────────────────
  // Declared here so AppDatabase can be injected into services and repositories
  // without the caller needing to reference Drift internals.

  late final NotesDao notesDao = NotesDao(this);
  late final TagsDao tagsDao = TagsDao(this);
  late final CategoriesDao categoriesDao = CategoriesDao(this);
  late final AudioRecordsDao audioRecordsDao = AudioRecordsDao(this);

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Creates the FTS5 virtual table and three triggers that keep it in sync
  /// with the [notes] table.
  ///
  /// Using a content table (`content='notes'`) means the FTS index stores only
  /// the row IDs; the actual text is read back from [notes] during queries.
  /// The three triggers (AFTER INSERT, AFTER UPDATE, BEFORE DELETE) ensure the
  /// index is always consistent with the source table.
  Future<void> _createFtsVirtualTableAndTriggers() async {
    // FTS5 virtual table — indexes title + content columns from notes.
    await customStatement(
      'CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts '
      "USING fts5(title, content, content='notes', content_rowid='rowid')",
    );

    // AFTER INSERT trigger — adds a new FTS entry whenever a note is created.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_fts_insert
      AFTER INSERT ON notes BEGIN
        INSERT INTO notes_fts(rowid, title, content)
        VALUES (new.rowid, new.title, new.content);
      END
    ''');

    // AFTER UPDATE trigger — refreshes the FTS entry when a note is modified.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_fts_update
      AFTER UPDATE ON notes BEGIN
        UPDATE notes_fts
        SET title   = new.title,
            content = new.content
        WHERE rowid = new.rowid;
      END
    ''');

    // BEFORE DELETE trigger — removes the FTS entry before the note is deleted.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_fts_delete
      BEFORE DELETE ON notes BEGIN
        DELETE FROM notes_fts WHERE rowid = old.rowid;
      END
    ''');
  }
}
