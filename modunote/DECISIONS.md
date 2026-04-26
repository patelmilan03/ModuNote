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
> and `progress.md` (phase-by-phase file log). All three together form complete context.

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
11. **Claude (or any AI agent) must never run `git` commands or commit code** — all commits are made exclusively by the developer using GitHub Desktop. Never run `git add`, `git commit`, `git push`, `git reset`, or any other git command that changes repository state. Code changes are written to disk only; the developer handles all version control.

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

**D2.8 — All three repository providers are `keepAlive: true`**
`noteRepositoryProvider`, `tagRepositoryProvider`, and `categoryRepositoryProvider` are all `keepAlive: true`. Repositories are stateless wrappers — they are cheap to construct but there is no reason to reconstruct them. Keeping them alive avoids re-subscription of any active streams.

**D2.9 — `QuillDeltaConverter` serialises content as JSON string**
`Note.content` (a `Map<String, dynamic>` Delta document) is stored in SQLite as a JSON string via `QuillDeltaConverter`. On read, it is deserialised back to `Map<String, dynamic>`. This is straightforward and Firebase-compatible (Firestore can store maps natively). The converter lives in `lib/data/datasources/local/converters/type_converters.dart`.

**D2.10 — `SyncStatus` stored as string in SQLite**
`SyncStatus` enum values are stored as their string names (`'local'`, `'pending'`, `'synced'`, `'conflict'`) via a custom `TypeConverter`. Never store enums as integers — string values are readable in SQLite browser tools and safe across enum reordering.

**D2.11 — `MigrationStrategy` declared from day one**
`AppDatabase` declares a `MigrationStrategy` with `onCreate` and `onUpgrade` stubs. `schemaVersion` starts at `1`. Future phases that add columns must increment `schemaVersion` and add a migration step. Never change an existing table without a migration.

---

## Phase 3 — State Management ⬜ Not Started

### Pre-Decided Architecture

**D3.1 — ViewModel pattern: `AsyncNotifier` for async data, `Notifier` for sync state**
Screens that load data from the repository use `AsyncNotifier<T>`. Screens with purely local UI state (e.g. a toggle) use `Notifier<T>`. Never use `StateNotifier` (deprecated in Riverpod 2). Never use `StateProvider` (too simple, not composable).

**D3.2 — One ViewModel per screen**
Each screen gets exactly one ViewModel file in `lib/presentation/viewmodels/`. The ViewModel exposes the minimum state the screen needs. Cross-screen state (e.g. the currently selected category) is shared via a separate top-level provider, not by sharing ViewModel instances.

**D3.3 — ViewModels watch repository streams via `ref.watch`**
`AsyncNotifier` ViewModels call `ref.watch(noteRepositoryProvider).watchAll()` and convert the resulting `Stream` to `AsyncValue` using `ref.listen` or `stream` pattern. Never manually subscribe to streams with `.listen()` inside a ViewModel — use Riverpod's stream-to-AsyncValue conversion.

**D3.4 — Error handling in ViewModels: `AsyncError` state**
When a repository call throws an `AppException`, the ViewModel catches it and sets state to `AsyncError(e, stackTrace)`. Never swallow exceptions silently. The view layer reads `AsyncValue.when(error: ...)` to show error UI.

**D3.5 — Providers to build in Phase 3**
- `noteListViewModelProvider` — `AsyncNotifier<List<Note>>`, watches `INoteRepository.watchAll()`
- `noteEditorViewModelProvider` — `AsyncNotifier<Note?>`, parameterised by optional noteId
- `tagListViewModelProvider` — `AsyncNotifier<List<Tag>>`, watches `ITagRepository.watchAll()`
- `categoryListViewModelProvider` — `AsyncNotifier<List<Category>>`, watches `ICategoryRepository.watchAll()`
- `searchViewModelProvider` — `AsyncNotifier<List<Note>>`, calls `INoteRepository.search(query)`

---

## Phase 4 — Note List Screen ⬜ Not Started

### Pre-Decided Architecture

**D4.1 — Screen is `ConsumerWidget`, uses `noteListViewModelProvider`**
`NoteListScreen` watches `noteListViewModelProvider` and renders `AsyncValue.when(data, loading, error)`. The loading state shows a shimmer skeleton. The error state shows a retry button.

**D4.2 — Two-section list: Pinned then Recent**
The note list is divided into two sections by a `SliverStickyHeader` or manual `SliverList` with section dividers. Pinned notes appear first under a "Pinned" label, then all other notes under "Recent". The sort within each section is `updatedAt` descending.

**D4.3 — Note card widget: `MNNoteCard`**
Each note is rendered by a reusable `MNNoteCard` widget in `lib/presentation/widgets/mn_note_card.dart`. It receives a `Note` object and an `onTap` callback. It never reads from a provider directly — it is purely presentational. Spec: see `MODUNOTE_UI_REFERENCE.md § 2.3`.

