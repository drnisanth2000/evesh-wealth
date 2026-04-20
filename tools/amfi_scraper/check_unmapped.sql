-- Lists fund_master rows that the AMFI mapping could not classify.
-- Patch tools/amfi_scraper/scrape.ts (match_patterns) and re-run gen_sql.
SELECT amfi_code, fund_name, category, sub_category
FROM fund_master
WHERE amfi_category_id IS NULL
ORDER BY fund_name;
