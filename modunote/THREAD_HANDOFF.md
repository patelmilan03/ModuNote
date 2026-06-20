# ModuNote — Thread Handoff Summary
> Paste this into a new Claude conversation to continue development.

---

## Status: Phase 11.5 ✅ Complete. Phase W (Web Portfolio Preview) ✅ Complete.

Phase 11.5 (bug fixes + UX features) is fully complete. **`flutter analyze` reports 0 issues.**

Phase 10 (Firebase preparation + live sync extension) is fully complete.

**`flutterfire configure` has already been run** — `lib/firebase_options.dart` contains real credentials for project `modunote-ba654`. Firebase is active. Anonymous sign-in works. No manual Firebase setup required on this machine.

---

## Phase W — Web Portfolio Preview ✅ Complete

**Live URL**: https://modunote-ba654.web.app

Flutter Web build of ModuNote deployed to Firebase Hosting. The app renders inside a phone-frame mockup (390×844) on a styled dark-navy landing page, hosted at the URL above.

### What was built

| File | Change |
|---|---|
| `lib/data/datasources/local/app_database.dart` | `createExecutor()` — `kIsWeb` branch: web uses `driftDatabase(name:'modunote', web:DriftWebOptions(...))`, native unchanged |
| `lib/data/datasources/file/audio_file_storage.dart` | Converted to 2-line conditional export — selects `_native.dart` or `_web.dart` at compile time |
| `lib/data/datasources/file/audio_file_storage_native.dart` | New file — original implementation (dart:io, path_provider) |
| `lib/data/datasources/file/audio_file_storage_web.dart` | New file — web stub (no dart:io; throws FileStorageException for path methods) |
| `lib/presentation/views/note_editor/note_editor_screen.dart` | `_onMicTap` kIsWeb guard (snackbar + return); `_AudioClipsRow` hidden on web |
| `test/widget_test.dart` | Replaced stale Flutter counter test with `void main() {}` placeholder |
| `web/index.html` | Phone-frame landing page (dark navy, CSS phone bezel, Dynamic Island, loading overlay, tech chips, GitHub button) |
| `web/flutter_bootstrap.js` | Custom bootstrap with `hostElement: #flutter-host` to confine Flutter to phone frame div |
| `web/drift_worker.dart` | New — `WasmDatabase.workerMainForOpen()` entry point |
| `web/drift_worker.js` | New — compiled JS worker (`dart compile js -O2`) |
| `web/sqlite3.wasm` | New — 714 KB, from sqlite3-2.9.4 GitHub release |
| `firebase.json` | Added `hosting` section: public `build/web`, SPA rewrite, WASM MIME, COOP/COEP headers |
| `.firebaserc` | New — maps default → `modunote-ba654` |

### Key constraints
- **Android build unchanged** — all web changes are `kIsWeb`-gated or conditional exports; native path untouched.
- **Audio disabled on web (Stage 1)** — snackbar shown; full WebM/Opus web audio is future work.
- **COOP/COEP headers required** — for drift's SharedArrayBuffer / WASM shared memory; set globally in firebase.json.

---

## What Phase 11.5 delivered

**Bug fixes:**
- **Bug 1** — Removed dead-code condition `!widget.noteTagIds.contains(normInput)` from `_TagInputSheet.showCreate` (was comparing tag name against ID list — always false).
- **Bug 2** — Wired ⋮ button in `NoteEditorScreen` to `_onMoreTap()` + `_NoteOptionsSheet` bottom sheet (Pin/Unpin, Archive, Delete). `_CircleIconButton.onTap` made nullable; button visually muted until note is persisted.
- **Bug 3** — `NoteListScreen` note cards wrapped in `Dismissible` (swipe left = archive, swipe right = pin toggle). Long-press opens `_NoteActionsSheet` with all three actions.
- **Bug 4** — `LocalNoteRepository.insert/update` return type fixed from `Future<Note>` to `Future<void>`; `togglePin` fixed from `Future<Note?>` to `Future<void>`.
- **Bug 5** — Third "System" tile added to `_AppearanceCard` in `SettingsScreen`. Now 3 tiles: Light / Dark / System.

**UX features (S1–S5):**
- **S1** — Swipe-to-dismiss on NoteListScreen cards (`Dismissible`, springs back, Drift stream handles card removal).
- **S2** — Note options sheet from ⋮ in editor (Pin/Unpin, Archive, Delete with confirm). Archive and Delete pop the editor after action.
- **S3** — System theme tile with split light/dark mini-preview and `Icons.brightness_auto_outlined`.
- **S4** — Archive screen (`/archive` route, outside ShellRoute). Access from Settings → "Archived Notes" card. Swipe right = restore, swipe left = delete (with confirm). Empty state.
- **S5** — Category/tag filter chip bar below search field on NoteListScreen. `NoteFilterNotifier @riverpod` Notifier holds filter state. `NoteListViewModel.build()` watches filter and switches between `watchAll()`, `watchByCategory()`, `watchByTag()`.

**Data layer additions:**
- `INoteRepository` — `watchArchived()` + `unarchive()` added to interface.
- All three impls (Local, Firebase, Synced) fully implement the new methods.
- `NoteEditorViewModel` — `togglePin()`, `archive()`, `delete()` methods added.

**New files:**
- `lib/presentation/viewmodels/archived_notes_view_model.dart`
- `lib/presentation/views/archive/archived_notes_screen.dart`

**Build:** `dart run build_runner build --delete-conflicting-outputs` — 99 outputs. `flutter analyze` — 0 issues.

**DB schema is version 2** — FTS5 triggers were corrected and a migration runs automatically on first app launch after updating. The FTS index is rebuilt during migration. No data loss.

