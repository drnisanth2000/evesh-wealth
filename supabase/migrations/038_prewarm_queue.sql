-- 038_prewarm_queue.sql
--
-- Infrastructure for background pre-warming of cold funds. The Flutter
-- client periodically asks the server "give me N cold fund codes that
-- haven't been refreshed recently" during idle time, fetches their NAV
-- history via mfapi.in, and upserts into nav_history. This fills in
-- coverage gracefully without blowing through the Disk IO budget.
--
-- We pick cold funds round-robin by AMC so one fund house doesn't
-- monopolise the prewarm slots, and we prioritize:
--   1. Funds a user has just interacted with but whose history isn't
--      yet populated (urgent)
--   2. Large AMCs (more likely to have popular funds)
--   3. Least-recently-prewarmed (fairness)

ALTER TABLE public.fund_master
  ADD COLUMN IF NOT EXISTS prewarm_last_at timestamptz,
  ADD COLUMN IF NOT EXISTS prewarm_priority smallint NOT NULL DEFAULT 0;
  -- prewarm_priority: 0 = normal, higher = picked first. Set to 10 when
  -- a user promotes the fund on-demand (so their history fill wins).

CREATE INDEX IF NOT EXISTS fund_master_prewarm_idx
  ON public.fund_master (prewarm_priority DESC, prewarm_last_at NULLS FIRST)
  WHERE is_active = true AND tracked_tier = 'cold';

-- Picker RPC: returns up to p_limit cold fund codes, balanced across
-- AMCs. Uses a LATERAL join to pick up to p_per_amc per fund house
-- from each round so the overall set is spread evenly.
CREATE OR REPLACE FUNCTION public.pick_prewarm_batch(
  p_limit    integer DEFAULT 50,
  p_per_amc  integer DEFAULT 3
)
RETURNS TABLE(amfi_code integer, amc text, fund_name text, priority smallint)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  WITH amcs AS (
    SELECT DISTINCT amc
      FROM fund_master
     WHERE is_active = true
       AND tracked_tier = 'cold'
       AND amc IS NOT NULL
  ),
  picks AS (
    SELECT f.*
      FROM amcs a
      JOIN LATERAL (
        SELECT amfi_code, amc, fund_name, prewarm_priority
          FROM fund_master fm
         WHERE fm.is_active = true
           AND fm.tracked_tier = 'cold'
           AND fm.amc = a.amc
         ORDER BY fm.prewarm_priority DESC,
                  fm.prewarm_last_at NULLS FIRST,
                  fm.aum_cr DESC NULLS LAST
         LIMIT p_per_amc
      ) f ON true
  )
  SELECT amfi_code, amc, fund_name, prewarm_priority
    FROM picks
   ORDER BY prewarm_priority DESC, random()
   LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION public.pick_prewarm_batch(integer, integer)
  TO authenticated, service_role;

-- Marker RPC the prewarm worker calls AFTER successfully fetching each
-- fund's history. Updates prewarm_last_at so the picker won't re-pick
-- it on the next pass.
CREATE OR REPLACE FUNCTION public.mark_prewarm_done(p_amfi_codes integer[])
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_count integer;
BEGIN
  IF p_amfi_codes IS NULL OR array_length(p_amfi_codes, 1) = 0 THEN
    RETURN 0;
  END IF;

  UPDATE fund_master
     SET prewarm_last_at  = now(),
         prewarm_priority = 0
   WHERE amfi_code = ANY(p_amfi_codes);

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.mark_prewarm_done(integer[])
  TO authenticated, service_role;
