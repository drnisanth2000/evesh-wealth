-- 015_fund_holdings_cache.sql
-- Fund holdings cache (Groww data) + groww_slug + notification prefs update

-- ══════════════════════════════════════════════════════════════
-- 1. fund_holdings_cache table
-- ══════════════════════════════════════════════════════════════

CREATE TABLE fund_holdings_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  amfi_code INT NOT NULL,
  company_name TEXT NOT NULL,
  sector_name TEXT,
  corpus_pct NUMERIC(8,4) NOT NULL,
  instrument_name TEXT,
  nature_name TEXT,
  rating TEXT,
  market_value NUMERIC(18,2),
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_holding UNIQUE (amfi_code, company_name)
);

CREATE INDEX idx_holdings_amfi ON fund_holdings_cache (amfi_code);
CREATE INDEX idx_holdings_fetched ON fund_holdings_cache (fetched_at);

-- No RLS — public fund data, not user-specific.

-- ══════════════════════════════════════════════════════════════
-- 2. Add groww_slug to fund_master
-- ══════════════════════════════════════════════════════════════

ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS groww_slug TEXT;

-- ══════════════════════════════════════════════════════════════
-- 3. Add overlap notification prefs for existing profiles
-- ══════════════════════════════════════════════════════════════

UPDATE profiles
SET notification_prefs = notification_prefs
  || '{"stock_concentration": true, "sector_concentration": true, "fund_overlap": true}'::jsonb
WHERE notification_prefs IS NOT NULL;
