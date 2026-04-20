-- 018_amfi_category_tables.sql
-- Adds AMFI/SEBI scheme categorisation catalog and per-fund FK,
-- plus an index NAV history table for benchmark comparison charts.

CREATE TABLE IF NOT EXISTS amfi_category (
  id TEXT PRIMARY KEY,
  super_category TEXT NOT NULL,
  name TEXT NOT NULL,
  sebi_definition TEXT,
  match_patterns TEXT[] NOT NULL DEFAULT '{}',
  tier1_benchmark TEXT,
  tier2_benchmark TEXT,
  default_term TEXT NOT NULL,
  default_asset_class TEXT NOT NULL,
  default_tax_category TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE fund_master
  ADD COLUMN IF NOT EXISTS amfi_category_id TEXT REFERENCES amfi_category(id),
  ADD COLUMN IF NOT EXISTS benchmark_tier1 TEXT,
  ADD COLUMN IF NOT EXISTS benchmark_tier2 TEXT;

CREATE INDEX IF NOT EXISTS idx_fund_master_amfi_category
  ON fund_master(amfi_category_id);

CREATE TABLE IF NOT EXISTS index_nav_history (
  index_name TEXT NOT NULL,
  nav_date DATE NOT NULL,
  nav NUMERIC(18,4) NOT NULL,
  PRIMARY KEY (index_name, nav_date)
);
