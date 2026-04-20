-- 030_run_short_window_refresh_now.sql
--
-- One-shot migration: re-runs the short-window returns refresh over the
-- entire universe in pure SQL, bypassing PostgREST's 8s statement timeout
-- and prepared-statement plan cache (which was poisoning the per-batch
-- RPC calls after the bulk nav_history backfill).
--
-- This loops over fund_master.amfi_code in 100-fund batches, calls the
-- existing refresh_short_window_returns_for_codes function for each
-- batch, and accumulates the count. Migration runs via supabase db push
-- which goes straight to Postgres (no PostgREST), so the only timeout
-- that applies is statement_timeout for the migration role, which is
-- effectively unlimited.

SET statement_timeout = 0;
SET lock_timeout = 0;

DO $$
DECLARE
  v_codes integer[];
  v_total bigint := 0;
  v_batch bigint;
  v_off int := 0;
  v_size int := 100;
BEGIN
  LOOP
    SELECT array_agg(amfi_code ORDER BY amfi_code)
      INTO v_codes
      FROM (
        SELECT amfi_code
          FROM fund_master
         WHERE is_active = true
         ORDER BY amfi_code
         OFFSET v_off
         LIMIT v_size
      ) s;

    EXIT WHEN v_codes IS NULL OR array_length(v_codes, 1) = 0;

    v_batch := public.refresh_short_window_returns_for_codes(v_codes);
    v_total := v_total + v_batch;
    v_off := v_off + v_size;

    IF v_off % 1000 = 0 THEN
      RAISE NOTICE 'offset=% total_updated=%', v_off, v_total;
    END IF;
  END LOOP;

  RAISE NOTICE 'FINAL total_updated=%', v_total;
END $$;

-- Re-propagate to IDCW siblings now that Growth-side data is fresh.
SELECT public.copy_growth_returns_to_idcw_siblings();
