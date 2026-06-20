# CLAUDE.md — ModuNote AI Agent Context

> This file is the single source of truth for any AI agent (Claude or otherwise) working on this codebase.
> Read this before writing, editing, or reviewing any file in this project.
> Keep this file updated at the end of every phase.

---

## Project Overview

**App name**: ModuNote
**Purpose**: Quick-capture ideation tool for a solo YouTube/Instagram content creator.
**Platform**: Android (Flutter). iOS deferred.
**Developer profile**: Junior Flutter developer. Background in Python / FastAPI / PostgreSQL. Has prior Flutter MVVM experience (VocalNote app).

---

## Architecture at a Glance

| Layer | Pattern | Key tech |
|---|---|---|
| State management | MVVM + Riverpod 2 | `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` |
| Local DB | Repository pattern | `drift` v2, `drift_flutter`, `drift_dev` |
| Navigation | Declarative + ShellRoute | `go_router` v14 |
| Floating bottom bar | Hide-on-scroll + scroll-to-top | `flutter_floating_bottom_bar` ^2.0.0 |
| Rich text | Delta JSON | `flutter_quill` v10 |
| Audio | Record + playback | `flutter_sound` v9 (AAC 32kbps mono 16kHz) |
| Voice-to-text | On-device | `speech_to_text` v7 |
| Theme persistence | SharedPreferences | `shared_preferences` ^2.3.0 |
| Fonts | Google Fonts | Plus Jakarta Sans (headings) + Inter (body) |
| UUID | v4 | `uuid` v4 |
| Remote API client | HTTP wrapper | `http` ^1.2.0 — `RemoteNoteService` |

**Rule**: ViewModels (`AsyncNotifier` / `Notifier`) depend on repository **interfaces** only — never on Drift DAOs directly. Views (`ConsumerWidget`) depend on ViewModels only.

---

## Folder Structure

```
lib/
├── main.dart                          # Entry — ProviderScope + WidgetsFlutterBinding
├── app.dart                           # MaterialApp.router — watches routerProvider + themeModeProvider
│
├── core/
│   ├── constants/app_constants.dart   # Magic numbers, string keys, audio config
│   ├── errors/app_exception.dart      # Sealed AppException hierarchy
│   ├── extensions/string_extensions.dart
│   ├── utils/uuid_generator.dart      # UuidGenerator.generate()
│   └── theme/
│       ├── app_colors.dart            # All design tokens (light + dark)
│       ├── app_typography.dart        # Plus Jakarta Sans + Inter helpers
│       └── app_theme.dart             # AppTheme.light() / AppTheme.dark()
│
├── data/
│   ├── models/                        # Plain immutable classes + Equatable
│   │   ├── note.dart                  # Note, SyncStatus enum
│   │   ├── tag.dart
│   │   ├── category.dart
│   │   └── audio_record.dart
│   ├── repositories/
│   │   ├── interfaces/                # Abstract contracts (INoteRepository etc.)
│   │   ├── local/                     # Drift implementations (Phase 2)
│   │   ├── remote/                    # Firebase stubs (Phase 10) — FirebaseNoteRepository
│   │   └── synced/                    # Sync wrapper (Phase 10) — SyncedNoteRepository
│   └── datasources/
│       ├── local/                     # Drift DAOs + AppDatabase (Phase 2)
│       └── file/                      # AudioFileStorage (Phase W — conditional export)
│           ├── audio_file_storage.dart          # 2-line conditional export shim
│           ├── audio_file_storage_native.dart   # dart:io implementation (native)
│           └── audio_file_storage_web.dart      # no-op / throw stub (web)
│
├── services/
│   ├── speech/speech_to_text_service.dart   # Phase 6
│   ├── audio/audio_recording_service.dart   # Phase 6
│   ├── auth/firebase_auth_service.dart      # Phase 10ext — silent anonymous sign-in
│   └── remote/remote_note_service.dart      # Phase 11 — HTTP client for FastAPI backend
│
└── presentation/
    ├── viewmodels/                    # AsyncNotifier classes (Phase 3+)
    ├── views/
    │   ├── note_list/note_list_screen.dart
    │   ├── note_editor/note_editor_screen.dart
    │   ├── search/search_screen.dart
    │   ├── tags/tags_screen.dart
    │   └── settings/settings_screen.dart
    ├── widgets/                       # Shared widgets — mn_note_card.dart, mn_search_field.dart, mn_editor_toolbar.dart, mn_tag_row.dart, mn_category_picker_sheet.dart, mn_bottom_nav.dart (Phase 4+)
    └── router/
        ├── app_router.dart            # GoRouter config, ShellRoute, _AppShell (ConsumerStatefulWidget+WidgetsBindingObserver), routerProvider, ThemeModeNotifier
        └── app_router.g.dart          # Generated — run `dart run build_runner build`
```

