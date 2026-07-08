# ModuNote — Phase 12 AI Implementation Plan (all stages)

> **Purpose**: The single, detailed, build-from-here spec for ModuNote's AI work. Any agent in any thread follows THIS file so the approach never deviates. It is the *how* — distinct from `DECISIONS.md` (the *why*) and `STATUS.md` (the *where we are*).
>
> **How to use this file**
> - Work top-to-bottom, one stage at a time. Do not start a stage until the previous one's checklist is fully ticked.
> - Each stage has a **Task checklist** with `[ ]` items. Tick them (`[x]`) as you complete them and note the date. This is the progress anchor — a fresh agent reads the checklist to know exactly where to resume.
> - When a stage completes: tick its checklist, update `STATUS.md` "Current Status & Next Phase", append a `DECISIONS.md` entry for any non-obvious choice, and update `session_context.md`.
> - If reality forces a deviation from this plan, **update this file first** (with a one-line reason), then proceed. Never silently diverge.
> - **Priority of the remaining stages vs. other work streams is tracked canonically in the root `README.md` → "Roadmap"** (2026-07-08: Stage 3 is P1, Stage-4 leftovers P4). This file remains the *how* for the stages.

---

## Locked decisions (do not re-litigate — see `DECISIONS.md` Phase 12)

