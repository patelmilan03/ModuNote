# ModuNote — Thread Handoff Summary
> Paste this into a new Claude conversation to continue development.

---

## Status: Phase 3 ✅ Complete. Proceed with Phase 4.

Phase 3 is fully complete. All 5 Riverpod ViewModels are in place and wired to the
Phase 2 repository layer. `dart run build_runner build --delete-conflicting-outputs`
must be run by the developer to generate the `.g.dart` files, then `flutter analyze`
should report 0 errors. The app still boots to the NoteListScreen placeholder — no UI
changes were made in Phase 3.

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

The complete Drift data layer. See `progress.md § Phase 2` for full file list.

Key summary:
- `app_database.dart` — `@DriftDatabase` with 5 tables, 4 DAOs, FTS5 + 3 triggers
- `database_providers.dart` — `appDatabaseProvider`, `noteRepositoryProvider`, `tagRepositoryProvider`, `categoryRepositoryProvider` (all `keepAlive: true`)
- Tables: `NotesTable`, `TagsTable`, `NoteTagsTable`, `CategoriesTable`, `AudioRecordsTable`
- DAOs: `NotesDao`, `TagsDao`, `CategoriesDao`, `AudioRecordsDao`
- Repos: `LocalNoteRepository`, `LocalTagRepository`, `LocalCategoryRepository`
- Type converters: `QuillDeltaConverter`, `DateTimeConverter`, `StringListConverter`

---

## What was built (Phase 3)

All 5 Riverpod ViewModels in `lib/presentation/viewmodels/`.

### ViewModel signatures

#### `note_list_view_model.dart`
```dart
@riverpod
class NoteListViewModel extends _$NoteListViewModel {
  Stream<List<Note>> build()         // streams noteRepositoryProvider.watchAll()
  Future<void> archive(String id)
  Future<void> delete(String id)
  Future<void> togglePin(String id)
}
```

#### `note_editor_view_model.dart`
```dart
@riverpod
class NoteEditorViewModel extends _$NoteEditorViewModel {
  bool _isNew;   // true when noteId == null; flipped to false after first insert
  Future<Note?> build({String? noteId})   // null → new note, non-null → findById
  Future<void> save(Note note)
  Future<void> updateTitle(String title)
  Future<void> updateContent(Map<String, dynamic> content)
  Future<void> addTag(String tagId)        // uses tagRepositoryProvider + reloads note
  Future<void> removeTag(String tagId)     // uses tagRepositoryProvider + reloads note
  Future<void> setCategory(String? categoryId)  // constructs Note directly (no copyWith)
}
```

Usage: `ref.watch(noteEditorViewModelProvider())` for new note,
`ref.watch(noteEditorViewModelProvider(noteId: id))` for existing.

#### `tag_list_view_model.dart`
```dart
@riverpod
class TagListViewModel extends _$TagListViewModel {
  Stream<List<Tag>> build()          // streams tagRepositoryProvider.watchAll()
  Future<Tag> insert(String name)    // returns created Tag (Phase 7 UI needs it)
  Future<void> delete(String id)
}
```

#### `category_tree_view_model.dart`
```dart
@riverpod
class CategoryTreeViewModel extends _$CategoryTreeViewModel {
  Stream<List<Category>> build()     // flat list; Phase 8 UI builds tree from parentId
  Future<Category> insert({required String name, String? parentId, int sortOrder = 0})
  Future<void> move(String id, String? newParentId)
  Future<void> delete(String id)
}
```

#### `search_view_model.dart`
```dart
class SearchState {
  final String query;
  final AsyncValue<List<Note>> results;
  // copyWith(...)
}

@riverpod
class SearchViewModel extends _$SearchViewModel {
  Timer? _debounce;                  // cancelled via ref.onDispose
  SearchState build()                // initial: query='', results=AsyncData([])
  void setQuery(String query)        // debounced 300 ms; empty query clears immediately
  // _performSearch(query) — private
}
```

