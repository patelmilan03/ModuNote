# ModuNote — Project Progress

> Updated at the end of every phase. Read this before starting any new phase.

---

## Project Identity

| Field | Value |
|---|---|
| App name | ModuNote |
| Flutter package | `modunote` |
| App ID | `com.modunote.app` |
| Platform | Android (iOS deferred) |
| Min Dart SDK | 3.3.0 |
| Min Flutter | 3.22.0 |
| Started | Phase 1 |

---

## Phase Status

| # | Phase | Status | Notes |
|---|---|---|---|
| 1 | Project setup & folder structure | ✅ **Complete** | See details below |
| 2 | Data layer (Drift schema, DAOs, Repositories) | ⬜ Not started | — |
| 3 | State management (Riverpod providers, base ViewModels) | ⬜ Not started | — |
| 4 | Note list screen | ⬜ Not started | — |
| 5 | Note editor screen (Quill) | ⬜ Not started | — |
| 6 | Voice-to-text + audio recording/playback | ⬜ Not started | — |
| 7 | Tags (freeform + autocomplete) | ⬜ Not started | — |
| 8 | Categories (hierarchical folder tree) | ⬜ Not started | — |
| 9 | Navigation + theming (GoRouter shell, M3 bottom nav) | ⬜ Not started | — |
| 10 | Firebase preparation layer | ⬜ Not started | — |
| 11 | Backend API scaffolding (FastAPI) | ⬜ Not started | — |
| 12 | AI features | ⬜ Not started | Deferred — post full app |

---

## Phase 1 — Project Setup & Folder Structure ✅

**Completed**: Phase 1
**Deliverable**: Runnable Flutter skeleton. `flutter run` boots to NoteListScreen placeholder.

### Files Created

#### Root
- `pubspec.yaml` — all 13 runtime + 6 dev dependencies locked
- `analysis_options.yaml` — flutter_lints + custom_lint (riverpod_lint)
- `build.yaml` — Riverpod generator + Drift codegen config
- `.gitignore` — excludes `*.g.dart`, build/, Android local config
- `CLAUDE.md` — AI agent context (architecture, conventions, phase status)
- `progress.md` — this file

#### `lib/`
- `main.dart` — `WidgetsFlutterBinding.ensureInitialized()` + `ProviderScope` + `runApp`
- `app.dart` — `ModuNoteApp extends ConsumerWidget`, `MaterialApp.router`, watches `routerProvider` + `themeModeProvider`

#### `lib/core/`
- `theme/app_colors.dart` — all 34 design tokens (17 light, 17 dark) + 3 shared
- `theme/app_typography.dart` — Plus Jakarta Sans + Inter helpers + `buildTextTheme()`
- `theme/app_theme.dart` — `AppTheme.light()` / `AppTheme.dark()` with Material 3 `ColorScheme.fromSeed`
- `constants/app_constants.dart` — string keys, note/tag/category limits, audio spec constants
- `errors/app_exception.dart` — sealed `AppException` + 5 subtypes (Database, FileStorage, NotFound, Validation, Permission)
- `extensions/string_extensions.dart` — `isBlank`, `isNotBlank`, `capitalised`, `normalised`, `truncate`
- `utils/uuid_generator.dart` — `UuidGenerator.generate()` wrapper

#### `lib/data/models/`
- `note.dart` — `Note` + `SyncStatus` enum (id, title, content, categoryId?, tagIds, isPinned, isArchived, createdAt, updatedAt, syncStatus)
- `tag.dart` — `Tag` (id, name lowercase, createdAt)
- `category.dart` — `Category` (id, name, parentId?, sortOrder, createdAt) with adjacency-list hierarchy
- `audio_record.dart` — `AudioRecord` (id, noteId, filePath, durationMs, fileSizeBytes, codec, transcribedText?, createdAt)

#### `lib/data/repositories/interfaces/`
- `i_note_repository.dart` — watchAll, watchByTag, watchByCategory, findById, search, insert, update, archive, delete, togglePin
- `i_tag_repository.dart` — watchAll, searchByPrefix, findByName, findByNote, insert, addToNote, removeFromNote, setTagsForNote, delete
- `i_category_repository.dart` — watchAll, findChildren, findById, insert, update, delete, move

#### `lib/data/repositories/local/` (stubs — Phase 2)
- `local_note_repository.dart`
- `local_tag_repository.dart`
- `local_category_repository.dart`

