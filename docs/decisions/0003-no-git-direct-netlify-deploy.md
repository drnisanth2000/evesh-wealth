# ADR-0003: No Git, Direct Netlify CLI Deploy

**Date:** 2026-04-08
**Status:** Accepted

## Context

eVesh is currently a solo project. The local working copy is not under git
version control — the developer iterates fast, runs builds locally, and
deploys directly to Netlify production via the Netlify CLI from `build/web`.
A git repo + GitHub Actions pipeline was considered but deferred.

## Decision

Continue using the existing `build_and_deploy.sh` script:

```bash
#!/bin/bash
set -e
SUPABASE_URL=$(netlify env:get SUPABASE_URL)
# ... fetch other env vars from Netlify ...
flutter build web --release --dart-define=SUPABASE_URL="$SUPABASE_URL" ...
netlify deploy --prod --dir=build/web
```

Env vars come from Netlify's environment, the build runs locally, and the
output is uploaded directly. No git remote, no CI, no PR review.

## Alternatives Considered

- **Set up git + GitHub + Actions CI** — rejected for now because solo dev,
  iteration speed matters more than process, and the script works reliably.
  We will revisit when a second contributor joins.
- **Use Netlify Git deploy (push to main → auto-build)** — rejected because
  it would force git adoption and slow down hot fixes (build runs in Netlify's
  cloud which is slower than local).
- **Use Supabase CLI link to a git repo for migrations** — partially used
  (`supabase db push`) but not git-driven.

## Consequences

**Good:**
- Fastest possible iteration: edit → `./build_and_deploy.sh` → live in ~50s
- No CI flakiness, no GitHub Actions minutes, no PR overhead
- Local builds are reproducible because env vars come from a single source (Netlify)
- The script is the source of truth — no hidden CI config

**Bad / accepted tradeoffs:**
- **No version history** — cannot diff "what changed between deploys"
- **No rollback via git revert** — must manually re-deploy a previous build
  (Netlify retains old deploys but rolling back requires dashboard access)
- **No code review gate** — quality depends on the developer's discipline
- **Backups are manual** — local working copy is the only copy. **Mitigation:**
  the developer runs Time Machine + periodic Dropbox/iCloud sync of the
  project folder. (TODO: confirm with user that backups are in place.)
- **Onboarding a second dev requires git first** — would need to import to
  a fresh git repo and reconcile any uncommitted state
- When AI agents (like Claude) try to help, `git status` / `git diff` /
  `git log` all fail. Agents must use the Netlify CLI script + dashboard logs
  for any deploy-related work.

## Verification

```bash
./build_and_deploy.sh
# Expected output ends with:
# ✔ Deploy is live!
# Production URL: https://evesh.netlify.app
```

Then visually verify https://evesh.netlify.app loads the latest build (hard
refresh with Cmd+Shift+R to bypass PWA cache).

## When to revisit this decision

Trigger any of:
- Second contributor joins the project
- A deploy regression takes > 30 min to recover from
- The developer accidentally loses local changes to the working copy

At that point, write ADR-NNNN proposing git adoption.

## References

- `build_and_deploy.sh` at project root
- Netlify project: `evesh` (Project ID: `ee416343-fe7d-4775-a5a2-4e3d4e1e50bd`)
