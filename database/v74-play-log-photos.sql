-- V74: 플레이 로그 사진 첨부 (최대 3장)
-- 기존 플레이 로그 데이터는 그대로 유지됩니다.

alter table public.board_game_play_logs
add column if not exists photos jsonb not null default '[]'::jsonb;

alter table public.board_game_play_logs
  drop constraint if exists board_game_play_logs_photos_array_check;
alter table public.board_game_play_logs
  add constraint board_game_play_logs_photos_array_check
  check (jsonb_typeof(photos) = 'array');

insert into storage.buckets (id, name, public)
values ('board-game-play-log-images', 'board-game-play-log-images', true)
on conflict (id) do update set public = true;

drop policy if exists "play log images public read" on storage.objects;
drop policy if exists "play log images authenticated insert" on storage.objects;
drop policy if exists "play log images authenticated update" on storage.objects;
drop policy if exists "play log images authenticated delete" on storage.objects;

create policy "play log images public read"
on storage.objects for select
to public
using (bucket_id = 'board-game-play-log-images');

create policy "play log images authenticated insert"
on storage.objects for insert
to authenticated
with check (bucket_id = 'board-game-play-log-images');

create policy "play log images authenticated update"
on storage.objects for update
to authenticated
using (bucket_id = 'board-game-play-log-images')
with check (bucket_id = 'board-game-play-log-images');

create policy "play log images authenticated delete"
on storage.objects for delete
to authenticated
using (bucket_id = 'board-game-play-log-images');
