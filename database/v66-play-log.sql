-- V66: GAME ARCHIVE 플레이 로그
create extension if not exists pgcrypto;

create table if not exists public.board_game_play_logs (
  id uuid primary key default gen_random_uuid(),
  game_id uuid null references public.board_games(id) on delete set null,
  game_title text not null,
  played_on date not null default current_date,
  players text not null default '',
  player_count smallint null check (player_count is null or player_count between 1 and 30),
  place text not null default '',
  result text not null default '',
  replay_tag text not null default '',
  memo text not null default '',
  is_first_play boolean not null default false,
  used_expansion boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.board_game_play_logs enable row level security;

grant select on table public.board_game_play_logs to anon, authenticated;
grant insert, update, delete on table public.board_game_play_logs to authenticated;

DROP POLICY IF EXISTS "play logs public read" ON public.board_game_play_logs;
CREATE POLICY "play logs public read"
ON public.board_game_play_logs FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "play logs authenticated insert" ON public.board_game_play_logs;
CREATE POLICY "play logs authenticated insert"
ON public.board_game_play_logs FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "play logs authenticated update" ON public.board_game_play_logs;
CREATE POLICY "play logs authenticated update"
ON public.board_game_play_logs FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "play logs authenticated delete" ON public.board_game_play_logs;
CREATE POLICY "play logs authenticated delete"
ON public.board_game_play_logs FOR DELETE
TO authenticated
USING (true);

create index if not exists board_game_play_logs_played_on_idx on public.board_game_play_logs(played_on desc);
create index if not exists board_game_play_logs_game_id_idx on public.board_game_play_logs(game_id);
