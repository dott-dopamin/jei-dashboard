-- JEI Dashboard V55
-- 잔룰 노트를 보드게임 책장 DB와 분리해서 독립 관리합니다.

create table if not exists public.game_rule_notes (
  id uuid primary key default gen_random_uuid(),
  game_name text not null unique,
  note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.game_rule_notes enable row level security;

grant select on public.game_rule_notes to anon;
grant select,insert,update,delete on public.game_rule_notes to authenticated;

drop policy if exists "public read game rule notes" on public.game_rule_notes;
drop policy if exists "authenticated manage game rule notes" on public.game_rule_notes;

create policy "public read game rule notes"
on public.game_rule_notes
for select
to anon
using (true);

create policy "authenticated manage game rule notes"
on public.game_rule_notes
for all
to authenticated
using (true)
with check (true);

-- 기존 V50/V51 방식의 잔룰 데이터가 이미 있다면 비어 있지 않은 메모만 자동 이관합니다.
-- 기존 테이블은 안전을 위해 삭제하지 않습니다.
do $$
begin
  if to_regclass('public.board_game_rule_notes') is not null then
    insert into public.game_rule_notes (game_name,note,updated_at)
    select b.title, r.note, coalesce(r.updated_at,now())
    from public.board_game_rule_notes r
    join public.board_games b on b.id=r.game_id
    where trim(coalesce(r.note,''))<>''
    on conflict (game_name) do update
      set note=excluded.note, updated_at=excluded.updated_at;
  end if;
end $$;
