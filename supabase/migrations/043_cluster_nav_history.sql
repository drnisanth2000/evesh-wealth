-- 043_cluster_nav_history.sql
--
-- Rewrite nav_history physically to reclaim disk space after the
-- 7.54M-row cleanup in migration 042. VACUUM FULL would also work
-- but can't run inside a transaction (and Supabase migration runner
-- always wraps in BEGIN/COMMIT). CLUSTER can.
--
-- The chosen index is the covering index from migration 039 which
-- sorts (amfi_code, nav_date DESC) — the exact order the asof-join
-- query walks. So we get two wins in one shot:
--   (a) disk reclaim from the DELETE bloat (~96% of the rows are gone)
--   (b) physical locality for the hot-path query
--
-- Takes an AccessExclusiveLock on nav_history for the duration.
-- With only ~294k rows left this finishes in well under 10 seconds.

SET statement_timeout = '120s';
SET lock_timeout = '30s';

CLUSTER public.nav_history USING nav_history_amfi_date_desc_nav_idx;

-- After CLUSTER, planner stats need refreshing.
ANALYZE public.nav_history;
