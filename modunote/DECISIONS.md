# ModuNote — Architectural & Development Decisions
> **Purpose**: Permanent record of every architectural, structural, and implementation
> decision made across all phases of the ModuNote project — both completed and planned.
> Any AI agent or developer picking up this project must read this file in full before
> writing, reviewing, or modifying any code.
>
> **Update rule**: Every time a pending decision is resolved, update this file immediately.
> Every time a new decision is introduced, append it to the relevant phase section.
>
> **Reading order**: Read this file alongside `CLAUDE.md` (architecture overview)
> and `STATUS.md` (phase-by-phase log + current status + next-phase scope). All three together form complete context.

---

## Project Identity

| Field | Value | Rationale |
|---|---|---|
| App name | ModuNote | Brand name. Not negotiable. |
| Flutter package | `modunote` | Flutter convention: lowercase, no hyphens |
| App ID | `com.modunote.app` | Org prefix generic enough for Play Store publishing |
| Primary platform | Android | Developer is Android-first. iOS deferred, non-destructive to add later |
| Min Dart SDK | `>=3.3.0 <4.0.0` | Required by Drift v2 macros + Riverpod Generator v2 |
| Min Flutter | `>=3.22.0` | Required for stable Material 3 NavigationBar pill indicator |

---

## Global Non-Negotiable Rules

These rules apply to every phase, every file, forever. Never override them.

1. **All screen widgets extend `ConsumerWidget`** — never `StatelessWidget` or `StatefulWidget` directly. Riverpod must be injectable everywhere.
2. **All providers use `@riverpod` annotation + code-gen** — no manual `Provider(...)`, `StateProvider(...)`, or `ChangeNotifierProvider(...)` declarations anywhere.
3. **ViewModels (`AsyncNotifier`/`Notifier`) import repository interfaces only** — never Drift DAOs, never `AppDatabase` directly. The interface is the contract.
4. **Views (`ConsumerWidget`) depend on ViewModels only** — never on repositories, DAOs, or database directly.
5. **All domain errors are wrapped in `AppException` subtypes** before surfacing to the ViewModel layer. Raw Drift, IO, or platform exceptions must never leak upward.
6. **Tag names are always stored and compared lowercase** — use `StringExtensions.normalised` on every write. Never store mixed-case tags.
7. **UUIDs always via `UuidGenerator.generate()`** — never call `Uuid().v4()` directly anywhere in the codebase.
8. **Generated files (`*.g.dart`) are gitignored and never edited manually** — they are build artifacts. Pre-written stubs are compile-time shims only; `dart run build_runner build --delete-conflicting-outputs` always replaces them.
9. **Run build_runner after any `@riverpod` annotation change or Drift table change** — skipping this will cause stale generated code to silently mismatch.
10. **`WidgetsFlutterBinding.ensureInitialized()` is always called before `runApp`** — required by Drift (async DB path resolution) and flutter_sound (platform channel setup).
11. **Claude may create and edit files on the local machine freely** — but must never run `git commit`, `git push`, `git pull`, `git reset`, or any git command that changes repository state or interacts with GitHub. All commits and pushes are handled exclusively by the developer using GitHub Desktop.

---

## Package Decisions

### Runtime Dependencies

