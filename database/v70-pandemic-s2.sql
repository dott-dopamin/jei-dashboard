-- JEI Dashboard V70 — Pandemic Legacy Season 2
-- Shared edit password defaults to 1017. Existing S1 data is untouched.

create table if not exists public.pandemic_legacy_s2_state (
  id integer primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  constraint pandemic_legacy_s2_singleton check (id = 1)
);

create table if not exists public.pandemic_legacy_s2_settings (
  id integer primary key,
  access_code text not null,
  constraint pandemic_legacy_s2_settings_singleton check (id = 1)
);

alter table public.pandemic_legacy_s2_state enable row level security;
alter table public.pandemic_legacy_s2_settings enable row level security;
grant select, insert, update, delete on table public.pandemic_legacy_s2_state to authenticated;
grant select, insert, update, delete on table public.pandemic_legacy_s2_settings to authenticated;

drop policy if exists "authenticated full access pandemic legacy s2 state" on public.pandemic_legacy_s2_state;
create policy "authenticated full access pandemic legacy s2 state"
on public.pandemic_legacy_s2_state for all to authenticated
using (true) with check (true);

drop policy if exists "authenticated full access pandemic legacy s2 settings" on public.pandemic_legacy_s2_settings;
create policy "authenticated full access pandemic legacy s2 settings"
on public.pandemic_legacy_s2_settings for all to authenticated
using (true) with check (true);

insert into public.pandemic_legacy_s2_state (id, data)
values (1, jsonb_build_object(
  'meta', jsonb_build_object(
    'current_month','1월','attempt',1,'rationing',4,'last_result','',
    'next_note','','current_objectives','','current_rules','','permanent_summary',''
  ),
  'players', jsonb_build_array(
    jsonb_build_object('name','다은','color','pink','character','','role','','detail',''),
    jsonb_build_object('name','한철','color','black','character','','role','','detail',''),
    jsonb_build_object('name','승민','color','blue','character','','role','','detail',''),
    jsonb_build_object('name','제이','color','white','character','','role','','detail','')
  ),
  'sessions', '[]'::jsonb
)) on conflict (id) do nothing;

insert into public.pandemic_legacy_s2_settings (id, access_code)
values (1, '1017')
on conflict (id) do nothing;

create or replace function public.get_pandemic_legacy_s2(p_code text)
returns jsonb
language plpgsql security definer set search_path=public
as $$
declare v_code text; v_data jsonb;
begin
  select access_code into v_code from public.pandemic_legacy_s2_settings where id=1;
  if p_code is null or p_code<>v_code then raise exception 'INVALID_CODE' using errcode='P0001'; end if;
  select data into v_data from public.pandemic_legacy_s2_state where id=1;
  return coalesce(v_data,'{}'::jsonb);
end;$$;

create or replace function public.save_pandemic_legacy_s2(p_code text, p_data jsonb)
returns jsonb
language plpgsql security definer set search_path=public
as $$
declare v_code text;
begin
  if auth.uid() is null then
    select access_code into v_code from public.pandemic_legacy_s2_settings where id=1;
    if p_code is null or p_code<>v_code then raise exception 'INVALID_CODE' using errcode='P0001'; end if;
  end if;
  update public.pandemic_legacy_s2_state set data=coalesce(p_data,'{}'::jsonb),updated_at=now() where id=1;
  return p_data;
end;$$;

revoke all on function public.get_pandemic_legacy_s2(text) from public;
revoke all on function public.save_pandemic_legacy_s2(text,jsonb) from public;
grant execute on function public.get_pandemic_legacy_s2(text) to anon,authenticated;
grant execute on function public.save_pandemic_legacy_s2(text,jsonb) to anon,authenticated;

