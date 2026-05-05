# ModuNote

**ModuNote** is an Android quick-capture ideation app for content creators and people who prefer speaking over typing for journalling. Open the app, tap the FAB, start typing or hit the mic — the note saves itself. No accounts, no syncing delays, no friction.

Built with Flutter using a strict **MVVM + Repository** architecture, a **Drift SQLite** local database with **FTS5 full-text search**, **Riverpod 2** state management with full code generation, and a **flutter_quill** Delta JSON rich text editor. A FastAPI backend and Firebase sync layer are planned for later phases.

This is a portfolio/resume project developed phase-by-phase with documented architectural decisions throughout.

---

## What it does

- **Capture notes instantly** — tap the amber FAB on the home screen, write a title, start typing in the rich text editor. The note auto-saves 800 ms after you stop typing. A small "Saved / Saving…" badge shows the live state.
- **Rich text editing** — the editor supports bold, italic, underline, H1, H2, bulleted lists, numbered lists, checklists, and blockquotes via a pinned formatting toolbar. Content is stored as Quill Delta JSON so it is portable and Firebase-ready.
- **Tags and categories** — each note can have multiple freeform tags and belong to a hierarchical category (adjacency-list tree, max depth 5). Tags are stored both in a normalised join table and as a denormalised JSON column on the note for O(1) ViewModel access.
- **Full-text search** — a SQLite FTS5 virtual table (`notes_fts`) stays in sync with note content via three SQLite triggers (INSERT / UPDATE / BEFORE DELETE). The search screen debounces queries at 300 ms and streams results as note cards.
- **Voice memos** — the editor toolbar has a mic button that will record AAC audio (32 kbps, mono, 16 kHz) and transcribe it using on-device speech recognition. The recording overlay UI is complete; the audio service is wired in Phase 6.
- **Pinning and archiving** — notes can be pinned to the top of the home screen or archived.
- **Offline-first** — the entire app works with zero network access. All data lives in a local SQLite database on the device. Firebase sync is a Phase 10 drop-in swap via the repository interface layer.

---

## Screenshots

> Coming once Phase 9 (final navigation shell and theming) is complete.

---

## Architecture

The project follows a strict four-layer architecture. Each layer only knows about the layer directly below it.

```
View  →  ViewModel  →  Repository Interface  →  Data Source (Drift DAO)
```

**Views** are `ConsumerWidget` or `ConsumerStatefulWidget`. They watch ViewModel providers and call notifier methods. They never touch a repository or a DAO.

**ViewModels** are Riverpod `AsyncNotifier` or `Notifier` classes generated from `@riverpod` annotations. They hold UI state and call methods on repository *interfaces*. They never import `AppDatabase` or any Drift type.

**Repository interfaces** (`INoteRepository`, `ITagRepository`, `ICategoryRepository`) are abstract Dart classes. The local Drift implementations live in `data/repositories/local/`. Phase 10 will add Firebase implementations that swap in without touching any ViewModel or View.

**Data sources** are Drift DAOs (`NotesDao`, `TagsDao`, `CategoriesDao`, `AudioRecordsDao`) registered on `AppDatabase`. They return typed streams and futures. Raw Drift/SQLite exceptions are caught here and re-thrown as `AppException` subtypes before reaching the ViewModel layer.

### Folder structure

```
lib/
├── core/
│   ├── constants/          # AppConstants — audio config, limits, string keys
│   ├── errors/             # Sealed AppException hierarchy (5 subtypes)
│   ├── extensions/         # StringExtensions — isBlank, normalised, truncate
│   ├── utils/              # UuidGenerator — wraps uuid package
│   └── theme/              # AppColors (34 tokens), AppTypography, AppTheme
│
├── data/
│   ├── models/             # Note, Tag, Category, AudioRecord — immutable + Equatable
│   ├── repositories/
│   │   ├── interfaces/     # INoteRepository, ITagRepository, ICategoryRepository
│   │   └── local/          # Drift implementations of each interface
│   └── datasources/
│       └── local/
│           ├── tables/     # 5 Drift table definitions
│           ├── daos/       # 4 DAOs (notes, tags, categories, audio records)
│           ├── converters/ # QuillDeltaConverter, DateTimeConverter, StringListConverter
│           ├── app_database.dart       # @DriftDatabase — 5 tables, FTS5, migrations
│           └── database_providers.dart # Riverpod providers for DB + 3 repositories
│
├── presentation/
│   ├── viewmodels/         # NoteListVM, NoteEditorVM, TagListVM, CategoryTreeVM, SearchVM
│   ├── views/
│   │   ├── note_list/      # NoteListScreen
│   │   ├── note_editor/    # NoteEditorScreen
│   │   ├── search/         # SearchScreen
│   │   ├── tags/           # TagsScreen (Phase 7)
│   │   └── settings/       # SettingsScreen (Phase 9)
│   ├── widgets/            # MNNoteCard, MNSearchField, MNEditorToolbar, MNTagRow
│   └── router/             # GoRouter config, AppRoutes constants, ThemeModeNotifier
│
└── services/
    ├── audio/              # AudioRecordingService (Phase 6)
    └── speech/             # SpeechToTextService (Phase 6)
```

---

## Data models

### Note
```
id            String        UUID v4
title         String
content       Map<String, dynamic>   Quill Delta JSON
categoryId    String?
tagIds        List<String>  denormalised JSON column for O(1) ViewModel reads
isPinned      bool
isArchived    bool
createdAt     DateTime
updatedAt     DateTime
syncStatus    SyncStatus    enum: local | synced | pending | conflict
```

