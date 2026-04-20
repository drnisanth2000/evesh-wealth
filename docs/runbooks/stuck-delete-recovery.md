# Runbook: Recovering from a Stuck DELETE / Connection Pool Exhaustion

**First written:** 2026-04-08 (incident during Path A migration)
**Severity:** P0 — REST API completely unreachable, app down

## Symptoms

- Supabase REST API returns HTTP 000 / connection timeout for all requests
- Flutter app shows "Failed to load funds" everywhere
- `supabase db push` fails with "Failed to create login role: Connection terminated due to connection timeout"
- Cannot run any SQL via the dashboard SQL editor (it also times out)
- No obvious error in logs because logs themselves can't be queried

## Root cause pattern

A long-running query held by the `service_role` did not terminate when the
client (curl, supabase CLI, Flutter app) disconnected. `service_role` has
**unlimited `statement_timeout`** on Supabase, so client disconnects don't
kill server-side queries. The query keeps holding a connection from the
PostgREST pool. If enough connections are stuck, the pool is exhausted and
**every** subsequent request times out.

The 2026-04-08 incident: a chunked DELETE on `nav_history` (chunk size 50k)
hung on one chunk for 15+ minutes after the orchestrating curl loop was
killed locally.

## Recovery procedure

### Step 1: Try to kill the stuck query via SQL

If you can still get *any* SQL connection (sometimes the pool has 1-2 free
slots), run:

```sql
SELECT pid, state, now() - query_start AS runtime, query
FROM pg_stat_activity
WHERE state = 'active'
  AND pid <> pg_backend_pid()
ORDER BY query_start ASC;
```

Identify the offending PID(s). Then:

```sql
SELECT pg_cancel_backend(<pid>);    -- soft cancel
SELECT pg_sleep(2);
SELECT pg_terminate_backend(<pid>); -- hard kill if cancel didn't work
```

### Step 2: If SQL is also unreachable — restart the project

When the connection pool is fully exhausted, you cannot run kill SQL because
your kill SQL also can't get a connection. **Restart the entire project:**

1. Open Supabase Dashboard → your project
2. **Settings → Infrastructure**
3. Click **Restart project**
4. Wait ~2 minutes for the restart to complete
5. The restart kills all in-flight connections, including the stuck ones
6. Verify recovery: run `SELECT 1;` in the SQL editor

### Step 3: Confirm no data loss

Long-running DELETEs that didn't commit will roll back when the connection
is killed. Verify rows are intact:

```sql
SELECT count(*) FROM <affected_table>;
-- Compare to your last known count
```

In the 2026-04-08 incident: nav_history had 7,830,227 rows before the stuck
DELETE, and 3,769,227 mid-incident. After the restart and rollback, count
returned to 7,830,227 — zero data loss because the uncommitted DELETE rolled
back cleanly.

### Step 4: Re-run the work safely

Use the **hardened cleanup pattern** that prevents recurrence:

```sql
CREATE OR REPLACE FUNCTION public.cleanup_nav_history_chunk(p_chunk int DEFAULT 25000)
RETURNS int
LANGUAGE plpgsql
SET search_path = public, pg_temp
SET statement_timeout = '20s'   -- ← critical: function self-caps even for service_role
SET lock_timeout = '5s'         -- ← critical: don't wait forever for locks
AS $$
BEGIN
  -- ... actual delete logic ...
END;
$$;
```

The `SET statement_timeout` on the function means even if a client disconnects,
the query terminates itself after 20 seconds.

## Prevention

For ANY long-running maintenance function:

1. **`SET statement_timeout`** on the function definition itself — don't rely
   on client-side timeouts or session-level settings, because `service_role`
   ignores most defaults
2. **`SET lock_timeout`** so the function fails fast if it can't get the lock
3. **Use small chunks** (25k rows max for DELETE) — bounded work per call
4. **Idempotent** — re-runnable without side effects
5. **Never put long DELETEs in migration files** — the migration runner wraps
   in `BEGIN/COMMIT` with a 2-min timeout. Use an RPC + external loop instead.

## How to find the dashboard restart button

Direct path: Supabase Dashboard → Project → **Settings** (gear icon, bottom-left)
→ **Infrastructure** → **Restart project** button (right side).

## References

- [ADR-0002: Tiered Warm/Cold Fund Universe](../decisions/0002-tiered-warm-cold-funds.md) — the migration that triggered the original incident
- `supabase/migrations/041_kill_stuck_queries.sql` — kept in the migration history as a future-use kill helper
- `supabase/migrations/042_harden_cleanup_and_rls.sql` — the hardened cleanup function with self-capped timeout
