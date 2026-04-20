-- 017_repair_watchlist_rules.sql
-- Repair: re-create watchlist_rules if migration 013 failed silently.
-- All statements are idempotent (IF NOT EXISTS / IF EXISTS guards).

CREATE TABLE IF NOT EXISTS watchlist_rules (
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

-- Policies (drop + create to be idempotent)
DO $$ BEGIN
  DROP POLICY IF EXISTS "select_own_rules" ON watchlist_rules;
  CREATE POLICY "select_own_rules" ON watchlist_rules
    FOR SELECT USING (owner_id = auth.uid());

  DROP POLICY IF EXISTS "insert_own_rules" ON watchlist_rules;
  CREATE POLICY "insert_own_rules" ON watchlist_rules
    FOR INSERT WITH CHECK (owner_id = auth.uid());

  DROP POLICY IF EXISTS "update_own_rules" ON watchlist_rules;
  CREATE POLICY "update_own_rules" ON watchlist_rules
    FOR UPDATE USING (owner_id = auth.uid());

  DROP POLICY IF EXISTS "delete_own_rules" ON watchlist_rules;
  CREATE POLICY "delete_own_rules" ON watchlist_rules
    FOR DELETE USING (owner_id = auth.uid());
END $$;

CREATE INDEX IF NOT EXISTS idx_watchlist_active
  ON watchlist_rules (owner_id, is_active)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_watchlist_amfi
  ON watchlist_rules (amfi_code)
  WHERE amfi_code IS NOT NULL;

-- Ensure fcm_token column exists on profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Set default notification_prefs for profiles that still have NULL
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
