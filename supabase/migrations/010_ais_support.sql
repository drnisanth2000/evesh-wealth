-- ═══════════════════════════════════════════════════════════════════════════════
-- eVesh Wealth Management — AIS (Annual Information Statement) Support
-- Migration: 010_ais_support.sql
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. AIS Statements table — stores parsed AIS data per member per FY
CREATE TABLE IF NOT EXISTS ais_statements (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  member_id         UUID REFERENCES family_members(id) ON DELETE CASCADE,
  financial_year    TEXT NOT NULL,              -- e.g. 'FY2526'
  pan               TEXT,
  investor_name     TEXT,
  date_of_birth     DATE,
  email             TEXT,
  mobile            TEXT,
  address           TEXT,

  -- ── Part B1: TDS Income ─────────────────────────────────────────────────
  salary_income     JSONB DEFAULT '[]'::jsonb,  -- [{employer, tds_192_code, amount, tds, quarters:[{q,date,amount,tds_deducted,tds_deposited,status}]}]
  dividend_income   JSONB DEFAULT '[]'::jsonb,  -- [{company, tds_194_code, info_source, total_amount, entries:[{quarter,date,amount,tds_deducted,tds_deposited,status}]}]
  interest_income   JSONB DEFAULT '[]'::jsonb,  -- [{bank, tds_194a_code, info_source, total_amount, entries:[{quarter,date,amount,tds_deducted,tds_deposited,status}]}]

  -- ── Part B2: SFT — Sale of Securities & MF ──────────────────────────────
  -- SFT-17-LES(M): Sale of listed equity shares via Depository
  stock_sales       JSONB DEFAULT '[]'::jsonb,  -- [{sr_no,date,security_name,isin,security_class,debit_type,credit_type,asset_type,quantity,sale_price,sales_consideration,stt,cost_of_acquisition,unit_fmv,fair_market_value,indexed_cost,status}]
  -- SFT-17-EMF(M): Sale of equity-oriented MF via Depository
  equity_mf_sales   JSONB DEFAULT '[]'::jsonb,  -- same structure as stock_sales
  -- SFT-18-OTU(M): Sale of other units (debt MF) via RTA
  debt_mf_sales     JSONB DEFAULT '[]'::jsonb,  -- same structure, grouped by info_source (CAMS/KFin)
  -- SFT-18(Pur): Purchase of MF
  mf_purchases      JSONB DEFAULT '[]'::jsonb,  -- [{info_code,info_source,amc_name,client_id,quarter,purchase_amount,sales_value,holder_flag,status}]

  -- ── Part B3: Tax Payments ───────────────────────────────────────────────
  tax_payments      JSONB DEFAULT '[]'::jsonb,  -- [{fy,major_head,minor_head,tax_a,surcharge_b,education_cess_c,others_d,total,bsr_code,date_of_deposit,challan_serial,challan_id}]

  -- ── Computed Summary ────────────────────────────────────────────────────
  -- Stock capital gains (from SFT-17-LES)
  stock_stcg        NUMERIC(18,2) DEFAULT 0,
  stock_ltcg        NUMERIC(18,2) DEFAULT 0,
  -- Equity MF capital gains (from SFT-17-EMF)
  eq_mf_stcg        NUMERIC(18,2) DEFAULT 0,
  eq_mf_ltcg        NUMERIC(18,2) DEFAULT 0,
  -- Debt MF capital gains (from SFT-18-OTU)
  debt_mf_stcg      NUMERIC(18,2) DEFAULT 0,
  debt_mf_ltcg      NUMERIC(18,2) DEFAULT 0,
  -- TDS totals
  total_salary      NUMERIC(18,2) DEFAULT 0,
  total_tds         NUMERIC(18,2) DEFAULT 0,
  total_dividends   NUMERIC(18,2) DEFAULT 0,
  total_interest    NUMERIC(18,2) DEFAULT 0,
  -- Counts
  stock_sale_count  INT DEFAULT 0,
  mf_sale_count     INT DEFAULT 0,
  purchase_count    INT DEFAULT 0,

  source_file       TEXT,
  imported_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(owner_id, member_id, financial_year)
);

CREATE INDEX IF NOT EXISTS idx_ais_statements_owner ON ais_statements(owner_id);
CREATE INDEX IF NOT EXISTS idx_ais_statements_member ON ais_statements(member_id);

ALTER TABLE ais_statements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own ais statements"
  ON ais_statements FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "Users can insert own ais statements"
  ON ais_statements FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "Users can update own ais statements"
  ON ais_statements FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY "Users can delete own ais statements"
  ON ais_statements FOR DELETE USING (owner_id = auth.uid());
CREATE POLICY "Service role full access on ais_statements"
  ON ais_statements FOR ALL USING (auth.role() = 'service_role');

-- 2. Extend import_source CHECK to allow 'ais_pdf'
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_import_source_check;
ALTER TABLE transactions ADD CONSTRAINT transactions_import_source_check
  CHECK (import_source IN ('manual','mfcentral_excel','mfcentral_pdf','cas','cams_cas_pdf','ais_pdf','api'));

-- 3. Add exit_load_free_pct to folio_details if not present
ALTER TABLE folio_details
  ADD COLUMN IF NOT EXISTS exit_load_free_pct NUMERIC(5,2) DEFAULT 0;
