-- 013_watchlist_rules.sql
-- Watchlist rules table + FCM token + notification prefs defaults

-- ══════════════════════════════════════════════════════════════
-- 1. watchlist_rules table
-- ══════════════════════════════════════════════════════════════

CREATE TABLE watchlist_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES auth.users(id) NOT NULL,
  member_id UUID REFERENCES family_members(id),
  amfi_code INT,
  fund_name TEXT,
  rule_type TEXT NOT NULL CHECK (rule_type IN ('stop_loss', 'gain_harvest', 'price_target', 'allocation_drift')),
  threshold_type TEXT NOT NULL CHECK (threshold_type IN ('nav', 'amount', 'pct')),
  threshold_value NUMERIC NOT NULL,
  direction TEXT NOT NULL DEFAULT 'below' CHECK (direction IN ('below', 'above')),
  asset_class_key TEXT,
  is_active BOOLEAN DEFAULT true,
  last_triggered_at TIMESTAMPTZ,
  cooldown_hours INT DEFAULT 24,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE watchlist_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "select_own_rules" ON watchlist_rules
  FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "insert_own_rules" ON watchlist_rules
  FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "update_own_rules" ON watchlist_rules
  FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY "delete_own_rules" ON watchlist_rules
  FOR DELETE USING (owner_id = auth.uid());

CREATE INDEX idx_watchlist_active
  ON watchlist_rules (owner_id, is_active)
  WHERE is_active = true;

CREATE INDEX idx_watchlist_amfi
  ON watchlist_rules (amfi_code)
  WHERE amfi_code IS NOT NULL;

-- ══════════════════════════════════════════════════════════════
-- 2. Add fcm_token to profiles
-- ══════════════════════════════════════════════════════════════

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- ══════════════════════════════════════════════════════════════
-- 3. Set default notification_prefs for existing profiles
-- ══════════════════════════════════════════════════════════════

UPDATE profiles
SET notification_prefs = jsonb_build_object(
  'email', true,
  'push', true,
  'frequency', 'daily',
  'stop_loss', true,
  'gain_harvest', true,
  'rebalance_drift', true,
  'sip_reminder', true,
  'nav_drop', true,
  'ltcg_harvest', true,
  'maturity_alert', true,
  'price_target', true,
  'report_weekly', true,
  'report_monthly', true,
  'report_yearly', true
)
WHERE notification_prefs IS NULL;