#### `lib/data/datasources/` (stubs — Phase 2 + 6)
- `local/.gitkeep` — Drift DAOs go here in Phase 2
- `file/.gitkeep` — AudioFileStorage goes here in Phase 6

#### `lib/services/` (stubs — Phase 6)
- `speech/speech_to_text_service.dart`
- `audio/audio_recording_service.dart`

#### `lib/presentation/`
- `router/app_router.dart` — GoRouter config, 6 routes, `routerProvider`, `ThemeModeNotifier`, `themeModeProvider`
- `router/app_router.g.dart` — pre-generated stub (replace by running build_runner)
- `views/note_list/note_list_screen.dart` — placeholder
- `views/note_editor/note_editor_screen.dart` — placeholder (accepts optional `noteId`)
- `views/search/search_screen.dart` — placeholder
- `views/tags/tags_screen.dart` — placeholder
- `views/settings/settings_screen.dart` — placeholder
- `viewmodels/.gitkeep` — AsyncNotifiers go here from Phase 3
- `widgets/.gitkeep` — shared widgets go here from Phase 4

### Post-Phase Fix (applied before Phase 2)

**Bug**: `Undefined name 'themeModeNotifierProvider'` in `app_router.dart`.

**Root cause**: The `themeMode` convenience provider (`@riverpod ThemeMode themeMode(Ref ref)`) referenced `themeModeNotifierProvider` — a name only defined in the generated `.g.dart`. Because the stub `.g.dart` didn't include the `_$ThemeModeNotifier` abstract base class, the class declaration `class ThemeModeNotifier extends _$ThemeModeNotifier` also failed to resolve, causing a cascade.

**Fix applied**:
1. Removed the `themeMode` convenience provider from `app_router.dart` entirely (was redundant).
2. Updated `app.dart` to watch `themeModeNotifierProvider` directly (`ref.watch(themeModeNotifierProvider)`).
3. Rewrote `app_router.g.dart` stub to include the `_$ThemeModeNotifier` abstract base class that Riverpod generator produces, and removed the now-deleted `themeMode` provider entry.

**Files changed**: `lib/app.dart`, `lib/presentation/router/app_router.dart`, `lib/presentation/router/app_router.g.dart`

---

### Decisions Recorded
- Android-only target at creation
- `equatable` over `freezed` for model equality (simpler, less codegen)
- Pre-written `app_router.g.dart` stub to avoid build_runner dependency at setup time
- `SyncStatus` enum included in `Note` from day one (Firebase prep)
- `ThemeModeNotifier` defaults to `ThemeMode.system`

### First-Run Instructions

```bash
# 1. Get dependencies
flutter pub get

# 2. Replace the pre-generated stub with real generated code
dart run build_runner build --delete-conflicting-outputs

# 3. Run
flutter run
```

Expected result: App launches with Material 3 scaffold, "ModuNote" in the app bar, "📝 Note List / Phase 4 — coming soon" centred on screen, amber FAB in the bottom-right.

---

---

## Phase 2 — Data Layer ✅

**Completed**: Phase 2
**Deliverable**: Full Drift schema, all DAOs, local repository implementations, and data-layer Riverpod providers wired to interfaces.

### Files Created

#### `lib/data/datasources/local/`
- `app_database.dart` — `@DriftDatabase` with 5 tables, 4 DAOs, FTS5 virtual table + 3 triggers (insert/update/delete), `MigrationStrategy`
- `app_database.g.dart` — stub (replace via `build_runner`); includes all 5 `$TableClass` impls + `_$AppDatabase`
- `row_classes.dart` — `NoteRow`, `TagRow`, `NoteTagRow`, `CategoryRow`, `AudioRecordRow` + 5 Companion classes
- `database_providers.dart` — `appDatabaseProvider`, `noteRepositoryProvider`, `tagRepositoryProvider`, `categoryRepositoryProvider` (all `keepAlive: true`)
- `database_providers.g.dart` — stub (replace via `build_runner`)

#### `lib/data/datasources/local/converters/`
- `type_converters.dart` — `QuillDeltaConverter`, `DateTimeConverter`, `StringListConverter`

#### `lib/data/datasources/local/tables/`
- `notes_table.dart` — `NotesTable` with `tagIds` denormalised column + `sync_status` default `'local'`
- `tags_table.dart` — `TagsTable` with unique constraint on `name`
- `note_tags_table.dart` — `NoteTagsTable` (composite PK: noteId + tagId)
- `categories_table.dart` — `CategoriesTable` with nullable `parentId`
- `audio_records_table.dart` — `AudioRecordsTable` with nullable `transcribedText`

