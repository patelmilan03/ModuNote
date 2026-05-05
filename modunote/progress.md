# ModuNote — Project Progress

> Updated at the end of every phase. Read this before starting any new phase.

> ⚠️ **Git rule**: Claude may create and edit files on the local machine freely. Claude must never run `git commit`, `git push`, `git pull`, `git reset`, or any git command that changes repository state or interacts with GitHub. All commits and pushes are handled exclusively by the developer using GitHub Desktop.

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
| 2 | Data layer (Drift schema, DAOs, Repositories) | ✅ **Complete** | See details below |
| 3 | State management (Riverpod providers, base ViewModels) | ✅ **Complete** | See details below |
| 4 | Note list screen | ✅ **Complete** | See details below |
| 5 | Note editor screen (Quill) | ✅ **Complete** | See details below |
| 6 | Voice-to-text + audio recording/playback | ✅ **Complete** | See details below |
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

> **Note**: This phase was completed across two sessions due to an interruption. The first session wrote `app_database.dart`, `notes_dao.dart`, `tags_dao.dart`, and the three local repository files before stopping mid-phase. The second session discovered multiple bugs in those committed files, created all missing files, fixed the bugs, ran `build_runner`, and committed the completed phase. See "Phase 2 Bugfix & Recovery" below.

### Files Created

#### `lib/data/datasources/local/`
- `app_database.dart` *(partially existed — not modified in Phase 2)* — `@DriftDatabase` with 5 tables, 4 DAOs, FTS5 virtual table + 3 triggers (INSERT/UPDATE/BEFORE DELETE), `MigrationStrategy`
- `database_providers.dart` — `appDatabaseProvider`, `noteRepositoryProvider`, `tagRepositoryProvider`, `categoryRepositoryProvider` (all `keepAlive: true`); `appDatabaseProvider` calls `ref.onDispose(db.close)`

#### `lib/data/datasources/local/converters/`
- `type_converters.dart` — `QuillDeltaConverter` (`Map<String,dynamic>` ↔ `String` JSON), `DateTimeConverter` (`DateTime` ↔ `int` epoch ms UTC), `StringListConverter` (`List<String>` ↔ `String` JSON array)

#### `lib/data/datasources/local/tables/`
- `notes_table.dart` — `NotesTable` (`@DataClassName('NoteRow')`): `tagIds` denormalised via `StringListConverter`, `sync_status` defaults to `'local'`
- `tags_table.dart` — `TagsTable` (`@DataClassName('TagRow')`): `name` has `.customConstraint('NOT NULL UNIQUE')`
- `note_tags_table.dart` — `NoteTagsTable` (`@DataClassName('NoteTagRow')`): composite primary key `{noteId, tagId}`
- `categories_table.dart` — `CategoriesTable` (`@DataClassName('CategoryRow')`): `parentId` nullable, `sortOrder` defaults to `0`
- `audio_records_table.dart` — `AudioRecordsTable` (`@DataClassName('AudioRecordRow')`): `transcribedText` nullable, `codec` defaults to `'aac'`

#### `lib/data/datasources/local/daos/`
- `categories_dao.dart` — `watchAll`, `findChildren(String parentId)`, `findRoots`, `findById`, `insertCategory`, `updateCategory`, `deleteCategory`, `moveCategory`, `updateSortOrder`
- `audio_records_dao.dart` — `watchByNote`, `findById`, `findByNote`, `totalFileSizeBytes` (raw SQL `COALESCE(SUM…)`), `insertAudioRecord`, `updateTranscription`, `deleteAudioRecord`, `deleteAllForNote`

*(Previously committed in interrupted session — fixed in Phase 2 recovery):*
- `notes_dao.dart` — `watchAll`, `watchByTag`, `watchByCategory`, `findById`, `search` (FTS5), `insertNote`, `updateNote`, `archiveNote`, `deleteNote`, `togglePin`, `updateTagIds`
- `tags_dao.dart` — `watchAll`, `searchByPrefix`, `findByName`, `findById`, `findByNote`, `insertTag`, `deleteTag`, `addTagToNote`, `removeTagFromNote`, `setTagsForNote`, `_syncDenormalisedTagIds`