**What Phase 10 extension (live Firebase sync) delivered:**
- **`.gitignore` secured**: added `google-services.json`, `android/app/google-services.json`, `lib/firebase_options.dart`, `session_context.md`. All sensitive Firebase config files are now gitignored before generation.
- **`firebase_auth: ^5.7.0`** added to `pubspec.yaml`. Firebase packages resolved: `firebase_core 3.15.2` + `cloud_firestore 5.6.12` + `firebase_auth 5.7.0`.
- **`lib/firebase_options.dart`** — STUB with placeholder values (gitignored). Replaced by `flutterfire configure` with real project credentials.
- **`lib/services/auth/firebase_auth_service.dart`** — singleton, `signInAnonymously()` (idempotent). Called from `main.dart` before `runApp`.
- **`lib/main.dart`** — now calls `Firebase.initializeApp()` + `FirebaseAuthService().signInAnonymously()` inside a try-catch before `runApp`. App boots normally even if Firebase fails.
- **`FirebaseNoteRepository`** fully implemented (live Firestore). Write methods (`insert`, `update`, `archive`, `delete`, `togglePin`) use Firestore upsert (`set()`). Read methods (`watchAll`, `findById`, etc.) remain `UnimplementedError` — reads stay local-only. UID fetched lazily via `FirebaseAuth.instance.currentUser?.uid`; all writes silently skip if uid is null.
- **`SyncedNoteRepository`** extended with `syncNote(noteId)` → read local → write remote → update local `syncStatus` → return new status; and `syncAllPending()` → find all non-synced notes → sync each. Removed `syncEnabled` flag and `unused_field` ignore comment — `_remote` is now actively used.
- **`syncedNoteRepositoryProvider`** added to `database_providers.dart` (typed as `SyncedNoteRepository`, not `INoteRepository`). `noteRepositoryProvider` now delegates to it via `ref.watch(syncedNoteRepositoryProvider)`.
- **`NoteEditorViewModel.syncNote(String noteId)`** — calls `syncedNoteRepositoryProvider.syncNote()`, updates ViewModel state with new `SyncStatus`, returns it.
- **`NoteEditorScreen._onBack()`** — after local save: set badge to "Syncing…", await `viewModel.syncNote()`, update badge, then pop.
- **`_SaveBadge`** extended from 2 states to 4: `isDirty=true` → "Saving…" (muted dot); `local` → "Local" (grey dot); `pending` → "Syncing…" (amber dot); `synced` → "Synced" (green dot).
- **`_AppShell`** converted from `StatelessWidget` to `ConsumerStatefulWidget` with `WidgetsBindingObserver`. On `AppLifecycleState.paused` (app background): calls `syncedNoteRepositoryProvider.syncAllPending().ignore()` (best-effort fire-and-forget).
- **`firestore.rules`** created at project root — deploy in Firebase Console → Firestore → Rules tab. Scopes all data to the anonymous UID.
- **Security scan completed**: GitHub repo clean (no credentials). All generated Firebase config files now gitignored.
- `build_runner` → 145 outputs. `flutter analyze` → 0 issues.

**What Phase 10 (stub phase) also delivered:**
- `FirebaseNoteRepository` stub (now replaced with live implementation).
- `SyncedNoteRepository` stub (now extended with sync methods).
- `firebase_core` + `cloud_firestore` packages (now joined by `firebase_auth`).

---

## Bug Fix Applied (Post-Phase 10 Extension) — BUG-FTS5

**Symptom**: Notes with heavy formatting (H1/H2/bold/italic/checkboxes/lists) had their first save succeed (INSERT — note appeared on home screen) but all subsequent auto-saves (UPDATEs) were silently rolled back. Home-screen timestamps never updated. Badge incorrectly showed "Local" even on failure.

**Root causes**:
1. FTS5 AFTER UPDATE trigger used `UPDATE notes_fts SET…` — invalid SQL for external content FTS5 tables. SQLite requires `INSERT INTO notes_fts(notes_fts,…) VALUES('delete',…)` + new INSERT. The invalid trigger caused every `UPDATE notes` to roll back.
2. `_performAutoSave` had a dead `catch (_)` block — `save()` catches `AppException` internally without rethrowing, so `_isDirty` was always reset to `false` (badge lied).

**Files changed**:
- `lib/data/datasources/local/app_database.dart` — `schemaVersion` bumped **1 → 2**; FTS5 UPDATE + DELETE triggers rewritten; `onUpgrade(from < 2)` migration drops broken triggers, recreates correct ones, runs `'rebuild'` to repair FTS index.
- `lib/presentation/viewmodels/note_editor_view_model.dart` — `debugPrint` added to save catch block.
- `lib/presentation/views/note_editor/note_editor_screen.dart` — `_performAutoSave` now reads `vmState.hasError` after `save()` and returns early on failure, keeping `_isDirty = true` so badge shows "Saving…" on failure. `debugPrint` logs failures.

**No build_runner re-run required** — no `@riverpod` annotations or Drift table structure changed.

---

## What was built (Phase 9 + post-Phase-9 refinements)

