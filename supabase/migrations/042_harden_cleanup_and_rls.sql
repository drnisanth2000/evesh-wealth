-- 042_harden_cleanup_and_rls.sql
--
-- (a) Replace cleanup_nav_history_chunk with a hardened version that
--     caps its own statement_timeout so a client disconnect can't
--     leave a zombie DELETE running and exhausting the connection
--     pool (which is exactly what happened during the first cleanup
--     pass — one 50k chunk hung server-side for 15+ minutes and took
--     down REST until a project restart).
--
-- (b) Enable Row-Level Security on the six tables flagged by the
--     Supabase security advisor. We add permissive policies that
--     preserve the current behaviour (reads from anon/authenticated,
--     writes only via service_role) so the app keeps working.
--
-- (c) Drop + recreate nav_history_all as a plain view (not SECURITY
--     DEFINER) — the INCLUDING ALL clone in migration 035 carried
--     over some default we didn't want.
--
-- (d) Pin search_path on every helper function we added this week
--     (cleanup_nav_history_chunk, array_distinct, etc.). Without
--     this the linter warns "Function Search Path Mutable" because
--     a malicious user with CREATE on a schema earlier in the path
--     could shadow pg_catalog symbols.

-- ────────────────────────────────────────────────────────────────
-- (a) Hardened cleanup function
-- ────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.cleanup_nav_history_chunk(p_chunk int DEFAULT 25000)
RETURNS int
LANGUAGE plpgsql
SET search_path = public, pg_temp
SET statement_timeout = '20s'
SET lock_timeout = '5s'
AS $$
DECLARE
  v_deleted int;
BEGIN
  -- Uses the fund_master_warm_active_idx partial index via an
  -- anti-join: rows whose amfi_code is NOT in the warm set, OR
  -- whose nav_date is older than 400 days.
  WITH victims AS (
    SELECT h.ctid
      FROM public.nav_history h
     WHERE NOT EXISTS (
             SELECT 1 FROM public.fund_master f
              WHERE f.amfi_code = h.amfi_code
                AND f.tracked_tier = 'warm'
                AND f.is_active = true
           )
        OR h.nav_date < (current_date - 400)
     LIMIT p_chunk
  )
  DELETE FROM public.nav_history h
  USING victims
  WHERE h.ctid = victims.ctid;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;

GRANT EXECUTE ON FUNCTION public.cleanup_nav_history_chunk(int) TO service_role;

-- ────────────────────────────────────────────────────────────────
-- (b) Enable RLS on flagged tables
-- ────────────────────────────────────────────────────────────────

-- fund_holdings_cache: read-only derived cache, readable by all,
-- writable only by service_role (which bypasses RLS anyway).
ALTER TABLE IF EXISTS public.fund_holdings_cache ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "fund_holdings_cache_select" ON public.fund_holdings_cache;
CREATE POLICY "fund_holdings_cache_select" ON public.fund_holdings_cache
  FOR SELECT TO anon, authenticated USING (true);

-- amfi_category: static reference data, readable by all.
ALTER TABLE IF EXISTS public.amfi_category ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "amfi_category_select" ON public.amfi_category;
CREATE POLICY "amfi_category_select" ON public.amfi_category
  FOR SELECT TO anon, authenticated USING (true);

-- index_nav_history: benchmark NAV history, readable by all.
ALTER TABLE IF EXISTS public.index_nav_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "index_nav_history_select" ON public.index_nav_history;
CREATE POLICY "index_nav_history_select" ON public.index_nav_history
  FOR SELECT TO anon, authenticated USING (true);

-- fund_perf_sync_log: internal log, readable by authenticated only.
ALTER TABLE IF EXISTS public.fund_perf_sync_log ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "fund_perf_sync_log_select" ON public.fund_perf_sync_log;
CREATE POLICY "fund_perf_sync_log_select" ON public.fund_perf_sync_log
  FOR SELECT TO authenticated USING (true);

-- nav_history_archive: archive table, readable by all (mirrors nav_history).
ALTER TABLE IF EXISTS public.nav_history_archive ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "nav_history_archive_select" ON public.nav_history_archive;
CREATE POLICY "nav_history_archive_select" ON public.nav_history_archive
  FOR SELECT TO anon, authenticated USING (true);

-- ────────────────────────────────────────────────────────────────
-- (c) Fix nav_history_all — recreate as plain view
-- ────────────────────────────────────────────────────────────────

DROP VIEW IF EXISTS public.nav_history_all;
CREATE VIEW public.nav_history_all
WITH (security_invoker = true) AS
SELECT amfi_code, nav_date, nav FROM public.nav_history
UNION ALL
SELECT amfi_code, nav_date, nav FROM public.nav_history_archive;

GRANT SELECT ON public.nav_history_all TO anon, authenticated, service_role;

-- ────────────────────────────────────────────────────────────────
-- (d) Pin search_path on the new helper functions
-- ────────────────────────────────────────────────────────────────

ALTER FUNCTION public.array_distinct(anyarray)           SET search_path = public, pg_temp;
ALTER FUNCTION public.evaluate_fund_tracked_tier()       SET search_path = public, pg_temp;
ALTER FUNCTION public.promote_fund_to_warm(integer, text) SET search_path = public, pg_temp;
ALTER FUNCTION public.promote_funds_to_warm(integer[], text) SET search_path = public, pg_temp;
ALTER FUNCTION public.pick_prewarm_batch(int, int)       SET search_path = public, pg_temp;
ALTER FUNCTION public.mark_prewarm_done(integer[])       SET search_path = public, pg_temp;
ALTER FUNCTION public.refresh_fund_screener_mv()         SET search_path = public, pg_temp;
ALTER FUNCTION public.archive_old_nav_history(int, int)  SET search_path = public, pg_temp;