**D4.4 — Archived notes are never shown on the home screen**
`INoteRepository.watchAll()` filters out `isArchived == true`. There is no archive screen in the current scope — archived notes are soft-deleted from the user's perspective until a future phase adds a trash/archive view.

**D4.5 — FAB navigates to `/note/new`**
The amber FAB calls `context.push(AppRoutes.newNote)`. It is positioned per the UI reference: `bottom: 96, right: 20` to clear the floating bottom nav bar.

**D4.6 — Search bar navigates to `/search`**
Tapping the `MNSearchField` on the home screen pushes `/search` using `context.push(AppRoutes.search)`. It does not expand inline — it is a navigation affordance, not an inline search. Inline search lives on the Explore screen.

---

## Phase 5 — Note Editor Screen ⬜ Not Started

### Pre-Decided Architecture

**D5.1 — Editor uses `flutter_quill` v10 with `QuillController`**
The `QuillController` is owned by the `NoteEditorViewModel` (or initialised in the screen with a `ConsumerStatefulWidget`). It is initialised from `Note.content` (Delta JSON map) on load. On every change, the controller's document is serialised back to Delta JSON and the ViewModel's save-debounce timer is reset.

**D5.2 — Auto-save with 800ms debounce**
The editor auto-saves after 800ms of inactivity. It does not save on every keystroke. The "Saved" status badge in the app bar reflects the save state: writing → a neutral dot, saved → green dot + "Saved". This is implemented with a `Timer` in the ViewModel, cancelled and restarted on each document change.

**D5.3 — Title is an inline editable `TextField` in the app bar**
The note title is not in the Quill document — it is a separate `TextField` styled to look like an app bar title (Plus Jakarta Sans, 17px, weight 700). It saves with the same debounce as the body.

**D5.4 — Format toolbar is pinned above the keyboard**
`MNEditorToolbar` is positioned using Flutter's `Scaffold.bottomSheet` or a `Column` with `Expanded` + `resizeToAvoidBottomInset: true`. It must always appear directly above the keyboard, not float freely. It contains 9 tools: bold, italic, underline, H1, H2, bullet list, numbered list, checklist, blockquote.

**D5.5 — `NoteEditorScreen` accepts optional `noteId`**
If `noteId` is null, the editor creates a new note. If `noteId` is provided (from `/note/:id`), the editor loads the existing note. New notes are saved to the DB immediately on first keystroke (not on back navigation) so they always have a valid ID.

**D5.6 — Quill Delta content is never stored as a Flutter-specific format**
The Delta JSON stored in SQLite is the standard Quill Delta format — not a Flutter-specific binary. This ensures the content can be rendered by the FastAPI backend (Phase 11) or any future web front-end without conversion.

---

## Phase 6 — Voice-to-Text + Audio ⬜ Not Started

### Pre-Decided Architecture

**D6.1 — Audio format: AAC, 32kbps, mono, 16kHz**
This is fixed. It gives ~0.24 MB/min, adequate quality for voice, and broad playback compatibility. Never change codec, bitrate, channel count, or sample rate without updating `AppConstants` and the audio spec documentation.

**D6.2 — Audio files stored under `getApplicationDocumentsDirectory()/audio_notes/`**
The subdirectory name is `AppConstants.audioSubDir = 'audio_notes'`. Files are named `{uuid}.aac`. The `AudioFileStorage` class in `lib/data/datasources/file/audio_file_storage.dart` handles all file I/O. DAOs never touch the file system — they only store the `filePath` string.

**D6.3 — `AudioRecordingService` streams amplitude for waveform**
`flutter_sound`'s recorder exposes a `Stream<RecordingDisposition>` with decibel level. `AudioRecordingService` maps this to a normalised `Stream<double>` (0.0–1.0) that the UI uses to render the waveform bar heights. Never compute waveform in the UI layer.

**D6.4 — Speech-to-text runs after recording stops, not in real-time**
`SpeechToTextService` is called with the recorded file path after recording ends. It transcribes the audio and the result is saved to `AudioRecord.transcribedText` and also inserted into the Quill document at the cursor position. Real-time streaming STT is not implemented in this phase.

**D6.5 — Microphone permission handled by `PermissionException`**
Before recording, the app checks microphone permission. If denied, it throws `PermissionException` which the ViewModel catches and surfaces as an error state. Never silently fail on permission denial.

**D6.6 — `AudioRecord` is linked to a note via `noteId`**
One note can have multiple `AudioRecord` entries (the user can record multiple clips). They are displayed in the tag row area of the editor. Deleting a note cascades to delete all its `AudioRecord` rows and the corresponding files on disk — handled by `AudioRecordsDao.deleteAllForNote` + `AudioFileStorage.deleteFile`.

---

## Phase 7 — Tags ⬜ Not Started