**What Phase 9 delivered:**
- **GoRouter `ShellRoute`**: `app_router.dart` rewritten with `ShellRoute` wrapping 4 tab routes. `_AppShell` private widget provides outer Scaffold + `BottomBar` (floating nav) + `MNBottomNav`. Note Editor routes remain outside the shell.
- **`MNBottomNav`**: new `lib/presentation/widgets/mn_bottom_nav.dart`. Floating pill widget, icon-only tabs (no labels), 60 px center gap for FAB notch. Active tab = `primaryContainer` bg + icon (22 dp). Uses `context.go` for tab switching.
- **`_NavFab`**: amber 52 px circle with amber glow shadow, positioned `top: -20` above the nav pill via `Positioned` in `_AppShell`'s `Stack`. Calls `context.push(AppRoutes.newNote)`. Sole entry point for new note creation — visible on all 4 shell tabs.
- **`flutter_floating_bottom_bar ^2.0.0`**: `_AppShell` uses `BottomBar` — nav hides when scrolling down, slides back on scroll up. When hidden, an amber 52 px scroll-to-top button appears (matches FAB style). No `ScrollController` wiring needed — package listens to scroll notifications from any descendant scrollable.
- **Theme persistence**: `ThemeModeNotifier` extended with `_loadPersistedMode()` (fire-and-forget from `build()`), `setLight/Dark/System()`, `_setAndPersist()`. SharedPreferences key: `AppConstants.prefThemeMode`. Package: `shared_preferences: ^2.3.0` added to `pubspec.yaml`.
- **Settings screen**: full rewrite. No Scaffold (shell provides). Appearance card with two `_ThemeTile` widgets (Light/Dark). Selected tile: 2px `primary` border + `primaryContainer`. Mini preview shows each theme's card appearance. `_RadioDot` confirms selection. System mode = neither highlighted.
- **Tab screens stripped of Scaffold/SafeArea**: `NoteListScreen`, `SearchScreen`, `TagsScreen` no longer have inner Scaffold. All per-screen `_BottomNav`/`_NavTab` classes removed.
- **`NoteListScreen` FAB removed**: old `_Fab` widget and `Stack`/`Positioned` wrapper replaced by direct `notesAsync.when(...)` return. Nav `_NavFab` is now the sole FAB.
- **SearchScreen back button**: `context.pop()` → `context.go(AppRoutes.home)` (shell tab, not pushed route).
- `flutter pub get` → `shared_preferences` + `flutter_floating_bottom_bar` + `motor` added. `build_runner` → 137 outputs. `flutter analyze` → 0 issues.

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
  Future<SyncStatus> syncNote(String noteId)    // Phase 10ext — pushes to Firestore, updates SyncStatus
}
```

Usage: `ref.watch(noteEditorViewModelProvider())` for new note,
`ref.watch(noteEditorViewModelProvider(noteId: id))` for existing.

#### `tag_list_view_model.dart`
```dart
@riverpod
class TagListViewModel extends _$TagListViewModel {
  Stream<List<Tag>> build()
  Future<Tag> insert(String name)
  Future<void> delete(String id)
}
```

#### `category_tree_view_model.dart`
```dart
@riverpod
class CategoryTreeViewModel extends _$CategoryTreeViewModel {
  Stream<List<Category>> build()
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
  Timer? _debounce;
  SearchState build()
  void setQuery(String query)   // debounced 300 ms; empty → AsyncData([]) immediately
}
```

---

## What was built (Phase 4)

Full Note List Screen.

### New files

#### `lib/presentation/widgets/`
- `mn_note_card.dart` — `MNNoteCard extends StatelessWidget`
  - Props: `Note note`, `VoidCallback onTap`, `List<String> tagNames = const []`
  - Renders: pinned tint background, pin icon (if isPinned), title (PJS 16.5/w700), 1-line preview (Inter 13.5/w400), up to 3 filled `#tag` chips
  - Private `_TagChip` widget (height 24, pill, chipBg/chipText colours)
  - `_timestamp()` → relative string ("Just now" / "Xm ago" / "Xh ago" / "Yesterday" / "Xd ago" / "MMM d" / "MMM d, yyyy")
  - `_preview()` → extracts plain text from Quill Delta `ops` list

- `mn_search_field.dart` — `MNSearchField extends StatelessWidget`
  - Props: `VoidCallback? onTap`
  - Height 48, borderRadius 16, surfaceContainer bg, 0.5px outline border
  - Placeholder: "Search notes, tags…" (Inter 14.5/w400/onSurfaceMuted)

#### `lib/presentation/views/note_list/note_list_screen.dart` (replaced)
Full `NoteListScreen extends ConsumerWidget`. Private widgets in same file:

| Widget | Type | Purpose |
|---|---|---|
| `_DataBody` | StatelessWidget | Renders app bar + search + pinned section + recent section; empty state inline |
| `_AppBarSection` | StatelessWidget | Day label (UPPERCASE) + "Your notes" (PJS 26/w800) + gradient avatar |
| `_SectionHeader` | StatelessWidget | Section label + hairline divider + optional count badge |
| `_LoadingBody` | StatelessWidget | 3 pulsing `_SkeletonBox` widgets |
| `_SkeletonBox` | StatefulWidget | AnimationController repeating pulse (opacity 0.35→0.65, 800 ms) |
| `_ErrorBody` | StatelessWidget | Error icon + message + Retry TextButton |
| `_EmptyState` | StatelessWidget | App bar + search + centred icon + "No notes yet" message |
| `_BottomNav` | StatelessWidget | Floating pill, `left: 16, right: 16, bottom: 14`, height 64 |
| `_NavTab` | StatelessWidget | AnimatedContainer pill; active = primaryContainer + label |
| `_Fab` | StatelessWidget | Amber 56×56, borderRadius 18, two-layer amber shadow |

**Key behaviours**:
- `NoteListScreen` watches `noteListViewModelProvider` + `tagListViewModelProvider`
- Builds `Map<String,String>` (tagId→tagName); passes resolved names to `MNNoteCard.tagNames`
- `Stack` → `Positioned.fill` (content) + `Positioned` (bottom nav) + `Positioned` (FAB)
- All inside `SafeArea` — positioned nav is 14px above safe-area bottom edge

---

## What was built (Phase 5)

Full Note Editor Screen.

### New / modified files

