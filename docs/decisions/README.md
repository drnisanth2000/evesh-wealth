# Architecture Decision Records (ADRs)

This directory captures the **why** behind non-trivial choices in eVesh.
Every ADR is a self-contained record of one decision: the context, what we
chose, what we rejected, and the consequences we accept.

## Rules

1. **Immutable** — once an ADR is `Accepted`, never edit it. To change a
   decision, write a **new** ADR with `Status: Supersedes ADR-NNNN` and
   update the old ADR's status to `Status: Superseded by ADR-NNNN`.
2. **Numbered** — sequential, zero-padded (`0001`, `0002`, ...). Never reuse a number.
3. **Slugged** — filename is `NNNN-kebab-case-title.md`.
4. **Short** — target 30-80 lines. ADRs that grow longer should probably
   become an architecture doc.
5. **Use the template** — copy `TEMPLATE.md` to start a new ADR.

## When to write an ADR

- Choosing a library / framework / service over alternatives
- Deciding to *not* do something (rejected approach worth recording)
- Adopting a convention that affects multiple files
- Making a tradeoff with non-obvious consequences
- Anything where in 6 months you'd ask "why did we do it that way?"

## When NOT to write an ADR

- Routine code changes
- Bug fixes (unless the fix changes a design)
- Pure refactors that preserve behavior
- Anything fully captured by the code itself

## Index

| # | Title | Status |
|---|---|---|
| [0001](0001-supabase-free-tier-strategy.md) | Stay on Supabase Free Tier | Accepted |
| [0002](0002-tiered-warm-cold-funds.md) | Tiered Warm/Cold Fund Universe | Accepted |
| [0003](0003-no-git-direct-netlify-deploy.md) | No Git, Direct Netlify CLI Deploy | Accepted |
| [0004](0004-screener-search-fund-master-fallback.md) | Screener Search Falls Back to fund_master | Accepted |
