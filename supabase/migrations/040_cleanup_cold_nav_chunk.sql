-- 040_cleanup_cold_nav_chunk.sql
--
-- One-shot helper: deletes nav_history rows for cold funds and rows
-- older than 400 days, in small chunks. Called repeatedly from bash
-- until it returns 0. Each call is its own transaction so we never
-- hit the 2-minute statement timeout. Dropped after cleanup completes.

CREATE OR REPLACE FUNCTION public.cleanup_nav_history_chunk(p_chunk int DEFAULT 50000)
RETURNS int
LANGUAGE plpgsql
AS $$
DECLARE
  v_deleted int;
BEGIN
  WITH victims AS (
    SELECT h.ctid
    FROM public.nav_history h
    LEFT JOIN public.fund_master f ON f.amfi_code = h.amfi_code
    WHERE f.tracked_tier = 'cold'
       OR f.tracked_tier IS NULL
       OR h.nav_date < (current_date - 400)
    LIMIT p_chunk
  )
  DELETE FROM public.nav_history h
  USING victims
  WHERE h.ctid = victims.ctid;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;

GRANT EXECUTE ON FUNCTION public.cleanup_nav_history_chunk(int) TO service_role;
