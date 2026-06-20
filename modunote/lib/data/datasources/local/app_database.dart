import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'converters/type_converters.dart';
export 'converters/type_converters.dart';
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
  AppDatabase(super.e);

  /// Creates the platform-appropriate [QueryExecutor].
  /// On web: uses WASM SQLite via drift_flutter's DriftWebOptions
  ///   (requires sqlite3.wasm + drift_worker.js in the web/ folder).
  /// On native: uses driftDatabase() with the existing modunote.db file path.
  static QueryExecutor createExecutor() {
    if (kIsWeb) {
      return driftDatabase(
        name: 'modunote',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      );
    }
    return driftDatabase(name: 'modunote.db');
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createFtsVirtualTableAndTriggers();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Fix FTS5 UPDATE and DELETE triggers — the original triggers used
            // UPDATE/DELETE SQL on the virtual table which is not valid for
            // external content FTS5 tables. Replace with the correct
            // 'delete' special INSERT form documented by SQLite.
            await customStatement('DROP TRIGGER IF EXISTS notes_fts_update');
            await customStatement('DROP TRIGGER IF EXISTS notes_fts_delete');
            await customStatement('''
              CREATE TRIGGER IF NOT EXISTS notes_fts_update
              AFTER UPDATE ON notes BEGIN
                INSERT INTO notes_fts(notes_fts, rowid, title, content)
                  VALUES('delete', old.rowid, old.title, old.content);
                INSERT INTO notes_fts(rowid, title, content)
                  VALUES(new.rowid, new.title, new.content);
              END
            ''');
            await customStatement('''
              CREATE TRIGGER IF NOT EXISTS notes_fts_delete
              AFTER DELETE ON notes BEGIN
                INSERT INTO notes_fts(notes_fts, rowid, title, content)
                  VALUES('delete', old.rowid, old.title, old.content);
              END
            ''');
            // Rebuild the FTS index from the current notes table to correct
            // any stale entries left by the broken triggers.
            await customStatement(
                "INSERT INTO notes_fts(notes_fts) VALUES('rebuild')");
          }
        },
      );

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

    // AFTER UPDATE trigger — removes old FTS entry then inserts the new one.
    // Must use the FTS5 'delete' special INSERT (not SQL UPDATE/DELETE) for
    // external content tables; plain UPDATE/DELETE on notes_fts is unsupported.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_fts_update
      AFTER UPDATE ON notes BEGIN
        INSERT INTO notes_fts(notes_fts, rowid, title, content)
          VALUES('delete', old.rowid, old.title, old.content);
        INSERT INTO notes_fts(rowid, title, content)
          VALUES(new.rowid, new.title, new.content);
      END
    ''');

    // AFTER DELETE trigger — removes the FTS entry after the note is deleted.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_fts_delete
      AFTER DELETE ON notes BEGIN
        INSERT INTO notes_fts(notes_fts, rowid, title, content)
          VALUES('delete', old.rowid, old.title, old.content);
      END
    ''');
  }
}
