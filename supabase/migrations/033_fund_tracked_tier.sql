-- 033_fund_tracked_tier.sql
--
-- Introduces a tiered fund universe so the daily nav_history + AMFI
-- refresh only processes the "warm" set (~2000 high-signal funds)
-- instead of the full 14k universe. This cuts daily Disk IO by ~85%
-- and makes the screener / research pages fast.
--
-- Tier semantics:
--   warm  → tracked by daily cron jobs. Screener & research pages show
--           these by default. Membership is recomputed weekly by
--           evaluate_fund_tracked_tier() based on AUM, return quartiles
--           in sub_category, age, passive fund flag, user holdings, and
--           user watchlist rules.
--   cold  → not tracked by the daily cron. Still searchable and still
--           openable from the detail page; the app lazily fetches
--           on-demand via mfapi.in and pre-warms idle-time in the
--           background. A cold fund automatically flips to warm the
--           moment any user interacts with it (see migration 037).
--
-- tier_reasons is an array of short tags explaining why a fund is warm
-- (e.g. {'aum+q5y','passive','held'}). Useful for debugging and for the
-- "Why is this tracked?" UI affordance on the fund detail page.

ALTER TABLE public.fund_master
  ADD COLUMN IF NOT EXISTS tracked_tier text NOT NULL DEFAULT 'cold'
    CHECK (tracked_tier IN ('warm','cold')),
  ADD COLUMN IF NOT EXISTS tier_reasons text[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS tier_evaluated_at timestamptz,
  ADD COLUMN IF NOT EXISTS tier_sticky_until timestamptz;
  -- tier_sticky_until: if set, fund cannot be demoted to 'cold' before
  -- this timestamp. Set by promote_fund_to_warm() when a user interacts
  -- so a recent on-demand fetch stays tracked for 30 days.

-- Hot index — used by every cron job that iterates the warm universe
-- and by the screener materialized view refresh.
CREATE INDEX IF NOT EXISTS fund_master_warm_active_idx
  ON public.fund_master (amfi_code)
  WHERE is_active = true AND tracked_tier = 'warm';

-- Reasons GIN index so we can answer "show me all passive funds we
-- track" or "show me everything held by a user" cheaply.
CREATE INDEX IF NOT EXISTS fund_master_tier_reasons_gin
  ON public.fund_master USING gin (tier_reasons);
