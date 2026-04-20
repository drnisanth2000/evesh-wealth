# Fund Tiering Architecture

> **Status:** Live in production since 2026-04-08
> **Owners:** eVesh core
> **Related docs:** `DATA_AUDIT_AND_SOP.md`

---

## 1. TL;DR

eVesh tracks ~14,000 Indian mutual funds. Storing daily NAV history for all of
them blew through Supabase's 500 MB free-tier quota (peak: 912 MB / 182%). We
split the universe into a **warm tier** (~3,672 funds with daily NAV refresh,
served from a materialized view) and a **cold tier** (~10,677 funds whose NAV
history is fetched on-demand the first time a user opens them, then promoted to
warm for 30 days).

**Result:** 912 MB → **113 MB (23%)**, nav_history rows 7.83M → **295K (-96.2%)**,
zero impact on UX, all funds remain searchable by name.

---

## 2. The Problem

- Supabase free tier: hard 500 MB DB limit
- naive cleanup couldn't work because:
  - users genuinely use the long tail (thematic funds, NFOs, sectoral)
  - the screener needs *some* perf data to rank
  - blanket "delete history > N days" loses recent data on old funds
- previous design stored ~7.8M nav_history rows (97% never queried)

---

## 3. The Architecture

### Warm tier (~3,672 funds)
Daily NAV refresh via cron, full perf metrics computed nightly, served from
the `fund_screener_mv` materialized view (~1.5 MB payload, sub-second queries).

A fund is **warm** if it satisfies any of:
- Top quartile by 1Y return within its sub-category
- AUM ≥ ₹100 cr
- Passive (index / ETF / fund-of-fund tracking an index)
- "Sticky" (within 30 days of being opened by any user)
- Held by any user (in `transactions`)
- Watched by any user (in `watchlist`)
- Young + large (< 3y old AND AUM ≥ ₹500 cr) — captures NFOs that matter

Sticky window: **30 days** (`tier_sticky_until` timestamp on `fund_master`).
After 30 days of no activity, the next nightly `evaluate_fund_tracked_tier()`
run can demote it back to cold if no other rule keeps it warm.

