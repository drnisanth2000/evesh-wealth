-- ────��─────────────────────────��──────────────────��───────────────────────────
-- Migration 009: CAMS CAS PDF Parser v2 columns
-- Adds confidence scoring on transactions and debug log on import_batches.
-- ─────────────────────────────���─────────────────────────────��─────────────────

-- 1. Confidence scoring per transaction (0-100 scale)
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS confidence INT;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS confidence_flags TEXT;

-- 2. Debug log for parse diagnostics (stored per import batch)
ALTER TABLE import_batches ADD COLUMN IF NOT EXISTS parse_debug_log TEXT;

-- 3. Expand tx_type CHECK constraint with new types from parser v2
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_tx_type_check;
ALTER TABLE transactions ADD CONSTRAINT transactions_tx_type_check
  CHECK (tx_type IN (
    'BUY', 'SELL', 'SIP', 'SWP',
    'Switch-In', 'Switch-Out',
    'IDCW', 'IDCW-Payout', 'IDCW-Reinvest',
    'Bonus', 'STX-BUY', 'STX-SELL',
    'STP-In', 'STP-Out',
    'Transfer-In', 'Transfer-Out',
    'Dividend', 'Interest', 'Maturity', 'Opening Balance'
  ));
