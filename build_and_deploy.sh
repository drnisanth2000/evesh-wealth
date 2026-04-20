#!/bin/bash
# Build Flutter web with Netlify env vars and deploy to production
set -e

# ── Git cleanliness check ────────────────────────────────────────────────────
# Warn if the working tree has uncommitted changes. The remote (github) is the
# backup of record; deploying dirty = what's live ≠ what's in git.
if git rev-parse --git-dir >/dev/null 2>&1; then
  DIRTY=$(git status --porcelain)
  UNPUSHED=$(git log @{u}..HEAD --oneline 2>/dev/null || echo "")
  if [ -n "$DIRTY" ] || [ -n "$UNPUSHED" ]; then
    echo ""
    echo "⚠️  Git working tree is not clean:"
    [ -n "$DIRTY" ] && echo "   Uncommitted changes:" && git status --short | sed 's/^/      /'
    [ -n "$UNPUSHED" ] && echo "   Unpushed commits:" && echo "$UNPUSHED" | sed 's/^/      /'
    echo ""
    read -p "Deploy anyway? The remote won't match what's live. [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Aborted. Commit + push first, then re-run ./build_and_deploy.sh"
      exit 1
    fi
  fi
fi

echo "Fetching env vars from Netlify..."
SUPABASE_URL=$(netlify env:get SUPABASE_URL 2>/dev/null)
SUPABASE_ANON_KEY=$(netlify env:get SUPABASE_ANON_KEY 2>/dev/null)
FIREBASE_API_KEY=$(netlify env:get FIREBASE_API_KEY 2>/dev/null)
FIREBASE_PROJECT_ID=$(netlify env:get FIREBASE_PROJECT_ID 2>/dev/null)
FIREBASE_MESSAGING_SENDER_ID=$(netlify env:get FIREBASE_MESSAGING_SENDER_ID 2>/dev/null)
FIREBASE_APP_ID=$(netlify env:get FIREBASE_APP_ID 2>/dev/null)
FIREBASE_VAPID_KEY=$(netlify env:get FIREBASE_VAPID_KEY 2>/dev/null)

echo "Building Flutter web..."
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=FIREBASE_API_KEY="$FIREBASE_API_KEY" \
  --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
  --dart-define=FIREBASE_APP_ID="$FIREBASE_APP_ID" \
  --dart-define=FIREBASE_VAPID_KEY="$FIREBASE_VAPID_KEY"

echo "Deploying to Netlify..."
netlify deploy --prod --dir=build/web

echo "Done!"