---

## Design System

**Reference file**: `MODUNOTE_UI_REFERENCE.md` (project root — copy from Claude project)

| Token | Light | Dark |
|---|---|---|
| Primary | `#5B4EFF` | `#B7AFFF` |
| Accent (FAB, CTA) | `#F59E0B` | `#F59E0B` (unchanged) |
| Background | `#FEFBFF` | `#1C1B2E` |
| Card | `#FFFFFF` | `#232238` |
| Record red | `#E5484D` | `#FF6369` |

Fonts: `Plus Jakarta Sans` (headings, weight 700–800) + `Inter` (body, weight 400–600).
All raw token values are in `lib/core/theme/app_colors.dart`.

---

## Data Models (summary)

### Note
```dart
// id, title, content (Quill Delta Map), categoryId?, tagIds[],
// isPinned, isArchived, createdAt, updatedAt, syncStatus
```

### Tag
```dart
// id, name (lowercase), createdAt
// Many-to-many with Note via join table (Phase 2)
```

### Category
```dart
// id, name, parentId? (null = root), sortOrder, createdAt
// Adjacency-list hierarchy. Max depth: 5
```

### AudioRecord
```dart
// id, noteId, filePath, durationMs, fileSizeBytes,
// codec ('aac'), transcribedText?, createdAt
```

---

## Audio Spec
- Format: AAC
- Bitrate: 32 kbps
- Channels: mono (1)
- Sample rate: 16 kHz
- Expected size: ~0.24 MB/min
- Storage dir: `AppConstants.audioSubDir` = `'audio_notes'` under `getApplicationDocumentsDirectory()`

---

## Navigation Routes

| Route | Screen | Shell? |
|---|---|---|
| `/` | NoteListScreen | ✅ ShellRoute tab 0 |
| `/search` | SearchScreen | ✅ ShellRoute tab 1 |
| `/tags` | TagsScreen | ✅ ShellRoute tab 2 |
| `/settings` | SettingsScreen | ✅ ShellRoute tab 3 |
| `/note/new` | NoteEditorScreen (new) | ❌ Full-screen push |
| `/note/:id` | NoteEditorScreen (edit) | ❌ Full-screen push |
| `/archive` | ArchivedNotesScreen | ❌ Full-screen push (from Settings) |

The four shell tabs share a persistent `MNBottomNav` rendered by `_AppShell` in `app_router.dart`. Tab screens return body content only — no `Scaffold` or `SafeArea`. Note Editor routes are outside the shell and pushed via `context.push`.

---

## Code Generation

Any time you add or modify a `@riverpod` annotated function or a Drift table, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated files (`*.g.dart`) are in `.gitignore` — never edit them manually.
The pre-generated stub `app_router.g.dart` in Phase 1 must be replaced by running build_runner after `flutter pub get`.

---

## Development Phase Status

| Phase | Title | Status |
|---|---|---|
| 1 | Project setup & folder structure | ✅ Complete |
| 2 | Data layer (Drift schema, DAOs, Repositories) | ✅ Complete |
| 3 | State management (Riverpod providers, base ViewModels) | ✅ Complete |
| 4 | Note list screen | ✅ Complete |
| 5 | Note editor screen (Quill) | ✅ Complete |
| 6 | Voice-to-text + audio recording/playback | ✅ Complete |
| 7 | Tags (freeform + autocomplete) | ✅ Complete |
| 8 | Categories (hierarchical folder tree) | ✅ Complete |
| 9 | Navigation + theming (GoRouter shell, M3 bottom nav) | ✅ Complete |
| 10 | Firebase preparation + live sync (anon auth, Firestore writes, SyncStatus badge, AppLifecycle) | ✅ Complete |
| 11 | Backend API scaffolding (FastAPI stubs) | ✅ Complete |
| 11.5 | Bug fixes + UX features (swipe cards, note options, system theme, archive screen, filter bar) | ✅ Complete |
| W | Web Portfolio Preview — Flutter Web + WASM SQLite + phone-frame landing page + Firebase Hosting | ✅ Complete |
| 12 | AI features (auto-tagging, summarisation) | ⬜ Not started |

