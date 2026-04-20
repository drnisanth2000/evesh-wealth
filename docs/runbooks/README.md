# Runbooks

Step-by-step playbooks for incidents and routine operations. Each runbook
should be readable under stress — clear steps, exact commands, no fluff.

## Index

### Incident response
- [Recovering from a Stuck DELETE / Connection Pool Exhaustion](stuck-delete-recovery.md)

### Routine operations
- [Secrets Inventory & Rotation](secrets-and-rotation.md) — where every secret lives and how to rotate it

### To be written
- `deploy-rollback.md` — rolling back a bad Netlify deploy
- `supabase-quota-emergency.md` — what to do when DB hits 90% of quota
- `edge-function-debugging.md` — how to read logs and debug a failing edge function
- `auth-locked-out.md` — recovering a user who can't log in

## Conventions

- **Symptoms first** — start with what the operator will see, so they can
  match their situation to the right runbook fast
- **Numbered steps** — explicit, no skipping
- **Exact commands** — copy-pasteable, no placeholders unless clearly marked
- **Verification step** — how do you know it worked?
- **Prevention section** — what changed (or should change) to prevent recurrence
