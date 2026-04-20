-- 037_promote_fund_to_warm.sql
--
-- Called by the Flutter client (and by the fetch-fund-ondemand edge
-- function) whenever a user interacts with a cold fund: opens its
-- detail page, adds it to their portfolio, adds it to a watchlist,
-- etc. Flips the fund to tracked_tier='warm' immediately, pins it in
-- place for 30 days via tier_sticky_until, and tags the reason so
-- evaluate_fund_tracked_tier() won't demote it during the next weekly
-- sweep.
--
-- Idempotent: calling on an already-warm fund just extends the sticky
-- window. Safe to call from anon or authenticated roles (so the Flutter
-- client can call it directly without a server-side round-trip).

CREATE OR REPLACE FUNCTION public.promote_fund_to_warm(
  p_amfi_code integer,
  p_reason    text DEFAULT 'on_demand'
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existed boolean;
BEGIN
  IF p_amfi_code IS NULL THEN
    RETURN false;
  END IF;

  UPDATE fund_master
     SET tracked_tier      = 'warm',
         tier_reasons      = array_distinct(
                               coalesce(tier_reasons, '{}')
                               || ARRAY[coalesce(p_reason, 'on_demand')]
                             ),
         tier_sticky_until = greatest(
                               coalesce(tier_sticky_until, now()),
                               now() + interval '30 days'
                             ),
         tier_evaluated_at = now()
   WHERE amfi_code = p_amfi_code
     AND is_active = true;

  GET DIAGNOSTICS v_existed = ROW_COUNT;
  RETURN v_existed;
END;
$$;

-- Flutter client calls this directly, so expose to authenticated users.
GRANT EXECUTE ON FUNCTION public.promote_fund_to_warm(integer, text)
  TO authenticated, service_role;

-- Batch variant for the pre-warm background job (see migration 038 +
-- edge function). Pass up to 100 codes in one call to avoid N+1.
CREATE OR REPLACE FUNCTION public.promote_funds_to_warm(
  p_amfi_codes integer[],
  p_reason     text DEFAULT 'prewarm'
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count integer;
BEGIN
  IF p_amfi_codes IS NULL OR array_length(p_amfi_codes, 1) = 0 THEN
    RETURN 0;
  END IF;

  UPDATE fund_master
     SET tracked_tier      = 'warm',
         tier_reasons      = array_distinct(
                               coalesce(tier_reasons, '{}')
                               || ARRAY[coalesce(p_reason, 'prewarm')]
                             ),
         tier_sticky_until = greatest(
                               coalesce(tier_sticky_until, now()),
                               now() + interval '30 days'
                             ),
         tier_evaluated_at = now()
   WHERE amfi_code = ANY(p_amfi_codes)
     AND is_active = true;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.promote_funds_to_warm(integer[], text)
  TO service_role;
