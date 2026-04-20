-- ═══════════════════════════════════════════════════════════════════════════════
-- eVesh Wealth Management — Subscriptions Table
-- Migration: 003_subscriptions.sql
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS subscriptions (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id            UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  tier                TEXT NOT NULL CHECK (tier IN ('free', 'individual', 'family')),
  status              TEXT NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active', 'trialling', 'past_due', 'cancelled', 'expired')),
  payment_provider    TEXT CHECK (payment_provider IN ('razorpay', 'stripe', 'manual')),
  provider_sub_id     TEXT,           -- Razorpay/Stripe subscription ID
  provider_order_id   TEXT,           -- Razorpay order ID
  plan_id             TEXT,           -- Provider plan ID
  amount_inr          NUMERIC(10,2),
  billing_cycle       TEXT CHECK (billing_cycle IN ('monthly', 'annual')),
  started_at          TIMESTAMPTZ,
  expires_at          TIMESTAMPTZ,
  trial_ends_at       TIMESTAMPTZ,
  cancelled_at        TIMESTAMPTZ,
  cancellation_reason TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER subscriptions_updated_at
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Users can read their own subscriptions; service_role manages writes
DROP POLICY IF EXISTS "subscriptions_owner_read" ON subscriptions;
CREATE POLICY "subscriptions_owner_read"
  ON subscriptions FOR SELECT
  TO authenticated
  USING (owner_id = auth.uid());

-- Admin can read all subscriptions
DROP POLICY IF EXISTS "subscriptions_admin_read" ON subscriptions;
CREATE POLICY "subscriptions_admin_read"
  ON subscriptions FOR SELECT
  TO authenticated
  USING (is_admin());

-- Index for payment provider lookups
CREATE INDEX IF NOT EXISTS idx_subscriptions_owner
  ON subscriptions(owner_id, status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_provider
  ON subscriptions(provider_sub_id) WHERE provider_sub_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_subscriptions_expires
  ON subscriptions(expires_at) WHERE status = 'active';

-- ─────────────────────────────────────────────────────────────────────────────
-- Function: update profile tier when subscription changes
-- Called by Edge Function webhook handler after payment
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION sync_profile_subscription_tier()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status = 'active' OR NEW.status = 'trialling' THEN
    UPDATE profiles
    SET
      subscription_tier = NEW.tier,
      subscription_status = NEW.status,
      subscription_expires_at = NEW.expires_at
    WHERE id = NEW.owner_id;
  ELSIF NEW.status IN ('cancelled', 'expired') THEN
    UPDATE profiles
    SET
      subscription_tier = 'free',
      subscription_status = NEW.status,
      subscription_expires_at = NULL
    WHERE id = NEW.owner_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER sync_subscription_to_profile
  AFTER INSERT OR UPDATE ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION sync_profile_subscription_tier();

-- ─────────────────────────────────────────────────────────────────────────────
-- IMPORT BATCHES  (track MF Central / CAS upload history)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS import_batches (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  file_name       TEXT,
  file_size_kb    INTEGER,
  import_source   TEXT CHECK (import_source IN ('mfcentral_excel','mfcentral_pdf','cas','manual_csv')),
  status          TEXT NOT NULL DEFAULT 'processing'
                    CHECK (status IN ('processing','completed','failed','partial')),
  rows_parsed     INTEGER DEFAULT 0,
  rows_inserted   INTEGER DEFAULT 0,
  rows_duplicate  INTEGER DEFAULT 0,
  rows_error      INTEGER DEFAULT 0,
  error_details   JSONB,
  storage_path    TEXT,   -- Supabase Storage path for the uploaded file
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at    TIMESTAMPTZ
);

ALTER TABLE import_batches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "import_batches_owner" ON import_batches;
CREATE POLICY "import_batches_owner"
  ON import_batches FOR ALL
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_import_batches_owner
  ON import_batches(owner_id, created_at DESC);
