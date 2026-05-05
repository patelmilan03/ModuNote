# ModuNote — Thread Handoff

> Read this file, CLAUDE.md, progress.md, and DECISIONS.md before writing a single line of code.
> This file is the authoritative summary of the current session and the scope for the next one.

---

## Current status

**Phases 1–5 complete and committed. Search screen implemented. All changes pushed to GitHub.**

`flutter analyze` = **0 issues**.
Next phase: **Phase 6 — Voice-to-text + audio recording/playback**.

---

## What this app is

**ModuNote** — a quick-capture ideation app for content creators and people who prefer speaking over typing for journalling. Android-only. Local-first (full offline). No accounts.

Core loop: open app → tap FAB → write or speak → note auto-saves. Everything else (tags, categories, search, voice) is organised around that core loop.

**Developer profile**: Junior Flutter developer. Background in Python / FastAPI / PostgreSQL. Has prior Flutter MVVM experience (VocalNote app).

---

## Repository

- **GitHub**: patelmilan03/ModuNote
- **Branch**: main
- **Package**: `modunote` (`com.modunote.app`)
- **Platform**: Android (iOS not configured)
- **Flutter**: ≥ 3.22.0 · Dart: ≥ 3.3.0

---

## Architecture (non-negotiable)

```
View → ViewModel → Repository Interface → DAO (Drift) → SQLite
```

- **Views** — `ConsumerWidget` or `ConsumerStatefulWidget`. Never `StatelessWidget`/`StatefulWidget` directly. Use `ConsumerStatefulWidget` only when `initState`/`dispose` lifecycle is needed (e.g. `NoteEditorScreen` owns `QuillController`).
- **ViewModels** — `@riverpod`-annotated `AsyncNotifier` or `Notifier`. Import repository interfaces only. Never touch DAOs or `AppDatabase`.
- **Repository interfaces** — live in `data/repositories/interfaces/`. ViewModels import these; never the implementation.
- **DAOs** — Drift-generated. Only the local repository implementations call them.
- **Errors** — all raw Drift/IO/platform exceptions are caught at the DAO/repository layer and re-thrown as `AppException` subtypes before reaching ViewModels.

---

## Phase-by-phase summary

### Phase 1 — Project setup ✅

Runnable Flutter skeleton with zero business logic.

- `pubspec.yaml` — 13 runtime deps, 6 dev deps (all versions locked — see below)
- `lib/main.dart` — `WidgetsFlutterBinding.ensureInitialized()` + `ProviderScope` + `runApp`
- `lib/app.dart` — `ModuNoteApp extends ConsumerWidget`, `MaterialApp.router`
- `lib/core/theme/` — `AppColors` (34 tokens), `AppTypography` (PJS + Inter), `AppTheme.light()` / `.dark()`
- `lib/core/constants/app_constants.dart` — magic numbers, audio spec, string keys
- `lib/core/errors/app_exception.dart` — sealed `AppException` + 5 subtypes (Database, FileStorage, NotFound, Validation, Permission)
- `lib/core/extensions/string_extensions.dart` — `isBlank`, `normalised`, `truncate`, `capitalised`
- `lib/core/utils/uuid_generator.dart` — `UuidGenerator.generate()`
- `lib/data/models/` — `Note` + `SyncStatus` enum, `Tag`, `Category`, `AudioRecord`
- `lib/data/repositories/interfaces/` — `INoteRepository`, `ITagRepository`, `ICategoryRepository`
- `lib/presentation/router/app_router.dart` — GoRouter (6 routes), `routerProvider`, `ThemeModeNotifier`
- All 5 view screens as placeholder stubs

### Phase 2 — Data layer ✅

Full Drift SQLite schema, DAOs, TypeConverters, local repository implementations.

- `lib/data/datasources/local/app_database.dart` — `@DriftDatabase` with 5 tables, 4 DAOs, FTS5 virtual table (`notes_fts`), 3 SQLite triggers (INSERT/UPDATE/BEFORE DELETE), `MigrationStrategy`
- `lib/data/datasources/local/database_providers.dart` — `appDatabaseProvider`, `noteRepositoryProvider`, `tagRepositoryProvider`, `categoryRepositoryProvider` (all `keepAlive: true`)
- Tables: `NotesTable`, `TagsTable`, `NoteTagsTable`, `CategoriesTable`, `AudioRecordsTable`
- DAOs: `NotesDao`, `TagsDao`, `CategoriesDao`, `AudioRecordsDao`
- Local repos: `LocalNoteRepository`, `LocalTagRepository`, `LocalCategoryRepository`
- TypeConverters: `QuillDeltaConverter` (Delta JSON ↔ TEXT), `DateTimeConverter` (DateTime ↔ epoch ms), `StringListConverter` (List\<String\> ↔ JSON array)

