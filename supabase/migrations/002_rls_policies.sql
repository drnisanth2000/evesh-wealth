-- ═══════════════════════════════════════════════════════════════════════════════
-- eVesh Wealth Management — Row Level Security Policies
-- Migration: 002_rls_policies.sql
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- Enable RLS on all user-data tables
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE profiles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE families           ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members     ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE other_assets       ENABLE ROW LEVEL SECURITY;
ALTER TABLE nav_history        ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals              ENABLE ROW LEVEL SECURITY;
ALTER TABLE alert_log          ENABLE ROW LEVEL SECURITY;
ALTER TABLE fund_master        ENABLE ROW LEVEL SECURITY;
ALTER TABLE benchmark_data     ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: check if current user is admin
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- Helper: get subscription tier
CREATE OR REPLACE FUNCTION get_subscription_tier()
RETURNS TEXT LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT subscription_tier FROM profiles WHERE id = auth.uid();
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- FUND MASTER  (global shared lookup — all authenticated users can read)
-- Only service_role (Edge Functions) can write
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "fund_master_authenticated_read" ON fund_master;
CREATE POLICY "fund_master_authenticated_read"
  ON fund_master FOR SELECT
  TO authenticated
  USING (true);

-- service_role bypass: Supabase service_role key bypasses RLS by default.
-- No explicit policy needed for service_role writes.

-- ─────────────────────────────────────────────────────────────────────────────
-- BENCHMARK DATA  (global read for all authenticated users)
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "benchmark_authenticated_read" ON benchmark_data;
CREATE POLICY "benchmark_authenticated_read"
  ON benchmark_data FOR SELECT
  TO authenticated
  USING (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- NAV HISTORY  (global read for all authenticated; service_role writes)
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "nav_history_authenticated_read" ON nav_history;
CREATE POLICY "nav_history_authenticated_read"
  ON nav_history FOR SELECT
  TO authenticated
  USING (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- PROFILES
-- ─────────────────────────────────────────────────────────────────────────────
-- Users can read and update only their own profile
DROP POLICY IF EXISTS "profiles_own_select" ON profiles;
CREATE POLICY "profiles_own_select"
  ON profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS "profiles_own_update" ON profiles;
CREATE POLICY "profiles_own_update"
  ON profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Profile is auto-created by trigger; users cannot INSERT manually
-- (service_role / trigger handles insertion)

-- ─────────────────────────────────────────────────────────────────────────────
-- FAMILIES
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "families_owner" ON families;
CREATE POLICY "families_owner"
  ON families FOR ALL
  TO authenticated
  USING (owner_id = auth.uid());

-- Admin can read all families
DROP POLICY IF EXISTS "families_admin_read" ON families;
CREATE POLICY "families_admin_read"
  ON families FOR SELECT
  TO authenticated
  USING (is_admin());

-- ─────────────────────────────────────────────────────────────────────────────
-- FAMILY MEMBERS
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "family_members_owner" ON family_members;
CREATE POLICY "family_members_owner"
  ON family_members FOR SELECT
  TO authenticated
  USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "family_members_owner_write" ON family_members;
CREATE POLICY "family_members_owner_write"
  ON family_members FOR INSERT
  TO authenticated
  WITH CHECK (
    owner_id = auth.uid()
    AND (
      -- Family tier: unlimited members
      get_subscription_tier() = 'family'
      OR
      -- Individual + Free: only 1 member allowed
      (
        get_subscription_tier() IN ('individual', 'free')
        AND (SELECT COUNT(*) FROM family_members WHERE owner_id = auth.uid()) < 1
      )
    )
  );

DROP POLICY IF EXISTS "family_members_owner_update" ON family_members;
CREATE POLICY "family_members_owner_update"
  ON family_members FOR UPDATE
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "family_members_owner_delete" ON family_members;
CREATE POLICY "family_members_owner_delete"
  ON family_members FOR DELETE
  TO authenticated
  USING (owner_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────────
-- TRANSACTIONS
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "transactions_owner_read" ON transactions;
CREATE POLICY "transactions_owner_read"
  ON transactions FOR SELECT
  TO authenticated
  USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "transactions_owner_insert" ON transactions;
CREATE POLICY "transactions_owner_insert"
  ON transactions FOR INSERT
  TO authenticated
  WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "transactions_owner_update" ON transactions;
CREATE POLICY "transactions_owner_update"
  ON transactions FOR UPDATE
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "transactions_owner_delete" ON transactions;
CREATE POLICY "transactions_owner_delete"
  ON transactions FOR DELETE
  TO authenticated
  USING (owner_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────────
-- GOALS
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "goals_owner" ON goals;
CREATE POLICY "goals_owner"
  ON goals FOR ALL
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────────
-- OTHER ASSETS
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "other_assets_owner" ON other_assets;
CREATE POLICY "other_assets_owner"
  ON other_assets FOR ALL
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (
    owner_id = auth.uid()
    -- Free tier: other assets not allowed
    AND get_subscription_tier() != 'free'
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- ALERT LOG
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "alert_log_owner_read" ON alert_log;
CREATE POLICY "alert_log_owner_read"
  ON alert_log FOR SELECT
  TO authenticated
  USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "alert_log_owner_update" ON alert_log;
CREATE POLICY "alert_log_owner_update"
  ON alert_log FOR UPDATE
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- service_role inserts alerts (from Edge Functions)
