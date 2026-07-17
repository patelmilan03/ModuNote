-- ModuNote — Supabase schema + Row-Level Security
-- Part of the Firebase → Supabase migration (see SUPABASE_MIGRATION_PLAN.md).
-- Run in Supabase → SQL Editor. RLS is the whole point: each user can only ever
-- read/write their OWN rows, enforced by the database — so the cross-user leak
-- class of bug becomes structurally impossible (no reliance on a WHERE clause).
--
-- Columns mirror the Flutter models (lib/data/models/*.dart). Entity ids stay
-- text (the app generates UUID v4 strings); user_id is the Supabase auth uid.

-- ── NOTES ────────────────────────────────────────────────────────────────
create table if not exists public.notes (
  id           text primary key,
  user_id      uuid not null default auth.uid()
                 references auth.users (id) on delete cascade,
  title        text        not null default '',
  content      jsonb       not null default '{}'::jsonb,   -- Quill delta
  category_id  text,
  tag_ids      jsonb       not null default '[]'::jsonb,    -- denormalised tag ids
  is_pinned    boolean     not null default false,
  is_archived  boolean     not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists notes_user_id_idx on public.notes (user_id);

-- ── TAGS ─────────────────────────────────────────────────────────────────
create table if not exists public.tags (
  id          text primary key,
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  name        text        not null,
  created_at  timestamptz not null default now(),
  unique (user_id, name)   -- tag names are unique per user
);
create index if not exists tags_user_id_idx on public.tags (user_id);

-- ── CATEGORIES (adjacency-list hierarchy: parent_id null = root) ──────────
create table if not exists public.categories (
  id          text primary key,
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  name        text        not null,
  parent_id   text,
  sort_order  integer     not null default 0,
  created_at  timestamptz not null default now()
);
create index if not exists categories_user_id_idx on public.categories (user_id);

-- ── Row-Level Security: owner-only access ─────────────────────────────────
alter table public.notes      enable row level security;
alter table public.tags       enable row level security;
alter table public.categories enable row level security;

-- One policy per table covering select/insert/update/delete. `using` gates
-- reads/updates/deletes to the owner; `with check` stops a client writing a row
-- under someone else's id.
create policy "own notes" on public.notes for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own tags" on public.tags for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own categories" on public.categories for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── RAG tables (documents / chunks) — handled in S3 ───────────────────────
-- `documents` + `chunks` already exist (created by the backend's Alembic
-- migration 0001_rag_tables). In S3 (RAG-on-RLS), documents.user_id is switched
-- from the Firebase uid (text) to the Supabase auth uid (uuid) and RLS is added.
-- NOTE: if the FastAPI backend keeps its service-role Postgres connection it
-- BYPASSES RLS, so it must still filter by the JWT-verified uid (migration
-- decision 2a). The exact ALTER/RLS for these two tables lands with the S3 auth
-- swap — see SUPABASE_MIGRATION_PLAN.md.
