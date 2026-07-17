# ModuNote — UI Polish Plan

> Standing plan for the post-Stage-2 **UI polish queue** (developer-requested, 2026-06-27). Companion to `STATUS.md` (live status), `DECISIONS.md` (rationale), and `PHASE_12_PLAN.md` (AI stages). **Rule: do one item at a time; scope it — and show a mockup for visual items — before writing code.**

## Process rules (every item)
- One item at a time, in queue order. Get approval on scope before coding.
- For visual items, present mockup variant(s) and let the developer pick before building.
- `flutter analyze` = 0 after each change; run the read-only Dart verification subagent.
- No git ops (developer commits via GitHub Desktop); append each request verbatim to `session_context.md`; update `STATUS.md`/`CLAUDE.md`/`DECISIONS.md` as items land.

## Build queue (order updated 2026-06-27)
1. ✅ **Skeleton loaders** — DONE. `skeletonizer` + `presentation/widgets/mn_skeletons.dart`; Tags / Search / Archive / Note editor loading states. (STATUS S2-F11.)
2. ✅ **Voice panel redesign** — DONE (2026-06-27). **Variant A** — pill→card grow via `AnimatedContainer`+`AnimatedSize` in `_VoicePanel.build()`; behavior preserved. B kept as a documented 1-prompt fallback (below). (STATUS S2-F12.)
3. ✅ **Test suite** — DONE (2026-06-29). Focused-starter suite: Flutter models + view-models (mocktail) + local repos (in-memory Drift) + RemoteNoteService (http MockClient) = **73 tests**, `flutter analyze` = 0; backend pytest (`modunote-api/`) = **18 tests** (rag_service `_chunk_text` + answer_question short-circuit, ai_service `_parse_tags`, FastAPI endpoints via TestClient with the service layer mocked). Done *before* de-bloat as a refactor safety net. See the "Test suite" section in `STATUS.md`.
4. 🟡 **Efficiency / de-bloat pass** — structure rounds DONE (2026-07-08): editor 2,697→944, note_list 1,137→137, settings 918→53; widgets extracted verbatim to per-screen `widgets/` subfolders (see STATUS). Remaining optional rounds: deps/assets/build-size audit (descoped by developer so far).
5. ⬜ **Startup UX** — splash screen + first-run onboarding slides.

> **Priority across ALL work streams is tracked canonically in the root `README.md` → "Roadmap"** (this file only specs the UI queue items). Per that roadmap, Stage 3 (Sentry/Langfuse/RAGAS, `PHASE_12_PLAN.md`) now comes BEFORE the remaining queue items here.

---

## Item 2 — Voice panel redesign (current focus)

**Goal:** modernise the voice recording + seek UI so it echoes the floating navbar pill, with an **animated expansion**: collapsed state = a rounded **pill**; on tap it **animates growing bigger** into the full panel; collapsing animates back down to the pill. ("We can improve on the original design after.")

**Current widget:** `_VoicePanel` in `lib/presentation/views/note_editor/note_editor_screen.dart` — play/pause, drag-to-seek bar, `current:total` timers, record/mic button, one-at-a-time recording carousel (prev/next); expanding reveals transcript + Paraphrase (opens the Stage-1 AI sheet) + Insert-into-note + red-trash delete. It's bottom-anchored and **swaps with `MNEditorToolbar`** based on keyboard visibility (`MediaQuery.viewInsets.bottom`).

**Animation approach (implementation, once a variant is chosen):**
- Morph pill → panel with `AnimatedContainer`/`AnimatedSize` (or an `AnimationController` + `SizeTransition`/`AlignTransition`) animating height, width, and corner radius; cross-fade the expanded content in.
- Keep it bottom-anchored; preserve the keyboard-up (toolbar) ↔ keyboard-down (voice panel) swap.
- Preserve ALL existing functions: play/pause, drag-seek, timers, record, carousel, transcript, Paraphrase, Insert, delete-with-confirm.
- Use `AppColors`/`AppTypography`; pill styling consistent with `MNBottomNav`.

