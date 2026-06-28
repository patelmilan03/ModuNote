# ModuNote — Project Status & Handoff

> Single source of truth for "what's done and what's next." Merges the former `progress.md` (phase-by-phase log) and `THREAD_HANDOFF.md` (session handoff). Updated at the end of every phase. Read this before starting any new phase.

> ⚠️ **Git rule**: Claude may create and edit files on the local machine freely. Claude must never run `git commit`, `git push`, `git pull`, `git reset`, or any git command that changes repository state or interacts with GitHub. All commits and pushes are handled exclusively by the developer using GitHub Desktop.

---

## Project Identity

| Field | Value |
|---|---|
| App name | ModuNote |
| Flutter package | `modunote` |
| App ID | `com.modunote.app` |
| Platform | Android (iOS deferred) |
| Min Dart SDK | 3.3.0 |
| Min Flutter | 3.22.0 |
| Started | Phase 1 |

---

## Phase Status

| # | Phase | Status | Notes |
|---|---|---|---|
| 1 | Project setup & folder structure | ✅ **Complete** | See details below |
| 2 | Data layer (Drift schema, DAOs, Repositories) | ✅ **Complete** | See details below |
| 3 | State management (Riverpod providers, base ViewModels) | ✅ **Complete** | See details below |
| 4 | Note list screen | ✅ **Complete** | See details below |
| 5 | Note editor screen (Quill) | ✅ **Complete** | See details below |
| 6 | Voice-to-text + audio recording/playback | ✅ **Complete** | See details below |
| 7 | Tags (freeform + autocomplete) | ✅ **Complete** | See details below |
| 8 | Categories (hierarchical folder tree) | ✅ **Complete** | See details below |
| 9 | Navigation + theming (GoRouter shell, M3 bottom nav) | ✅ **Complete** | See details below |
| 10 | Firebase preparation layer | ✅ **Complete** | See details below |
| 11 | Backend API scaffolding (FastAPI) | ✅ **Complete** | See details below |
| 11.5 | Bug fixes + UX features (swipe cards, note options, system theme, archive screen, filter bar) | ✅ **Complete** | See details below |
| W | Web Portfolio Preview — Flutter Web build + phone-frame landing page + Firebase Hosting deploy | ✅ **Complete** | See details below |
| 11.6 | Bug fixes — hierarchical category filtering, filter-bar empty state, editor category sync, tag browsing in editor | ✅ **Complete** | See "Current Status" below |
| 12 | AI features — Groq writing assistant → RAG QnA → observability → deployment (4-stage roadmap) | 🟡 **In progress** | See `DECISIONS.md` Phase 12 + `PHASE_12_PLAN.md` |

> **Chronological order of recent work:** Phase 11.5 → Phase W → Phase 11.6 → (Phase 12 next). The "W" label sorts oddly in the table but was completed between 11.5 and 11.6.

---

## Current Status & Next Phase

**Current state (as of 2026-06-22):** Feature-complete through **Phase 11.6 + Phase W**; **Phase 12 Stage 1 (AI writing assistant) complete** (Groq via FastAPI). `flutter analyze` = **0 issues**. Live web demo: **https://modunote-ba654.web.app**

**Deployment (pulled forward):** to test AI on a physical device without the laptop, the API is deployed early on **Render free tier** (no credit card; cold start defeated with a keep-warm `/health` pinger) with single static `X-API-Key` auth. Code + runbook done (`modunote-api/DEPLOY.md`, `render.yaml`, `Dockerfile`); Flutter reads `API_BASE_URL`+`API_KEY` via `--dart-define`. **Pending developer step**: create the Render service from `render.yaml` + add the pinger. See `DECISIONS.md` D12.6.

### Voice/VTT redesign — live build tracker (✅ ALL STEPS COMPLETE 2026-06-22)
> Per-step status so the work can resume cleanly across token limits. Full spec is in `session_context.md` (2026-06-22 "Voice/VTT editor redesign").
> **Foundation ✅ DONE**: `AudioRecordingService` playback engine (`seekTo`/pause/resume + player progress sub); backend `POST /api/v1/notes/transcribe` (Groq Whisper) + `RemoteNoteService.transcribe` pending in Step C.

- ✅ **Step C — VTT wiring** *(DONE 2026-06-22)*: `RemoteNoteService.transcribe()` (multipart → `/notes/transcribe`); `_stopRecording` uses on-device STT, falls back to a Whisper upload when empty, stores on `AudioRecord.transcribedText`, no longer inserts into the note body; removed `_insertTranscriptAtCursor`. `flutter analyze` = 0.
- ✅ **Step D — Voice panel widget** *(DONE 2026-06-22)*: `_VoicePanel` (play/pause + seek bar + `current:total` timers + record button + one-at-a-time carousel; expand → transcript + Paraphrase opens the AI sheet via `_AiToolsSheet.contentOverride` + Insert-into-note + red-trash delete). Replaced `_AudioClipsRow`/`_AudioClipChip`. `_RecordingOverlay` kept for live recording feedback. `flutter analyze` = 0.
- ✅ **Step E — Editor layout** *(DONE 2026-06-22)*: tags/category row (+ suggest banner) moved to the top under the title; bottom swaps `MNEditorToolbar` (keyboard up) ↔ `_VoicePanel` (keyboard down) via `MediaQuery.viewInsets.bottom`; removed `_MicButton` from `MNTagRow`. `flutter analyze` = 0.
- ✅ **Step F — Delete confirm + Settings** *(DONE 2026-06-22)*: `audioDeleteConfirm` SharedPreferences-backed `@riverpod` pref (default ask) in `audio_pref_view_model.dart`; red-trash delete → confirm dialog with "Don't ask again" checkbox; `_VoiceNotesCard` Settings toggle to re-enable. `flutter analyze` = 0. **Voice/VTT redesign COMPLETE.**

**Firebase:** Live. `flutterfire configure` has already been run on this machine — `lib/firebase_options.dart` holds real credentials for project `modunote-ba654` (gitignored, not the placeholder stub). Anonymous sign-in + Firestore sync work. No manual Firebase setup is needed here; a fresh clone on a new machine must run `flutterfire configure` first.

### Phase 11.6 — Bug fixes (most recent completed work) ✅
- **Hierarchical category filtering** — selecting a parent category now shows notes from all descendant categories. Added `watchByCategoryIds(List<String>)` through `NotesDao` → `INoteRepository` → all three impls (Local / Firebase stub / Synced); `NoteListViewModel._collectDescendants()` resolves the subtree client-side from the category adjacency list, then calls `watchByCategoryIds`.
- **Filter-bar empty state** — new `_FilteredEmptyState` (`ConsumerWidget`) keeps the filter chip bar visible and shows "No notes in X" when a tag/category filter returns zero notes. Previously the whole tags/categories tray vanished. `_EmptyState` is now gated on `filter.type == NoteFilterType.all`.
- **Editor category sync** — `_onCategoryTap` now calls `_syncCurrentNote()` after `setCategory()`, so the chosen category is reflected immediately instead of only after closing and reopening the editor.
- **Tag browsing in editor** — the `_TagInputSheet` now watches `tagListViewModelProvider` and lists all existing tags (excluding those already on the note) when the field is empty, switching to prefix-filtered results as you type. Previously it only offered to create a new tag.

