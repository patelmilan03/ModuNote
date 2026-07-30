# ModuNote — BACKLOG (single source of truth for all planned work)

> **This file is the ONE prioritized list of everything actionable on ModuNote** — tasks, bugs, cleanup, roadmap features, ops chores, and open decisions. If it is planned and not yet done, it lives here, ranked.
>
> **Maintenance rules (also in `CLAUDE.md`):**
> 1. **New idea / change / bug → add ONE row here first.** Do not scatter it into README, STATUS, or any other doc. Give it the next free `MN-##` id (never reuse or renumber an existing id).
> 2. **When an item ships:** mark its Status `✅ Done` here (keep the row for one cycle, then move to the `## Done` section), THEN update the relevant permanent docs as usual (`STATUS.md` for milestones, `DECISIONS.md` for decisions, `CLAUDE.md` for new conventions, `BUGS.md` for bug detail, `TESTING.md` for test steps).
> 3. **After finishing any task, remind the user of what's still pending** — surface the next 2–3 `⬜ To do` rows by rank so nothing stalls silently.
> 4. **Ids are permanent identities; Rank is the re-sortable priority.** Reprioritizing = change the Rank column, never the id. Detail for bugs stays in `BUGS.md`; detail for features stays in the plan docs — this file links, it does not duplicate.

