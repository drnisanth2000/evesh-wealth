/**
 * eVesh — Supabase Edge Function: fetch-fund-ondemand
 *
 * Lazy-fetch NAV history and short-window returns for a cold fund the
 * moment a user interacts with it, or in background batches picked by
 * pick_prewarm_batch for idle-time prewarming.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const MFAPI_BASE = 'https://api.mfapi.in/mf';

const HOT_DAYS = 400;
const PREWARM_CONCURRENCY = 4;

const CORS = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type':                 'application/json',
};

interface MfapiResponse {
  meta?: { scheme_code?: number; scheme_name?: string };
  data?: Array<{ date: string; nav: string }>;
}

interface NavRow { amfi_code: number; nav_date: string; nav: number }

function parseDate(ddmmyyyy: string): string | null {
  const m = /^(\d{2})-(\d{2})-(\d{4})$/.exec(ddmmyyyy.trim());
  if (!m) return null;
  return `${m[3]}-${m[2]}-${m[1]}`;
}

async function fetchMfapi(amfiCode: number): Promise<NavRow[]> {
  const r = await fetch(`${MFAPI_BASE}/${amfiCode}`, {
    headers: { 'accept': 'application/json' },
  });
  if (!r.ok) throw new Error(`mfapi ${amfiCode} HTTP ${r.status}`);
  const j: MfapiResponse = await r.json();
  const raw = j?.data ?? [];
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - HOT_DAYS);
  const cutoffIso = cutoff.toISOString().slice(0, 10);

  const rows: NavRow[] = [];
  for (const d of raw) {
    const iso = parseDate(d.date);
    if (!iso) continue;
    if (iso < cutoffIso) break;
    const nav = Number(d.nav);
    if (!Number.isFinite(nav) || nav <= 0) continue;
    rows.push({ amfi_code: amfiCode, nav_date: iso, nav });
  }
  return rows;
}

async function upsertNav(
  supabase: ReturnType<typeof createClient>,
  rows: NavRow[],
): Promise<void> {
  if (rows.length === 0) return;
  for (let i = 0; i < rows.length; i += 1000) {
    const chunk = rows.slice(i, i + 1000);
    const { error } = await supabase
      .from('nav_history')
      .upsert(chunk, { onConflict: 'amfi_code,nav_date' });
    if (error) throw new Error(`nav upsert: ${error.message}`);
  }
}

async function refreshReturns(
  supabase: ReturnType<typeof createClient>,
  codes: number[],
): Promise<number> {
  if (codes.length === 0) return 0;
  const { data, error } = await supabase.rpc(
    'refresh_short_window_returns_for_codes',
    { p_codes: codes },
  );
  if (error) throw new Error(`refresh_short_window_returns_for_codes: ${error.message}`);
  return Number(data ?? 0);
}

async function handleSingle(
  supabase: ReturnType<typeof createClient>,
  amfiCode: number,
) {
  const rows = await fetchMfapi(amfiCode);
  await upsertNav(supabase, rows);
  await refreshReturns(supabase, [amfiCode]);

  await supabase.rpc('promote_fund_to_warm', {
    p_amfi_code: amfiCode,
    p_reason: 'on_demand',
  });

  const { data: fund, error } = await supabase
    .from('fund_master')
    .select('amfi_code, fund_name, amc, category, sub_category, latest_nav, '
          + 'prev_nav, nav_date, return_7d, return_15d, return_1m, return_3m, '
          + 'return_6m, return_1y, return_3y, return_5y, aum_cr, expense_ratio, '
          + 'fund_rating, tracked_tier, tier_reasons')
    .eq('amfi_code', amfiCode)
    .maybeSingle();
  if (error) throw new Error(`fund_master fetch: ${error.message}`);

  return { ok: true, mode: 'single', amfi_code: amfiCode, nav_rows: rows.length, fund };
}

async function handlePrewarm(
  supabase: ReturnType<typeof createClient>,
  limit: number,
  perAmc: number,
) {
  const { data: picks, error: pickErr } = await supabase.rpc('pick_prewarm_batch', {
    p_limit: limit,
    p_per_amc: perAmc,
  });
  if (pickErr) throw new Error(`pick_prewarm_batch: ${pickErr.message}`);
  const list = (picks ?? []) as Array<{ amfi_code: number; amc: string }>;
  if (list.length === 0) {
    return { ok: true, mode: 'prewarm', picked: 0, fetched: 0, failed: 0 };
  }

  let fetched = 0;
  let failed = 0;
  const queue = [...list];
  const workers = Array.from({ length: PREWARM_CONCURRENCY }, async () => {
    while (queue.length > 0) {
      const p = queue.shift();
      if (!p) break;
      try {
        const rows = await fetchMfapi(p.amfi_code);
        await upsertNav(supabase, rows);
        fetched++;
      } catch (e) {
        console.error(`prewarm ${p.amfi_code} failed:`, (e as Error).message);
        failed++;
      }
    }
  });
  await Promise.all(workers);

  const okCodes = list.map((p) => p.amfi_code);
  if (okCodes.length > 0) {
    try {
      await refreshReturns(supabase, okCodes);
    } catch (e) {
      console.error('refreshReturns prewarm:', (e as Error).message);
    }
    await supabase.rpc('mark_prewarm_done', { p_amfi_codes: okCodes });
  }

  return { ok: true, mode: 'prewarm', picked: list.length, fetched, failed };
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'POST required' }),
      { status: 405, headers: CORS });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const mode = String(body?.mode ?? 'single');
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    if (mode === 'single') {
      const amfiCode = Number(body?.amfi_code);
      if (!Number.isFinite(amfiCode) || amfiCode <= 0) {
        return new Response(JSON.stringify({ error: 'amfi_code required' }),
          { status: 400, headers: CORS });
      }
      const result = await handleSingle(supabase, amfiCode);
      return new Response(JSON.stringify(result), { headers: CORS });
    }

    if (mode === 'prewarm') {
      const limit = Math.min(Math.max(Number(body?.limit ?? 30), 1), 100);
      const perAmc = Math.min(Math.max(Number(body?.per_amc ?? 3), 1), 10);
      const result = await handlePrewarm(supabase, limit, perAmc);
      return new Response(JSON.stringify(result), { headers: CORS });
    }

    return new Response(JSON.stringify({ error: `unknown mode: ${mode}` }),
      { status: 400, headers: CORS });
  } catch (e) {
    console.error('fetch-fund-ondemand error:', e);
    return new Response(JSON.stringify({ error: (e as Error).message }),
      { status: 500, headers: CORS });
  }
});
