# ModuNote

A quick-capture ideation app for solo content creators (YouTube / Instagram). Built with Flutter for Android. Designed for people who prefer speaking over typing — capture ideas, voice notes, and rich text in seconds.

---

## Tech Stack

| Layer | Technology |
|---|---|
| State management | Flutter Riverpod 2 (code-gen + `@riverpod`) |
| Local database | Drift v2 (SQLite ORM, FTS5, migrations) |
| Navigation | GoRouter v14 (declarative, URL-based) |
| Rich text | flutter_quill v10 (Quill Delta JSON) |
| Audio recording | flutter_sound v9 (AAC 32kbps mono 16kHz) |
| Voice-to-text | speech_to_text v7 (on-device, no API key) |
| Fonts | Plus Jakarta Sans + Inter (google_fonts) |

## Architecture

MVVM pattern. ViewModels (`AsyncNotifier` / `Notifier`) depend on **repository interfaces** only. Views (`ConsumerWidget`) depend on ViewModels only. Drift DAOs never leak above the repository layer.

```
lib/
├── core/          constants, errors, extensions, theme
├── data/
│   ├── models/             immutable Equatable domain models
│   ├── repositories/       interfaces + Drift implementations
│   └── datasources/        Drift tables/DAOs/AppDatabase, AudioFileStorage
├── services/               AudioRecordingService, SpeechToTextService
└── presentation/
    ├── viewmodels/         AsyncNotifier classes
    ├── views/              one folder per screen
    ├── widgets/            shared widgets
    └── router/             GoRouter config
```

## Phase Status

| # | Phase | Status |
|---|---|---|
| 1 | Project setup & folder structure | ✅ Complete |
| 2 | Data layer (Drift schema, DAOs, Repositories) | ✅ Complete |
| 3 | State management (Riverpod providers, ViewModels) | ✅ Complete |
| 4 | Note list screen | ✅ Complete |
| 5 | Note editor screen (Quill) | ✅ Complete |
| 6 | Voice-to-text + audio recording/playback | ✅ Complete |
| 7 | Tags (freeform + autocomplete) | ⬜ Not started |
| 8 | Categories (hierarchical folder tree) | ⬜ Not started |
| 9 | Navigation + theming (GoRouter shell, M3 bottom nav) | ⬜ Not started |
| 10 | Firebase preparation layer | ⬜ Not started |
| 11 | Backend API scaffolding (FastAPI) | ⬜ Not started |
| 12 | AI features (auto-tagging, summarisation) | ⬜ Not started |

## Getting Started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze      # must report 0 issues
flutter run          # Android device or emulator required
```

First launch: empty state on Home screen. Tap the amber `+` FAB to create a note. Tap the mic icon in the editor to record voice with live transcription.

## Key Documentation

| File | Purpose |
|---|---|
| `CLAUDE.md` | Architecture overview, conventions, phase status — read first |
| `DECISIONS.md` | Every architectural decision with full rationale |
| `progress.md` | Phase-by-phase file log and bug history |
| `THREAD_HANDOFF.md` | Latest session summary + next-phase scope |
| `TESTING.md` | Manual testing checklist (smoke test + full regression) |
| `MODUNOTE_UI_REFERENCE.md` | Pixel-level UI specification |

## Platform

Android only. iOS is non-destructively addable later. Min API 21 (Android 5.0+).

