# ADR-0002: Tiered Warm/Cold Fund Universe

**Date:** 2026-04-08
**Status:** Accepted

## Context

eVesh tracks ~14,000 Indian mutual funds. Storing daily NAV history for all of
them generated 7.8M `nav_history` rows and pushed the database to 912 MB
(182% of free-tier quota — see ADR-0001). Telemetry showed ~97% of those rows
were never queried: users overwhelmingly look at large/popular funds plus a
small long-tail of held positions and watchlist items.

## Decision

Split the fund universe into two tiers:

- **Warm (~3,672 funds):** daily NAV refresh, full perf metrics, served from
  the `fund_screener_mv` materialized view
- **Cold (~10,677 funds):** row exists in `fund_master` (still searchable by
  name), zero or stub-only NAV history, promoted to warm on first user open
  via the `fetch-fund-ondemand` edge function

A fund is warm if it satisfies any of:
top quartile 1Y return, AUM ≥ ₹100cr, passive (index/ETF), within 30 days of
last user open ("sticky"), held by any user, watched by any user, or young+large
(< 3y old AND AUM ≥ ₹500cr).

## Alternatives Considered

- **Time-based pruning ("delete NAV > 400 days old for everyone")** — rejected
  because it loses recent data on old funds while keeping ancient data on
  inactive ones. Doesn't match access patterns.
- **AUM-only threshold ("only keep funds > ₹500cr AUM")** — rejected because
  it kills NFOs (new fund offers) and thematic funds that some users care about.
- **All-cold (fetch everything on demand)** — rejected because the screener
  needs *some* perf data to rank funds, and on-demand fetches would make the
  default screener experience slow.
- **Move to Supabase Pro and skip the work** — see ADR-0001.

## Consequences

**Good:**
- DB shrunk from 912 MB → 113 MB (-87.6%)
- Screener payload shrunk from ~25 MB → ~1.5 MB (-94%)
- Screener queries are sub-second instead of multi-second
- Cold funds remain *discoverable* by name (ADR-0004) and *promoteable* on
  demand — users never hit a dead end
- Sticky window means a fund opened once stays warm for 30 days, so repeat
  visits are always fast

**Bad / accepted tradeoffs:**
- First open of a cold fund takes ~1.8s (mfapi.in fetch + insert + promote)
  vs. < 200ms for a warm fund
- Newly-promoted cold funds have a 24h gap before alpha/beta/tracking error
  populate (those need the nightly perf-sync cron with benchmark alignment)
- Adds operational complexity: edge function, idle prewarm, sticky timestamps,
  evaluate_fund_tracked_tier cron
- New funds < 3 years old that aren't in any user's portfolio show up cold
  even if they're trending — we accept this; trending funds get pulled in by
  the user-action signals quickly

## Verification

```sql
SELECT tracked_tier, count(*)
FROM fund_master
WHERE is_active = true
GROUP BY tracked_tier;
-- Expected: warm ~3,672, cold ~10,677
```

```sql
SELECT count(*) FROM nav_history;
-- Expected: ~295k (down from 7.83M)
```

End-to-end smoke test:
1. Open https://evesh.netlify.app/#/portfolio/152057 (HDFC Technology Fund, cold)
2. Page renders instantly with basic row
3. After ~5s, pull-to-refresh
4. NAV chart populates with ~3 years of history
5. Fund is now warm for 30 days

## References

- [ADR-0001: Stay on Supabase Free Tier](0001-supabase-free-tier-strategy.md)
- [ADR-0004: Screener Search Falls Back to fund_master](0004-screener-search-fund-master-fallback.md)
- [FUND_TIERING_ARCHITECTURE.md](../../FUND_TIERING_ARCHITECTURE.md) (full architecture reference)
- Migrations: 033-045 in `supabase/migrations/`
- Edge function: `supabase/functions/fetch-fund-ondemand/`