**Legend** — **Owner:** 🤖 Agent (Sonnet executor) · 👤 Milan (human-only) · 🤝 Both.  **Status:** ⬜ To do · 🔵 In progress · ✅ Done · 💤 Parked · ❓ Needs decision.
**Prev. label** = the identifier this item used before the 2026-07-21 consolidation (old GitHub issue #, README `P#`, `Task #`, or health-sweep section), so history stays traceable.

---

## 🎯 Current focus

**Chunk A = MN-01 → MN-04** (one thread each) is effectively closed — MN-01 ✅, MN-04 CI-green end-to-end pending Milan's device sign-in check. MN-02 (Sentry) is blocked on Milan's dashboard steps; MN-03 (docs audit) is unstarted.

**→ Chunk B = MN-05 → MN-09 is the next agent work: five independent cleanups designed to run as THREE SUBAGENTS IN PARALLEL in a single thread.** Full dispatcher brief, per-agent file-ownership map, gate sequence, and Milan's 2 manual `git rm --cached` steps are in `NEXT_THREAD.md` → "EXECUTION PLAN — Chunk B". Behaviour-neutral by design (no Dart logic, no `build_runner`, no backend).

Full executor + human briefs for both chunks are in `NEXT_THREAD.md`.

---

## TIER 0 — Chunk A: do now (in this exact order)

| Rank | ID | Item | Category (prev label) | Owner | Status |
|---|---|---|---|---|---|
| 1 | MN-01 | Bump `python-jose` 3.3.0 → 3.4.0 (CVE-2024-33663/-33664) | Security · backend (Task 1) | 🤖 | ✅ |
| 2 | MN-02 | Activate Sentry in prod — set `SENTRY_DSN` in Render + verify | Ops (Task 2) | 🤝 | ⬜ |
| 3 | MN-03 | Docs truth audit (status docs only) + apply approved fixes | Docs (Task 3) | 🤖 | ⬜ |
| 4 | MN-04 | CI/CD pipeline — GitHub Actions gate → signed APK → Firebase App Distribution | DevOps · feature (Task 4 / README P1) | 🤝 | 🔵 (CI green, pending device sign-in confirmation) |

> ✅ Already done this session: `custom_lint` INFO fixed (`tag_list_view_model.dart` → plain `Ref`), gate now strict; test count reconciled to **72**.

---

## TIER 1 — do around CI (cheap, protects the pipeline)

| Rank | ID | Item | Category (prev label) | Owner | Status |
|---|---|---|---|---|---|
| 5 | MN-05 | Rewrite `modunote/.gitignore` as clean UTF-8 (was a binary file — 16 NUL bytes at offset 1480; `**/.claude/*` restored on its own line) | Cleanup (health-sweep B) | 🤖 | ✅ |
| 6 | MN-06 | Delete `lib/core/utils/string_extensions.dart` (dead re-export shim, **verified 0 importers**) | Cleanup (health-sweep A) | 🤖 | ✅ |
| 7 | MN-07 | Untrack `.firebase/hosting.*.cache` (already gitignored; fails checklist S3) — **still pending: needs Milan's `git rm --cached`** | Cleanup (health-sweep A) | 👤 | ⬜ |
| 8 | MN-08 | Untrack `web/drift_worker.js.map` + `.deps` (dart2js byproducts) + add to gitignore — **split**: ✅ agent half done (ignore rules added by Chunk B Agent 1 at `.gitignore:82–84`, verified matching via `git check-ignore --no-index`); ⬜ **still pending: Milan's `git rm --cached`** — until then the files stay tracked and the rules have no effect | Cleanup (health-sweep A) | 🤝 | 🔵 |
| 9 | MN-09 | Delete 4 stale `.gitkeep` files (all parent dirs now hold real files) + stray `modunote/{android/` dir | Cleanup (health-sweep A) | 🤖 | ✅ |

---

## TIER 2 — Bug Batch A (highest-value code fixes; after Chunk A)

> Full repro + fix for every bug is in **`BUGS.md`** (canonical). Fix order per that file: MN-10 → MN-12 → MN-13 → MN-11 → MN-15/16. GitHub issues: bugs 1–16 = **#7–#22**; **bug 17 (MN-26) is NOT filed** (see MN-42).

| Rank | ID | Item | Category (prev label) | Owner | Status |
|---|---|---|---|---|---|
| 10 | MN-10 | Audio session leaked on nearly every note view (idempotent dispose) | Bug #1 · MED-HIGH | 🤖 | ⬜ |
| 10.5 | MN-69 | Cloud restore fails after `applicationId` change (`com.example` → `dev.milanpatel`) — sign-in works but existing notes not restored | Bug · MED-HIGH | 🤝 | ⬜ |
| 11 | MN-11 | Deleting a note orphans audio records + leaks audio files on disk | Bug #17 · MEDIUM | 🤖 | ⬜ |
| 12 | MN-12 | `NoteEditorViewModel.save()` drops note value → concurrent edit lost | Bug #3 · MEDIUM | 🤖 | ⬜ |
| 13 | MN-13 | Mutation errors clobber stream-backed list (whole list vanishes) | Bug #4 · MEDIUM | 🤖 | ⬜ |

---

## TIER 3 — Bug Batch B + remaining bugs

| Rank | ID | Item | Category (prev label) | Owner | Status |
|---|---|---|---|---|---|
| 14 | MN-14 | Deleting a tag orphans `note_tags` rows + stale `note.tagIds` (transactional cascade) | Bug #2 · MEDIUM | 🤖 | ⬜ |
| 15 | MN-15 | `setState` after await without mounted guard (`_onMicTap`/`_stopRecording`) | Bug #6 · MEDIUM | 🤖 | ⬜ |
| 16 | MN-16 | `addTag`/`removeTag`/`togglePin`: no `ref.mounted` guard + `findById` null → `AsyncData(null)` | Bug #7 · MEDIUM | 🤖 | ⬜ |
| 17 | MN-17 | Home long-press sheet occluded by floating nav (missing `useRootNavigator`) | Bug #5 · LOW | 🤖 | ⬜ |
| 18 | MN-18 | Category max nesting off-by-one (caps at 4, docs say 5) | Bug #8 · LOW | 🤖 | ⬜ |
| 19 | MN-19 | `SyncedNoteRepository.update` doesn't set `pending` → skipped by `syncAllPending` | Bug #9 · LOW | 🤖 | ⬜ |
| 20 | MN-20 | FTS sanitiser misses `' ^ .` → invalid MATCH → error instead of empty | Bug #10 · LOW | 🤖 | ⬜ |
| 21 | MN-21 | VM catch clauses only catch `AppException` → non-AppException escapes | Bug #11 · LOW | 🤖 | ⬜ |
| 22 | MN-22 | `_performAutoSave`/`_onBack`: `ref.read` after await without mounted guard | Bug #12 · LOW | 🤖 | ⬜ |
| 23 | MN-23 | Partial recording start leak (`startListening` throws after `startRecording`) | Bug #13 · LOW | 🤖 | ⬜ |
| 24 | MN-24 | `AudioRecordingService.onProgress` subscription never cancelled | Bug #14 · LOW | 🤖 | ⬜ |
| 25 | MN-25 | RagIndexTags / audio_pref cold-start load race can clobber edits | Bug #15 · LOW | 🤖 | ⬜ |
| 26 | MN-26 | Debounce not cancelled before archive → narrow un-archive window | Bug #16 · LOW | 🤖 | ⬜ |

---

## TIER 4 — Cleanup / tech-debt batch (after bugs; do as one pass)

| Rank | ID | Item | Category (prev label) | Owner | Status |
|---|---|---|---|---|---|
| 27 | MN-27 | Delete 22 dead symbols — over-specified Phase-2 repo interface chains never wired to UI (see health-sweep C for the exact list; **verify each has 0 callers before deleting**) | Cleanup (health-sweep C) | 🤖 | ⬜ |
| 28 | MN-28 | Wire up unused validation constants (`noteTitleMaxLength`/`tagNameMaxLength`/`categoryNameMaxLength`; use `AppConstants.appName` at 3 hardcoded sites + `dbFileName`) | Cleanup (health-sweep C) | 🤖 | ⬜ |
| 29 | MN-29 | Extract 6-way duplicate bottom-sheet grabber → `MNSheetGrabber` (~60 lines) | Cleanup (health-sweep D) | 🤖 | ⬜ |
| 30 | MN-30 | Merge `_AddTagChip` + `_AddTriggerTagChip` → one `MNAddChip` | Cleanup (health-sweep D) | 🤖 | ⬜ |
| 31 | MN-31 | Fix 3 stale comments (`tags_dao.dart:9`, `i_category_repository.dart:28`, `i_note_repository.dart:4`) | Cleanup (health-sweep C) | 🤖 | ⬜ |
| 32 | MN-32 | Zero-risk dependency bumps (`equatable`, `path_provider`, `speech_to_text`, `uuid`, `flutter_floating_bottom_bar`; relax `google_sign_in` → `^6.2.1`) | Cleanup (health-sweep E) | 🤖 | ⬜ |
| 33 | MN-33 | Wire `dart run custom_lint` into the standing pre-commit routine + correct `TECH_STACK.md:171` | Process (health-sweep E) | 🤝 | ⬜ |

---

## TIER 5 — Roadmap features (post-CI milestones)

| Rank | ID | Item | Category (prev label) | Owner | Status |
|---|---|---|---|---|---|
| 34 | MN-34 | Startup UX — native splash screen + first-run onboarding carousel | Feature (README P2 · `UI_POLISH_PLAN.md` item 5) | 🤖 | ⬜ |
| 35 | MN-35 | Phase 12 Stage 3 remainder — Langfuse tracing → RAGAS eval baseline → light guardrails | Feature (README P3 · `PHASE_12_PLAN.md` Stage 3) | 🤝 | ⬜ |
| 36 | MN-36 | Deployment hardening — tighten backend `ALLOWED_ORIGINS` + scheduled `pg_dump` backup | Feature (README P4 · `PHASE_12_PLAN.md` Stage 4) | 🤝 | ⬜ |
| 37 | MN-37 | Supabase consolidation S1–S4 — auth + data + vectors on one Postgres, RLS-enforced; removes Firebase | Feature (README P5 · `SUPABASE_MIGRATION_PLAN.md`) | 🤝 | ⬜ |

---

## TIER 6 — Ops / docs chores (do opportunistically)

| Rank | ID | Item | Category (prev label) | Owner | Status |
|---|---|---|---|---|---|
| 40 | MN-40 | Repair GitHub issue mojibake (5 titles + 14 bodies) — `python modunote/bugs/fix_issue_encoding.py --apply` (dry-run clean) | Ops (developer to-do) | 👤 | ⬜ |
| 41 | MN-41 | Commit pending docs — `BUGS.md`, `STATUS.md`, new `BACKLOG.md`, untracked `modunote/bugs/` | Ops (developer to-do) | 👤 | ⬜ |
| 42 | MN-42 | File bug 17 (MN-11) as a GitHub issue — the other 16 are #7–#22 | Ops (developer to-do) | 👤 | ⬜ |
| 43 | MN-43 | Resume `.tex` — fill the GitHub URL + decide the "Live" link | Ops (developer to-do) | 👤 | ⬜ |
| 44 | MN-44 | Demo video | Ops (PORTFOLIO_PLAN Week 1) | 👤 | ⬜ |
| 44.5 | MN-71 | `modunote/SUPABASE_MIGRATION_PLAN.md` is **both tracked AND matched by an ignore rule** (root `.gitignore:6`), unlike `modunote/TECH_STACK.md` on `:5` which is correctly untracked. Inert while the file stays tracked, so nothing is broken — but the intent is contradictory. Decide: untrack it (private, like TECH_STACK.md) or drop the ignore line (intentionally public). Found during the 2026-07-26 Chunk B verification; fold into the MN-03 docs audit | Docs · repo hygiene | 🤝 | ⬜ |
| 45 | MN-70 | **Periodic** prune of harness-created worktrees + spent `claude/*` branches. Not urgent and not a bug: harness worktrees are unavoidable and expected, and the 0-unique-commit branches are proof the rule is working — all real work landed on `main`. **Verified 2026-07-25: 2 worktrees (`elegant-tereshkova-a179ee`, `modunote-parallel-tasks-f04782`) and 10 `claude/*` branches, every one with `git rev-list --count main..<branch>` = 0 and no uncommitted project files**, so nothing is lost by deleting them. Re-verify before each prune; commands in `CLAUDE.md` → "ALL WORK LANDS ON `main`" | Ops · repo hygiene | 👤 | ⬜ |

---

## ❓ Open decisions (need Milan's call before the linked work can proceed)

| ID | Question | Blocks | Prev. label |
|---|---|---|---|
| MN-50 | `AppColors.darkPinTint` is unused → pinned notes may be visually identical to normal cards in dark mode. Wire the tint up, or delete the token? | a small UI fix | to-be-discussed |
| MN-51 | `SyncStatus.conflict` is never written/compared. Keep as forward-planning for conflict resolution, or delete? | MN-27 scope | to-be-discussed |
| MN-52 | `ITagRepository.findById` has 0 `lib/` callers but IS exercised by a test. Keep as tested API surface, or delete method + test together? | MN-27 scope | to-be-discussed |
| MN-53 | `Milan_Patel_LinkedIn_Profile_Update.md` is tracked on the public repo (**confirmed tracked**). Intentional showcase, or remove as noise? | repo hygiene | to-be-discussed |
| MN-54 | Bug-fix state-management convention (MN-12/13/16): apply one convention across ALL viewmodels + document in `CLAUDE.md` (recommended), or only the flagged sites? | MN-12, MN-13, MN-16 | to-be-discussed |

---

## 💤 Parked (revisit when a concrete need appears)

| ID | Item | Prev. label |
|---|---|---|
| MN-60 | Efficiency-pass remainder — trim unused deps/assets, build-size audit | README Parked |
| MN-61 | Sync conflict-resolution UI (currently last-write-wins by `updatedAt`) | README Parked |
| MN-62 | Web audio recording (WebM/Opus + IndexedDB) | README Parked |
| MN-63 | Audio cloud backup (Supabase Storage, after S2) | README Parked |
| MN-64 | Category drag-to-reorder (schema ready, no UI) | README Parked |
| MN-65 | iOS build (non-destructive to add) | README Parked |
| MN-66 | Supabase Realtime live sync | README Parked |
| MN-67 | Major dependency upgrades — flutter_quill 10→11, go_router 14→17, Firebase trio, Riverpod 2→3, flutter_lints 4→6 (one at a time, full regression each) | health-sweep E |
| MN-68 | Release blocker — release builds signed with debug keys (resolved as part of MN-04 STEP 1; delete this row once MN-04 lands) | health-sweep F |

---

## ✅ Done
_(move rows here with the completion date as they land)_

- 2026-07-30 · CI fix — Firebase App Distribution step failed with HTTP 400 *"Release notes length exceeds maximum character limit"*. `ci.yml` passed the **entire** commit message (subject + full body) to `--release-notes`, exceeding the 5000-char cap. Now uses the subject line only, truncated to 500 chars, prefixed with build number + short SHA. Worst-case output measured at 524 chars.
- 2026-07-30 · CI hardening — the commit message reached the shell via `${{ }}` interpolation in **three** steps (Distribute + both "Notify Discord"). GitHub substitutes that text *before* the shell parses, so a commit containing `"`, a backtick, or `$(…)` would break the step or execute on the runner while the keystore + service-account JSON were on disk; the Discord steps' `sed` quote-escaping could never fire for the same reason. All three now pass untrusted text via `env:`, and the two Discord payloads are built with `jq` (correct JSON escaping for quotes/backslashes/newlines) instead of hand-rolled string concatenation. Verified: run bodies extracted verbatim from `ci.yml` and executed against a message containing `"`/backticks/`$(echo PWNED)`/backslash/newlines → both emitted valid JSON, `PWNED` stayed literal. `head_commit` is null on `pull_request`, so the commit field degrades to a plain short SHA.

- 2026-07-25 · MN-04 (in progress) — first pushed CI run (`ci.yml`) failed at `flutter pub get`: pinned Flutter `3.22.0` bundles Dart SDK 3.4.0, but `skeletonizer ^2.1.3` requires Dart ≥3.7.0 (added 2026-06-27 for skeleton loaders, never hit this floor locally because the dev machine's Flutter is newer). Fix: bumped both jobs' `flutter-version` in `.github/workflows/ci.yml` to `3.41.2` (the locally-installed version) and corrected `modunote/pubspec.yaml`'s `environment.sdk` floor from `>=3.3.0` to `>=3.7.0` to match reality. Verified locally end-to-end with 3.41.2 before committing: `flutter pub get` ok → `build_runner` ok → `flutter analyze` 0 issues → `dart run custom_lint` "No issues found!" → `flutter test` **+72 All tests passed!, 0 skips**.
- 2026-07-25 · MN-04 (in progress) — second pushed CI run failed at the "Custom lint" step **despite `custom_lint` itself printing "No issues found!"**. Root cause: `ci.yml`'s gate script used `grep -qv "No issues found"`, which succeeds (triggering the failure branch) if **any single line** of the output doesn't contain that exact phrase — true for the `Analyzing...` line and the blank line that `dart run custom_lint` always prints first, so the gate could never pass regardless of lint result. Fixed the boolean logic to `if ! echo "$OUTPUT" | grep -q "No issues found"` (fail only when the phrase is absent from the whole output) and verified both the pass case (real captured output) and the fail case (synthetic issue line) against the corrected script locally.
- 2026-07-25 · MN-04 (in progress) — Landing A (Quality Gate) now green; Landing B (Release job) failed at `assembleRelease`: `KeytoolException: Failed to read key "modunote" from store "/tmp/modunote-release.jks": keystore password was incorrect`. **Correction to the same-day entry above that called this a pure secrets-side issue:** found and fixed a real code bug — the "Write key.properties" step (`ci.yml`) used an **unquoted heredoc** (`<< EOF`) while interpolating `KEYSTORE_PASSWORD`/`KEY_PASSWORD`/`KEY_ALIAS`. Bash performs `$`-expansion and backtick command-substitution inside unquoted heredoc bodies, so any password containing `$` (very common in generated strong passwords, e.g. `Sup3r$ecret99`) silently truncates (→ `Sup3r`) before it ever reaches `keytool`. Reproduced the exact mangling locally with a demo, then fixed by quoting the delimiter (`<< 'EOF'`) — this disables all shell reinterpretation of the heredoc body while leaving GitHub's `${{ secrets.X }}` substitution (which happens before bash runs, independent of quoting) untouched. Re-verified the fix preserves a `$`-containing value byte-for-byte. The other two secret-writing steps in the same job were checked and are already safe (`ANDROID_KEYSTORE_BASE64` via `echo "..."` — base64's alphabet has no shell metacharacters; `FIREBASE_SERVICE_ACCOUNT_JSON` via `echo '...'` — already single-quoted). **Milan to do:** commit + push `.github/workflows/ci.yml`. If the release job still fails after this, then it genuinely is a secrets-side mismatch — verify `keytool -list -v -keystore C:\Milan\keys\modunote-release.jks -alias modunote` succeeds locally with the password you have, and re-paste `KEYSTORE_PASSWORD`/`KEY_PASSWORD` fresh (watch for trailing whitespace).
- 2026-07-24 · MN-01 — `python-jose` bumped 3.3.0 → 3.4.0 (CVE-2024-33663/-33664). Installed version verified 3.4.0; `core/auth.py:94` RS256 pin + `jose` imports unchanged; 26 pytest green; `git diff` = exactly one line. **Milan to do:** commit + push `modunote-api`; confirm `GET /health` returns 200 after Render redeploys.
- 2026-07-25 · MN-04 (in progress) — after the heredoc fix, Landing B got past keystore signing and all the way to building the signed APK (`✓ Built ... 68.2MB`), then failed: `--build-number=5: command not found`, exit 127. Root cause: the "Build release APK" step's `--dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }} \` was the **only** unquoted `${{ }}` substitution in the whole file sitting directly before a line-continuation backslash — every other `${{ secrets.X }}`/`${{ github.event... }}` usage elsewhere in the file is wrapped in `"..."`. GitHub substitutes `${{ }}` as raw text before bash ever parses the script, so if the `API_BASE_URL` secret has so much as a trailing newline (easy to pick up from a copy-paste), it gets injected mid-script and silently terminates the command early — exactly matching the build succeeding with `--release`+`--dart-define` applied, then `--build-number=...` running as its own bogus "command". Fixed by collapsing the step to one line and quoting the value: `flutter build apk --release --dart-define=API_BASE_URL="${{ secrets.API_BASE_URL }}" --build-number=${{ github.run_number }}`. Audited the rest of the file for the same unquoted-substitution-before-continuation pattern — no other instance found. **Milan to do:** (1) commit + push `.github/workflows/ci.yml`; (2) double-check the `API_BASE_URL` GitHub secret for a stray trailing newline/whitespace and re-set it cleanly if present — the CI crash is now fixed either way, but a trailing newline baked into the compiled `--dart-define` constant could still reach the shipped app; (3) confirm Landing B completes end-to-end (APK built + distributed to Firebase App Tester), then mark MN-04 ✅ here.
- 2026-07-25 · MN-04 (in progress) — the quoted `--dart-define=API_BASE_URL="${{ secrets.API_BASE_URL }}"` fix stopped the script from crashing, but the release job now fails differently: `flutter build apk` errors `Target file "--dart-define=API_BASE_URL=***\n" not found.` This confirms the earlier theory precisely — the `API_BASE_URL` secret's stored value carries an embedded/trailing newline. Because it's now quoted, that newline survives *inside* the single argv token flutter receives; flutter's arg parser doesn't recognise the token as the `--dart-define` option and instead drops the whole thing into the positional "target file" slot. Rather than keep guessing the exact shape of the secret's corruption, hardened the step defensively: moved the secret into `env: API_BASE_URL: ${{ secrets.API_BASE_URL }}` (env vars are passed at the OS process level, immune to raw-text-substitution corrupting the script), then `CLEAN_API_BASE_URL=$(printf '%s' "$API_BASE_URL" | tr -d '[:space:]')` strips every whitespace character (not just trim) before it reaches `flutter build`, plus a length-only debug echo (never prints the value) for visibility if it fails again. Verified locally with a synthetic value containing embedded newlines/spaces — cleans to the correct URL and forms exactly 2 argv tokens. **Milan to do:** (1) commit + push `.github/workflows/ci.yml`; (2) separately, re-paste the `API_BASE_URL` secret cleanly (no trailing Enter/whitespace) — the workflow no longer depends on this being clean, but it's worth fixing at the source too; (3) confirm Landing B completes end-to-end, then mark MN-04 ✅ here.
- 2026-07-25 · MN-04 — CI/CD pipeline fully green end-to-end for the first time: Quality Gate (analyze + custom_lint + 72 tests) passed, Release job built a signed release APK and distributed it via Firebase App Distribution to the `milan` tester group. Took 4 rounds of CI debugging to get here (Flutter/Dart SDK floor, custom_lint gate logic, heredoc `$`-expansion truncating the keystore password, `API_BASE_URL` secret corruption) — see the entries above for each root cause. **One acceptance check remains before this is fully ✅ done:** confirm Google Sign-In works in the installed release APK (the reason the release SHA-1 step existed in B-PREREQ) — CI can build and sign the APK but can't verify sign-in itself. Row stays 🔵 until Milan confirms.
- 2026-07-26 · **MN-05 / MN-06 / MN-09 — Chunk B, executed as three parallel subagents in one thread, then independently verified.** MN-05: `modunote/.gitignore` rewritten clean — **0 NUL bytes** (was 16 at offset 1480), no BOM, no CRLF, valid UTF-8, `**/.claude/*` restored on its own line (`:74`), no duplicate `build/` rule. MN-06: dead 48-byte re-export shim `lib/core/utils/string_extensions.dart` deleted; the real `lib/core/extensions/string_extensions.dart` untouched. MN-09: 4 stale `.gitkeep` files deleted + the stray `modunote/{android` brace-expansion directory removed. **Gates re-run from the main tree 2026-07-26: `flutter analyze` → "No issues found!" · `dart run custom_lint` → "No issues found!" · `flutter test` → `+72: All tests passed!` with 0 skips.** Ignore-rule regression sweep passed: every tracked file still visible, and `firebase_options.dart` / `build/` / `session_context.md` / `*.g.dart` / `.firebase/` / `test/.cache/` all still ignored. Changed-file set was exactly the 3 ownership scopes — no agent strayed. **Verification caveat worth remembering:** `git check-ignore` silently skips files already in the index, so it returns nothing for tracked paths and looks like "no rule matches"; use `--no-index` when testing rules against tracked files, or the check is vacuous.
- 2026-07-21 · `custom_lint` INFO fixed + gate made strict; test count reconciled to 72 (prep for MN-04).