---

## Key Conventions

- **All screen widgets** extend `ConsumerWidget` or `ConsumerStatefulWidget` — never `StatelessWidget`/`StatefulWidget` directly (Riverpod can be watched everywhere). Use `ConsumerStatefulWidget` when the screen needs `initState`/`dispose` lifecycle (e.g. `NoteEditorScreen` owns `QuillController`).
- **Providers** use `@riverpod` annotation + code-gen. No manual `Provider(...)` declarations.
- **Models** are immutable plain Dart classes with `Equatable`. `copyWith` on every model.
- **Repository interfaces** live in `data/repositories/interfaces/`. ViewModels import the interface, not the implementation.
- **Errors** are wrapped in `AppException` subtypes before surfacing to the ViewModel layer.
- **Tag names** are always stored and compared lowercase. Use `StringExtensions.normalised`.
- **UUIDs** always go through `UuidGenerator.generate()` — never call `Uuid().v4()` directly.
- **Drift companion naming** — Companions are named after the **table class**, not the data class: `NotesTableCompanion` (not `NoteRowCompanion`), `TagsTableCompanion`, `NoteTagsTableCompanion`, `CategoriesTableCompanion`, `AudioRecordsTableCompanion`.
- **DatabaseException** constructor signature is `DatabaseException(String message, {Object? cause})` — there is no `originalError` or `stackTrace` parameter.
- **No git operations** — Claude may create and edit files on the local machine freely. Claude must never run `git commit`, `git push`, `git pull`, `git reset`, or any other git command that changes repository state or interacts with GitHub. All commits and pushes are handled exclusively by the developer using GitHub Desktop.

---

## Important Files Quick Reference

| File | What it does |
|---|---|
| `pubspec.yaml` | All package versions |
| `build.yaml` | Code-gen config for Riverpod + Drift |
| `analysis_options.yaml` | Linting rules + custom_lint plugin |
| `lib/core/theme/app_colors.dart` | Every design token |
| `lib/core/constants/app_constants.dart` | Magic numbers and string keys |
| `lib/presentation/widgets/mn_bottom_nav.dart` | Floating pill bottom nav — 4 icon-only tabs with 60 px center gap (FAB notch), active `primaryContainer` pill, `context.go` tab switching |
| `lib/presentation/router/app_router.dart` | GoRouter config, `ShellRoute`, `_AppShell` (uses `BottomBar` for hide-on-scroll + amber scroll-to-top icon), `_NavFab` (center notch FAB → new note), `ThemeModeNotifier` |
| `lib/data/datasources/local/app_database.dart` | `@DriftDatabase` — 5 tables, 4 DAOs, FTS5, migrations |
| `lib/data/datasources/local/database_providers.dart` | 6 `keepAlive` providers: `appDatabase`, `syncedNoteRepository` (typed `SyncedNoteRepository`), `noteRepository` (typed `INoteRepository`, delegates to synced), `tagRepository`, `categoryRepository`, `audioRecordRepository` |
| `lib/data/datasources/file/audio_file_storage.dart` | File I/O for audio recordings (create dir, generate path, delete, size) |
| `lib/services/audio/audio_recording_service.dart` | flutter_sound wrapper — record AAC, stream amplitude, playback |
| `lib/services/speech/speech_to_text_service.dart` | speech_to_text wrapper — live dictation with Android timeout recovery |
| `lib/services/auth/firebase_auth_service.dart` | Singleton — `signInAnonymously()` (idempotent). Called from `main.dart`. |
| `lib/services/remote/remote_note_service.dart` | HTTP client for the FastAPI backend — `suggestTags()` + `summariseNote()` (both stub-level; called in Phase 12). Plain Dart class, not a Riverpod provider. Default base URL `http://10.0.2.2:8000/api/v1` (Android emulator loopback). |
| `lib/firebase_options.dart` | STUB (gitignored). Replace by running `flutterfire configure`. |
| `lib/data/datasources/local/converters/type_converters.dart` | `QuillDeltaConverter`, `DateTimeConverter`, `StringListConverter` |
| `lib/data/repositories/remote/firebase_note_repository.dart` | Live Firestore write impl — `insert`/`update`/`archive`/`unarchive`/`delete`/`togglePin` via Firestore set. Reads remain `UnimplementedError`. |
| `lib/data/repositories/synced/synced_note_repository.dart` | Sync wrapper — all standard ops delegate to local; `syncNote(id)` + `syncAllPending()` push to Firestore |
| `firestore.rules` | Firestore security rules (deploy manually in Firebase Console) |
| `lib/presentation/viewmodels/note_list_view_model.dart` | `NoteFilterNotifier` (holds `NoteFilter` — all/category/tag); `NoteListViewModel` watches filter + switches repo stream |
| `lib/presentation/viewmodels/archived_notes_view_model.dart` | `ArchivedNotesViewModel` — `watchArchived()` stream + `restore(id)` + `delete(id)` |
| `lib/presentation/views/archive/archived_notes_screen.dart` | Archive screen — full-screen outside ShellRoute, swipe right = restore, swipe left = delete |
| `web/index.html` | Phone-frame landing page — dark navy, CSS phone bezel, loading overlay, tech chips, GitHub link |
| `web/flutter_bootstrap.js` | Custom Flutter bootstrap — mounts app into `#flutter-host` (phone frame div) via `hostElement` |
| `web/drift_worker.dart` | Drift WASM web worker entry point (`WasmDatabase.workerMainForOpen()`) |
| `web/drift_worker.js` | Compiled JS worker (from `dart compile js -O2 web/drift_worker.dart`) |
| `web/sqlite3.wasm` | Pre-compiled SQLite WASM module (sqlite3-2.9.4, 714 KB) |
| `firebase.json` | Firebase config — `hosting` section: `build/web`, SPA rewrite, WASM MIME, COOP/COEP headers |
| `.firebaserc` | Firebase project alias — `default → modunote-ba654` |
| `MODUNOTE_UI_REFERENCE.md` | Full pixel-level UI spec from Claude Design |
| `progress.md` | Human-readable phase progress log |
| `TESTING.md` | Manual testing checklist — 40 sections, ~175+ checks. Quick smoke test (~50 🔴 critical checks, ~20 min) + full regression (~175+ checks, ~1.5 hr). Section 40 = Firebase sync checks. |

