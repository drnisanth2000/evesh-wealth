-- ═══════════════════════════════════════════════════════════════════════════════
-- Fix RLS policies that use get_subscription_tier() — returns null inside
-- policy evaluation, blocking all inserts for family_members and other_assets.
-- App is free for all users; subscription gating removed until Razorpay ships.
-- ═══════════════════════════════════════════════════════════════════════════════

-- FAMILY MEMBERS: allow insert when owner_id matches (no member count limit)
DROP POLICY IF EXISTS "family_members_owner_write" ON family_members;
CREATE POLICY "family_members_owner_write"
  ON family_members FOR INSERT
  TO authenticated
  WITH CHECK (owner_id = auth.uid());

-- OTHER ASSETS: allow all operations when owner_id matches (no tier gate)
DROP POLICY IF EXISTS "other_assets_owner" ON other_assets;
CREATE POLICY "other_assets_owner"
  ON other_assets FOR ALL
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());
