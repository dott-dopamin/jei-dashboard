-- V34 patch: allow people who know the shared campaign code to edit/save.
-- Run once in Supabase SQL Editor. Existing campaign data is preserved.

create or replace function public.save_pandemic_legacy_s1(
  p_code text,
  p_data jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
begin
  -- Signed-in JEI admin can save without the shared code.
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

revoke all on function public.save_pandemic_legacy_s1(text, jsonb) from public;
grant execute on function public.save_pandemic_legacy_s1(text, jsonb) to anon, authenticated;
