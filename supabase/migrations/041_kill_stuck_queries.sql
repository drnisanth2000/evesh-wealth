-- 041_kill_stuck_queries.sql
--
-- Emergency helper: cancels any stuck cleanup_nav_history_chunk backends
-- that outlived their client connection. Safe no-op if nothing matches.

SELECT pid,
       state,
       now() - query_start AS runtime,
       pg_cancel_backend(pid) AS cancelled
  FROM pg_stat_activity
 WHERE query ILIKE '%cleanup_nav_history_chunk%'
   AND pid <> pg_backend_pid();

-- Give Postgres a second to unwind, then terminate any holdouts.
SELECT pg_sleep(2);

SELECT pid,
       state,
       now() - query_start AS runtime,
       pg_terminate_backend(pid) AS terminated
  FROM pg_stat_activity
 WHERE query ILIKE '%cleanup_nav_history_chunk%'
   AND pid <> pg_backend_pid();
