-- ═══════════════════════════════════════════════════════════════════════════════
-- eVesh — Security Sprint 3: RLS hardening
-- Migration: 046_sprint_3_rls_hardening.sql
--
-- (a) Drop dead `service_role` RLS policies (service_role bypasses RLS anyway
--     — these never evaluate and create a false sense of protection).
-- (b) Restrict `fund_holdings_cache`, `nav_history_archive`, and the
--     `nav_history_all` view to `authenticated` only. Prevents unauth
--     bulk-scrape of curated dataset via the PostgREST anon role.
-- (c) Prevent authenticated users from self-modifying privileged columns on
--     `profiles`: `role`, `subscription_tier`, `subscription_status`,
--     `subscription_expires_at`. Service-role writes (from webhook trigger)
--     are unaffected.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- (a) Drop redundant service_role policies
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Service role can manage import batches"       ON public.import_batches;
DROP POLICY IF EXISTS "Service role full access on folio_details"    ON public.folio_details;
DROP POLICY IF EXISTS "Service role full access on ais_statements"   ON public.ais_statements;

COMMENT ON TABLE public.folio_details  IS 'RLS: owner_id = auth.uid() for authenticated; service_role bypasses RLS by Supabase default.';
COMMENT ON TABLE public.ais_statements IS 'RLS: owner_id = auth.uid() for authenticated; service_role bypasses RLS by Supabase default.';
COMMENT ON TABLE public.import_batches IS 'RLS: owner_id = auth.uid() for authenticated; service_role bypasses RLS by Supabase default.';

-- ─────────────────────────────────────────────────────────────────────────────
-- (b) Restrict curated cache/archive tables to authenticated only
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "fund_holdings_cache_select" ON public.fund_holdings_cache;
CREATE POLICY "fund_holdings_cache_select" ON public.fund_holdings_cache
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "nav_history_archive_select" ON public.nav_history_archive;
CREATE POLICY "nav_history_archive_select" ON public.nav_history_archive
  FOR SELECT TO authenticated USING (true);

-- Revoke anon SELECT on the union view; regrant to authenticated + service_role.
REVOKE SELECT ON public.nav_history_all FROM anon;
GRANT  SELECT ON public.nav_history_all TO authenticated, service_role;

-- ─────────────────────────────────────────────────────────────────────────────
-- (c) Guard privileged columns on profiles against self-modification
-- ─────────────────────────────────────────────────────────────────────────────
-- The existing RLS policy `profiles_own_update` allows a user to update their
-- own row but does NOT restrict which columns are modifiable. A BEFORE UPDATE
-- trigger preserves the OLD value for privileged columns whenever the caller
-- is not running as service_role. This prevents an authenticated user from
-- escalating to admin or upgrading their subscription tier via a direct
-- PATCH to /rest/v1/profiles.
CREATE OR REPLACE FUNCTION public.prevent_profile_privilege_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- service_role bypasses the guard (webhook-driven subscription sync etc.)
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  -- For authenticated callers: silently preserve protected columns.
  -- We do not RAISE so legitimate PATCHes that happen to include unchanged
  -- values for these columns still succeed.
  NEW.role                    := OLD.role;
  NEW.subscription_tier       := OLD.subscription_tier;
  NEW.subscription_status     := OLD.subscription_status;
  NEW.subscription_expires_at := OLD.subscription_expires_at;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS prevent_profile_privilege_escalation_trg ON public.profiles;
CREATE TRIGGER prevent_profile_privilege_escalation_trg
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_profile_privilege_escalation();
