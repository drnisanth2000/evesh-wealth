-- 029_analyze_nav_history.sql
--
-- After bulk-loading ~6M new rows into nav_history via the mfapi.in
-- backfill, autovacuum had not yet refreshed table statistics. The
-- planner was therefore picking a sequential scan over nav_history
-- even when the query had a tight (amfi_code = ANY(...)) predicate,
-- which caused refresh_short_window_returns_for_codes to time out
-- on every call. Force an immediate ANALYZE so the planner can use
-- the (amfi_code, nav_date) primary key.

ANALYZE public.nav_history;
