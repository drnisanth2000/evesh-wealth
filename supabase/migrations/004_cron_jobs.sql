-- ═══════════════════════════════════════════════════════════════════════════════
-- eVesh Wealth Management — Scheduled Jobs (pg_cron)
-- Migration: 004_cron_jobs.sql
-- ═══════════════════════════════════════════════════════════════════════════════
-- NOTE: Run this AFTER deploying Edge Functions.
-- Replace YOUR_PROJECT_REF with your actual Supabase project ref.
-- Replace YOUR_SERVICE_ROLE_KEY with the service_role key (store in Vault).
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Daily NAV refresh at 22:00 IST (16:30 UTC) weekdays
--    Fetches AMFI NAVAll.txt and updates fund_master.latest_nav
-- ─────────────────────────────────────────────────────────────────────────────
SELECT cron.schedule(
  'evesh-nav-refresh',
  '30 16 * * 1-5',
  $$
    SELECT net.http_post(
      url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/fetch-nav-batch',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
      body := '{}'::jsonb
    );
  $$
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Daily alert check at 19:00 IST (13:30 UTC) weekdays
--    Checks NAV drops, price targets, SIP reminders, LTCG harvest, maturity alerts
-- ─────────────────────────────────────────────────────────────────────────────
SELECT cron.schedule(
  'evesh-send-alerts',
  '30 13 * * 1-5',
  $$
    SELECT net.http_post(
      url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-alert-email',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
      body := '{}'::jsonb
    );
  $$
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Quarterly fund metadata refresh (1 Jan, 1 Apr, 1 Jul, 1 Oct at 09:00 IST)
--    Refreshes expense ratios, fund manager names from mf.captnemo.in
-- ─────────────────────────────────────────────────────────────────────────────
SELECT cron.schedule(
  'evesh-quarterly-metadata',
  '30 3 1 1,4,7,10 *',
  $$
    SELECT net.http_post(
      url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/refresh-fund-metadata',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
      body := '{}'::jsonb
    );
  $$
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Clean up old read alerts (daily at 02:00 UTC)
--    Removes alerts older than 90 days that have been read
-- ─────────────────────────────────────────────────────────────────────────────
SELECT cron.schedule(
  'evesh-cleanup-alerts',
  '0 2 * * *',
  $$
    DELETE FROM alert_log
    WHERE is_read = TRUE
    AND created_at < NOW() - INTERVAL '90 days';
  $$
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Weekly NAV history update for held funds (Sundays 06:00 IST = 00:30 UTC)
--    Fetches full historical NAV for all funds with recent transactions
-- ─────────────────────────────────────────────────────────────────────────────
SELECT cron.schedule(
  'evesh-nav-history-refresh',
  '30 0 * * 0',
  $$
    SELECT net.http_post(
      url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/fetch-nav-batch',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
      body := '{"mode": "history"}'::jsonb
    );
  $$
);
