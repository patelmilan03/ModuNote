# ModuNote — Thread Handoff Summary
> Paste this into a new Claude conversation to continue development.

---

## Status: Phase 2 ✅ Complete. Proceed with Phase 3.

Phase 2 is fully complete and verified. The entire Drift data layer is in place —
5 tables, 4 DAOs, type converters, 3 local repository implementations, and Riverpod
providers wiring everything to the repository interfaces. `flutter analyze` reports
0 errors. The app boots to NoteListScreen.

> **Session interruption note**: Phase 2 was completed across two sessions. The first
> session committed partial work (app_database, notes_dao, tags_dao, and the 3 local repos)
> before stopping. The second session found and fixed multiple bugs in those files (wrong
> companion naming convention, wrong DatabaseException params, wrong import paths,
> interface/implementation mismatches, dependency version conflicts), created all missing
> files, ran build_runner successfully (93 outputs), and committed the completed phase.
> See "Phase 2 bugs fixed" below.

---

## What was built (Phase 1)

A runnable Flutter skeleton — 38 files, zero business logic.

**Root config**: `pubspec.yaml` (13 runtime + 6 dev deps), `analysis_options.yaml`
(flutter_lints + riverpod_lint), `build.yaml` (Riverpod + Drift codegen), `.gitignore`

**Entry**: `lib/main.dart` → `WidgetsFlutterBinding` + `ProviderScope` + `runApp`
`lib/app.dart` → `ModuNoteApp extends ConsumerWidget`, `MaterialApp.router`,
watches `routerProvider` + `themeModeNotifierProvider`

**Core layer** (`lib/core/`):
- `theme/app_colors.dart` — all 34 design tokens (17 light, 17 dark + 3 shared)
- `theme/app_typography.dart` — Plus Jakarta Sans + Inter via GoogleFonts
- `theme/app_theme.dart` — `AppTheme.light()` / `AppTheme.dark()` with M3 ColorScheme.fromSeed
- `constants/app_constants.dart` — string keys, limits, audio spec constants
- `errors/app_exception.dart` — sealed `AppException` + 5 subtypes
- `extensions/string_extensions.dart` — `isBlank`, `normalised`, `truncate`, etc.
- `utils/uuid_generator.dart` — `UuidGenerator.generate()` wrapper
- `utils/string_extensions.dart` — re-export shim for `extensions/string_extensions.dart`

**Data models** (`lib/data/models/`):
- `note.dart` — `Note` + `SyncStatus` enum
- `tag.dart` — `Tag` (lowercase name)
- `category.dart` — `Category` (adjacency list, parentId nullable)
- `audio_record.dart` — `AudioRecord` (AAC, transcribedText nullable)

**Repository interfaces** (`lib/data/repositories/interfaces/`):
- `i_note_repository.dart` — watchAll, watchByTag, watchByCategory, findById, search, insert, update, archive, delete, togglePin
- `i_tag_repository.dart` — watchAll, searchByPrefix, findByName, findById, findByNote, insert(String name), addTagToNote, removeTagFromNote, setTagsForNote, delete
- `i_category_repository.dart` — watchAll, findChildren(String parentId), findRoots, findById, insert, update, delete, move, updateSortOrder

**Router + screens**:
- `lib/presentation/router/app_router.dart` — GoRouter (6 routes), `routerProvider`, `ThemeModeNotifier`
- 5 placeholder screens (NoteListScreen, NoteEditorScreen, SearchScreen, TagsScreen, SettingsScreen)

---

## What was built (Phase 2)

The complete Drift data layer — schema, converters, DAOs, repositories, and Riverpod DI.

### `lib/data/datasources/local/`

- `app_database.dart` — `@DriftDatabase(tables: [NotesTable, TagsTable, NoteTagsTable, CategoriesTable, AudioRecordsTable], daos: [NotesDao, TagsDao, CategoriesDao, AudioRecordsDao])`. Includes FTS5 virtual table `notes_fts` + 3 SQLite triggers (INSERT/UPDATE/BEFORE DELETE). `MigrationStrategy` with `onCreate`.
- `database_providers.dart` — 4 Riverpod providers, all `keepAlive: true`:
  - `appDatabaseProvider` — opens DB, calls `ref.onDispose(db.close)`
  - `noteRepositoryProvider` → `LocalNoteRepository(db.notesDao)`
  - `tagRepositoryProvider` → `LocalTagRepository(db.tagsDao)`
  - `categoryRepositoryProvider` → `LocalCategoryRepository(db.categoriesDao)`

### `lib/data/datasources/local/converters/`

- `type_converters.dart`:
  - `QuillDeltaConverter` — `Map<String,dynamic>` ↔ JSON `String`; fallback to `{ops:[{insert:'\n'}]}` on bad JSON
  - `DateTimeConverter` — `DateTime` ↔ `int` (milliseconds since epoch, UTC)
  - `StringListConverter` — `List<String>` ↔ JSON `String`; fallback to `[]` on bad JSON

