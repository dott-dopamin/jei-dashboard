-- JEI PERSONAL DASHBOARD — 독립 Supabase 프로젝트 전용
-- IMPORTANT: 기존 팬데믹/보드게임 프로젝트가 아닌 새 프로젝트에만 실행하세요.
-- 각 테이블의 owner_id와 RLS가 개인 데이터를 분리합니다.
begin;
create extension if not exists pgcrypto;

create table if not exists public.todos (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 content text not null,
 status text not null default '시작전' check(status in ('시작전','진행중','완료')),
 sort_order integer not null default 0,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists idx_todos_owner_status_order on public.todos(owner_id,status,sort_order);

create table if not exists public.notes (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 content text not null default '',
 updated_at timestamptz not null default now(),
 constraint notes_one_per_person unique(owner_id)
);

create table if not exists public.calendar_events (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 event_date date not null,
 end_date date,
 title text not null,
 is_holiday boolean not null default false,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint calendar_dates_ordered check (end_date is null or end_date>=event_date)
);
create index if not exists idx_calendar_events_owner_date on public.calendar_events(owner_id,event_date);

create table if not exists public.calendar_keywords (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 keyword text not null,
 color text not null default '#e9edf3',
 created_at timestamptz not null default now(),
 constraint unique_keyword_per_owner unique(owner_id,keyword)
);

create table if not exists public.discontinued_items (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 product_name text not null,
 memo text not null default '',
 created_at timestamptz not null default now()
);
create index if not exists idx_discontinued_owner_created on public.discontinued_items(owner_id,created_at desc);

-- Client can never read another owner's rows or insert them under another owner_id.
-- Explicit policies avoid accidental authenticated ALL defaults.
do $$
declare t text;
begin
 foreach t in array array['todos','notes','calendar_events','calendar_keywords','discontinued_items'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('alter table public.%I force row level security',t);
  execute format('drop policy if exists %I on public.%I','personal_select',t);
  execute format('drop policy if exists %I on public.%I','personal_insert',t);
  execute format('drop policy if exists %I on public.%I','personal_update',t);
  execute format('drop policy if exists %I on public.%I','personal_delete',t);
  execute format('create policy personal_select on public.%I for select to authenticated using ((select auth.uid()) = owner_id)',t);
  execute format('create policy personal_insert on public.%I for insert to authenticated with check ((select auth.uid()) = owner_id)',t);
  execute format('create policy personal_update on public.%I for update to authenticated using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id)',t);
  execute format('create policy personal_delete on public.%I for delete to authenticated using ((select auth.uid()) = owner_id)',t);
  execute format('revoke all on public.%I from anon',t);
  execute format('grant select,insert,update,delete on public.%I to authenticated',t);
 end loop;
end $$;
commit;