### Pre-Decided Architecture

**D7.1 — Tag entry: freeform with live autocomplete**
The tag input in the note editor is a `TextField` that shows a dropdown of existing tags matching the current prefix (via `ITagRepository.searchByPrefix`). Selecting a suggestion assigns the existing tag. Pressing enter/comma/space with no match creates a new tag. This is the standard "chip input" UX pattern.

**D7.2 — Tag names are normalised on every write**
Before inserting a new tag or matching an existing one, the input is always passed through `StringExtensions.normalised` (`.toLowerCase().trim()`). The DB unique constraint on `tags.name` is case-insensitive by design because all values are normalised before write. Never store a tag without normalising first.

**D7.3 — Tags screen shows density bars**
Each tag row on the Tags screen shows a proportional density bar: width = `(tagNoteCount / maxNoteCount) * 100%`. The max is computed across all tags in the current list. This is a pure UI computation in the ViewModel — not stored in the DB.

**D7.4 — Tag deletion cascades from UI only**
Deleting a tag from the Tags screen calls `ITagRepository.delete(id)`. The `TagsDao` removes the tag from `tags`, removes all rows in `note_tags` for that tag, and syncs `tagIds` on affected notes via `_syncDenormalisedTagIds`. This is done inside a Drift transaction.

**D7.5 — Maximum 20 tags per note**
`AppConstants.maxTagsPerNote = 20`. The tag input is disabled once a note has 20 tags. The ViewModel enforces this before calling the repository.

---

## Phase 8 — Categories ⬜ Not Started

### Pre-Decided Architecture

**D8.1 — Category structure: adjacency list, max depth 5**
Categories are stored as a flat list with a nullable `parentId` (adjacency list pattern). Building the tree for display is done in the ViewModel by recursively grouping by `parentId`. Max nesting depth is `AppConstants.maxCategoryDepth = 5`. The ViewModel enforces this when creating a new category — it checks the depth of the target parent before inserting.

**D8.2 — One note belongs to zero or one category**
`Note.categoryId` is nullable. A note with no category is in "Uncategorised" — this is not a real category row in the DB, just a null state displayed as a UI affordance. Never create a default "Uncategorised" category in the DB.

**D8.3 — Category picker is a bottom sheet**
Assigning a category from the note editor opens a bottom sheet (`MNCategoryPickerSheet`) showing the full tree. Spec: `MODUNOTE_UI_REFERENCE.md § 3.5`. Tree rows are indented by `paddingLeft = 10.0 + depth * 20.0`. Expand/collapse state is local to the sheet (not persisted).

**D8.4 ⚠️ PENDING: Category deletion policy**
When a category with children is deleted, the behaviour is **not yet decided**. Two options:
- **Cascade**: delete all descendants recursively and set `categoryId = null` on all affected notes.
- **Re-parent**: move all direct children up to the deleted category's parent (or root if no parent).

This decision must be made at the start of Phase 8 before writing any DAO code for `deleteCategory`. Update this file and `progress.md` when resolved.

**D8.5 — `sortOrder` on categories**
Categories have a `sortOrder: int` field for manual ordering within siblings. The default is insertion order (0, 1, 2, ...). Drag-to-reorder UI is deferred to a future version — Phase 8 only exposes alphabetical display.

---

## Phase 9 — Navigation + Theming ⬜ Not Started

### Pre-Decided Architecture

**D9.1 — GoRouter `ShellRoute` for persistent bottom nav bar**
Phase 9 refactors the GoRouter config in `app_router.dart` to wrap the four main tabs (Home, Explore, Tags, Settings) in a `ShellRoute`. The shell widget renders `MNBottomNav` persistently and swaps the child based on the current route. The Note Editor and Category Picker do not participate in the shell — they are full-screen routes pushed on top.

**D9.2 — Bottom nav bar is a custom floating pill**
`MNBottomNav` is a custom widget, not `BottomNavigationBar` or `NavigationBar` from Material. It is positioned as an absolutely-positioned overlay using a `Stack` in the shell widget. Spec: `MODUNOTE_UI_REFERENCE.md § 2.1`. It has 4 tabs: Home (index 0), Explore (index 1), Tags (index 2), Settings (index 3).

**D9.3 — Theme persistence via SharedPreferences**
`ThemeModeNotifier` (created in Phase 1) is extended in Phase 9 to read from and write to SharedPreferences using the key `AppConstants.prefThemeMode`. On app start, it reads the saved value. On toggle, it writes the new value. The persistence logic lives in the Notifier's `build()` method and `set*` methods.