#### `lib/data/datasources/local/daos/`
- `notes_dao.dart` — `watchAll`, `watchByTag`, `watchByCategory`, `findById`, `search` (FTS5), `insertNote`, `updateNote`, `archiveNote`, `deleteNote`, `togglePin`, `updateTagIds`
- `notes_dao.g.dart` — mixin stub
- `tags_dao.dart` — `watchAll`, `searchByPrefix`, `findByName`, `findById`, `findByNote`, `insertTag`, `deleteTag`, `addTagToNote`, `removeTagFromNote`, `setTagsForNote`, `_syncDenormalisedTagIds`
- `tags_dao.g.dart` — mixin stub
- `categories_dao.dart` — `watchAll`, `findChildren`, `findById`, `insertCategory`, `updateCategory`, `deleteCategory`, `moveCategory`
- `categories_dao.g.dart` — mixin stub
- `audio_records_dao.dart` — `watchByNote`, `findById`, `findByNote`, `totalFileSizeBytes`, `insertAudioRecord`, `updateTranscription`, `deleteAudioRecord`, `deleteAllForNote`
- `audio_records_dao.g.dart` — mixin stub

#### `lib/data/repositories/local/` (upgraded from stubs)
- `local_note_repository.dart` — implements `INoteRepository` via `NotesDao`; maps `NoteRow` ↔ `Note`; parses `SyncStatus` enum
- `local_tag_repository.dart` — implements `ITagRepository` via `TagsDao`; normalises tag names on write
- `local_category_repository.dart` — implements `ICategoryRepository` via `CategoriesDao`

### Decisions Recorded
- FTS5 virtual table with 3 SQLite triggers (insert/update/delete) for always-consistent full-text search
- `tagIds` denormalised column on `NotesTable` for O(1) tag list access in ViewModel streams
- `setTagsForNote` runs inside a Drift `transaction()` for atomicity
- All Drift exceptions wrapped in `DatabaseException` at the DAO boundary
- Row data classes and Companions extracted to `row_classes.dart` (normally generated — build_runner replaces)
- `appDatabaseProvider` calls `ref.onDispose(db.close)` for clean shutdown

---

## Decisions Log (cross-phase)

| Decision | Value | Phase set |
|---|---|---|
| State management | Riverpod 2 + code-gen | 1 |
| Local DB | Drift v2 | 1 |
| Navigation | GoRouter v14 | 1 |
| Rich text | flutter_quill v10 | 1 |
| Audio codec | AAC 32kbps mono 16kHz | 1 |
| Model equality | Equatable (not freezed) | 1 |
| Tag storage | lowercase normalised | 1 |
| Category structure | Adjacency list, max depth 5 | 1 |
| Firebase strategy | Repo interface swap (Phase 10) | 1 |
| Backend stack | FastAPI + PostgreSQL + SQLAlchemy async | 1 (planning) |
| AI features | Deferred to Phase 12 | 1 (planning) |
| Category deletion policy | **TBD — Phase 8** | — |
| AI provider (Gemini vs Groq) | **TBD — Phase 12** | — |

---

## Pending Decisions

| Decision | Phase to resolve |
|---|---|
| Category deletion policy when children exist (cascade vs re-parent) | 8 |
| AI provider evaluation (Gemini free tier vs Groq) | 12 |

---

## Post-Phase 1 Bugfix — app_router.g.dart stub incomplete

**Issue**: `Undefined name 'themeModeNotifierProvider'` error at compile time.

**Root cause**: The pre-generated `app_router.g.dart` stub was missing the
`themeModeProvider` entry (generated from the `themeMode` convenience function).
When a `part` file has a missing declaration, Dart marks the entire part as
broken — causing all symbols from it (including `themeModeNotifierProvider`) to
appear undefined, even though that definition was present.

**Fix**: Added the missing `themeModeProvider` block to `app_router.g.dart`.
The stub now contains all three generated symbols:
- `routerProvider` (from `router` function)
- `themeModeNotifierProvider` (from `ThemeModeNotifier` class)
- `themeModeProvider` (from `themeMode` convenience function) ← was missing

**File changed**: `lib/presentation/router/app_router.g.dart`

**Reminder**: This stub is only a compile-time shim. Running
`dart run build_runner build --delete-conflicting-outputs` replaces it with
the real generated output and should always be done before first run.
