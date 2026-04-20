# ADR-0005: Adopt Git + Private GitHub Repo for Version History and Backup

**Date:** 2026-04-20
**Status:** Accepted (supersedes ADR-0003)

## Context

ADR-0003 (2026-04-08) rejected git in favour of direct Netlify CLI deploys,
citing iteration speed and solo-dev simplicity. Two weeks and many production
changes later (Security Sprint 1, Wealth Planner v2 launch, Rebalance v3),
the accepted tradeoffs have become more costly:

- The working copy is the only copy. A disk failure loses everything.
- No diff between deploys — hard to reason about what changed when a bug
  surfaces after a `build_and_deploy.sh` run.
- No rollback primitive beyond the Netlify dashboard.
- Claude/agent workflows (`code-review`, `commit-push-pr`, plan execution)
  assume a git repo and degrade without one.

The original trigger "developer accidentally loses local changes" has not
fired, but the asymmetry (high downside if it does, low cost to prevent) now
favours adoption.

## Decision

Adopt git inside `evesh_wealth/` with a private GitHub repo as the remote.
Keep the existing `build_and_deploy.sh` flow unchanged — git is for history
and backup, not for CI or deploy triggers.

**Scope:** `evesh_wealth/` only. The outer `Wealth Management App/` folder
(old prototypes, `SN_holdings.csv`, PDF blueprints, CAS reports) stays out
of version control — it mixes code, personal financial data, and archived
prototypes that should not live in a repo.

**Secrets posture:**
- `SUPABASE_ANON_KEY` is client-facing by design (RLS enforces access). It
  lives in Netlify env vars for production builds and in `.claude/launch.json`
  for local dev. The launch.json is gitignored.
- Service role keys, Firebase admin credentials, and any `.env*` files are
  gitignored explicitly.

## Alternatives Considered

- **Stay on no-git (status quo from ADR-0003)** — rejected. The backup risk
  has grown with the user base; Time Machine alone is not a sufficient
  disaster plan for a live product.
- **Netlify Git deploy (push-to-deploy)** — still rejected for the same
  reason as ADR-0003: slower than local builds, less control.
- **GitHub Actions CI** — deferred. Would add PR gates and automated
  checks, but with a solo dev today it adds friction for little gain.
  Revisit when a second contributor joins.
- **Public repo** — rejected. Contains product code, infra decisions,
  and references to internal infrastructure. Private only.

## Consequences

**Good:**
- Off-machine backup via GitHub.
- `git log` / `git diff` / `git blame` restored — Claude workflows work
  normally again.
- Branch + revert available for experiments.
- Audit trail of what shipped when.

**Bad / accepted tradeoffs:**
- Must remember to commit + push regularly, otherwise the remote drifts
  from the local state that actually deployed.
- `.gitignore` discipline required — one accidentally committed `.env`
  is a rotation event.
- `build_and_deploy.sh` still deploys uncommitted changes. A future ADR
  may add a pre-deploy `git status` check to warn on dirty state.

## Verification

```bash
cd evesh_wealth
git status                 # clean working tree or intentional changes only
git remote -v              # origin → github.com/<user>/evesh-wealth
git log --oneline -5       # recent commits visible
gh repo view --web         # repo loads, visibility = private
```

After the initial push, open the GitHub UI and confirm:
- Repo is private
- `.claude/launch.json` is NOT in the file tree
- `build/`, `.dart_tool/`, `node_modules/` are NOT in the file tree
- No Supabase anon/service keys appear in file contents

## When to revisit this decision

Trigger any of:
- A second contributor joins → add PR protection + CI checks
- A secret leaks in a commit → rotate, force-push-purge, add pre-commit
  hooks (e.g. `gitleaks`)
- Push-to-deploy becomes attractive (e.g. mobile CI builds) → migrate
  from local `build_and_deploy.sh` to Netlify Git deploy or GitHub Actions

## References

- ADR-0003 (superseded)
- `.gitignore` at `evesh_wealth/.gitignore`
- `build_and_deploy.sh` at `evesh_wealth/build_and_deploy.sh`