### `lib/data/datasources/local/tables/`

- `notes_table.dart` — `@DataClassName('NoteRow')`. Columns: id, title, content (QuillDeltaConverter), categoryId (nullable), tagIds (StringListConverter, default `'[]'`), isPinned (default false), isArchived (default false), createdAt/updatedAt (DateTimeConverter), syncStatus (default `'local'`). PK: `{id}`.
- `tags_table.dart` — `@DataClassName('TagRow')`. `name` uses `.customConstraint('NOT NULL UNIQUE')`.
- `note_tags_table.dart` — `@DataClassName('NoteTagRow')`. Composite PK: `{noteId, tagId}`.
- `categories_table.dart` — `@DataClassName('CategoryRow')`. `parentId` nullable. `sortOrder` defaults to `0`.
- `audio_records_table.dart` — `@DataClassName('AudioRecordRow')`. `transcribedText` nullable. `codec` defaults to `'aac'`.

### `lib/data/datasources/local/daos/`

- `notes_dao.dart` — watchAll (ordered updatedAt DESC), watchByTag (join), watchByCategory (filter + updatedAt DESC), findById, search (FTS5 MATCH), insertNote, updateNote, archiveNote (sets isArchived=true), deleteNote, togglePin, updateTagIds
- `tags_dao.dart` — watchAll (name ASC), searchByPrefix (LIKE `prefix%`), findByName, findById, findByNote (join), insertTag, deleteTag, addTagToNote, removeTagFromNote, setTagsForNote (transaction: delete all → insert new → `_syncDenormalisedTagIds`), `_syncDenormalisedTagIds` (reads join table, writes tagIds JSON to note)
- `categories_dao.dart` — watchAll (sortOrder ASC, name ASC), findChildren(String parentId), findRoots (parentId IS NULL), findById, insertCategory, updateCategory (returns bool), deleteCategory, moveCategory (writes parentId only), updateSortOrder
- `audio_records_dao.dart` — watchByNote (createdAt ASC), findById, findByNote, totalFileSizeBytes (raw SQL COALESCE SUM), insertAudioRecord, updateTranscription (writes transcribedText only), deleteAudioRecord, deleteAllForNote

### `lib/data/repositories/local/`

- `local_note_repository.dart` — wraps `NotesDao`; maps `NoteRow` ↔ `Note`; parses `SyncStatus` from string
- `local_tag_repository.dart` — wraps `TagsDao`; normalises tag names via `StringExtensions.normalised` before write
- `local_category_repository.dart` — wraps `CategoriesDao`; maps `CategoryRow` ↔ `Category`

---

## Phase 2 bugs fixed

These bugs existed in files committed by the interrupted first session and were fixed before build_runner ran:

| Bug | Fix |
|---|---|
| Companion names: `NoteRowCompanion` etc. | Drift names companions after the TABLE class → `NotesTableCompanion`, `TagsTableCompanion`, `NoteTagsTableCompanion`, `CategoriesTableCompanion`, `AudioRecordsTableCompanion` |
| `DatabaseException(msg, originalError: e, stackTrace: st)` | Correct signature is `DatabaseException(String message, {Object? cause})` → fixed to `DatabaseException(msg, cause: e)` |
| Import paths: `'../datasources/local/…'` | Resolves to non-existent path; corrected to `'../../datasources/local/…'` |
| `string_extensions` import: `core/utils/` | File is at `core/extensions/`; fixed import + added `core/utils/string_extensions.dart` re-export |
| `ITagRepository`/`ICategoryRepository` mismatched signatures | Rewrote both interfaces to exactly match implementations |
| `intl` version conflict | Added `dependency_overrides: intl: '>=0.19.0 <0.21.0'` to `pubspec.yaml` |
| `custom_lint`/`riverpod_generator` incompatibility | Bumped to `custom_lint: ^0.7.6`, `riverpod_lint: ^2.4.0` |

---

## Architecture decisions locked in Phase 2

| Decision | Value |
|---|---|
| FTS5 full-text search | Virtual table + 3 SQLite triggers — always in sync, no app-level maintenance |
| Tag denormalisation | `tagIds` JSON column on `NotesTable` for O(1) ViewModel stream access |
| `setTagsForNote` | Runs inside Drift `transaction()` for atomicity; syncs denormalised column |
| TypeConverters | Applied at column level — Drift handles serialisation transparently |
| Companion naming | TABLE class name + `Companion` suffix (Drift codegen convention) |
| `DatabaseException` | `(String message, {Object? cause})` — the only extra param is `cause` |
| Data provider lifecycle | All 4 data-layer providers use `keepAlive: true` |
| DB dispose | `appDatabaseProvider` calls `ref.onDispose(db.close)` |
| `findChildren` non-nullable | Takes a required `String parentId`; root access via dedicated `findRoots()` |