**Critical naming rules learned in this phase:**
- Drift companions are named after the TABLE class, not the data class: `NotesTableCompanion` (NOT `NoteRowCompanion`)
- `DatabaseException` signature: `DatabaseException(String message, {Object? cause})` — no `originalError`, no `stackTrace` param

### Phase 3 — State management ✅

All 5 Riverpod ViewModels. No UI changes.

```dart
// NoteListViewModel — build() → Stream<List<Note>>
// Methods: archive(id), delete(id), togglePin(id)

// NoteEditorViewModel — family provider
// build({String? noteId}) → Future<Note?>
// _isNew flag: true when noteId == null, cleared after first insert
// Methods: save(note), addTag(tagId), removeTag(tagId), setCategory(categoryId?)

// TagListViewModel — build() → Stream<List<Tag>>
// Methods: insert(String name) → Tag, delete(id)

// CategoryTreeViewModel — build() → Stream<List<Category>>
// Methods: insert(name, parentId?, sortOrder), move(id, newParentId?), delete(id)

// SearchViewModel — Notifier<SearchState>
// SearchState { query: String, results: AsyncValue<List<Note>> }
// setQuery(String) — 300 ms debounce; empty query → AsyncData([]) immediately
```

Provider usage pattern:
```dart
ref.watch(noteEditorViewModelProvider())              // new note
ref.watch(noteEditorViewModelProvider(noteId: id))   // existing note
```

### Phase 4 — Note list screen ✅

**New files:**
- `lib/presentation/widgets/mn_note_card.dart` — `MNNoteCard extends StatelessWidget`. Props: `Note note`, `VoidCallback onTap`, `List<String> tagNames`. Renders pinned tint bg, pin icon, title (PJS 16.5/w700), 1-line body preview from Quill Delta `ops`, up to 3 `#tag` chips, relative timestamp.
- `lib/presentation/widgets/mn_search_field.dart` — `MNSearchField extends StatelessWidget`. Non-editable tap target (height 48, br 16, surfaceContainer bg). Navigates to `/search` on tap.
- `lib/presentation/views/note_list/note_list_screen.dart` — full implementation. `NoteListScreen extends ConsumerWidget`. Stack layout: `Positioned.fill` content + `Align(bottomCenter)` bottom nav + `Positioned` FAB. Sections: PINNED + RECENT with `_SectionHeader`, skeleton loading (`_SkeletonBox` StatefulWidget, opacity 0.35→0.65 800 ms), error state, empty state.

**Bottom nav design (Phase 4 + post-Phase-5 fix):**
- Centered at bottom via `Align(alignment: Alignment.bottomCenter, child: Padding(bottom: 14))`
- Container is intrinsically sized (not full-width) — `mainAxisSize: MainAxisSize.min`
- Each `_NavTab`: fixed 48×48 `AnimatedContainer` with `shape: BoxShape.circle` — true circle indicator
- No labels on tabs — icon only
- Home tab active on `NoteListScreen`

### Phase 5 — Note editor screen ✅

**New files:**
- `lib/presentation/widgets/mn_editor_toolbar.dart` — `MNEditorToolbar extends StatefulWidget`. Owns `controller.addListener` → `setState` for selection-aware active badges. 9 tools: bold, italic, underline, H1, H2, bullet, numbered, checklist, blockquote. Each 34×34, br 10. Active = `primaryContainer` bg + `onPrimaryContainer` icon. H1/H2 use `Text` label (no icon). Toggle: active → `Attribute.clone(attr, null)`; inactive → `formatSelection(attr)`.
- `lib/presentation/widgets/mn_tag_row.dart` — `MNTagRow extends StatelessWidget`. Category chip (h30 br10), horizontal-scroll row of dismissible tag chips + `+ tag` outlined chip, mic button (40×40 br14; idle = primaryContainer; recording = recordRed + stop square + `.withValues(alpha: 0.15)` glow).
- `lib/presentation/views/note_editor/note_editor_screen.dart` — `NoteEditorScreen extends ConsumerStatefulWidget`.

**NoteEditorScreen key state:**

