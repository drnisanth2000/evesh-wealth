# eVesh Documentation

This directory is the **single source of truth** for how eVesh works, why it
was built that way, and how to operate it. Goal: minimize repeated work and
keep code quality high by capturing context while it's fresh.

## Layout

```
docs/
├── architecture/   "How does X work right now?" — living reference docs.
│                   Edit in place when the system changes.
│
├── decisions/      "Why did we choose X over Y?" — ADRs (Architecture Decision
│                   Records). Immutable. Append a new ADR to supersede an old one.
│
└── runbooks/       "When X breaks, do Y." — incident response playbooks.
                    Add a new one after every meaningful incident.
```

## When to write what

| Situation | Write this |
|---|---|
| Building a new subsystem | `architecture/<name>.md` |
| Making a non-trivial choice (pick A over B) | `decisions/NNNN-<slug>.md` (ADR) |
| Fixing a tricky bug worth remembering | Add a "Gotchas" section to the relevant `architecture/` doc |
| Recovering from a production incident | `runbooks/<incident-type>.md` |
| Routine operation (deploy, rollback, etc.) | `runbooks/<operation>.md` |

## Conventions

- **Architecture docs are editable** — update them in the same commit as the code change. Doc drift is the #1 reason these systems fail.
- **ADRs are immutable** — once accepted, never edit. To change a decision, write a new ADR with `Status: Supersedes ADR-NNNN`.
- **Runbooks are living** — update when the procedure changes.
- **One doc per concern** — prefer many small focused docs over one giant one.

## Index

### Architecture
- [Fund Tiering](architecture/fund_tiering.md) — warm/cold fund universe, on-demand promotion. *(Currently lives at `/FUND_TIERING_ARCHITECTURE.md` at the project root for visibility — will move here when convenient.)*

### Decisions (ADRs)
- [ADR-0001: Stay on Supabase Free Tier](decisions/0001-supabase-free-tier-strategy.md)
- [ADR-0002: Tiered Warm/Cold Fund Universe](decisions/0002-tiered-warm-cold-funds.md)
- [ADR-0003: No Git, Direct Netlify CLI Deploy](decisions/0003-no-git-direct-netlify-deploy.md)
- [ADR-0004: Screener Search Falls Back to fund_master](decisions/0004-screener-search-fund-master-fallback.md)

### Runbooks
- [Recovering from a Stuck DELETE](runbooks/stuck-delete-recovery.md)