#### `lib/presentation/widgets/`
- `mn_editor_toolbar.dart` — `MNEditorToolbar extends StatefulWidget`. Props: `required QuillController controller`. Owns `controller.addListener` → `setState` so active badges update on selection changes. 9 tools: bold, italic, underline, H1 (Text label), H2 (Text label), bullet, numbered list, checklist, blockquote. Each tool: 34×34, `br 10`, active bg = `primaryContainer`, active icon = `onPrimaryContainer`, inactive = transparent + `onSurfaceVariant`. Toggle: active → `Attribute.clone(attr, null)`; inactive → `formatSelection(attr)`. Checklist active = list value `'checked'` or `'unchecked'`.
- `mn_tag_row.dart` — `MNTagRow extends StatelessWidget`. Props: `tagIds`, `allTags`, `categoryName?`, `onRemoveTag`, `onAddTagTap`, `onCategoryTap`, `onMicTap`, `isRecording`. Category chip (h30, br10), horizontal-scroll row of dismissible sm filled tag chips + `+ tag` sm outlined chip, mic button (40×40 br14; idle = primaryContainer; recording = recordRed + stop square + glow).

#### `lib/presentation/views/note_editor/note_editor_screen.dart` (replaced)
`NoteEditorScreen extends ConsumerStatefulWidget`. Key state variables:

| Variable | Type | Purpose |
|---|---|---|
| `_quillController` | `QuillController?` | Null until note data loads |
| `_titleController` | `TextEditingController` | Title field |
| `_editorFocusNode` | `FocusNode` | Quill editor focus |
| `_editorScrollController` | `ScrollController` | Quill scroll |
| `_contentSubscription` | `StreamSubscription?` | Content-change → auto-save |
| `_debounce` | `Timer?` | 800 ms auto-save |
| `_recordTimer` | `Timer?` | 1 s tick for recording |
| `_isDirty` | `bool` | Unsaved changes pending |
| `_isRecording` | `bool` | Recording overlay visible |
| `_recordSeconds` | `int` | Recording timer counter |
| `_currentNote` | `Note?` | Last saved/loaded note |
| `_controllersInitialized` | `bool` | One-shot init guard |

**Private widgets in same file**: `_EditorAppBar`, `_CircleIconButton`, `_SaveBadge`, `_RecordingOverlay`, `_WaveformBars`, `_PulsingStopButton`.

**Key behaviours**:
- `noteAsync.whenData(_initControllers)` in `build()` — one-shot controller init
- `document.changes.listen()` (not `addListener`) — fires on content changes only
- `_performAutoSave()` builds Note from local state, calls `NoteEditorViewModel.save(note)`
- `_onBack()` flushes debounce, `await _performAutoSave()`, then `context.pop()`
- `_syncCurrentNote()` called after `addTag`/`removeTag` to keep `_currentNote.tagIds` in sync
- Category chip → stub `showModalBottomSheet` ("Category picker — Phase 8")

---

## What was built (Phase 6)

Voice-to-Text + Audio Recording/Playback.

### New files

#### `lib/data/datasources/file/`
- `audio_file_storage.dart` — `AudioFileStorage`: `ensureAudioDir`, `generateFilePath` (`{appDocs}/audio_notes/{uuid}.aac`), `getFileSize`, `deleteFile`. All IO wrapped in `FileStorageException`.

#### `lib/data/repositories/interfaces/`
- `i_audio_record_repository.dart` — `IAudioRecordRepository`: `watchByNote`, `findByNote`, `findById`, `insert`, `updateTranscription`, `delete`, `deleteAllForNote`.

#### `lib/data/repositories/local/`
- `local_audio_record_repository.dart` — Drift-backed implementation via `AudioRecordsDao`. Maps `AudioRecordRow` ↔ `AudioRecord`. Wraps exceptions as `DatabaseException`.

#### `lib/services/audio/`
- `audio_recording_service.dart` — Wraps `FlutterSoundRecorder` + `FlutterSoundPlayer`. `init()` opens both (idempotent). `startRecording(filePath)` uses `Codec.aacADTS`, `bitRate 32000`, `numChannels 1`, `sampleRate 16000`. `amplitudeStream` — normalised 0.0–1.0 from `RecordingDisposition.decibels`. `stopRecording()` returns `durationMs` via `Stopwatch`. `startPlayback`/`stopPlayback` for existing clips. `dispose()` closes both.

#### `lib/services/speech/`
- `speech_to_text_service.dart` — Wraps `SpeechToText`. `initialize()` requests mic permission (returns `false` if denied). `startListening(onResult)` uses `ListenMode.dictation`, `pauseFor: 8s`. Appends final words to `_accumulated`. **Android STT timeout recovery**: `_onStatus` restarts listening if `'notListening'` fires while still `_active`. `stopListening()`, `resetText()`, `dispose()`.

#### `lib/presentation/viewmodels/`
- `audio_editor_view_model.dart` — `AudioEditorViewModel extends _$AudioEditorViewModel`. Family param: `{required String noteId}`. `build()` streams `IAudioRecordRepository.watchByNote(noteId)`. `saveRecording(filePath, durationMs, fileSizeBytes, transcript?)` creates + inserts `AudioRecord`. `deleteRecord(id)` — file deletion is caller's responsibility.

### Modified files

#### `lib/data/datasources/local/database_providers.dart`
Added `audioRecordRepositoryProvider` (`@Riverpod(keepAlive: true)` → `LocalAudioRecordRepository(db.audioRecordsDao)`).

#### `lib/presentation/views/note_editor/note_editor_screen.dart` (updated)

New state fields in `_NoteEditorScreenState`:
| Field | Type | Purpose |
|---|---|---|
| `_audioService` | `AudioRecordingService` | Owned service instance |
| `_sttService` | `SpeechToTextService` | Owned service instance |
| `_audioStorage` | `AudioFileStorage` | File path generation |
| `_audioInitialized` | `bool` | Lazy-init guard |
| `_amplitudeSubscription` | `StreamSubscription<double>?` | Feeds waveform |
| `_currentRecordingPath` | `String?` | In-progress recording file |
| `_currentAmplitude` | `double` | 0.0–1.0 for waveform bars |
| `_liveTranscript` | `String` | Live partial STT text |

New `_onMicTap()`: flushes auto-save if needed → lazy-inits services → checks STT permission → generates file path → `startRecording` + `startListening` simultaneously → subscribes to amplitude → starts record timer.

