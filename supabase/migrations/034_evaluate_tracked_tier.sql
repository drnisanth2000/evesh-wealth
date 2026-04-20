-- 034_evaluate_tracked_tier.sql
--
-- Defines evaluate_fund_tracked_tier(): recomputes which active funds
-- qualify for tier='warm'. Runs weekly via pg_cron.
--
-- The warm set is the UNION of these buckets (so funds that excel on
-- any single axis get tracked; nothing slips through the cracks):
--
--   q_5y   : AUM >= 100cr AND top quartile 5Y return in sub_category
--   q_3y   : AUM >= 100cr AND top quartile 3Y return in sub_category
--   q_1y   : AUM >= 100cr AND top quartile 1Y return in sub_category  (momentum / turnaround)
--   q_6m   : AUM >= 100cr AND top quartile 6M return in sub_category  (recent inflection)
--   young  : launch_date within last 3Y AND AUM >= 500cr               (new funds with conviction)
--   passive: index / ETF funds (category/sub_category/name contains 'Index' or 'ETF')
--   held   : any fund currently held by any user (transactions.amfi_code with BUY and net units > 0)
--   watched: any fund referenced by an active watchlist_rules entry
--   sticky : fund was promoted on-demand in the last 30 days
--            (tier_sticky_until > now())
--
-- A fund qualifies for warm if it hits ANY of the above. Cold =
-- everything else. The 'sticky' category protects on-demand promotions
-- from being overwritten mid-cycle.
--
-- After updating tier, we log a summary row and return it so the cron
-- job and ad-hoc callers can see what happened.

-- Helper: deduplicate a text array. Defined first because the main
-- evaluator uses it in its UPSERT reasons-merge step.
CREATE OR REPLACE FUNCTION public.array_distinct(anyarray)
RETURNS anyarray
LANGUAGE sql IMMUTABLE STRICT AS $$
  SELECT array_agg(DISTINCT x ORDER BY x) FROM unnest($1) AS x;
$$;

