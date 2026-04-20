-- 027_copy_short_returns_to_idcw.sql
--
-- For IDCW / Dividend / Reinvestment plan rows, the underlying portfolio
-- is identical to the Growth option of the same scheme & plan_type, so
-- the period RETURNS (1M, 3M, 6M, 1Y, 3Y, 5Y) are identical too — only
-- NAV differs because of dividend payouts. Standard practice (and what
-- AMFI itself shows) is to display the Growth-option total return on
-- the IDCW row.
--
-- We already restrict the AMFI refresh from writing latest_nav/prev_nav
-- onto IDCW rows (migration in refresh-fund-performance-amfi after the
-- -68% Bandhan day-change bug). What's missing is propagation of the
-- short-window returns we now compute from nav_history into the IDCW
-- siblings, since we never seed IDCW codes into nav_history.
--
-- This function matches IDCW rows to their Growth sibling by normalized
-- scheme name (mirrors the matcher in refresh-fund-performance-amfi)
-- and copies the 1M/3M/6M values across. It's idempotent and only
-- writes when the source has a value and the target doesn't.

CREATE OR REPLACE FUNCTION public.copy_growth_returns_to_idcw_siblings()
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated bigint := 0;
BEGIN
  WITH normalized AS (
    SELECT
      amfi_code,
      fund_name,
      plan_type,
      return_1m, return_3m, return_6m, return_7d, return_15d,
      -- Reuse the same normalisation pattern as the AMFI matcher.
      regexp_replace(
        regexp_replace(
          regexp_replace(
            lower(fund_name),
            '\([^)]*\)', ' ', 'g'
          ),
          '\m(direct plan|regular plan|direct|regular|growth option|growth|idcw payout|idcw reinvestment|idcw|dividend payout|dividend reinvestment|dividend|payout|reinvestment|plan|option)\M',
          ' ', 'g'
        ),
        '[^a-z0-9]+', ' ', 'g'
      ) AS normkey,
      (lower(fund_name) ~ '\m(idcw|dividend|payout|reinvest)\M') AS is_idcw
    FROM fund_master
    WHERE is_active = true
  ),
  growth_src AS (
    SELECT
      trim(normkey) AS normkey,
      plan_type,
      max(return_1m)  AS return_1m,
      max(return_3m)  AS return_3m,
      max(return_6m)  AS return_6m,
      max(return_7d)  AS return_7d,
      max(return_15d) AS return_15d
    FROM normalized
    WHERE NOT is_idcw
      AND (return_1m IS NOT NULL OR return_3m IS NOT NULL OR return_6m IS NOT NULL)
    GROUP BY trim(normkey), plan_type
  ),
  upd AS (
    UPDATE fund_master fm
       SET return_1m  = COALESCE(fm.return_1m , g.return_1m),
           return_3m  = COALESCE(fm.return_3m , g.return_3m),
           return_6m  = COALESCE(fm.return_6m , g.return_6m),
           return_7d  = COALESCE(fm.return_7d , g.return_7d),
           return_15d = COALESCE(fm.return_15d, g.return_15d)
      FROM normalized n
      JOIN growth_src g
        ON g.normkey = trim(n.normkey)
       AND g.plan_type = n.plan_type
     WHERE fm.amfi_code = n.amfi_code
       AND n.is_idcw
       AND (
            (fm.return_1m  IS NULL AND g.return_1m  IS NOT NULL) OR
            (fm.return_3m  IS NULL AND g.return_3m  IS NOT NULL) OR
            (fm.return_6m  IS NULL AND g.return_6m  IS NOT NULL) OR
            (fm.return_7d  IS NULL AND g.return_7d  IS NOT NULL) OR
            (fm.return_15d IS NULL AND g.return_15d IS NOT NULL)
       )
     RETURNING fm.amfi_code
  )
  SELECT count(*) INTO v_updated FROM upd;
  RETURN v_updated;
END;
$$;

GRANT EXECUTE ON FUNCTION public.copy_growth_returns_to_idcw_siblings() TO service_role;
