-- 024_short_window_returns_from_history.sql
--
-- AMFI's fund-performance API returns return_1m / return_3m / return_6m for
-- only ~7% of the universe (mostly because it gates short windows on
-- "scheme age" and category). The screener leaves these cells empty for
-- thousands of well-known funds, which makes the 3M / 6M sort + filters
-- useless.
--
-- We already store full daily NAV history in `nav_history` (loaded
-- on-demand by `fetch-nav-batch`). This migration adds a function that
-- recomputes return_7d / return_15d / return_1m / return_3m / return_6m
-- straight from `nav_history` for every fund that has enough history,
-- and schedules it to run nightly after the AMFI refresh.
--
-- Window definitions: each window N picks the NAV row whose date is
-- nearest to (latest_date - N days), with a tolerance of 7 calendar days
-- to avoid being defeated by long holiday clusters. We then return
-- (latest_nav / window_nav) - 1, expressed as a percentage to match the
-- existing column convention (return_1y is stored as e.g. 12.34, not 0.1234).
--
-- This function is *idempotent* and *additive*: it never overwrites a
-- value with NULL (so a fund with only 14 days of history won't have its
-- valid return_7d wiped just because return_1m can't be computed).

CREATE OR REPLACE FUNCTION public.refresh_short_window_returns()
RETURNS TABLE(updated_funds bigint, total_eligible bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated bigint := 0;
  v_eligible bigint := 0;
BEGIN
  -- Build a per-fund snapshot of (latest_date, latest_nav) once.
  WITH latest AS (
    SELECT DISTINCT ON (amfi_code)
           amfi_code,
           nav_date AS latest_date,
           nav      AS latest_nav
    FROM nav_history
    WHERE nav IS NOT NULL AND nav > 0
    ORDER BY amfi_code, nav_date DESC
  ),
  -- For each window N, find the NAV row in nav_history closest to
  -- (latest_date - N days), within ±7 days. We use LATERAL so each
  -- window lookup is independent and missing windows just stay NULL.
  picks AS (
    SELECT
      l.amfi_code,
      l.latest_nav,
      (SELECT nav FROM nav_history h
        WHERE h.amfi_code = l.amfi_code
          AND h.nav IS NOT NULL AND h.nav > 0
          AND h.nav_date BETWEEN (l.latest_date - INTERVAL '7 days'  - INTERVAL '7 days')
                              AND (l.latest_date - INTERVAL '7 days'  + INTERVAL '7 days')
        ORDER BY abs(extract(epoch FROM (h.nav_date - (l.latest_date - INTERVAL '7 days'))))
        LIMIT 1)  AS nav_7d,
      (SELECT nav FROM nav_history h
        WHERE h.amfi_code = l.amfi_code
          AND h.nav IS NOT NULL AND h.nav > 0
          AND h.nav_date BETWEEN (l.latest_date - INTERVAL '15 days' - INTERVAL '7 days')
                              AND (l.latest_date - INTERVAL '15 days' + INTERVAL '7 days')
        ORDER BY abs(extract(epoch FROM (h.nav_date - (l.latest_date - INTERVAL '15 days'))))
        LIMIT 1)  AS nav_15d,
      (SELECT nav FROM nav_history h
        WHERE h.amfi_code = l.amfi_code
          AND h.nav IS NOT NULL AND h.nav > 0
          AND h.nav_date BETWEEN (l.latest_date - INTERVAL '30 days' - INTERVAL '7 days')
                              AND (l.latest_date - INTERVAL '30 days' + INTERVAL '7 days')
        ORDER BY abs(extract(epoch FROM (h.nav_date - (l.latest_date - INTERVAL '30 days'))))
        LIMIT 1)  AS nav_1m,
      (SELECT nav FROM nav_history h
        WHERE h.amfi_code = l.amfi_code
          AND h.nav IS NOT NULL AND h.nav > 0
          AND h.nav_date BETWEEN (l.latest_date - INTERVAL '90 days' - INTERVAL '7 days')
                              AND (l.latest_date - INTERVAL '90 days' + INTERVAL '7 days')
        ORDER BY abs(extract(epoch FROM (h.nav_date - (l.latest_date - INTERVAL '90 days'))))
        LIMIT 1)  AS nav_3m,
      (SELECT nav FROM nav_history h
        WHERE h.amfi_code = l.amfi_code
          AND h.nav IS NOT NULL AND h.nav > 0
          AND h.nav_date BETWEEN (l.latest_date - INTERVAL '180 days' - INTERVAL '7 days')
                              AND (l.latest_date - INTERVAL '180 days' + INTERVAL '7 days')
        ORDER BY abs(extract(epoch FROM (h.nav_date - (l.latest_date - INTERVAL '180 days'))))
        LIMIT 1)  AS nav_6m
    FROM latest l
  ),
  computed AS (
    SELECT
      amfi_code,
      CASE WHEN nav_7d  IS NOT NULL THEN ((latest_nav / nav_7d ) - 1.0) * 100.0 END AS r_7d,
      CASE WHEN nav_15d IS NOT NULL THEN ((latest_nav / nav_15d) - 1.0) * 100.0 END AS r_15d,
      CASE WHEN nav_1m  IS NOT NULL THEN ((latest_nav / nav_1m ) - 1.0) * 100.0 END AS r_1m,
      CASE WHEN nav_3m  IS NOT NULL THEN ((latest_nav / nav_3m ) - 1.0) * 100.0 END AS r_3m,
      CASE WHEN nav_6m  IS NOT NULL THEN ((latest_nav / nav_6m ) - 1.0) * 100.0 END AS r_6m
    FROM picks
  ),
  upd AS (
    UPDATE fund_master fm
       SET return_7d  = COALESCE(c.r_7d , fm.return_7d),
           return_15d = COALESCE(c.r_15d, fm.return_15d),
           return_1m  = COALESCE(c.r_1m , fm.return_1m),
           return_3m  = COALESCE(c.r_3m , fm.return_3m),
           return_6m  = COALESCE(c.r_6m , fm.return_6m)
      FROM computed c
     WHERE fm.amfi_code = c.amfi_code
       AND (
            c.r_7d  IS DISTINCT FROM fm.return_7d  OR
            c.r_15d IS DISTINCT FROM fm.return_15d OR
            c.r_1m  IS DISTINCT FROM fm.return_1m  OR
            c.r_3m  IS DISTINCT FROM fm.return_3m  OR
            c.r_6m  IS DISTINCT FROM fm.return_6m
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

GRANT EXECUTE ON FUNCTION public.refresh_short_window_returns() TO service_role;

-- Schedule nightly at 04:00 UTC (09:30 IST), 30 minutes after the AMFI
-- performance refresh runs at 03:30 UTC. Re-runnable.
DO $$
BEGIN
  PERFORM cron.unschedule('refresh_short_window_returns_daily');
EXCEPTION WHEN OTHERS THEN
  NULL;
END$$;

SELECT cron.schedule(
  'refresh_short_window_returns_daily',
  '0 4 * * *',  -- 09:30 IST every day
  $$ SELECT public.refresh_short_window_returns(); $$
);
