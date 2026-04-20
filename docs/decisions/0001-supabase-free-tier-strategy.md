# ADR-0001: Stay on Supabase Free Tier

**Date:** 2026-04-08
**Status:** Accepted

## Context

eVesh is pre-revenue and bootstrapped. Supabase free tier provides 500 MB DB,
unlimited API requests, 50K monthly active users, and edge functions. We hit
912 MB (182% of quota) by storing daily NAV history for ~14k mutual funds.
Two paths: (a) upgrade to Pro ($25/mo, 8 GB), or (b) engineer within the
free-tier constraint.

## Decision

Stay on free tier and engineer the data layer to fit within 500 MB. Treat
the quota as a forcing function for good design — most of the 7.8M NAV rows
were never queried, so we had a real bloat problem regardless of the quota.

## Alternatives Considered

- **Upgrade to Supabase Pro ($25/mo)** — rejected because pre-revenue, and
  upgrading would have masked the underlying inefficiency. The shrink work
  improves query latency and screener payload size regardless of tier.
- **Self-host Postgres on a VPS** — rejected because we lose Supabase's auth,
  RLS, edge functions, and cron, which are core to the app architecture.
- **Move NAV history to a separate cheap store (S3/Parquet)** — rejected as
  premature; the warm/cold split is simpler and didn't require new infra.

## Consequences

**Good:**
- $0/mo infrastructure cost
- Forced us to design a tiered fund universe (ADR-0002), which is independently
  better engineering: smaller payloads, faster screener, less wasted IO
- Operational discipline: every new feature gets a "what does this cost in MB?" check

**Bad / accepted tradeoffs:**
- Hard ceiling at 500 MB — at current 113 MB we have ~4× headroom, but if the
  warm universe doubles we'll need to revisit
- Can't blindly cache data — every storage decision needs justification
- Single project, no read replicas or PITR backups beyond free-tier window

## Verification

```sql
SELECT pg_size_pretty(pg_database_size(current_database()));
-- Expected: < 500 MB
```

Currently: **113 MB / 500 MB (23%)** as of 2026-04-08.

## References

- [ADR-0002: Tiered Warm/Cold Fund Universe](0002-tiered-warm-cold-funds.md)
- [FUND_TIERING_ARCHITECTURE.md](../../FUND_TIERING_ARCHITECTURE.md)