#### `lib/data/repositories/local/` (upgraded from stubs — bugs fixed in Phase 2 recovery)
- `local_note_repository.dart` — implements `INoteRepository` via `NotesDao`; maps `NoteRow` ↔ `Note`; parses `SyncStatus` enum
- `local_tag_repository.dart` — implements `ITagRepository` via `TagsDao`; normalises tag names on write via `StringExtensions.normalised`
- `local_category_repository.dart` — implements `ICategoryRepository` via `CategoriesDao`

#### `lib/data/repositories/interfaces/` (signatures corrected to match implementations)
- `i_tag_repository.dart` — `insert(String name)` (not `insert(Tag tag)`); `addTagToNote`/`removeTagFromNote` (not `addToNote`/`removeFromNote`); `setTagsForNote` uses positional params; added `findById`
- `i_category_repository.dart` — `findChildren(String parentId)` non-nullable; added `findRoots()`; added `updateSortOrder(String id, int sortOrder)`; `move` uses positional params; corrected `insert` signature

#### `lib/core/utils/string_extensions.dart`
- Re-export shim: `export '../extensions/string_extensions.dart'` — created because `local_tag_repository.dart` imports from `core/utils/` but the file lives at `core/extensions/`. Keeps the committed repo file unmodified.

### Architectural Decisions

| Decision | Detail |
|---|---|
| FTS5 full-text search | Virtual table `notes_fts` with 3 SQLite triggers (INSERT/UPDATE/BEFORE DELETE) keeps the index always in sync without application-level maintenance |
| Denormalised `tagIds` column | `NotesTable.tagIds` stores a JSON-encoded `List<String>` alongside the normalised join table. Gives O(1) tag list access in ViewModel streams without a join |
| `setTagsForNote` transactional | Runs inside Drift `transaction()`: deletes all join-table rows for the note, inserts new ones, then calls `_syncDenormalisedTagIds` — atomic, no partial state |
| TypeConverters — not raw SQL | `QuillDeltaConverter`, `DateTimeConverter`, `StringListConverter` registered on table columns so Drift handles serialisation transparently |
| Companion naming | Drift names companions after the TABLE class, not the data class: `NotesTableCompanion`, `TagsTableCompanion`, `NoteTagsTableCompanion`, `CategoriesTableCompanion`, `AudioRecordsTableCompanion` |
| `DatabaseException` signature | `DatabaseException(String message, {Object? cause})` — the `cause` named param is the only extra field; no `originalError` or `stackTrace` |
| `keepAlive: true` on all data providers | Database and repository providers must not be disposed during the app session |
| `ref.onDispose(db.close)` | Ensures SQLite connection is closed cleanly if the provider is ever disposed |
| `findChildren` non-nullable | `findChildren(String parentId)` takes a required ID; callers wanting root categories use the dedicated `findRoots()` method |

### Phase 2 Bugfix & Recovery

The first session was interrupted after committing partial work. The second session found and fixed the following bugs before the phase could be completed:

| Bug | Root cause | Fix |
|---|---|---|
| Companion class names wrong in all DAOs + repos | Drift names companions after the TABLE class (`NotesTableCompanion`), not the data class (`NoteRowCompanion`) | Bulk-renamed across `notes_dao.dart`, `tags_dao.dart`, and all three local repos |
| `DatabaseException` wrong constructor params | All repos called `DatabaseException('msg', originalError: e, stackTrace: st)` but the constructor only accepts `(message, {cause})` | Replaced with `DatabaseException(msg, cause: e)` throughout |
| Wrong import paths in local repos | `'../datasources/local/...'` resolves to non-existent `lib/data/repositories/datasources/` | Fixed to `'../../datasources/local/...'` |
| Wrong `string_extensions` import | `local_tag_repository.dart` imported from `core/utils/` but file is at `core/extensions/` | Fixed import + created `core/utils/string_extensions.dart` re-export |
| Interface / implementation mismatch | `ITagRepository` and `ICategoryRepository` had signatures that didn't match the implementations (wrong method names, wrong param types) | Rewrote both interfaces to exactly match their implementations |
| `intl` version conflict | `flutter_quill ^10.8.5` requires `intl ^0.19.0`; Flutter SDK pins `intl 0.20.2` | Added `dependency_overrides: intl: '>=0.19.0 <0.21.0'` to `pubspec.yaml` |
| `custom_lint`/`riverpod_generator` incompatibility | `riverpod_generator ^2.4.3` incompatible with `custom_lint ^0.6.4` | Bumped to `custom_lint: ^0.7.6` and `riverpod_lint: ^2.4.0` |