| Package | Locked version | Why this package | Why not alternatives |
|---|---|---|---|
| `flutter_riverpod` | `^2.5.1` | Industry-standard reactive state management for Flutter. Compile-safe, testable, no context required | Provider (too simple for this complexity), BLoC (too verbose for solo dev), GetX (anti-pattern, global state) |
| `riverpod_annotation` | `^2.3.5` | Required for `@riverpod` code-gen annotations | — (companion to flutter_riverpod) |
| `drift` | `^2.18.0` | Type-safe SQLite ORM with streams, transactions, FTS5, migrations | sqflite (no type safety, no streams), Isar (no relational joins for tags), Hive (not relational) |
| `drift_flutter` | `^0.2.1` | Flutter-specific Drift setup — handles native SQLite path resolution automatically | — (required companion to drift on Flutter) |
| `flutter_quill` | `^10.8.5` | Most battle-tested rich text editor for Flutter. Delta JSON is portable, serialisable, and Firebase-ready | super_editor (less mature), custom solution (months of work) |
| `go_router` | `^14.2.0` | Official Flutter navigation package. Declarative, URL-based, supports ShellRoute for bottom nav | Navigator 2.0 raw (too verbose), auto_route (extra codegen overhead) |
| `speech_to_text` | `^7.0.0` | On-device STT. Free, offline, no API key, works across Android/iOS | Google STT API (costs money, requires internet), Whisper (no Flutter package, requires backend) |
| `flutter_sound` | `^9.2.13` | Combined record + playback in one package. Supports AAC codec at exact spec required | record package alone (no playback), just_audio (no recording) |
| `google_fonts` | `^6.2.1` | Zero-config font loading for Plus Jakarta Sans + Inter from Google CDN | Manual font files in assets/ (larger repo, manual updates) |
| `uuid` | `^4.4.0` | Minimal, zero-dependency UUID v4 generation | nanoid (less conventional), custom (pointless risk) |
| `path_provider` | `^2.1.3` | Required by drift_flutter for resolving the database file path on device | — (platform requirement) |
| `path` | `^1.9.0` | Path manipulation utilities for audio file storage | — (standard Dart utility) |
| `equatable` | `^2.0.5` | Value equality for domain model classes without boilerplate `==` and `hashCode` | freezed (adds code-gen overhead and union types we don't need), manual (error-prone) |

### Dev Dependencies

| Package | Locked version | Purpose |
|---|---|---|
| `riverpod_generator` | `^2.4.3` | Generates provider boilerplate from `@riverpod` annotations |
| `build_runner` | `^2.4.11` | Orchestrates all code generators (Riverpod + Drift) |
| `drift_dev` | `^2.18.0` | Generates Drift table classes, DAO mixins, database implementations |
| `flutter_lints` | `^4.0.0` | Standard Flutter lint rules baseline |
| `custom_lint` | `^0.7.6` | Plugin host for riverpod_lint — catches provider mistakes at analysis time. Bumped from `^0.6.4` in Phase 2 to resolve incompatibility with `riverpod_generator ^2.4.3`. |
| `riverpod_lint` | `^2.4.0` | Riverpod-specific lint rules (e.g. warns on missing provider scopes, bad watch patterns). Bumped from `^2.3.10` in Phase 2 alongside custom_lint. |

---

## Phase 1 — Project Setup & Folder Structure ✅ Complete

### Decisions Made

**D1.1 — Platform target**
Android only at project creation. iOS excluded from `flutter create` flags to avoid Xcode boilerplate. iOS can be added non-destructively later via `flutter create --platforms ios .` without touching existing code.

**D1.2 — Model equality strategy: Equatable over Freezed**
All domain models (`Note`, `Tag`, `Category`, `AudioRecord`) are plain immutable Dart classes extending `Equatable`. Rationale: Freezed adds code-gen overhead and union type complexity not needed for simple value objects. Equatable gives `==`, `hashCode`, and `props` with zero generated files. Every model must implement `copyWith` manually. This decision is final — do not introduce Freezed unless the developer explicitly requests it.

**D1.3 — `SyncStatus` enum in `Note` from day one**
The `Note` model includes a `syncStatus` field of type `SyncStatus` enum (`local`, `pending`, `synced`, `conflict`) even though Firebase sync is not built until Phase 10. This avoids a breaking model change mid-project. Default value is `SyncStatus.local`. The Drift `notes` table has a `sync_status TEXT NOT NULL DEFAULT 'local'` column from Phase 2 onwards.

**D1.4 — Pre-written `app_router.g.dart` stub strategy**
Because `build_runner` cannot be run during project scaffolding (no Flutter SDK in the build environment), a hand-written stub is provided as a compile-time shim. This stub declares all generated symbols (`routerProvider`, `themeModeNotifierProvider`, `themeModeProvider`, `_$ThemeModeNotifier`) so the project compiles before the developer runs `build_runner`. The stub is replaced by real generated output on first `dart run build_runner build --delete-conflicting-outputs`. The same stub pattern is used for all DAO `.g.dart` files in Phase 2.

**D1.5 — `ThemeModeNotifier` defaults to `ThemeMode.system`**
The theme follows the device's OS setting by default. The developer can override to light or dark. Persistence to SharedPreferences is deferred to Phase 9. Until Phase 9, the choice resets on app restart.

**D1.6 — `themeMode` convenience provider architecture**
`app_router.dart` defines three `@riverpod` symbols: `router` (the GoRouter), `ThemeModeNotifier` (the state notifier), and `themeMode` (a read-only convenience provider that unwraps `ThemeModeNotifier`'s state for `MaterialApp.router`). `app.dart` watches `themeModeProvider` (the convenience provider). This is the correct pattern — do not collapse them.

**D1.7 — Known Phase 1 bug and fix**
The original `app_router.g.dart` stub was missing the `themeModeProvider` block. A missing declaration in a `part` file causes Dart to reject the entire part file, making all symbols from it (including `themeModeNotifierProvider`) appear undefined. Fix: the stub must contain all three provider blocks and the `_$ThemeModeNotifier` abstract class. This is documented so future stubs are written correctly the first time.

**D1.8 — Folder structure is fixed**
The folder structure established in Phase 1 is permanent. New files always go in their designated folder. The structure is:
```
lib/
├── core/           — constants, errors, extensions, utils, theme
├── data/
│   ├── models/     — domain model classes only
│   ├── repositories/interfaces/  — abstract contracts
│   ├── repositories/local/       — Drift implementations
│   └── datasources/local/        — Drift tables, DAOs, AppDatabase
│   └── datasources/file/         — AudioFileStorage
├── services/       — speech/, audio/
└── presentation/
    ├── viewmodels/ — AsyncNotifier classes
    ├── views/      — one subfolder per screen
    ├── widgets/    — shared reusable widgets
    └── router/     — GoRouter config
```

---

## Phase 2 — Data Layer ✅ Complete

### Decisions Made

**D2.1 — Drift table design: 5 tables**
Tables: `notes`, `tags`, `note_tags` (join), `categories`, `audio_records`. All primary keys are TEXT (UUID strings). All timestamps are INTEGER (Unix epoch milliseconds). This is non-negotiable — never use SQLite's DATETIME type; INTEGER milliseconds are portable, sortable, and unambiguous.

**D2.2 — FTS5 virtual table for full-text search**
A Drift FTS5 virtual table (`notes_fts`) mirrors the `notes` table's `title` and `content` columns. Three SQLite triggers keep it synchronised: `notes_ai` (after insert), `notes_au` (after update), `notes_ad` (after delete). This gives O(log n) full-text search without any backend. The FTS table is never queried directly from Dart — only via `NotesDao.search()`.

**D2.3 — `tagIds` denormalised column on `NotesTable`**
`NotesTable` has a `tag_ids TEXT NOT NULL DEFAULT '[]'` column storing the note's tag IDs as a JSON-encoded list (via `StringListConverter`). This is a deliberate denormalisation for O(1) access in ViewModel streams — the ViewModel does not need to join across `note_tags` just to show the tag chips on a note card. The join table (`note_tags`) remains authoritative; `tagIds` is a cache. `TagsDao.setTagsForNote` always updates both in a single transaction.

**D2.4 — `setTagsForNote` is atomic via Drift transaction**
When assigning tags to a note, `setTagsForNote` deletes all existing rows in `note_tags` for that note, inserts the new set, then calls `_syncDenormalisedTagIds` to update `notes.tag_ids`. This entire sequence runs inside `database.transaction(() async { ... })`. Never split this into separate calls from outside the DAO.

**D2.5 — All Drift exceptions are caught and re-thrown as `DatabaseException` at the DAO boundary**
Every DAO method wraps its body in a `try/catch` that catches `DriftWrappedException` and generic `Exception`, then throws `DatabaseException(message, cause: e)`. Raw Drift exceptions must never propagate above the DAO layer. Repository implementations do not catch — they trust the DAOs.

**D2.6 — Row classes live inside `app_database.g.dart` (generated); no separate `row_classes.dart` exists**
Drift generates data classes (`NoteRow`, `TagRow`, etc.) and Companion classes into `app_database.g.dart`. During Phase 2 recovery, a hand-written stub for `app_database.g.dart` was provided inline in that single file — it defined all row classes, companion classes, `$Table` classes, and `_$AppDatabase`. There is no separate `row_classes.dart` file. After `build_runner` ran successfully (93 outputs), the stub was replaced by the real generated output entirely within `app_database.g.dart`. Never create a separate `row_classes.dart` file.

**D2.7 — `appDatabaseProvider` is `keepAlive: true` and calls `ref.onDispose`**
The database must not be recreated on every widget rebuild. `keepAlive: true` on `appDatabaseProvider` ensures it lives for the app's lifetime. `ref.onDispose(db.close)` ensures the SQLite connection is flushed and closed cleanly on hot restart or app termination.

**D2.8 — All repository providers are `keepAlive: true`**
`noteRepositoryProvider`, `tagRepositoryProvider`, `categoryRepositoryProvider`, and (added Phase 6) `audioRecordRepositoryProvider` are all `keepAlive: true`. Repositories are stateless wrappers — they are cheap to construct but there is no reason to reconstruct them. Keeping them alive avoids re-subscription of any active streams. Total `keepAlive` providers in `database_providers.dart`: 5 (including `appDatabaseProvider`).

**D2.9 — `QuillDeltaConverter` serialises content as JSON string**
`Note.content` (a `Map<String, dynamic>` Delta document) is stored in SQLite as a JSON string via `QuillDeltaConverter`. On read, it is deserialised back to `Map<String, dynamic>`. This is straightforward and Firebase-compatible (Firestore can store maps natively). The converter lives in `lib/data/datasources/local/converters/type_converters.dart`.

**D2.10 — `SyncStatus` stored as string in SQLite**
`SyncStatus` enum values are stored as their string names (`'local'`, `'pending'`, `'synced'`, `'conflict'`) via a custom `TypeConverter`. Never store enums as integers — string values are readable in SQLite browser tools and safe across enum reordering.

**D2.11 — `MigrationStrategy` declared from day one**
`AppDatabase` declares a `MigrationStrategy` with `onCreate` and `onUpgrade` stubs. `schemaVersion` starts at `1`. Future phases that add columns must increment `schemaVersion` and add a migration step. Never change an existing table without a migration.

---

## Phase 3 — State Management ✅ Complete

### Decisions Made

**D3.1 — ViewModel pattern: `AsyncNotifier` for async data, `Notifier` for sync state**
Screens that load data from the repository use `AsyncNotifier<T>`. Screens with purely local UI state (e.g. a toggle) use `Notifier<T>`. Never use `StateNotifier` (deprecated in Riverpod 2). Never use `StateProvider` (too simple, not composable).

**D3.2 — One ViewModel per screen**
Each screen gets exactly one ViewModel file in `lib/presentation/viewmodels/`. The ViewModel exposes the minimum state the screen needs. Cross-screen state (e.g. the currently selected category) is shared via a separate top-level provider, not by sharing ViewModel instances.

**D3.3 — ViewModels watch repository streams via `ref.watch`**
Stream-based ViewModels (NoteList, TagList, CategoryTree) have `build()` return `Stream<T>` directly — Riverpod code-gen wraps each emission as `AsyncValue<T>` automatically. This is the canonical stream-to-AsyncValue conversion; never use `.listen()` manually. `NoteEditorViewModel` uses `Future<Note?>` in `build()` and manages state manually since there is no `watchById` stream on `INoteRepository`.

**D3.4 — Error handling in ViewModels: `AsyncError` state**
When a repository call throws an `AppException`, the ViewModel catches it and sets state to `AsyncError(e, stackTrace)`. Never swallow exceptions silently. The view layer reads `AsyncValue.when(error: ...)` to show error UI.

**D3.5 — Providers built in Phase 3** *(D3.5 corrected: `searchViewModelProvider` was originally listed as `AsyncNotifier<List<Note>>` — this was wrong; confirmed `Notifier<SearchState>` by developer before implementation)*
- `noteListViewModelProvider` — `StreamNotifier<List<Note>>`, streams `INoteRepository.watchAll()`
- `noteEditorViewModelProvider` — `AsyncNotifier<Note?>`, family provider parameterised by optional `noteId`
- `tagListViewModelProvider` — `StreamNotifier<List<Tag>>`, streams `ITagRepository.watchAll()`
- `categoryTreeViewModelProvider` — `StreamNotifier<List<Category>>`, streams `ICategoryRepository.watchAll()`
- `searchViewModelProvider` — `Notifier<SearchState>`, debounced 300 ms → `INoteRepository.search(query)`

**D3.6 — `NoteEditorViewModel._isNew` tracks insert vs update**
A private `bool _isNew` field is set to `true` when `noteId == null` in `build()`. It is flipped to `false` after the first successful `insert`. All subsequent `save()` calls use `update`. This avoids an extra `findById` round-trip just to determine insert vs update.

**D3.7 — `setCategory(null)` bypasses `Note.copyWith`**
`Note.copyWith(categoryId: null)` keeps the old value (standard Dart nullable-copyWith limitation). `NoteEditorViewModel.setCategory` constructs the `Note` directly so `categoryId: null` is honoured to remove a category assignment. This is intentional and documented to prevent future accidental use of `copyWith` for this case.

**D3.8 — `SearchState` is a plain class in the same file as `SearchViewModel`**
`SearchState` (holding `query: String` and `results: AsyncValue<List<Note>>`) is not a separate file; it lives in `search_view_model.dart`. It has no `Equatable` dependency — the provider's `Notifier` handles rebuild correctly via reference equality on `copyWith` output.

---

## Phase 4 — Note List Screen ✅ Complete

### Decisions Made

**D4.1 — Screen is `ConsumerWidget`, uses `noteListViewModelProvider`**
`NoteListScreen` watches `noteListViewModelProvider` and renders `AsyncValue.when(data, loading, error)`. It also watches `tagListViewModelProvider` to build a `Map<String, String>` (tagId → tagName) for resolving tag names on note cards. The loading state shows pulsing skeleton boxes. The error state shows a retry button calling `ref.invalidate(noteListViewModelProvider)`.

**D4.2 — Two-section list: Pinned then Recent**
Notes are split into `pinned` (isPinned == true) and `recent` (isPinned == false) lists inside the `data` branch. Each list is sorted by `updatedAt` descending. Section headers are only rendered when their respective list is non-empty. Implemented with a `ListView` whose children list is built imperatively.

**D4.3 — Note card widget: `MNNoteCard extends StatelessWidget`**
`lib/presentation/widgets/mn_note_card.dart`. Props: `Note note`, `VoidCallback onTap`, `List<String> tagNames` (defaults to `const []`). The `tagNames` parameter is resolved by `NoteListScreen` before passing — the card never reads providers. Preview text is extracted from Quill Delta JSON (`note.content['ops']`). Timestamp is computed inline. Up to 3 tag chips shown.

**D4.4 — Archived notes are never shown on the home screen**
`INoteRepository.watchAll()` filters out `isArchived == true`. No archive UI in current scope.

**D4.5 — FAB: amber, `bottom: 96`, `right: 20`, navigates to `/note/new`**
Custom `_Fab` widget (GestureDetector + Container). Uses `AppColors.accent` background, `AppColors.accentOn` icon, `borderRadius: 18`, and two-layer box shadow per spec. Calls `context.push(AppRoutes.newNote)`.

**D4.6 — `MNSearchField` on Home is non-editable; tap navigates to `/search`**
`lib/presentation/widgets/mn_search_field.dart` is a `StatelessWidget` with optional `VoidCallback onTap`. On Home it is non-editable (GestureDetector wraps a static row). On Explore it will be editable (Phase 5+).

**D4.7 — Floating bottom nav implemented on NoteListScreen (Phase 4 only)**
The `_BottomNav` widget is absolutely positioned at `left: 16, right: 16, bottom: 14` within a `Stack` inside `SafeArea`. This is a per-screen implementation for Phase 4. Phase 9 (`ShellRoute`) will replace it with a persistent cross-screen nav. Home tab is `isActive: true` (hardcoded for Phase 4).

**D4.8 — Tag name resolution via dual-provider watch**
`NoteListScreen.build()` watches both `noteListViewModelProvider` and `tagListViewModelProvider`. It uses `tagsAsync.maybeWhen(data: ..., orElse: () => <String, String>{})` to build the id→name map. If tags are still loading, cards render without chip labels (empty `tagNames` list); they appear on the next rebuild when tags resolve.

**D4.9 — Shimmer skeleton: pulsing `_SkeletonBox` StatefulWidget**
No third-party shimmer package. `_SkeletonBox` uses `AnimationController.repeat(reverse: true)` with an `AnimatedBuilder` to oscillate opacity between 0.35 and 0.65 over 800 ms. Three skeleton cards shown in `_LoadingBody`.

**D4.10 — No build_runner required for Phase 4**
No new `@riverpod` annotations were added. No new Drift tables. `dart run build_runner build` does not need to be re-run after Phase 4.

---

## Phase 5 — Note Editor Screen ✅ Complete

### Implementation Decisions

**D5.1 — `NoteEditorScreen extends ConsumerStatefulWidget`**
The screen owns `QuillController`, `TextEditingController` (title), `FocusNode`, `ScrollController`, and all timer/subscription handles. `ConsumerStatefulWidget` provides `initState`/`dispose` lifecycle alongside Riverpod watch. Purely presentational shared widgets use `StatelessWidget` (`MNTagRow`) or `StatefulWidget` (`MNEditorToolbar`).

**D5.2 — Controller initialization guarded by `_controllersInitialized` bool**
`_initControllers(Note? note)` is called from `build()` via `noteAsync.whenData(_initControllers)`. The guard ensures it runs exactly once. For existing notes: initializes `QuillController` from `Document.fromJson(note.content['ops'] as List)` and sets `_titleController.text`. For new notes: `QuillController` starts with an empty `Document()`. `setState` is NOT called inside `_initControllers` — the synchronous assignment to `_quillController` during the build frame is sufficient.

**D5.3 — Auto-save: 800 ms debounce on content changes only**
Content changes are detected via `_quillController!.document.changes.listen(...)` (`StreamSubscription` on document mutations, not selection changes). Title changes via `_titleController.addListener`. Both call `_scheduleAutoSave()`. The `_isDirty` flag drives the save badge: `true` → neutral dot + "Saving…"; `false` → green dot + "Saved". On back, the debounce is flushed synchronously (`await _performAutoSave()`) before `context.pop()`.

**D5.4 — `MNEditorToolbar extends StatefulWidget`**
The toolbar owns `controller.addListener` in `initState` (fires on content AND selection changes) so active-state badges update when the cursor moves into formatted text. Toggle logic: active → `Attribute.clone(attr, null)` (removes); inactive → `formatSelection(attr)`. Checklist active = list value `'checked'` OR `'unchecked'`.

**D5.5 — `MNTagRow extends StatelessWidget`**
All state callbacks (`onRemoveTag`, `onAddTagTap`, `onCategoryTap`, `onMicTap`) passed from the parent screen. Tag names resolved from `allTags` list passed in (no provider watch inside widget).

**D5.6 — Recording overlay positioned via `Positioned(left:16, right:16, bottom:8)` in a `Stack`**
The full body column (app bar + editor + tag row + toolbar) is wrapped in a `Stack`. When `_isRecording == true`, `_RecordingOverlay` is absolutely positioned above the toolbar. The pulsing stop button uses `SingleTickerProviderStateMixin` in private `_PulsingStopButton`.

**D5.7 — Tag addition ensures note is persisted first**
`_onAddTagTap` checks `_currentNote == null`. If so, it cancels the debounce and calls `await _performAutoSave()` synchronously before showing the dialog. After `addTag()` or `removeTag()` completes, `_syncCurrentNote()` re-reads the ViewModel state to keep `_currentNote` in sync with the updated `tagIds`.

**D5.8 — Category bottom sheet is a Phase 5 stub**
Tapping the category chip calls `showModalBottomSheet` with placeholder text "Category picker — Phase 8". Full tree picker built in Phase 8.

---

## Phase 6 — Voice-to-Text + Audio ✅ Complete

### Implementation Decisions

**D6.1 — Audio format: AAC, 32kbps, mono, 16kHz**
This is fixed. It gives ~0.24 MB/min, adequate quality for voice, and broad playback compatibility. Never change codec, bitrate, channel count, or sample rate without updating `AppConstants` and the audio spec documentation.

**D6.2 — Audio files stored under `getApplicationDocumentsDirectory()/audio_notes/`**
The subdirectory name is `AppConstants.audioSubDir = 'audio_notes'`. Files are named `{uuid}.aac`. The `AudioFileStorage` class in `lib/data/datasources/file/audio_file_storage.dart` handles all file I/O. DAOs never touch the file system — they only store the `filePath` string.

**D6.3 — `AudioRecordingService` streams amplitude for waveform**
`flutter_sound`'s recorder exposes a `Stream<RecordingDisposition>` with decibel level. `AudioRecordingService` maps this to a normalised `Stream<double>` (0.0–1.0) via `((db + 60) / 60).clamp(0.0, 1.0)` that the UI uses to render the waveform bar heights. Never compute waveform in the UI layer.

**D6.4 — ~~Speech-to-text runs after recording stops~~ → REVISED: STT runs simultaneously with flutter_sound recording**
*Original plan*: `SpeechToTextService` would transcribe the recorded audio file after recording ends.
*Why it changed*: `speech_to_text` v7 only performs live microphone recognition — it cannot transcribe an audio file. File-based transcription is not supported by the package.
*Final decision (confirmed by developer)*: `flutter_sound` recording and `speech_to_text` listening run simultaneously on the same microphone input. The live transcript accumulates in `SpeechToTextService._accumulated` as the user speaks. On stop, the accumulated text is inserted at the Quill cursor. The audio file is saved to `AudioRecord` regardless of STT result.

**D6.5 — Microphone permission handled without `permission_handler` package**
Before recording, `SpeechToTextService.initialize()` is called which triggers the Android `RECORD_AUDIO` permission dialog via the `speech_to_text` package's native handling. Once granted, `flutter_sound` can also use the mic. If `initialize()` returns `false`, a SnackBar is shown ("Microphone permission denied") and recording is aborted. No `PermissionException` is thrown from the ViewModel — permission denial is handled directly in the screen's `_onMicTap`. `PermissionException` is still in `AppException` for future use.

**D6.6 — `AudioRecord` is linked to a note via `noteId`**
One note can have multiple `AudioRecord` entries (the user can record multiple clips). They are displayed in the editor as a horizontal scroll row of compact clip chips above `MNTagRow`. Deleting a note cascades to delete all its `AudioRecord` rows and the corresponding files on disk — handled by `AudioRecordsDao.deleteAllForNote` + `AudioFileStorage.deleteFile`.

**D6.7 — Android STT timeout recovery via `_onStatus` restart**
Android's on-device STT engine stops listening automatically after approximately 7 seconds of silence and fires a `'notListening'` status callback. Without recovery, long recordings would silently stop transcribing. Fix: `SpeechToTextService._onStatus` detects the `'notListening'` status and — if `_active` is still `true` — schedules a 200 ms delayed call to `_listen()` to restart recognition. The 200 ms gap prevents an immediate re-trigger loop. This pattern is transparent to the caller; `accumulatedText` continues to grow across restarts.

**D6.8 — `AudioRecordingService` and `SpeechToTextService` are plain Dart classes, not `@riverpod` providers**
Both services are owned by `_NoteEditorScreenState` as instance fields. Their lifecycle is tied to the screen: created lazily on first mic tap (guarded by `_audioInitialized`), disposed in `State.dispose()`. They are NOT registered as Riverpod providers because they hold active platform channels and subscriptions that must be tied to a single screen instance, not shared app-wide. The `AudioEditorViewModel` and `audioRecordRepositoryProvider` ARE `@riverpod` because they hold only DB-level state.

**D6.9 — File deletion is the screen's responsibility, not the ViewModel's**
`AudioEditorViewModel.deleteRecord(id)` only removes the DB row. The screen's `_AudioClipsRowState._delete` method is responsible for calling both `ref.read(audioEditorViewModelProvider(...).notifier).deleteRecord(id)` AND `_audioStorage.deleteFile(filePath)`. This separation keeps the ViewModel free of file-system concerns (ViewModels must not import `dart:io`) and keeps the DAO's responsibility scope narrow.

---

## Phase 7 — Tags ✅ Complete

### Pre-Decided Architecture (all implemented as designed)

**D7.1 — Tag entry: freeform with live autocomplete**
The tag input in the note editor is a `TextField` that shows a dropdown of existing tags matching the current prefix (via `ITagRepository.searchByPrefix`). Selecting a suggestion assigns the existing tag. Pressing enter with no match creates a new tag. Implemented as `_TagInputSheet` (`ConsumerStatefulWidget`) shown via `showModalBottomSheet<Tag>`. The sheet returns the `Tag` to add; the screen calls `NoteEditorViewModel.addTag(tag.id)` on receipt.

**D7.2 — Tag names are normalised on every write**
Before inserting a new tag or matching an existing one, the input is always passed through `StringExtensions.normalised` (`.toLowerCase().trim()`). The DB unique constraint on `tags.name` is case-insensitive by design because all values are normalised before write. Never store a tag without normalising first.

**D7.3 — Tags screen shows density bars**
Each tag row on the Tags screen shows a proportional density bar: width = `(tagNoteCount / maxNoteCount) * 100%`. The max is computed across all tags in the current list. This is a pure UI computation in `TagsScreen.build()` — not stored in the DB. Counts come from `tagNoteCountsProvider` (`@riverpod FutureProvider → Map<String,int>`). Uses `LayoutBuilder` + a `Stack` of two `Container` widgets (track + fill). `maxCount` defaults to 1 when no tags have notes (avoids divide-by-zero).

**D7.4 — Tag deletion cascades from UI only**
Deleting a tag from the Tags screen calls `ITagRepository.delete(id)`. The `TagsDao` removes the tag from `tags`, removes all rows in `note_tags` for that tag, and syncs `tagIds` on affected notes via `_syncDenormalisedTagIds`. This is done inside a Drift transaction. Long-press on a tag row triggers a delete confirmation dialog.

**D7.5 — Maximum 20 tags per note**
`AppConstants.maxTagsPerNote = 20`. The `+ tag` chip in `MNTagRow` renders at 40% opacity and ignores taps when `maxTagsReached == true`. `_onAddTagTap` in `NoteEditorScreen` returns early with a SnackBar ("Maximum 20 tags per note") when the limit is reached.

### Implementation Details

**D7.6 — `_TagInputSheet` is a `ConsumerStatefulWidget` in `note_editor_screen.dart`**
The sheet has its own `TextEditingController`, 200 ms debounce timer, and `_suggestions: List<Tag>` state. It calls `tagListViewModelProvider.notifier.searchByPrefix` on each change and `findByName` on submit to distinguish "use existing" from "create new". It pops with the `Tag` object. The screen does not see the sheet's internals — it only receives the result.

**D7.7 — `tagNoteCountsProvider` is not `keepAlive`**
By default, `@riverpod` providers are auto-disposed when their last listener unmounts. `tagNoteCountsProvider` is therefore recreated each time `TagsScreen` opens, ensuring note counts are always fresh on screen entry. No manual invalidation needed.

**D7.8 — `TagListViewModel` gains query helper methods (no state mutation)**
`searchByPrefix(prefix)` and `findByName(name)` delegate directly to the repo and do not set `state`. They are convenience methods for the `_TagInputSheet` view layer so the sheet never calls the repo directly (rule 4 compliance).

**D7.9 — `TagsDao.countNotesPerTag` uses raw SQL GROUP BY**
A `customSelect` query on `note_tags GROUP BY tag_id` with `COUNT(note_id)` returns note counts per tag. Tags with zero notes are not in the result map (default to 0 in the UI). This is a one-shot query, not a stream.

**D7.10 — Tags screen bottom nav is per-screen (active tab index 2)**
Consistent with Phase 4 (`NoteListScreen` has active tab 0). Phase 9's `ShellRoute` will replace all per-screen nav bars with a single persistent one.

---

## Phase 8 — Categories ✅ Complete

### Pre-Decided Architecture

**D8.1 — Category structure: adjacency list, max depth 5**
Categories are stored as a flat list with a nullable `parentId` (adjacency list pattern). Building the tree for display is done in the ViewModel by recursively grouping by `parentId`. Max nesting depth is `AppConstants.maxCategoryDepth = 5`. The ViewModel enforces this when creating a new category — it checks the depth of the target parent before inserting.

**D8.2 — One note belongs to zero or one category**
`Note.categoryId` is nullable. A note with no category is in "Uncategorised" — this is not a real category row in the DB, just a null state displayed as a UI affordance. Never create a default "Uncategorised" category in the DB.

**D8.3 — Category picker is a bottom sheet**
Assigning a category from the note editor opens a bottom sheet (`MNCategoryPickerSheet`) showing the full tree. Spec: `MODUNOTE_UI_REFERENCE.md § 3.5`. Tree rows are indented by `paddingLeft = 10.0 + depth * 20.0`. Expand/collapse state is local to the sheet (not persisted).

**D8.4 — PD-01 resolved: re-parent deletion policy**
✅ Resolved at Phase 8 start (developer decision).
When a category is deleted, its direct children are re-parented to the deleted category's parent (grandparent), or to root (`parentId = null`) if no grandparent. Notes whose `categoryId` equals the deleted category are set to `null` (Uncategorised). The alternative (cascade delete all descendants) was rejected — it would silently delete subtrees the user may want to keep.

**D8.5 — `sortOrder` on categories**
Categories have a `sortOrder: int` field for manual ordering within siblings. The default is insertion order (0, 1, 2, ...). Drag-to-reorder UI is deferred to a future version — Phase 8 only exposes alphabetical display.

### Implementation Decisions

**D8.6 — `clearCategoryFromNotes` added to `NotesDao`**
A new `clearCategoryFromNotes(String categoryId)` method sets `categoryId = null` on all notes that currently reference the given category. It is called exclusively by `LocalCategoryRepository.delete` inside the deletion transaction. It uses `Value(null)` in a `NotesTableCompanion` — consistent with how Drift nulls out nullable columns. No annotation change was needed; `NotesDao` already declared `@DriftAccessor(tables: [NotesTable, NoteTagsTable])`.

**D8.7 — `LocalCategoryRepository` constructor extended with `NotesDao`**
The Phase 2 implementation of `LocalCategoryRepository` took only `CategoriesDao`. Phase 8 extends the constructor to `const LocalCategoryRepository(this._categoriesDao, this._notesDao)` so the repository can call `clearCategoryFromNotes` during deletion. The provider in `database_providers.dart` is updated to pass `db.notesDao` as the second argument. No build_runner run was needed (function body change only; annotation unchanged).

**D8.8 — `MNCategoryPickerSheet` return value protocol**
`MNCategoryPickerSheet` communicates its outcome via `Navigator.pop<String>`:
- Non-empty `String` → the selected category id (assign that category)
- Empty `String` `""` → the user chose "None" (unassign the category)
- `null` → the sheet was dismissed with no change (tapped the X, swiped away, pressed back)

The note editor's `_onCategoryTap` checks the result after `showModalBottomSheet` returns: `null` → no-op; empty string → `setCategory(null)`; non-empty → `setCategory(id)`.

**D8.9 — `MNCategoryPickerSheet` expand state seeded from ancestor chain**
On sheet open, `_initExpanded` walks up the ancestor chain of the current `categoryId` and adds each ancestor's id to `_expandedIds`. This ensures the currently-selected category is visible without the user having to manually expand its parent folders. Expand/collapse toggling persists for the duration of the sheet but is not saved between openings.

**D8.10 — No build_runner run required for Phase 8**
No new `@riverpod` annotations were added. No Drift table structure changed. The `database_providers.dart` change is in the function body only (annotation `@Riverpod(keepAlive: true)` unchanged). `notes_dao.dart` new method has no Drift generator annotation. All generated `.g.dart` files remain current from Phase 7.

---

## Phase 9 — Navigation + Theming ✅ Complete

### Pre-Decided Architecture (all implemented as designed)

**D9.1 — GoRouter `ShellRoute` for persistent bottom nav bar**
`app_router.dart` wraps the four main tabs (Home `/`, Explore `/search`, Tags `/tags`, Settings `/settings`) in a `ShellRoute`. `_AppShell` renders `MNBottomNav` persistently and swaps the tab body based on the current route. Note Editor routes (`/note/new`, `/note/:id`) are `GoRoute` entries outside the shell — full-screen routes accessed via `context.push`.

**D9.2 — Bottom nav bar is a custom floating pill**
`MNBottomNav` is a new `StatelessWidget` at `lib/presentation/widgets/mn_bottom_nav.dart`. It is positioned via `Positioned(left:16, right:16, bottom:14)` in the `_AppShell`'s `Stack`. Props: `int activeIndex`. 4 tabs: Home (0), Explore (1), Tags (2), Settings (3). Active tab: `primaryContainer` bg + `br:26` pill + label (Inter 13/600). Inactive: icon only on transparent bg. Uses `context.go` for tab switching.

**D9.3 — Theme persistence via SharedPreferences**
`ThemeModeNotifier.build()` remains synchronous (`Notifier<ThemeMode>`) — fires `_loadPersistedMode()` as fire-and-forget from `build()`, returning `ThemeMode.system` as the first-frame default. Writes happen via `_setAndPersist(ThemeMode)` which sets `state` immediately (instant UI update) then writes to SharedPreferences. Key: `AppConstants.prefThemeMode = 'theme_mode'`. Package added: `shared_preferences: ^2.3.0`.

**D9.4 — `_AppShell` provides outer Scaffold + SafeArea; tab screens return content only**
`_AppShell extends StatelessWidget` is a private class in `app_router.dart`. It wraps the child in `Scaffold(body: SafeArea(child: Stack([Positioned.fill(child), Positioned(nav)])))`. Tab screens (`NoteListScreen`, `SearchScreen`, `TagsScreen`, `SettingsScreen`) no longer have their own `Scaffold`/`SafeArea` — they return body content directly. This avoids nested Scaffold issues. FAB remains inside `NoteListScreen` (Home-only concern, not shell concern).

**D9.5 — Settings screen theme toggle uses two-option card, not a Switch**
`settings_screen.dart` is a full rewrite of the Phase 1 placeholder. Returns `ListView` (no Scaffold). Contains an Appearance card with two `_ThemeTile` widgets (Light / Dark). Selected tile: 2 px `primary` border + `primaryContainer` bg. Unselected: 0.5 px `outlineStrong` + `surfaceContainer` bg. Mini preview shows simulated note card in each theme's card colour. If `ThemeMode.system`, neither tile is highlighted — system is a hidden third state.

### Implementation Details

**D9.6 — Tab navigation uses `context.go`; Note Editor uses `context.push`**
All 4 tab routes use `context.go(route)` — they are shell children, not pushed onto the GoRouter stack. Note Editor and Category Picker are pushed with `context.push`. SearchScreen's back arrow now calls `context.go(AppRoutes.home)` instead of `context.pop()` because `/search` is a shell tab, not a pushed route.

**D9.7 — `MNBottomNav` active index derived from `state.uri.path` in shell builder**
`_AppShell._tabIndex(String loc)` maps location strings to indices: `/search` → 1, `/tags` → 2, `/settings` → 3, everything else → 0. Passed as `location: state.uri.path` from the ShellRoute builder.

**D9.8 — `_AppShell` and `MNBottomNav` are `StatelessWidget`, not `ConsumerWidget`**
Neither watches Riverpod providers — `_AppShell` uses only `Theme.of(context)` for scaffold background colour. The convention "screen widgets extend ConsumerWidget" applies to screen-level widgets only, not internal layout helpers.

**D9.9 — Tags screen `go_router` and `app_router` imports removed post-refactor**
After removing the per-screen `_BottomNav`/`_NavTab` classes, `tags_screen.dart` no longer references `go_router` or `AppRoutes` — both imports removed to maintain `flutter analyze = 0 issues`.

**D9.10 — `sort_child_properties_last` lint requires `child:` param to be last**
Flutter's `sort_child_properties_last` rule requires `child:` (and `children:`) named parameters to appear last in widget constructor calls. The ShellRoute builder initially called `_AppShell(child: child, location: ...)` — the lint flagged it. Fixed to `_AppShell(location: state.uri.path, child: child)`. All future widget constructors with `child:` must put it last.

**D9.11 — `flutter_floating_bottom_bar ^2.0.0` replaces manual `Stack`/`Positioned` nav layout**
`_AppShell.build()` was refactored from `SafeArea(child: Stack([Positioned.fill(child), Positioned(nav)]))` to `BottomBar(body: SafeArea(child: child), child: Stack([MNBottomNav, Positioned(FAB)]))`. The package provides hide-on-scroll via `NotificationListener<ScrollNotification>` — no `ScrollController` wiring required. Any descendant `ListView` / `CustomScrollView` in `body` automatically drives the hide/show animation. `BottomBarThemeData(barDecoration: transparent)` ensures the package doesn't double-decorate the nav pill. `clip: Clip.none` preserves `MNBottomNav`'s drop shadow.

**D9.12 — `_NavFab` center notch is the sole entry point for creating a new note**
The old `_Fab` widget inside `NoteListScreen` (`Stack` / `Positioned(bottom:96, right:20)`) was removed. `_NavFab` — a private `StatelessWidget` in `app_router.dart` — is a 52 px amber circle with amber glow shadow, positioned with `Positioned(top: -20)` inside the `_AppShell` Stack so it protrudes 20 px above the nav pill. It calls `context.push(AppRoutes.newNote)`. Being inside `_AppShell` means it is present on all 4 shell tabs, not just Home.

**D9.13 — Icon-only tabs (no text labels in nav)**
`MNBottomNav`'s `_NavTab` was simplified: the `Row([Icon, if(isActive) Text(...)])` is replaced by `Center(child: Icon(..., size: 22))`. The active tab still shows the `primaryContainer` background pill — it just has no label. A 60 px `SizedBox` gap in the row creates the visual notch space for the protruding FAB. The `label` parameter and `AppTypography` import were removed.

**D9.14 — Scroll-to-top icon uses `BottomBar.icon` builder, not `BottomBarThemeData` fields**
`BottomBarThemeData` (v2.0.0) supports `barDecoration`, `iconDecoration`, `iconWidth`, `iconHeight` — it does NOT have `iconData` or `iconColor` fields. To customise the scroll-to-top icon, pass the `icon: BackToTopIconBuilder` function directly on `BottomBar`: `icon: (w, h) => Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.accentOn, size: w * 1.4)`. The `iconDecoration` is set to amber (`AppColors.accent`) to match the nav FAB, making the scroll-to-top button visually consistent.

---

## Phase 10 — Firebase Preparation Layer ✅ Complete

### Implementation Details

**D10.5 — `FirebaseNoteRepository` is a pure Dart stub with no Firebase imports**
The class implements `INoteRepository` with every method throwing `UnimplementedError`. Crucially, it imports no Firebase packages — it is a pure Dart file. This means the class compiles and type-checks without `Firebase.initializeApp()` being called and without `google-services.json` being present. Firebase SDK imports will be added when live Firestore calls are implemented.

**D10.6 — `SyncedNoteRepository` suppresses `unused_field` on `_remote`**
`_remote` is held as a class field for the future sync phase. Since `syncEnabled` is always `false` in Phase 10, `_remote` is never called. A targeted `// ignore: unused_field` comment on the field prevents `flutter analyze` from flagging it, which would otherwise produce 1 issue. This is the canonical Dart approach for intentionally-held future-use fields.

**D10.7 — `noteRepositoryProvider` body changed; no build_runner run required**
The provider annotation (`@Riverpod(keepAlive: true)`) and return type (`INoteRepository`) are unchanged. Only the body was modified to return `SyncedNoteRepository(local: ..., remote: ...)`. No `@riverpod` annotation was added or removed, so `dart run build_runner build` does not need to be run for Phase 10.

**D10.8 — `SyncStatus` audit result: all writes already correct**
Confirmed that `Note.syncStatus` defaults to `SyncStatus.local` in the model constructor. Every note constructed in the editor uses this default or preserves the existing `syncStatus` via `copyWith`. `_noteToCompanion` in `LocalNoteRepository` writes `note.syncStatus.name` to the DB — so all notes are stored as `'local'` throughout Phase 10. No callsite changes were needed.

**D10.9 — Firebase SDK added to pubspec.yaml without Gradle configuration**
`firebase_core: ^3.6.0` and `cloud_firestore: ^5.4.4` were added to `pubspec.yaml`. The Android Gradle files (`android/build.gradle`, `android/app/build.gradle`) were NOT modified and `google-services.json` was NOT added. This is safe because: (1) the Google Services Gradle plugin is not applied, so no build failure; (2) no `Firebase.initializeApp()` is called anywhere, so no runtime crash. Full Firebase setup requires running `flutterfire configure` which generates `google-services.json`, `firebase_options.dart`, and applies the Gradle plugin — documented as a manual step before Phase 11/12.

### Pre-Decided Architecture

**D10.1 — Firebase integration via repository interface swap**
The Firebase integration does not touch any ViewModel or View. `LocalNoteRepository` is replaced by `SyncedNoteRepository` (which wraps both Drift and Firestore) at the Riverpod provider level only — in `database_providers.dart`. The ViewModel continues watching `INoteRepository` without any change.

**D10.2 — Phase 10 only adds stubs — no live Firebase calls**
Phase 10's deliverable is the scaffolding: `FirebaseNoteRepository` stub, `SyncedNoteRepository` stub, Firebase SDK added to `pubspec.yaml`, `google-services.json` placeholder documentation, and `SyncStatus` wiring verified. No actual Firestore reads/writes until the developer explicitly enables them.

**D10.3 — `SyncStatus` transitions**
`local` → note exists only on device, not yet queued for sync. `pending` → queued for sync, not yet confirmed. `synced` → confirmed written to Firestore. `conflict` → local and remote diverge (last-write-wins resolution in Phase 10, full conflict UI deferred). The `updatedAt` timestamp is the tiebreaker for last-write-wins.

**D10.4 — Firebase Auth is out of scope for Phase 10**
Phase 10 does not implement sign-in. The Firebase project is set up with anonymous auth or no auth, and sync is keyed to device ID. Full auth (Google sign-in) is deferred to post-MVP.

---

### Phase 10 Extension — Live Firebase Sync ✅ Complete

**D10.10 — Anonymous auth: silent, no login UI**
The developer uses the app personally — no user-facing auth flow is needed. `FirebaseAuthService` (singleton at `lib/services/auth/firebase_auth_service.dart`) calls `FirebaseAuth.instance.signInAnonymously()` idempotently on app start. Firebase assigns a device UID automatically. Firestore security rules scope all data to `request.auth.uid == userId`, so no other user can read or write the data even if someone inspects the Firebase project credentials.

**D10.11 — Reads stay local-only; Firestore is write-only for sync**
Firestore has no FTS5 equivalent. `FirebaseNoteRepository` read methods (`watchAll`, `watchByTag`, `watchByCategory`, `findById`, `search`) all throw `UnimplementedError`. All reads go through `LocalNoteRepository` (Drift). Firestore only receives writes during `syncNote()` / `syncAllPending()`. This means Firestore is a backup sink, not the primary data store.

**D10.12 — Sync triggered on note-close and app-background, NOT on every auto-save**
Local Drift auto-save (800 ms debounce) still fires on every keystroke as before. Firebase sync fires only when: (1) the user presses back from `NoteEditorScreen` (`_onBack()`), or (2) the app goes to background (`AppLifecycleState.paused`). This avoids hammering Firestore with a write per keystroke and keeps Firestore costs near zero.

**D10.13 — Firebase init wrapped in try-catch; app boots without Firebase**
`main.dart` wraps `Firebase.initializeApp()` + `FirebaseAuthService().signInAnonymously()` in a try-catch. If Firebase fails (e.g. stub `firebase_options.dart` still in place before `flutterfire configure` is run), a `debugPrint` is emitted and the app continues without sync. All sync operations in `SyncedNoteRepository` and `FirebaseNoteRepository` also catch errors silently.

**D10.14 — `syncedNoteRepositoryProvider` typed as `SyncedNoteRepository` (not `INoteRepository`)**
`syncNote()` and `syncAllPending()` are extra methods not in `INoteRepository`. To call them, the caller needs the concrete type. A dedicated `@Riverpod(keepAlive: true) SyncedNoteRepository syncedNoteRepository(...)` provider is added. `noteRepositoryProvider` delegates to it: `ref.watch(syncedNoteRepositoryProvider)`. Single shared instance — no duplication.

**D10.15 — `_SaveBadge` extended from 2 to 4 states**
Old states: `isDirty=true` → "Saving…" (muted dot), `isDirty=false` → "Saved" (green dot).
New states: `isDirty=true` → "Saving…" (muted dot), `SyncStatus.local` → "Local" (grey `#9E9E9E` dot), `SyncStatus.pending` → "Syncing…" (amber `AppColors.accent` dot), `SyncStatus.synced` → "Synced" (green `AppColors.savedGreen` dot). Screen-level `_syncStatus` state variable initialized from `note.syncStatus` in `_initControllers`.

**D10.16 — `_AppShell` converted to `ConsumerStatefulWidget` with `WidgetsBindingObserver`**
`_AppShell` was `StatelessWidget` in Phase 9 (D9.8). It now needs `ref` (for `syncedNoteRepositoryProvider`) and `WidgetsBinding.instance.addObserver` (for AppLifecycle). Converted to `ConsumerStatefulWidget` + `_AppShellState extends ConsumerState<_AppShell> with WidgetsBindingObserver`. The D9.8 rule ("_AppShell is StatelessWidget") is superseded by this decision.

**D10.17 — Firestore security rules deny all paths except `/users/{uid}/notes/{noteId}`**
`firestore.rules` at project root. Deployed manually in Firebase Console. Two-rule structure: (1) allow read/write on notes subcollection when `request.auth != null && request.auth.uid == userId`; (2) deny all other paths with `allow read, write: if false`. This ensures no data leakage even if someone finds the Firebase project ID.

**D10.18 — Security scan: `.gitignore` gaps patched**
Before this session, `google-services.json` and `lib/firebase_options.dart` were not in `.gitignore`. These files contain Firebase project identifiers (API keys, app IDs) and are generated by `flutterfire configure`. Both are now gitignored alongside `session_context.md`. GitHub repo scan (179 files) confirmed clean — no credentials committed.

**D10.19 — FTS5 trigger bug fixed: schema version bumped to 2 (BUG-FTS5)**
Root cause: The original FTS5 AFTER UPDATE trigger used `UPDATE notes_fts SET title=…, content=… WHERE rowid=N` and the AFTER DELETE trigger used `DELETE FROM notes_fts WHERE rowid=N`. Both are unsupported SQL for external content FTS5 tables — SQLite requires the special `INSERT INTO fts(fts, …) VALUES('delete', …)` form. The broken UPDATE trigger caused every note UPDATE to fail and roll back, while INSERTs (first save) succeeded. Result: notes appeared on the home screen (first INSERT worked) but timestamps never updated (all subsequent UPDATEs silently failed).
Fix: `app_database.dart` `schemaVersion` bumped to 2. `_createFtsVirtualTableAndTriggers()` rewritten with correct triggers. `onUpgrade(from < 2)` drops the broken triggers, recreates correct ones, and runs `INSERT INTO notes_fts(notes_fts) VALUES('rebuild')` to repair the FTS index.

**D10.20 — `_performAutoSave` now detects silent ViewModel save failures**
`NoteEditorViewModel.save()` catches `AppException` internally and sets `state = AsyncError` without rethrowing. As a result, `_performAutoSave`'s `catch (_)` was dead code — execution always reached `_isDirty = false`, making the badge show "Local" even on a failed save. Fix: after awaiting `save()`, `_performAutoSave` explicitly reads `ref.read(…).hasError` and returns early (keeping `_isDirty = true`) if the ViewModel is in error state. `debugPrint` added to both the ViewModel catch block and the screen's error path so failures are visible in the debug console.

---

## Phase 11 — Backend API Scaffolding ✅ Complete

### Pre-Decided Architecture

**D11.1 — Backend stack: FastAPI + PostgreSQL + SQLAlchemy async + Alembic**
Chosen because the developer has existing Python/FastAPI/PostgreSQL skills. This is non-negotiable — do not substitute Django, Node, or any other stack.

**D11.2 — Backend lives in a separate repository**
The FastAPI backend is a separate repo, not a subdirectory of the Flutter project. Phase 11 creates the scaffolding in a `modunote-api/` directory at the same level as `modunote/`.

**D11.3 — Phase 11 is stubs only — no deployed endpoints**
Phase 11 delivers: project structure, `main.py`, router stubs for the AI endpoints (`/api/v1/notes/{id}/tags/suggest`, `/api/v1/notes/{id}/summary`), Pydantic models, SQLAlchemy model stubs, Alembic config, and a `docker-compose.yml` for local development. No endpoint is functional until Phase 12.

**D11.4 — API is stateless, JWT-authenticated**
The API expects a JWT bearer token in the `Authorization` header. In the stub phase, auth is bypassed with a development flag (`DEV_MODE=true` in `.env`). Full JWT validation is implemented when auth is enabled in post-Phase-12 work.

**D11.5 — Flutter calls the API via a `RemoteNoteService` class**
A `lib/services/remote/remote_note_service.dart` class handles all HTTP calls using `http: ^1.2.0` (stdlib-level, no extra overhead for stub-level calls). It is not a repository — it is a service. The `SyncedNoteRepository` (Phase 10) uses it for AI enrichment calls after sync. ViewModels never call the API directly.

### Implementation Decisions

**D11.6 — `http` package chosen over `dio`**
`http: ^1.2.0` was chosen for Phase 11 stubs because it is the standard Dart HTTP library with minimal overhead. `dio` would add interceptors, retry logic, and other features that are unnecessary while all endpoints return 501. If Phase 12 requires auth header injection on every request or retry logic, swap to `dio` then.

**D11.7 — `RemoteNoteService` is a plain Dart class, not a Riverpod provider**
Mirrors the pattern used for `AudioRecordingService` and `SpeechToTextService` (D6.8). Lifecycle is managed by the caller. `SyncedNoteRepository` will hold a reference in Phase 12. ViewModels must never instantiate or call `RemoteNoteService` directly.

**D11.8 — Default base URL is `http://10.0.2.2:8000/api/v1`**
`10.0.2.2` is the Android emulator's special loopback address that routes to the host machine's `localhost`. This allows the emulator to call the FastAPI server running on the dev machine without any network configuration. Override via constructor param when testing on a physical device or deploying to production.

**D11.9 — `RemoteServiceException` added to `AppException` sealed class**
All HTTP errors from `RemoteNoteService` are wrapped in `RemoteServiceException(message, {cause})`. Consistent with `DatabaseException` (D2.5) and `FileStorageException` — raw `http.ClientException` and `SocketException` never propagate above the service layer.

**D11.10 — Backend `core/auth.py` dev-mode bypass returns fixed UID `"dev-user-local"`**
When `DEV_MODE=true`, `verify_token` returns the string `"dev-user-local"` without inspecting the `Authorization` header. This allows curl/Swagger testing without a real Firebase token. In production (`DEV_MODE=false`), missing or invalid tokens raise `HTTP 401`.

**D11.11 — Alembic `env.py` uses async SQLAlchemy engine**
`alembic/env.py` wraps migration execution in `asyncio.run()` to be consistent with the app's async SQLAlchemy setup. All future migrations will run via `alembic upgrade head` using the async engine. The `DATABASE_URL` is read from `core/config.py` (Settings class) — never hardcoded.

**D11.12 — Backend `db/models.py` stub — no tables created in Phase 11**
`SQLAlchemy Note` model is defined but Alembic has no migration files yet. Running `alembic upgrade head` on a clean DB will produce no table changes until Phase 12 generates the first migration via `alembic revision --autogenerate`. This is intentional — Phase 11 is scaffolding only.

---

## Phase 11.5 — Bug Fixes + UX Features ✅ Complete

### Decisions Made

**D11.5a — Swipe-to-dismiss on note cards springs back (no real dismissal)**
`NoteListScreen` cards are wrapped in `Dismissible`: swipe left = archive, swipe right = toggle pin. `confirmDismiss` returns `false` so the card springs back; the underlying Drift stream removes/reorders it on the next emission. This avoids dismissal animations fighting the reactive list.

**D11.5b — Note options sheet from the editor ⋮ button**
The ⋮ button in `NoteEditorScreen` opens `_NoteOptionsSheet` (Pin/Unpin, Archive, Delete-with-confirm). `_CircleIconButton.onTap` made nullable; the button is muted until the note is first persisted. Archive and Delete pop the editor after the action.

**D11.5c — Long-press on a list card opens `_NoteActionsSheet`**
Mirrors the editor options sheet for the list screen — same three actions.

**D11.5d — `INoteRepository` gains `watchArchived()` + `unarchive()`**
Added to the interface and implemented in all three impls (Local, Firebase stub, Synced). `NoteEditorViewModel` gains `togglePin()`, `archive()`, `delete()`.

**D11.5e — Archive screen at `/archive`, outside the ShellRoute**
`ArchivedNotesScreen` + `ArchivedNotesViewModel`. Reached from Settings → "Archived Notes". Swipe right = restore, swipe left = delete-with-confirm. Own empty state. Full-screen push, not a shell tab.

**D11.5f — System theme exposed as a third tile**
`_AppearanceCard` in `SettingsScreen` now has Light / Dark / System tiles. System uses `Icons.brightness_auto_outlined` with a split light/dark mini-preview. `ThemeMode.system` was already the default (D1.5); this surfaces it.

**D11.5g — Category/tag filter chip bar on the home screen**
`NoteFilterNotifier` (`@riverpod Notifier<NoteFilter>`) holds the active filter (all / category / tag). `NoteListViewModel.build()` watches it and switches between `watchAll()`, `watchByCategory()`, and `watchByTag()`.

**D11.5h — `LocalNoteRepository` write methods return `Future<void>`**
`insert`/`update` corrected from `Future<Note>` to `Future<void>`; `togglePin` from `Future<Note?>` to `Future<void>` — matching the interface.

---

## Phase W — Web Portfolio Preview ✅ Complete

### Implementation Decisions

**DW.1 — Platform-conditional executor via `driftDatabase()` + `DriftWebOptions`**
`AppDatabase.createExecutor()` branches on `kIsWeb`. On web: `driftDatabase(name: 'modunote', web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')))`. On native: `driftDatabase(name: 'modunote.db')` (unchanged). Used the `drift_flutter 0.2.7` high-level API (`DriftWebOptions` from `drift_flutter`) rather than raw `WasmDatabase.open()` from `drift/wasm.dart` — cleaner, one unified function for both platforms.

**DW.2 — `AudioFileStorage` web/native split via Dart conditional export**
`dart:io` is not available at compile time on web — not just a runtime issue. A `kIsWeb` check inside the class body would not fix the compile failure. Solution: convert `audio_file_storage.dart` to a 2-line conditional export file: `export '..._native.dart' if (dart.library.html) '..._web.dart'`. The native file contains the full original implementation; the web stub provides the same class shape but throws `FileStorageException` for path-based methods and no-ops `ensureAudioDir`/`deleteFile`. No `dart:io` import in the web stub.

**DW.3 — Audio recording disabled on web (Stage 1); informational snackbar shown**
`flutter_sound` writes AAC to native file paths — no web equivalent. `NoteEditorScreen._onMicTap()` checks `kIsWeb` as its first guard: if web, show snackbar "Audio recording is not available in the web preview." and return. `_AudioClipsRow` is hidden entirely on web via `if (!kIsWeb && _currentNote != null) _AudioClipsRow(...)`. Stage 2 web audio (WebM/Opus + IndexedDB blobs) is deferred.

**DW.4 — Custom `flutter_bootstrap.js` with `hostElement` to confine Flutter to a phone frame div**
By default Flutter web takes the full viewport. To embed it in a 390×844 phone frame div, a custom `web/flutter_bootstrap.js` is used with `{{flutter_js}}` / `{{flutter_build_config}}` template variables (Flutter replaces these during build). `initializeEngine({hostElement: document.querySelector('#flutter-host')})` confines the Flutter canvas to the specific div inside the phone frame.

**DW.5 — COOP/COEP headers required for drift WASM shared memory**
`SharedArrayBuffer` (used by drift's OPFS-shared storage backend for best performance) requires cross-origin isolation headers: `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`. These are set globally in `firebase.json` hosting headers. Without them, drift falls back to IndexedDB (still functional, just slower). Added to `firebase.json` hosting section.

**DW.6 — `sqlite3.wasm` downloaded from GitHub releases, not from pub cache**
The `sqlite3` pub package ships C source but not a pre-compiled WASM binary. The WASM file must be downloaded separately from the sqlite3.dart GitHub releases page (`sqlite3-2.9.4`). File placed at `web/sqlite3.wasm` (713 KB).

**DW.7 — `web/drift_worker.dart` compiled to JS with `dart compile js -O2`**
Drift's WASM backend requires a Dart web worker compiled to JS. Entry point: `web/drift_worker.dart` using `package:drift/wasm.dart`'s `WasmDatabase.workerMainForOpen()`. Compiled to `web/drift_worker.js` via `dart compile js -O2 -o web/drift_worker.js web/drift_worker.dart`. This file is checked into the repo (it's a build artifact but needed before `flutter build web`).

**DW.8 — Phone-frame landing page: pure CSS, responsive**
`web/index.html` replaced with a styled dark-navy landing page (background `#1C1B2E`). The phone frame is CSS-only: `.phone-bezel` with `border-radius: 50px`, dynamic island via `::before` pseudo-element, side buttons via `::after`. `#flutter-host` is `position: absolute; inset: 0` inside `.phone-screen`. Loading overlay fades on `flutter-first-frame` event. Responsive: CSS `calc()` scales the frame below 460 px viewport width. Same font families as the app (Plus Jakarta Sans + Inter).

**DW.9 — Firebase Hosting SPA rewrite ensures GoRouter URL routing works**
GoRouter uses URL-based navigation; all paths (e.g. `/search`, `/tags/`) must serve `index.html`. Firebase Hosting `firebase.json` has `"rewrites": [{"source": "**", "destination": "/index.html"}]`.

---

## Phase 11.6 — Bug Fixes (filter + editor) ✅ Complete

### Decisions Made

**D11.6a — Hierarchical category filtering via client-side descendant resolution**
Selecting a parent category must show notes from the whole subtree. Added `NotesDao.watchByCategoryIds(List<String>)` (Drift `isIn()` filter), surfaced through `INoteRepository` and all three impls. `NoteListViewModel._collectDescendants(all, rootId)` runs an iterative BFS over the category adjacency list to collect the root + all descendant ids, then calls `watchByCategoryIds`. Descendant resolution lives in the ViewModel (not SQL) because the adjacency list is already streamed via `categoryTreeViewModelProvider`; a recursive SQL CTE adds complexity for no benefit at this scale.

**D11.6b — `_FilteredEmptyState` keeps the filter bar visible on empty results**
Previously a filter returning zero notes fell through to `_EmptyState` (no chips), so the whole tray vanished and felt broken. Fix: `_EmptyState` is now gated on `filter.type == NoteFilterType.all`; any active filter with zero results renders `_FilteredEmptyState` (`ConsumerWidget`) — search field + `_FilterChipBar` + a centered "No notes in [name]" message.

**D11.6c — Editor category selection syncs immediately**
`_onCategoryTap` now calls `_syncCurrentNote()` after `setCategory()`, re-reading the ViewModel so `_currentNote.categoryId` reflects the change without closing/reopening the editor. Same `_syncCurrentNote()` pattern already used after tag add/remove (D5.7).

**D11.6d — Tag picker browses existing tags when the field is empty**
`_TagInputSheet` (`ConsumerStatefulWidget`) now watches `tagListViewModelProvider` in `build()` and lists all tags not already on the note (under an "All tags" subheader) when the input is empty, switching to prefix-filtered `_suggestions` as the user types. Previously the sheet only offered to create a new tag, hiding existing ones.

---

## Phase 12 — AI Features 🟡 In Planning

> **Direction locked**: full **4-stage roadmap**, first feature **via the FastAPI backend** (`modunote-api/`), provider **Groq** (switched from Gemini on 2026-06-22 — see D12.2). Supersedes the earlier "two features, provider TBD" plan, preserved under "Superseded" below per the file's never-delete rule.

### Resolved Decisions

**D12.1 — AI features are strictly post-full-app** *(unchanged)*
No AI feature is built until Phases 1–11 + W are complete and the app is fully functional. ✅ Satisfied as of Phase 11.6.

**D12.2 — Provider: Groq** *(resolves PD-02; switched from Gemini 2026-06-22)*
Chat/text generation runs on **Groq** (default model `llama-3.3-70b-versatile`) via the official `groq` Python SDK (OpenAI-compatible). Chosen because Gemini's free tier proved unusable in practice for this developer — requests failed before any real testing — whereas Groq offers a generous, fast free tier. The provider logic is isolated in `services/ai_service.py`, so this swap touched only that file + `config.py` + `requirements.txt` — no Flutter changes (the payoff of the backend-routed architecture, D12.3).
*Embeddings (Stage 2 RAG)*: Groq has no first-party embedding model, so Stage 2 will use **local `sentence-transformers`** (e.g. `all-MiniLM-L6-v2`, 384-dim) in the FastAPI process — free, no quota, no second key. Alternatives if a hosted embedder is preferred: Mistral (`mistral-embed`) or Cohere (`embed-v3`).
*Superseded rationale (Gemini)*: originally chosen for its free tier + first-party embeddings; dropped after the free tier blocked testing. ⚠️ Free-tier limits change — verify Groq quotas at https://console.groq.com.

**D12.3 — Architecture: route AI through the FastAPI backend, not direct from Flutter** *(resolves the build-path fork)*
The existing `modunote-api/` scaffold (FastAPI + PostgreSQL + SQLAlchemy async) is activated. Flutter's `RemoteNoteService` calls the backend; the backend calls the LLM provider (Groq). Chosen over direct-from-Flutter because Stages 2–4 (RAG, observability, deployment) all require the backend regardless — routing Stage 1 through it from the start avoids throwaway work and keeps the API key server-side. Also matches the developer's existing Python/FastAPI strength.

**D12.4 — AI calls never block the save/UI flow** *(unchanged in spirit; renumbered)*
Local Drift auto-save remains authoritative. AI calls fire asynchronously after a save completes. Failure (no internet, API error, rate limit) is silent and non-fatal — the note is already saved. All HTTP errors wrapped in `RemoteServiceException` (D11.9).

**D12.5 — UX & scope resolutions (2026-06-22)**
- **Stage 1 presentation**: *both* — auto-tag suggestions as a dismissible banner + a bottom sheet for the text-rewrite actions (Improve/Humanize/Paraphrase/Script/Critique + Summarise).
- **Stage 2 QnA**: a *dedicated QnA screen* with its own route + nav entry (not a Search-screen mode).
- **Backend auth/scope**: *single-user* — `DEV_MODE` bypass locally, one static API key (`X-API-Key`) once deployed. No multi-tenant accounts or per-user JWT.
- The full step-by-step build spec for all four stages, with per-stage task checklists, lives in **`PHASE_12_PLAN.md`** — the standing plan all threads follow.

**D12.6 — Deployment pulled forward; Render free tier (2026-06-22)**
Stage 4 deployment is done right after Stage 1 (not last) so a physical device can reach the API without the laptop. Hosting: **Render free web service** — chosen over a free VM because Render needs **no credit card** (the developer will not put financial info on a portfolio project), deploys straight from the GitHub repo, and auto-redeploys on push. Render free spins down after ~15 min idle; the cold start (which previously failed a live demo) is defeated with a **keep-warm pinger** (cron-job.org / UptimeRobot hitting the unauthenticated `/health` every ~10 min) — fits within Render's 750 free instance-hours/month for one service. Auth: a single static `API_KEY` in the `X-API-Key` header when `DEV_MODE=false`; the Flutter app supplies `API_BASE_URL` + `API_KEY` via `--dart-define` so neither is committed. Config: `render.yaml` Blueprint (secrets `sync:false`). Runbook: `modunote-api/DEPLOY.md`. *(Superseded mid-session: an earlier GCP-VM + Tailscale-Funnel plan was dropped because GCP/Oracle require card verification.)*

**D12.7 — Stage 2 RAG concretes (2026-06-27): hosted Jina embeddings, Supabase pgvector, tag-gated sync, Home-card QnA entry**
Four Stage 2 open items (flagged in `PHASE_12_PLAN.md`) resolved with the developer before coding:
- **Embeddings: hosted API — Jina AI `jina-embeddings-v2-base-en` (768-dim).** *Supersedes* the plan's default of local `sentence-transformers` (`all-MiniLM-L6-v2`, 384-dim). Reason: the Render free web service has ~512 MB RAM and `sentence-transformers` drags in PyTorch (~500 MB+ resident) — a realistic OOM/cold-build risk that would take the deployed portfolio demo down. A hosted embedder keeps the dyno tiny. Jina chosen over Google `text-embedding-004` because Google reuses the same Gemini free tier that previously blocked testing (see D12.2); chosen over Voyage/Cohere as a no-credit-card, generous free tier with a recognisable name. The embedding call goes out over HTTP from the FastAPI process (`httpx`); Supabase is only the vector store, not the embedder. **The 768 dimension is now load-bearing** — it fixes the `chunks.embedding vector(768)` column; changing providers later means re-indexing.
- **Vector store: Supabase Postgres + `pgvector`.** *Supersedes* the implicit "existing/Render Postgres." Reason: Render's free Postgres is deleted after ~30 days (kills a portfolio demo); Supabase free Postgres is persistent, has `pgvector` available, and gives a SQL dashboard. The app connects to Supabase via `DATABASE_URL` (separate from the Render web service). One database only — no Chroma/second store (anti-drift guardrail upheld).
- **Sync triggers: plan default, now user-editable.** Indexable = a note carrying any trigger tag. Index (upsert) on the existing save-close hook; deindex when a note loses all trigger tags or is deleted. The default set is `{study, notes, research}` (`AppConstants.ragIndexTags`), but the **live set is user-editable from Settings** and persisted in SharedPreferences (`RagIndexTags` notifier, key `rag_index_tags`) — added 2026-06-27 at the developer's request ("modify the RAG scope from inside the app"). The note editor's `_scheduleRagSync` reads the live set, not the constant. Note: the backend `/index/notes` does not filter by tag (it indexes whatever Flutter sends), so the tag gate is purely client-side and changing it needs no redeploy. Caveat: changing the set only affects notes as they are next opened+closed (no bulk re-index yet).
  - **Refinement (decided + done 2026-06-27, S2-F9):** the Settings scope picker only lets the user select from **tags that already exist** on their notes — no free-text/new-tag creation. Reason: a trigger tag matching no real tag can never index anything, so free-text entry is a footgun; tying scope to actual tags keeps it meaningful. UI is a bottom-sheet picker (`_TagPickerSheet`) over `tagListViewModelProvider` (minus already-selected); the persisted-set storage and `_scheduleRagSync` matching are unchanged. `RagIndexTags.addTag` still normalises (input is already a real lowercase tag name).
- **Embeddings transport: force IPv4 (2026-06-27).** `services/embedding_service.py` builds the `httpx.AsyncClient` with `AsyncHTTPTransport(local_address="0.0.0.0")`. Reason: Render's free tier has no IPv6 egress, so the Jina HTTPS call failed with `[Errno 101] Network is unreachable`; binding the socket to IPv4 fixes it (mirrors what the Groq SDK does internally).
- **Bulk re-index + app-wide toasts (2026-06-27, S2-F10).** Added `RagReindex` (`@riverpod`) to re-index all active notes whose tags are in the scope set, surfaced via a "Re-index all notes now" button in the Settings scope card (so the user needn't reopen each note after changing scope or fixing connectivity). Background sync feedback uses the **`toastification`** package with a global `rootNavigatorKey` (in `core/utils/app_toast.dart`, passed to GoRouter; app wrapped in `ToastificationWrapper`) — chosen so a *background* op (which has no live screen `BuildContext`) can show a toast over whatever screen is visible. `core/utils/app_toast.dart` imports only flutter + toastification + `core/theme` (no presentation dependency). UX decision: the auto on-close indexer toasts **only on index failure** (deindex/cleanup failures stay silent, so closing untagged notes never toasts); the explicit re-index button shows a success/fail/none summary.
- **QnA nav: Home-screen card** (not a 5th nav tab). Reason: the 4-tab floating pill + center FAB is already full; a prominent "Ask your notes" card on Home keeps the nav uncluttered while staying discoverable. The dedicated `/qna` route + `QnaScreen` are unchanged from the locked plan.
- **Supabase TLS: encrypted-but-unverified** (added 2026-06-27 during S2-B8). `db/session.py` and `alembic/env.py` `_connect_args()` build an SSL context with `check_hostname=False` + `verify_mode=CERT_NONE` for non-local hosts. Reason: connecting to Supabase with a verifying context fails with `SSL: CERTIFICATE_VERIFY_FAILED — self-signed certificate in certificate chain` (the managed cert chain and/or a local TLS-intercepting AV/proxy). Traffic remains encrypted; verification is skipped. Acceptable for a single-user app; revisit if multi-tenant. (The proper alternative is bundling Supabase's CA cert via `load_verify_locations`, deferred as unnecessary here.)

### The 4-Stage Roadmap

**Stage 1 — Writing assistant** (the first feature)
- *Backend*: `services/ai_service.py` (new) calls Groq; expose actions under the note endpoints (extend the existing `tags/suggest` + `summary` stubs, or add `/api/v1/notes/{id}/assist`). The first Alembic migration is generated here (`alembic revision --autogenerate`).
- *Actions* — a fixed menu, each a prompt template (NOT an autonomous agent): **Improve**, **Humanize**, **Paraphrase**, **Format-as-script**, **Critique**. The note's tags are passed as context so advice adapts (e.g. `#youtube` vs `#instagram`).
- *Flutter*: `RemoteNoteService` gets real calls (remove the 501 stubs); results shown in a suggestion/diff UI with accept-or-dismiss. The original auto-tagging (suggested-tags banner) and summarisation (blockquote insert at top of the Quill doc) fold in here as two of the actions.

**Stage 2 — RAG QnA backend** *(embeddings + host concretes resolved in D12.7)*
- For notes tagged study/notes/research: chunk → embed (**hosted Jina `jina-embeddings-v2-base-en`, 768-dim** — see D12.7; not local `sentence-transformers`) → store in **pgvector on Supabase** (add the extension; do NOT introduce Chroma; one database is simpler and production-credible) → top-k similarity retrieval → Groq answers **with citations**.
- *New design dependency*: notes are currently local-first and only *written* to Firestore — the backend never sees note text. Stage 2's first task is a sync extension that pushes plain-text content of selected (study/notes-tagged) notes to the backend for indexing.

**Stage 3 — Observability & evals**
- **Langfuse** (trace every LLM call: prompt / tokens / latency / cost), **Sentry** (FastAPI error monitoring — add early, it's ~5 lines), **RAGAS / LLM-as-judge** (faithfulness + relevance scoring of RAG answers), and **light guardrails** (start with Pydantic validation + basic input/output checks before reaching for a framework like Guardrails AI / NeMo).

**Stage 4 — Production deployment** (scope = "deploy," NOT "billed SaaS")
- Small VM (Hetzner / DigitalOcean / Fly.io) + **Caddy** reverse proxy (automatic HTTPS/TLS) + Docker Compose + **GitHub Actions** CI/CD + monitoring (Langfuse + Sentry + an uptime check). Multi-tenancy and billing are explicitly out of scope unless the developer later chooses to productise — that is a separate, much larger effort.

### Superseded (kept for history)
- *Old D12.2* ("two AI features in scope: auto-tagging + summarisation") → folded into **Stage 1**; the roadmap expanded to 4 stages.
- *Old D12.3 / PD-02* ("AI provider pending — Gemini vs Groq") → **Resolved: Groq** (Gemini tried first, then dropped — see D12.2).
- *Old D12.5* ("all AI logic lives in the backend service layer; Flutter never calls a provider directly") → retained and reaffirmed as the new **D12.3**.

---

## Design System Decisions

All values sourced from `MODUNOTE_UI_REFERENCE.md`. These are non-negotiable — never override with ad-hoc color or font values inline in widget code. Always use `AppColors` constants or `AppTypography` helpers.

**DS.1 — Seed color: `#5B4EFF` (indigo-violet)**
This is the Material 3 seed for `ColorScheme.fromSeed`. It generates the full color scheme. The seed is never used directly as a widget color — always use the derived scheme tokens.

**DS.2 — Accent color: `#F59E0B` (warm amber)**
Used for: FAB background, blockquote left border, category picker "New category" button, pin indicator. This color is the same in both light and dark mode — it does not change with the seed. Always reference `AppColors.accent`.

**DS.3 — Recording red: `#E5484D` (light) / `#FF6369` (dark)**
Used only for: recording indicator, waveform fill, danger rows in settings. Never use for general error states — use `colorScheme.error` for that. The slightly lighter dark-mode variant is intentional.

**DS.4 — Typography rule: no hardcoded font sizes in widget files**
All text styles must use `AppTypography.plusJakartaSans(...)` or `AppTypography.inter(...)` helpers, or reference `Theme.of(context).textTheme` entries. Never write `TextStyle(fontSize: 16)` directly in a widget — always go through the helpers.

**DS.5 — Border radius values are fixed per component type**
- Note cards: `borderRadius: 20`
- Bottom nav bar: `borderRadius: 32`
- FAB: `borderRadius: 18`
- Chips (sm): `borderRadius: 999` (fully round)
- Chips (md): `borderRadius: 999`
- Bottom sheets: `borderTopLeftRadius: 28, borderTopRightRadius: 28`
- Toolbar buttons: `borderRadius: 10`
- Category tree rows: `borderRadius: 14`

Never deviate from these values. They are pixel-specified in the design system.

---

## Known Bugs & Pitfalls Log

| ID | Description | Phase | Status | Resolution |
|---|---|---|---|---|
| BUG-01 | `Undefined name 'themeModeNotifierProvider'` — `app_router.g.dart` stub missing `themeModeProvider` block. Missing symbol in `part` file breaks entire part. | 1 | ✅ Fixed | Added `themeModeProvider` block + `_$ThemeModeNotifier` abstract class to stub |
| BUG-02 | Companion class names wrong across all DAOs and local repos — used `NoteRowCompanion`, `TagRowCompanion`, etc. Drift names companions after the TABLE class, not the data class. | 2 | ✅ Fixed | Renamed to `NotesTableCompanion`, `TagsTableCompanion`, `NoteTagsTableCompanion`, `CategoriesTableCompanion`, `AudioRecordsTableCompanion` throughout all 7 affected files |
| BUG-03 | `DatabaseException` called with non-existent params `originalError:` and `stackTrace:` in all three local repos — the constructor only accepts `(String message, {Object? cause})`. | 2 | ✅ Fixed | Replaced all callsites with `DatabaseException(message, cause: e)` |
| BUG-04 | Wrong import paths in local repos — `'../datasources/local/…'` resolves to non-existent `lib/data/repositories/datasources/` | 2 | ✅ Fixed | Corrected to `'../../datasources/local/…'` |
| BUG-05 | `local_tag_repository.dart` imported `string_extensions` from `core/utils/` — file lives at `core/extensions/` | 2 | ✅ Fixed | Fixed import directly; added `core/utils/string_extensions.dart` re-export shim so both paths work |
| BUG-06 | `ITagRepository` and `ICategoryRepository` method signatures mismatched their implementations (`addToNote` vs `addTagToNote`, nullable vs non-nullable `findChildren`, missing `findRoots`, `updateSortOrder`) | 2 | ✅ Fixed | Rewrote both interfaces to exactly match implementations |
| BUG-07 | `intl` version conflict — `flutter_quill ^10.8.5` requires `intl ^0.19.0` but Flutter SDK pins `intl 0.20.2` | 2 | ✅ Fixed | Added `dependency_overrides: intl: '>=0.19.0 <0.21.0'` to `pubspec.yaml` |
| BUG-08 | `custom_lint ^0.6.4` incompatible with `riverpod_generator ^2.4.3` — `flutter pub get` failed | 2 | ✅ Fixed | Bumped `custom_lint` to `^0.7.6` and `riverpod_lint` to `^2.4.0` in `pubspec.yaml` |
| BUG-09 | D3.5 in DECISIONS.md listed `searchViewModelProvider` as `AsyncNotifier<List<Note>>` — wrong. `Notifier<SearchState>` is needed to co-locate query + async results for debounced search UX. | 3 | ✅ Fixed | Confirmed by developer before Phase 3 implementation. D3.5 corrected in place. `SearchState` holds `query: String` + `results: AsyncValue<List<Note>>`. |
| BUG-10 | `overridden_fields` + `annotate_overrides` on 4 DAO fields in `AppDatabase` — redeclared `notesDao`, `tagsDao`, `categoriesDao`, `audioRecordsDao` as `late final` fields, shadowing the same concrete `late final` fields already generated in `_$AppDatabase`. Dart cannot override a concrete field with another concrete field; adding `@override` suppressed one lint but not the other. | 3 | ✅ Fixed | Removed all 4 DAO field declarations from `AppDatabase`. They are inherited from `_$AppDatabase` which already initialises them correctly with `this as AppDatabase`. |
| BUG-11 | 20 `info`-level lint issues post-Phase-3: `unnecessary_import` in 7 files (DAO table imports redundant because `app_database.dart` re-exports all tables and DAOs; DAO imports in local repos redundant for same reason; `flutter_riverpod` in `search_view_model.dart` re-exported by `riverpod_annotation`). Also `use_super_parameters` on `AppDatabase` constructor and `prefer_const_declarations` on `UuidGenerator._uuid`. | 3 | ✅ Fixed | Removed 11 redundant imports across `notes_dao.dart`, `tags_dao.dart`, `audio_records_dao.dart`, `categories_dao.dart`, `local_note_repository.dart`, `local_tag_repository.dart`, `local_category_repository.dart`, `search_view_model.dart`. Applied `super.e` constructor syntax in `AppDatabase`. Changed `static final _uuid = const Uuid()` to `static const _uuid = Uuid()`. `flutter analyze` now reports 0 issues. |
| BUG-12 | 2 `prefer_const_constructors` lint warnings during Phase 4 NoteListScreen implementation. | 4 | ✅ Fixed | Applied `const` to the affected widget constructors during implementation. `flutter analyze` 0 issues. |
| BUG-13 | `speech_to_text` v7 cannot transcribe audio files — original D6.4 architecture assumed file-based transcription ("STT runs after recording stops using the recorded file path"). This is not a code bug but a capability misunderstanding: `speech_to_text` v7 only performs live microphone recognition; it has no file transcription API. Running `recognize(audioFilePath)` is not supported. Discovered during Phase 6 planning. | 6 | ✅ Resolved | Architecture revised to simultaneous live STT + flutter_sound recording (confirmed by developer). D6.4 updated in DECISIONS.md. **Pitfall for future phases**: never assume `speech_to_text` can transcribe an audio file. If file-based transcription is ever needed, a separate backend endpoint (Whisper or Google STT API) is required. |
| BUG-14 | Android STT engine silently stops recognising after ~7 seconds of silence and fires a `'notListening'` status event. Without recovery, long recordings would truncate the transcript mid-sentence. Not documented in the `speech_to_text` package README. | 6 | ✅ Fixed | Added `_onStatus` callback to `SpeechToTextService` that detects `'notListening'` while `_active == true` and restarts `_stt.listen()` after a 200 ms delay. This transparent restart is documented as D6.7. |
| BUG-15 | `flutter analyze` post-Phase-6: `unnecessary_import` in `local_audio_record_repository.dart` — `import '../../datasources/local/daos/audio_records_dao.dart'` was redundant because `app_database.dart` already re-exports `AudioRecordsDao`. | 6 | ✅ Fixed | Removed the redundant import. Consistent with Phase 3 cleanup that removed all direct DAO imports from local repos (BUG-11). `app_database.dart` is the single import point for all Drift DAOs and tables. |
| BUG-16 | `flutter analyze` post-Phase-6: `deprecated_member_use` in `speech_to_text_service.dart` — `listenMode` and `cancelOnError` passed as direct params to `_stt.listen()` were deprecated in `speech_to_text ^7.0.0`. The new API wraps them in `SpeechListenOptions`. `pauseFor` is not deprecated and stays as a direct param. | 6 | ✅ Fixed | Replaced `listenMode: ListenMode.dictation, cancelOnError: false` with `listenOptions: SpeechListenOptions(listenMode: ListenMode.dictation, cancelOnError: false)`. `SpeechListenOptions` is re-exported from `package:speech_to_text/speech_to_text.dart` — no new import required. |
| BUG-17 | `flutter analyze` post-Phase-6: `prefer_const_constructors` in `audio_recording_service.dart` — `throw FileStorageException(...)` in `_assertInitialized()` was missing `const`. `FileStorageException` has a `const` constructor (`const FileStorageException(super.message, {super.cause})`). | 6 | ✅ Fixed | Changed `throw FileStorageException(...)` to `throw const FileStorageException(...)`. |
| BUG-18 | Phase 8: `_onCategoryTap` used `noteEditorViewModelProvider(_currentNote!.id)` (positional arg) — wrong. The provider is a family with a **named** `noteId:` parameter; `@riverpod` code-gen always uses named params for family providers. Positional call triggers `extra_positional_arguments_could_be_named` at analysis time. | 8 | ✅ Fixed | Changed to `noteEditorViewModelProvider(noteId: widget.noteId)` — consistent with every other call site in the file. |
| BUG-19 | GitHub issue #1: `_AudioClipsRowState._togglePlayback` silently failed on existing notes — `AudioRecordingService.startPlayback` calls `_assertInitialized()` which throws `FileStorageException` if `init()` has never been called. On a freshly-opened note (no mic tap), the service was never initialised, so playback produced no audio and no error UI. | 7 | ✅ Fixed (pre-Phase-8 commit) | Added `initState()` to `_AudioClipsRowState` that calls `widget.audioService.init().ignore()` eagerly. `init()` is already idempotent (`if (_initialized) return`), so this is safe to call unconditionally. |
| BUG-20 | GitHub issue #2: Loading an existing note with rich-text formatting (lists, checkboxes) silently erased the formatting. Root cause: `_initControllers` cast `note.content['ops']` with a bare `as List` and wrapped `Document.fromJson` in `catch (_) { doc = Document(); }`. A type mismatch (`List<dynamic>` vs `List<Map<String,dynamic>>`) triggered the catch, returning a blank document — no error was ever surfaced to the developer. | 5 | ✅ Fixed (pre-Phase-8 commit) | Replaced bare cast with `.map((op) => Map<String,dynamic>.from(op as Map)).toList()`. Changed silent catch to `catch (e, st) { debugPrint('NoteEditor: failed to deserialize content: $e\n$st'); doc = Document(); }` so failures are visible in the log. |
| BUG-21 | GitHub issue #3: Bottom nav tabs on `TagsScreen` did nothing when tapped — `_NavTab` had no `onTap` parameter and the `GestureDetector` wrapper was missing entirely. All tab buttons were inert. Discovered after Phase 7 committed `TagsScreen` with a copy of the Phase 4 `_BottomNav` that was never wired up. | 7 | ✅ Fixed (pre-Phase-8 commit) | Added `onTap: VoidCallback` and `activeIcon: IconData` to `_NavTab`; wrapped each tab in a `GestureDetector`; wired Home → `context.go(AppRoutes.home)`, Explore → `AppRoutes.search`, Tags → no-op (already active), Settings → `AppRoutes.settings`. Added `go_router` and `app_router` imports to `tags_screen.dart`. |
| BUG-22 | Phase 8: `_selectedCategoryName()` fallback used `const Category(id: '', name: 'root', sortOrder: 0, createdAt: null)`. But `Category.createdAt` is declared `required DateTime createdAt` (non-nullable) — passing `null` is a compile error. Caught immediately when verifying the `Category` model before `flutter analyze` would have caught it. | 8 | ✅ Fixed | Rewrote `_selectedCategoryName()` to use `.where((c) => c.id == _selectedId)` and check `.isEmpty` — no fallback `Category` object needed. |
| BUG-23 | Phase 9: `sort_child_properties_last` lint error in `app_router.dart` ShellRoute builder. Initial call was `_AppShell(child: child, location: state.uri.path)` — Flutter lint requires `child:` to be the last named parameter. Flagged by `flutter analyze` (1 issue). | 9 | ✅ Fixed | Reordered to `_AppShell(location: state.uri.path, child: child)`. Rule applies to all widget constructors — `child:` and `children:` must always be last. |
| BUG-24 | Post-Phase-9: `BottomBarThemeData` v2.0.0 has no `iconData` or `iconColor` fields. Initial implementation tried to use `BottomBarThemeData(iconData: ..., iconColor: ...)` to customise the scroll-to-top icon. Both fields are undefined — `flutter analyze` reported 2 errors. | 9 | ✅ Fixed | Removed `iconData`/`iconColor` from `BottomBarThemeData`. Used `icon: (w, h) => Icon(...)` builder parameter directly on `BottomBar` for icon customisation. Styled `iconDecoration` (background) via `BottomBarThemeData.iconDecoration` (which does exist). |
| BUG-25 | Selecting a parent category on the home screen showed only notes assigned to that exact category, not its descendants — hierarchical filtering was missing. `NotesDao.watchByCategory` used `categoryId.equals(id)`. | 11.6 | ✅ Fixed | Added `watchByCategoryIds(isIn(ids))` through DAO → interface → all 3 impls; `NoteListViewModel._collectDescendants()` resolves the subtree (D11.6a). |
| BUG-26 | Tapping a tag/category filter that matched zero notes made the entire filter chip tray disappear — the screen fell through to `_EmptyState` (no chips). | 11.6 | ✅ Fixed | Gated `_EmptyState` on `NoteFilterType.all`; added `_FilteredEmptyState` that keeps the chip bar + shows "No notes in X" (D11.6b). |
| BUG-27 | Choosing a category in the note editor did not visibly update until the editor was closed and reopened — `_currentNote` stayed stale after `setCategory()`. | 11.6 | ✅ Fixed | Added `_syncCurrentNote()` after `setCategory()` in `_onCategoryTap` (D11.6c). |
| BUG-28 | The editor tag picker only allowed creating new tags — existing tags were never listed, so the user couldn't reuse them. | 11.6 | ✅ Fixed | `_TagInputSheet` now watches `tagListViewModelProvider` and lists all not-yet-applied tags when the field is empty (D11.6d). |

---

## Pending Decisions Index

| ID | Decision | Phase to resolve | Options |
|---|---|---|---|
| PD-01 | Category deletion policy when children exist | 8 ✅ Resolved | **Re-parent children to grandparent** (cascade rejected — see D8.4) |
| PD-02 | AI provider selection | 12 ✅ Resolved | **Groq** (chat) — generous/fast free tier; Gemini tried first but its free tier blocked testing. Stage 2 embeddings via local sentence-transformers. See D12.2 |

---

## How to Update This File

- When a **pending decision is resolved**: Find the PD entry in the Pending Decisions Index, mark it resolved, add `✅ Resolved: [chosen option]`, and update the relevant Phase section with the final decision under a `D{phase}.{n}` heading.
- When a **new decision is made during implementation**: Add it to the relevant Phase section as the next `D{phase}.{n}` entry with full rationale.
- When a **bug is found and fixed**: Add it to the Known Bugs & Pitfalls Log with resolution.
- **Never delete old entries** — even superseded decisions are kept with a note explaining why they changed.
