# CLAUDE.md — ModuNote AI Agent Context

> This file is the single source of truth for any AI agent (Claude or otherwise) working on this codebase.
> Read this before writing, editing, or reviewing any file in this project.
> Keep this file updated at the end of every phase.

---

## Project Overview

**App name**: ModuNote
**Purpose**: Quick-capture ideation app for content creators and people who prefer speaking over typing for journalling.
**Platform**: Android (Flutter). iOS deferred.
**Developer profile**: Junior Flutter developer. Background in Python / FastAPI / PostgreSQL. Has prior Flutter MVVM experience (VocalNote app).

---

## Architecture at a Glance

| Layer | Pattern | Key tech |
|---|---|---|
| State management | MVVM + Riverpod 2 | `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` |
| Local DB | Repository pattern | `drift` v2, `drift_flutter`, `drift_dev` |
| Navigation | Declarative | `go_router` v14 |
| Rich text | Delta JSON | `flutter_quill` v10 |
| Audio | Record + playback | `flutter_sound` v9 (AAC 32kbps mono 16kHz) |
| Voice-to-text | On-device | `speech_to_text` v7 |
| Fonts | Google Fonts | Plus Jakarta Sans (headings) + Inter (body) |
| UUID | v4 | `uuid` v4 |

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
│   │   └── local/                     # Drift implementations (Phase 2)
│   └── datasources/
│       ├── local/                     # Drift DAOs + AppDatabase (Phase 2)
│       └── file/                      # AudioFileStorage (Phase 6)
│
├── services/
│   ├── speech/speech_to_text_service.dart   # Phase 6
│   └── audio/audio_recording_service.dart   # Phase 6
│
└── presentation/
    ├── viewmodels/                    # AsyncNotifier classes (Phase 3+)
    ├── views/
    │   ├── note_list/note_list_screen.dart
    │   ├── note_editor/note_editor_screen.dart
    │   ├── search/search_screen.dart
    │   ├── tags/tags_screen.dart
    │   └── settings/settings_screen.dart
    ├── widgets/                       # Shared widgets — mn_note_card.dart, mn_search_field.dart, mn_editor_toolbar.dart, mn_tag_row.dart (Phase 4+)
    └── router/
        ├── app_router.dart            # GoRouter config, routerProvider, ThemeModeNotifier
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

| Route | Screen |
|---|---|
| `/` | NoteListScreen |
| `/note/new` | NoteEditorScreen (new) |
| `/note/:id` | NoteEditorScreen (edit) |
| `/search` | SearchScreen |
| `/tags` | TagsScreen |
| `/settings` | SettingsScreen |

Phase 9 will wrap these in a `ShellRoute` for the persistent bottom nav bar.

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
| 6 | Voice-to-text + audio recording/playback | ⬜ Not started |
| 7 | Tags (freeform + autocomplete) | ⬜ Not started |
| 8 | Categories (hierarchical folder tree) | ⬜ Not started |
| 9 | Navigation + theming (GoRouter shell, M3 bottom nav) | ⬜ Not started |
| 10 | Firebase preparation layer (stubs, SyncStatus) | ⬜ Not started |
| 11 | Backend API scaffolding (FastAPI stubs) | ⬜ Not started |
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
| `lib/presentation/router/app_router.dart` | Routes + ThemeModeNotifier |
| `lib/data/datasources/local/app_database.dart` | `@DriftDatabase` — 5 tables, 4 DAOs, FTS5, migrations |
| `lib/data/datasources/local/database_providers.dart` | Riverpod providers for DB + 3 repositories (all `keepAlive: true`) |
| `lib/data/datasources/local/converters/type_converters.dart` | `QuillDeltaConverter`, `DateTimeConverter`, `StringListConverter` |
| `MODUNOTE_UI_REFERENCE.md` | Full pixel-level UI spec from Claude Design |
| `progress.md` | Human-readable phase progress log |

---

## On-boarding Checklist (new dev / new AI session)

1. Read `CLAUDE.md` (this file) — understand the architecture.
2. Read `progress.md` — know what's been built and what's next.
3. Read `THREAD_HANDOFF.md` — get the most recent session summary and next-phase scope.
4. Read `MODUNOTE_UI_REFERENCE.md` — before touching any UI file.
5. Run `flutter pub get` then `dart run build_runner build --delete-conflicting-outputs`.
5. Run `flutter run` — should boot to NoteListScreen (Phase 4 — full note list UI).
6. Ask the developer which phase to proceed with before writing any code.
