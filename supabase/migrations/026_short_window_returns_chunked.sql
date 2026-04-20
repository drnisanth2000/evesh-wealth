-- 026_short_window_returns_chunked.sql
--
-- PostgREST imposes an 8-second statement timeout on user-callable RPCs,
-- and the asof-style join in 025 still cannot finish in that budget once
-- nav_history holds ~1k funds × ~3k rows each (≈3M scan rows × 5
-- windows). Rather than fight the timeout we add a chunked variant that
-- processes a slice of funds at a time and returns the count, so a
-- shell loop can iterate the universe in ~150-fund batches.
--
-- The cron job continues to call the unchunked variant — Postgres' own
-- timeout for autovacuum / cron-invoked SECURITY DEFINER calls is much
-- higher (the cron worker doesn't go through PostgREST), so the nightly
-- run still completes in one shot.

CREATE OR REPLACE FUNCTION public.refresh_short_window_returns_chunk(
  p_offset integer,
  p_limit  integer
)
RETURNS TABLE(updated_funds bigint, total_eligible bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated bigint := 0;
  v_eligible bigint := 0;
BEGIN
  WITH latest AS (
    SELECT amfi_code, latest_date, latest_nav
    FROM (
      SELECT DISTINCT ON (amfi_code)
             amfi_code,
             nav_date AS latest_date,
             nav      AS latest_nav
      FROM nav_history
      WHERE nav IS NOT NULL AND nav > 0
      ORDER BY amfi_code, nav_date DESC
    ) s
    ORDER BY amfi_code
    OFFSET p_offset
    LIMIT p_limit
  ),
  targets AS (
    SELECT
      l.amfi_code, l.latest_date, l.latest_nav,
      w.window_days,
      (l.latest_date - make_interval(days => w.window_days))::date AS target_date
    FROM latest l
    CROSS JOIN (VALUES (7), (15), (30), (90), (180)) AS w(window_days)
  ),
  matched AS (
    SELECT DISTINCT ON (t.amfi_code, t.window_days)
      t.amfi_code, t.window_days, t.latest_nav, h.nav AS old_nav
    FROM targets t
    JOIN nav_history h
      ON h.amfi_code = t.amfi_code
     AND h.nav IS NOT NULL AND h.nav > 0
     AND h.nav_date BETWEEN (t.target_date - INTERVAL '7 days')::date
                        AND (t.target_date + INTERVAL '7 days')::date
    ORDER BY t.amfi_code, t.window_days,
             abs(h.nav_date - t.target_date), h.nav_date
  ),
  pivoted AS (
    SELECT
      amfi_code,
      max(CASE WHEN window_days = 7   THEN ((latest_nav / old_nav) - 1) * 100 END) AS r_7d,
      max(CASE WHEN window_days = 15  THEN ((latest_nav / old_nav) - 1) * 100 END) AS r_15d,
      max(CASE WHEN window_days = 30  THEN ((latest_nav / old_nav) - 1) * 100 END) AS r_1m,
      max(CASE WHEN window_days = 90  THEN ((latest_nav / old_nav) - 1) * 100 END) AS r_3m,
      max(CASE WHEN window_days = 180 THEN ((latest_nav / old_nav) - 1) * 100 END) AS r_6m
    FROM matched
    GROUP BY amfi_code
  ),
  upd AS (
    UPDATE fund_master fm
       SET return_7d  = COALESCE(p.r_7d , fm.return_7d),
           return_15d = COALESCE(p.r_15d, fm.return_15d),
           return_1m  = COALESCE(p.r_1m , fm.return_1m),
           return_3m  = COALESCE(p.r_3m , fm.return_3m),
           return_6m  = COALESCE(p.r_6m , fm.return_6m)
      FROM pivoted p
     WHERE fm.amfi_code = p.amfi_code
       AND (
            p.r_7d  IS DISTINCT FROM fm.return_7d  OR
            p.r_15d IS DISTINCT FROM fm.return_15d OR
            p.r_1m  IS DISTINCT FROM fm.return_1m  OR
            p.r_3m  IS DISTINCT FROM fm.return_3m  OR
            p.r_6m  IS DISTINCT FROM fm.return_6m
       )
     RETURNING fm.amfi_code
  )
  SELECT
    (SELECT count(*) FROM upd),
    (SELECT count(*) FROM latest)
  INTO v_updated, v_eligible;

  RETURN QUERY SELECT v_updated, v_eligible;
END;
$$;

GRANT EXECUTE ON FUNCTION public.refresh_short_window_returns_chunk(integer, integer) TO service_role;
