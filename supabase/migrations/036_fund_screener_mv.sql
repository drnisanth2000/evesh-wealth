-- 036_fund_screener_mv.sql
--
-- Materialized view powering the /research/screener page. Pre-sorted,
-- column-trimmed, and limited to tracked_tier='warm' (~2000 rows) so
-- the initial screener payload is ~1.5MB instead of ~25MB and ships
-- in a single round-trip.
--
-- Refreshed nightly at 02:30 IST (after the short-window returns
-- compute job finishes) via pg_cron. Refreshed CONCURRENTLY so reads
-- never block. Requires the unique index below.

CREATE MATERIALIZED VIEW IF NOT EXISTS public.fund_screener_mv AS
SELECT
  amfi_code,
  fund_name,
  amc,
  category,
  sub_category,
  fund_type,
  plan_type,
  tax_category,
  latest_nav,
  prev_nav,
  nav_date,
  aum_cr,
  expense_ratio,
  fund_rating,
  crisil_rating,
  return_7d,
  return_15d,
  return_1m,
  return_3m,
  return_6m,
  return_1y,
  return_3y,
  return_5y,
  return_inception,
  return_bench_1y,
  return_bench_3y,
  return_bench_5y,
  return_bench_10y,
  info_ratio_1y,
  info_ratio_3y,
  info_ratio_5y,
  info_ratio_10y,
  benchmark_index,
  riskometer_scheme,
  riskometer_bench,
  tracked_tier,
  tier_reasons,
  -- Pre-computed 1D change for UI (avoids client-side math)
  CASE
    WHEN prev_nav IS NOT NULL AND prev_nav > 0 AND latest_nav IS NOT NULL
    THEN ((latest_nav / prev_nav) - 1) * 100
    ELSE NULL
  END AS day_change_pct,
  -- Pre-computed sub_category rank on 1Y return (powers screener sort)
  RANK() OVER (PARTITION BY sub_category ORDER BY return_1y DESC NULLS LAST) AS rank_1y_in_subcat,
  RANK() OVER (PARTITION BY sub_category ORDER BY return_3y DESC NULLS LAST) AS rank_3y_in_subcat,
  RANK() OVER (PARTITION BY sub_category ORDER BY return_5y DESC NULLS LAST) AS rank_5y_in_subcat
FROM public.fund_master
WHERE is_active = true
  AND tracked_tier = 'warm';

-- Unique index required by REFRESH CONCURRENTLY.
CREATE UNIQUE INDEX IF NOT EXISTS fund_screener_mv_pk
  ON public.fund_screener_mv (amfi_code);

-- Common sort indexes so paginated queries don't re-sort on every call.
CREATE INDEX IF NOT EXISTS fund_screener_mv_sub_1y_idx
  ON public.fund_screener_mv (sub_category, return_1y DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS fund_screener_mv_sub_3y_idx
  ON public.fund_screener_mv (sub_category, return_3y DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS fund_screener_mv_sub_5y_idx
  ON public.fund_screener_mv (sub_category, return_5y DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS fund_screener_mv_aum_idx
  ON public.fund_screener_mv (aum_cr DESC NULLS LAST);

-- Trigram index on fund_name for typeahead search within the warm set.
CREATE INDEX IF NOT EXISTS fund_screener_mv_name_trgm
  ON public.fund_screener_mv USING gin (fund_name gin_trgm_ops);

-- Grant read access to anon + authenticated so PostgREST can serve it.
GRANT SELECT ON public.fund_screener_mv TO anon, authenticated, service_role;

-- Refresh function — callable via RPC or cron.
CREATE OR REPLACE FUNCTION public.refresh_fund_screener_mv()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.fund_screener_mv;
END;
$$;

GRANT EXECUTE ON FUNCTION public.refresh_fund_screener_mv() TO service_role;

-- Daily cron — 02:30 IST = 21:00 UTC previous day. Runs after the
-- short-window returns + AMFI refresh jobs so it sees fresh numbers.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.unschedule('refresh-fund-screener-mv');
  END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'refresh-fund-screener-mv',
      '0 21 * * *',  -- 21:00 UTC = 02:30 IST
      $cron$ SELECT public.refresh_fund_screener_mv(); $cron$
    );
  END IF;
END $$;
