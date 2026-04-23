# ModuNote — Thread Handoff Summary
> Paste this into a new Claude conversation to continue development.

---

## Status: Phase 1 ✅ Complete. Proceed with Phase 2.

Phase 1 is fully complete and verified. The Flutter project skeleton is built, all
files are in place, and the one post-phase bug (described below) has been fixed.

---

## What was built (Phase 1)

A runnable Flutter skeleton — 38 files, zero business logic.

**Root config**: `pubspec.yaml` (13 runtime + 6 dev deps), `analysis_options.yaml`
(flutter_lints + riverpod_lint), `build.yaml` (Riverpod + Drift codegen), `.gitignore`

**Entry**: `lib/main.dart` → `WidgetsFlutterBinding` + `ProviderScope` + `runApp`
`lib/app.dart` → `ModuNoteApp extends ConsumerWidget`, `MaterialApp.router`,
watches `routerProvider` + `themeModeProvider`

**Core layer** (`lib/core/`):
- `theme/app_colors.dart` — all 34 design tokens (17 light, 17 dark + 3 shared)
- `theme/app_typography.dart` — Plus Jakarta Sans + Inter via GoogleFonts
- `theme/app_theme.dart` — `AppTheme.light()` / `AppTheme.dark()` with M3 ColorScheme.fromSeed
- `constants/app_constants.dart` — string keys, limits, audio spec constants
- `errors/app_exception.dart` — sealed `AppException` + 5 subtypes
- `extensions/string_extensions.dart` — `isBlank`, `normalised`, `truncate`, etc.
- `utils/uuid_generator.dart` — `UuidGenerator.generate()` wrapper

**Data models** (`lib/data/models/`):
- `note.dart` — `Note` + `SyncStatus` enum
- `tag.dart` — `Tag` (lowercase name)
- `category.dart` — `Category` (adjacency list, parentId nullable)
- `audio_record.dart` — `AudioRecord` (AAC, transcribedText nullable)

**Repository interfaces** (`lib/data/repositories/interfaces/`):
- `i_note_repository.dart` — watchAll, watchByTag, watchByCategory, findById, search, insert, update, archive, delete, togglePin
- `i_tag_repository.dart` — watchAll, searchByPrefix, findByName, findByNote, insert, addToNote, removeFromNote, setTagsForNote, delete
- `i_category_repository.dart` — watchAll, findChildren, findById, insert, update, delete, move

**Stubs** (filled in later phases):
- `lib/data/repositories/local/` — 3 stub files (Phase 2)
- `lib/data/datasources/local/` + `file/` — Phase 2 / Phase 6
- `lib/services/speech/` + `audio/` — Phase 6

**Router + screens**:
- `lib/presentation/router/app_router.dart` — GoRouter (6 routes), `routerProvider`, `ThemeModeNotifier`, `themeModeProvider`
- `lib/presentation/router/app_router.g.dart` — pre-generated stub (3 providers)
- 5 placeholder screens (NoteListScreen, NoteEditorScreen, SearchScreen, TagsScreen, SettingsScreen)

**Meta files**:
- `CLAUDE.md` — AI agent onboarding context (architecture, conventions, phase status)
- `progress.md` — human-readable phase log + decisions log + bugfix log

---

## Bug fixed after Phase 1

**Error**: `Undefined name 'themeModeNotifierProvider'` in `app_router.dart`

**Cause**: The pre-generated `app_router.g.dart` stub was missing the
`themeModeProvider` definition (for the `themeMode` convenience function).
A missing symbol in a `part` file causes Dart to treat the whole part as broken,
making all symbols from it — including `themeModeNotifierProvider` — appear undefined.

**Fix**: Added the `themeModeProvider` block to the stub. The stub now correctly
defines all three generated symbols: `routerProvider`, `themeModeNotifierProvider`,
`themeModeProvider`, and the `_$ThemeModeNotifier` abstract base class.

---

## First-run instructions (for the developer)

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Expected: Material 3 scaffold, "ModuNote" app bar, "📝 Note List / Phase 4 — coming soon"
centred on screen, amber FAB bottom-right.

---

## Architecture decisions locked in Phase 1

| Decision | Value |
|---|---|
| State management | Riverpod 2 + code-gen (`@riverpod` annotations) |
| Local DB | Drift v2 |
| Navigation | GoRouter v14 |
| Rich text editor | flutter_quill v10 (Quill Delta JSON) |
| Audio | flutter_sound v9 — AAC 32kbps mono 16kHz (~0.24 MB/min) |
| Voice-to-text | speech_to_text v7 (on-device) |
| Fonts | Plus Jakarta Sans (headings) + Inter (body) via google_fonts |
| Model equality | Equatable (not freezed) — simpler, less codegen |
| Tag storage | Lowercase normalised via `StringExtensions.normalised` |
| UUID | `UuidGenerator.generate()` wrapper — never call `Uuid().v4()` directly |
| Category hierarchy | Adjacency list, max depth 5 |
| SyncStatus | Included in Note from day one — Firebase prep for Phase 10 |
| ThemeMode | Defaults to `ThemeMode.system`, toggled via `ThemeModeNotifier` |
| Firebase strategy | Repository interface swap — Phase 10 |
| Backend stack | FastAPI + PostgreSQL + SQLAlchemy async — Phase 11 |
| AI features | Deferred to Phase 12 |

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

---

## Pending decisions (to be resolved in later phases)

| Decision | Phase |
|---|---|
| Category deletion policy when children exist (cascade vs re-parent) | 8 |
| AI provider evaluation (Gemini free tier vs Groq) | 12 |

---

## Phase 2 — What to build next

**Title**: Data layer — Drift schema, DAOs, Repositories

**Scope**:
1. `AppDatabase` class (Drift) with all 5 tables
2. Table definitions: `NotesTable`, `TagsTable`, `CategoriesTable`, `AudioRecordsTable`, `NoteTagsTable` (join)
3. 4 DAOs: `NotesDao`, `TagsDao`, `CategoriesDao`, `AudioRecordsDao`
4. Type converters: `DateTime ↔ int`, `Map<String,dynamic> ↔ String` (Quill Delta JSON), `List<String> ↔ String`, `SyncStatus ↔ String`
5. `LocalNoteRepository`, `LocalTagRepository`, `LocalCategoryRepository` — implementing the Phase 1 interfaces
6. Riverpod providers for the database and repositories (registered for DI)
7. Full-text search (Drift FTS5 virtual table on notes)
8. Update `CLAUDE.md` and `progress.md`

**Before starting Phase 2**, Claude should present a detailed summary of every
architectural decision (Drift table design, DAO method signatures, FTS approach,
provider registration strategy) for developer approval — per project protocol.

---

## Files in this project (attach to new thread)

The developer has the following files to attach:
- `CLAUDE.md` — AI context
- `progress.md` — phase log
- `MODUNOTE_UI_REFERENCE.md` — design spec
- The Phase 1 zip (`modunote_phase1_fixed.zip`) for file-level reference if needed