New `_stopRecording()`: cancels timers/subscriptions → `stopRecording()` + `stopListening()` → saves `AudioRecord` via `audioEditorViewModelProvider` → inserts transcript at Quill cursor.

`_insertTranscriptAtCursor(String text)`: inserts `'\n$text\n'` at `selection.baseOffset`.

`_WaveformBars`: now accepts `double amplitude`. Uses `AnimatedContainer(duration: 80ms)` per bar. Heights computed as `4.0 + amplitude * 20.0 * coefficient[i]` with 12 fixed bar coefficients.

`_RecordingOverlay`: gains `amplitude` + `liveTranscript` props. Shows transcript preview (Inter 11.5/w400/muted, single-line ellipsis) below timer when non-empty.

New `_AudioClipsRow extends ConsumerStatefulWidget`: watches `audioEditorViewModelProvider(noteId:)`. Horizontal scroll row of `_AudioClipChip` widgets (h28, surfaceContainer bg, pill). Each chip: play/pause (16px icon) + duration (Inter 11/w600/muted) + delete (16px ×). Manages `_playingId` state for play/pause toggle.

Column order in `_buildEditor`: AppBar → QuillEditor (Expanded) → `_AudioClipsRow` → `MNTagRow` → `MNEditorToolbar`.

#### `android/app/src/main/AndroidManifest.xml`
Added `<uses-permission android:name="android.permission.RECORD_AUDIO"/>`.

---

## What was built (Phase 9)

Navigation + Theming — GoRouter ShellRoute, persistent bottom nav, theme persistence, full Settings screen.

### New files

#### `lib/presentation/widgets/`
- `mn_bottom_nav.dart` — `MNBottomNav extends StatelessWidget`. Props: `int activeIndex`. Floating pill 64px, card bg, br 32, outlineStrong 0.5px, 6px shadow. Row of 4 `_NavTab` children (Home/Explore/[60 dp gap]/Tags/Settings). Active: `primaryContainer` bg, br 26, icon only (22 dp). Inactive: transparent, icon only. No label text on any tab. All tabs use `context.go(route)`.

### Modified files

#### `pubspec.yaml`
- Added `shared_preferences: ^2.3.0`.

#### `lib/presentation/router/app_router.dart`
- `router()` function now returns GoRouter with `ShellRoute` wrapping 4 tab routes, plus Note Editor routes outside the shell.
- New `_AppShell extends StatelessWidget`: `Scaffold(body: SafeArea(Stack([Positioned.fill(child), Positioned(nav)])))`. `_tabIndex(String loc)` maps path → 0/1/2/3.
- `ThemeModeNotifier` extended: `_loadPersistedMode()` (fire-and-forget from `build()`), `setLight()`, `setDark()`, `setSystem()`, `toggle()`, `_setAndPersist(ThemeMode)`. Reads/writes `AppConstants.prefThemeMode` key via `SharedPreferences`.

#### `lib/presentation/views/settings/settings_screen.dart`
- Full rewrite. Returns `ListView(padding: fromLTRB(20,8,20,150))`. No Scaffold.
- `_SettingsAppBar` → "Settings" PJS 24/800/−0.5.
- `_AppearanceCard` → Appearance card with `Row([_ThemeTile(Light), _ThemeTile(Dark)])`.
- `_ThemeTile` → selected: 2px primary border + primaryContainer bg; unselected: 0.5px outlineStrong + surfaceContainer.
- `_MiniPreview(h:56, br:10)` → simulated note card using hard-coded `AppColors.darkCard`/`lightCard`.
- `_RadioDot` (18×18) → selected: primary fill + white circle icon; unselected: outlineStrong border.

#### `lib/presentation/views/note_list/note_list_screen.dart`
- `build()`: removed Scaffold/SafeArea wrapper → returns `Stack(...)` directly.
- `_DataBody`, `_EmptyState`: `context.push(AppRoutes.search)` → `context.go(AppRoutes.search)`.
- Removed `_BottomNav` + `_NavTab` private classes.

#### `lib/presentation/views/search/search_screen.dart`
- `build()`: removed Scaffold/SafeArea wrapper → returns `Column(...)` directly.
- `onBack`: `context.pop()` → `context.go(AppRoutes.home)`.
- Removed `_BottomNav` + `_NavTab` private classes.

#### `lib/presentation/views/tags/tags_screen.dart`
- `build()`: removed Scaffold/SafeArea wrapper → returns `Column(...)` directly.
- Removed `_BottomNav` + `_NavTab` private classes.
- Removed now-unused `go_router` and `app_router` imports.

---

## What was built (Phase 8)

Categories — data layer + category picker bottom sheet.

### Modified files

#### `lib/data/datasources/local/daos/notes_dao.dart`
- Added `clearCategoryFromNotes(String categoryId)` — bulk-nulls `categoryId` on all notes belonging to the deleted category. Called by `LocalCategoryRepository.delete` before the category row is removed.

#### `lib/data/repositories/local/local_category_repository.dart`
- Constructor: `const LocalCategoryRepository(this._categoriesDao, this._notesDao)` (was single-arg).
- `delete(String id)` fully implemented with re-parent policy (PD-01 resolved): fetches grandparent id → moves all direct children → clears notes → deletes category.

#### `lib/data/datasources/local/database_providers.dart`
- `categoryRepository` provider: `LocalCategoryRepository(db.categoriesDao, db.notesDao)` (was single-arg).

#### `lib/presentation/views/note_editor/note_editor_screen.dart`
- Added import: `'../../widgets/mn_category_picker_sheet.dart'`
- `_showCategoryStub` replaced with `_onCategoryTap`:
  - `showModalBottomSheet<String>(... MNCategoryPickerSheet(currentCategoryId: ...))`
  - Result: `null` = no-op, `""` = `setCategory(null)`, non-empty = `setCategory(id)`
  - Auto-saves unsaved note before setCategory (same pattern as `_onMicTap`)
