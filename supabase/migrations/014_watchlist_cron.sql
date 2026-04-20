-- 014_watchlist_cron.sql
-- Schedule check-watchlist-rules and portfolio reports

-- Daily watchlist check at 22:30 IST (17:00 UTC)
SELECT cron.schedule(
  'check-watchlist-rules',
  '0 17 * * *',
  $$SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/check-watchlist-rules',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  )$$
);

-- Weekly portfolio report: Sundays 10:00 IST (04:30 UTC)
SELECT cron.schedule(
  'weekly-portfolio-report',
  '30 4 * * 0',
  $$SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/send-portfolio-report',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{"report_type": "weekly"}'::jsonb
  )$$
);

-- Monthly portfolio report: 1st of month 10:00 IST (04:30 UTC)
SELECT cron.schedule(
  'monthly-portfolio-report',
  '30 4 1 * *',
  $$SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/send-portfolio-report',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{"report_type": "monthly"}'::jsonb
  )$$
);

-- Yearly portfolio report: Jan 1 10:00 IST (04:30 UTC)
SELECT cron.schedule(
  'yearly-portfolio-report',
  '30 4 1 1 *',
  $$SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/send-portfolio-report',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{"report_type": "yearly"}'::jsonb
  )$$
);