| Variable | Type | Purpose |
|---|---|---|
| `_quillController` | `QuillController?` | Null until note loads |
| `_titleController` | `TextEditingController` | Title field |
| `_editorFocusNode` | `FocusNode` | Quill focus |
| `_editorScrollController` | `ScrollController` | Quill scroll |
| `_contentSubscription` | `StreamSubscription?` | `document.changes` → auto-save |
| `_debounce` | `Timer?` | 800 ms auto-save debounce |
| `_recordTimer` | `Timer?` | 1 s recording tick |
| `_isDirty` | `bool` | Unsaved changes flag |
| `_isRecording` | `bool` | Recording overlay visible |
| `_recordSeconds` | `int` | Recording timer |
| `_currentNote` | `Note?` | Last saved/loaded note |
| `_controllersInitialized` | `bool` | One-shot init guard |

**Key behaviours:**
- `noteAsync.whenData(_initControllers)` called in `build()` — sets `_quillController` synchronously, no `setState` needed
- `document.changes.listen()` NOT `addListener` — fires on content only, not cursor movement
- `_onBack()` cancels debounce → `await _performAutoSave()` → `context.pop()`
- `_syncCurrentNote()` re-reads VM state after `addTag`/`removeTag`
- Category chip → stub `showModalBottomSheet` ("Category picker — Phase 8")
- All colour opacity uses `.withValues(alpha:)` — not deprecated `.withOpacity()`

**Private widgets in editor file:** `_EditorAppBar`, `_CircleIconButton`, `_SaveBadge` (green dot "Saved" / muted dot "Saving…"), `_RecordingOverlay`, `_WaveformBars` (12 static bars), `_PulsingStopButton` (SingleTickerProviderStateMixin, scale 0.95→1.05).

### Post-Phase-5 fixes ✅

**Search screen** (`lib/presentation/views/search/search_screen.dart`) — replaced placeholder with full implementation:
- `SearchScreen extends ConsumerStatefulWidget` with auto-focused `TextField`
- Calls `searchViewModelProvider.notifier.setQuery()` on every keystroke
- Three states: empty prompt ("Search your notes"), no-results state, results list (`MNNoteCard`)
- Clear (×) button appears when field has text
- Same circle-indicator bottom nav with Explore tab active
- Back button → `context.pop()`

**Bottom nav redesign** (applied to both `NoteListScreen` and `SearchScreen`):
- Changed from `Positioned(left:16, right:16)` full-width → `Align(bottomCenter)` + `Padding(bottom:14)`
- Active indicator changed from pill (`AnimatedContainer` with `borderRadius:26`) → circle (`shape: BoxShape.circle`, 48×48 fixed)
- Removed `Expanded` from `_NavTab` — tabs are now fixed-size, nav is intrinsically sized

---

## Full package list

| Package | Version | Role |
|---|---|---|
| flutter_riverpod | ^2.5.1 | State management |
| riverpod_annotation | ^2.3.5 | @riverpod annotation |
| drift | ^2.18.0 | SQLite ORM |
| drift_flutter | ^0.2.1 | Flutter SQLite path setup |
| flutter_quill | ^10.8.5 | Rich text editor (Delta JSON) |
| go_router | ^14.2.0 | Navigation |
| speech_to_text | ^7.0.0 | On-device voice-to-text |
| flutter_sound | ^9.2.13 | Audio recording + playback |
| google_fonts | ^6.2.1 | Plus Jakarta Sans + Inter |
| uuid | ^4.4.0 | UUID v4 generation |
| path_provider | ^2.1.3 | App directory paths |
| path | ^1.9.0 | Path manipulation |
| equatable | ^2.0.5 | Model value equality |
| riverpod_generator | ^2.4.3 | (dev) Provider code-gen |
| build_runner | ^2.4.11 | (dev) Code generation runner |
| drift_dev | ^2.18.0 | (dev) Drift code-gen |
| flutter_lints | ^4.0.0 | (dev) Lint rules |
| custom_lint | ^0.7.6 | (dev) riverpod_lint host |
| riverpod_lint | ^2.4.0 | (dev) Riverpod lint rules |

`dependency_overrides: intl: '>=0.19.0 <0.21.0'` — required because flutter_quill and Flutter SDK have conflicting intl version requirements.

---

## Design tokens

All in `lib/core/theme/app_colors.dart`. Never hardcode colours anywhere.

