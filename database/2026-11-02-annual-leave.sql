-- JEI Dashboard V111: 연차 관리 / Existing Supabase project ONLY.
-- Apply ONCE in SQL Editor. Does not modify any existing table or data.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE IF NOT EXISTS public.dashboard_leave_years (
  owner_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  year integer NOT NULL CHECK (year BETWEEN 2000 AND 2100),
  total_days numeric(5,1) NOT NULL DEFAULT 0 CHECK (total_days >= 0 AND total_days <= 365 AND mod(total_days * 2, 1) = 0),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (owner_id,year)
);
CREATE TABLE IF NOT EXISTS public.dashboard_leave_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  start_date date NOT NULL,
  end_date date NOT NULL,
  leave_type text NOT NULL CHECK (leave_type IN ('full','am','pm')),
  note text NOT NULL DEFAULT '' CHECK(length(note) <= 300),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT dashboard_leave_dates_order CHECK (end_date >= start_date),
  CONSTRAINT dashboard_leave_same_year CHECK (EXTRACT(YEAR FROM start_date) = EXTRACT(YEAR FROM end_date)),
  CONSTRAINT dashboard_leave_half_single CHECK (leave_type = 'full' OR start_date = end_date)
);
CREATE INDEX IF NOT EXISTS idx_dashboard_leave_owner_dates ON public.dashboard_leave_entries(owner_id,start_date,end_date);
ALTER TABLE public.dashboard_leave_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dashboard_leave_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dashboard_leave_years FORCE ROW LEVEL SECURITY;
ALTER TABLE public.dashboard_leave_entries FORCE ROW LEVEL SECURITY;
REVOKE ALL ON public.dashboard_leave_years FROM PUBLIC, anon;
REVOKE ALL ON public.dashboard_leave_entries FROM PUBLIC, anon;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.dashboard_leave_years TO authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.dashboard_leave_entries TO authenticated;
DROP POLICY IF EXISTS jei_leave_year_select ON public.dashboard_leave_years;
DROP POLICY IF EXISTS jei_leave_year_insert ON public.dashboard_leave_years;
DROP POLICY IF EXISTS jei_leave_year_update ON public.dashboard_leave_years;
DROP POLICY IF EXISTS jei_leave_year_delete ON public.dashboard_leave_years;
CREATE POLICY jei_leave_year_select ON public.dashboard_leave_years FOR SELECT TO authenticated USING (owner_id = (select auth.uid()));
CREATE POLICY jei_leave_year_insert ON public.dashboard_leave_years FOR INSERT TO authenticated WITH CHECK (owner_id = (select auth.uid()));
CREATE POLICY jei_leave_year_update ON public.dashboard_leave_years FOR UPDATE TO authenticated USING (owner_id = (select auth.uid())) WITH CHECK (owner_id = (select auth.uid()));
CREATE POLICY jei_leave_year_delete ON public.dashboard_leave_years FOR DELETE TO authenticated USING (owner_id = (select auth.uid()));
DROP POLICY IF EXISTS jei_leave_entry_select ON public.dashboard_leave_entries;
DROP POLICY IF EXISTS jei_leave_entry_insert ON public.dashboard_leave_entries;
DROP POLICY IF EXISTS jei_leave_entry_update ON public.dashboard_leave_entries;
DROP POLICY IF EXISTS jei_leave_entry_delete ON public.dashboard_leave_entries;
CREATE POLICY jei_leave_entry_select ON public.dashboard_leave_entries FOR SELECT TO authenticated USING (owner_id = (select auth.uid()));
CREATE POLICY jei_leave_entry_insert ON public.dashboard_leave_entries FOR INSERT TO authenticated WITH CHECK (owner_id = (select auth.uid()));
CREATE POLICY jei_leave_entry_update ON public.dashboard_leave_entries FOR UPDATE TO authenticated USING (owner_id = (select auth.uid())) WITH CHECK (owner_id = (select auth.uid()));
CREATE POLICY jei_leave_entry_delete ON public.dashboard_leave_entries FOR DELETE TO authenticated USING (owner_id = (select auth.uid()));
COMMIT;

-- Check individual account visibility by signing in as that account:
-- select * from public.dashboard_leave_entries where owner_id = auth.uid();
-- SQL Editor runs with admin privileges; do NOT treat SQL Editor outputs as an RLS user test.
