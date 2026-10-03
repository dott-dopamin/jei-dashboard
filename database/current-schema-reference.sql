-- =============================================================
-- JEI Dashboard / Supabase current schema reference
-- 기준일: 2026-10-04
--
-- 유지보수/복구용 참고본입니다.
-- 라이브 DB에 무조건 전체 재실행하지 말고 필요한 부분만 확인해 적용하세요.
-- =============================================================

create extension if not exists pgcrypto;

-- -------------------------
-- Personal dashboard
-- -------------------------
create table if not exists public.todos (
  id uuid primary key default gen_random_uuid(),
  content text not null,
  status text not null default '시작전'
    check (status in ('시작전','진행중','완료')),
  sort_order integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  content text default '',
  updated_at timestamptz default now()
);

create table if not exists public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  event_date date not null,
  end_date date,
  title text not null,
  is_holiday boolean not null default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_calendar_events_date
on public.calendar_events(event_date);

create table if not exists public.calendar_keywords (
  id uuid primary key default gen_random_uuid(),
  keyword text not null unique,
  color text not null default '#e9edf3',
  created_at timestamptz default now()
);

create table if not exists public.discontinued_items (
  id uuid primary key default gen_random_uuid(),
  product_name text not null,
  memo text default '',
  created_at timestamptz default now()
);

-- -------------------------
-- GAME ARCHIVE
-- -------------------------
create table if not exists public.board_games (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  genre text not null
    check (genre in ('전략','파티/패밀리','추리','마피아/디덕션','협력')),
  player_count text default '',
  play_time text default '',
  image_url text default '',
  is_expansion boolean not null default false,
  is_funding boolean not null default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

insert into storage.buckets (id,name,public)
values ('board-game-images','board-game-images',true)
on conflict (id) do update set public = true;

-- -------------------------
-- Pandemic Legacy S1
-- -------------------------
create table if not exists public.pandemic_legacy_s1_state (
  id integer primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  constraint pandemic_legacy_s1_singleton check (id = 1)
);

create table if not exists public.pandemic_legacy_s1_settings (
  id integer primary key,
  access_code text not null,
  constraint pandemic_legacy_s1_settings_singleton check (id = 1)
);

-- 팬데믹 공유 비밀번호의 실제 값은 이 참고 파일에 적지 않습니다.
-- 변경 시:
-- update public.pandemic_legacy_s1_settings set access_code='새비밀번호' where id=1;

create or replace function public.get_pandemic_legacy_s1(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_data jsonb;
begin
  select access_code into v_code
  from public.pandemic_legacy_s1_settings
  where id = 1;

  if p_code is null or p_code <> v_code then
    raise exception 'INVALID_CODE' using errcode = 'P0001';
  end if;

  select data into v_data
  from public.pandemic_legacy_s1_state
  where id = 1;

  return coalesce(v_data, '{}'::jsonb);
end;
$$;

create or replace function public.save_pandemic_legacy_s1(p_code text, p_data jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
begin
  if auth.uid() is null then
    select access_code into v_code
    from public.pandemic_legacy_s1_settings
    where id = 1;

    if p_code is null or p_code <> v_code then
      raise exception 'INVALID_CODE' using errcode = 'P0001';
    end if;
  end if;

  update public.pandemic_legacy_s1_state
  set data = coalesce(p_data, '{}'::jsonb),
      updated_at = now()
  where id = 1;

  return p_data;
end;
$$;

-- -------------------------
-- RLS / grants reference
-- -------------------------
alter table public.todos enable row level security;
alter table public.notes enable row level security;
alter table public.calendar_events enable row level security;
alter table public.calendar_keywords enable row level security;
alter table public.discontinued_items enable row level security;
alter table public.board_games enable row level security;
alter table public.pandemic_legacy_s1_state enable row level security;
alter table public.pandemic_legacy_s1_settings enable row level security;

grant select,insert,update,delete on public.todos to authenticated;
grant select,insert,update,delete on public.notes to authenticated;
grant select,insert,update,delete on public.calendar_events to authenticated;
grant select,insert,update,delete on public.calendar_keywords to authenticated;
grant select,insert,update,delete on public.discontinued_items to authenticated;
grant select on public.board_games to anon;
grant select,insert,update,delete on public.board_games to authenticated;
grant select,insert,update,delete on public.pandemic_legacy_s1_state to authenticated;
grant select,insert,update,delete on public.pandemic_legacy_s1_settings to authenticated;

-- 실제 라이브 DB의 RLS policy는 Supabase Dashboard에서도 함께 확인하세요.
-- board_games: anon SELECT, authenticated ALL
-- 개인 대시보드 테이블: authenticated ALL
-- pandemic tables: authenticated ALL, 공유 비밀번호 사용자는 SECURITY DEFINER RPC로 접근
-- storage.objects / board-game-images: public SELECT, authenticated INSERT/UPDATE/DELETE

revoke all on function public.get_pandemic_legacy_s1(text) from public;
revoke all on function public.save_pandemic_legacy_s1(text,jsonb) from public;
grant execute on function public.get_pandemic_legacy_s1(text) to anon, authenticated;
grant execute on function public.save_pandemic_legacy_s1(text,jsonb) to anon, authenticated;
