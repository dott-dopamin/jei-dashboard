-- JEI / Pandemic Legacy Season 1 campaign page
-- Run once in Supabase SQL Editor.

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

alter table public.pandemic_legacy_s1_state enable row level security;
alter table public.pandemic_legacy_s1_settings enable row level security;

grant select, insert, update, delete on table public.pandemic_legacy_s1_state to authenticated;
grant select, insert, update, delete on table public.pandemic_legacy_s1_settings to authenticated;

create policy "authenticated full access pandemic legacy state"
on public.pandemic_legacy_s1_state
for all to authenticated
using (true)
with check (true);

create policy "authenticated full access pandemic legacy settings"
on public.pandemic_legacy_s1_settings
for all to authenticated
using (true)
with check (true);

insert into public.pandemic_legacy_s1_state (id, data)
values (
  1,
  jsonb_build_object(
    'meta', jsonb_build_object(
      'current_month','1월',
      'attempt',1,
      'funding','',
      'last_result','',
      'next_note',''
    ),
    'players', jsonb_build_array(
      jsonb_build_object('name','제이','character','','role',''),
      jsonb_build_object('name','승연','character','','role',''),
      jsonb_build_object('name','우리','character','','role',''),
      jsonb_build_object('name','종우','character','','role','')
    ),
    'sessions', '[]'::jsonb
  )
)
on conflict (id) do nothing;

insert into public.pandemic_legacy_s1_settings (id, access_code)
values (1, '1017')
on conflict (id) do update set access_code = excluded.access_code;

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

revoke all on function public.get_pandemic_legacy_s1(text) from public;
grant execute on function public.get_pandemic_legacy_s1(text) to anon, authenticated;

-- Later, to change the shared password:
-- update public.pandemic_legacy_s1_settings set access_code = 'NEW_PASSWORD' where id = 1;