### Tag
```
id        String    UUID v4
name      String    always lowercase — normalised on write
createdAt DateTime
```
Many-to-many with Note via `NoteTagsTable` join table. Tag names have a UNIQUE constraint at the database level.

### Category
```
id         String    UUID v4
name       String
parentId   String?   null = root category
sortOrder  int
createdAt  DateTime
```
Adjacency-list hierarchy. Max depth 5. `CategoriesDao` exposes `findRoots()` and `findChildren(parentId)` separately.

### AudioRecord
```
id               String     UUID v4
noteId           String     foreign key → Note
filePath         String     absolute path under getApplicationDocumentsDirectory()/audio_notes/
durationMs       int
fileSizeBytes    int
codec            String     always 'aac'
transcribedText  String?    set after speech_to_text completes
createdAt        DateTime
```

---

## Database

`AppDatabase` is a Drift `@DriftDatabase` class with 5 tables, 4 DAOs, and a full-text search setup:

- **FTS5 virtual table** (`notes_fts`) mirrors note title and content text
- **3 SQLite triggers** keep the FTS index in sync automatically — INSERT populates it, UPDATE refreshes it, BEFORE DELETE removes the row
- **TypeConverters** handle serialisation transparently: `QuillDeltaConverter` (Delta JSON ↔ SQLite text), `DateTimeConverter` (DateTime ↔ epoch ms), `StringListConverter` (List\<String\> ↔ JSON array)
- **MigrationStrategy** with `onCreate` is in place for future `onUpgrade` migrations

All 4 data-layer Riverpod providers use `keepAlive: true` so the database connection is never dropped during the app session. `ref.onDispose(db.close)` ensures clean shutdown.

---

## Tech stack

| Concern | Package | Version |
|---|---|---|
| State management | flutter_riverpod | ^2.5.1 |
| Provider code-gen | riverpod_annotation + riverpod_generator | ^2.3.5 / ^2.4.3 |
| Local database | drift + drift_flutter | ^2.18.0 / ^0.2.1 |
| Database code-gen | drift_dev | ^2.18.0 |
| Navigation | go_router | ^14.2.0 |
| Rich text editor | flutter_quill | ^10.8.5 |
| Audio recording/playback | flutter_sound | ^9.2.13 |
| On-device voice-to-text | speech_to_text | ^7.0.0 |
| Fonts | google_fonts | ^6.2.1 |
| Model equality | equatable | ^2.0.5 |
| UUID generation | uuid | ^4.4.0 |
| File paths | path_provider + path | ^2.1.3 / ^1.9.0 |

---

## Design system

The app uses a custom Material 3 theme built on top of `ColorScheme.fromSeed`. All design tokens are defined as static `Color` constants in `lib/core/theme/app_colors.dart` — nothing is hardcoded anywhere else.

| Token | Light | Dark |
|---|---|---|
| Primary | `#5B4EFF` | `#B7AFFF` |
| Accent / FAB | `#F59E0B` | `#F59E0B` |
| Background | `#FEFBFF` | `#1C1B2E` |
| Card surface | `#FFFFFF` | `#232238` |
| Surface container | `#F3F0FF` | `#2C2B42` |
| Record red | `#E5484D` | `#FF6369` |

Typefaces: **Plus Jakarta Sans** (headings, weight 700–800) and **Inter** (body, weight 400–600), loaded via `google_fonts`.

---

## Getting started

**Prerequisites:** Flutter ≥ 3.22.0 · Dart ≥ 3.3.0 · Android device or emulator (iOS not configured)

```bash
# 1. Install dependencies
flutter pub get

# 2. Run code generation (Riverpod providers + Drift table classes)
dart run build_runner build --delete-conflicting-outputs

# 3. Verify — should report 0 issues
flutter analyze

# 4. Run
flutter run
```

A SQLite database is created automatically on first launch. The home screen will show an empty state until notes are created.

---

## Phase progress

| # | Phase | Status |
|---|---|---|
| 1 | Project setup — folder structure, theme, models, router scaffold | ✅ Complete |
| 2 | Data layer — Drift schema, DAOs, TypeConverters, local repositories | ✅ Complete |
| 3 | State management — all 5 Riverpod ViewModels wired to repositories | ✅ Complete |
| 4 | Note list screen — pinned/recent sections, skeleton loading, search bar, FAB | ✅ Complete |
| 5 | Note editor — Quill editor, toolbar, tag row, recording overlay UI | ✅ Complete |
| 6 | Voice-to-text and audio recording/playback | ⬜ Not started |
| 7 | Tags — freeform entry, autocomplete, tag management screen | ⬜ Not started |
| 8 | Categories — hierarchical folder tree picker | ⬜ Not started |
| 9 | Navigation shell — GoRouter ShellRoute, persistent bottom nav, theme toggle | ⬜ Not started |
| 10 | Firebase preparation — auth stub, Firestore repository implementation | ⬜ Not started |
| 11 | Backend — FastAPI + PostgreSQL + SQLAlchemy async API scaffolding | ⬜ Not started |
| 12 | AI features — auto-tagging, note summarisation | ⬜ Not started |

Architectural decisions for every completed phase are documented in [`DECISIONS.md`](DECISIONS.md).
