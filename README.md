# ModuNote

**ModuNote** is an Android note-taking app built for a solo content creator who needs to capture ideas the moment they happen. Open the app, tap the FAB, start typing — the note saves itself. No accounts, no syncing delays, no friction.

Built with Flutter using a strict **MVVM + Repository** architecture, a **Drift SQLite** local database with **FTS5 full-text search**, **Riverpod 2** state management with full code generation, a **flutter_quill** Delta JSON rich text editor, and **Firebase** for anonymous auth and Firestore sync. A FastAPI + PostgreSQL backend is scaffolded for Phase 12 AI features.

This is a portfolio/resume project developed phase-by-phase with documented architectural decisions throughout.

> **Live web demo →** [modunote-ba654.web.app](https://modunote-ba654.web.app) — Flutter Web build hosted on Firebase Hosting, rendered inside a Pixel 8 phone-frame mockup. See [Web Portfolio Preview](#web-portfolio-preview) below.

<p align="center">
  <img src="image_17.png" alt="ModuNote web preview" width="420" />
</p>

---

## What it does

- **Capture notes instantly** — tap the amber FAB on the home screen, write a title, start typing in the rich text editor. The note auto-saves 800 ms after you stop typing. A small "Saved / Saving…" badge shows the live save state.
- **Rich text editing** — bold, italic, underline, H1, H2, bulleted lists, numbered lists, checklists, and blockquotes via a pinned formatting toolbar. Content is stored as Quill Delta JSON — portable and Firebase-ready.
- **Tags and categories** — each note can carry multiple freeform tags and belong to a hierarchical category (adjacency-list tree, max depth 5). Tags are stored in a normalised join table and as a denormalised JSON column on the note for O(1) ViewModel reads. The tag picker in the editor shows all existing tags on open for one-tap selection, with prefix search as you type. A filter chip bar on the home screen filters by category or tag; selecting a parent category includes notes from all descendant categories.
- **Full-text search** — a SQLite FTS5 virtual table (`notes_fts`) stays in sync via three SQLite triggers. The search screen debounces at 300 ms and streams results live.
- **Voice memos** — the editor toolbar has a mic button that records AAC audio (32 kbps, mono, 16 kHz) and transcribes it using on-device speech recognition. Live amplitude waveform and transcript preview appear while recording.
- **Swipe actions on note cards** — swipe left to archive, swipe right to toggle pin. Cards spring back after the action fires so the list updates without jarring dismissal animations. Long-press (or the ⋮ button in the editor) opens a contextual bottom sheet for pin, archive, or delete.
- **Archive screen** — accessible from Settings; lists all archived notes with swipe-right to restore or swipe-left to permanently delete (with confirmation).
- **Pinning** — pinned notes float to a separate "Pinned" section above the recent list; unpinning returns them to the recency order.
- **Theme** — light, dark, and system modes with a live preview tile picker in Settings. Mode persists across restarts via SharedPreferences.
- **Firebase sync** — anonymous sign-in on app launch (silent, no account required). Every create/update/archive/delete is queued as `SyncStatus.pending` and pushed to Firestore on note-close and on app-background events. A coloured sync badge on each card shows local / synced / pending / conflict state.
- **Offline-first** — the entire app works with zero network access. Firebase sync is a drop-in addition via the repository interface layer, not a dependency of the core experience.

---

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
│   │   ├── local/          # Drift implementations
│   │   ├── remote/         # FirebaseNoteRepository (Firestore writes)
│   │   └── synced/         # SyncedNoteRepository — wraps local + remote
│   └── datasources/
│       ├── local/
│       │   ├── tables/     # 5 Drift table definitions
│       │   ├── daos/       # 4 DAOs (notes, tags, categories, audio records)
│       │   ├── converters/ # QuillDeltaConverter, DateTimeConverter, StringListConverter
│       │   ├── app_database.dart       # @DriftDatabase — 5 tables, FTS5, v2 migration
│       │   └── database_providers.dart # 6 keepAlive Riverpod providers
│       └── file/           # AudioFileStorage — create dir, generate path, delete
│
├── presentation/
│   ├── viewmodels/         # NoteListVM, NoteEditorVM, TagListVM, CategoryTreeVM,
│   │                       # SearchVM, ArchivedNotesVM, NoteFilterNotifier
│   ├── views/
│   │   ├── note_list/      # NoteListScreen — swipe cards, filter chip bar
│   │   ├── note_editor/    # NoteEditorScreen — Quill, voice, ⋮ options sheet
│   │   ├── search/         # SearchScreen
│   │   ├── tags/           # TagsScreen — density bars, tag management
│   │   ├── archive/        # ArchivedNotesScreen — restore / delete
│   │   └── settings/       # SettingsScreen — theme tiles, archive entry
│   ├── widgets/            # MNNoteCard, MNSearchField, MNEditorToolbar,
│   │                       # MNTagRow, MNCategoryPickerSheet, MNBottomNav
│   └── router/             # GoRouter ShellRoute, _AppShell, ThemeModeNotifier
│
└── services/
    ├── audio/              # AudioRecordingService — flutter_sound AAC wrapper
    ├── speech/             # SpeechToTextService — on-device, Android timeout recovery
    ├── auth/               # FirebaseAuthService — silent anonymous sign-in
    └── remote/             # RemoteNoteService — HTTP client for FastAPI (Phase 12)
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
| Firebase (auth + Firestore) | firebase_core + cloud_firestore + firebase_auth | ^3.x |
| Floating bottom nav | flutter_floating_bottom_bar | ^2.0.0 |
| Theme persistence | shared_preferences | ^2.3.0 |
| Remote API client | http | ^1.2.0 |
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
| 3 | State management — all Riverpod ViewModels wired to repositories | ✅ Complete |
| 4 | Note list screen — pinned/recent sections, skeleton loading, search bar, FAB | ✅ Complete |
| 5 | Note editor — Quill editor, toolbar, tag row, recording overlay UI | ✅ Complete |
| 6 | Voice-to-text + audio recording/playback — AAC, amplitude waveform, transcription | ✅ Complete |
| 7 | Tags — freeform entry, autocomplete, tag management screen with density bars | ✅ Complete |
| 8 | Categories — hierarchical folder tree picker with re-parent-on-delete | ✅ Complete |
| 9 | Navigation + theming — GoRouter ShellRoute, hide-on-scroll bottom nav, theme persistence | ✅ Complete |
| 10 | Firebase — anonymous auth, Firestore write layer, SyncStatus badge, AppLifecycle sync | ✅ Complete |
| 11 | Backend API scaffolding — FastAPI + PostgreSQL + SQLAlchemy async, stub AI endpoints | ✅ Complete |
| 11.5 | Bug fixes + UX — swipe actions, note options sheet, archive screen, filter chips, system theme | ✅ Complete |
| 11.6 | Bug fixes — hierarchical category filtering, filter bar empty state, editor category sync, tag browsing | ✅ Complete |
| 12 | AI features — auto-tagging, note summarisation via FastAPI | ⬜ Not started |
| W | Web portfolio preview — Flutter Web + WASM SQLite, Pixel 8 phone-frame landing page, Firebase Hosting | ✅ Complete |

Architectural decisions for every completed phase are documented in [`DECISIONS.md`](modunote/DECISIONS.md).

---

## Web portfolio preview

**Live → [modunote-ba654.web.app](https://modunote-ba654.web.app)**

The Flutter app runs in a browser inside a CSS Pixel 8 phone-frame landing page. Powered by Flutter Web (CanvasKit) + WASM SQLite (via a Drift web worker), hosted on Firebase Hosting with COOP/COEP headers for `SharedArrayBuffer` support.

**Implementation highlights:**
- Custom `flutter_bootstrap.js` mounts the app into `#flutter-host` inside the phone frame via `hostElement`
- WASM SQLite runs in a dedicated web worker (`drift_worker.dart` compiled with `dart compile js -O2`)
- `AudioFileStorage` uses conditional exports — native `dart:io` on Android, no-op stub on web
- Audio recording gracefully disabled on web with an informational snackbar; all other features work fully
- Real-time loading progress bar driven by `PerformanceObserver` milestones + Flutter custom events

**Web feature scope:**

| Feature | Web status |
|---|---|
| Notes CRUD | ✅ Full |
| Rich text editor | ✅ Full |
| Tags + categories | ✅ Full |
| Full-text search | ✅ Full |
| Firebase sync | ✅ Full |
| Theme switching | ✅ Full |
| Voice-to-text | ✅ Full (Chrome Web Speech API) |
| Audio recording | ⚠️ Gracefully disabled (flutter_sound AAC not supported on web) |
