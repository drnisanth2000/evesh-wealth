# ADR-0004: Screener Search Falls Back to fund_master

**Date:** 2026-04-08
**Status:** Accepted

## Context

After ADR-0002 (tiered warm/cold fund universe), the Screener tab queried
`fund_screener_mv` exclusively. The MV contains warm funds only (~3,672 of
~14,000). When a user typed the name of a cold fund (e.g. "HDFC Technology"),
the screener returned **"No funds match your filters"** even though the fund
existed in `fund_master`. This was confusing UX — the user knew the fund
existed and got a dead end.

## Decision

When the user types a search query (≥ 2 chars) in the screener, the
`screenerResultsProvider` delegates to `screenerResultsAllProvider`, which
queries `fund_master` directly (full ~14k universe). When there's no search
query, the original warm-only MV path is used.

Cold-fund rows in search results show `—` for returns columns (no perf data
yet). Tapping a cold result navigates to FundDetailScreen, which fires
`fetch-fund-ondemand` and promotes the fund to warm for 30 days.

## Alternatives Considered

- **Add cold funds to the MV with NULL perf** — rejected because the MV would
  bloat from ~3.7k to ~14k rows and the payload would 4×, defeating the
  performance win from ADR-0002.
- **"Show all funds" toggle in the UI** — rejected because users wouldn't know
  to flip it. The whole point is to make the system feel like there's only
  one universe.
- **Two separate search boxes** — rejected as confusing UX.
- **Auto-invoke prewarm when user starts typing** — rejected because it
  would create surprising network activity for every keystroke and the cold
  fund the user wants might not be in the prewarm batch.

## Consequences

**Good:**
- All ~14k funds discoverable by name from the screener
- Default browse path remains fast (warm-only MV)
- Cost is paid only when the user actually searches, and it's a single REST
  query bounded to 100 rows
- Cold-fund discovery feeds user-signal into ADR-0002's promotion rules:
  funds users actually search for get promoted by virtue of being opened

**Bad / accepted tradeoffs:**
- Cold-fund search results have `—` in returns columns until promoted
- Search performance on `fund_master` is slightly slower than the MV
  (acceptable: still < 500ms for ilike on 14k rows with the trigram index)
- Two providers maintained in parallel (`screenerResults` + `screenerResultsAll`)
  with mostly-duplicated filter logic. **Future:** factor common filter
  builder into a private helper.

## Verification

1. Hard refresh https://evesh.netlify.app (Cmd+Shift+R)
2. Go to Screener tab
3. Type "hdfc tech"
4. Expected: HDFC Technology Fund appears in results (was previously absent)
5. Tap it → FundDetailScreen opens → cold→warm promotion fires
6. NAV chart populates after ~5s + pull-to-refresh

## References

- [ADR-0002: Tiered Warm/Cold Fund Universe](0002-tiered-warm-cold-funds.md)
- `lib/presentation/providers/screener_provider.dart` — the fallback lives in `screenerResultsProvider`, lines ~24-50
- Deploy: 2026-04-08 (build ID `69d669f425e8041e913effc7`)
