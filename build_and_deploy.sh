#!/bin/bash
# Build Flutter web with Netlify env vars and deploy to production
set -e

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
