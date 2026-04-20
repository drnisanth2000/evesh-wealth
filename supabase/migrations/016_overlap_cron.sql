-- 016_overlap_cron.sql
-- Schedule check-portfolio-overlap semi-monthly (1st and 15th)

-- 1st of month at 23:00 IST (17:30 UTC)
SELECT cron.schedule(
  'check-portfolio-overlap-1st',
  '30 17 1 * *',
  $$SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/check-portfolio-overlap',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  )$$
);

-- 15th of month at 23:00 IST (17:30 UTC)
SELECT cron.schedule(
  'check-portfolio-overlap-15th',
  '30 17 15 * *',
  $$SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/check-portfolio-overlap',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  )$$
);