-- Session photos (same 1~3 image workflow as S1, but kept completely separate)
create table if not exists public.pandemic_legacy_s2_photos (
  id uuid primary key default gen_random_uuid(),
  session_id text not null,
  data_url text not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_pandemic_legacy_s2_photos_session on public.pandemic_legacy_s2_photos(session_id,created_at);
alter table public.pandemic_legacy_s2_photos enable row level security;
grant select,insert,delete on public.pandemic_legacy_s2_photos to authenticated;
drop policy if exists "authenticated manage pandemic legacy s2 photos" on public.pandemic_legacy_s2_photos;
create policy "authenticated manage pandemic legacy s2 photos" on public.pandemic_legacy_s2_photos for all to authenticated using (true) with check (true);

create or replace function public.get_pandemic_legacy_s2_photos(p_code text,p_session_id text)
returns table(id uuid,session_id text,data_url text,created_at timestamptz)
language plpgsql security definer set search_path=public
as $$
declare v_code text;
begin
  if auth.uid() is null then
    select access_code into v_code from public.pandemic_legacy_s2_settings where id=1;
    if p_code is null or p_code<>v_code then raise exception 'INVALID_CODE' using errcode='P0001'; end if;
  end if;
  return query select p.id,p.session_id,p.data_url,p.created_at from public.pandemic_legacy_s2_photos p where p.session_id=p_session_id order by p.created_at;
end;$$;

create or replace function public.save_pandemic_legacy_s2_photo(p_code text,p_session_id text,p_data_url text)
returns uuid
language plpgsql security definer set search_path=public
as $$
declare v_code text; v_id uuid; v_count integer;
begin
  if auth.uid() is null then
    select access_code into v_code from public.pandemic_legacy_s2_settings where id=1;
    if p_code is null or p_code<>v_code then raise exception 'INVALID_CODE' using errcode='P0001'; end if;
  end if;
  if p_data_url is null or p_data_url not like 'data:image/%' then raise exception 'INVALID_IMAGE'; end if;
  if length(p_data_url)>1500000 then raise exception 'PHOTO_TOO_LARGE'; end if;
  select count(*) into v_count from public.pandemic_legacy_s2_photos where session_id=p_session_id;
  if v_count>=3 then raise exception 'PHOTO_LIMIT'; end if;
  insert into public.pandemic_legacy_s2_photos(session_id,data_url) values(p_session_id,p_data_url) returning id into v_id;
  return v_id;
end;$$;

create or replace function public.delete_pandemic_legacy_s2_photo(p_code text,p_photo_id uuid)
returns void
language plpgsql security definer set search_path=public
as $$
declare v_code text;
begin
  if auth.uid() is null then
    select access_code into v_code from public.pandemic_legacy_s2_settings where id=1;
    if p_code is null or p_code<>v_code then raise exception 'INVALID_CODE' using errcode='P0001'; end if;
  end if;
  delete from public.pandemic_legacy_s2_photos where id=p_photo_id;
end;$$;

create or replace function public.delete_pandemic_legacy_s2_session_photos(p_code text,p_session_id text)
returns void
language plpgsql security definer set search_path=public
as $$
declare v_code text;
begin
  if auth.uid() is null then
    select access_code into v_code from public.pandemic_legacy_s2_settings where id=1;
    if p_code is null or p_code<>v_code then raise exception 'INVALID_CODE' using errcode='P0001'; end if;
  end if;
  delete from public.pandemic_legacy_s2_photos where session_id=p_session_id;
end;$$;

revoke all on function public.get_pandemic_legacy_s2_photos(text,text) from public;
revoke all on function public.save_pandemic_legacy_s2_photo(text,text,text) from public;
revoke all on function public.delete_pandemic_legacy_s2_photo(text,uuid) from public;
revoke all on function public.delete_pandemic_legacy_s2_session_photos(text,text) from public;
grant execute on function public.get_pandemic_legacy_s2_photos(text,text) to anon,authenticated;
grant execute on function public.save_pandemic_legacy_s2_photo(text,text,text) to anon,authenticated;
grant execute on function public.delete_pandemic_legacy_s2_photo(text,uuid) to anon,authenticated;
grant execute on function public.delete_pandemic_legacy_s2_session_photos(text,text) to anon,authenticated;
