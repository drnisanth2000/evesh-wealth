-- 021_schedule_refresh_index_nav.sql
-- Cron-schedules the refresh-index-nav Edge Function for weekday market close.

SELECT cron.schedule(
  'refresh_index_nav_daily',
  '30 19 * * 1-5',  -- 19:30 IST weekdays
  $$ SELECT net.http_post(
       url := 'https://bewtjsjhdtwhrsshmigm.supabase.co/functions/v1/refresh-index-nav',
       headers := jsonb_build_object(
         'Authorization', 'Bearer ' || current_setting('app.service_role_key', true),
         'content-type', 'application/json'
       ),
       body := '{}'::jsonb
     );$$
);
