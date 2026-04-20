-- 022_fund_performance_amfi.sql
-- Extends fund_master with AMFI daily performance fields and adds a sync log.
-- All ADD COLUMN statements are IF NOT EXISTS so this migration is safe to re-run.

-- ── fund_master new columns ────────────────────────────────────────────────
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS nav_direct          NUMERIC(12,4);

ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS return_7d           NUMERIC(7,4);
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS return_15d          NUMERIC(7,4);
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS return_1m           NUMERIC(7,4);
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS return_3m           NUMERIC(7,4);
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS return_6m           NUMERIC(7,4);
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS return_10y          NUMERIC(7,4);

-- Direct plan returns
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS return_direct_1y    NUMERIC(7,4);
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS return_direct_3y    NUMERIC(7,4);
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS return_direct_5y    NUMERIC(7,4);
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS return_direct_10y   NUMERIC(7,4);

-- Benchmark returns
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS return_bench_1y     NUMERIC(7,4);
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS return_bench_3y     NUMERIC(7,4);
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS return_bench_5y     NUMERIC(7,4);
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS return_bench_10y    NUMERIC(7,4);

-- Information ratios
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS info_ratio_1y       NUMERIC(7,4);
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS info_ratio_3y       NUMERIC(7,4);
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS info_ratio_5y       NUMERIC(7,4);
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS info_ratio_10y      NUMERIC(7,4);

-- Riskometer readings
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS riskometer_scheme   TEXT;
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS riskometer_bench    TEXT;

-- Source tracking
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS returns_source      TEXT;
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS returns_updated_at  TIMESTAMPTZ;

-- Helpful indexes for the screener
CREATE INDEX IF NOT EXISTS idx_fund_master_return_3m      ON fund_master (return_3m DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_fund_master_return_6m      ON fund_master (return_6m DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_fund_master_info_ratio_3y  ON fund_master (info_ratio_3y DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_fund_master_info_ratio_5y  ON fund_master (info_ratio_5y DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_fund_master_returns_source ON fund_master (returns_source);

-- ── fund_perf_sync_log ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fund_perf_sync_log (
  id           SERIAL PRIMARY KEY,
  run_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  report_date  DATE,
  total_funds  INTEGER,
  updated      INTEGER,
  errors       JSONB
);

CREATE INDEX IF NOT EXISTS idx_fund_perf_sync_log_run_at ON fund_perf_sync_log (run_at DESC);