**Recovery strategy**: Hand-wrote minimal `.g.dart` stubs for all DAOs and providers to enable compilation before `build_runner` ran. Once `flutter pub get` succeeded (after the pubspec fixes above), `dart run build_runner build --delete-conflicting-outputs` replaced all stubs with real generated code (93 outputs). `flutter analyze` confirmed 0 errors.

### First-Run Instructions (Phase 2 state)

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Expected: app boots to NoteListScreen placeholder; Drift opens the SQLite database on first launch (no crash).

---

## Phase 3 — State Management ✅

**Completed**: Phase 3
**Deliverable**: 5 Riverpod ViewModels wired to the Phase 2 repository layer. No UI changes — placeholder screens unchanged.

### Files Created

#### `lib/presentation/viewmodels/`

- `note_list_view_model.dart` — `NoteListViewModel extends _$NoteListViewModel`. `build()` returns `Stream<List<Note>>` from `INoteRepository.watchAll()`. Mutations: `archive`, `delete`, `togglePin`. Errors set `state = AsyncError(e, st)`; stream auto-updates state on success.
- `note_editor_view_model.dart` — `NoteEditorViewModel extends _$NoteEditorViewModel`. Family provider with optional `noteId` build param. `build()` returns `Future<Note?>` (null for new note). Private `_isNew` flag tracks insert vs update. Mutations: `save`, `updateTitle`, `updateContent`, `addTag`, `removeTag`, `setCategory`. `addTag`/`removeTag` use `ITagRepository` then reload note via `findById`. `setCategory` constructs Note directly (bypasses `copyWith` to correctly handle `null` to clear a category).
- `tag_list_view_model.dart` — `TagListViewModel extends _$TagListViewModel`. `build()` streams `ITagRepository.watchAll()`. Mutations: `insert` (returns `Tag`), `delete`.
- `category_tree_view_model.dart` — `CategoryTreeViewModel extends _$CategoryTreeViewModel`. `build()` streams `ICategoryRepository.watchAll()` as a flat list. Mutations: `insert`, `move`, `delete`.
- `search_view_model.dart` — `SearchState` class + `SearchViewModel extends _$SearchViewModel`. `SearchState` holds `query: String` + `results: AsyncValue<List<Note>>`. `setQuery` debounces 300 ms via `dart:async Timer`. `ref.onDispose` cancels the timer. Empty query clears results immediately without DB hit.

### Architectural Decisions

| Decision | Detail |
|---|---|
| Stream-based VMs use `build() → Stream<T>` | Riverpod code-gen generates `StreamNotifier` — each stream emission becomes `AsyncData<T>` automatically. No manual `.listen()` anywhere. |
| `NoteEditorViewModel` uses `Future<Note?>` | No `watchById` on `INoteRepository`; editor manages state manually after each mutation. |
| `_isNew` field for insert vs update | Set in `build()`, cleared after first successful `insert`. Avoids extra DB round-trip. |
| `setCategory(null)` bypasses `copyWith` | `Note.copyWith(categoryId: null)` keeps old value (Dart nullable-copyWith limitation). Direct constructor call used instead. |
| `SearchState` co-locates query + results | Original D3.5 listed `AsyncNotifier<List<Note>>` for search — confirmed incorrect by developer. `Notifier<SearchState>` is the right choice. |
| Search debounce: 300 ms | Small enough to feel responsive; large enough to avoid hammering FTS5 on every keystroke. |

### Bugfix Log