---

## Session Context Log (`session_context.md`)

`session_context.md` lives in the project root and is a **running log for the current session**. It is gitignored — never committed.

**Rule: append to `session_context.md` immediately whenever the user asks you to implement, update, remove, or diagnose/fix a malfunctioning feature or any other change that modifies project functionality.** Record the exact wording of the request plus the date/time. Do not paraphrase.

Format each entry as:

```
[YYYY-MM-DD HH:MM] <exact user request verbatim>
```

Do not wipe or truncate `session_context.md` at any point — entries accumulate across the session so the full request history is available if the context window is compressed.

**Rule: once the user accepts/confirms a feature or change, append the relevant knowledge from that work into the appropriate permanent `.md` file(s).** Use the session_context.md entry for that request as the source of truth for what was done. Target files:

| What was built / decided | Append to |
|---|---|
| New architectural decision or trade-off | `DECISIONS.md` |
| Phase completion or feature milestone | `progress.md` |
| Key facts the next session must know | `THREAD_HANDOFF.md` |
| New manual test steps for the feature | `TESTING.md` |
| New package, route, folder, or convention | `CLAUDE.md` itself |

Write only what is new — do not duplicate content already in the target file. Keep entries concise and factual (no session-specific wording like "in this session we…").

---

## On-boarding Checklist (new dev / new AI session)

0. **Check for `session_context.md`** in the project root. If it exists and is non-empty, read it FIRST before any other file — it contains the verbatim log of every feature/fix request made in the current in-progress session and overrides or extends the permanent docs.
1. Read `CLAUDE.md` (this file) — understand the architecture.
2. Read `progress.md` — know what's been built and what's next.
3. Read `THREAD_HANDOFF.md` — get the most recent session summary and next-phase scope.
4. Read `DECISIONS.md` — all architectural decisions and their rationale.
5. Read `MODUNOTE_UI_REFERENCE.md` — before touching any UI file.
6. Run `flutter pub get` then `dart run build_runner build --delete-conflicting-outputs`. (`shared_preferences` added in Phase 9, `flutter_floating_bottom_bar ^2.0.0` added post-Phase-9, `firebase_core` + `cloud_firestore` + `firebase_auth` added Phase 10, `http ^1.2.0` added Phase 11 — always re-run after a new package.) **Phase 10ext**: run `flutterfire configure` first if `lib/firebase_options.dart` is still the placeholder stub.
7. Run `flutter analyze` — must report 0 issues before writing any code.
8. Run `flutter run` — boots to NoteListScreen with persistent floating nav; amber `+` FAB in nav center taps to open Note Editor; scrolling content hides nav and shows amber up-arrow scroll-to-top; tap mic → recording overlay; tap Tags tab → Tags screen with density bars; tap Settings tab → theme tiles.
9. Ask the developer which phase to proceed with before writing any code.
10. After completing a phase, run the smoke test checks in `TESTING.md` before committing.
11. After completing a phase, run the **Security Pre-Commit Checklist** below before staging anything.

