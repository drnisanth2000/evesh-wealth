-- ═══════════════════════════════════════════════════════════════════════════════
-- eVesh Wealth Management — CAMS CAS PDF Support
-- Migration: 008_cams_cas_pdf_support.sql
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1A. New columns on transactions for STT & stamp duty tracking
ALTER TABLE transactions
  ADD COLUMN IF NOT EXISTS stamp_duty    NUMERIC(12,4) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS stt_amount    NUMERIC(12,4) DEFAULT 0;

-- 1B. Add 'cams_cas_pdf' to import_source CHECK constraint
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_import_source_check;
ALTER TABLE transactions ADD CONSTRAINT transactions_import_source_check
  CHECK (import_source IN ('manual','mfcentral_excel','mfcentral_pdf','cas','cams_cas_pdf','api'));

-- 1C. Folio details table — stores rich per-folio metadata from CAMS CAS
CREATE TABLE IF NOT EXISTS folio_details (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  member_id         UUID REFERENCES family_members(id) ON DELETE CASCADE,
  folio_number      TEXT NOT NULL,
  amc_name          TEXT,
  scheme_name       TEXT,
  isin              TEXT,
  pan               TEXT,
  kyc_status        TEXT,
  pan_status        TEXT,
  investor_name     TEXT,
  registrar         TEXT,
  advisor_code      TEXT,
  demat_status      TEXT,
  nominee_1         TEXT,
  nominee_2         TEXT,
  nominee_3         TEXT,
  closing_units     NUMERIC(18,4),
  closing_nav       NUMERIC(12,4),
  closing_nav_date  DATE,
  total_cost_value  NUMERIC(18,2),
  market_value      NUMERIC(18,2),
  exit_load_text    TEXT,
  UNIQUE(owner_id, folio_number, isin),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_folio_details_owner ON folio_details(owner_id);
CREATE INDEX IF NOT EXISTS idx_folio_details_member ON folio_details(member_id);
CREATE INDEX IF NOT EXISTS idx_folio_details_folio ON folio_details(folio_number);

ALTER TABLE folio_details ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own folio details"
  ON folio_details FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "Users can insert own folio details"
  ON folio_details FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "Users can update own folio details"
  ON folio_details FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY "Users can delete own folio details"
  ON folio_details FOR DELETE USING (owner_id = auth.uid());
CREATE POLICY "Service role full access on folio_details"
  ON folio_details FOR ALL USING (auth.role() = 'service_role');

CREATE TRIGGER folio_details_updated_at
  BEFORE UPDATE ON folio_details
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 1D. Add contact fields to family_members for CAMS-extracted data
ALTER TABLE family_members
  ADD COLUMN IF NOT EXISTS email   TEXT,
  ADD COLUMN IF NOT EXISTS mobile  TEXT,
  ADD COLUMN IF NOT EXISTS address TEXT;
