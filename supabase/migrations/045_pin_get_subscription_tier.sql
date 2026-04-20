-- 045_pin_get_subscription_tier.sql
--
-- Follow-up to 044: the guessed `get_subscription_tier(uuid)` signature
-- doesn't exist — the real function takes no args. Pin search_path on it.

ALTER FUNCTION public.get_subscription_tier() SET search_path = public, pg_temp;
