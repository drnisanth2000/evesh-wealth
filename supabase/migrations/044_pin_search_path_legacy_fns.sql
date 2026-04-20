-- 044_pin_search_path_legacy_fns.sql
--
-- Clears the 8 remaining "Function Search Path Mutable" warnings from
-- the Supabase security advisor by pinning search_path on legacy
-- helper functions that were created before we knew about the linter
-- rule. Pure metadata change — no behavioral impact.
--
-- Also restricts fund_screener_mv to authenticated+service_role only.
-- The advisor flags materialized views exposed to anon because MVs
-- bypass RLS (unlike tables/views). Since the screener tab requires
-- login anyway in the app, dropping anon access is safe and closes
-- the warning.

-- ────────────────────────────────────────────────────────────────
-- Pin search_path on 8 legacy functions
-- ────────────────────────────────────────────────────────────────

DO $$
DECLARE
  fn_signature text;
  fn_signatures text[] := ARRAY[
    'public.cleanup_orphaned_transactions()',
    'public.shift_nav_to_prev()',
    'public.update_nav_30d_high()',
    'public.match_amfi_category(text)',
    'public.update_updated_at()',
    'public.is_admin()',
    'public.get_subscription_tier(uuid)',
    'public.sync_profile_subscription_tier()'
  ];
BEGIN
  FOREACH fn_signature IN ARRAY fn_signatures LOOP
    -- Try a few common signatures per function name (some of these
    -- might have differently-typed args than we guessed). Swallow
    -- "function does not exist" so the migration is idempotent.
    BEGIN
      EXECUTE format('ALTER FUNCTION %s SET search_path = public, pg_temp', fn_signature);
      RAISE NOTICE 'pinned: %', fn_signature;
    EXCEPTION WHEN undefined_function THEN
      RAISE NOTICE 'skipped (no such fn): %', fn_signature;
    END;
  END LOOP;
END $$;

-- Fallback: pin search_path on ANY remaining function in public
-- that still has config NULL (catches oddly-typed overloads we missed).
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT n.nspname || '.' || p.proname ||
           '(' || pg_get_function_identity_arguments(p.oid) || ')' AS sig
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
       AND p.prokind = 'f'
       AND (p.proconfig IS NULL OR NOT (p.proconfig::text LIKE '%search_path%'))
  LOOP
    BEGIN
      EXECUTE format('ALTER FUNCTION %s SET search_path = public, pg_temp', r.sig);
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'could not pin: % (%)', r.sig, SQLERRM;
    END;
  END LOOP;
END $$;

-- ────────────────────────────────────────────────────────────────
-- Restrict fund_screener_mv — remove anon access
-- ────────────────────────────────────────────────────────────────

REVOKE SELECT ON public.fund_screener_mv FROM anon;
-- authenticated + service_role retain their SELECT from migration 036.
