-- ═══════════════════════════════════════════════════════════════════════════════
-- eVesh — Wealth Planner v2: asset class override
-- Migration: 049_asset_class_override.sql
--
-- Adds `asset_class_override` to `transactions` so the user can manually
-- re-classify a fund into a different asset class (Core Equity / Satellite
-- Equity / Hybrid / Debt / Liquid / Gold / Alternate) when the auto mapping
-- from AMFI category + fund_master is wrong.
--
-- Coexists with the existing `bucket_override` column. Asset class override
-- drives the "My Mutual Funds → Current" grouping; bucket override drives the
-- 3-bucket Rebalance view.
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS asset_class_override TEXT
    CHECK (asset_class_override IN (
      'coreEquity','satelliteEquity','hybrid','debt','liquid','gold','alternate'
    ));

COMMENT ON COLUMN public.transactions.asset_class_override IS
  'Wealth Planner v2: manual override of the auto-derived asset class '
  '(per-fund, applies to all rows of an amfi_code). Values match the '
  'AssetClass enum .name in Dart.';