| Token | Light | Dark |
|---|---|---|
| Primary | `#5B4EFF` | `#B7AFFF` |
| Accent / FAB | `#F59E0B` | unchanged |
| Background | `#FEFBFF` | `#1C1B2E` |
| Card | `#FFFFFF` | `#232238` |
| Surface container | `#F3F0FF` | `#2C2B42` |
| Record red | `#E5484D` | `#FF6369` |

Fonts: **Plus Jakarta Sans** (headings, w700–800) via `AppTypography.plusJakartaSans(...)`. **Inter** (body, w400–600) via `AppTypography.inter(...)`.

---

## Navigation routes

| Constant | Path | Screen |
|---|---|---|
| `AppRoutes.home` | `/` | NoteListScreen |
| `AppRoutes.newNote` | `/note/new` | NoteEditorScreen (new) |
| `AppRoutes.editNote` | `/note/:id` | NoteEditorScreen (existing) |
| `AppRoutes.search` | `/search` | SearchScreen |
| `AppRoutes.tags` | `/tags` | TagsScreen (placeholder) |
| `AppRoutes.settings` | `/settings` | SettingsScreen (placeholder) |

`AppRoutes.editNotePath(String id)` builds the edit path. Phase 9 wraps these in a `ShellRoute`.

---

## Key conventions (enforce every phase)

1. All screen widgets extend `ConsumerWidget` or `ConsumerStatefulWidget` — never `StatelessWidget` directly
2. All providers use `@riverpod` annotation — no manual `Provider(...)` declarations
3. ViewModels import repository interfaces only — never DAOs or `AppDatabase`
4. All errors wrapped in `AppException` subtypes before reaching ViewModels
5. Tag names always lowercase via `StringExtensions.normalised` on every write
6. UUIDs always via `UuidGenerator.generate()` — never `Uuid().v4()` directly
7. Drift companions named after TABLE class: `NotesTableCompanion` (not `NoteRowCompanion`)
8. `DatabaseException(String message, {Object? cause})` — no other params
9. Generated `*.g.dart` files are gitignored — never edit manually
10. Run `dart run build_runner build --delete-conflicting-outputs` after any `@riverpod` or Drift table change
11. All colour opacity via `.withValues(alpha:)` — not `.withOpacity()` (deprecated in Flutter 3.27+)
12. **Never run git commands** — all commits and pushes are done by the developer manually

---

## Pending decisions

| Decision | Phase to resolve |
|---|---|
| Category deletion policy when children exist (cascade vs re-parent) | 8 |
| AI provider evaluation (Gemini free tier vs Groq) | 12 |

---

## Phase 6 — What to build next

**Title**: Voice-to-Text + Audio Recording/Playback

**Audio spec**: AAC · 32 kbps · mono · 16 kHz · stored under `getApplicationDocumentsDirectory()/audio_notes/`

**Scope**:

1. Implement `AudioRecordingService` in `lib/services/audio/audio_recording_service.dart` (stub exists) — uses `flutter_sound` to record AAC, expose amplitude stream for waveform bars
2. Implement `SpeechToTextService` in `lib/services/speech/speech_to_text_service.dart` (stub exists) — wraps `speech_to_text` v7
3. Wire mic button in `MNTagRow` to `AudioRecordingService` via `NoteEditorScreen`
4. Connect `_WaveformBars` to real amplitude stream (currently static bars)
5. After recording stops, run `SpeechToTextService` → insert transcript at Quill cursor position
6. Persist `AudioRecord` via `AudioRecordsDao` + a new `IAudioRecordRepository` / `LocalAudioRecordRepository`
7. Handle microphone permission — catch `PermissionException` and show a snackbar
8. `flutter analyze` = 0 issues
9. Update `CLAUDE.md`, `DECISIONS.md`, `progress.md`, `THREAD_HANDOFF.md`

**Files already in place**: `lib/services/audio/audio_recording_service.dart` (stub), `lib/services/speech/speech_to_text_service.dart` (stub), `AudioRecordsDao` fully implemented, `AudioRecord` model complete.

**Before starting**: present a detailed implementation plan for developer approval.

---

## First-run instructions (current state)

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze    # expected: 0 issues
flutter run        # boots to NoteListScreen
```

Expected flow: Home screen shows "Your notes" with pinned/recent sections → tap amber FAB → Note Editor opens with Quill editor + format toolbar + tag row → type → "Saved" badge goes green after 0.8 s → tap back → returns to list. Tap search bar or Explore nav tab → Search screen opens with auto-focused text field → type to search → results appear as note cards.
