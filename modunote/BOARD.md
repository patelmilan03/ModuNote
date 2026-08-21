---
project: ModuNote
updated: 2026-08-21
source: BACKLOG.md (deep, full ranked list — this board holds the active/near-term view)
---

# ModuNote — Board

> Card order within a column = priority (top = do first). `BACKLOG.md` remains the
> exhaustive ranked list + parked tail; low-priority long tails below are single
> pointer cards, not one-per-row, to keep this board scannable.

## 🧊 Backlog

- [ ] MN-11 · Deleting a note orphans audio records + leaks audio files  @agent #bug
- [ ] MN-14 · Deleting a tag orphans `note_tags` rows + stale `note.tagIds`  @agent #bug
- [ ] MN-15 · `setState` after await without mounted guard (mic/stop recording)  @agent #bug
- [ ] MN-17→MN-26 · 10 remaining LOW-severity bugs — repro/fix in `BUGS.md`  @agent #bug
- [ ] MN-27 · Delete 22 dead symbols (verify 0 callers each)  @agent #techdebt
- [ ] MN-28 · Wire up unused validation constants + `AppConstants` usages  @agent #techdebt
- [ ] MN-29 · Extract 6-way duplicate bottom-sheet grabber → `MNSheetGrabber`  @agent #cleanup
- [ ] MN-30 · Merge `_AddTagChip` + `_AddTriggerTagChip` → `MNAddChip`  @agent #cleanup
- [ ] MN-31 · Fix 3 stale comments (tags_dao, i_category_repo, i_note_repo)  @agent #cleanup
- [ ] MN-32 · Zero-risk dependency bumps (equatable/path_provider/uuid/…)  @agent #techdebt
- [ ] MN-33 · Wire `dart run custom_lint` into pre-commit + fix `TECH_STACK.md:171`  @both #devops
- [ ] MN-34 · Startup UX — native splash + first-run onboarding carousel  @agent #feature
- [ ] MN-35 · Stage 3 remainder — Langfuse tracing → RAGAS baseline → guardrails  @both #feature
- [ ] MN-36 · Deploy hardening — tighten `ALLOWED_ORIGINS` + scheduled `pg_dump`  @both #feature
- [ ] MN-37 · Supabase consolidation S1–S4 — one Postgres, RLS, removes Firebase  @both #feature
- [ ] MN-40 · Repair GitHub issue mojibake (`fix_issue_encoding.py --apply`)  @milan #ops
- [ ] MN-42 · File bug 17 (MN-11) as a GitHub issue  @milan #ops
- [ ] MN-43 · Resume `.tex` — fill GitHub URL + decide the "Live" link  @milan #ops
- [ ] MN-44 · Demo video  @milan #ops
- [ ] MN-70 · Periodic prune of harness worktrees + spent `claude/*` branches  @milan #ops
- [ ] MN-60→MN-68 · Parked ideas (web audio, realtime sync, iOS, major dep upgrades…) — see `BACKLOG.md` → Parked  @both #feature

## 📋 To Do (next up)

- [ ] MN-04a · Verify Google Sign-In in installed release APK — closes MN-04 acceptance  @milan #devops
- [ ] MN-03 · Docs truth audit (status docs) + apply approved fixes  @agent #docs
- [ ] MN-69 · Cloud restore fails after `applicationId` change (notes not restored)  @both #bug
- [ ] MN-02 · Activate Sentry in prod — set `SENTRY_DSN` in Render + verify  @both #ops
- [ ] MN-10 · Audio session leaked on nearly every note view (idempotent dispose)  @agent #bug
- [ ] MN-07 · Untrack `.firebase/hosting.*.cache` (`git rm --cached`)  @milan #cleanup
- [ ] MN-08 · Untrack `web/drift_worker.js.map` + `.deps` (`git rm --cached`; ignore rules already added)  @both #cleanup

## 🔵 In Progress

_(no dev thread mid-flight — MN-04 pipeline shipped; its one manual acceptance check is MN-04a in To Do)_

## ⛔ Blocked

- [ ] MN-12 · `NoteEditorViewModel.save()` drops note value → concurrent edit lost — waiting on MN-54 decision  @agent #bug
- [ ] MN-13 · Mutation errors clobber stream-backed list — waiting on MN-54 decision  @agent #bug
- [ ] MN-16 · `addTag`/`removeTag`/`togglePin` mounted-guards + null `findById` — waiting on MN-54 decision  @agent #bug

## ❓ Needs Decision

- [ ] MN-54 · Bug-fix state-mgmt convention: apply across ALL viewmodels + document in `CLAUDE.md`, or only flagged sites? (unblocks MN-12/13/16)  @milan #techdebt
- [ ] MN-71 · `SUPABASE_MIGRATION_PLAN.md` is tracked AND gitignored — untrack (private) or drop the ignore line (public)?  @both #docs
- [ ] MN-50 · `AppColors.darkPinTint` unused → pinned notes may be identical in dark mode. Wire up or delete?  @milan #cleanup
- [ ] MN-51 · `SyncStatus.conflict` never written/compared. Keep for planned conflict resolution or delete?  @milan #techdebt
- [ ] MN-52 · `ITagRepository.findById` — 0 `lib/` callers but exercised by a test. Keep or delete method + test?  @milan #techdebt
- [ ] MN-53 · `Milan_Patel_LinkedIn_Profile_Update.md` tracked on public repo. Showcase or remove?  @milan #docs

## ✅ Done

- [x] CI hardening · release-notes 5000-char cap + shell-injection fix in `ci.yml` (3 steps) — 2026-07-31  @agent #devops
- [x] MN-04 · CI/CD pipeline green end-to-end — signed APK built + distributed via Firebase App Distribution — 2026-07-25  @both #devops
- [x] MN-05 · `modunote/.gitignore` rewritten clean UTF-8 (was binary, 16 NUL bytes) — 2026-07-26  @agent #cleanup
- [x] MN-06 · Delete dead `string_extensions.dart` re-export shim (0 importers) — 2026-07-26  @agent #cleanup
- [x] MN-09 · Delete 4 stale `.gitkeep` + stray `{android` brace dir — 2026-07-26  @agent #cleanup
- [x] MN-01 · `python-jose` 3.3.0 → 3.4.0 (CVE-2024-33663/-33664) — 2026-07-24  @agent #security
- [x] Phase12-S2 · RAG QnA end-to-end (pgvector + Jina + Groq, citations) — 2026-06-27  @agent #feature
- [x] Phase12-S1 · Groq AI writing assistant (improve/paraphrase/summarise, tag-aware) — 2026-06-22  @agent #feature

%% kanban:settings
```
{"kanban-plugin":"board","new-card-insertion-method":"prepend","show-checkboxes":false}
```
%%