---

## Security Pre-Commit Checklist

Run every item before staging files for commit at the end of any phase or significant change set.

### S1 — Gitignored secrets present on disk (never commit these)
- [ ] `lib/firebase_options.dart` exists locally but is NOT staged (`git ls-files lib/firebase_options.dart` returns nothing)
- [ ] `android/app/google-services.json` exists locally but is NOT staged
- [ ] `android/key.properties` is NOT staged (signing config)
- [ ] `*.jks` / `*.keystore` files are NOT staged
- [ ] No `.env` or `.env.*` files are staged
- [ ] `session_context.md` is NOT staged

### S2 — No hardcoded secrets in source files
- [ ] Run: `git diff --staged | grep -iE "AIza|apiKey|api_key|secretKey|secret_key|private_key|password|bearer |token"` — output must be empty (false positives for field names like `apiKeyProvider` are OK; actual string literals are not)
- [ ] Run: `git ls-files "*.dart" | xargs grep -l "AIza"` — must return no files (Firebase Web API key pattern)
- [ ] No hardcoded base URLs pointing to production servers in committed code (use `AppConstants` or environment variables)

### S3 — Firebase config files
- [ ] `firebase.json` contains only hosting config, COOP/COEP headers, and rewrites — no API keys (App IDs like `1:xxx:android:xxx` are public identifiers, not secrets; acceptable to commit)
- [ ] `.firebaserc` contains only project aliases — acceptable to commit
- [ ] `.firebase/` directory is gitignored (cache/build artifacts — `git ls-files .firebase/` must return nothing after this phase's work)

### S4 — Firestore security rules
- [ ] `firestore.rules` enforces `request.auth != null && request.auth.uid == userId` for user data paths
- [ ] `firestore.rules` has a catch-all `allow read, write: if false` at the bottom
- [ ] Rules have been deployed (manually in Firebase Console or via `firebase deploy --only firestore:rules`)

### S5 — Android signing
- [ ] `android/key.properties` is gitignored — verify `git ls-files android/key.properties` returns nothing
- [ ] No release keystore passwords appear in any `build.gradle` or `build.gradle.kts` file

### S6 — Repository hygiene
- [ ] `build/` directory is NOT staged (Flutter build output)
- [ ] `**/*.g.dart` generated files are NOT staged (Riverpod/Drift code-gen)
- [ ] No large binary files (`.apk`, `.aab`, `.ipa`) are staged
- [ ] `web/sqlite3.wasm` being tracked is acceptable (it is a pre-compiled public binary, not a secret)

### S7 — README / docs
- [ ] No API keys, tokens, or passwords appear in any `.md` file that will be committed
- [ ] Live URLs in READMEs (e.g. Firebase Hosting URL) are intentional and public-safe

**If any S1–S7 item fails: do not commit. Fix the issue first (add to .gitignore, remove from staging, rotate the key if it was already pushed).**

---

SPAWN A VERIFICATION SUBAGENT AFTER THE MAIN TASK FINISHES. SCOPE IT TO ONLY THE DART SOURCE FILES (lib/**/*.dart) THAT WERE ACTUALLY EDITED IN THE CURRENT SESSION — DO NOT PASS ANY .md FILES. THE SUBAGENT MUST READ EACH SCOPED FILE FRESH AND CHECK EACH MANDATORY RULE LINE BY LINE. IT MUST PRODUCE A CHECKLIST TABLE WITH ONE ROW PER RULE, A PASS OR FAIL STATUS, AND EXACT EVIDENCE (QUOTE + LINE NUMBER) FOR EACH ITEM. BLOCK TASK COMPLETION ON ANY FAIL RESULT. RESTRICT THE SUBAGENT TO READ-ONLY TOOLS SO IT CANNOT CHANGE ANYTHING WHILE AUDITING.