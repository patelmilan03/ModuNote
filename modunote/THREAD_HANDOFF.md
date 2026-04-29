# ModuNote — Thread Handoff Summary
> Paste this into a new Claude conversation to continue development.

---

## Status: Phase 5 ✅ Complete. Proceed with Phase 6.

Phase 5 is fully complete. `NoteEditorScreen` has been replaced with the full Quill editor
implementation. Two new shared widgets (`MNEditorToolbar`, `MNTagRow`) are in place.
`flutter analyze` reports **0 issues**. No new packages were added. No build_runner run is
required. The developer should commit Phase 5 via GitHub Desktop before starting Phase 6.

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

## Architecture decisions locked (Phases 1–5)

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
| Data providers lifecycle | `keepAlive: true` on all 4 data providers | 2 |
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
| Category deletion policy when children exist (cascade vs re-parent) | 8 |
| AI provider evaluation (Gemini free tier vs Groq) | 12 |

---

## First-run instructions (Phase 5 state)

```bash
# No new packages added in Phase 5 — flutter pub get not needed
# No new @riverpod annotations — build_runner not needed
flutter analyze   # expected: 0 issues
flutter run       # boots to NoteListScreen; tap FAB to open NoteEditorScreen
```

Expected: Home screen unchanged. Tap amber FAB → Note Editor opens with empty Quill editor,
title TextField, "Saved" badge, format toolbar, tag row, mic button. Type text → badge shows
"Saving…" → 0.8 s later shows green dot "Saved". Tap back → returns to Note List. Tap an
existing note card → editor opens with pre-loaded title + content.

---

## Phase 6 — What to build next

**Title**: Voice-to-Text + Audio Recording/Playback

**Scope** (from DECISIONS.md D6.1–D6.6):

1. Wire the mic button in `MNTagRow` to real audio recording via `AudioRecordingService`
2. Connect waveform bars in `_RecordingOverlay` to real amplitude stream
3. After recording stops, run `SpeechToTextService` and insert transcript at Quill cursor
4. Implement `AudioRecord` persistence via `AudioRecordsDao` + `LocalAudioRecordRepository`
5. Add microphone permission handling via `PermissionException`
6. `flutter analyze` = 0 issues after implementation
7. Update all four doc files

**Key files already in place**: `lib/services/audio/audio_recording_service.dart` (stub),
`lib/services/speech/speech_to_text_service.dart` (stub). Wire these up to the UI.

**Before starting Phase 6**, Claude must present a detailed plan for developer approval.

---

## Files to attach to new thread

- `CLAUDE.md` — AI context (architecture, conventions, phase status)
- `DECISIONS.md` — all architectural decisions (Phases 1–4 complete)
- `progress.md` — phase log + decisions log
- `MODUNOTE_UI_REFERENCE.md` — design spec (required before any UI work)
- `THREAD_HANDOFF.md` — this file
