# Architecture Docs

Living reference docs for each major subsystem in eVesh. Edit these in place
when the system changes — the goal is that any one of them can be read
standalone to rebuild context for that subsystem.

## Index

- **Fund Tiering** → currently lives at [`/FUND_TIERING_ARCHITECTURE.md`](../../FUND_TIERING_ARCHITECTURE.md) at the project root for visibility. Will be moved here when convenient.

## To be written

- `cams_parser.md` — CAMS CAS PDF → transaction extraction pipeline
- `portfolio_reconciliation.md` — how holdings are computed from transactions
- `auth_and_rls.md` — Supabase auth setup, family/member model, RLS policies
- `analytics.md` — XIRR, rolling returns, alpha/beta computation
- `watchlist_and_alerts.md` — watchlist rules, edge function alerting

Each new subsystem we touch should get a doc here on the way out.
