-- V110: completion timestamp for each person's TODO items.
-- Run ONCE in the existing Supabase project (SQL Editor); existing rows remain unchanged.
begin;
alter table public.todos add column if not exists completed_at timestamptz;
comment on column public.todos.completed_at is 'When this task was marked complete; null if not completed or previously unknown';
commit;
