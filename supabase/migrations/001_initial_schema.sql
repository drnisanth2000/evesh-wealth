-- ═══════════════════════════════════════════════════════════════════════════════
-- eVesh Wealth Management — Initial Schema
-- Migration: 001_initial_schema.sql
-- ═══════════════════════════════════════════════════════════════════════════════

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pg_trgm";   -- trigram text search for fund names
CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- gen_random_uuid(), digest()
CREATE EXTENSION IF NOT EXISTS "pg_cron";   -- scheduled jobs for NAV refresh & alerts

-- ─────────────────────────────────────────────────────────────────────────────
-- PROFILES  (extends auth.users — created by Supabase trigger on sign-up)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id                      UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email                   TEXT NOT NULL,
  full_name               TEXT,
  pan                     TEXT,
  mobile                  TEXT,
  role                    TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  subscription_tier       TEXT NOT NULL DEFAULT 'free'
                            CHECK (subscription_tier IN ('free', 'individual', 'family')),
  subscription_status     TEXT NOT NULL DEFAULT 'active'
                            CHECK (subscription_status IN ('active', 'trialling', 'past_due', 'cancelled', 'expired')),
  subscription_expires_at TIMESTAMPTZ,
  mfa_enabled             BOOLEAN NOT NULL DEFAULT FALSE,
  fcm_token               TEXT,
  notification_prefs      JSONB NOT NULL DEFAULT '{
    "email": true,
    "push": false,
    "nav_drop": true,
    "sip_reminder": true,
    "ltcg_harvest": true,
    "rebalance_drift": true,
    "maturity_alert": true
  }'::JSONB,
  onboarding_complete     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-create profile on auth.users insert
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', '')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- FAMILIES  (one per owner; stores target allocation %)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS families (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id                    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  family_name                 TEXT NOT NULL DEFAULT 'My Family',
  -- Target allocation percentages (must sum to ≤ 100)
  target_core_equity          NUMERIC(5,2) NOT NULL DEFAULT 40.00,
  target_satellite_equity     NUMERIC(5,2) NOT NULL DEFAULT 20.00,
  target_hybrid               NUMERIC(5,2) NOT NULL DEFAULT 5.00,
  target_debt                 NUMERIC(5,2) NOT NULL DEFAULT 20.00,
  target_liquid               NUMERIC(5,2) NOT NULL DEFAULT 5.00,
  target_gold                 NUMERIC(5,2) NOT NULL DEFAULT 5.00,
  target_alternate            NUMERIC(5,2) NOT NULL DEFAULT 5.00,  -- REITs, PMS, AIF, Real Estate
  rebalance_drift_threshold   NUMERIC(4,2) NOT NULL DEFAULT 5.00,  -- trigger if drift > 5%
  risk_profile                TEXT DEFAULT 'Moderate'
                                CHECK (risk_profile IN ('Conservative','Moderate','ModeratelyAggressive','Aggressive','VeryAggressive')),
  primary_email               TEXT,
  sip_reminder_day            INTEGER DEFAULT 5 CHECK (sip_reminder_day BETWEEN 1 AND 28),
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER families_updated_at
  BEFORE UPDATE ON families
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- FAMILY MEMBERS  (individual investors within a family)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS family_members (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id       UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  owner_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  display_name    TEXT NOT NULL,
  pan             TEXT,
  date_of_birth   DATE,
  relationship    TEXT CHECK (relationship IN ('Self','Spouse','Son','Daughter','Father','Mother','HUF','Other')),
  risk_profile    TEXT CHECK (risk_profile IN ('Conservative','Moderate','ModeratelyAggressive','Aggressive','VeryAggressive')),
  tax_slab_pct    NUMERIC(4,1) DEFAULT 30.0 CHECK (tax_slab_pct IN (0, 5, 10, 15, 20, 30)),
  sip_day         INTEGER DEFAULT 5 CHECK (sip_day BETWEEN 1 AND 28),
  kyc_status      TEXT DEFAULT 'Complete' CHECK (kyc_status IN ('Complete','Pending','Expired','Not Started')),
  is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
  color_hex       TEXT DEFAULT '#1B8A5A',  -- chart color for this member
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER family_members_updated_at
  BEFORE UPDATE ON family_members
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- FUND MASTER  (global shared lookup — all 2000+ Indian MFs)
-- Written only by service_role (Edge Functions); read by all authenticated users
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fund_master (
  amfi_code             INTEGER PRIMARY KEY,
  isin_growth           TEXT,
  isin_div_reinvest     TEXT,
  fund_name             TEXT NOT NULL,
  amc                   TEXT,
  -- Classification
  category              TEXT,          -- "Equity Scheme - Flexi Cap Fund"
  sub_category          TEXT,
  fund_type             TEXT,          -- "Equity","Debt","Hybrid","Gold","Index","InternationalFOF"
  tax_category          TEXT,          -- "Equity","Debt","Hybrid-E","Hybrid-D","SGB","Exempt","International"
  plan_type             TEXT,          -- "Direct","Regular"
  -- NAV
  latest_nav            NUMERIC(12,4),
  prev_nav              NUMERIC(12,4),  -- previous day NAV (for 1D change)
  nav_date              DATE,
  nav_30d_high          NUMERIC(12,4),  -- rolling 30-day high NAV (for drop alerts)
  -- Fund metadata (from mf.captnemo.in)
  expense_ratio         NUMERIC(5,3),
  er_source             TEXT DEFAULT 'AMFI',
  er_updated_at         DATE,
  fund_managers         TEXT[],         -- array: ["Rajeev Thakkar", "Raunak Onkar"]
  manager_updated_at    DATE,
  crisil_rating         TEXT,           -- "Very High Risk","High Risk","Moderately High Risk","Moderate Risk","Low to Moderate","Low"
  fund_rating           INTEGER,        -- 1–5 stars (Value Research / Morningstar)
  aum_cr                NUMERIC(14,2),  -- AUM in crores
  -- Returns (from captnemo)
  return_1y             NUMERIC(7,4),
  return_3y             NUMERIC(7,4),
  return_5y             NUMERIC(7,4),
  return_inception      NUMERIC(7,4),
  volatility_1y         NUMERIC(7,4),   -- annualised std dev
  benchmark_index       TEXT,
  exit_load             TEXT,
  min_investment        NUMERIC(12,2),
  min_sip_amount        NUMERIC(10,2),
  launch_date           DATE,
  is_active             BOOLEAN DEFAULT TRUE,
  nav_updated_at        TIMESTAMPTZ DEFAULT NOW(),
  metadata_updated_at   TIMESTAMPTZ
);

-- Full-text / trigram index for fund name typeahead search
CREATE INDEX IF NOT EXISTS idx_fund_master_name_trgm
  ON fund_master USING gin(fund_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_fund_master_isin_growth
  ON fund_master(isin_growth);
CREATE INDEX IF NOT EXISTS idx_fund_master_category
  ON fund_master(category, fund_type);
CREATE INDEX IF NOT EXISTS idx_fund_master_amc
  ON fund_master(amc);

-- ─────────────────────────────────────────────────────────────────────────────
-- TRANSACTIONS  (single entry point for ALL asset types)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  family_id       UUID REFERENCES families(id) ON DELETE SET NULL,
  member_id       UUID REFERENCES family_members(id) ON DELETE CASCADE,
  -- Fund / asset identification
  amfi_code       INTEGER REFERENCES fund_master(amfi_code),
  isin            TEXT,
  symbol          TEXT,                -- NSE/BSE ticker for stocks
  asset_type      TEXT NOT NULL CHECK (asset_type IN (
                    'MF','Stock','PMS','Gold','RealEstate',
                    'SGB','REIT','InvIT','FD','PPF','NPS','AIF','SIF','Other'
                  )),
  asset_name      TEXT,               -- free-text for non-MF assets
  -- Transaction data
  tx_date         DATE NOT NULL,
  tx_type         TEXT NOT NULL CHECK (tx_type IN (
                    'BUY','SELL','SIP','SWP',
                    'Switch-In','Switch-Out',
                    'IDCW','Bonus',
                    'STX-BUY','STX-SELL',
                    'STP-In','STP-Out',
                    'Dividend','Interest','Maturity',
                    'Opening Balance'
                  )),
  units           NUMERIC(18,4),
  nav_at_tx       NUMERIC(12,4),      -- NAV / price at transaction date
  amount          NUMERIC(18,2) NOT NULL,
  folio_number    TEXT,
  broker          TEXT,               -- HDFC/Axis/360One/Zerodha/IndMoney/Groww/Kuvera/MFCentral/Direct/Other
  notes           TEXT,
  -- Price alert thresholds (per-holding, like original Transactions col P/Q)
  target_amount   NUMERIC(18,2),      -- harvest target — alert when portfolio value reaches this
  stoploss_amount NUMERIC(18,2),      -- stop-loss — alert when portfolio value falls to this
  -- Deduplication: SHA256(amfi_code || tx_date || amount || tx_type || member_id)
  dedup_hash      TEXT UNIQUE,
  -- Import metadata
  import_source   TEXT DEFAULT 'manual'
                    CHECK (import_source IN ('manual','mfcentral_excel','mfcentral_pdf','cas','api')),
  raw_import_ref  TEXT,               -- reference to the source row in import batch
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER transactions_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX IF NOT EXISTS idx_transactions_owner_date
  ON transactions(owner_id, tx_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_member_amfi
  ON transactions(member_id, amfi_code);
CREATE INDEX IF NOT EXISTS idx_transactions_amfi_type
  ON transactions(amfi_code, tx_type);
CREATE INDEX IF NOT EXISTS idx_transactions_family
  ON transactions(family_id, tx_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_dedup
  ON transactions(dedup_hash);
CREATE INDEX IF NOT EXISTS idx_transactions_asset_type
  ON transactions(owner_id, asset_type, tx_date DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- NAV HISTORY  (daily NAV per fund — stored on-demand for held funds)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS nav_history (
  amfi_code   INTEGER NOT NULL REFERENCES fund_master(amfi_code) ON DELETE CASCADE,
  nav_date    DATE NOT NULL,
  nav         NUMERIC(12,4) NOT NULL,
  PRIMARY KEY (amfi_code, nav_date)
);

CREATE INDEX IF NOT EXISTS idx_nav_history_amfi_date
  ON nav_history(amfi_code, nav_date DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- GOALS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS goals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  family_id       UUID REFERENCES families(id) ON DELETE SET NULL,
  member_id       UUID REFERENCES family_members(id) ON DELETE CASCADE,
  goal_name       TEXT NOT NULL,
  goal_type       TEXT DEFAULT 'Other'
                    CHECK (goal_type IN ('Retirement','Education','Home','Vehicle','Marriage','Travel','Emergency','Other')),
  target_amount   NUMERIC(18,2) NOT NULL,
  target_date     DATE NOT NULL,
  current_amount  NUMERIC(18,2) NOT NULL DEFAULT 0,
  monthly_sip     NUMERIC(14,2),
  assumed_return  NUMERIC(5,2) NOT NULL DEFAULT 12.0,  -- assumed CAGR %
  bucket          INTEGER CHECK (bucket IN (1,2,3)),   -- 1=Stability, 2=Income, 3=Growth
  priority        TEXT NOT NULL DEFAULT 'Medium'
                    CHECK (priority IN ('Critical','High','Medium','Low','Aspirational')),
  status          TEXT,   -- computed: Achieved / OnTrack / Watch / Behind
  linked_fund_amfi_codes INTEGER[],  -- funds allocated to this goal
  notes           TEXT,
  icon_emoji      TEXT DEFAULT '🎯',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER goals_updated_at
  BEFORE UPDATE ON goals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX IF NOT EXISTS idx_goals_owner
  ON goals(owner_id, target_date);
CREATE INDEX IF NOT EXISTS idx_goals_member
  ON goals(member_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- OTHER ASSETS  (SGBs, REITs, InvITs, FDs, PPF, NPS, PMS, Real Estate, AIF, SIF)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS other_assets (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  family_id       UUID REFERENCES families(id) ON DELETE SET NULL,
  member_id       UUID REFERENCES family_members(id) ON DELETE CASCADE,
  asset_type      TEXT NOT NULL CHECK (asset_type IN (
                    'SGB','REIT','InvIT','FD','RD','PPF','NPS',
                    'PMS','AIF','SIF','RealEstate','GoldPhysical',
                    'GoldETF','Bonds','EPF','Gratuity','Other'
                  )),
  description     TEXT NOT NULL,
  isin_symbol     TEXT,                -- for REITs/InvITs/ETFs
  quantity        NUMERIC(18,4),       -- units / grams / sq.ft
  cost_value      NUMERIC(18,2),       -- total cost of acquisition
  current_value   NUMERIC(18,2),       -- manually updated for PMS/AIF/RealEstate
  current_price   NUMERIC(12,4),       -- price per unit (auto for REITs via proxy)
  -- Income / interest
  interest_rate   NUMERIC(6,3),        -- coupon or FD rate %
  interest_frequency TEXT DEFAULT 'Cumulative'
                    CHECK (interest_frequency IN ('Monthly','Quarterly','Half-Yearly','Annual','Cumulative','At Maturity')),
  accrued_interest NUMERIC(14,2),
  -- Tax
  tax_category    TEXT DEFAULT 'Debt',
  -- Dates
  start_date      DATE,
  maturity_date   DATE,
  lock_in_end_date DATE,
  last_valuation_date DATE,
  -- SGB specific
  is_sgb          BOOLEAN DEFAULT FALSE,
  sgb_tranche     TEXT,               -- "SGB 2020-21 Series X"
  sgb_issue_price NUMERIC(10,4),
  -- Metadata
  broker_or_institution TEXT,
  account_number  TEXT,
  notes           TEXT,
  last_updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_other_assets_owner_type
  ON other_assets(owner_id, asset_type);
CREATE INDEX IF NOT EXISTS idx_other_assets_maturity
  ON other_assets(maturity_date) WHERE maturity_date IS NOT NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- ALERT LOG
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS alert_log (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  alert_type      TEXT NOT NULL CHECK (alert_type IN (
                    'NAV_DROP','PRICE_HARVEST','STOPLOSS',
                    'SIP_REMINDER','LTCG_HARVEST',
                    'ER_CHANGE','MANAGER_CHANGE',
                    'REBALANCE_DRIFT','MATURITY',
                    'XIRR_BELOW_TARGET','GOAL_BEHIND',
                    'PORTFOLIO_GAIN','SYSTEM'
                  )),
  severity        TEXT NOT NULL CHECK (severity IN ('URGENT','MEDIUM','LOW')),
  title           TEXT NOT NULL,
  body            TEXT,
  amfi_code       INTEGER REFERENCES fund_master(amfi_code),
  member_id       UUID REFERENCES family_members(id) ON DELETE CASCADE,
  -- Deduplication key — prevents re-firing same alert
  -- Format: {type}_{amfi/member}_{FY/date} e.g. "LTCG_HARVEST_100356_FY2526"
  dedup_key       TEXT UNIQUE,
  is_read         BOOLEAN NOT NULL DEFAULT FALSE,
  emailed_at      TIMESTAMPTZ,
  push_sent_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_alert_log_owner_unread
  ON alert_log(owner_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_alert_log_dedup
  ON alert_log(dedup_key);

-- ─────────────────────────────────────────────────────────────────────────────
-- BENCHMARK DATA  (index values for portfolio comparison)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS benchmark_data (
  index_name    TEXT NOT NULL,   -- 'Nifty50TRI','Nifty500TRI','Midcap150TRI','Smallcap250TRI','GoldIndex'
  nav_date      DATE NOT NULL,
  index_value   NUMERIC(14,4),
  PRIMARY KEY (index_name, nav_date)
);

CREATE INDEX IF NOT EXISTS idx_benchmark_index_date
  ON benchmark_data(index_name, nav_date DESC);