### Key design decisions (Phase 3)

| Decision | Detail |
|---|---|
| Stream VMs: `build() → Stream<T>` | Riverpod generates `StreamNotifier` — each emission auto-wrapped as `AsyncData<T>`. No `.listen()` in ViewModels. |
| `NoteEditorViewModel` uses Future | No `watchById` on `INoteRepository`; state is managed manually after each mutation. |
| `_isNew` for insert/update | Set in `build()`, cleared after first `insert`. No extra DB round-trip. |
| `setCategory(null)` bypasses `copyWith` | `Note.copyWith(categoryId: null)` keeps old value (Dart limitation). Constructor used directly. |
| `SearchState` Notifier pattern | Original D3.5 listed `AsyncNotifier<List<Note>>` — confirmed wrong by developer. `Notifier<SearchState>` correct. |
| Error handling | All mutations catch `AppException`, set `state = AsyncError(e, st)`. Non-AppException errors are not caught (DAO layer boundary). |

---

## Architecture decisions locked in Phase 3

| Decision | Value |
|---|---|
| ViewModel stream pattern | `build() → Stream<T>` for list VMs |
| NoteEditorViewModel family param | Optional `noteId`; `_isNew` flag |
| SearchState pattern | `Notifier<SearchState>`; 300 ms debounce |
| `setCategory(null)` | Direct constructor; no `copyWith` |

---

## All architecture decisions (Phases 1–3)

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
| ViewModel stream pattern | `build() → Stream<T>` for list VMs | 3 |
| NoteEditorViewModel family param | Optional `noteId`; `_isNew` flag for insert/update | 3 |
| SearchState pattern | `Notifier<SearchState>`; 300 ms debounce | 3 |

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
- **Claude may create/edit files locally** — but must never run `git commit`, `git push`, `git pull`, or any git command touching GitHub. All commits made exclusively by the developer using GitHub Desktop.

---

## Pending decisions (to be resolved in later phases)

| Decision | Phase |
|---|---|
| Category deletion policy when children exist (cascade vs re-parent) | 8 |
| AI provider evaluation (Gemini free tier vs Groq) | 12 |

---

## First-run instructions

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze   # expected: 0 errors
flutter run       # app boots to NoteListScreen placeholder
```

Expected: Material 3 scaffold, "ModuNote" app bar, "📝 Note List / Phase 4 — coming soon"
centred on screen, amber FAB bottom-right. 5 new `.g.dart` files generated in
`lib/presentation/viewmodels/`.

---

## Phase 4 — What to build next

**Title**: Note List Screen

**Scope** (from DECISIONS.md D4.1–D4.6):
1. Replace `NoteListScreen` placeholder with a full implementation using `noteListViewModelProvider`
2. Render `AsyncValue.when(data, loading, error)` — loading = shimmer skeleton, error = retry button
3. Two-section list: "Pinned" then "Recent", each sorted by `updatedAt` DESC
4. `MNNoteCard` widget in `lib/presentation/widgets/mn_note_card.dart` — receives `Note`, `onTap`; never reads providers directly
5. Archived notes never shown (`INoteRepository.watchAll()` already filters them)
6. Amber FAB → `context.push(AppRoutes.newNote)`
7. `MNSearchField` tap → `context.push(AppRoutes.search)` (navigation affordance, not inline search)
8. Update `CLAUDE.md`, `progress.md`, `THREAD_HANDOFF.md`

**Before starting Phase 4**, Claude should present a detailed summary of every widget,
state path, and method signature for developer approval — per project protocol.

**UI spec**: Read `MODUNOTE_UI_REFERENCE.md` before touching any widget.

---

## Files to attach to new thread

- `CLAUDE.md` — AI context (architecture, conventions, phase status)
- `progress.md` — phase log + decisions log
- `MODUNOTE_UI_REFERENCE.md` — design spec (required before any UI work)
- `THREAD_HANDOFF.md` — this file
