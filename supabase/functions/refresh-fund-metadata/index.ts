// Precedence: AMFI > Kuvera. If returns_source='AMFI' and returns_updated_at < 7 days old,
// we skip writing return/AUM/benchmark/riskometer fields. Kuvera remains authoritative for
// expense_ratio, fund_managers, exit_load, min_investment, launch_date, fund_rating, portfolio_turnover.

/**
 * eVesh — Supabase Edge Function: refresh-fund-metadata
 *
 * Fetches rich fund metadata from mf.captnemo.in (Kuvera source) for all held funds.
 * Detects changes in critical fields and creates alerts:
 *  - Fund manager change
 *  - Expense ratio change (>0.05% delta)
 *  - Rating change (CRISIL or fund_rating)
 *  - AUM significant drop (>30%)
 *
 * Runs quarterly via pg_cron, or manually triggered.
 * Rate-limited to 1 request / 400ms to be respectful.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const CAPTNEMO_BASE = 'https://mf.captnemo.in';

// ─── Types ──────────────────────────────────────────────────────────────────

interface KuveraFund {
  ISIN?: string;
  aum?: number;                    // in lakhs
  category?: string;               // e.g. "Debt - Bonds"
  crisil_rating?: string;          // e.g. "Moderate Risk"
  detail_info?: string;            // AMC SID link
  expense_ratio?: string;          // e.g. "0.34"
  expense_ratio_date?: string;     // e.g. "2022-04-30"
  fund_category?: string;          // e.g. "Banking and PSU Fund"
  fund_house?: string;
  fund_manager?: string;           // semicolon-separated: "A; B; C"
  fund_name?: string;
  fund_rating?: number;            // 1-5
  fund_rating_date?: string;
  fund_type?: string;              // Equity, Debt, Hybrid, etc.
  investment_objective?: string;
  jan_31_nav?: number;             // NAV on Jan 31 2018 — grandfathering!
  lock_in_period?: number;         // days
  lump_min?: number;
  maturity_type?: string;          // "Open Ended", "Close Ended"
  name?: string;                   // full scheme name
  portfolio_turnover?: number | null;
  returns?: {
    date?: string;
    inception?: number;
    week_1?: number;
    year_1?: number;
    year_3?: number;
    year_5?: number;
  };
  sip_min?: number;
  start_date?: string;             // launch date
  tags?: string[];
  tax_period?: number;             // days for LTCG (365=equity, 1095=debt)
  volatility?: number;
}

interface Alert {
  amfi_code: number;
  alert_type: string;
  old_value: string | null;
  new_value: string | null;
  metadata?: Record<string, unknown>;
}

// ─── Main handler ───────────────────────────────────────────────────────────

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // ── Mode parsing ──────────────────────────────────────────────────────
    //   mode=held    (default) — only funds appearing in the transactions table
    //   mode=all     — full-universe pass, paginated via cursor
    //   cursor=<int> — exclusive lower bound on amfi_code (use the
    //                  `nextCursor` returned from the previous call)
    //   limit=<int>  — max funds to process in this invocation (default 200)
    let mode = 'held';
    let cursor = 0;
    let limitN = 200;
    if (req.method === 'POST') {
      try {
        const body = await req.json();
        if (body?.mode) mode = String(body.mode);
        if (body?.cursor != null) cursor = Number(body.cursor) || 0;
        if (body?.limit != null) limitN = Math.min(Number(body.limit) || 200, 500);
      } catch { /* ignore */ }
    } else {
      const u = new URL(req.url);
      if (u.searchParams.get('mode')) mode = u.searchParams.get('mode')!;
      if (u.searchParams.get('cursor')) cursor = Number(u.searchParams.get('cursor')!) || 0;
      if (u.searchParams.get('limit')) {
        limitN = Math.min(Number(u.searchParams.get('limit')!) || 200, 500);
      }
    }

    let amfiCodes: number[] = [];
    if (mode === 'all') {
      // Full-universe pass. Walk fund_master in amfi_code order so clients can
      // drive chunking via the returned `nextCursor`.
      const { data: rows, error: allErr } = await supabase
        .from('fund_master')
        .select('amfi_code')
        .eq('is_active', true)
        .gt('amfi_code', cursor)
        .order('amfi_code', { ascending: true })
        .limit(limitN);
      if (allErr) throw allErr;
      amfiCodes = (rows ?? []).map((r: any) => r.amfi_code).filter(Boolean);
    } else {
      // Held-funds-only pass (original behaviour)
      const { data: heldFunds, error: txError } = await supabase
        .from('transactions')
        .select('amfi_code')
        .not('amfi_code', 'is', null)
        .limit(500);
      if (txError) throw txError;
      amfiCodes = [...new Set(
        heldFunds?.map((r: any) => r.amfi_code).filter(Boolean) ?? []
      )];
    }

    // Get current fund_master data for change detection (include fund_name for Direct plan lookup)
    const { data: currentFunds } = await supabase
      .from('fund_master')
      .select('amfi_code, isin_growth, isin_div_reinvest, fund_name, plan_type, fund_managers, expense_ratio, crisil_rating, fund_rating, aum_cr')
      .in('amfi_code', amfiCodes);

    const currentMap = new Map(
      (currentFunds ?? []).map((f: any) => [f.amfi_code, f])
    );

    console.log(`Refreshing metadata for ${amfiCodes.length} held funds`);

    let updated = 0;
    let alertsCreated = 0;
    const errors: string[] = [];
    const allAlerts: Alert[] = [];

    for (const amfiCode of amfiCodes) {
      try {
        const current = currentMap.get(amfiCode);
        const isin = current?.isin_growth || current?.isin_div_reinvest;
        if (!isin) continue;

        // Try fetching from Kuvera — it may return an array or single object
        let kuveraData = await fetchKuveraData(isin);

        // If failed (Kuvera only has Direct plans), find the Direct plan ISIN
        if (!kuveraData && current?.fund_name) {
          const directIsin = await findDirectPlanIsin(supabase, current.fund_name, isin);
          if (directIsin) {
            kuveraData = await fetchKuveraData(directIsin);
            if (kuveraData) {
              console.log(`Used Direct plan ISIN ${directIsin} for ${current.fund_name}`);
            }
          }
        }

        if (!kuveraData) {
          await sleep(400);
          continue;
        }

        // Detect changes and create alerts
        processKuveraData(amfiCode, kuveraData, current, allAlerts);

        // Update fund_master
        await upsertFundMetadata(supabase, amfiCode, kuveraData);
        updated++;

        // Rate limiting — be respectful to captnemo
        await sleep(400);
      } catch (e) {
        errors.push(`AMFI ${amfiCode}: ${String(e)}`);
        console.error(`Metadata refresh failed for ${amfiCode}:`, e);
      }
    }

    // Batch insert alerts
    if (allAlerts.length > 0) {
      const alertRows = allAlerts.map(a => ({
        amfi_code: a.amfi_code,
        alert_type: a.alert_type,
        old_value: a.old_value,
        new_value: a.new_value,
        metadata: a.metadata ?? {},
        detected_at: new Date().toISOString(),
      }));

      const { error: alertErr } = await supabase
        .from('fund_alerts')
        .insert(alertRows);

      if (alertErr) {
        console.error('Alert insert error:', alertErr.message);
      } else {
        alertsCreated = alertRows.length;
        console.log(`Created ${alertsCreated} fund alerts`);
      }
    }

    console.log(`Updated metadata for ${updated}/${amfiCodes.length} funds. Alerts: ${alertsCreated}. Errors: ${errors.length}`);

    // For mode=all, return the cursor of the last amfi_code we *attempted*
    // so the client can resume on the next call.
    const nextCursor = amfiCodes.length > 0
      ? Math.max(...amfiCodes)
      : null;

    return new Response(
      JSON.stringify({
        success: true,
        mode,
        cursor,
        nextCursor,
        done: mode === 'all' ? amfiCodes.length < limitN : true,
        fundsProcessed: amfiCodes.length,
        updated,
        alertsCreated,
        alerts: allAlerts.map(a => ({
          amfi_code: a.amfi_code,
          type: a.alert_type,
          old: a.old_value,
          new: a.new_value,
        })),
        errors: errors.slice(0, 10),
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('refresh-fund-metadata error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

// ─── Kuvera fetch helpers ───────────────────────────────────────────────────

/** Fetch Kuvera data for an ISIN. Returns parsed fund object or null. */
async function fetchKuveraData(isin: string): Promise<KuveraFund | null> {
  try {
    const resp = await fetch(`${CAPTNEMO_BASE}/kuvera/${isin}`, { redirect: 'follow' });
    if (!resp.ok) return null;

    const raw = await resp.json();

    // Kuvera can return array [{...}] or single object {...} or {error: "..."}
    let data: KuveraFund;
    if (Array.isArray(raw)) {
      if (raw.length === 0) return null;
      data = raw[0];
    } else {
      data = raw;
    }

    // Check for error response
    if ((data as any).error) return null;
    if (!data.name && !data.fund_manager && !data.ISIN) return null;

    return data;
  } catch {
    return null;
  }
}

/**
 * Find Direct plan ISIN for a Regular plan fund.
 * Kuvera only indexes Direct plans, so for Regular plan holdings
 * we look up the corresponding Direct plan ISIN in fund_master.
 */
async function findDirectPlanIsin(
  supabase: ReturnType<typeof createClient>,
  fundName: string,
  regularIsin: string,
): Promise<string | null> {
  // Strategy 1: Replace "Regular" with "Direct" in fund name
  const directNameVariants = [
    fundName.replace(/REGULAR\s*PLAN/i, 'DIRECT PLAN'),
    fundName.replace(/Regular\s*Plan/i, 'Direct Plan'),
    fundName.replace(/-\s*Regular\s*/i, '- Direct '),
    fundName.replace(/Regular/i, 'Direct'),
  ];

  for (const variant of directNameVariants) {
    if (variant === fundName) continue; // no change, skip

    const { data } = await supabase
      .from('fund_master')
      .select('isin_growth')
      .ilike('fund_name', variant)
      .not('isin_growth', 'is', null)
      .limit(1)
      .single();

    if (data?.isin_growth && data.isin_growth !== regularIsin) {
      return data.isin_growth;
    }
  }

  // Strategy 2: Same AMC + similar name + Direct plan_type
  // Extract the core fund name (remove plan/growth/dividend suffixes)
  const coreName = fundName
    .replace(/\s*-\s*(Regular|Direct)\s*(Plan)?\s*/gi, '')
    .replace(/\s*-?\s*(Growth|Dividend|IDCW)\s*(Option|Plan)?\s*/gi, '')
    .trim();

  if (coreName.length > 10) {
    const { data } = await supabase
      .from('fund_master')
      .select('isin_growth')
      .ilike('fund_name', `%${coreName}%Direct%`)
      .not('isin_growth', 'is', null)
      .limit(1)
      .single();

    if (data?.isin_growth && data.isin_growth !== regularIsin) {
      return data.isin_growth;
    }
  }

  return null;
}

// ─── Change detection ───────────────────────────────────────────────────────

function processKuveraData(
  amfiCode: number,
  data: KuveraFund,
  current: any,
  alerts: Alert[],
) {
  if (!current) return;

  // 1. Fund manager change
  if (data.fund_manager) {
    const newManagers = data.fund_manager.split(';').map(s => s.trim()).filter(Boolean);
    const oldManagers: string[] = current.fund_managers ?? [];

    // Normalize for comparison
    const oldSet = new Set(oldManagers.map(m => m.toLowerCase().trim()));
    const newSet = new Set(newManagers.map(m => m.toLowerCase().trim()));

    const added = newManagers.filter(m => !oldSet.has(m.toLowerCase().trim()));
    const removed = oldManagers.filter(m => !newSet.has(m.toLowerCase().trim()));

    if ((added.length > 0 || removed.length > 0) && oldManagers.length > 0) {
      alerts.push({
        amfi_code: amfiCode,
        alert_type: 'fund_manager_change',
        old_value: oldManagers.join('; '),
        new_value: newManagers.join('; '),
        metadata: { added, removed },
      });
    }
  }

  // 2. Expense ratio change (>0.05% delta is significant)
  if (data.expense_ratio != null) {
    const newER = parseFloat(data.expense_ratio);
    const oldER = current.expense_ratio ? parseFloat(current.expense_ratio) : null;

    if (oldER != null && !isNaN(newER) && Math.abs(newER - oldER) > 0.05) {
      alerts.push({
        amfi_code: amfiCode,
        alert_type: 'expense_ratio_change',
        old_value: oldER.toFixed(2),
        new_value: newER.toFixed(2),
        metadata: {
          delta: (newER - oldER).toFixed(2),
          direction: newER > oldER ? 'increased' : 'decreased',
        },
      });
    }
  }

  // 3. CRISIL rating change
  if (data.crisil_rating && current.crisil_rating) {
    if (data.crisil_rating !== current.crisil_rating) {
      alerts.push({
        amfi_code: amfiCode,
        alert_type: 'crisil_rating_change',
        old_value: current.crisil_rating,
        new_value: data.crisil_rating,
      });
    }
  }

  // 4. Fund rating change (1-5 scale)
  if (data.fund_rating != null && current.fund_rating != null) {
    if (data.fund_rating !== current.fund_rating) {
      alerts.push({
        amfi_code: amfiCode,
        alert_type: 'fund_rating_change',
        old_value: String(current.fund_rating),
        new_value: String(data.fund_rating),
        metadata: {
          direction: data.fund_rating > current.fund_rating ? 'upgraded' : 'downgraded',
        },
      });
    }
  }

  // 5. AUM significant drop (>30% — could indicate large redemptions)
  if (data.aum != null && current.aum_cr != null) {
    const newAumCr = data.aum / 100; // Kuvera AUM is in lakhs → crore
    const oldAumCr = parseFloat(current.aum_cr);

    if (oldAumCr > 0 && newAumCr < oldAumCr * 0.7) {
      alerts.push({
        amfi_code: amfiCode,
        alert_type: 'aum_significant_drop',
        old_value: `₹${oldAumCr.toFixed(0)} Cr`,
        new_value: `₹${newAumCr.toFixed(0)} Cr`,
        metadata: {
          drop_pct: (((oldAumCr - newAumCr) / oldAumCr) * 100).toFixed(1),
        },
      });
    }
  }
}

// ─── Upsert fund_master with Kuvera data ────────────────────────────────────

async function upsertFundMetadata(
  supabase: ReturnType<typeof createClient>,
  amfiCode: number,
  data: KuveraFund,
) {
  // ── AMFI precedence check ──────────────────────────────────────────────
  // If AMFI has written returns/AUM/benchmark/riskometer fields within the
  // last 7 days, do NOT let Kuvera overwrite them. Kuvera stays authoritative
  // for expense_ratio, fund_managers, exit_load, min_investment, launch_date,
  // fund_rating, portfolio_turnover regardless.
  let amfiFresh = false;
  try {
    const { data: srcRow } = await supabase
      .from('fund_master')
      .select('returns_source, returns_updated_at')
      .eq('amfi_code', amfiCode)
      .maybeSingle();
    if (srcRow && (srcRow as any).returns_source === 'AMFI' && (srcRow as any).returns_updated_at) {
      const updatedAt = new Date((srcRow as any).returns_updated_at).getTime();
      const ageMs = Date.now() - updatedAt;
      if (ageMs < 7 * 24 * 60 * 60 * 1000) {
        amfiFresh = true;
      }
    }
  } catch (err) {
    // If the columns don't exist yet (migration 022 not applied), treat as non-fresh.
    console.warn(`AMFI precedence check failed for ${amfiCode}:`, (err as Error).message);
  }

  const update: Record<string, any> = {
    metadata_updated_at: new Date().toISOString(),
  };

  // Fund manager — split semicolon-separated into array (Kuvera-only, always written)
  if (data.fund_manager) {
    update.fund_managers = data.fund_manager.split(';').map(s => s.trim()).filter(Boolean);
    update.manager_updated_at = new Date().toISOString().slice(0, 10);
  }

  // Ratings — fund_rating is Kuvera-only (always), crisil_rating is AMFI-owned when fresh
  if (!amfiFresh && data.crisil_rating) update.crisil_rating = data.crisil_rating;
  if (data.fund_rating != null) update.fund_rating = data.fund_rating;
  if (data.fund_rating_date) update.fund_rating_date = data.fund_rating_date;

  // Expense ratio — Kuvera-only, always written
  if (data.expense_ratio != null) {
    update.expense_ratio = parseFloat(data.expense_ratio);
    update.er_source = 'kuvera';
    if (data.expense_ratio_date) update.er_updated_at = data.expense_ratio_date;
  }

  // AUM (Kuvera provides in lakhs → convert to crore) — skipped if AMFI fresh
  if (!amfiFresh && data.aum != null) update.aum_cr = data.aum / 100;

  // Returns — skipped if AMFI fresh
  if (!amfiFresh && data.returns) {
    if (data.returns.week_1 != null) update.return_1w = data.returns.week_1;
    if (data.returns.year_1 != null) update.return_1y = data.returns.year_1;
    if (data.returns.year_3 != null) update.return_3y = data.returns.year_3;
    if (data.returns.year_5 != null) update.return_5y = data.returns.year_5;
    if (data.returns.inception != null) update.return_inception = data.returns.inception;
  }

  // Volatility — skipped if AMFI fresh. portfolio_turnover is Kuvera-only (always).
  if (!amfiFresh && data.volatility != null) update.volatility_1y = data.volatility;
  if (data.portfolio_turnover != null) update.portfolio_turnover = data.portfolio_turnover;

  // If Kuvera actually wrote any of the precedence-governed fields, tag the
  // row so the next AMFI run can cleanly upgrade it.
  if (!amfiFresh && (
    update.aum_cr != null ||
    update.return_1y != null ||
    update.return_3y != null ||
    update.return_5y != null ||
    update.return_1w != null ||
    update.return_inception != null ||
    update.volatility_1y != null ||
    update.crisil_rating != null
  )) {
    update.returns_source = 'kuvera';
    update.returns_updated_at = new Date().toISOString();
  }

  // Categories
  if (data.fund_category) update.fund_category = data.fund_category;
  if (data.category) update.sub_category = data.category;
  if (data.fund_type) update.fund_type = data.fund_type;

  // ── AMFI category mapping (SEBI 2018) ───────────────────────────────────
  // Resolve sub_category/fund_category → amfi_category_id via the
  // match_amfi_category() helper, then attach tier1/tier2 benchmark names.
  // Benchmark fields are skipped if AMFI is the fresh authority for returns.
  try {
    const lookupText = data.category || data.fund_category || '';
    if (lookupText) {
      const { data: matchData } = await supabase.rpc('match_amfi_category', {
        p_text: lookupText,
      });
      const matchedId = (matchData as string | null) ?? null;
      if (matchedId) {
        update.amfi_category_id = matchedId;
        if (!amfiFresh) {
          const { data: catRow } = await supabase
            .from('amfi_category')
            .select('tier1_benchmark, tier2_benchmark')
            .eq('id', matchedId)
            .maybeSingle();
          if (catRow) {
            update.benchmark_tier1 = (catRow as any).tier1_benchmark ?? null;
            update.benchmark_tier2 = (catRow as any).tier2_benchmark ?? null;
          }
        }
      }
    }
  } catch (err) {
    console.warn(`amfi_category lookup failed for ${amfiCode}:`, (err as Error).message);
  }

  // Investment details
  if (data.investment_objective) update.investment_objective = data.investment_objective;
  if (data.maturity_type) update.maturity_type = data.maturity_type;
  if (data.lock_in_period != null) update.lock_in_period = data.lock_in_period;
  if (data.tax_period != null) update.tax_period = data.tax_period;
  if (data.detail_info) update.detail_info = data.detail_info;
  if (data.tags && data.tags.length > 0) update.tags = data.tags;

  // Minimum investment
  if (data.lump_min != null) update.min_investment = data.lump_min;
  if (data.sip_min != null) update.min_sip_amount = data.sip_min;

  // Launch date
  if (data.start_date) update.launch_date = data.start_date;

  // Jan 31 2018 NAV — critical for grandfathering calculation
  if (data.jan_31_nav != null) update.jan_31_nav = data.jan_31_nav;

  const { error } = await supabase
    .from('fund_master')
    .update(update)
    .eq('amfi_code', amfiCode);

  if (error) {
    console.error(`Update failed for ${amfiCode}:`, error.message);
  }
}

function sleep(ms: number) {
  return new Promise(r => setTimeout(r, ms));
}
