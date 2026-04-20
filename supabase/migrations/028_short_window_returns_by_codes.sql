-- 028_short_window_returns_by_codes.sql
--
-- Migration 026's chunked variant still scanned the entire nav_history
-- table to compute the `latest` CTE before slicing — which broke once
-- nav_history grew past ~8M rows. This variant takes an explicit
-- amfi_code[] parameter so the planner can use the (amfi_code, nav_date)
-- index to pick latest_nav per fund without a full scan.
--
-- Caller passes ~50-100 codes per call; PostgREST is happy and the
-- per-call cost is bounded.

CREATE OR REPLACE FUNCTION public.refresh_short_window_returns_for_codes(
  p_codes integer[]
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated bigint := 0;
BEGIN
  WITH latest AS (
    SELECT DISTINCT ON (amfi_code)
           amfi_code,
           nav_date AS latest_date,
           nav      AS latest_nav
    FROM nav_history
    WHERE amfi_code = ANY(p_codes)
      AND nav IS NOT NULL AND nav > 0
    ORDER BY amfi_code, nav_date DESC
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
  SELECT count(*) INTO v_updated FROM upd;
  RETURN v_updated;
END;
$$;

GRANT EXECUTE ON FUNCTION public.refresh_short_window_returns_for_codes(integer[]) TO service_role;