- `onCategoryTap: _showCategoryStub` → `onCategoryTap: _onCategoryTap`

### Created files

#### `lib/presentation/widgets/mn_category_picker_sheet.dart`
`MNCategoryPickerSheet extends ConsumerStatefulWidget`. Constructor: `{required String? currentCategoryId}`.

Key implementation:
- State: `_selectedId` (tracks current selection), `_expandedIds` (expand/collapse; pre-seeded with ancestor chain of `currentCategoryId` on first data load)
- Tree building: groups categories by `parentId` in `_buildScrollableTree`; siblings sorted by `sortOrder` then `name`; rendered recursively via `addRows(parentId, depth)`
- Row indentation: `paddingLeft = 10.0 + depth * 20.0`
- "None" row: `folder_off_outlined` icon; pops with `""` (unassign)
- Category rows: expand chevron (if has children) + folder icon + name; tapping pops with `category.id`; chevron tap toggles `_expandedIds` via `setState`
- "New category" row: shows context hint when a category is selected; taps open `_showNewCategoryDialog` AlertDialog; submit calls `categoryTreeViewModelProvider.notifier.insert(name, parentId: _selectedId)`
- Returns: non-empty String = assign, `""` = unassign, `null` = dismiss

No build_runner required. `flutter analyze` = 0 issues.

---

## Architecture decisions locked (Phases 1–9)

| Decision | Value | Phase |
|---|---|---|
| State management | Riverpod 2 + code-gen | 1 |
| Local DB | Drift v2 | 1 |
| Navigation | GoRouter v14 | 1 |
| Rich text editor | flutter_quill v10 (Quill Delta JSON) | 1 |
| Audio | flutter_sound v9 — AAC 32kbps mono 16kHz | 1 |
| Voice-to-text | speech_to_text v7 (on-device) | 1 |
| Fonts | Plus Jakarta Sans + Inter (google_fonts) | 1 |
| Model equality | Equatable (not freezed) | 1 |
| Tag storage | Lowercase via `StringExtensions.normalised` | 1 |
| UUID | `UuidGenerator.generate()` | 1 |
| FTS5 full-text search | Virtual table + 3 SQLite triggers | 2 |
| Tag denormalisation | `tagIds` JSON column on `NotesTable` | 2 |
| Companion naming | TABLE class name + `Companion` | 2 |
| Type converters | `QuillDeltaConverter`, `DateTimeConverter`, `StringListConverter` | 2 |
| Data providers lifecycle | `keepAlive: true` on all 5 data providers | 2/6 |
| ViewModel stream pattern | `build() → Stream<T>` for list VMs | 3 |
| `NoteEditorViewModel` family param | Optional `noteId`; `_isNew` flag | 3 |
| `SearchState` pattern | `Notifier<SearchState>`; 300 ms debounce | 3 |
| `MNNoteCard` widget type | `StatelessWidget` — purely presentational | 4 |
| Tag name resolution | Dual-provider watch in screen; Map passed to card | 4 |
| Phase 4 bottom nav | Per-screen (hardcoded active=Home); Phase 9 → `ShellRoute` | 4 |
| Shimmer skeleton | Custom `_SkeletonBox` StatefulWidget (no package) | 4 |
| `NoteEditorScreen` widget type | `ConsumerStatefulWidget` — owns `QuillController` lifecycle | 5 |
| Controller init strategy | `_initControllers` guarded by bool; called via `noteAsync.whenData()` in build | 5 |
| Auto-save source | `document.changes` stream (not `addListener`) — content-only, no cursor noise | 5 |
| `MNEditorToolbar` | `StatefulWidget` owning `addListener` for selection-aware active state | 5 |
| `MNTagRow` | `StatelessWidget` — all callbacks passed from parent screen | 5 |
| Recording overlay | `Positioned(bottom:8)` in Stack; pulsing via `_PulsingStopButton` StatefulWidget | 5 |
| Category picker Phase 5 | Stub `showModalBottomSheet` — full tree in Phase 8 | 5 |
| Color opacity API | `.withValues(alpha:)` — not deprecated `.withOpacity()` | 5 |
| STT approach | Simultaneous `flutter_sound` + `speech_to_text` (confirmed by developer) | 6 |
| STT timeout recovery | `_onStatus('notListening')` restarts `_stt.listen()` if `_active` is true | 6 |
| Services lifecycle | `AudioRecordingService` + `SpeechToTextService` are plain Dart classes owned by `_NoteEditorScreenState` — not `@riverpod` providers | 6 |
| Audio clip chips | Displayed in `_AudioClipsRow` (ConsumerStatefulWidget) above MNTagRow | 6 |
| `_AudioClipsRow` widget type | `ConsumerStatefulWidget` — needs provider watch + `_playingId` playback state | 6 |
| PD-01: category deletion policy | Re-parent children to grandparent/root; notes set Uncategorised | 8 |
| `MNCategoryPickerSheet` return value | `String?` from modal: non-empty = assign, `""` = unassign, `null` = dismiss | 8 |
| Category picker expand seeding | Ancestor chain pre-expanded on sheet open so current selection is visible | 8 |
| `clearCategoryFromNotes` | `NotesDao` method; `Value(null)` companion; called before category row delete | 8 |
| GoRouter `ShellRoute` for tabs | `_AppShell` provides Scaffold+`BottomBar`+`MNBottomNav`; tab screens return body content only | 9 |
| `ThemeModeNotifier` stays `Notifier<ThemeMode>` | Synchronous build; fire-and-forget `_loadPersistedMode()` from `build()`; defaults to `ThemeMode.system` | 9 |
| Tab nav uses `context.go` | Shell tabs are not pushed; use `go`. Note Editor uses `context.push`. SearchScreen back uses `go('/')`. | 9 |
| Settings screen theme toggle | Two-tile card (Light/Dark); `ThemeMode.system` = neither tile highlighted | 9 |
| `_MiniPreview` uses hard-coded `AppColors` | Preview must show correct theme colours regardless of active app theme | 9 |
| `sort_child_properties_last` lint | `child:` must be last named parameter in all widget constructor calls | 9 |
| `flutter_floating_bottom_bar` for nav | `BottomBar` in `_AppShell` hides nav on scroll-down; shows amber scroll-to-top button when hidden | 9+ |
| `_NavFab` center notch | 52 dp amber circle in `Stack(Positioned(top:-20))` above `MNBottomNav`; `context.push(newNote)` | 9+ |
| Icon-only tabs | Removed label text from `_NavTab`; all tabs show `Center(child: Icon(size:22))` only | 9+ |
| `BottomBar.icon` for scroll-to-top | `BackToTopIconBuilder (w,h) => Icon(keyboard_arrow_up_rounded, size: w*1.4)` — no separate state needed | 9+ |
| Firebase repo seam | `noteRepositoryProvider` → `ref.watch(syncedNoteRepositoryProvider)`; single shared instance | 10 |
| `syncedNoteRepositoryProvider` typed `SyncedNoteRepository` | Typed provider exposes `syncNote`/`syncAllPending` methods unavailable on `INoteRepository` | 10ext |
| Anonymous auth — no login UI | `FirebaseAuthService().signInAnonymously()` in `main.dart`; UID scopes Firestore data | 10ext |
| Reads stay local-only | `FirebaseNoteRepository` read methods remain `UnimplementedError`; Firestore has no FTS5 | 10ext |
| Sync on note-close + app-background | `_onBack()` calls `viewModel.syncNote()`; `_AppShell` AppLifecycle → `syncAllPending()` on paused | 10ext |
| `_SaveBadge` 4 states | Saving/Local/Syncing/Synced — grey/amber/green dots matching SyncStatus | 10ext |
| `_AppShell` → `ConsumerStatefulWidget` | Needs `WidgetsBindingObserver` for AppLifecycle; `ref` for `syncedNoteRepositoryProvider` | 10ext |
| Firebase init try-catch in main.dart | App boots normally even if Firebase fails (e.g. before `flutterfire configure` is run) | 10ext |