---

## All architecture decisions (Phase 1 + 2)

| Decision | Value | Phase |
|---|---|---|
| State management | Riverpod 2 + code-gen (`@riverpod` annotations) | 1 |
| Local DB | Drift v2 | 1 |
| Navigation | GoRouter v14 | 1 |
| Rich text editor | flutter_quill v10 (Quill Delta JSON) | 1 |
| Audio | flutter_sound v9 — AAC 32kbps mono 16kHz (~0.24 MB/min) | 1 |
| Voice-to-text | speech_to_text v7 (on-device) | 1 |
| Fonts | Plus Jakarta Sans (headings) + Inter (body) via google_fonts | 1 |
| Model equality | Equatable (not freezed) — simpler, less codegen | 1 |
| Tag storage | Lowercase normalised via `StringExtensions.normalised` | 1 |
| UUID | `UuidGenerator.generate()` wrapper — never call `Uuid().v4()` directly | 1 |
| Category hierarchy | Adjacency list, max depth 5 | 1 |
| SyncStatus | Included in Note from day one — Firebase prep for Phase 10 | 1 |
| ThemeMode | Defaults to `ThemeMode.system`, toggled via `ThemeModeNotifier` | 1 |
| Firebase strategy | Repository interface swap — Phase 10 | 1 |
| Backend stack | FastAPI + PostgreSQL + SQLAlchemy async — Phase 11 | 1 |
| AI features | Deferred to Phase 12 | 1 |
| FTS5 full-text search | Virtual table + 3 SQLite triggers | 2 |
| Tag denormalisation | `tagIds` JSON column on `NotesTable` | 2 |
| Companion naming | TABLE class name + `Companion` (Drift codegen convention) | 2 |
| Type converters | `QuillDeltaConverter`, `DateTimeConverter`, `StringListConverter` | 2 |
| Data providers lifecycle | All 4 data-layer providers use `keepAlive: true` | 2 |

---

## Key conventions (enforce in all phases)

- All screen widgets extend `ConsumerWidget` — never `StatelessWidget` directly
- All providers use `@riverpod` annotation — no manual `Provider(...)` declarations
- ViewModels import repository **interfaces** only, never Drift DAOs directly
- All errors wrapped in `AppException` subtypes before surfacing to ViewModels
- Tag names always stored lowercase via `StringExtensions.normalised`
- UUIDs always via `UuidGenerator.generate()`
- Generated files (`*.g.dart`) are gitignored — never edit manually
- Run `dart run build_runner build --delete-conflicting-outputs` after any `@riverpod` or Drift table change
- Drift companions are named after the TABLE class: `NotesTableCompanion` not `NoteRowCompanion`
- `DatabaseException` signature: `DatabaseException(String message, {Object? cause})`

---

## Pending decisions (to be resolved in later phases)

| Decision | Phase |
|---|---|
| Category deletion policy when children exist (cascade vs re-parent) | 8 |
| AI provider evaluation (Gemini free tier vs Groq) | 12 |

---

## First-run instructions

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Expected: Material 3 scaffold, "ModuNote" app bar, "📝 Note List / Phase 4 — coming soon"
centred on screen, amber FAB bottom-right. Drift opens the SQLite database silently on launch.

---

## Phase 3 — What to build next

**Title**: State management — Riverpod providers + base ViewModels

**Scope**:
1. `NoteListViewModel` (`AsyncNotifier<List<Note>>`) — watches `noteRepositoryProvider`, exposes `watchAll()`, `archive()`, `togglePin()`, `delete()`
2. `NoteEditorViewModel` (`AsyncNotifier<Note?>`) — loads note by id (or null for new), exposes `save()`, `updateTitle()`, `updateContent()`, `addTag()`, `removeTag()`, `setCategory()`
3. `TagListViewModel` (`AsyncNotifier<List<Tag>>`) — watches `tagRepositoryProvider`, exposes `watchAll()`, `insert()`, `delete()`
4. `CategoryTreeViewModel` (`AsyncNotifier<List<Category>>`) — watches `categoryRepositoryProvider`, exposes `watchAll()`, `insert()`, `move()`, `delete()`
5. `SearchViewModel` (`Notifier<SearchState>`) — debounced search query → `noteRepositoryProvider.search()`
6. All ViewModels use `@riverpod` annotation + code-gen
7. Update `CLAUDE.md`, `progress.md`, `THREAD_HANDOFF.md`

**Before starting Phase 3**, Claude should present a detailed summary of every ViewModel's
state shape, provider type choice (`AsyncNotifier` vs `Notifier`), and error handling strategy
for developer approval — per project protocol.

---

## Files to attach to new thread

- `CLAUDE.md` — AI context (architecture, conventions, phase status)
- `progress.md` — phase log + decisions log
- `MODUNOTE_UI_REFERENCE.md` — design spec (required before any UI work)
- `THREAD_HANDOFF.md` — this file