### Next phase — Phase 12: AI features (in planning)
Direction locked: **full 4-stage roadmap**, first feature **via the FastAPI backend** (`modunote-api/`), provider **Groq** (switched from Gemini on 2026-06-22 — Gemini's free tier blocked testing; see `DECISIONS.md` D12.2).

1. **Stage 1 — Writing assistant** ✅ *complete (2026-06-22)*: Groq-powered Improve / Humanize / Paraphrase / Format-as-script / Critique + Summarise, tag-aware. Flutter (`RemoteNoteService`) → FastAPI → Groq; never blocks save.
   - ✅ Backend (`modunote-api/`): `services/ai_service.py` (Groq `AsyncGroq`), AI models in `models/note.py`, live `/api/v1/notes/{id}/{assist,tags/suggest,summary}`. **Developer confirmed it works** with a real `GROQ_API_KEY`.
   - ✅ Flutter: `quill_extensions.dart` (Delta→plaintext), `RemoteNoteService.assist` + `existingTags`, `remoteNoteServiceProvider`; editor UI — `_TagSuggestBanner` (auto-suggest once when content ≥15 chars & untagged, dismissible) + `_AiToolsSheet` from the ⋮ "AI assist" (Insert / Replace / Copy; Summarise → top blockquote). `flutter analyze` = 0.
   - 🟡 **IN PROGRESS**: Stage 2 — RAG QnA. Decisions locked 2026-06-27 (D12.7). See the live build tracker below + `PHASE_12_PLAN.md` Stage 2.
2. **Stage 2 — RAG QnA**: ingest notes tagged study/notes/research → chunk → embed (**hosted Jina `jina-embeddings-v2-base-en`, 768-dim** — D12.7, since Groq has no embeddings and the Render free dyno can't fit local PyTorch) → **pgvector on Supabase** → retrieval-augmented answers with citations. Requires pushing plain-text note content to the backend (the one new sync design).
3. **Stage 3 — Observability & evals**: Langfuse tracing, Sentry error monitoring, RAGAS / LLM-as-judge evals, light guardrails (start with Pydantic + basic checks).
4. **Stage 4 — Production deployment** (scope = "deploy," not "billed SaaS"): small VM + Caddy (auto-TLS) + GitHub Actions CI/CD + monitoring.

Full decisions and rationale live in **`DECISIONS.md` → Phase 12**. The detailed, step-by-step build spec for all four stages (with per-stage task checklists to tick as you go) is in **`PHASE_12_PLAN.md`** — the standing plan any new thread follows.

### Phase 12 Stage 2 — RAG QnA — live build tracker (🟡 IN PROGRESS, started 2026-06-27)
> Per-step begun/done status so work resumes cleanly across token limits. Decisions: D12.7 (Jina 768-dim hosted embeddings, Supabase pgvector, `study/notes/research` sync tags, Home-card → `/qna`). Backend lives in the separate gitignored repo `../modunote-api`. ⬜ = not started, 🔨 = in progress, ✅ = done.
>
> **Status: STAGE 2 VERIFIED END-TO-END (local). `flutter analyze` = 0; backend RAG pipeline confirmed working against live Supabase + Jina + Groq.** On 2026-06-27 the developer created a Supabase project; `alembic upgrade head` created the `vector` extension + `documents`/`chunks` tables + HNSW cosine index; a programmatic smoke test indexed a note (Jina embedding → pgvector) and answered a question (cosine top-k → Groq) with a correct citation, then deindexed. SSL fix required (see below). **Only remaining: set `DATABASE_URL` + `JINA_API_KEY` in the Render dashboard for the deployed/prod path.** Routes: `POST /api/v1/index/notes`, `DELETE /api/v1/index/notes/{note_id}`, `POST /api/v1/qna`.
>
> **SSL note:** Supabase's TLS cert chain trips default verification ("self-signed certificate in certificate chain"). `db/session.py` + `alembic/env.py` `_connect_args()` use an encrypted-but-**unverified** SSL context (`check_hostname=False`, `CERT_NONE`) for any non-local host. Traffic stays encrypted; acceptable for this single-user app.

Backend (`modunote-api/`):
- ✅ **S2-B1 — Deps + config** *(2026-06-27)*: `asyncpg==0.30.0` + `pgvector==0.3.6` + `tiktoken==0.8.0` in `requirements.txt`; `config.py` + `.env.example` + `render.yaml` add `jina_api_key`, `jina_model=jina-embeddings-v2-base-en`, `embed_dim=768`, `rag_top_k=5`, `rag_index_tags=[study,notes,research]`; `DATABASE_URL` → Supabase (direct conn note added).
- ✅ **S2-B2 — Runtime DB session** *(2026-06-27)*: `db/session.py` (async engine + `async_sessionmaker` + `get_session` dep; auto-SSL for non-local hosts). First DB-connected code in the backend.
- ✅ **S2-B3 — Models** *(2026-06-27)*: `db/models.py` `Document` + `Chunk` (`embedding Vector(768)`, FK cascade); pydantic schemas in `models/rag.py` (`IndexNoteRequest/Response`, `QnaRequest`, `Citation`, `QnaResponse`).
- ✅ **S2-B4 — Alembic migration** *(2026-06-27)*: `alembic/versions/0001_rag_tables.py` — `CREATE EXTENSION IF NOT EXISTS vector`, `documents` + `chunks` tables, **HNSW cosine** index (`vector_cosine_ops`) on `embedding`. Hand-written (no live DB needed to generate).
- ✅ **S2-B5 — Embedding service** *(2026-06-27)*: `services/embedding_service.py` — Jina API via `httpx` (`embed_documents` / `embed_query`).
- ✅ **S2-B6 — RAG service** *(2026-06-27)*: `services/rag_service.py` — chunk (`tiktoken` cl100k, ~600 tok / 100 overlap) → embed → upsert; `deindex_note`; cosine top-k retrieval; context block + citations; empty-retrieval guard. RAG prompt added to `ai_service.rag_answer` (all Groq prompts in one file).
- ✅ **S2-B7 — Endpoints** *(2026-06-27)*: `routers/rag.py` — `POST /index/notes` (empty content → deindex), `DELETE /index/notes/{note_id}` (204), `POST /qna`; included in `main.py`. Errors → 502 (provider/embedding/DB), no stack leaks.
- ✅ **S2-B8 — Backend smoke (local)** *(2026-06-27)*: Supabase `DATABASE_URL` + `JINA_API_KEY` set in `.env`; `alembic upgrade head` created extension + tables + HNSW index; programmatic end-to-end test passed (index → grounded answer + citation → deindex). Required an SSL fix: `_connect_args()` in `db/session.py` + `alembic/env.py` now use an unverified TLS context (Supabase cert chain fails default verification). **Still TODO (developer):** paste `DATABASE_URL` + `JINA_API_KEY` into the Render dashboard for prod.

Flutter (`modunote/`):
- ✅ **S2-F1 — Constant** *(2026-06-27)*: `AppConstants.ragIndexTags = {study, notes, research}`.
- ✅ **S2-F2 — Service** *(2026-06-27)*: `RemoteNoteService.indexNote` / `deindexNote` / `ask`; typed `QnaAnswer` + `Citation` model (`lib/data/models/qna_answer.dart`); `RemoteServiceException` on failure.
- ✅ **S2-F3 — Sync wiring** *(2026-06-27)*: `_scheduleRagSync(Note)` in `note_editor_screen.dart` — on close (`_onBack`) indexes if any trigger tag else deindexes; delete path also deindexes. Fire-and-forget (never blocks save — D12.4).
- ✅ **S2-F4 — ViewModel** *(2026-06-27)*: `QnaViewModel` (`@riverpod`, auto-dispose) holds `List<QnaTurn>` (question + `AsyncValue<QnaAnswer>`); `ask`/`clear`. `build_runner` run.
- ✅ **S2-F5 — Route + entry** *(2026-06-27)*: `AppRoutes.qna = '/qna'` GoRoute (outside shell); `_AskNotesCard` on Home (below search field) → `context.push('/qna')`.
- ✅ **S2-F6 — Screen** *(2026-06-27)*: `QnaScreen` (`ConsumerStatefulWidget`) — chat bubbles, thinking row, citation chips → `context.push(editNotePath)`, empty state, input bar.
- ✅ **S2-F7 — Quality** *(2026-06-27)*: `flutter analyze` = **0 issues**.

**Remaining for full Stage 2 (developer):** S2-B8 — create Supabase project, set `DATABASE_URL` (direct conn) + `JINA_API_KEY` in `modunote-api/.env`, `alembic upgrade head`, Swagger smoke test; then set the same two secrets in the Render dashboard (already wired in `render.yaml`). After that, Stage 2 is end-to-end.

---

## Phase W — Web Portfolio Preview ✅

**Completed**: Phase W (Stage 1)
**Deliverable**: Flutter Web build of ModuNote deployed to Firebase Hosting as a live portfolio showcase. The app renders inside a phone-frame mockup on a styled dark-navy landing page.

**Live URL**: https://modunote-ba654.web.app

### Files Created

- `web/flutter_bootstrap.js` — Custom bootstrap that renders Flutter into `#flutter-host` (hostElement), preventing full-viewport takeover by the Flutter canvas
- `web/drift_worker.dart` — Dart entry point for the drift WASM web worker (`WasmDatabase.workerMainForOpen()`)
- `web/drift_worker.js` — Compiled JavaScript worker (from `dart compile js -O2`)
- `web/sqlite3.wasm` — Pre-compiled SQLite WASM module (sqlite3-2.9.4, 714 KB, from GitHub release)
- `lib/data/datasources/file/audio_file_storage_native.dart` — Native (dart:io) audio storage implementation (extracted from original `audio_file_storage.dart`)
- `lib/data/datasources/file/audio_file_storage_web.dart` — Web stub for `AudioFileStorage` — all methods no-op or throw `FileStorageException`; no `dart:io` import

### Files Modified

- `web/index.html` — Replaced Flutter's default page with a styled phone-frame landing page: dark navy (`#1C1B2E`) background, radial glow, CSS phone bezel with dynamic island detail, `390×844` Flutter host element, header (wordmark + tagline), tech stack chips, GitHub link
- `lib/data/datasources/file/audio_file_storage.dart` — Converted to conditional export: `export '_native.dart' if (dart.library.html) '_web.dart'`. No `dart:io` import.
- `lib/data/datasources/local/app_database.dart` — `createExecutor()` now branches on `kIsWeb`: web path calls `driftDatabase(name: 'modunote', web: DriftWebOptions(sqlite3Wasm, driftWorker))`, native path unchanged (`driftDatabase(name: 'modunote.db')`)
- `lib/presentation/views/note_editor/note_editor_screen.dart` — Added `kIsWeb` guard at top of `_onMicTap()` (shows snackbar and returns); gated `_AudioClipsRow` render with `!kIsWeb`
- `test/widget_test.dart` — Replaced stale default Flutter counter test (referenced non-existent `MyApp`) with a no-op placeholder
- `firebase.json` — Added `hosting` section: `public: build/web`, SPA rewrites, `.wasm` Content-Type header, COOP/COEP headers for cross-origin isolation (required for drift WASM shared memory)
- `.firebaserc` — New file: maps `default` project alias to `modunote-ba654`

### Key decisions

- **`drift_flutter 0.2.7` provides `DriftWebOptions`** — used the high-level `driftDatabase(name:, web: DriftWebOptions(...))` API rather than raw `WasmDatabase.open()`. Cleaner and future-proof.
- **COOP/COEP headers** — Required for `SharedArrayBuffer` which enables drift's preferred OPFS-shared storage. Without them drift falls back to IndexedDB (still works, just slower).
- **Audio disabled on web (Stage 1)** — `flutter_sound` records AAC to native file paths; no equivalent on web. The `_onMicTap()` web path shows an informational snackbar. Audio clips row is hidden on web.
- **Responsive phone frame** — CSS scales the phone bezel proportionally below 460 px viewport width.

### Build output

`flutter build web` — 0 errors, 1 harmless font warning (CupertinoIcons from a dependency). `flutter analyze` — 0 issues. 45 files deployed.

---

## Phase 1 — Project Setup & Folder Structure ✅

**Completed**: Phase 1
**Deliverable**: Runnable Flutter skeleton. `flutter run` boots to NoteListScreen placeholder.

### Files Created

#### Root
- `pubspec.yaml` — all 13 runtime + 6 dev dependencies locked
- `analysis_options.yaml` — flutter_lints + custom_lint (riverpod_lint)
- `build.yaml` — Riverpod generator + Drift codegen config
- `.gitignore` — excludes `*.g.dart`, build/, Android local config
- `CLAUDE.md` — AI agent context (architecture, conventions, phase status)
- `STATUS.md` (formerly `progress.md`) — this file

#### `lib/`
- `main.dart` — `WidgetsFlutterBinding.ensureInitialized()` + `ProviderScope` + `runApp`
- `app.dart` — `ModuNoteApp extends ConsumerWidget`, `MaterialApp.router`, watches `routerProvider` + `themeModeProvider`

#### `lib/core/`
- `theme/app_colors.dart` — all 34 design tokens (17 light, 17 dark) + 3 shared
- `theme/app_typography.dart` — Plus Jakarta Sans + Inter helpers + `buildTextTheme()`
- `theme/app_theme.dart` — `AppTheme.light()` / `AppTheme.dark()` with Material 3 `ColorScheme.fromSeed`
- `constants/app_constants.dart` — string keys, note/tag/category limits, audio spec constants
- `errors/app_exception.dart` — sealed `AppException` + 5 subtypes (Database, FileStorage, NotFound, Validation, Permission)
- `extensions/string_extensions.dart` — `isBlank`, `isNotBlank`, `capitalised`, `normalised`, `truncate`
- `utils/uuid_generator.dart` — `UuidGenerator.generate()` wrapper

#### `lib/data/models/`
- `note.dart` — `Note` + `SyncStatus` enum (id, title, content, categoryId?, tagIds, isPinned, isArchived, createdAt, updatedAt, syncStatus)
- `tag.dart` — `Tag` (id, name lowercase, createdAt)
- `category.dart` — `Category` (id, name, parentId?, sortOrder, createdAt) with adjacency-list hierarchy
- `audio_record.dart` — `AudioRecord` (id, noteId, filePath, durationMs, fileSizeBytes, codec, transcribedText?, createdAt)

#### `lib/data/repositories/interfaces/`
- `i_note_repository.dart` — watchAll, watchByTag, watchByCategory, findById, search, insert, update, archive, delete, togglePin
- `i_tag_repository.dart` — watchAll, searchByPrefix, findByName, findByNote, insert, addToNote, removeFromNote, setTagsForNote, delete
- `i_category_repository.dart` — watchAll, findChildren, findById, insert, update, delete, move

#### `lib/data/repositories/local/` (stubs — Phase 2)
- `local_note_repository.dart`
- `local_tag_repository.dart`
- `local_category_repository.dart`

#### `lib/data/datasources/` (stubs — Phase 2 + 6)
- `local/.gitkeep` — Drift DAOs go here in Phase 2
- `file/.gitkeep` — AudioFileStorage goes here in Phase 6

#### `lib/services/` (stubs — Phase 6)
- `speech/speech_to_text_service.dart`
- `audio/audio_recording_service.dart`

#### `lib/presentation/`
- `router/app_router.dart` — GoRouter config, 6 routes, `routerProvider`, `ThemeModeNotifier`, `themeModeProvider`
- `router/app_router.g.dart` — pre-generated stub (replace by running build_runner)
- `views/note_list/note_list_screen.dart` — placeholder
- `views/note_editor/note_editor_screen.dart` — placeholder (accepts optional `noteId`)
- `views/search/search_screen.dart` — placeholder
- `views/tags/tags_screen.dart` — placeholder
- `views/settings/settings_screen.dart` — placeholder
- `viewmodels/.gitkeep` — AsyncNotifiers go here from Phase 3
- `widgets/.gitkeep` — shared widgets go here from Phase 4

### Post-Phase Fix (applied before Phase 2)

**Bug**: `Undefined name 'themeModeNotifierProvider'` in `app_router.dart`.

**Root cause**: The `themeMode` convenience provider (`@riverpod ThemeMode themeMode(Ref ref)`) referenced `themeModeNotifierProvider` — a name only defined in the generated `.g.dart`. Because the stub `.g.dart` didn't include the `_$ThemeModeNotifier` abstract base class, the class declaration `class ThemeModeNotifier extends _$ThemeModeNotifier` also failed to resolve, causing a cascade.

**Fix applied**:
1. Removed the `themeMode` convenience provider from `app_router.dart` entirely (was redundant).
2. Updated `app.dart` to watch `themeModeNotifierProvider` directly (`ref.watch(themeModeNotifierProvider)`).
3. Rewrote `app_router.g.dart` stub to include the `_$ThemeModeNotifier` abstract base class that Riverpod generator produces, and removed the now-deleted `themeMode` provider entry.

**Files changed**: `lib/app.dart`, `lib/presentation/router/app_router.dart`, `lib/presentation/router/app_router.g.dart`

---

### Decisions Recorded
- Android-only target at creation
- `equatable` over `freezed` for model equality (simpler, less codegen)
- Pre-written `app_router.g.dart` stub to avoid build_runner dependency at setup time
- `SyncStatus` enum included in `Note` from day one (Firebase prep)
- `ThemeModeNotifier` defaults to `ThemeMode.system`

### First-Run Instructions

```bash
# 1. Get dependencies
flutter pub get

# 2. Replace the pre-generated stub with real generated code
dart run build_runner build --delete-conflicting-outputs

# 3. Run
flutter run
```

Expected result: App launches with Material 3 scaffold, "ModuNote" in the app bar, "📝 Note List / Phase 4 — coming soon" centred on screen, amber FAB in the bottom-right.

---

---

## Phase 2 — Data Layer ✅

**Completed**: Phase 2
**Deliverable**: Full Drift schema, all DAOs, local repository implementations, and data-layer Riverpod providers wired to interfaces.

> **Note**: This phase was completed across two sessions due to an interruption. The first session wrote `app_database.dart`, `notes_dao.dart`, `tags_dao.dart`, and the three local repository files before stopping mid-phase. The second session discovered multiple bugs in those committed files, created all missing files, fixed the bugs, ran `build_runner`, and committed the completed phase. See "Phase 2 Bugfix & Recovery" below.

### Files Created

#### `lib/data/datasources/local/`
- `app_database.dart` *(partially existed — not modified in Phase 2)* — `@DriftDatabase` with 5 tables, 4 DAOs, FTS5 virtual table + 3 triggers (INSERT/UPDATE/BEFORE DELETE), `MigrationStrategy`
- `database_providers.dart` — `appDatabaseProvider`, `noteRepositoryProvider`, `tagRepositoryProvider`, `categoryRepositoryProvider` (all `keepAlive: true`); `appDatabaseProvider` calls `ref.onDispose(db.close)`

#### `lib/data/datasources/local/converters/`
- `type_converters.dart` — `QuillDeltaConverter` (`Map<String,dynamic>` ↔ `String` JSON), `DateTimeConverter` (`DateTime` ↔ `int` epoch ms UTC), `StringListConverter` (`List<String>` ↔ `String` JSON array)

#### `lib/data/datasources/local/tables/`
- `notes_table.dart` — `NotesTable` (`@DataClassName('NoteRow')`): `tagIds` denormalised via `StringListConverter`, `sync_status` defaults to `'local'`
- `tags_table.dart` — `TagsTable` (`@DataClassName('TagRow')`): `name` has `.customConstraint('NOT NULL UNIQUE')`
- `note_tags_table.dart` — `NoteTagsTable` (`@DataClassName('NoteTagRow')`): composite primary key `{noteId, tagId}`
- `categories_table.dart` — `CategoriesTable` (`@DataClassName('CategoryRow')`): `parentId` nullable, `sortOrder` defaults to `0`
- `audio_records_table.dart` — `AudioRecordsTable` (`@DataClassName('AudioRecordRow')`): `transcribedText` nullable, `codec` defaults to `'aac'`

#### `lib/data/datasources/local/daos/`
- `categories_dao.dart` — `watchAll`, `findChildren(String parentId)`, `findRoots`, `findById`, `insertCategory`, `updateCategory`, `deleteCategory`, `moveCategory`, `updateSortOrder`
- `audio_records_dao.dart` — `watchByNote`, `findById`, `findByNote`, `totalFileSizeBytes` (raw SQL `COALESCE(SUM…)`), `insertAudioRecord`, `updateTranscription`, `deleteAudioRecord`, `deleteAllForNote`

*(Previously committed in interrupted session — fixed in Phase 2 recovery):*
- `notes_dao.dart` — `watchAll`, `watchByTag`, `watchByCategory`, `findById`, `search` (FTS5), `insertNote`, `updateNote`, `archiveNote`, `deleteNote`, `togglePin`, `updateTagIds`
- `tags_dao.dart` — `watchAll`, `searchByPrefix`, `findByName`, `findById`, `findByNote`, `insertTag`, `deleteTag`, `addTagToNote`, `removeTagFromNote`, `setTagsForNote`, `_syncDenormalisedTagIds`

#### `lib/data/repositories/local/` (upgraded from stubs — bugs fixed in Phase 2 recovery)
- `local_note_repository.dart` — implements `INoteRepository` via `NotesDao`; maps `NoteRow` ↔ `Note`; parses `SyncStatus` enum
- `local_tag_repository.dart` — implements `ITagRepository` via `TagsDao`; normalises tag names on write via `StringExtensions.normalised`
- `local_category_repository.dart` — implements `ICategoryRepository` via `CategoriesDao`

#### `lib/data/repositories/interfaces/` (signatures corrected to match implementations)
- `i_tag_repository.dart` — `insert(String name)` (not `insert(Tag tag)`); `addTagToNote`/`removeTagFromNote` (not `addToNote`/`removeFromNote`); `setTagsForNote` uses positional params; added `findById`
- `i_category_repository.dart` — `findChildren(String parentId)` non-nullable; added `findRoots()`; added `updateSortOrder(String id, int sortOrder)`; `move` uses positional params; corrected `insert` signature

#### `lib/core/utils/string_extensions.dart`
- Re-export shim: `export '../extensions/string_extensions.dart'` — created because `local_tag_repository.dart` imports from `core/utils/` but the file lives at `core/extensions/`. Keeps the committed repo file unmodified.

### Architectural Decisions

| Decision | Detail |
|---|---|
| FTS5 full-text search | Virtual table `notes_fts` with 3 SQLite triggers (INSERT/UPDATE/BEFORE DELETE) keeps the index always in sync without application-level maintenance |
| Denormalised `tagIds` column | `NotesTable.tagIds` stores a JSON-encoded `List<String>` alongside the normalised join table. Gives O(1) tag list access in ViewModel streams without a join |
| `setTagsForNote` transactional | Runs inside Drift `transaction()`: deletes all join-table rows for the note, inserts new ones, then calls `_syncDenormalisedTagIds` — atomic, no partial state |
| TypeConverters — not raw SQL | `QuillDeltaConverter`, `DateTimeConverter`, `StringListConverter` registered on table columns so Drift handles serialisation transparently |
| Companion naming | Drift names companions after the TABLE class, not the data class: `NotesTableCompanion`, `TagsTableCompanion`, `NoteTagsTableCompanion`, `CategoriesTableCompanion`, `AudioRecordsTableCompanion` |
| `DatabaseException` signature | `DatabaseException(String message, {Object? cause})` — the `cause` named param is the only extra field; no `originalError` or `stackTrace` |
| `keepAlive: true` on all data providers | Database and repository providers must not be disposed during the app session |
| `ref.onDispose(db.close)` | Ensures SQLite connection is closed cleanly if the provider is ever disposed |
| `findChildren` non-nullable | `findChildren(String parentId)` takes a required ID; callers wanting root categories use the dedicated `findRoots()` method |

### Phase 2 Bugfix & Recovery

The first session was interrupted after committing partial work. The second session found and fixed the following bugs before the phase could be completed:

| Bug | Root cause | Fix |
|---|---|---|
| Companion class names wrong in all DAOs + repos | Drift names companions after the TABLE class (`NotesTableCompanion`), not the data class (`NoteRowCompanion`) | Bulk-renamed across `notes_dao.dart`, `tags_dao.dart`, and all three local repos |
| `DatabaseException` wrong constructor params | All repos called `DatabaseException('msg', originalError: e, stackTrace: st)` but the constructor only accepts `(message, {cause})` | Replaced with `DatabaseException(msg, cause: e)` throughout |
| Wrong import paths in local repos | `'../datasources/local/...'` resolves to non-existent `lib/data/repositories/datasources/` | Fixed to `'../../datasources/local/...'` |
| Wrong `string_extensions` import | `local_tag_repository.dart` imported from `core/utils/` but file is at `core/extensions/` | Fixed import + created `core/utils/string_extensions.dart` re-export |
| Interface / implementation mismatch | `ITagRepository` and `ICategoryRepository` had signatures that didn't match the implementations (wrong method names, wrong param types) | Rewrote both interfaces to exactly match their implementations |
| `intl` version conflict | `flutter_quill ^10.8.5` requires `intl ^0.19.0`; Flutter SDK pins `intl 0.20.2` | Added `dependency_overrides: intl: '>=0.19.0 <0.21.0'` to `pubspec.yaml` |
| `custom_lint`/`riverpod_generator` incompatibility | `riverpod_generator ^2.4.3` incompatible with `custom_lint ^0.6.4` | Bumped to `custom_lint: ^0.7.6` and `riverpod_lint: ^2.4.0` |

**Recovery strategy**: Hand-wrote minimal `.g.dart` stubs for all DAOs and providers to enable compilation before `build_runner` ran. Once `flutter pub get` succeeded (after the pubspec fixes above), `dart run build_runner build --delete-conflicting-outputs` replaced all stubs with real generated code (93 outputs). `flutter analyze` confirmed 0 errors.

### First-Run Instructions (Phase 2 state)

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Expected: app boots to NoteListScreen placeholder; Drift opens the SQLite database on first launch (no crash).

---

## Phase 3 — State Management ✅

**Completed**: Phase 3
**Deliverable**: 5 Riverpod ViewModels wired to the Phase 2 repository layer. No UI changes — placeholder screens unchanged.

### Files Created

#### `lib/presentation/viewmodels/`

- `note_list_view_model.dart` — `NoteListViewModel extends _$NoteListViewModel`. `build()` returns `Stream<List<Note>>` from `INoteRepository.watchAll()`. Mutations: `archive`, `delete`, `togglePin`. Errors set `state = AsyncError(e, st)`; stream auto-updates state on success.
- `note_editor_view_model.dart` — `NoteEditorViewModel extends _$NoteEditorViewModel`. Family provider with optional `noteId` build param. `build()` returns `Future<Note?>` (null for new note). Private `_isNew` flag tracks insert vs update. Mutations: `save`, `updateTitle`, `updateContent`, `addTag`, `removeTag`, `setCategory`. `addTag`/`removeTag` use `ITagRepository` then reload note via `findById`. `setCategory` constructs Note directly (bypasses `copyWith` to correctly handle `null` to clear a category).
- `tag_list_view_model.dart` — `TagListViewModel extends _$TagListViewModel`. `build()` streams `ITagRepository.watchAll()`. Mutations: `insert` (returns `Tag`), `delete`.
- `category_tree_view_model.dart` — `CategoryTreeViewModel extends _$CategoryTreeViewModel`. `build()` streams `ICategoryRepository.watchAll()` as a flat list. Mutations: `insert`, `move`, `delete`.
- `search_view_model.dart` — `SearchState` class + `SearchViewModel extends _$SearchViewModel`. `SearchState` holds `query: String` + `results: AsyncValue<List<Note>>`. `setQuery` debounces 300 ms via `dart:async Timer`. `ref.onDispose` cancels the timer. Empty query clears results immediately without DB hit.

### Architectural Decisions

| Decision | Detail |
|---|---|
| Stream-based VMs use `build() → Stream<T>` | Riverpod code-gen generates `StreamNotifier` — each stream emission becomes `AsyncData<T>` automatically. No manual `.listen()` anywhere. |
| `NoteEditorViewModel` uses `Future<Note?>` | No `watchById` on `INoteRepository`; editor manages state manually after each mutation. |
| `_isNew` field for insert vs update | Set in `build()`, cleared after first successful `insert`. Avoids extra DB round-trip. |
| `setCategory(null)` bypasses `copyWith` | `Note.copyWith(categoryId: null)` keeps old value (Dart nullable-copyWith limitation). Direct constructor call used instead. |
| `SearchState` co-locates query + results | Original D3.5 listed `AsyncNotifier<List<Note>>` for search — confirmed incorrect by developer. `Notifier<SearchState>` is the right choice. |
| Search debounce: 300 ms | Small enough to feel responsive; large enough to avoid hammering FTS5 on every keystroke. |

### Bugfix Log

| Bug | Fix |
|---|---|
| D3.5 error: `searchViewModelProvider` listed as `AsyncNotifier<List<Note>>` | Confirmed by developer as wrong. Corrected to `Notifier<SearchState>` before implementation. DECISIONS.md updated at Phase 3 start. |
| `overridden_fields` on DAO fields in `AppDatabase` — redeclared fields that `_$AppDatabase` already provides as concrete `late final` | Removed all 4 DAO field declarations from `AppDatabase`; inherited directly from the generated base class. |
| 11 `unnecessary_import` warnings — redundant table imports in DAOs, redundant DAO imports in local repos, redundant `flutter_riverpod` in `search_view_model.dart` | Removed all redundant imports; each file now imports only `app_database.dart` (which re-exports tables and DAOs) or `riverpod_annotation` (which re-exports Riverpod). |
| `use_super_parameters` on `AppDatabase(QueryExecutor e) : super(e)` | Changed to `AppDatabase(super.e)`. |
| `prefer_const_declarations` on `UuidGenerator._uuid` | Changed `static final _uuid = const Uuid()` to `static const _uuid = Uuid()`. |

### First-Run Instructions (Phase 3 state)

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter run
```

Expected: app boots to NoteListScreen placeholder (no UI change from Phase 2). `build_runner` produces 5 new `.g.dart` files in `lib/presentation/viewmodels/`. `flutter analyze` reports 0 errors.

---

---

## Phase 4 — Note List Screen ✅

**Completed**: Phase 4
**Deliverable**: Full NoteListScreen implementation. `flutter run` shows the live note list with pinned/recent sections, shimmer loading, error retry, floating bottom nav, and amber FAB.

### Files Created

#### `lib/presentation/widgets/`
- `mn_note_card.dart` — `MNNoteCard extends StatelessWidget`. Props: `Note note`, `VoidCallback onTap`, `List<String> tagNames`. Renders card per UI Reference § 2.3: pinned tint background, pin icon, title (PJS 16.5/700), single-line preview (Inter 13.5/400), up to 3 filled tag chips. Private `_TagChip` widget. Timestamp computed inline from `note.updatedAt`. Body preview extracted from Quill Delta JSON.
- `mn_search_field.dart` — `MNSearchField extends StatelessWidget`. Props: `VoidCallback? onTap`. Height 48, surfaceContainer bg, borderRadius 16, 0.5px outline border. Non-editable on Home; navigates on tap.

#### `lib/presentation/views/note_list/`
- `note_list_screen.dart` — **Replaced** placeholder with full implementation. `NoteListScreen extends ConsumerWidget`. Watches `noteListViewModelProvider` + `tagListViewModelProvider`. Uses `Stack` + `Positioned.fill` + two `Positioned` overlays (bottom nav + FAB). Private helper widgets:
  - `_DataBody` — renders note list with section headers; empty state inline
  - `_AppBarSection` — day label + "Your notes" + gradient avatar
  - `_SectionHeader` — "PINNED" / "RECENT" label + hairline divider + optional count badge
  - `_LoadingBody` — 3 pulsing `_SkeletonBox` widgets as fake cards
  - `_SkeletonBox` — `StatefulWidget`, `AnimationController.repeat(reverse: true)`, opacity 0.35→0.65
  - `_ErrorBody` — error icon + "Could not load notes" + Retry `TextButton`
  - `_EmptyState` — empty icon + "No notes yet" + search field + centred message
  - `_BottomNav` — floating pill nav at `left: 16, right: 16, bottom: 14`; 4 tabs; Home active
  - `_NavTab` — `AnimatedContainer` pill; active = `primaryContainer` bg + icon + label
  - `_Fab` — amber 56×56, `borderRadius: 18`, two-layer amber shadow

### Architectural Decisions

| Decision | Detail |
|---|---|
| Tag name resolution | `NoteListScreen` watches both `noteListViewModelProvider` + `tagListViewModelProvider`; builds `Map<String,String>` id→name; passes resolved names to `MNNoteCard.tagNames` |
| `MNNoteCard` is `StatelessWidget` | Purely presentational — no providers. Tab navigation, swipe actions deferred to later phases |
| Shimmer without package | `_SkeletonBox` `StatefulWidget` with `AnimationController` — no `shimmer` package required |
| Bottom nav scope | Phase 4 bottom nav is per-screen (hardcoded Home active). Replaced by `ShellRoute` in Phase 9 |
| No build_runner | No new `@riverpod` annotations or Drift tables — build_runner does not need to re-run |
| `flutter analyze` | 0 issues (2 `prefer_const_constructors` warnings fixed during implementation) |

### First-Run Instructions (Phase 4 state)

```bash
# No new packages — no flutter pub get needed
# No new @riverpod annotations — no build_runner needed
flutter analyze   # expected: 0 issues
flutter run       # app boots to full NoteListScreen
```

Expected: Home screen renders with "Your notes" heading, gradient avatar, search field, PINNED / RECENT sections (empty state if DB empty), floating amber FAB, floating bottom nav pill.

---

## Phase 5 — Note Editor Screen ✅

**Completed**: Phase 5
**Deliverable**: Full `NoteEditorScreen` implementation with Quill rich-text editor, 800 ms auto-save, format toolbar, tag row, and recording overlay UI (wired to real audio in Phase 6).

### Files Created

#### `lib/presentation/widgets/`
- `mn_editor_toolbar.dart` — `MNEditorToolbar extends StatefulWidget`. Props: `required QuillController controller`. Owns `controller.addListener` to update active-state badges on selection/content changes. 9 formatting tools (bold, italic, underline, H1, H2, bullet, numbered list, checklist, blockquote) each rendered as 34×34 `_ToolButton` with `borderRadius: 10`. Active: `primaryContainer` bg, `onPrimaryContainer` icon. Inactive: transparent bg, `onSurfaceVariant` icon. H1/H2 use `Text` labels (no Material icon available). Toggle: active → `Attribute.clone(attr, null)` unsets; inactive → `formatSelection(attr)` applies. Checklist active = list value `'checked'` OR `'unchecked'`. Spec: UI Reference § 3.4.
- `mn_tag_row.dart` — `MNTagRow extends StatelessWidget`. Props: `tagIds`, `allTags`, `categoryName?`, `onRemoveTag`, `onAddTagTap`, `onCategoryTap`, `onMicTap`, `isRecording`. Category chip (height 30, `br 10`, surfaceContainer bg). Horizontal scrollable row of dismissible sm filled tag chips + `+ tag` sm outlined chip. Mic button (40×40, `br 14`; idle = primaryContainer; recording = recordRed + white square). Spec: UI Reference § 3.4.

#### `lib/presentation/views/note_editor/`
- `note_editor_screen.dart` — **Replaced** placeholder. `NoteEditorScreen extends ConsumerStatefulWidget`. Key state: `QuillController? _quillController`, `TextEditingController _titleController`, `FocusNode`, `ScrollController`, `StreamSubscription? _contentSubscription`, `Timer? _debounce`, `Timer? _recordTimer`, `bool _isDirty`, `bool _isRecording`, `int _recordSeconds`, `Note? _currentNote`, `bool _controllersInitialized`. Layout: `Scaffold(resizeToAvoidBottomInset: true)` → `SafeArea` → `Stack` (Column + `Positioned` recording overlay). Column: `_EditorAppBar` (back btn + title TextField + `_SaveBadge` + more btn) + `Expanded(QuillEditor)` + `MNTagRow` + `MNEditorToolbar`. Private widgets: `_EditorAppBar`, `_CircleIconButton`, `_SaveBadge`, `_RecordingOverlay`, `_WaveformBars`, `_PulsingStopButton`.

### Architectural Decisions

| Decision | Detail |
|---|---|
| `ConsumerStatefulWidget` for editor | Owns `QuillController` lifecycle (`initState`/`dispose`). Only exception to the "always `ConsumerWidget`" rule |
| Controller init from `whenData` in build | `noteAsync.whenData(_initControllers)` called each build; guarded by `_controllersInitialized`. Sets `_quillController` synchronously; no `setState` needed — current build frame sees updated value |
| Content-only stream subscription | `_quillController!.document.changes.listen()` for auto-save (not `addListener`) — avoids triggering save on cursor movements |
| Auto-save on back | `_onBack` cancels debounce, `await _performAutoSave()`, then `context.pop()` |
| `_syncCurrentNote()` after tag mutations | After `addTag`/`removeTag`, re-reads ViewModel state to keep `_currentNote.tagIds` in sync |
| No `withOpacity` | All translucent colors use `.withValues(alpha: ...)` to match Flutter 3.27+ deprecation-free style |
| No new packages, no build_runner | Phase 5 adds no new `@riverpod` providers and no new Drift tables |

### First-Run Instructions (Phase 5 state)

```bash
# No new packages, no new @riverpod annotations
flutter analyze   # expected: 0 issues
flutter run       # tap FAB → Note Editor opens; type → auto-saves after 0.8 s
```

Expected: Tapping FAB opens Note Editor with empty Quill editor. Title TextField at top. "Saved" badge shows green dot after 0.8 s idle. Format toolbar pins above keyboard. Tag row shows "+ tag" chip and mic button. Tapping mic shows recording overlay with timer. Tapping back returns to Note List.

---

## Phase 6 — Voice-to-Text + Audio Recording/Playback ✅

**Completed**: Phase 6
**Deliverable**: Real audio recording via `flutter_sound` + live speech-to-text via `speech_to_text`, wired to the mic button. Audio clip chips with playback. Transcript inserted at Quill cursor on stop.

### Files Created

#### `lib/data/datasources/file/`
- `audio_file_storage.dart` — `AudioFileStorage`. `ensureAudioDir()` creates `audio_notes/` under `getApplicationDocumentsDirectory()`. `generateFilePath()` returns `{audioDir}/{uuid}.aac`. `getFileSize(filePath)` returns bytes. `deleteFile(filePath)` removes file. All IO exceptions wrapped in `FileStorageException`.

#### `lib/data/repositories/interfaces/`
- `i_audio_record_repository.dart` — `IAudioRecordRepository` interface: `watchByNote`, `findByNote`, `findById`, `insert`, `updateTranscription`, `delete`, `deleteAllForNote`.

#### `lib/data/repositories/local/`
- `local_audio_record_repository.dart` — Implements `IAudioRecordRepository` via `AudioRecordsDao`. Maps `AudioRecordRow` ↔ `AudioRecord`. Wraps Drift exceptions as `DatabaseException(msg, cause: e)`.

#### `lib/services/audio/`
- `audio_recording_service.dart` — Replaces stub. `FlutterSoundRecorder` + `FlutterSoundPlayer`. `init()` opens both (idempotent, guarded by `_initialized`). `startRecording(filePath)` uses `Codec.aacADTS`, `bitRate: 32000`, `numChannels: 1`, `sampleRate: 16000`; maps `onProgress.decibels` → `amplitudeStream` (0.0–1.0 normalized). `stopRecording()` returns `durationMs` via `Stopwatch`. `startPlayback(filePath, {onDone})` / `stopPlayback()`. `dispose()` closes both safely.

#### `lib/services/speech/`
- `speech_to_text_service.dart` — Replaces stub. `SpeechToText` wrapper. `initialize()` requests mic permission. `startListening({onResult})` uses `ListenMode.dictation`, `pauseFor: 8s`. Appends `finalResult` words to `_accumulated`; passes `_accumulated + inFlight` for partial. `_onStatus` handler restarts listener on `'notListening'` while `_active` (Android STT timeout recovery). `stopListening()`, `resetText()`, `dispose()`.

#### `lib/presentation/viewmodels/`
- `audio_editor_view_model.dart` — `AudioEditorViewModel extends _$AudioEditorViewModel`. Family `{required String noteId}`. `build()` → `Stream<List<AudioRecord>>` from `audioRecordRepositoryProvider.watchByNote`. `saveRecording(filePath, durationMs, fileSizeBytes, transcript?)` → constructs + inserts `AudioRecord`. `deleteRecord(id)` → deletes DB row (caller deletes file).

### Files Modified

#### `lib/data/datasources/local/database_providers.dart`
- Added `audioRecordRepositoryProvider` (`@Riverpod(keepAlive: true)`) → `LocalAudioRecordRepository(db.audioRecordsDao)`. Added imports for new interface + repo.

#### `lib/presentation/views/note_editor/note_editor_screen.dart`
- **`_onMicTap()`**: replaced stub. Flushes auto-save if needed, lazy-inits `AudioRecordingService` + `SpeechToTextService`, checks STT permission (SnackBar + early return if denied), generates file path, starts recording + listening simultaneously, subscribes to amplitude stream for waveform, starts record timer.
- **`_stopRecording()`**: replaced stub. Cancels timer + amplitude subscription, stops both services, saves `AudioRecord` via `audioEditorViewModelProvider`, inserts transcript at Quill cursor via `_insertTranscriptAtCursor`.
- **`_insertTranscriptAtCursor(text)`**: new method. Inserts `'\n$text\n'` at `selection.baseOffset`.
- **`_WaveformBars`**: now accepts `double amplitude`. `AnimatedContainer(duration: 80ms)` per bar with height `= 4.0 + amplitude * 20.0 * coefficient[i]`.
- **`_RecordingOverlay`**: gains `amplitude` + `liveTranscript` props. Transcript preview added below timer row (hidden when empty).
- **`_AudioClipsRow`** (new `ConsumerStatefulWidget`): watches `audioEditorViewModelProvider`. Horizontal scroll of `_AudioClipChip` widgets. Manages `_playingId` for play/pause. Chips: h28, pill, surfaceContainer bg, play/pause icon + duration text + delete ×.
- **Column order in `_buildEditor`**: AppBar → QuillEditor → `_AudioClipsRow` → `MNTagRow` → `MNEditorToolbar`.
- New state fields: `_audioService`, `_sttService`, `_audioStorage`, `_audioInitialized`, `_amplitudeSubscription`, `_currentRecordingPath`, `_currentAmplitude`, `_liveTranscript`.

#### `android/app/src/main/AndroidManifest.xml`
- Added `<uses-permission android:name="android.permission.RECORD_AUDIO"/>`.

### Post-Phase-6 flutter analyze Fixes

Three `flutter analyze` issues found after moving Phase 6 files from Claude worktree to the main project directory. All fixed; `flutter analyze` now reports **0 issues**.

| File | Issue | Fix |
|---|---|---|
| `lib/data/repositories/local/local_audio_record_repository.dart` | `unnecessary_import` — direct DAO import redundant (re-exported via `app_database.dart`) | Removed `import '../../datasources/local/daos/audio_records_dao.dart'` |
| `lib/services/speech/speech_to_text_service.dart` | `deprecated_member_use` — `listenMode:` and `cancelOnError:` params on `_stt.listen()` deprecated in `speech_to_text ^7.0.0` | Wrapped in `listenOptions: SpeechListenOptions(listenMode: ListenMode.dictation, cancelOnError: false)` |
| `lib/services/audio/audio_recording_service.dart` | `prefer_const_constructors` — `throw FileStorageException(...)` in `_assertInitialized()` missing `const` | Changed to `throw const FileStorageException(...)` |

### Architectural Decisions

| Decision | Detail |
|---|---|
| STT approach | Simultaneous: `flutter_sound` records AAC while `speech_to_text` listens live. Confirmed by developer. Works on most modern Android devices. |
| D6.4 revised | Original D6.4 assumed file-based STT (impossible with `speech_to_text` v7). Revised to live STT running simultaneously with flutter_sound recording. |
| STT timeout recovery | `_onStatus('notListening')` handler with 200 ms delay restarts `_stt.listen()` if still `_active`. Prevents transcript truncation on long recordings. |
| Services lifecycle | `AudioRecordingService` + `SpeechToTextService` are plain Dart classes owned by `_NoteEditorScreenState`. Not `@riverpod` providers — lifecycle is tied to the screen. |
| `_AudioClipsRow` widget type | `ConsumerStatefulWidget` — needs both `ref.watch(audioEditorViewModelProvider)` and local `_playingId` playback state. |
| File deletion responsibility | `audioEditorViewModelProvider.deleteRecord` removes the DB row only. The screen (via `_audioStorage.deleteFile`) removes the file. Separation of concerns. |

### First-Run Instructions (Phase 6 state)

```bash
dart run build_runner build --delete-conflicting-outputs
# New generated: audio_editor_view_model.g.dart; updated: database_providers.g.dart
flutter analyze   # expected: 0 issues
flutter run
```

Expected: Tap FAB → Note Editor. Tap mic button → OS dialog (first launch) → grant → recording overlay with live timer + animated waveform bars. Speak → transcript text appears. Tap pulsing stop → overlay gone, words inserted into editor, audio chip appears above tag row. Tap play chip → audio plays back.

---

## Phase 7 — Tags (Freeform + Autocomplete) ✅

**Completed**: Phase 7
**Deliverable**: Live-autocomplete tag input in the Note Editor, full Tags screen with density bars, maxTagsPerNote enforcement.

### Files Modified

#### `lib/data/datasources/local/daos/tags_dao.dart`
- Added `countNotesPerTag()` — `customSelect` raw SQL (`GROUP BY tag_id`) returns `Map<String, int>` of tagId → note count.

#### `lib/data/repositories/interfaces/i_tag_repository.dart`
- Added `getNoteCounts()` → `Future<Map<String, int>>` abstract method.

#### `lib/data/repositories/local/local_tag_repository.dart`
- Implemented `getNoteCounts()` delegating to `_tagsDao.countNotesPerTag()`. Wraps exceptions as `DatabaseException`.

#### `lib/presentation/viewmodels/tag_list_view_model.dart`
- Added `searchByPrefix(String prefix)` method — delegates to repo, never mutates state.
- Added `findByName(String name)` method — delegates to repo, never mutates state.
- Added `tagNoteCountsProvider` top-level `@riverpod` function (auto-disposed `FutureProvider<Map<String,int>>`). **build_runner required** (and run).

#### `lib/presentation/views/tags/tags_screen.dart`
- **Full rewrite** of Phase 1 placeholder. `TagsScreen extends ConsumerWidget`.
- App bar: "Tags" (PJS 24/800) + `"N tags"` subtitle + 40×40 Add button (`primaryContainer`, br 14).
- Tags list: outer card (card bg, 0.5px outline, br 20, p 6) with per-row density bars.
- Each `_TagRow`: hash icon container (36×36, chipBg, br 12) + tag name column (PJS 15/700) + density bar (`LayoutBuilder`, h3, `primary` fill at 55% opacity) + count badge (Inter 12/600, surfaceContainer) + chevron.
- Density: `fraction = count / maxCount`; `maxCount = max of all counts`, min 1.
- Long-press row → delete confirmation dialog.
- Add button → simple AlertDialog with TextField → `tagListViewModelProvider.notifier.insert(name)`.
- Bottom nav pill (active tab 2) consistent with Phase 4 design.
- Loading / Error / Empty states per conventions.

#### `lib/presentation/views/note_editor/note_editor_screen.dart`
- Replaced `_showAddTagDialog` (AlertDialog stub) + `_addTag(String name)` with `_onAddTagTap` that calls `showModalBottomSheet<Tag>` returning `_TagInputSheet`.
- Added maxTagsPerNote guard in `_onAddTagTap` (SnackBar + early return).
- Passes `maxTagsReached` to `MNTagRow`.
- Added `_TagInputSheet` (`ConsumerStatefulWidget`): 200 ms debounce on `searchByPrefix`, suggestion list + "Create" tile, `findByName` on submit to distinguish existing vs new tag. Pops with `Tag`.
- Added `_SuggestionTile` and `_CreateTile` private stateless widgets for the sheet's suggestion UI.
- Added imports: `app_constants.dart`, `string_extensions.dart`.

#### `lib/presentation/widgets/mn_tag_row.dart`
- Added `maxTagsReached: bool` parameter (default `false`).
- `_AddTagChip` gains `disabled: bool` parameter — renders at 40% opacity and ignores taps when disabled.

### Architecture Decisions
See DECISIONS.md D7.1–D7.10.

### First-Run Instructions (Phase 7 state)

```bash
# build_runner was already run during Phase 7 implementation
# No new packages needed
flutter analyze   # expected: 0 issues ✅
flutter run
```

Expected:
- Note Editor → tap `+ tag` → bottom sheet opens with text field and autocomplete suggestions
- Type a partial tag name → suggestions appear below the field
- Select suggestion → existing tag added; submit new name → "Create #name" tile → creates + adds
- At 20 tags: `+ tag` chip fades to 40% opacity; tapping shows SnackBar "Maximum 20 tags per note"
- Tags tab in bottom nav → Tags screen with list of all tags, density bars, and note counts
- Long-press a tag row → delete confirmation dialog → tag removed from all notes

---

## Phase 8 — Categories (Hierarchical Folder Tree) ✅

**Completed**: Phase 8
**Deliverable**: Full category picker bottom sheet wired to the note editor. Re-parent deletion policy in the data layer.

### Files Modified

#### `lib/data/datasources/local/daos/notes_dao.dart`
- Added `clearCategoryFromNotes(String categoryId)` — sets `categoryId = null` on all notes that reference the given category. Called by `LocalCategoryRepository.delete` before removing the category row.

#### `lib/data/repositories/local/local_category_repository.dart`
- Constructor extended from `(this._categoriesDao)` to `(this._categoriesDao, this._notesDao)`.
- `delete(String id)` fully implemented (was leaf-only stub): walks ancestor chain for grandparent, re-parents all direct children via `moveCategory`, clears `categoryId` on affected notes, then deletes the category row.

#### `lib/data/datasources/local/database_providers.dart`
- `categoryRepository` provider body changed from `LocalCategoryRepository(db.categoriesDao)` to `LocalCategoryRepository(db.categoriesDao, db.notesDao)`.

### Files Created

#### `lib/presentation/widgets/mn_category_picker_sheet.dart`
- `MNCategoryPickerSheet extends ConsumerStatefulWidget`. Constructor: `{required String? currentCategoryId}`.
- State: `Set<String> _expandedIds` (pre-seeded by walking the ancestor chain of `currentCategoryId`), `String? _selectedId`.
- Layout: grabber → header ("Move to category" + close ×) → constrained `ListView` (max 55% screen height).
- Tree built by grouping categories by `parentId`; siblings sorted by `sortOrder` then name.
- "None" row at top (unassigns category; returns `""`).
- Category rows: `paddingLeft = 10.0 + depth * 20.0`, expand/collapse chevron, folder icon, selection checkmark. Tapping any row returns that category's id.
- "New category" row at bottom: shows context hint (`Under · parentName` if a category is selected). Tapping opens an `AlertDialog` text field and calls `CategoryTreeViewModel.insert`.
- Return value protocol: non-empty String = category id selected, empty String = unassigned, null = dismissed.

#### `lib/presentation/views/note_editor/note_editor_screen.dart`
- Added import for `mn_category_picker_sheet.dart`.
- `_showCategoryStub` replaced with `_onCategoryTap`:
  - Opens `MNCategoryPickerSheet` via `showModalBottomSheet<String>`.
  - Interprets result: null = no-op, empty = `setCategory(null)`, non-empty = `setCategory(id)`.
  - Auto-saves unsaved note before calling `setCategory` (mirrors `_onMicTap` pattern).
- `onCategoryTap: _showCategoryStub` call site updated to `onCategoryTap: _onCategoryTap`.

### Architectural Decisions

| Decision | Detail |
|---|---|
| PD-01 resolved: re-parent | Children moved to grandparent (root if no grandparent); notes unassigned. Cascade rejected — avoids silent subtree deletion. |
| Return value protocol | `String?` from modal: non-empty = assign, `""` = unassign, `null` = dismiss. Mirrors `pushNamed` conventions. |
| `clearCategoryFromNotes` in `NotesDao` | Uses `Value(null)` in `NotesTableCompanion` to explicitly null-out the nullable column. Called before category row delete (foreign-key safe order). |
| `_initExpanded` seeds from ancestor chain | On sheet open, walks `parentId` chain from `currentCategoryId` to root; adds each ancestor to `_expandedIds`. Current selection visible without user expansion. |
| No build_runner required | No new `@riverpod` annotations; no Drift table structure change. All `.g.dart` files remain current from Phase 7. |
| `flutter analyze` | **0 issues** after Phase 8. BUG-18 fixed: `noteEditorViewModelProvider` call used positional arg (wrong) — corrected to named `noteId:` param. |

### First-Run Instructions (Phase 8 state)

```bash
# No new packages, no new @riverpod annotations
# No build_runner run required
flutter analyze   # expected: 0 issues
flutter run
```

Expected:
- Note Editor → tap category chip → `MNCategoryPickerSheet` opens as bottom sheet with full tree.
- Tapping a category row assigns it; category chip label updates.
- Tapping "None" row unassigns; chip label reverts to default "Category" label.
- Tapping "New category" row → AlertDialog → type name → category created and tree updates.
- Tapping × (close) or dismissing sheet → no change.
- Delete a category via the picker's tree (when CategoryListScreen is built) → children re-parented, notes become Uncategorised.

---

## Phase 9 — Navigation + Theming ✅

**Completed**: Phase 9
**Deliverable**: Persistent `MNBottomNav` floating pill across all 4 tabs via GoRouter `ShellRoute`. Full Settings screen with Light/Dark theme tiles. Theme persistence to SharedPreferences. All per-screen `_BottomNav` implementations removed. `flutter analyze = 0 issues`.

### Files Created

#### `lib/presentation/widgets/`
- `mn_bottom_nav.dart` — `MNBottomNav extends StatelessWidget`. Props: `int activeIndex`. 64px height, card bg, `br:32`, `outlineStrong` 0.5px border, 6px shadow. 4 `Expanded` `_NavTab` children. Active tab: `primaryContainer` bg + `br:26` pill + icon + label (Inter 13/600/+0.1). Inactive: transparent bg + icon only (`onSurfaceVariant`). All tabs call `context.go(route)` for navigation. Spec: `MODUNOTE_UI_REFERENCE.md § 2.5`.

### Files Modified

#### `pubspec.yaml`
- Added `shared_preferences: ^2.3.0` (runtime dep, under utilities section).

#### `lib/presentation/router/app_router.dart`
- **Full rewrite of `router()` function**: added `ShellRoute` wrapping the 4 tab `GoRoute` entries. Note Editor routes remain outside the shell.
- **New `_AppShell extends StatelessWidget`**: private shell widget. Provides outer `Scaffold(body: SafeArea(child: Stack([Positioned.fill(child), Positioned(nav)])))`. `_tabIndex(String loc)` derives active index from location string.
- **`ThemeModeNotifier` extended**: added `_loadPersistedMode()` (fire-and-forget from `build()`), `setLight()`, `setDark()`, `setSystem()`, `toggle()`, `_setAndPersist(ThemeMode)`. Reads/writes `AppConstants.prefThemeMode` key via `SharedPreferences`.
- New imports: `shared_preferences`, `app_constants.dart`, `mn_bottom_nav.dart`.

#### `lib/presentation/views/settings/settings_screen.dart`
- **Full rewrite** of Phase 1 placeholder. No `Scaffold` (shell provides it). Returns `ListView(padding: fromLTRB(20,8,20,150))`.
- Children: `_SettingsAppBar` ("Settings" PJS 24/800/−0.5) + `_AppearanceCard`.
- `_AppearanceCard`: card bg, 0.5px outline, `br:22`, padding 16. Title (PJS 15/700) + subtitle (Inter 12.5). Row of two `_ThemeTile` widgets.
- `_ThemeTile`: selected = 2px `primary` border + `primaryContainer` bg; unselected = 0.5px `outlineStrong` + `surfaceContainer`. Column: `_MiniPreview(h:56, br:10)` + row(icon + label + `_RadioDot`).
- `_MiniPreview`: simulated note card using each theme's card/line colours (hard-coded `AppColors.darkCard` / `AppColors.lightCard` so preview is always correct regardless of active theme).
- `_RadioDot`: 18×18 circle; selected = `cs.primary` fill + white `Icons.circle(8px)`; unselected = `outlineStrong` 1.5px border.

#### `lib/presentation/views/note_list/note_list_screen.dart`
- `NoteListScreen.build()`: removed `Scaffold(body: SafeArea(child: Stack(...)))` wrapper; now returns `Stack(...)` directly (shell provides Scaffold + SafeArea).
- `_DataBody.build()`: `context.push(AppRoutes.search)` → `context.go(AppRoutes.search)` on `MNSearchField.onTap`.
- `_EmptyState.build()`: same change on `MNSearchField.onTap`.
- Removed `_BottomNav` and `_NavTab` private classes entirely.

#### `lib/presentation/views/search/search_screen.dart`
- `SearchScreen.build()`: removed `Scaffold(body: SafeArea(child: Stack(...)))` wrapper; now returns `Column(...)` directly.
- `onBack` callback: `context.pop()` → `context.go(AppRoutes.home)` (shell tabs have no stack to pop).
- Removed `_BottomNav` and `_NavTab` private classes entirely.

#### `lib/presentation/views/tags/tags_screen.dart`
- `TagsScreen.build()`: removed `Scaffold(backgroundColor:..., body: SafeArea(child: Stack(...)))` wrapper; now returns `Column(...)` directly.
- Removed `_BottomNav` and `_NavTab` private classes entirely.
- Removed now-unused imports: `package:go_router/go_router.dart` and `../../router/app_router.dart`.

### Architectural Decisions

| Decision | Detail |
|---|---|
| `ShellRoute` for tab persistence | `_AppShell` wraps the 4 tab routes; provides outer Scaffold + SafeArea + MNBottomNav. Note Editor routes outside the shell. |
| Tab screens: no inner Scaffold | Tab screens return body content only — shell provides the Scaffold. Avoids nested-Scaffold Material warnings. |
| `ThemeModeNotifier` stays `Notifier<ThemeMode>` | Kept synchronous; fire-and-forget `_loadPersistedMode()` from `build()`. Default = `ThemeMode.system` for first frame. |
| `context.go` for tab nav | Tab routes are shell children; pushed via `go`. Note Editor uses `context.push`. SearchScreen back = `go('/home')`. |
| `_AppShell._tabIndex` from location string | Active tab index derived from `state.uri.path` in ShellRoute builder — no additional state. |
| `sort_child_properties_last` lint | `child:` param must be last in widget constructor calls. Caught by `flutter analyze` during Phase 9 (BUG-23). |
| `_MiniPreview` uses hard-coded `AppColors` | Preview must always look like the correct theme's card regardless of the user's current theme. Can't use `Theme.of(context)` here. |

### Post-Phase-9 build results

```
flutter pub get           # shared_preferences 2.5.5 + 6 platform packages added
dart run build_runner build --delete-conflicting-outputs   # 137 outputs in 28s
flutter analyze           # No issues found! ✅
```

### Post-Phase-9 UI Refinements (same PR, committed together)

After Phase 9 initial completion, three further UI changes were applied to the same commit:

**1. `flutter_floating_bottom_bar ^2.0.0` integration**

Added to `pubspec.yaml`. `_AppShell.build()` refactored:
- Before: `SafeArea(child: Stack([Positioned.fill(child), Positioned(nav)]))`
- After: `BottomBar(body: SafeArea(child: child), child: Stack([MNBottomNav, _NavFab]))`
- `hideOnScroll: true` — nav hides when scrolling down, slides back on scroll up
- `showIcon: true` with amber `iconDecoration` — when nav is hidden, an amber up-arrow button appears to scroll back to top
- `clip: Clip.none` preserves `MNBottomNav` drop shadow

Files modified: `pubspec.yaml`, `lib/presentation/router/app_router.dart`

**2. FAB notch in nav bar**

`_NavFab` — new private `StatelessWidget` in `app_router.dart`:
- 52 × 52 px amber circle, amber glow shadow, `add_rounded` icon in `accentOn`
- Positioned `top: -20` above the nav pill (protrudes 20 px above the bar)
- Calls `context.push(AppRoutes.newNote)` — available on all 4 shell tabs

`MNBottomNav` row: added 60 px `SizedBox` center gap to create the visual notch.

Old `_Fab` and `Positioned(bottom:96, right:20)` wrapper removed from `NoteListScreen`.

Files modified: `lib/presentation/router/app_router.dart`, `lib/presentation/widgets/mn_bottom_nav.dart`, `lib/presentation/views/note_list/note_list_screen.dart`

**3. Icon-only tabs**

`_NavTab` simplified: `Row([Icon, if(isActive) Text(...)])` → `Center(child: Icon(..., size:22))`. Active tab retains the `primaryContainer` pill — icon only, no label. `AppTypography` import removed from `mn_bottom_nav.dart`.

Files modified: `lib/presentation/widgets/mn_bottom_nav.dart`

**Post-refinement build results:**
```
flutter pub get           # flutter_floating_bottom_bar 2.0.0 + motor 1.1.0 added
flutter analyze           # No issues found! ✅
```

### First-Run Instructions (Phase 9 state, including refinements)

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze   # expected: 0 issues
flutter run       # Persistent floating nav; amber + FAB in center; icon-only tabs; hide-on-scroll
```

Expected:
- App boots to NoteListScreen; floating pill bottom nav (Home tab active, icon-only, no label).
- Center of nav: amber `+` FAB protruding above the bar; tapping opens Note Editor full-screen.
- Scrolling note list down → nav pill hides; amber up-arrow button appears bottom-center.
- Tapping up-arrow → scrolls back to top; nav slides back into view.
- Tapping Explore / Tags / Settings tabs → nav persists, content swaps.
- Settings tab → two theme tiles (Light / Dark). Tapping Light → app theme switches.
- Kill + restart → previously chosen theme restored from SharedPreferences.

---

## Phase 10 — Firebase Preparation Layer ✅

**Completed**: Phase 10
**Deliverable**: Firebase abstraction seam wired through the repository layer. App behaviour is identical to Phase 9 at runtime — 100% of operations still go through local Drift. `flutter analyze` = 0 issues.

### Files Created

#### `lib/data/repositories/remote/`
- `firebase_note_repository.dart` — `FirebaseNoteRepository implements INoteRepository`. `const` constructor. All 10 interface methods throw `UnimplementedError`. No Firebase package imports — pure Dart stub. Live Firestore calls are wired when `flutterfire configure` is run.

#### `lib/data/repositories/synced/`
- `synced_note_repository.dart` — `SyncedNoteRepository implements INoteRepository`. Constructor: `{required INoteRepository local, required INoteRepository remote, bool syncEnabled = false}`. With `syncEnabled = false` (Phase 10 default), all 10 methods delegate to `_local`. `_remote` is held as a field (`// ignore: unused_field`) for the future sync phase.

### Files Modified

#### `pubspec.yaml`
- Added `firebase_core: ^3.6.0` and `cloud_firestore: ^5.4.4`. Resolved to `firebase_core 3.15.2` + `cloud_firestore 5.6.12` + platform interfaces. No Gradle files modified — full Firebase setup deferred to when `flutterfire configure` is run.

#### `lib/data/datasources/local/database_providers.dart`
- `noteRepositoryProvider` body changed from `LocalNoteRepository(db.notesDao)` to `SyncedNoteRepository(local: LocalNoteRepository(db.notesDao), remote: const FirebaseNoteRepository())`. Annotation (`@Riverpod(keepAlive: true)`) and return type (`INoteRepository`) unchanged — no build_runner run required.
- Added 2 new imports: `firebase_note_repository.dart`, `synced_note_repository.dart`.

### Architectural Decisions

| Decision | Detail |
|---|---|
| `FirebaseNoteRepository` has no Firebase imports | Pure Dart stub — imports only `note.dart` and `i_note_repository.dart`. Compiles without `google-services.json` or `Firebase.initializeApp()`. |
| `SyncedNoteRepository._remote` retained with `// ignore:` | Field held for future sync phase; `unused_field` suppressed with targeted comment to keep `flutter analyze` at 0 issues. |
| No Gradle changes in Phase 10 | Adding Firebase packages to `pubspec.yaml` does not break the Android build because the Google Services Gradle plugin is not applied. Full setup requires `flutterfire configure`. |
| `noteRepositoryProvider` body-only change | Annotation and type unchanged — no build_runner re-run needed. |
| `SyncStatus` audit result | All note writes already use `SyncStatus.local` (default in `Note` constructor). No callsite changes required. |

### First-Run Instructions (Phase 10 state)

```bash
flutter pub get
# build_runner not required (no @riverpod or Drift table changes)
flutter analyze   # expected: 0 issues
flutter run       # behaviour identical to Phase 9
```

Expected: App boots identically to Phase 9. All note operations still go through local Drift. No Firebase calls are made. `SyncedNoteRepository` is invisible at runtime.

---

## Phase 10 Extension — Live Firebase Sync ✅

**Completed**: Phase 10 Extension
**Deliverable**: Live anonymous Firebase Authentication + Firestore sync wired through the existing seam. Notes sync to Firestore on note-close and on app-background. `_SaveBadge` extended to 4 states. `flutter analyze` = 0 issues.

Key changes (the former `THREAD_HANDOFF.md` detail is now merged into this file):
- `firebase_auth: ^5.7.0` added to `pubspec.yaml` (resolved: 5.7.0)
- `lib/services/auth/firebase_auth_service.dart` — singleton, `signInAnonymously()` (idempotent)
- `lib/main.dart` — `Firebase.initializeApp()` + `FirebaseAuthService().signInAnonymously()` in try-catch before `runApp`
- `FirebaseNoteRepository` replaced with live Firestore implementation (writes only — reads stay local)
- `SyncedNoteRepository` extended with `syncNote(noteId)` and `syncAllPending()`
- `syncedNoteRepositoryProvider` added (typed as `SyncedNoteRepository`)
- `NoteEditorViewModel.syncNote(String noteId)` added
- `NoteEditorScreen._onBack()` — syncs after local save; `_SaveBadge` 4 states: Saving/Local/Syncing/Synced
- `_AppShell` converted to `ConsumerStatefulWidget` + `WidgetsBindingObserver`; `syncAllPending()` on `AppLifecycleState.paused`
- `firestore.rules` created at project root
- `.gitignore` secured: `google-services.json` + `lib/firebase_options.dart` added
- Developer ran `flutterfire configure` → `lib/firebase_options.dart` has real credentials (project: `modunote-ba654`)

### Post-Extension Bug Fix — FTS5 Triggers (BUG-FTS5)

**Symptom**: Notes with heavy formatting (H1, H2, bold, italic, checkboxes, numbered/bullet lists) appeared to save once but home-screen timestamps never updated on subsequent edits. Save badge showed "Local" even on failure.

**Root cause 1**: FTS5 AFTER UPDATE trigger used invalid SQL (`UPDATE notes_fts SET…`) for an external content FTS5 table. SQLite requires the special `INSERT INTO notes_fts(notes_fts,…) VALUES('delete',…)` form. Every note UPDATE triggered this invalid SQL, causing a rollback — first INSERT succeeded (note appeared on home screen), but no UPDATE ever persisted.

**Root cause 2**: `_performAutoSave` had a dead `catch (_)` block — `NoteEditorViewModel.save()` catches `AppException` internally and doesn't rethrow, so `_isDirty` was always cleared to `false` even on failure (badge showed "Local" incorrectly).

**Fix** (D10.19 + D10.20):
- `app_database.dart` `schemaVersion` bumped to **2**
- AFTER UPDATE and AFTER DELETE triggers rewritten with correct FTS5 `'delete'` INSERT syntax
- `onUpgrade(from < 2)` drops broken triggers, recreates correct ones, rebuilds FTS index
- `_performAutoSave` checks `vmState.hasError` after save; returns early on failure (keeps `_isDirty = true`)
- `debugPrint` added to ViewModel catch block + screen error path

---

## Phase 11 — Backend API Scaffolding ✅

**Completed**: Phase 11
**Deliverable**: FastAPI backend scaffold in `modunote-api/` (sibling directory to `modunote/`). Two AI endpoint stubs returning 501. Flutter `RemoteNoteService` HTTP client wired to the API. `flutter analyze` = 0 issues.

### Backend files created (`modunote-api/`)

| File | Purpose |
|---|---|
| `main.py` | FastAPI app — mounts `/api/v1` router, `GET /health`, CORS middleware |
| `requirements.txt` | fastapi, uvicorn, sqlalchemy[asyncio], asyncpg, alembic, pydantic, pydantic-settings, python-jose, httpx |
| `docker-compose.yml` | PostgreSQL 16 on port 5432, DB `modunote_dev` |
| `.env.example` | `DATABASE_URL`, `SECRET_KEY`, `DEV_MODE=true`, `ALLOWED_ORIGINS` |
| `.gitignore` | Python virtualenv, `__pycache__`, `.env`, Alembic versions cache |
| `core/config.py` | `Settings(BaseSettings)` — reads `.env` |
| `core/auth.py` | `verify_token` — bypasses JWT when `DEV_MODE=true`; returns `"dev-user-local"` |
| `routers/notes.py` | `POST /api/v1/notes/{id}/tags/suggest` → 501; `POST /api/v1/notes/{id}/summary` → 501 |
| `models/note.py` | Pydantic: `TagSuggestRequest/Response`, `SummaryRequest/Response` |
| `db/models.py` | SQLAlchemy `Note` model stub (id, user_id, title, content, sync_status, timestamps) |
| `alembic.ini` | Alembic config — `script_location = alembic` |
| `alembic/env.py` | Async Alembic env — reads `DATABASE_URL` from settings; uses async SQLAlchemy engine |
| `alembic/versions/.gitkeep` | Empty dir placeholder — migrations added in Phase 12 |

### Flutter files changed (`modunote/`)

| File | Change |
|---|---|
| `pubspec.yaml` | Added `http: ^1.2.0` under Remote API section |
| `lib/core/errors/app_exception.dart` | Added `RemoteServiceException` final class |
| `lib/services/remote/remote_note_service.dart` | New — `RemoteNoteService` plain Dart class. `suggestTags()` + `summariseNote()` both return `UnimplementedError` (server returns 501). Base URL: `http://10.0.2.2:8000/api/v1` |

### Running the backend locally

```bash
cd modunote-api/
docker-compose up -d
python -m venv venv && venv\Scripts\activate   # Windows
pip install -r requirements.txt
copy .env.example .env   # edit values if needed (DEV_MODE=true by default)
uvicorn main:app --reload
# → http://localhost:8000/health   → {"status": "ok"}
# → http://localhost:8000/docs     → Swagger UI
```

### Architectural Decisions
See DECISIONS.md D11.6–D11.12.

---

## Decisions Log (cross-phase)

| Decision | Value | Phase set |
|---|---|---|
| State management | Riverpod 2 + code-gen | 1 |
| Local DB | Drift v2 | 1 |
| Navigation | GoRouter v14 | 1 |
| Rich text | flutter_quill v10 | 1 |
| Audio codec | AAC 32kbps mono 16kHz | 1 |
| Model equality | Equatable (not freezed) | 1 |
| Tag storage | lowercase normalised | 1 |
| Category structure | Adjacency list, max depth 5 | 1 |
| Firebase strategy | Repo interface swap (Phase 10) | 1 |
| Backend stack | FastAPI + PostgreSQL + SQLAlchemy async | 1 (planning) |
| AI features | Deferred to Phase 12 | 1 (planning) |
| Full-text search | FTS5 virtual table + 3 SQLite triggers | 2 |
| Tag denormalisation | `tagIds` JSON column on NotesTable for O(1) ViewModel access | 2 |
| Companion naming | TABLE class name + Companion (e.g. `NotesTableCompanion`) | 2 |
| Type converters | `QuillDeltaConverter`, `DateTimeConverter`, `StringListConverter` | 2 |
| Data providers lifecycle | All 5 data-layer providers use `keepAlive: true` (Phase 6 added `audioRecordRepositoryProvider`) | 2 / 6 |
| ViewModel stream pattern | `build() → Stream<T>` for list VMs; Riverpod auto-wraps as `AsyncValue<T>` | 3 |
| `NoteEditorViewModel` family param | Optional `noteId` build param; `_isNew` flag tracks first insert | 3 |
| `SearchState` pattern | `Notifier<SearchState>` with query + `AsyncValue<List<Note>>` results; 300 ms debounce | 3 |
| Category deletion policy | **Re-parent children to grandparent/root; notes → Uncategorised** | 8 |
| Navigation shell | GoRouter `ShellRoute` — `_AppShell` provides Scaffold+`BottomBar`+`MNBottomNav`+`_NavFab`; tab screens return body only | 9 |
| Theme persistence | `shared_preferences` — `ThemeModeNotifier` reads on build, writes on set; key `theme_mode` | 9 |
| Settings theme toggle | Two-tile card (Light / Dark); System = hidden third state (neither highlighted) | 9 |
| Tab navigation | `context.go` for tabs; `context.push` for Note Editor; `context.go(home)` for SearchScreen back | 9 |
| Floating bottom bar | `flutter_floating_bottom_bar ^2.0.0` — `BottomBar` hides nav on scroll; shows amber scroll-to-top icon | 9 |
| FAB notch | `_NavFab` (52 px amber circle) protrudes 20 px above nav pill; sole entry point for new note creation | 9 |
| Icon-only tabs | `_NavTab` shows icon only (no label); active tab = `primaryContainer` pill; 60 px center gap for FAB | 9 |
| Firebase repo seam | `noteRepositoryProvider` → `SyncedNoteRepository(local, remote, syncEnabled:false)`; ViewModel unchanged | 10 |
| Firebase stub: no imports | `FirebaseNoteRepository` is pure Dart — no `firebase_core` / `cloud_firestore` imports until live calls added | 10 |
| Firebase Gradle deferred | `flutterfire configure` + `google-services.json` are manual steps before Phase 11/12; Gradle unchanged in Phase 10 | 10 |
| AI provider (Gemini vs Groq) | **TBD — Phase 12** | — |

---

## Pending Decisions

| Decision | Phase to resolve |
|---|---|
| Category deletion policy when children exist | 8 ✅ Resolved: re-parent |
| AI provider evaluation (Gemini free tier vs Groq) | 12 |

---

## Documentation Produced (Post-Phase-6 Session)

The following documentation files were created or significantly updated after Phase 6 was completed. They are not code changes but are part of the project's permanent record.

### Files Updated

| File | What changed |
|---|---|
| `CLAUDE.md` | Phase 6 status marked ✅; `audio_file_storage.dart`, `audio_recording_service.dart`, `speech_to_text_service.dart` added to quick reference; `database_providers.dart` description updated to 5 `keepAlive` providers; `TESTING.md` added to quick reference (15 sections); on-boarding checklist expanded to 10 steps including `flutter analyze` gate and TESTING.md smoke test |
| `THREAD_HANDOFF.md` | Status header updated to "Phase 6 ✅ Complete. Proceed with Phase 7."; full "What was built (Phase 6)" section added; architecture decisions table updated with all Phase 6 entries; Phase 7 scope documented; first-run instructions updated; `TESTING.md` added to files-to-attach list |
| `DECISIONS.md` | Phase 6 status changed from ⬜ to ✅; D6.4 revised; D6.5–D6.9 added; D2.8 updated to 5 keepAlive providers; BUG-15–BUG-17 added (post-Phase-6 `flutter analyze` fixes: unnecessary import, deprecated STT params, missing `const`) |
| `README.md` | Replaced default Flutter stub with full project description, tech stack table, architecture overview, phase status table, getting-started commands, and key documentation references |
| `progress.md` | Phase 6 section added (this file); data providers lifecycle corrected from 4 to 5 |

### Files Created

| File | Purpose |
|---|---|
| `TESTING.md` | Full manual testing guide. **15 sections**, ~130 numbered checks covering all Phases 1–6 features. Includes: app bootstrap, note list screen, note creation + auto-save, editor + toolbar (all 9 buttons), pinning/sections, search, voice recording (permission flow, waveform, STT, timeout recovery, stop + insert, clip chips), data persistence, themes (exact color token checks), navigation/routing, stub screens, edge cases, performance, `flutter analyze` gate, and **Section 15 — Voice/STT deep verification** (exact Android on-device file paths, ADB commands for file listing + DB pulling, sqlite3 queries for `audio_records` table, logcat filtering). Quick smoke test: ~46 🔴 CRITICAL checks in ~20 min. Full regression: ~130 checks in ~1.5 hr. |

### Testing Philosophy (recorded for future phases)

- **Phases 1–9** (active feature development): Manual smoke test only. The UI changes too fast between phases to justify automating it.
- **After Phase 9** (navigation stable): Add **unit tests** for ViewModels and repository layer (`flutter_test`). These are pure Dart, fast, and don't break on UI refactors.
- **After Phase 12** (feature-complete): Add **integration tests** for critical flows (`integration_test` package). Add **GitHub Actions** CI to run `flutter analyze` + `flutter test` on every push.
- The `TESTING.md` smoke test list maps directly to future integration test cases — each numbered check is a candidate `testWidgets(...)` scenario.

---

## Phase 11.5 — Bug Fixes + UX Features ✅

**Completed**: Post-Phase 11 polish session
**Deliverable**: 5 bug fixes + 5 UX enhancements. `flutter analyze` = 0 issues.

### Bug Fixes

| # | Bug | Fix |
|---|---|---|
| Bug 1 | Dead-code condition `!widget.noteTagIds.contains(normInput)` in `_TagInputSheet.showCreate` compared tag name string against ID list — always false | Removed the dead condition; `showCreate` now only checks `normInput.isNotEmpty && !hasExactMatch` |
| Bug 2 | `⋮` button in `NoteEditorScreen` wired to empty no-op `onTap: () {}` | Added `_onMoreTap()` method + `_NoteOptionsSheet` bottom sheet; `_EditorAppBar` gains `onMoreTap: VoidCallback?` param; button disabled (muted colour, null onTap) until note is persisted |
| Bug 3 | Note list screen had no pin/archive/delete actions | Added `_SwipeableNoteCard` with `Dismissible` (swipe left = archive, swipe right = pin toggle) + long-press `_NoteActionsSheet` bottom sheet |
| Bug 4 | `LocalNoteRepository.insert/update` returned `Future<Note>` and `togglePin` returned `Future<Note?>` — mismatched `INoteRepository` interface which declares all three as `Future<void>` | Fixed return types; removed unnecessary DB re-reads from `insert`/`update`; `togglePin` reads existing then writes new pin state |
| Bug 5 | Settings screen only had Light/Dark tiles — ThemeMode.system was unrepresented in UI | Added third "System" tile with `Icons.brightness_auto_outlined` and a split light/dark mini-preview |

### UX Enhancements (S1–S5)

| # | Feature | Implementation |
|---|---|---|
| S1 | Swipe-to-dismiss on note cards | `Dismissible` in `_SwipeableNoteCard`; `confirmDismiss` always returns `false` (springs back); Drift stream handles card removal |
| S2 | Note options sheet from ⋮ button | `_NoteOptionsSheet` (`_OptionsRow` × 3): Pin/Unpin, Archive, Delete. Delete triggers `AlertDialog` confirm. Archive + Delete navigate back after action. |
| S3 | System theme tile | Third tile in `_AppearanceCard` row; 3 `Expanded` tiles with reduced padding; `_ThemeTile` now takes `_PreviewType` enum instead of `bool isDarkPreview`; System preview = split left-light / right-dark card |
| S4 | Archive screen | New `lib/presentation/views/archive/archived_notes_screen.dart`. `ArchivedNotesScreen extends ConsumerWidget`. Swipe right = restore, swipe left = delete (with confirm dialog). Access via Settings "Archived Notes" card. Route: `/archive` (outside ShellRoute). |
| S5 | Category/tag filter chip bar on NoteListScreen | `_FilterChipBar ConsumerWidget` below search field: "All" chip + category chips + tag chips. Backed by `NoteFilterNotifier @riverpod` Notifier. `NoteListViewModel.build()` watches `noteFilterNotifierProvider` and calls `watchAll()`, `watchByCategory()`, or `watchByTag()` accordingly. |

### New Files

| File | Purpose |
|---|---|
| `lib/presentation/viewmodels/archived_notes_view_model.dart` | `ArchivedNotesViewModel @riverpod` — `build()` → `watchArchived()`, `restore(id)`, `delete(id)` |
| `lib/presentation/views/archive/archived_notes_screen.dart` | Archive screen — full-screen, back button, dismissible cards, empty state |

### Modified Files

| File | Key changes |
|---|---|
| `lib/data/repositories/interfaces/i_note_repository.dart` | Added `watchArchived()` and `unarchive()` abstract methods |
| `lib/data/datasources/local/daos/notes_dao.dart` | Added `watchArchived()` and `unarchiveNote()` methods |
| `lib/data/repositories/local/local_note_repository.dart` | Fixed `insert`/`update`/`togglePin` return types; added `watchArchived()`/`unarchive()` |
| `lib/data/repositories/remote/firebase_note_repository.dart` | Added `watchArchived()` stub + `unarchive()` Firestore call |
| `lib/data/repositories/synced/synced_note_repository.dart` | Added `watchArchived()` and `unarchive()` delegating to `_local` |
| `lib/presentation/viewmodels/note_list_view_model.dart` | Added `NoteFilterType` enum, `NoteFilter` class, `NoteFilterNotifier @riverpod`; `NoteListViewModel.build()` watches filter |
| `lib/presentation/viewmodels/note_editor_view_model.dart` | Added `togglePin()`, `archive()`, `delete()` methods |
| `lib/presentation/widgets/mn_note_card.dart` | Added optional `onLongPress: VoidCallback?` parameter |
| `lib/presentation/views/note_list/note_list_screen.dart` | `_DataBody` → `ConsumerWidget`; added `_SwipeableNoteCard`, `_NoteActionsSheet`, `_FilterChipBar`, `_FilterChip` |
| `lib/presentation/views/note_editor/note_editor_screen.dart` | Bug 1 dead-code removed; `_onMoreTap()`, `_showDeleteConfirm()`, `_NoteOptionsSheet`, `_OptionsRow` added; `_EditorAppBar` gains `onMoreTap`; `_CircleIconButton.onTap` made nullable |
| `lib/presentation/views/settings/settings_screen.dart` | 3-tile `_AppearanceCard`; `_PreviewType` enum; `_SystemMiniPreview`; `_ArchiveCard` link to `/archive` |
| `lib/presentation/router/app_router.dart` | Added `AppRoutes.archive`; added `GoRoute` for `/archive` → `ArchivedNotesScreen` |

### Build Results

```
dart run build_runner build --delete-conflicting-outputs  # 99 outputs in 27s
flutter analyze                                           # No issues found! ✅
```

---

## Post-Phase 1 Bugfix — app_router.g.dart stub incomplete

**Issue**: `Undefined name 'themeModeNotifierProvider'` error at compile time.

**Root cause**: The pre-generated `app_router.g.dart` stub was missing the
`themeModeProvider` entry (generated from the `themeMode` convenience function).
When a `part` file has a missing declaration, Dart marks the entire part as
broken — causing all symbols from it (including `themeModeNotifierProvider`) to
appear undefined, even though that definition was present.

**Fix**: Added the missing `themeModeProvider` block to `app_router.g.dart`.
The stub now contains all three generated symbols:
- `routerProvider` (from `router` function)
- `themeModeNotifierProvider` (from `ThemeModeNotifier` class)
- `themeModeProvider` (from `themeMode` convenience function) ← was missing

**File changed**: `lib/presentation/router/app_router.g.dart`

**Reminder**: This stub is only a compile-time shim. Running
`dart run build_runner build --delete-conflicting-outputs` replaces it with
the real generated output and should always be done before first run.
