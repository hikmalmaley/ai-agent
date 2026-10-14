-- ============================================================
-- Mission Control — skema Supabase
-- Cara pakai: buka Supabase Dashboard → SQL Editor → paste seluruh
-- file ini → Run. Selesai dalam sekali jalan.
-- ============================================================

-- 1) Snapshot state penuh (1 baris, id=1). Ditulis collector tiap ~30 dtk.
create table if not exists state_snapshots (
  id int primary key,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

-- 2) Ledger event kerja agent (mirror dari tasks.jsonl)
create table if not exists task_events (
  id bigserial primary key,
  ts text not null,
  task_id text not null,
  agent text not null,
  subagent text,
  title text,
  status text not null,
  detail text,
  created_at timestamptz not null default now()
);
create index if not exists task_events_created_idx on task_events (created_at desc);
create index if not exists task_events_task_idx on task_events (task_id);

-- 3) Antrean quick task
create table if not exists queue (
  id bigserial primary key,
  ts text not null,
  prompt text not null,
  agent text not null,
  status text not null default 'queued',
  created_at timestamptz not null default now()
);
create index if not exists queue_created_idx on queue (created_at desc);

-- 4) Status pause global (1 baris, id=1)
create table if not exists dispatch (
  id int primary key,
  paused boolean not null default false,
  updated_at timestamptz not null default now()
);

-- 5) Pause per agent
create table if not exists agent_pause (
  agent text primary key,
  paused boolean not null default true,
  updated_at timestamptz not null default now()
);

-- 6) Jadwal cron (mirror dari markdown cron.d)
create table if not exists schedules (
  id text primary key,
  title text,
  enabled boolean not null default true,
  owner text,
  kind text,
  label text,
  timezone text,
  next_iso text,
  is_system boolean not null default false,
  updated_at timestamptz not null default now()
);

-- 7) Histori watchdog
create table if not exists watchdog_log (
  id bigserial primary key,
  ts text,
  event text,
  url text,
  note text,
  created_at timestamptz not null default now()
);
create index if not exists watchdog_log_created_idx on watchdog_log (created_at desc);

-- ============================================================
-- Row Level Security.
-- Catatan jujur: anon key memang dirancang untuk diekspos di
-- frontend publik. Policy di bawah memberi anon: baca semua,
-- tulis secukupnya (insert event/antrean, ubah dispatch/pause).
-- Siapa pun yang memegang URL+anon key BISA menulis baris baru
-- (mis. event palsu). Untuk dashboard pribadi ini risikonya
-- diterima; ketatkan nanti bila perlu (mis. service_role di
-- collector milik sendiri).
-- ============================================================
alter table state_snapshots enable row level security;
alter table task_events     enable row level security;
alter table queue           enable row level security;
alter table dispatch        enable row level security;
alter table agent_pause     enable row level security;
alter table schedules       enable row level security;
alter table watchdog_log    enable row level security;

-- state_snapshots: baca publik; tulis (insert/update) publik
drop policy if exists "mc_read"   on state_snapshots;
drop policy if exists "mc_write"  on state_snapshots;
drop policy if exists "mc_update" on state_snapshots;
create policy "mc_read"   on state_snapshots for select using (true);
create policy "mc_write"  on state_snapshots for insert with check (true);
create policy "mc_update" on state_snapshots for update using (true) with check (true);

-- task_events: baca + insert publik (append-only, tanpa update/delete)
drop policy if exists "mc_read"   on task_events;
drop policy if exists "mc_insert" on task_events;
create policy "mc_read"   on task_events for select using (true);
create policy "mc_insert" on task_events for insert with check (true);

-- queue: baca + insert publik
drop policy if exists "mc_read"   on queue;
drop policy if exists "mc_insert" on queue;
create policy "mc_read"   on queue for select using (true);
create policy "mc_insert" on queue for insert with check (true);

-- dispatch: baca + insert + update publik (1 baris)
drop policy if exists "mc_read"   on dispatch;
drop policy if exists "mc_write"  on dispatch;
drop policy if exists "mc_update" on dispatch;
create policy "mc_read"   on dispatch for select using (true);
create policy "mc_write"  on dispatch for insert with check (true);
create policy "mc_update" on dispatch for update using (true) with check (true);

-- agent_pause: baca + tulis + hapus publik
drop policy if exists "mc_read"   on agent_pause;
drop policy if exists "mc_write"  on agent_pause;
drop policy if exists "mc_update" on agent_pause;
drop policy if exists "mc_delete" on agent_pause;
create policy "mc_read"   on agent_pause for select using (true);
create policy "mc_write"  on agent_pause for insert with check (true);
create policy "mc_update" on agent_pause for update using (true) with check (true);
create policy "mc_delete" on agent_pause for delete using (true);

-- schedules: baca + tulis penuh publik (collector replace-all)
drop policy if exists "mc_read"   on schedules;
drop policy if exists "mc_write"  on schedules;
drop policy if exists "mc_update" on schedules;
drop policy if exists "mc_delete" on schedules;
create policy "mc_read"   on schedules for select using (true);
create policy "mc_write"  on schedules for insert with check (true);
create policy "mc_update" on schedules for update using (true) with check (true);
create policy "mc_delete" on schedules for delete using (true);

-- watchdog_log: baca + insert publik
drop policy if exists "mc_read"   on watchdog_log;
drop policy if exists "mc_insert" on watchdog_log;
create policy "mc_read"   on watchdog_log for select using (true);
create policy "mc_insert" on watchdog_log for insert with check (true);
