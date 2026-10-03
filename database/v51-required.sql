-- JEI Dashboard V51
-- 1) 잔룰 노트 테이블
create table if not exists public.board_game_rule_notes (
  game_id uuid primary key references public.board_games(id) on delete cascade,
  note text not null default '',
  updated_at timestamptz not null default now()
);
alter table public.board_game_rule_notes enable row level security;
grant select on public.board_game_rule_notes to anon;
grant select,insert,update,delete on public.board_game_rule_notes to authenticated;
drop policy if exists "public read board game rule notes" on public.board_game_rule_notes;
drop policy if exists "authenticated manage board game rule notes" on public.board_game_rule_notes;
create policy "public read board game rule notes" on public.board_game_rule_notes for select to anon using (true);
create policy "authenticated manage board game rule notes" on public.board_game_rule_notes for all to authenticated using (true) with check (true);

-- 2) 팬데믹 S1 회차 사진
-- 공유 비밀번호 사용자는 direct table access 대신 아래 SECURITY DEFINER RPC로만 접근합니다.
create table if not exists public.pandemic_legacy_s1_photos (
  id uuid primary key default gen_random_uuid(),
  session_id text not null,
  data_url text not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_pandemic_legacy_s1_photos_session on public.pandemic_legacy_s1_photos(session_id,created_at);
alter table public.pandemic_legacy_s1_photos enable row level security;
grant select,insert,delete on public.pandemic_legacy_s1_photos to authenticated;
drop policy if exists "authenticated manage pandemic legacy photos" on public.pandemic_legacy_s1_photos;
create policy "authenticated manage pandemic legacy photos" on public.pandemic_legacy_s1_photos for all to authenticated using (true) with check (true);

create or replace function public.get_pandemic_legacy_s1_photos(p_code text, p_session_id text)
returns table(id uuid, session_id text, data_url text, created_at timestamptz)
language plpgsql security definer set search_path=public
as $$
declare v_code text;
begin
  if auth.uid() is null then
    select access_code into v_code from public.pandemic_legacy_s1_settings where id=1;
    if p_code is null or p_code<>v_code then raise exception 'INVALID_CODE' using errcode='P0001'; end if;
  end if;
  return query select p.id,p.session_id,p.data_url,p.created_at from public.pandemic_legacy_s1_photos p where p.session_id=p_session_id order by p.created_at;
end;$$;

create or replace function public.save_pandemic_legacy_s1_photo(p_code text, p_session_id text, p_data_url text)
returns uuid
language plpgsql security definer set search_path=public
as $$
declare v_code text; v_id uuid; v_count integer;
begin
  if auth.uid() is null then
    select access_code into v_code from public.pandemic_legacy_s1_settings where id=1;
    if p_code is null or p_code<>v_code then raise exception 'INVALID_CODE' using errcode='P0001'; end if;
  end if;
  if p_data_url is null or p_data_url not like 'data:image/%' then raise exception 'INVALID_IMAGE'; end if;
  if length(p_data_url)>1500000 then raise exception 'PHOTO_TOO_LARGE'; end if;
  select count(*) into v_count from public.pandemic_legacy_s1_photos where session_id=p_session_id;
  if v_count>=3 then raise exception 'PHOTO_LIMIT'; end if;
  insert into public.pandemic_legacy_s1_photos(session_id,data_url) values(p_session_id,p_data_url) returning id into v_id;
  return v_id;
end;$$;

create or replace function public.delete_pandemic_legacy_s1_photo(p_code text, p_photo_id uuid)
returns void
language plpgsql security definer set search_path=public
as $$
declare v_code text;
begin
  if auth.uid() is null then
    select access_code into v_code from public.pandemic_legacy_s1_settings where id=1;
    if p_code is null or p_code<>v_code then raise exception 'INVALID_CODE' using errcode='P0001'; end if;
  end if;
  delete from public.pandemic_legacy_s1_photos where id=p_photo_id;
end;$$;

create or replace function public.delete_pandemic_legacy_s1_session_photos(p_code text, p_session_id text)
returns void
language plpgsql security definer set search_path=public
as $$
declare v_code text;
begin
  if auth.uid() is null then
    select access_code into v_code from public.pandemic_legacy_s1_settings where id=1;
    if p_code is null or p_code<>v_code then raise exception 'INVALID_CODE' using errcode='P0001'; end if;
  end if;
  delete from public.pandemic_legacy_s1_photos where session_id=p_session_id;
end;$$;

revoke all on function public.get_pandemic_legacy_s1_photos(text,text) from public;
revoke all on function public.save_pandemic_legacy_s1_photo(text,text,text) from public;
revoke all on function public.delete_pandemic_legacy_s1_photo(text,uuid) from public;
revoke all on function public.delete_pandemic_legacy_s1_session_photos(text,text) from public;
grant execute on function public.get_pandemic_legacy_s1_photos(text,text) to anon,authenticated;
grant execute on function public.save_pandemic_legacy_s1_photo(text,text,text) to anon,authenticated;
grant execute on function public.delete_pandemic_legacy_s1_photo(text,uuid) to anon,authenticated;
grant execute on function public.delete_pandemic_legacy_s1_session_photos(text,text) to anon,authenticated;
