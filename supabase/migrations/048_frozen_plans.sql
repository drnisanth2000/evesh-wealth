-- ═══════════════════════════════════════════════════════════════════════════════
-- eVesh — Wealth Planner v2 Hotfix Round 4: frozen_plans table
-- Migration: 048_frozen_plans.sql
--
-- The legacy ActionCenter "Freeze Plan" button (and now the new Asset
-- Allocation → Asset "Freeze Plan" button) inserts a `frozen_plans` row.
-- The table was never created. Round 4's Rebalance target derivation
-- ALSO reads `frozen_plans` (via `activeFrozenPlanProvider`) so the missing
-- table breaks Suggested with `PGRST205: Could not find 'public.frozen_plans'`.
--
-- Schema mirrors `FrozenPlan.toJson()` (snake_case after Round-4 normalisation).
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.frozen_plans (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id              UUID NOT NULL REFERENCES public.profiles(id)        ON DELETE CASCADE,
  member_id             UUID          REFERENCES public.family_members(id)  ON DELETE CASCADE,
  fund_allocations      JSONB NOT NULL DEFAULT '{}'::jsonb,
  additional_lumpsum    NUMERIC(18,2) NOT NULL DEFAULT 0,
  additional_sip        NUMERIC(18,2) NOT NULL DEFAULT 0,
  health_score          INTEGER,
  health_delta          INTEGER,
  total_tax_impact      NUMERIC(18,2),
  total_exit_load       NUMERIC(18,2),
  bucket_targets        JSONB,
  asset_class_targets   JSONB,
  action_items          JSONB,
  status                TEXT NOT NULL DEFAULT 'active'
                          CHECK (status IN ('active','completed','superseded')),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at          TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_frozen_plans_owner_status
  ON public.frozen_plans(owner_id, status);
CREATE INDEX IF NOT EXISTS idx_frozen_plans_member
  ON public.frozen_plans(member_id) WHERE member_id IS NOT NULL;

-- Only one active plan per (owner_id, member_id). Use a partial unique index
-- so the supersede flow (UPDATE status → 'superseded' before INSERT) keeps
-- working without races.
CREATE UNIQUE INDEX IF NOT EXISTS idx_frozen_plans_one_active_per_member
  ON public.frozen_plans(owner_id, COALESCE(member_id, '00000000-0000-0000-0000-000000000000'))
  WHERE status = 'active';

ALTER TABLE public.frozen_plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "frozen_plans_owner" ON public.frozen_plans;
CREATE POLICY "frozen_plans_owner"
  ON public.frozen_plans FOR ALL
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

COMMENT ON TABLE public.frozen_plans IS
  'Wealth Planner v2: snapshot of a member''s active allocation plan. Asset Allocation → Asset → Freeze writes here. RLS: owner_id = auth.uid().';
