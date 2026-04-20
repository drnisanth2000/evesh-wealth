-- 023_schedule_refresh_fund_performance.sql
-- Schedules the refresh-fund-performance-amfi Edge Function at 09:00 IST daily.
-- 09:00 IST = 03:30 UTC.

-- Unschedule any prior instance so this migration is re-runnable.
DO $$
BEGIN
  PERFORM cron.unschedule('refresh_fund_performance_daily');
EXCEPTION WHEN OTHERS THEN
  -- job didn't exist; ignore
  NULL;
END$$;

SELECT cron.schedule(
  'refresh_fund_performance_daily',
  '30 3 * * *',  -- 09:00 IST = 03:30 UTC every day
  $$ SELECT net.http_post(
       url := 'https://bewtjsjhdtwhrsshmigm.supabase.co/functions/v1/refresh-fund-performance-amfi',
       headers := jsonb_build_object(
         'Authorization', 'Bearer ' || current_setting('app.service_role_key', true),
         'content-type', 'application/json'
       ),
       body := '{}'::jsonb
     );$$
);