**Chosen direction (2026-06-27): Variant A — anchored card that grows from the pill.** Collapsed = a full-width rounded pill flush to the bottom (play · seek · `current:total` · mic); tapping animates it growing straight up into a rounded card (all corners rounded) revealing the waveform, transcript, and Paraphrase / Insert / delete actions. Animate height + corner-radius (`AnimatedContainer`/`AnimatedSize`) with expanded content cross-fading in.

### Variant B (documented fallback — switch is a single prompt)
If A is disliked, "switch to Variant B" regenerates it cleanly against the then-current code (no commented-out/dead code kept, per the de-bloat goal). **B spec:** identical collapsed pill + expanded content as A, but the panel is a **floating pill with side margins and a soft drop shadow** (mirrors `MNBottomNav`) that inflates *in place* while staying floating — rather than A's edge-to-edge anchored card. (Variant C, considered but not chosen: morphs into a bottom sheet with a grab handle, top-rounded corners.) The interactive mockup of all three lives in the 2026-06-27 chat (`voice_panel_grow_from_pill_variants`).

---

## Item 3 — Startup UX (after voice panel)
- **Splash screen:** native (`flutter_native_splash`, shown while engine loads) and/or an animated in-app splash. *Decisions needed:* logo asset (wordmark vs image), static / animated / both.
- **First-run onboarding:** a `PageView` carousel of feature slides, shown once on first launch, gated by a SharedPreferences "seen" flag. *Decisions needed:* slide content + count, custom vs `introduction_screen` package.

## Item 3 — Test suite (DONE 2026-06-29)
**Flutter** (`modunote/test/`, mirrors `lib/`):
- Models — `copyWith`/equality for Note/Tag/Category/AudioRecord; `fromJson` for QnaAnswer/Citation. Core extensions — `StringExtensions`, `plainTextFromDelta`.
- ViewModels — RagIndexTags (SharedPreferences), QnaViewModel, NoteListViewModel, RagReindex — via `ProviderContainer` + `overrideWithValue` of repo/service providers backed by mocktail mocks (`test/util/mocks.dart`).
- Local repos — LocalNoteRepository + LocalTagRepository against `AppDatabase(NativeDatabase.memory())`.
- RemoteNoteService — `http` `runWithClient` + `MockClient` (no class refactor): assist/ask/indexNote/deindexNote happy + error paths.
- **sqlite3-on-Windows wrinkle solved** in `test/util/sqlite3_test_setup.dart`: `ensureSqlite3()` probes for a host lib, else downloads the official `sqlite3.dll` once into the gitignored `test/.cache/`; repo tests skip gracefully if it can't be obtained. Dev-deps added: `sqlite3`, `archive`.
- Kept the pre-existing `test/presentation/views/settings_scope_picker_test.dart`; removed the no-op `test/widget_test.dart`.

**Backend** (`modunote-api/`, separate repo): `requirements-dev.txt` (pytest + pytest-asyncio), `pytest.ini` (asyncio auto), `tests/` — `_chunk_text` + `answer_question` empty-retrieval short-circuit (embedding/session mocked), `_parse_tags`, and endpoints (`/health`, `/assist`, `/qna`, `/index/notes`) via `TestClient` with auth + DB-session dependencies overridden and the service layer monkeypatched. No live Groq/Jina/DB.

Run: `flutter test` (modunote) · `python -m pytest` (modunote-api, deps from `requirements-dev.txt`).

---

## Context snapshot (so this plan stands alone)
- Phase 12 Stage 2 (RAG QnA) code complete; **Render backend verified working 2026-06-27** (live `/qna` + `/index` return 200 after switching Render's `DATABASE_URL` to the Supabase session pooler).
- Debugging: `.vscode/launch.json` has "ModuNote (Render API)" (full debug + Inspector + AI via `--dart-define-from-file=dart_defines.json`) and "ModuNote (local / no backend)".
- Remaining AI roadmap (separate from this UI queue): Stage 3 observability/evals, Stage 4 deployment hardening — see `PHASE_12_PLAN.md`.