**D9.4 — `ColorScheme.fromSeed` with manual overrides**
Material 3's `ColorScheme.fromSeed` is used as the base but several tokens are manually overridden to match the design spec exactly. Light mode: `surface → #FEFBFF`, `surfaceContainer → #F4F0FA`. Dark mode: `surface → #1C1B2E`, `surfaceContainer → #2A2942`. These are already set in `AppTheme` from Phase 1 — Phase 9 completes the full `NavigationBar`, `Card`, `Chip`, `FloatingActionButton`, and `BottomSheet` theme overrides.

**D9.5 — Settings screen theme toggle uses two-option card, not a Switch**
The theme toggle on the Settings screen is a two-card grid (Light / Dark), not a Switch widget. The "System" option is exposed only via a third hidden state — if the current mode is `ThemeMode.system`, neither card is highlighted. Spec: `MODUNOTE_UI_REFERENCE.md § 3.6`.

---

## Phase 10 — Firebase Preparation Layer ⬜ Not Started

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

## Phase 11 — Backend API Scaffolding ⬜ Not Started

### Pre-Decided Architecture

**D11.1 — Backend stack: FastAPI + PostgreSQL + SQLAlchemy async + Alembic**
Chosen because the developer has existing Python/FastAPI/PostgreSQL skills. This is non-negotiable — do not substitute Django, Node, or any other stack.

**D11.2 — Backend lives in a separate repository**
The FastAPI backend is a separate repo, not a subdirectory of the Flutter project. Phase 11 creates the scaffolding in a `modunote-api/` directory at the same level as `modunote/`.

**D11.3 — Phase 11 is stubs only — no deployed endpoints**
Phase 11 delivers: project structure, `main.py`, router stubs for the AI endpoints (`/api/v1/notes/{id}/tags/suggest`, `/api/v1/notes/{id}/summary`), Pydantic models, SQLAlchemy model stubs, Alembic config, and a `docker-compose.yml` for local development. No endpoint is functional until Phase 12.

**D11.4 — API is stateless, JWT-authenticated**
The API expects a JWT bearer token in the `Authorization` header. In the stub phase, auth is bypassed with a development flag. Full JWT validation is implemented when auth is enabled in post-Phase-12 work.

**D11.5 — Flutter calls the API via a `RemoteNoteService` class**
A `lib/services/remote/remote_note_service.dart` class handles all HTTP calls using `dio` or `http`. It is not a repository — it is a service. The `SyncedNoteRepository` (Phase 10) uses it for AI enrichment calls after sync. ViewModels never call the API directly.

---

## Phase 12 — AI Features ⬜ Not Started

### Pre-Decided Architecture

**D12.1 — AI features are strictly post-full-app**
No AI feature is built until Phases 1–11 are complete and the app is fully functional. This decision is final. Do not move AI features earlier under any circumstances.

**D12.2 — Two AI features in scope for Phase 12**
Priority order:
1. **Smart auto-tagging**: After a note is saved, the API analyses the content and suggests up to 5 tags. The user sees a "Suggested tags" prompt and can accept or dismiss each one.
2. **Note summarisation**: A "Summarise" action in the note editor's overflow menu sends the note to the API and inserts a summary blockquote at the top of the Quill document.

**D12.3 ⚠️ PENDING: AI provider selection**
Two candidates under evaluation:
- **Google Gemini API** (free tier: 15 requests/min, 1M tokens/day as of planning). Advantage: free, multimodal for future image notes.
- **Groq API** (free tier: fast inference on Llama/Mixtral). Advantage: very fast, good for real-time suggestions.

This decision is made at the start of Phase 12 after evaluating current free-tier limits and response quality. Update this file when resolved.

**D12.4 — AI calls are fire-and-forget from the UI perspective**
The user does not wait for AI tagging. After saving a note, the AI call is made in the background. If it succeeds, suggested tags appear as a dismissible banner. If it fails (no internet, API error), it fails silently — the note is already saved correctly. Never block the save flow on AI response.

**D12.5 — AI features are isolated in the backend service layer**
All AI logic lives in the FastAPI backend (`services/ai_service.py`). The Flutter app never calls an AI provider directly. This means the AI provider can be swapped at the backend without any Flutter code change.

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

---

## Pending Decisions Index

| ID | Decision | Phase to resolve | Options |
|---|---|---|---|
| PD-01 | Category deletion policy when children exist | 8 | Cascade delete all descendants / Re-parent children to grandparent |
| PD-02 | AI provider selection | 12 | Google Gemini free tier / Groq API |

---

## How to Update This File

- When a **pending decision is resolved**: Find the PD entry in the Pending Decisions Index, mark it resolved, add `✅ Resolved: [chosen option]`, and update the relevant Phase section with the final decision under a `D{phase}.{n}` heading.
- When a **new decision is made during implementation**: Add it to the relevant Phase section as the next `D{phase}.{n}` entry with full rationale.
- When a **bug is found and fixed**: Add it to the Known Bugs & Pitfalls Log with resolution.
- **Never delete old entries** — even superseded decisions are kept with a note explaining why they changed.