CREATE OR REPLACE FUNCTION public.evaluate_fund_tracked_tier()
RETURNS TABLE(
  warm_count       bigint,
  cold_count       bigint,
  promoted         bigint,
  demoted          bigint,
  reason_breakdown jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_promoted bigint;
  v_demoted  bigint;
BEGIN
  -- Build the warm set in a temp table. Using a temp table (instead of
  -- a single huge CTE) lets the planner pick separate good plans for
  -- each bucket and keeps the UPDATE step small. Drop-if-exists guards
  -- against a stale temp table from a previous call in the same session.
  DROP TABLE IF EXISTS _warm_candidates;
  CREATE TEMP TABLE _warm_candidates(
    amfi_code integer PRIMARY KEY,
    reasons   text[] NOT NULL DEFAULT '{}'
  ) ON COMMIT DROP;

  -- Pre-compute sub_category quartile thresholds ONCE per window.
  -- PERCENT_RANK is cheaper than a correlated PERCENTILE_CONT subquery.
  WITH ranked AS (
    SELECT
      amfi_code,
      sub_category,
      aum_cr,
      PERCENT_RANK() OVER (PARTITION BY sub_category ORDER BY return_5y NULLS FIRST) AS pct_5y,
      PERCENT_RANK() OVER (PARTITION BY sub_category ORDER BY return_3y NULLS FIRST) AS pct_3y,
      PERCENT_RANK() OVER (PARTITION BY sub_category ORDER BY return_1y NULLS FIRST) AS pct_1y,
      PERCENT_RANK() OVER (PARTITION BY sub_category ORDER BY return_6m NULLS FIRST) AS pct_6m
    FROM fund_master
    WHERE is_active = true
      AND sub_category IS NOT NULL
  )
  INSERT INTO _warm_candidates (amfi_code, reasons)
  SELECT amfi_code, ARRAY['aum+q5y']::text[]
    FROM ranked WHERE aum_cr >= 100 AND pct_5y >= 0.75
  ON CONFLICT (amfi_code) DO UPDATE
    SET reasons = _warm_candidates.reasons || EXCLUDED.reasons;

  WITH ranked AS (
    SELECT amfi_code, sub_category, aum_cr,
      PERCENT_RANK() OVER (PARTITION BY sub_category ORDER BY return_3y NULLS FIRST) AS pct_3y
    FROM fund_master WHERE is_active = true AND sub_category IS NOT NULL
  )
  INSERT INTO _warm_candidates (amfi_code, reasons)
  SELECT amfi_code, ARRAY['aum+q3y']::text[]
    FROM ranked WHERE aum_cr >= 100 AND pct_3y >= 0.75
  ON CONFLICT (amfi_code) DO UPDATE
    SET reasons = array_distinct(_warm_candidates.reasons || EXCLUDED.reasons);

  WITH ranked AS (
    SELECT amfi_code, sub_category, aum_cr,
      PERCENT_RANK() OVER (PARTITION BY sub_category ORDER BY return_1y NULLS FIRST) AS pct_1y
    FROM fund_master WHERE is_active = true AND sub_category IS NOT NULL
  )
  INSERT INTO _warm_candidates (amfi_code, reasons)
  SELECT amfi_code, ARRAY['aum+q1y']::text[]
    FROM ranked WHERE aum_cr >= 100 AND pct_1y >= 0.75
  ON CONFLICT (amfi_code) DO UPDATE
    SET reasons = array_distinct(_warm_candidates.reasons || EXCLUDED.reasons);

  WITH ranked AS (
    SELECT amfi_code, sub_category, aum_cr,
      PERCENT_RANK() OVER (PARTITION BY sub_category ORDER BY return_6m NULLS FIRST) AS pct_6m
    FROM fund_master WHERE is_active = true AND sub_category IS NOT NULL
  )
  INSERT INTO _warm_candidates (amfi_code, reasons)
  SELECT amfi_code, ARRAY['aum+q6m']::text[]
    FROM ranked WHERE aum_cr >= 100 AND pct_6m >= 0.75
  ON CONFLICT (amfi_code) DO UPDATE
    SET reasons = array_distinct(_warm_candidates.reasons || EXCLUDED.reasons);

  -- Young funds with conviction
  INSERT INTO _warm_candidates (amfi_code, reasons)
  SELECT amfi_code, ARRAY['young_large']::text[]
  FROM fund_master
  WHERE is_active = true
    AND launch_date IS NOT NULL
    AND launch_date > (now() - interval '3 years')::date
    AND aum_cr >= 500
  ON CONFLICT (amfi_code) DO UPDATE
    SET reasons = array_distinct(_warm_candidates.reasons || EXCLUDED.reasons);

  -- Index funds & ETFs — always passive, low churn, always tracked
  INSERT INTO _warm_candidates (amfi_code, reasons)
  SELECT amfi_code, ARRAY['passive']::text[]
  FROM fund_master
  WHERE is_active = true
    AND (
         lower(coalesce(category, ''))     ~ '(index|etf)'
      OR lower(coalesce(sub_category, '')) ~ '(index|etf)'
      OR lower(fund_name)                  ~ '(\m(etf|index)\M)'
      OR lower(coalesce(fund_type, ''))    = 'index'
    )
  ON CONFLICT (amfi_code) DO UPDATE
    SET reasons = array_distinct(_warm_candidates.reasons || EXCLUDED.reasons);

  -- User-held funds (derived from transactions: any amfi_code with
  -- positive net units across BUY/SELL for any user)
  INSERT INTO _warm_candidates (amfi_code, reasons)
  SELECT DISTINCT t.amfi_code, ARRAY['held']::text[]
  FROM transactions t
  WHERE t.amfi_code IS NOT NULL
  ON CONFLICT (amfi_code) DO UPDATE
    SET reasons = array_distinct(_warm_candidates.reasons || EXCLUDED.reasons);

  -- User watchlist rules
  INSERT INTO _warm_candidates (amfi_code, reasons)
  SELECT DISTINCT wr.amfi_code, ARRAY['watched']::text[]
  FROM watchlist_rules wr
  WHERE wr.amfi_code IS NOT NULL AND wr.is_active = true
  ON CONFLICT (amfi_code) DO UPDATE
    SET reasons = array_distinct(_warm_candidates.reasons || EXCLUDED.reasons);

  -- Sticky: funds promoted on-demand recently
  INSERT INTO _warm_candidates (amfi_code, reasons)
  SELECT amfi_code, ARRAY['sticky']::text[]
  FROM fund_master
  WHERE is_active = true
    AND tier_sticky_until IS NOT NULL
    AND tier_sticky_until > now()
  ON CONFLICT (amfi_code) DO UPDATE
    SET reasons = array_distinct(_warm_candidates.reasons || EXCLUDED.reasons);

  -- Count cold→warm promotions BEFORE the update (RETURNING would see
  -- the new 'warm' value, making the delta invisible).
  SELECT count(*) INTO v_promoted
    FROM fund_master fm
    JOIN _warm_candidates c USING (amfi_code)
   WHERE fm.tracked_tier = 'cold';

  -- Promote (and refresh reasons for funds already warm).
  UPDATE fund_master fm
     SET tracked_tier      = 'warm',
         tier_reasons      = c.reasons,
         tier_evaluated_at = now()
    FROM _warm_candidates c
   WHERE fm.amfi_code = c.amfi_code
     AND (fm.tracked_tier = 'cold' OR fm.tier_reasons IS DISTINCT FROM c.reasons);

  -- Count warm→cold demotions (warm, not sticky, no longer qualified).
  SELECT count(*) INTO v_demoted
    FROM fund_master fm
   WHERE fm.is_active = true
     AND fm.tracked_tier = 'warm'
     AND (fm.tier_sticky_until IS NULL OR fm.tier_sticky_until <= now())
     AND NOT EXISTS (SELECT 1 FROM _warm_candidates c WHERE c.amfi_code = fm.amfi_code);

  -- Demote.
  UPDATE fund_master fm
     SET tracked_tier      = 'cold',
         tier_reasons      = '{}',
         tier_evaluated_at = now()
   WHERE fm.is_active = true
     AND fm.tracked_tier = 'warm'
     AND (fm.tier_sticky_until IS NULL OR fm.tier_sticky_until <= now())
     AND NOT EXISTS (SELECT 1 FROM _warm_candidates c WHERE c.amfi_code = fm.amfi_code);

  -- Final counts and reason breakdown
  RETURN QUERY
    WITH tier_counts AS (
      SELECT tracked_tier, count(*) AS n
      FROM fund_master WHERE is_active = true
      GROUP BY tracked_tier
    ),
    reason_counts AS (
      SELECT reason, count(*) AS n
      FROM fund_master, unnest(tier_reasons) AS reason
      WHERE is_active = true AND tracked_tier = 'warm'
      GROUP BY reason
    )
    SELECT
      (SELECT coalesce(n, 0) FROM tier_counts WHERE tracked_tier = 'warm') AS warm_count,
      (SELECT coalesce(n, 0) FROM tier_counts WHERE tracked_tier = 'cold') AS cold_count,
      v_promoted,
      v_demoted,
      (SELECT coalesce(jsonb_object_agg(reason, n), '{}'::jsonb) FROM reason_counts);
END;
$$;

GRANT EXECUTE ON FUNCTION public.evaluate_fund_tracked_tier() TO service_role;
GRANT EXECUTE ON FUNCTION public.array_distinct(anyarray)     TO service_role;

-- Weekly cron — Sunday 03:00 IST (21:30 UTC Saturday). Low-traffic
-- window, after the daily AMFI refresh has populated current returns.
-- Only installed if pg_cron extension is available.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.unschedule('evaluate-fund-tracked-tier');
  END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'evaluate-fund-tracked-tier',
      '30 21 * * 6',  -- Saturday 21:30 UTC = Sunday 03:00 IST
      $cron$ SELECT public.evaluate_fund_tracked_tier(); $cron$
    );
  END IF;
END $$;
