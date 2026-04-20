# Runbook: Secrets Inventory & Rotation

**Last updated:** 2026-04-20

This runbook lists every secret eVesh depends on, where it lives, whether
it's sensitive, and how to rotate it. Keep this current whenever a secret
moves or a new one is added.

## Inventory

| Secret | Sensitivity | Where it lives | How it's consumed |
|---|---|---|---|
| `SUPABASE_URL` | Public | Netlify env → `build_and_deploy.sh` → `--dart-define` | Flutter web runtime |
| `SUPABASE_ANON_KEY` | Low (anon role, RLS-protected — safe to expose but rotate if abused) | Netlify env → `build_and_deploy.sh` → `--dart-define` | Flutter web runtime |
| `FIREBASE_API_KEY` + app/project/sender IDs + VAPID | Low (Firebase Web API keys are domain-restricted — safe to expose) | Netlify env → `build_and_deploy.sh` → `--dart-define` | FCM push notifications |
| **`SUPABASE_ACCESS_TOKEN`** | **HIGH** (project-management scope — can modify DB, deploy functions, read all data) | `~/.zshenv` as `export SUPABASE_ACCESS_TOKEN=...` | Supabase CLI (`supabase db push`, `supabase functions deploy`) |
| `SERVICE_ROLE_KEY` | CRITICAL (bypasses RLS) | Supabase dashboard → stored in Postgres session config `app.settings.service_role_key` | Edge functions only, via `current_setting()` |
| Netlify auth token | Medium | `~/.netlify/config.json` (Netlify CLI manages this) | `netlify` CLI |

## What's NOT in version control

`.gitignore` explicitly excludes:
- `.env`, `.env.*` (any dotfile env)
- `.claude/launch.json` (has dev Supabase anon key + local paths)
- `.netlify/` (has `state.json` with siteId — public, but gitignored anyway)
- `firebase-adminsdk*.json`, `google-services.json`, `GoogleService-Info.plist`
- `supabase/.temp/`, `supabase/.env`
- `*.pem`, `*.key`, `secrets.json`

Verify at any time with:

```bash
git ls-files | grep -Ei '(env|secret|key|token|adminsdk)'
```

Expected output: empty.

## Rotation procedures

### SUPABASE_ACCESS_TOKEN (personal access token)

Highest priority if leaked — this token can drop tables and deploy code.

1. Go to https://supabase.com/dashboard/account/tokens
2. Revoke the current token
3. Click **Generate new token** → name it (e.g. `evesh-cli-YYYYMMDD`) → copy
4. Update your shell env in your terminal (replace with the new token):

   ```bash
   echo "export SUPABASE_ACCESS_TOKEN=\"PASTE_NEW_TOKEN\"" > ~/.zshenv
   source ~/.zshenv
   ```

5. Verify a fresh shell picks it up:

   ```bash
   zsh -c 'echo ${SUPABASE_ACCESS_TOKEN:0:10}'
   ```

   Expected: `sbp_` + 6 hex chars.

6. Test the CLI still works:

   ```bash
   cd evesh_wealth
   supabase projects list
   ```

   Should list the `evesh` project (ref `bewtjsjhdtwhrsshmigm`).

### SUPABASE_ANON_KEY (if compromised)

1. Supabase dashboard → Project → Settings → API → **Reset anon key**
2. Copy the new key
3. Netlify dashboard → Site settings → Environment variables → update `SUPABASE_ANON_KEY`
4. Run `./build_and_deploy.sh` — it pulls from Netlify env and rebuilds
5. Verify the live site still loads after deploy (the old anon key will stop working immediately when reset)

### SERVICE_ROLE_KEY (if compromised — highest blast radius)

This is a disaster scenario. The service role key bypasses RLS, so anyone
holding it has read/write access to all user data.

1. Supabase dashboard → Project → Settings → API → **Reset service_role key**
2. Update the Postgres session setting `app.settings.service_role_key` to the
   new value. Current path: Supabase SQL Editor, run
   `ALTER DATABASE postgres SET app.settings.service_role_key = 'NEW_KEY';`
3. Redeploy all edge functions that use it (they read it via
   `current_setting('app.settings.service_role_key')` at request time, so a
   function restart picks up the new value).
4. Audit access logs for anomalous queries between suspected leak and rotation.

### FIREBASE_API_KEY

Firebase web keys are designed to be public, but if you want to rotate:

1. Firebase Console → Project settings → Your apps → Web app → regenerate
2. Update Netlify env var `FIREBASE_API_KEY`
3. `./build_and_deploy.sh`

## Principles

- **Never commit a real secret**, even to a private repo. A private repo today
  can become a public one tomorrow; secrets in git history are expensive to
  purge. Use Netlify env vars (production) and `~/.zshenv` (local dev) only.
- **Don't paste tokens into Claude/AI chats** — they end up in transcripts
  that may be retained. If a secret was pasted accidentally, rotate it.
- **Prefer env vars over inline tokens in scripts**. `supabase` CLI reads
  `SUPABASE_ACCESS_TOKEN` from the environment automatically; no need for
  inline `SUPABASE_ACCESS_TOKEN=sbp_... supabase ...` prefixes.
- **Review this runbook quarterly** — new secrets added? Old ones removed?
  Update the table above.

## References

- [ADR-0005](../decisions/0005-adopt-git-github-backup.md) — git adoption and
  secret-handling posture
- [`.gitignore`](../../.gitignore) — authoritative list of excluded patterns
- [`build_and_deploy.sh`](../../build_and_deploy.sh) — how secrets flow from
  Netlify env into the Flutter build