---

## Key conventions (enforce in all phases)

- All **screen** widgets extend `ConsumerWidget` or `ConsumerStatefulWidget`. Use `ConsumerStatefulWidget` only when the screen needs `initState`/`dispose` (e.g. `NoteEditorScreen` owns `QuillController`). Shared presentational widgets use `StatelessWidget` or `StatefulWidget` as appropriate.
- All providers use `@riverpod` annotation — no manual `Provider(...)` declarations
- ViewModels import repository **interfaces** only, never Drift DAOs directly
- All errors wrapped in `AppException` subtypes before surfacing to ViewModels
- Tag names always stored lowercase via `StringExtensions.normalised`
- UUIDs always via `UuidGenerator.generate()`
- Generated files (`*.g.dart`) are gitignored — never edit manually
- Run `dart run build_runner build --delete-conflicting-outputs` after any `@riverpod` or Drift table change
- Drift companions: `NotesTableCompanion`, `TagsTableCompanion`, etc.
- `DatabaseException` signature: `DatabaseException(String message, {Object? cause})`
- **Claude may create/edit files locally** — never run git commands. All commits via GitHub Desktop.

---

## Pending decisions

| Decision | Phase |
|---|---|
| Category deletion policy when children exist | 8 ✅ Resolved: re-parent |
| AI provider evaluation (Gemini free tier vs Groq) | 12 |

---

## First-run instructions (Phase 10 extension state)

### Firebase setup status
`flutterfire configure` has already been run on this machine. `lib/firebase_options.dart` contains real credentials (project: `modunote-ba654`). Anonymous Authentication and Firestore are enabled. **Skip the one-time setup steps below unless moving to a new machine.**

### One-time Firebase setup (new machine only — skip if already done)

1. Create Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android app — package name: `com.modunote.app`
3. Enable **Firestore Database** (start in production mode)
4. Enable **Authentication → Sign-in method → Anonymous**
5. Deploy Firestore security rules from `firestore.rules` (Rules tab in Firebase Console)
6. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
7. In the `modunote/` directory: `flutterfire configure` — select your project + Android only
   - This generates `lib/firebase_options.dart` (real values, replaces stub) + `android/app/google-services.json` + patches Gradle files
   - ⚠️ Both generated files are gitignored — do NOT commit them. They must be re-generated on each new machine.

### Code setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze   # expected: 0 issues
flutter run
```

### Expected behaviour after Firebase setup
- App boots, anonymous sign-in fires silently in background.
- All note operations still go through local Drift (auto-save every 800 ms).
- Opening a note → badge shows "Local". Pressing back → badge briefly shows "Syncing…" → then "Synced" (if Firebase configured) or stays "Local" (if Firebase unavailable).
- Pressing home button (app background) triggers `syncAllPending()` for any unsynced notes.
- Floating pill bottom nav, amber `+` FAB, hide-on-scroll, Settings theme toggle — all Phase 9 behaviour unchanged.

### If Firebase is not yet configured (stub still in place)
App boots and runs normally. Sync calls are wrapped in try-catch and fail silently. Badge will show "Local" permanently until Firebase is set up.

---

## What was built (Phase 11)

**Backend** (`modunote-api/` — sibling directory at same level as `modunote/`):
- `main.py` — FastAPI app with CORS middleware, mounts `/api/v1` router, `GET /health`
- `requirements.txt` — fastapi, uvicorn, sqlalchemy[asyncio], asyncpg, alembic, pydantic, pydantic-settings, python-jose, httpx
- `docker-compose.yml` — PostgreSQL 16 on port 5432, DB `modunote_dev`
- `.env.example` — `DATABASE_URL`, `SECRET_KEY`, `DEV_MODE=true`, `ALLOWED_ORIGINS`
- `core/config.py` — `Settings(BaseSettings)` reads `.env`
- `core/auth.py` — `verify_token`: bypasses JWT when `DEV_MODE=true`, returns `"dev-user-local"`
- `routers/notes.py` — `POST /api/v1/notes/{id}/tags/suggest` → 501; `POST /api/v1/notes/{id}/summary` → 501
- `models/note.py` — Pydantic `TagSuggestRequest/Response`, `SummaryRequest/Response`
- `db/models.py` — SQLAlchemy `Note` model stub (id, user_id, title, content, sync_status, timestamps)
- `alembic.ini` + `alembic/env.py` — async Alembic env reads `DATABASE_URL` from settings
- `alembic/versions/.gitkeep` — placeholder; first real migration in Phase 12

**Flutter** (`modunote/`):
- `pubspec.yaml` — added `http: ^1.2.0`
- `lib/core/errors/app_exception.dart` — added `RemoteServiceException` to sealed class
- `lib/services/remote/remote_note_service.dart` — `RemoteNoteService` plain Dart class; `suggestTags()` + `summariseNote()` both throw `UnimplementedError` (server returns 501). Base URL: `http://10.0.2.2:8000/api/v1`.

