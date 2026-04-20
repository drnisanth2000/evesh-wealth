-- 035_nav_history_archive.sql
--
-- Creates nav_history_archive and a function archive_old_nav_history()
-- that moves rows older than N days out of the hot table. nav_history
-- currently has ~7.8M rows, most of which are only read by the short-
-- window returns job which looks back at most 180 days. Keeping a
-- 400-day hot window (enough for 1Y returns with safety margin) cuts
-- the hot table to ~1M rows and shrinks every scan proportionally.
--
-- The archive table uses the same schema and same indexes so long-
-- horizon analytics (5Y rolling, XIRR) can still query it via a UNION
-- ALL view if needed.
--
-- NOTE: the archive function is NOT called from this migration. Run it
-- manually from the dashboard SQL editor AFTER the Disk IO Budget alert
-- has cleared, and during low-traffic hours. Moving 6M rows is a
-- one-time 10-15 minute IO-heavy operation.

CREATE TABLE IF NOT EXISTS public.nav_history_archive (
  LIKE public.nav_history INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES
);

COMMENT ON TABLE public.nav_history_archive IS
  'Cold-storage mirror of nav_history for rows older than the hot-window cutoff. '
  'Updated by archive_old_nav_history(). Read only for long-horizon analytics.';

-- Convenience view that seamlessly queries both tables for code that
-- needs historical data without caring about the split.
CREATE OR REPLACE VIEW public.nav_history_all AS
  SELECT * FROM public.nav_history
  UNION ALL
  SELECT * FROM public.nav_history_archive;

COMMENT ON VIEW public.nav_history_all IS
  'Hot + archived NAV history combined. Use for 3Y/5Y/10Y rolling returns. '
  'Short-window (<=180d) returns should query nav_history directly for speed.';

-- Main archive function. Chunked so we never move more than N rows in
-- a single transaction, avoiding long locks and letting IO pace itself.
CREATE OR REPLACE FUNCTION public.archive_old_nav_history(
  p_cutoff_days int DEFAULT 400,
  p_chunk_size  int DEFAULT 50000
)
RETURNS TABLE(archived_rows bigint, remaining_hot bigint, remaining_archive bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cutoff date := (current_date - make_interval(days => p_cutoff_days))::date;
  v_moved  bigint := 0;
  v_batch  bigint;
BEGIN
  LOOP
    WITH victims AS (
      SELECT amfi_code, nav_date
        FROM nav_history
       WHERE nav_date < v_cutoff
       LIMIT p_chunk_size
    ),
    moved AS (
      DELETE FROM nav_history h
       USING victims v
       WHERE h.amfi_code = v.amfi_code AND h.nav_date = v.nav_date
       RETURNING h.*
    )
    INSERT INTO nav_history_archive
    SELECT * FROM moved
    ON CONFLICT DO NOTHING;

    GET DIAGNOSTICS v_batch = ROW_COUNT;
    v_moved := v_moved + v_batch;
    EXIT WHEN v_batch = 0;

    -- Let the DB breathe between chunks so we don't starve concurrent
    -- cron jobs and API traffic.
    PERFORM pg_sleep(0.2);
  END LOOP;

  RETURN QUERY
    SELECT v_moved,
           (SELECT count(*) FROM nav_history),
           (SELECT count(*) FROM nav_history_archive);
END;
$$;

GRANT EXECUTE ON FUNCTION public.archive_old_nav_history(int, int) TO service_role;
