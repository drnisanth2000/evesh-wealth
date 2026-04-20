-- 020_backfill_fund_amfi_category.sql
-- Adds match_amfi_category() helper and backfills fund_master rows.

CREATE OR REPLACE FUNCTION match_amfi_category(p_text TEXT)
RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
  v_id TEXT;
  v_norm TEXT := lower(coalesce(p_text, ''));
BEGIN
  IF v_norm = '' THEN
    RETURN NULL;
  END IF;
  SELECT id INTO v_id
  FROM amfi_category
  WHERE EXISTS (
    SELECT 1 FROM unnest(match_patterns) AS p
    WHERE v_norm LIKE '%' || p || '%'
  )
  ORDER BY array_length(match_patterns, 1) DESC
  LIMIT 1;
  RETURN v_id;
END;$$;

UPDATE fund_master fm
SET amfi_category_id = match_amfi_category(coalesce(fm.sub_category, fm.category)),
    benchmark_tier1 = ac.tier1_benchmark,
    benchmark_tier2 = ac.tier2_benchmark
FROM amfi_category ac
WHERE ac.id = match_amfi_category(coalesce(fm.sub_category, fm.category))
  AND fm.amfi_category_id IS NULL;