`flutter analyze` = 0 issues. No build_runner run required (no new @riverpod annotations).

---

## Phase 12 — What to build next

**Title**: AI Features (Auto-tagging + Note Summarisation)

**Scope** (from DECISIONS.md D12.1–D12.5):

1. **AI provider selection** (PD-02 — resolve at Phase 12 start): Evaluate Google Gemini free tier vs Groq API for tag suggestion and summarisation. Decision affects backend `services/ai_service.py` only — Flutter code is unchanged regardless.
2. **Backend `services/ai_service.py`**: Implement `suggest_tags(title, content) → list[str]` and `summarise(title, content) → str` using the chosen AI provider. Replace the 501 stubs in `routers/notes.py` with real calls.
3. **First Alembic migration**: `alembic revision --autogenerate -m "create_notes"` → `alembic upgrade head` to create the `notes` table in PostgreSQL.
4. **Flutter `RemoteNoteService`**: Implement real `suggestTags()` and `summariseNote()` (remove `UnimplementedError` stubs). Both calls fire-and-forget after note save — never block the save flow (D12.4).
5. **Smart auto-tagging UI**: After `_onBack()` saves + syncs, call `suggestTags` in background. On response, show a dismissible "Suggested tags" banner below the note card on the list screen. User can accept or dismiss each tag individually.
6. **Note summarisation**: Add "Summarise" overflow menu item to `NoteEditorScreen`. On tap, call `summariseNote()` and insert result as a Quill blockquote at document top.
7. **`flutter analyze` = 0 issues**.
8. **Update all doc files** post-completion.

**Before starting Phase 12**, Claude must present a detailed plan and wait for developer approval. Resolve PD-02 (AI provider) at the start of that session.

---

## Documentation completed (Post-Phase-6 session)

The following doc work was completed after Phase 6 code was finished:

| File | What was done |
|---|---|
| `TESTING.md` | **Created.** Full manual testing guide: **15 sections**, ~130 numbered checks, all Phases 1–6 features. Section 15 = voice/STT deep verification (ADB file paths, DB inspection, logcat filtering). Quick smoke test (~46 🔴 critical checks, ~20 min). Full regression (~130 checks, ~1.5 hr). Run smoke test before every commit. |
| `DECISIONS.md` | D6.4 revised (file-based STT → simultaneous live STT); D6.5–D6.9 added; D2.8 corrected (3 repos → 4 repos + DB = 5 keepAlive providers). Phase 6 status ✅. |
| `CLAUDE.md` | `TESTING.md` added to quick reference; on-boarding checklist updated to 10 steps including `flutter analyze` gate and TESTING.md post-phase smoke test; DB providers description corrected to 5 keepAlive. |
| `README.md` | Replaced default Flutter stub with full project description, tech stack, architecture, phase status, getting-started guide, and documentation index. |
| `progress.md` | Data providers lifecycle entry corrected from 4→5; Documentation section added covering all post-Phase-6 doc changes and testing philosophy for future phases. |

---

## Phase 9 — What to build next

**Title**: Navigation + Theming (GoRouter ShellRoute, M3 bottom nav, theme persistence)

**Scope** (from DECISIONS.md D9.1–D9.5):

1. **GoRouter `ShellRoute`** — refactor `app_router.dart` to wrap Home (`/`), Explore (`/search`), Tags (`/tags`), Settings (`/settings`) in a `ShellRoute`. The Note Editor and Category Picker do not participate in the shell.
2. **`MNBottomNav`** — extract the floating pill nav from per-screen `_BottomNav` implementations into a single shared widget rendered by the shell. Remove per-screen nav bars from `NoteListScreen`, `TagsScreen`, and the Search screen.
3. **Theme persistence** — extend `ThemeModeNotifier` to read from and write to `SharedPreferences` using `AppConstants.prefThemeMode`. Add `shared_preferences` package to `pubspec.yaml`.
4. **Settings screen** — replace placeholder with theme toggle (Light / Dark card grid, per D9.5).
5. **`flutter analyze` = 0 issues**.
6. **Update all doc files** post-completion.

**Before starting Phase 9**, Claude must present a detailed plan and wait for developer approval.

---

## Files to attach to new thread

- `CLAUDE.md` — AI context (architecture, conventions, phase status)
- `DECISIONS.md` — all architectural decisions (Phases 1–6 complete)
- `progress.md` — phase log, decisions log, bugfix history
- `MODUNOTE_UI_REFERENCE.md` — design spec (required before any UI work)
- `THREAD_HANDOFF.md` — this file
- `TESTING.md` — manual testing checklist (smoke test + full regression, Phases 1–6)
