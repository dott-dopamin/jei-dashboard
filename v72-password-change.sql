-- JEI Dashboard V72 — Pandemic Legacy Season 2 password change
-- Run once in Supabase SQL Editor.
-- Existing Season 2 data is untouched.

create or replace function public.change_pandemic_legacy_s2_code(
  p_current_code text,
  p_new_code text
)
returns boolean
language plpgsql
security definer
set search_path=public
as $$
declare
  v_code text;
begin
  if p_new_code is null or length(trim(p_new_code)) < 4 then
    raise exception 'INVALID_NEW_CODE' using errcode='22023';
  end if;

  -- Shared editors must prove the current code.
  -- An authenticated site admin may change it without re-entering the old code.
  if auth.uid() is null then
    select access_code into v_code
    from public.pandemic_legacy_s2_settings
    where id = 1;

    if p_current_code is null or p_current_code <> v_code then
      raise exception 'INVALID_CODE' using errcode='P0001';
    end if;
  end if;

  update public.pandemic_legacy_s2_settings
  set access_code = trim(p_new_code)
  where id = 1;

  return true;
end;
$$;

revoke all on function public.change_pandemic_legacy_s2_code(text,text) from public;
grant execute on function public.change_pandemic_legacy_s2_code(text,text) to anon, authenticated;
