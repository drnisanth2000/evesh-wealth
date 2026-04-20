-- supabase/migrations/012_frozen_plans.sql
-- Slice 6b: frozen plans + per-member drift threshold

-- frozen_plans table
CREATE TABLE IF NOT EXISTS frozen_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES auth.users(id) NOT NULL,
  member_id UUID REFERENCES family_members(id),
  fund_allocations JSONB NOT NULL,
  additional_lumpsum NUMERIC DEFAULT 0,
  additional_sip NUMERIC DEFAULT 0,
  health_score INT,
  health_delta INT,
  total_tax_impact NUMERIC,
  total_exit_load NUMERIC,
  bucket_targets JSONB,
  action_items JSONB,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ
);

-- RLS
ALTER TABLE frozen_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own frozen plans"
  ON frozen_plans FOR SELECT
  USING (owner_id = auth.uid());

CREATE POLICY "Users can insert own frozen plans"
  ON frozen_plans FOR INSERT
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can update own frozen plans"
  ON frozen_plans FOR UPDATE
  USING (owner_id = auth.uid());

CREATE POLICY "Users can delete own frozen plans"
  ON frozen_plans FOR DELETE
  USING (owner_id = auth.uid());

-- Index for quick lookup of active plan per member
CREATE INDEX idx_frozen_plans_owner_member_status
  ON frozen_plans(owner_id, member_id, status);

-- drift_threshold_pct column on family_members
ALTER TABLE family_members
  ADD COLUMN IF NOT EXISTS drift_threshold_pct NUMERIC DEFAULT 5.0;
