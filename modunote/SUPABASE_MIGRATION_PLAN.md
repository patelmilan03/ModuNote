# Supabase Consolidation — Migration Plan (PROPOSED — awaiting approval)

> Status: **DRAFT / not started.** Do not implement until the developer approves.
> Goal: replace **Firebase (Auth + Firestore)** with **Supabase (Auth + Postgres + RLS)**
> as the single backend for auth + data + vectors, so per-user isolation is enforced
> by the database (Row-Level Security) instead of hand-written `WHERE user_id` filters.

## Why (motivation)
The RAG cross-user leak (fixed 2026-07-01 on Firebase) happened because isolation
relied on remembering a `WHERE Document.user_id == uid` in every query. **RLS makes
that class of bug structurally impossible**: policies (`using (auth.uid() = user_id)`)
mean the database itself refuses to return another user's rows. We already run
Supabase Postgres + pgvector for the RAG store, so consolidating removes a provider
(Firebase), unifies identity to one JWT, and puts notes + vectors in one database.

**This is NOT required** — the leak is already fixed on the current stack. This is a
deliberate architecture simplification with a real (large) migration cost.

## What changes (surface area)
| Area | Today (Firebase) | After (Supabase) |
|---|---|---|
| Auth | `firebase_auth` + `google_sign_in` → Firebase ID token | `supabase_flutter` Google OAuth → Supabase session/JWT |
| Auth gate | router redirect on `FirebaseAuth.currentUser` | router redirect on Supabase `onAuthStateChange` / `currentSession` |
| Login screen | Firebase Google sign-in | Supabase `signInWithOAuth(Provider.google)` (deep-link redirect) |
| Cloud sync | `CloudSyncService` → Firestore `/users/{uid}/...` | Supabase tables `notes/tags/categories` with RLS |
| Local store | Drift (local-first) — **unchanged** | Drift (local-first) — **unchanged** |
| RAG identity | backend verifies Firebase ID token (`core/auth.py`) | backend verifies Supabase JWT (HS256, project JWT secret) **or** move retrieval to a Supabase RPC run under the user's JWT (pure RLS) |
| RAG isolation | `WHERE Document.user_id == uid` (manual) | RLS on `documents`/`chunks` (`user_id uuid default auth.uid()`) |
| Removed deps | — | `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`, `lib/firebase_options.dart`, `firestore.rules` |

## Decisions to confirm BEFORE starting
1. **Local store:** keep **Drift local-first** (offline-first UX, recommended) vs. go Supabase-direct (drop Drift — much bigger change, loses offline). → recommend **keep Drift**.
2. **RAG retrieval path:** (a) keep FastAPI + verify Supabase JWT + filter by uid (least change, reuses current infra); vs. (b) a Supabase **RPC / edge function** doing the pgvector similarity under the user's JWT so **RLS** scopes it (pure "leak-impossible" story, more work). → recommend **(a)** first, **(b)** as a follow-up.
3. **Data:** clean slate (everything was wiped → easiest) vs. migrate existing Firestore data. → recommend **clean slate**.
4. **Anonymous / guest:** Supabase supports anonymous sign-in — keep the "Continue without an account" escape hatch on Supabase? → recommend **yes**.

## Phased plan (each phase: analyze 0 + tests + read-only audit; developer approves before the next)
- **S1 — Supabase Auth (Google).** Add `supabase_flutter`; init in `main.dart`; new `SupabaseAuthService` (OAuth Google + anonymous + signOut + `onAuthStateChange`); Android deep-link / redirect URL config; router gate + login screen + profile avatar switched to the Supabase session. *Developer:* enable Google provider in Supabase Auth, add the redirect URL / Android deep link, provide Supabase URL + anon key (via `--dart-define`).
- **S2 — Data tables + RLS.** Create `notes`/`tags`/`categories` tables in Supabase (columns mirror the models; `user_id uuid not null default auth.uid()`), enable RLS with owner policies; rewrite `CloudSyncService` to push/pull against Supabase (`supabase.from('notes')…`) instead of Firestore; keep Drift local-first + the on-background backup + on-sign-in restore behaviour and the same audited safety (transaction, name-dedup, merge).
- **S3 — RAG on RLS.** Add `user_id uuid` + RLS to `documents`/`chunks`; backend `core/auth.py` verifies the **Supabase JWT** (HS256 with the project JWT secret) instead of the Firebase token (or option 2b: move retrieval into a Supabase RPC). Keep the per-user scoping tests.
- **S4 — Remove Firebase.** Delete `firebase_*` deps, `google_sign_in`, `firebase_options.dart`, `firestore.rules`, `FirebaseAuthService`; update `main.dart`, docs, and the security checklist (Firebase secrets → Supabase keys).

## Effort & risk
- **Effort:** Large (auth + sync + backend auth + RLS across two repos). Roughly the size of the Firebase auth+sync arc we just built — because it largely *replaces* it.
- **Risk:** Android OAuth deep-link setup is fiddlier than Firebase's native Google sign-in; a botched RLS policy can lock a user out of their own rows (mitigate: test policies with the audit + a "local-only if unauthenticated" fallback like today).
- **Payoff:** one provider, one identity, DB-enforced isolation, notes + vectors in one Postgres — and a strong portfolio talking point ("multi-tenant isolation via Postgres RLS").

## Not doing (out of scope for this plan)
- Realtime sync (Supabase Realtime) — could replace the on-background push later.
- Supabase Storage for audio — the "audio is local-only" gap is tracked separately.

---
*When approved, work proceeds S1 → S4, one phase at a time, each verified + audited before the next, per the project's standing process.*
