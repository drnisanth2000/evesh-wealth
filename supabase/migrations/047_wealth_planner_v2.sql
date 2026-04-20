-- ═══════════════════════════════════════════════════════════════════════════════
-- eVesh — Wealth Planner v2: foundations
-- Migration: 047_wealth_planner_v2.sql
--
-- (a) `bucket_override` on `other_assets` and `transactions` so the user can
--     manually re-classify a holding into a different 3-bucket (Liquid /
--     Fixed Income / Growth) when the auto mapping is wrong.
-- (b) New table `pending_orders` — captures user-initiated buy/SIP/switch/SWP/
--     sell/gift intents. Order Status tab reads from here. No broker
--     integration yet — status flips are user-managed.
-- (c) New table `rebalance_dismissals` — when the user dismisses a suggested
--     swap, we hash (member, from_amfi, to_amfi, drift_bucket) so re-running
--     analysis with slightly different ₹ values still matches.
-- (d) New table `deployment_plans` — saved lumpsum / SIP / split plans with
--     the full computed allocation in JSONB.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- (a) bucket_override columns
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.other_assets
  ADD COLUMN IF NOT EXISTS bucket_override TEXT
    CHECK (bucket_override IN ('liquid','fixedIncome','growth'));

ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS bucket_override TEXT
    CHECK (bucket_override IN ('liquid','fixedIncome','growth'));

COMMENT ON COLUMN public.other_assets.bucket_override IS
  'Wealth Planner v2: manual override of the auto-derived 3-bucket classification.';
COMMENT ON COLUMN public.transactions.bucket_override IS
  'Wealth Planner v2: manual override of the auto-derived 3-bucket classification (per-fund, applies to all rows of an amfi_code).';

-- ─────────────────────────────────────────────────────────────────────────────
-- (b) pending_orders
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pending_orders (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id        UUID NOT NULL REFERENCES public.profiles(id)        ON DELETE CASCADE,
  family_id       UUID          REFERENCES public.families(id)        ON DELETE SET NULL,
  member_id       UUID          REFERENCES public.family_members(id)  ON DELETE CASCADE,
  amfi_code       INTEGER,
  fund_name       TEXT NOT NULL,
  asset_type      TEXT NOT NULL DEFAULT 'MF',
  order_kind      TEXT NOT NULL CHECK (order_kind IN
                    ('buy','sip','lumpsum','switch','swp','sell','gift')),
  switch_to_amfi  INTEGER,                  -- only for order_kind = 'switch'
  amount          NUMERIC(18,2),            -- ₹ value (NULL for unit-based orders)
  units           NUMERIC(18,4),            -- units (NULL for amount-based orders)
  status          TEXT NOT NULL DEFAULT 'placed'
                    CHECK (status IN ('draft','placed','executed','cancelled')),
  source          TEXT NOT NULL DEFAULT 'manual'
                    CHECK (source IN ('manual','rebalance','deployment','watchlist')),
  source_ref      UUID,                     -- e.g. deployment_plan id, dismissal id
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  executed_at     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_pending_orders_owner_status
  ON public.pending_orders(owner_id, status);
CREATE INDEX IF NOT EXISTS idx_pending_orders_member
  ON public.pending_orders(member_id) WHERE member_id IS NOT NULL;

ALTER TABLE public.pending_orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pending_orders_owner" ON public.pending_orders;
CREATE POLICY "pending_orders_owner"
  ON public.pending_orders FOR ALL
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

COMMENT ON TABLE public.pending_orders IS
  'Wealth Planner v2: user-initiated draft/placed/executed orders. RLS: owner_id = auth.uid().';

-- ─────────────────────────────────────────────────────────────────────────────
-- (c) rebalance_dismissals
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.rebalance_dismissals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id        UUID NOT NULL REFERENCES public.profiles(id)        ON DELETE CASCADE,
  family_id       UUID          REFERENCES public.families(id)        ON DELETE SET NULL,
  member_id       UUID          REFERENCES public.family_members(id)  ON DELETE CASCADE,
  suggestion_hash TEXT NOT NULL,            -- sha256(memberId|fromAmfi|toAmfi|driftBucket)
  from_amfi_code  INTEGER,
  to_amfi_code    INTEGER,                  -- NULL when 'Exit' suggestion
  drift_pct       NUMERIC(6,2),
  reason          TEXT,
  dismissed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_rebalance_dismissals_owner_hash
  ON public.rebalance_dismissals(owner_id, suggestion_hash);
CREATE INDEX IF NOT EXISTS idx_rebalance_dismissals_member
  ON public.rebalance_dismissals(member_id) WHERE member_id IS NOT NULL;

ALTER TABLE public.rebalance_dismissals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rebalance_dismissals_owner" ON public.rebalance_dismissals;
CREATE POLICY "rebalance_dismissals_owner"
  ON public.rebalance_dismissals FOR ALL
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

COMMENT ON TABLE public.rebalance_dismissals IS
  'Wealth Planner v2: dismissed rebalance suggestions. UNIQUE (owner_id, suggestion_hash) prevents re-creation. RLS: owner_id = auth.uid().';

-- ─────────────────────────────────────────────────────────────────────────────
-- (d) deployment_plans
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.deployment_plans (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id        UUID NOT NULL REFERENCES public.profiles(id)        ON DELETE CASCADE,
  family_id       UUID          REFERENCES public.families(id)        ON DELETE SET NULL,
  member_id       UUID          REFERENCES public.family_members(id)  ON DELETE CASCADE,
  lumpsum_rupees  NUMERIC(18,2) NOT NULL DEFAULT 0,
  sip_rupees      NUMERIC(18,2) NOT NULL DEFAULT 0,
  split_pct       NUMERIC(5,2)  NOT NULL DEFAULT 30
                    CHECK (split_pct >= 0 AND split_pct <= 100),
  plan_jsonb      JSONB NOT NULL,           -- materialised allocation tree
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  executed_at     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_deployment_plans_owner
  ON public.deployment_plans(owner_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_deployment_plans_member
  ON public.deployment_plans(member_id) WHERE member_id IS NOT NULL;

ALTER TABLE public.deployment_plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "deployment_plans_owner" ON public.deployment_plans;
CREATE POLICY "deployment_plans_owner"
  ON public.deployment_plans FOR ALL
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

COMMENT ON TABLE public.deployment_plans IS
  'Wealth Planner v2: saved lumpsum / SIP / split deployment plans with full allocation tree in JSONB. RLS: owner_id = auth.uid().';

-- ─────────────────────────────────────────────────────────────────────────────
-- Verification (run these and share output if anything is unexpected)
-- ─────────────────────────────────────────────────────────────────────────────
-- SELECT column_name, data_type, is_nullable
--   FROM information_schema.columns
--  WHERE table_schema = 'public'
--    AND table_name IN ('other_assets','transactions')
--    AND column_name = 'bucket_override';
--
-- SELECT tablename, rowsecurity
--   FROM pg_tables
--  WHERE schemaname = 'public'
--    AND tablename IN ('pending_orders','rebalance_dismissals','deployment_plans');
--
-- SELECT polname, polcmd FROM pg_policy
--  WHERE polrelid IN (
--    'public.pending_orders'::regclass,
--    'public.rebalance_dismissals'::regclass,
--    'public.deployment_plans'::regclass
--  );