### Cold tier (~10,677 funds)
- Row exists in `fund_master` (so it's searchable by name)
- Zero or stub-only rows in `nav_history`
- Promoted to warm on first user interaction via `fetch-fund-ondemand` edge fn
- Idle prewarm batches grow the warm universe organically (~30 funds every 60s
  while a user has the screener tab open)

---

## 4. Database Layer

### Migration index (033 → 045)

| File | Purpose |
|---|---|
| `033_fund_tracked_tier.sql` | Add `tracked_tier`, `tier_sticky_until`, `last_user_seen_at` columns to `fund_master` |
| `034_evaluate_tracked_tier.sql` | `evaluate_fund_tracked_tier()` — nightly job that recomputes warm/cold |
| `035_nav_history_archive.sql` | `nav_history_archive` table + `archive_old_nav_history()` rotation |
| `036_fund_screener_mv.sql` | `fund_screener_mv` materialized view + `refresh_fund_screener_mv()` |
| `037_promote_fund_to_warm.sql` | `promote_fund_to_warm()` + `promote_funds_to_warm()` (single + batch) |
| `038_prewarm_queue.sql` | `pick_prewarm_batch()` + `mark_prewarm_done()` for AMC round-robin |
| `039_nav_history_covering_index.sql` | `(amfi_code, nav_date DESC)` covering index — hot-path enabler |
| `040_cleanup_cold_nav_chunk.sql` | First chunked-DELETE RPC (later hardened in 042) |
| `041_kill_stuck_queries.sql` | Emergency `pg_terminate_backend` helper (kept for future) |
| `042_harden_cleanup_and_rls.sql` | **Critical recovery** — self-capped timeout on cleanup, RLS on 5 tables, fix `nav_history_all` view, pin `search_path` on 8 helpers |
| `043_cluster_nav_history.sql` | `CLUSTER` to reclaim disk after 7.5M-row DELETE |
| `044_pin_search_path_legacy_fns.sql` | Close 8 "Function Search Path Mutable" advisor warnings + revoke anon from MV |
| `045_pin_get_subscription_tier.sql` | Fix wrong signature guess in 044 |

### Key tables

- **`fund_master`** — canonical list of all funds (~14k rows). Key columns added by 033: `tracked_tier`, `tier_sticky_until`, `last_user_seen_at`
- **`nav_history`** — daily NAVs (warm funds only after migration 040). ~295k rows
- **`nav_history_archive`** — cold storage for evicted rows (added in 035)
- **`nav_history_all`** — `UNION ALL` view of both, `security_invoker` (042c)
- **`fund_screener_mv`** — pre-joined materialized view, the screener's hot path
- **`fund_perf_sync_log`** — sync run audit trail
- **`index_nav_history`** — benchmark NAVs (Nifty 50, Nifty Midcap, etc.) for alpha/beta computation

### RLS posture (set in 042b)

| Table | anon | authenticated | service_role |
|---|---|---|---|
| `fund_holdings_cache` | ✅ SELECT | ✅ SELECT | bypass |
| `amfi_category` | ✅ SELECT | ✅ SELECT | bypass |
| `index_nav_history` | ✅ SELECT | ✅ SELECT | bypass |
| `nav_history_archive` | ✅ SELECT | ✅ SELECT | bypass |
| `fund_perf_sync_log` | ❌ | ✅ SELECT | bypass |
| `fund_screener_mv` | ❌ (revoked in 044) | ✅ SELECT | bypass |

Writes to all of the above are service-role only (cron + edge functions).

### Helper functions (all pinned `search_path = public, pg_temp`)

| Function | Signature | Purpose |
|---|---|---|
| `evaluate_fund_tracked_tier()` | `()` | Nightly recompute of warm/cold |
| `promote_fund_to_warm(int, text)` | `(amfi_code, reason)` | Single-fund promotion |
| `promote_funds_to_warm(int[], text)` | `(amfi_codes, reason)` | Batch promotion |
| `pick_prewarm_batch(int, int)` | `(limit, per_amc)` | AMC round-robin selection |
| `mark_prewarm_done(int[])` | `(amfi_codes)` | Stamp completion |
| `cleanup_nav_history_chunk(int)` | `(chunk_size DEFAULT 25000)` | **Self-capped at 20s statement_timeout** — safe to call from clients that may disconnect |
| `archive_old_nav_history(int, int)` | `(older_than_days, batch)` | Move stale rows to archive |
| `refresh_fund_screener_mv()` | `()` | Rebuild the screener MV |

---

## 5. Edge Function: `fetch-fund-ondemand`

**Location:** `supabase/functions/fetch-fund-ondemand/index.ts`

### Two modes

**`single`** — promote one cold fund to warm
```json
POST /functions/v1/fetch-fund-ondemand
{ "mode": "single", "amfi_code": 152057 }
```
- Pulls 400 days of NAV history from mfapi.in
- Upserts into `nav_history`
- Calls `promote_fund_to_warm(amfi_code, 'on-demand')`
- Stamps `tier_sticky_until = now() + 30 days`
- Typical latency: ~1.8s

**`prewarm`** — idle batch backfill
```json
POST /functions/v1/fetch-fund-ondemand
{ "mode": "prewarm", "limit": 30, "per_amc": 3 }
```
- `pick_prewarm_batch()` chooses up to N funds, max `per_amc` per AMC
- Pipelines mfapi.in fetches in parallel
- Returns `{ "fetched": <count> }`
- Typical latency: ~5.6s for 30 funds

### Failure modes
- mfapi.in 5xx → individual fund skipped, others continue
- Timeout (default 90s) → returns whatever was fetched, idempotent on retry
- Edge function errors are surfaced as Riverpod errors in the Flutter layer (no silent swallows)

---

## 6. Flutter Layer

### `fundDetailProvider` (`lib/presentation/providers/fund_provider.dart:41`)
- Reads `fund_master` row by `amfi_code`
- If `tracked_tier == 'cold'`, fires fire-and-forget `fetch-fund-ondemand` (mode: single)
- Renders the basic row immediately — does NOT await promotion
- Pull-to-refresh re-runs the provider and picks up freshly-populated values
- IIFE wrapper around the invoke so try/catch is type-safe (lesson from `catchError` return-type bug)

### `navHistoryProvider` (`lib/presentation/providers/fund_provider.dart:127`)
- **Critical gotcha**: queries `nav_history` with `order DESC + limit 3650`. Ascending+limit silently dropped recent rows for old funds (e.g. Nippon Large Cap launched 2007, ~4,589 trading-day rows). Re-sorts ascending in memory.
- Backfill threshold: < 60 trading days (~3 months) → invoke `fetch-nav-batch` mode `single`
- Errors **propagate** as Riverpod errors (previous design swallowed with `catch (_)` and hid two production bugs)
- Single source of truth for daily NAV — every chart/analytics consumer reads from this provider

### `screenerResultsProvider` (`lib/presentation/providers/screener_provider.dart:24`)
- Default path: query `fund_screener_mv` (warm-only, ~1.5 MB payload)
- **Search fallback (added 2026-04-08):** if `filters.searchQuery` ≥ 2 chars, delegates to `screenerResultsAllProvider` which queries `fund_master` directly (full ~14k universe)
- Why: without the fallback, typing "HDFC Technology" returned "No funds match your filters" because that fund is cold. Confusing UX — user knows the fund exists.
- Cold-fund rows show `—` for returns until promoted; tapping a result triggers cold→warm via `fundDetailProvider`

### `fundPrewarmBatchProvider` (`lib/presentation/providers/fund_provider.dart:85`)
- Called from `screener_tab.dart:_schedulePrewarm()` ~5s after the user lands on the screener
- Re-fires every 60s while the tab is active, cancelled on tab leave
- Calls `fetch-fund-ondemand` mode `prewarm` (limit=30, per_amc=3)
- Fire-and-forget; UI never blocks on prewarm

---

## 7. Operational Notes

### How to manually promote a fund to warm
```sql
SELECT promote_fund_to_warm(152057, 'manual: testing');
```

### How to inspect tier distribution
```sql
SELECT tracked_tier, count(*)
FROM fund_master
WHERE is_active = true
GROUP BY tracked_tier;
```

### How to find what the screener is currently serving
```sql
SELECT count(*) FROM fund_screener_mv;
```

### How to kill a stuck DELETE (the 2026-04-08 incident)
```sql
SELECT pid, state, now() - query_start AS runtime
FROM pg_stat_activity
WHERE query ILIKE '%cleanup_nav_history_chunk%'
  AND pid <> pg_backend_pid();

SELECT pg_terminate_backend(<pid>);
```

**If `service_role` queries are stuck and the connection pool is exhausted**:
the API itself will be unreachable (HTTP 000). You cannot run the kill SQL.
Go to Supabase dashboard → **Settings → Infrastructure → Restart project**.
This is what happened on 2026-04-08 when a chunked DELETE hung server-side
after the client (curl) was killed. `service_role` has unlimited
`statement_timeout`, so client disconnects don't terminate server queries.

**Prevention:** migration 042 puts `SET statement_timeout = '20s'` on the
function itself, so even service-role calls self-cap. Always use this pattern
for long-running maintenance functions.

### How to deploy
```bash
export PATH="$HOME/.npm-global/bin:$PATH"
./build_and_deploy.sh
```
- The script reads env vars from `netlify env:get`, runs `flutter build web --release`,
  and deploys to Netlify production via `netlify deploy --prod --dir=build/web`
- **No git** — this project deploys directly from local builds
- Production URL: https://evesh.netlify.app

### How to deploy database migrations
```bash
supabase db push
```
**Caveat:** the migration runner wraps each file in `BEGIN/COMMIT` with a 2-min
timeout. Long DELETEs **do not** belong in migrations — use an RPC + external
loop pattern instead (see migration 040 + the chunked-cleanup workflow).

### How to deploy edge functions
```bash
supabase functions deploy fetch-fund-ondemand
```

---

## 8. Known Limitations

### Newly-promoted cold funds
After cold→warm promotion, NAV history loads instantly but **alpha/beta/tracking
error are blank** until the next nightly perf-sync cron runs. Reason: those
metrics need benchmark NAV alignment from `index_nav_history`, which the
on-demand path doesn't compute. This is acceptable — core charts and returns
work immediately, deeper analytics fill in within 24h.

### Rolling returns
Need ≥ 3 years of NAV history (3Y rolling) or ≥ 5 years (5Y rolling). New
funds (e.g. HDFC Technology Fund, launched 2022) show "Insufficient data for
rolling returns". This will populate naturally as the fund ages — no fix
required.

### Cosmetic Supabase advisor warnings (intentionally accepted)
1. **`pg_trgm` extension in public schema** — used by trigram search index,
   risky to move (would have to rebuild indexes that are critical to fund search)
2. **`fund_screener_mv` exposed in API** — required by the screener, anon
   already revoked in migration 044
3. **Leaked Password Protection** — toggle in Auth dashboard, optional

### Free-tier ceiling
We're currently at 23% of the 500 MB quota with growth headroom. If the warm
universe doubles, we'd be at ~46%. Beyond that, consider:
- Tightening warm criteria (raise AUM threshold from ₹100cr to ₹250cr)
- Reducing NAV history window from 400 days to 250 days for warm funds
- Moving to Supabase Pro ($25/mo, 8GB)

---

## 9. Results

| Metric | Before | After | Δ |
|---|---|---|---|
| DB size | 912 MB (182%) | 113 MB (23%) | **-87.6%** |
| `nav_history` rows | 7,830,227 | 295,609 | **-96.2%** |
| Warm funds | n/a (all warm) | 3,672 | — |
| Cold funds | 0 | 10,677 | — |
| Screener payload | ~25 MB | ~1.5 MB | **-94%** |
| Security advisor errors | 6 | 0 | ✅ |
| Security advisor warnings | 13 | 3 (cosmetic) | ✅ |
| Cold-fund first-open latency | n/a | ~1.8s | — |
| Warm-fund first-open latency | < 200ms | < 200ms | unchanged |

---

## 10. Change Log

### 2026-04-08 — Path A migration deployed
- Migrations 033 → 045 applied
- Edge function `fetch-fund-ondemand` deployed
- Flutter providers updated (`fundDetail`, `navHistory`, `fundPrewarmBatch`)
- DB shrunk from 912 MB → 113 MB
- **Incident:** chunked DELETE hung server-side after client disconnect, exhausted
  the REST connection pool, required project restart. Migration 042 added
  self-capped statement_timeout to prevent recurrence.
- **Provider bug fix:** `fundDetail` `unnecessary_cast` + `catchError` return-type
  errors → wrapped fire-and-forget in IIFE with try/catch

### 2026-04-08 — Screener search fallback (this commit)
- **Symptom:** typing "HDFC Technology" in screener returned "No funds match
  your filters" even though the fund exists in `fund_master`
- **Cause:** screener queried `fund_screener_mv` (warm-only), cold funds invisible
- **Fix:** `screenerResultsProvider` now delegates to `screenerResultsAllProvider`
  (queries `fund_master` directly) when `filters.searchQuery` is set
- **Files:** `lib/presentation/providers/screener_provider.dart` (8 lines added)
- **Verified:** HDFC Technology Fund now appears in screener search, tap
  navigates to detail page, cold→warm promotion fires, NAV chart loads