| Decision | Value |
|---|---|
| Provider | **Groq** (chat — `llama-3.3-70b-versatile`). Stage 2 embeddings via **hosted Jina `jina-embeddings-v2-base-en`, 768-dim** (Groq has none; switched from the earlier local `sentence-transformers` plan on 2026-06-27 — Render free 512 MB RAM can't fit PyTorch, see `DECISIONS.md` D12.7). Switched chat provider from Gemini 2026-06-22. |
| Architecture | **Flutter → FastAPI (`modunote-api/`) → Groq.** Flutter never calls the LLM directly. API key stays server-side. |
| Auth/scope | **Single-user.** Local dev: `DEV_MODE=true` bypass. Deployed (Stage 4): one static API key in a request header. No multi-tenant/JWT-per-user. |
| Stage 1 UI | **Both** — auto-tag suggestions as a dismissible banner + a bottom sheet for the text-rewrite actions. |
| Stage 2 QnA UI | **New dedicated QnA screen** (own route + nav entry). |
| Save flow | AI calls are **always async and never block** local Drift auto-save. Failure is silent/non-fatal. |
| Quality bars | `flutter analyze` = 0 issues; backend `ruff`/`mypy` clean (if configured). No git ops by Claude. |

### Reused codebase facts the plan depends on
- `lib/services/remote/remote_note_service.dart` already exists (HTTP client, base URL `http://10.0.2.2:8000/api/v1`, `suggestTags()` + `summariseNote()` stubs).
- Backend `modunote-api/` already has FastAPI + `core/config.py` (Settings) + `core/auth.py` (DEV_MODE bypass returns `"dev-user-local"`) + `routers/notes.py` (501 stubs) + async Alembic.
- **Important correction**: the backend is NOT the source of truth for notes (reads stay local — `DECISIONS.md` D10.11). So endpoints **receive note text in the request body** from Flutter; they do not fetch notes by id from a backend store. The existing `/{id}/…` stubs are repurposed to body-based contracts below.
- Quill content is Delta JSON. Flutter must extract **plain text** from the Delta before sending (helper needed — see Stage 1).
- Errors from `RemoteNoteService` wrap in `RemoteServiceException` (`DECISIONS.md` D11.9).
- All new Flutter providers use `@riverpod` code-gen; run `dart run build_runner build --delete-conflicting-outputs` after adding any.

### New dependencies (install at the start of the stage that needs them)

| Stage | Flutter (`pubspec.yaml`) | Backend (`requirements.txt`) | Env vars (backend `.env`) |
|---|---|---|---|
| 1 | none (uses `http`) | `groq` | `GROQ_API_KEY`, `GROQ_MODEL=llama-3.3-70b-versatile` |
| 2 | none | `asyncpg` (uncomment), `pgvector`, `tiktoken` (chunk sizing) — *not* `sentence-transformers` (D12.7) | `DATABASE_URL`=Supabase, `JINA_API_KEY`, `JINA_MODEL=jina-embeddings-v2-base-en`, `EMBED_DIM=768`, `RAG_TOP_K=5` |
| 3 | `sentry_flutter` (optional, app-side) | `langfuse`, `sentry-sdk[fastapi]`, `ragas`, `datasets` | `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, `LANGFUSE_HOST`, `SENTRY_DSN` |
| 4 | none (build-time `--dart-define=API_BASE_URL=…`) | none new | `API_KEY` (static, single-user), `ALLOWED_ORIGINS` |

> ⚠️ Model names change. Verify the Groq chat model at https://console.groq.com/docs/models (and the embedding model at Stage 2). Keep model names in config, never hardcoded in call sites.

---

## Data flow (all stages)

```
Stage 1 (stateless):
  Editor → RemoteNoteService → POST /assist|/tags/suggest|/summary (note text in body)
        → FastAPI ai_service → Groq chat → JSON back → editor banner/sheet

Stage 2 (stateful, RAG):
  (index)  Note saved & tagged study/notes → RemoteNoteService.indexNote(text)
           → POST /index/notes → chunk → local embed (sentence-transformers) → pgvector upsert
  (ask)    QnA screen → RemoteNoteService.ask(question)
           → POST /qna → embed question → pgvector top-k → Groq answer+citations → screen

Stage 3: every LLM call wrapped in Langfuse trace; FastAPI errors → Sentry; RAGAS offline eval script.
Stage 4: same API behind Caddy (TLS) on a VM; Flutter points at prod URL via --dart-define; GitHub Actions deploys.
```

---

# STAGE 1 — Writing assistant (first feature)

**Goal**: From the note editor, the user can run AI text actions and get tag suggestions, all routed through the backend to Groq. Stateless — no DB tables, no migration.

### 1A. Backend (`modunote-api/`)

**Endpoints** (all under `/api/v1`, all accept note content in the body):

| Method | Path | Request body | Response |
|---|---|---|---|
| POST | `/assist` | `{ "action": "improve\|humanize\|paraphrase\|script\|critique", "title": str, "content": str, "tags": [str] }` | `{ "result": str }` |
| POST | `/tags/suggest` | `{ "title": str, "content": str, "existing_tags": [str] }` | `{ "suggested_tags": [str] }` (≤5, lowercase) |
| POST | `/summary` | `{ "title": str, "content": str }` | `{ "summary": str }` (1–3 sentences) |

- Create `services/ai_service.py`: a thin Groq client (`AsyncGroq`). One function per action that builds the prompt, calls `client.chat.completions.create(model=settings.groq_model, messages=[...])`, and returns `choices[0].message.content`. Centralise the model + temperature here.
- Add Pydantic request/response models in `models/` (e.g. `models/ai.py`).
- Wire into `routers/notes.py` (or a new `routers/ai.py`) — replace the 501 stubs.
- `core/config.py`: add `GEMINI_API_KEY`, `GEMINI_MODEL`. Read from env, never hardcode. Add to `.env.example`.
- Auth: keep `core/auth.py` DEV_MODE bypass for now (single-user).
- **Prompts** (store as constants in `ai_service.py`; keep them version-controlled):
  - *improve*: "Improve clarity, flow, and concision of the following note. Keep the author's meaning and voice. Return only the rewritten text."
  - *humanize*: "Rewrite to sound natural and spoken, as a content creator would say it aloud. Remove robotic/AI phrasing. Return only the rewritten text."
  - *paraphrase*: "Paraphrase the following while preserving meaning. Return only the rewritten text."
  - *script*: "Restructure the following note into a short video script with a hook, body, and call-to-action. Return only the script."
  - *critique*: "Give 3–5 concise, actionable suggestions to improve this note. Return a bullet list, no preamble."
  - Every prompt is suffixed with the note's tags as context: "Context tags: {tags}." plus the title and content.
  - *tags/suggest*: "Suggest up to 5 short, lowercase, single- or two-word tags for this note. Exclude these existing tags: {existing}. Return a JSON array of strings only."
  - *summary*: "Summarise this note in 1–3 sentences. Return only the summary."
- Output hygiene: trim whitespace; for tags, parse JSON defensively and re-normalise to lowercase; cap lengths.

**Stage 1 backend checklist**
- [x] `groq` added to `requirements.txt`; `GROQ_API_KEY` + `GROQ_MODEL` in `config.py` + `.env.example` (2026-06-22; switched from Gemini)
- [x] `services/ai_service.py` with the 5 actions + tag-suggest + summary, prompts as constants
- [x] Pydantic request/response schemas — *deviation*: added to `models/note.py` alongside the existing TagSuggest/Summary models rather than a separate `models/ai.py` (less churn)
- [x] `/assist`, `/tags/suggest`, `/summary` endpoints return real Groq output (501 removed) — `routers/notes.py`
- [x] Manual test via Swagger (`/docs`) with `DEV_MODE=true` — **developer confirmed the backend works (2026-06-22)** with a real `GROQ_API_KEY`
- [x] Errors return clean 4xx/5xx (502 on provider error, 422 on empty content) — no stack traces leaked

### 1B. Flutter

- Add a **plain-text extractor** for Quill Delta (e.g. `lib/core/extensions/quill_extensions.dart` → `String plainTextFromDelta(Map content)`), used to build request bodies.
- `RemoteNoteService`: implement `assist(action, title, content, tags)`, `suggestTags(...)`, `summarise(...)` returning typed results; wrap failures in `RemoteServiceException`.
- New `@riverpod` ViewModel `AiAssistViewModel` (family by `noteId`) holding `AsyncValue` for in-flight calls; methods per action. Keep it separate from `NoteEditorViewModel` so AI state never interferes with save state.
- **UI — "Both"**:
  - *Tag-suggest banner*: after a note is saved/closed (reuse the existing sync-on-close hook), call `suggestTags`; if results return, show a dismissible banner (on the note card in the list and/or top of the editor) with chips → tap a chip to add the tag via the existing `addTag()` flow; × dismisses.
  - *Text-actions bottom sheet*: add an "AI" action to the editor (toolbar button or the existing ⋮ `_NoteOptionsSheet`). Opens `_AiToolsSheet` listing Improve / Humanize / Paraphrase / Script / Critique. On tap: show a loading state in the sheet, call the backend, then show the result with **Insert / Replace / Copy / Dismiss**. "Summarise" inserts a blockquote at the top of the Quill doc (reuses `/summary`).
- Never block save: all calls fire after `_performAutoSave()` completes; on error show a SnackBar ("AI unavailable — try again"), note already saved.

**Stage 1 Flutter checklist**
- [x] Quill plain-text extractor helper — `lib/core/extensions/quill_extensions.dart` (2026-06-22)
- [x] `RemoteNoteService.assist` added; `suggestTags`/`summariseNote` now live; `existingTags` param added; `RemoteServiceException` on failure
- [x] `remoteNoteServiceProvider` (`@riverpod`) + `build_runner` run — *deviation*: no `AiAssistViewModel`; the editor uses the service provider directly, consistent with how the screen owns `AudioRecordingService`/`SpeechToTextService` (D6.8/D11.7)
- [x] Tag-suggest banner — `_TagSuggestBanner`; auto-fetches once when content ≥15 chars & note untagged (fires on open for existing notes and after first autosave for new ones); chips → find-or-create tag → `addTag()`; dismissible (2026-06-22)
- [x] `_AiToolsSheet` opened from the ⋮ `_NoteOptionsSheet` ("AI assist"): 5 actions + Summarise; result shows Insert / Replace / Copy / Back; Summarise inserts a top blockquote
- [x] AI calls fire after `_performAutoSave()`; failures non-fatal (silent for suggestions, error state in the sheet for actions)
- [x] `flutter analyze` = 0 issues (full Stage 1)

### Stage 1 acceptance
Open a note → run "Humanize" → see rewritten text in the sheet → Insert works. Close the note → tag-suggest banner appears with relevant lowercase tags → tapping a chip adds it. Airplane mode → actions fail gracefully, note still saved.

---

# STAGE 2 — RAG QnA backend + dedicated screen

**Goal**: Ask natural-language questions about notes tagged study/notes; get answers grounded in those notes with citations. Stateful (pgvector). This stage adds the only new sync path in the project.

### 2A. The sync design (build this first)
- The backend must hold the **plain text** of indexable notes. Indexable = notes carrying any of the configured trigger tags (default constant `RAG_INDEX_TAGS = {study, notes, research}` — store in `AppConstants` Flutter-side and mirror in backend config).
- Trigger: when an indexable note is saved/closed (reuse the existing sync-on-close hook used for Firestore), call `RemoteNoteService.indexNote(noteId, title, plaintext, tags)`. When a note loses all trigger tags or is deleted, call `RemoteNoteService.deindexNote(noteId)`.
- Endpoints:
  - POST `/index/notes` — body `{ "note_id": str, "title": str, "content": str, "tags": [str] }` → upsert (re-chunk + re-embed, replacing prior chunks for that note_id).
  - DELETE `/index/notes/{note_id}` — remove all chunks for that note.

### 2B. Backend RAG pipeline
> **Deviation (2026-06-27, D12.7):** embeddings are **hosted Jina `jina-embeddings-v2-base-en` (768-dim)** over `httpx`, not local `sentence-transformers`; the vector store is **Supabase Postgres + pgvector** (set `DATABASE_URL` to the Supabase connection string), not the Render/local Postgres. The vector column is therefore `vector(768)`. Backend was stateless until now — Stage 2 also adds the runtime DB session (`db/session.py`) and re-enables `asyncpg`.
- Enable **pgvector**: `CREATE EXTENSION IF NOT EXISTS vector;` Add via the first Alembic migration.
- Tables (Alembic `revision --autogenerate` after defining models in `db/models.py`):
  - `documents` (note_id PK, title, tags, updated_at)
  - `chunks` (id PK, note_id FK, chunk_index, text, embedding `vector(768)` — match `jina-embeddings-v2-base-en` dims) + an ivfflat/hnsw cosine index on `embedding`.
- Ingestion: chunk plain text (~500–800 tokens, ~100 overlap; use `tiktoken` for sizing) → embed each chunk via the **Jina embeddings API** (`services/embedding_service.py`) → upsert into `chunks`.
- Retrieval (`/qna`, body `{ "question": str }` → `{ "answer": str, "citations": [{note_id, title, snippet}] }`):
  - embed the question → pgvector cosine top-k (`RAG_TOP_K`, default 5) → build a context block with source labels → Groq chat prompt: "Answer the question using ONLY the provided notes. Cite the note titles you used. If the notes don't contain the answer, say so." → return answer + the citation list (the retrieved chunks' note_id/title/snippet).
- Guard: if no chunks indexed or retrieval empty, return a friendly "No indexed notes to answer from yet."

**Stage 2 backend checklist**
- [x] `pgvector` dependency + `CREATE EXTENSION vector` in first Alembic migration (2026-06-27 — `alembic/versions/0001_rag_tables.py`; also `asyncpg`, `tiktoken`)
- [x] `db/models.py` `documents` + `chunks` (vector column + HNSW ANN index); `db/session.py` runtime async session added (2026-06-27). *(`alembic upgrade head` is the developer step S2-B8 — needs a live Supabase DB.)*
- [x] `services/rag_service.py`: chunk (tiktoken) → embed (Jina) → upsert; deindex; retrieve top-k (2026-06-27)
- [x] `/index/notes` (upsert), `DELETE /index/notes/{id}`, `/qna` endpoints — `routers/rag.py`, wired into `main.py` (2026-06-27)
- [x] Embedding dim = 768 (`jina-embeddings-v2-base-en`); cosine op class (`vector_cosine_ops`) on the HNSW index (2026-06-27)
- [ ] Swagger test: index 2–3 notes, ask a question, get a grounded answer + citations *(developer step S2-B8 — needs Supabase `DATABASE_URL` + `JINA_API_KEY`)*

> Validated by an import/wiring smoke test (`venv` python): all modules import, the pgvector cosine query compiles, the chunker works, routes registered. `flutter analyze` = 0.

### 2C. Flutter — dedicated QnA screen
- New route (e.g. `/qna`) and a nav entry (add a destination, or a prominent card/icon — keep the 4-tab shell or add a 5th destination; document the choice in DECISIONS when built).
- `QnaScreen` (`ConsumerStatefulWidget`) — chat-style: question input, answer bubbles, citation chips that deep-link to the source note (`/note/:id`).
- `QnaViewModel` (`@riverpod`) holds the Q/A turns + in-flight state.
- `RemoteNoteService.indexNote/deindexNote/ask` implemented.
- Wire indexing into the note save/close path for trigger-tagged notes (and deindex on tag removal/delete).

**Stage 2 Flutter checklist**
- [x] `AppConstants.ragIndexTags`; index/deindex wired into note save-close (`_scheduleRagSync` in `_onBack`) + delete (2026-06-27)
- [x] `RemoteNoteService.indexNote/deindexNote/ask` (+ `QnaAnswer`/`Citation` model) (2026-06-27)
- [x] `/qna` route + Home "Ask your notes" card (`_AskNotesCard`); `QnaScreen` (chat UI + citation chips → `editNotePath`) (2026-06-27)
- [x] `QnaViewModel` (`@riverpod`, auto-dispose); `build_runner` run (2026-06-27)
- [x] `flutter analyze` = 0 issues (2026-06-27)

### Stage 2 acceptance
Tag 2–3 notes `#study`, close them (they index) → open QnA screen → ask a question answerable from those notes → get a grounded answer + tappable citations that open the right note. Ask something unrelated → model says it can't answer from the notes.

---

# STAGE 3 — Observability & evals

**Goal**: See, measure, and guard every AI call. Build incrementally; Sentry first (cheap), then Langfuse, then evals.

- **Sentry** (backend): `sentry-sdk[fastapi]`, init in `main.py` with `SENTRY_DSN`. Captures unhandled errors. ~5 lines. (Optional `sentry_flutter` app-side for crash reporting.)
- **Langfuse**: wrap every LLM + embedding call in a Langfuse trace/span (prompt, model, tokens, latency, cost). Use a decorator/util in `ai_service.py` + `rag_service.py` so no call site is untraced. Cloud free tier or self-host.
- **Evals (RAGAS / LLM-as-judge)**: an offline script `eval/run_eval.py` + a small hand-built dataset (`eval/dataset.jsonl`: question, ground-truth-ish answer, expected source notes) drawn from your own notes. Score faithfulness + answer relevancy + context precision. Run before/after prompt or retrieval changes; record scores in `STATUS.md`.
- **Guardrails (light)**: start with Pydantic validation (already) + explicit checks — max output length, strip/refuse empty input, detect when retrieval is empty and short-circuit, basic profanity/PII check only if needed. Do NOT pull in a heavy framework unless a concrete need appears.

**Stage 3 checklist**
- [x] Sentry in FastAPI (`SENTRY_DSN`) *(code done 2026-07-08: `sentry-sdk[fastapi]==2.64.0`, init in `main.py` gated on `settings.sentry_dsn` — errors-only, `traces_sample_rate=0.0` (Langfuse owns tracing), `send_default_pii=False`, environment from `DEV_MODE`; `SENTRY_DSN` added to config/.env.example/render.yaml `sync:false`; 26 pytest green. **Developer:** create the free sentry.io project (platform FastAPI), paste the DSN into Render, redeploy, force one error to confirm it lands.)*
- [ ] Langfuse tracing on ALL Groq + embedding calls (no untraced call site)
- [ ] `eval/dataset.jsonl` (≥10 Q/A from real notes) + `eval/run_eval.py` (RAGAS) producing scores
- [ ] Baseline eval scores recorded in `STATUS.md`
- [ ] Guardrails: output caps, empty-input refusal, empty-retrieval short-circuit

### Stage 3 acceptance
A QnA request shows up as a full trace in Langfuse (prompt, tokens, latency, cost). A forced backend error appears in Sentry. `python eval/run_eval.py` prints faithfulness/relevancy scores.

---

# STAGE 4 — Production deployment (scope = "deploy," not billed SaaS)

> 🟢 **Pulled forward to after Stage 1 (2026-06-22)** so a physical device can reach the API without the laptop. Chosen approach: **Render free web service** (no credit card), deployed from the GitHub repo via `render.yaml`. Render free's cold start is defeated with a **keep-warm pinger** on the unauthenticated `/health` (cron-job.org / UptimeRobot, ~10 min). This replaces the Caddy + domain plan below. Full runbook: `modunote-api/DEPLOY.md`. (A GCP-VM + Tailscale-Funnel plan was considered first but dropped — GCP/Oracle require card verification.)

**Goal**: The API runs on a real host with HTTPS, auto-deploys from GitHub, and is monitored. Single-user auth via a static API key.

- **Auth for prod**: switch from DEV_MODE bypass to a single static `API_KEY` checked in `core/auth.py` (header `X-API-Key`). Flutter sends it; injected at build time via `--dart-define`. (Still single-user — no per-user accounts.)
- **Containerize**: `Dockerfile` for the API; `docker-compose.prod.yml` with `api` + `postgres` (pgvector image, e.g. `pgvector/pgvector:pg16`) + `caddy`.
- **Caddy**: reverse proxy with automatic HTTPS/TLS (`Caddyfile` with the domain → `api:8000`). One of the simplest ways to get TLS.
- **Hosting**: recommended small VM (Hetzner CX22 / DigitalOcean droplet) or Fly.io. **Final pick deferred to Stage 4 start** — record in DECISIONS. Keep cost near $0–$5/mo (free Groq tier + tiny VM + local embeddings).
- **CI/CD**: GitHub Actions — on push to main: lint (`ruff`) + type-check (`mypy`) + any tests → build image → deploy (SSH/`docker compose pull && up -d`, or Fly deploy). Secrets in GitHub Actions secrets, never in the repo.
- **CORS**: restrict `ALLOWED_ORIGINS` to the web app origin (`modunote-ba654.web.app`) + localhost.
- **Flutter**: replace the `10.0.2.2` dev base URL with the prod URL via `--dart-define=API_BASE_URL=…`; default stays localhost for dev. Rebuild web + Android pointing at prod.
- **Backups**: a simple `pg_dump` cron (the vector store can be rebuilt by re-indexing, but back up anyway).

**Stage 4 checklist**
- [x] `API_KEY` auth in `core/auth.py` (X-API-Key when `DEV_MODE=false`); Flutter sends `X-API-Key` via `--dart-define` (`API_BASE_URL` + `API_KEY`) (2026-06-22)
- [x] `render.yaml` Blueprint (free web service, secrets `sync:false`); `Dockerfile` kept for local/portability
- [x] Cold start defeated with a keep-warm pinger on `/health` (no card; within 750 free hrs/mo)
- [ ] **Developer step**: create the Render service from `render.yaml`, set `GROQ_API_KEY` + `API_KEY` in the dashboard, add the keep-warm pinger — see `modunote-api/DEPLOY.md`
- [ ] CORS restricted to the web origin via `ALLOWED_ORIGINS` (set in Render env)
- [ ] (later) auto-deploy is automatic on push; add monitoring (Langfuse + Sentry); managed Postgres at Stage 2

### Stage 4 acceptance
Push to main → Action builds and deploys → the live HTTPS API answers a QnA request from the deployed web app, traced in Langfuse, with the static API key enforced.

---

## Open items deferred by design (decide at the relevant stage, then record in DECISIONS)
- ✅ **QnA nav placement** *(resolved 2026-06-27, D12.7)*: **Home-screen card** ("Ask your notes") → `/qna`. Not a 5th tab (the 4-tab pill + center FAB is full).
- ✅ **Embeddings + vector host** *(resolved 2026-06-27, D12.7)*: hosted Jina (768-dim) + Supabase pgvector.
- ✅ **RAG trigger tags** *(user-configurable, done 2026-06-27)*: default `{study, notes, research}`, now editable from Settings + persisted (`RagIndexTags` notifier, key `rag_index_tags`); `_scheduleRagSync` reads the live set. See D12.7. ✅ **Refinement (S2-F9, done 2026-06-27):** the Settings scope picker offers ONLY existing tags (bottom-sheet picker over `tagListViewModelProvider`); no free-text creation.
- **Deployment host**: Render (web service) chosen at Stage 4 (D12.6); Supabase for the DB (D12.7).
- **Chunk size / top_k**: start 500–800 tokens / k=5; tune using Stage 3 eval scores.

## Things that must NOT happen (anti-drift guardrails)
- Do NOT call the LLM provider (Groq) directly from Flutter. Always via the backend.
- Do NOT put the Groq API key in the Flutter app or any committed file.
- Do NOT introduce Chroma or a second vector store — pgvector in the existing Postgres only.
- Do NOT make AI calls block local save. Local Drift is always authoritative.
- Do NOT add multi-user accounts/billing — single-user is the locked scope.
- Do NOT skip `build_runner` after `@riverpod` changes, or commit with `flutter analyze` issues.