| Bug | Fix |
|---|---|
| D3.5 error: `searchViewModelProvider` listed as `AsyncNotifier<List<Note>>` | Confirmed by developer as wrong. Corrected to `Notifier<SearchState>` before implementation. DECISIONS.md updated at Phase 3 start. |
| `overridden_fields` on DAO fields in `AppDatabase` — redeclared fields that `_$AppDatabase` already provides as concrete `late final` | Removed all 4 DAO field declarations from `AppDatabase`; inherited directly from the generated base class. |
| 11 `unnecessary_import` warnings — redundant table imports in DAOs, redundant DAO imports in local repos, redundant `flutter_riverpod` in `search_view_model.dart` | Removed all redundant imports; each file now imports only `app_database.dart` (which re-exports tables and DAOs) or `riverpod_annotation` (which re-exports Riverpod). |
| `use_super_parameters` on `AppDatabase(QueryExecutor e) : super(e)` | Changed to `AppDatabase(super.e)`. |
| `prefer_const_declarations` on `UuidGenerator._uuid` | Changed `static final _uuid = const Uuid()` to `static const _uuid = Uuid()`. |

### First-Run Instructions (Phase 3 state)

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter run
```

Expected: app boots to NoteListScreen placeholder (no UI change from Phase 2). `build_runner` produces 5 new `.g.dart` files in `lib/presentation/viewmodels/`. `flutter analyze` reports 0 errors.

---

---

## Phase 4 — Note List Screen ✅

**Completed**: Phase 4
**Deliverable**: Full NoteListScreen implementation. `flutter run` shows the live note list with pinned/recent sections, shimmer loading, error retry, floating bottom nav, and amber FAB.

### Files Created

#### `lib/presentation/widgets/`
- `mn_note_card.dart` — `MNNoteCard extends StatelessWidget`. Props: `Note note`, `VoidCallback onTap`, `List<String> tagNames`. Renders card per UI Reference § 2.3: pinned tint background, pin icon, title (PJS 16.5/700), single-line preview (Inter 13.5/400), up to 3 filled tag chips. Private `_TagChip` widget. Timestamp computed inline from `note.updatedAt`. Body preview extracted from Quill Delta JSON.
- `mn_search_field.dart` — `MNSearchField extends StatelessWidget`. Props: `VoidCallback? onTap`. Height 48, surfaceContainer bg, borderRadius 16, 0.5px outline border. Non-editable on Home; navigates on tap.

#### `lib/presentation/views/note_list/`
- `note_list_screen.dart` — **Replaced** placeholder with full implementation. `NoteListScreen extends ConsumerWidget`. Watches `noteListViewModelProvider` + `tagListViewModelProvider`. Uses `Stack` + `Positioned.fill` + two `Positioned` overlays (bottom nav + FAB). Private helper widgets:
  - `_DataBody` — renders note list with section headers; empty state inline
  - `_AppBarSection` — day label + "Your notes" + gradient avatar
  - `_SectionHeader` — "PINNED" / "RECENT" label + hairline divider + optional count badge
  - `_LoadingBody` — 3 pulsing `_SkeletonBox` widgets as fake cards
  - `_SkeletonBox` — `StatefulWidget`, `AnimationController.repeat(reverse: true)`, opacity 0.35→0.65
  - `_ErrorBody` — error icon + "Could not load notes" + Retry `TextButton`
  - `_EmptyState` — empty icon + "No notes yet" + search field + centred message
  - `_BottomNav` — floating pill nav at `left: 16, right: 16, bottom: 14`; 4 tabs; Home active
  - `_NavTab` — `AnimatedContainer` pill; active = `primaryContainer` bg + icon + label
  - `_Fab` — amber 56×56, `borderRadius: 18`, two-layer amber shadow

### Architectural Decisions

| Decision | Detail |
|---|---|
| Tag name resolution | `NoteListScreen` watches both `noteListViewModelProvider` + `tagListViewModelProvider`; builds `Map<String,String>` id→name; passes resolved names to `MNNoteCard.tagNames` |
| `MNNoteCard` is `StatelessWidget` | Purely presentational — no providers. Tab navigation, swipe actions deferred to later phases |
| Shimmer without package | `_SkeletonBox` `StatefulWidget` with `AnimationController` — no `shimmer` package required |
| Bottom nav scope | Phase 4 bottom nav is per-screen (hardcoded Home active). Replaced by `ShellRoute` in Phase 9 |
| No build_runner | No new `@riverpod` annotations or Drift tables — build_runner does not need to re-run |
| `flutter analyze` | 0 issues (2 `prefer_const_constructors` warnings fixed during implementation) |

### First-Run Instructions (Phase 4 state)

```bash
# No new packages — no flutter pub get needed
# No new @riverpod annotations — no build_runner needed
flutter analyze   # expected: 0 issues
flutter run       # app boots to full NoteListScreen
```

Expected: Home screen renders with "Your notes" heading, gradient avatar, search field, PINNED / RECENT sections (empty state if DB empty), floating amber FAB, floating bottom nav pill.

---

## Phase 5 — Note Editor Screen ✅

**Completed**: Phase 5
**Deliverable**: Full `NoteEditorScreen` implementation with Quill rich-text editor, 800 ms auto-save, format toolbar, tag row, and recording overlay UI (wired to real audio in Phase 6).

### Files Created

#### `lib/presentation/widgets/`
- `mn_editor_toolbar.dart` — `MNEditorToolbar extends StatefulWidget`. Props: `required QuillController controller`. Owns `controller.addListener` to update active-state badges on selection/content changes. 9 formatting tools (bold, italic, underline, H1, H2, bullet, numbered list, checklist, blockquote) each rendered as 34×34 `_ToolButton` with `borderRadius: 10`. Active: `primaryContainer` bg, `onPrimaryContainer` icon. Inactive: transparent bg, `onSurfaceVariant` icon. H1/H2 use `Text` labels (no Material icon available). Toggle: active → `Attribute.clone(attr, null)` unsets; inactive → `formatSelection(attr)` applies. Checklist active = list value `'checked'` OR `'unchecked'`. Spec: UI Reference § 3.4.
- `mn_tag_row.dart` — `MNTagRow extends StatelessWidget`. Props: `tagIds`, `allTags`, `categoryName?`, `onRemoveTag`, `onAddTagTap`, `onCategoryTap`, `onMicTap`, `isRecording`. Category chip (height 30, `br 10`, surfaceContainer bg). Horizontal scrollable row of dismissible sm filled tag chips + `+ tag` sm outlined chip. Mic button (40×40, `br 14`; idle = primaryContainer; recording = recordRed + white square). Spec: UI Reference § 3.4.

#### `lib/presentation/views/note_editor/`
- `note_editor_screen.dart` — **Replaced** placeholder. `NoteEditorScreen extends ConsumerStatefulWidget`. Key state: `QuillController? _quillController`, `TextEditingController _titleController`, `FocusNode`, `ScrollController`, `StreamSubscription? _contentSubscription`, `Timer? _debounce`, `Timer? _recordTimer`, `bool _isDirty`, `bool _isRecording`, `int _recordSeconds`, `Note? _currentNote`, `bool _controllersInitialized`. Layout: `Scaffold(resizeToAvoidBottomInset: true)` → `SafeArea` → `Stack` (Column + `Positioned` recording overlay). Column: `_EditorAppBar` (back btn + title TextField + `_SaveBadge` + more btn) + `Expanded(QuillEditor)` + `MNTagRow` + `MNEditorToolbar`. Private widgets: `_EditorAppBar`, `_CircleIconButton`, `_SaveBadge`, `_RecordingOverlay`, `_WaveformBars`, `_PulsingStopButton`.

### Architectural Decisions

| Decision | Detail |
|---|---|
| `ConsumerStatefulWidget` for editor | Owns `QuillController` lifecycle (`initState`/`dispose`). Only exception to the "always `ConsumerWidget`" rule |
| Controller init from `whenData` in build | `noteAsync.whenData(_initControllers)` called each build; guarded by `_controllersInitialized`. Sets `_quillController` synchronously; no `setState` needed — current build frame sees updated value |
| Content-only stream subscription | `_quillController!.document.changes.listen()` for auto-save (not `addListener`) — avoids triggering save on cursor movements |
| Auto-save on back | `_onBack` cancels debounce, `await _performAutoSave()`, then `context.pop()` |
| `_syncCurrentNote()` after tag mutations | After `addTag`/`removeTag`, re-reads ViewModel state to keep `_currentNote.tagIds` in sync |
| No `withOpacity` | All translucent colors use `.withValues(alpha: ...)` to match Flutter 3.27+ deprecation-free style |
| No new packages, no build_runner | Phase 5 adds no new `@riverpod` providers and no new Drift tables |

### First-Run Instructions (Phase 5 state)

```bash
# No new packages, no new @riverpod annotations
flutter analyze   # expected: 0 issues
flutter run       # tap FAB → Note Editor opens; type → auto-saves after 0.8 s
```

Expected: Tapping FAB opens Note Editor with empty Quill editor. Title TextField at top. "Saved" badge shows green dot after 0.8 s idle. Format toolbar pins above keyboard. Tag row shows "+ tag" chip and mic button. Tapping mic shows recording overlay with timer. Tapping back returns to Note List.

---

## Phase 6 — Voice-to-Text + Audio Recording/Playback ✅

**Completed**: Phase 6
**Deliverable**: Real audio recording via `flutter_sound` + live speech-to-text via `speech_to_text`, wired to the mic button. Audio clip chips with playback. Transcript inserted at Quill cursor on stop.

### Files Created

#### `lib/data/datasources/file/`
- `audio_file_storage.dart` — `AudioFileStorage`. `ensureAudioDir()` creates `audio_notes/` under `getApplicationDocumentsDirectory()`. `generateFilePath()` returns `{audioDir}/{uuid}.aac`. `getFileSize(filePath)` returns bytes. `deleteFile(filePath)` removes file. All IO exceptions wrapped in `FileStorageException`.

#### `lib/data/repositories/interfaces/`
- `i_audio_record_repository.dart` — `IAudioRecordRepository` interface: `watchByNote`, `findByNote`, `findById`, `insert`, `updateTranscription`, `delete`, `deleteAllForNote`.

#### `lib/data/repositories/local/`
- `local_audio_record_repository.dart` — Implements `IAudioRecordRepository` via `AudioRecordsDao`. Maps `AudioRecordRow` ↔ `AudioRecord`. Wraps Drift exceptions as `DatabaseException(msg, cause: e)`.

#### `lib/services/audio/`
- `audio_recording_service.dart` — Replaces stub. `FlutterSoundRecorder` + `FlutterSoundPlayer`. `init()` opens both (idempotent, guarded by `_initialized`). `startRecording(filePath)` uses `Codec.aacADTS`, `bitRate: 32000`, `numChannels: 1`, `sampleRate: 16000`; maps `onProgress.decibels` → `amplitudeStream` (0.0–1.0 normalized). `stopRecording()` returns `durationMs` via `Stopwatch`. `startPlayback(filePath, {onDone})` / `stopPlayback()`. `dispose()` closes both safely.

#### `lib/services/speech/`
- `speech_to_text_service.dart` — Replaces stub. `SpeechToText` wrapper. `initialize()` requests mic permission. `startListening({onResult})` uses `ListenMode.dictation`, `pauseFor: 8s`. Appends `finalResult` words to `_accumulated`; passes `_accumulated + inFlight` for partial. `_onStatus` handler restarts listener on `'notListening'` while `_active` (Android STT timeout recovery). `stopListening()`, `resetText()`, `dispose()`.

#### `lib/presentation/viewmodels/`
- `audio_editor_view_model.dart` — `AudioEditorViewModel extends _$AudioEditorViewModel`. Family `{required String noteId}`. `build()` → `Stream<List<AudioRecord>>` from `audioRecordRepositoryProvider.watchByNote`. `saveRecording(filePath, durationMs, fileSizeBytes, transcript?)` → constructs + inserts `AudioRecord`. `deleteRecord(id)` → deletes DB row (caller deletes file).

### Files Modified

#### `lib/data/datasources/local/database_providers.dart`
- Added `audioRecordRepositoryProvider` (`@Riverpod(keepAlive: true)`) → `LocalAudioRecordRepository(db.audioRecordsDao)`. Added imports for new interface + repo.

#### `lib/presentation/views/note_editor/note_editor_screen.dart`
- **`_onMicTap()`**: replaced stub. Flushes auto-save if needed, lazy-inits `AudioRecordingService` + `SpeechToTextService`, checks STT permission (SnackBar + early return if denied), generates file path, starts recording + listening simultaneously, subscribes to amplitude stream for waveform, starts record timer.
- **`_stopRecording()`**: replaced stub. Cancels timer + amplitude subscription, stops both services, saves `AudioRecord` via `audioEditorViewModelProvider`, inserts transcript at Quill cursor via `_insertTranscriptAtCursor`.
- **`_insertTranscriptAtCursor(text)`**: new method. Inserts `'\n$text\n'` at `selection.baseOffset`.
- **`_WaveformBars`**: now accepts `double amplitude`. `AnimatedContainer(duration: 80ms)` per bar with height `= 4.0 + amplitude * 20.0 * coefficient[i]`.
- **`_RecordingOverlay`**: gains `amplitude` + `liveTranscript` props. Transcript preview added below timer row (hidden when empty).
- **`_AudioClipsRow`** (new `ConsumerStatefulWidget`): watches `audioEditorViewModelProvider`. Horizontal scroll of `_AudioClipChip` widgets. Manages `_playingId` for play/pause. Chips: h28, pill, surfaceContainer bg, play/pause icon + duration text + delete ×.
- **Column order in `_buildEditor`**: AppBar → QuillEditor → `_AudioClipsRow` → `MNTagRow` → `MNEditorToolbar`.
- New state fields: `_audioService`, `_sttService`, `_audioStorage`, `_audioInitialized`, `_amplitudeSubscription`, `_currentRecordingPath`, `_currentAmplitude`, `_liveTranscript`.

#### `android/app/src/main/AndroidManifest.xml`
- Added `<uses-permission android:name="android.permission.RECORD_AUDIO"/>`.

### Architectural Decisions

| Decision | Detail |
|---|---|
| STT approach | Simultaneous: `flutter_sound` records AAC while `speech_to_text` listens live. Confirmed by developer. Works on most modern Android devices. |
| D6.4 revised | Original D6.4 assumed file-based STT (impossible with `speech_to_text` v7). Revised to live STT running simultaneously with flutter_sound recording. |
| STT timeout recovery | `_onStatus('notListening')` handler with 200 ms delay restarts `_stt.listen()` if still `_active`. Prevents transcript truncation on long recordings. |
| Services lifecycle | `AudioRecordingService` + `SpeechToTextService` are plain Dart classes owned by `_NoteEditorScreenState`. Not `@riverpod` providers — lifecycle is tied to the screen. |
| `_AudioClipsRow` widget type | `ConsumerStatefulWidget` — needs both `ref.watch(audioEditorViewModelProvider)` and local `_playingId` playback state. |
| File deletion responsibility | `audioEditorViewModelProvider.deleteRecord` removes the DB row only. The screen (via `_audioStorage.deleteFile`) removes the file. Separation of concerns. |

### First-Run Instructions (Phase 6 state)

```bash
dart run build_runner build --delete-conflicting-outputs
# New generated: audio_editor_view_model.g.dart; updated: database_providers.g.dart
flutter analyze   # expected: 0 issues
flutter run
```

Expected: Tap FAB → Note Editor. Tap mic button → OS dialog (first launch) → grant → recording overlay with live timer + animated waveform bars. Speak → transcript text appears. Tap pulsing stop → overlay gone, words inserted into editor, audio chip appears above tag row. Tap play chip → audio plays back.

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
| Full-text search | FTS5 virtual table + 3 SQLite triggers | 2 |
| Tag denormalisation | `tagIds` JSON column on NotesTable for O(1) ViewModel access | 2 |
| Companion naming | TABLE class name + Companion (e.g. `NotesTableCompanion`) | 2 |
| Type converters | `QuillDeltaConverter`, `DateTimeConverter`, `StringListConverter` | 2 |
| Data providers lifecycle | All 5 data-layer providers use `keepAlive: true` (Phase 6 added `audioRecordRepositoryProvider`) | 2 / 6 |
| ViewModel stream pattern | `build() → Stream<T>` for list VMs; Riverpod auto-wraps as `AsyncValue<T>` | 3 |
| `NoteEditorViewModel` family param | Optional `noteId` build param; `_isNew` flag tracks first insert | 3 |
| `SearchState` pattern | `Notifier<SearchState>` with query + `AsyncValue<List<Note>>` results; 300 ms debounce | 3 |
| Category deletion policy | **TBD — Phase 8** | — |
| AI provider (Gemini vs Groq) | **TBD — Phase 12** | — |

---

## Pending Decisions

| Decision | Phase to resolve |
|---|---|
| Category deletion policy when children exist (cascade vs re-parent) | 8 |
| AI provider evaluation (Gemini free tier vs Groq) | 12 |

---

## Documentation Produced (Post-Phase-6 Session)

The following documentation files were created or significantly updated after Phase 6 was completed. They are not code changes but are part of the project's permanent record.

### Files Updated

| File | What changed |
|---|---|
| `CLAUDE.md` | Phase 6 status marked ✅; `audio_file_storage.dart`, `audio_recording_service.dart`, `speech_to_text_service.dart` added to quick reference; `database_providers.dart` description updated to 5 `keepAlive` providers; `TESTING.md` added to quick reference; on-boarding checklist expanded to 10 steps including `flutter analyze` gate and TESTING.md smoke test |
| `THREAD_HANDOFF.md` | Status header updated to "Phase 6 ✅ Complete. Proceed with Phase 7."; full "What was built (Phase 6)" section added; architecture decisions table updated with all Phase 6 entries; Phase 7 scope documented; first-run instructions updated; `TESTING.md` added to files-to-attach list |
| `DECISIONS.md` | Phase 6 status changed from ⬜ to ✅; D6.4 revised from "file-based STT" to "simultaneous live STT + flutter_sound" with full rationale; D6.5 updated to reflect permission handling without `permission_handler` package; D6.7 added (Android STT timeout recovery pattern); D6.8 added (services lifecycle as plain Dart classes); D6.9 added (file deletion separation of concerns); D2.8 updated to reflect 5 keepAlive providers |
| `README.md` | Replaced default Flutter stub with full project description, tech stack table, architecture overview, phase status table, getting-started commands, and key documentation references |
| `progress.md` | Phase 6 section added (this file); data providers lifecycle corrected from 4 to 5 |

### Files Created

| File | Purpose |
|---|---|
| `TESTING.md` | Full manual testing guide. 14 sections, ~130 numbered checks covering all Phases 1–6 features. Includes: app bootstrap, note list screen, note creation + auto-save, editor + toolbar (all 9 buttons), pinning/sections, search, voice recording (permission flow, waveform, STT, timeout recovery, stop + insert, clip chips), data persistence, themes (exact color token checks), navigation/routing, stub screens, edge cases, performance, and `flutter analyze` gate. Quick smoke test: ~35 🔴 CRITICAL checks in ~15 min. Full regression: ~130 checks in ~1 hr. |

### Testing Philosophy (recorded for future phases)

- **Phases 1–9** (active feature development): Manual smoke test only. The UI changes too fast between phases to justify automating it.
- **After Phase 9** (navigation stable): Add **unit tests** for ViewModels and repository layer (`flutter_test`). These are pure Dart, fast, and don't break on UI refactors.
- **After Phase 12** (feature-complete): Add **integration tests** for critical flows (`integration_test` package). Add **GitHub Actions** CI to run `flutter analyze` + `flutter test` on every push.
- The `TESTING.md` smoke test list maps directly to future integration test cases — each numbered check is a candidate `testWidgets(...)` scenario.

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
