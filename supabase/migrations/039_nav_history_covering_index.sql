-- 032_nav_history_covering_index.sql
--
-- After bulk-loading ~6M new rows into nav_history, the existing primary
-- key alone was not sufficient for the asof-join queries in
-- refresh_short_window_returns_for_codes: the planner was picking a
-- sequential scan over 7.8M rows even when the predicate was
-- `amfi_code = ANY(...)` with a tight array, which blew through the
-- project's Disk IO Budget and caused widespread gateway timeouts.
--
-- This migration adds a DESC covering index so:
--   (a) the "latest nav per fund" subquery becomes a bounded index seek
--       (reads a single index leaf per amfi_code, not the whole table)
--   (b) the asof-match subquery reads `nav` directly from the index
--       without hitting the heap, making it an index-only scan
--
-- IMPORTANT: CREATE INDEX CONCURRENTLY cannot run inside a transaction,
-- and supabase db push wraps every migration in one. We use a plain
-- CREATE INDEX here. On a healthy instance it takes ~60-90s and briefly
-- locks writes to nav_history; reads are unaffected. Run this only AFTER
-- the Disk IO Budget alert clears — building a B-tree on 7.8M rows costs
-- ~500MB of fresh IO itself.

CREATE INDEX IF NOT EXISTS nav_history_amfi_date_desc_nav_idx
  ON public.nav_history (amfi_code, nav_date DESC)
  INCLUDE (nav);

-- Also add the stats target bump — the planner was underestimating the
-- selectivity of `amfi_code = ANY(...)` because default_statistics_target
-- gives only 100 buckets and we have ~3000 distinct amfi_codes.
ALTER TABLE public.nav_history
  ALTER COLUMN amfi_code SET STATISTICS 1000;

-- Refresh stats so the new statistics target takes effect.
ANALYZE public.nav_history;
