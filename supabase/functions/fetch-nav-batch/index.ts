/**
 * eVesh — Supabase Edge Function: fetch-nav-batch
 *
 * Responsibilities:
 * 1. (mode: "latest" or default) Fetch AMFI NAVAll.txt → update fund_master.latest_nav for all funds
 * 2. (mode: "seed") Initial full seeding of fund_master with all ~2000+ Indian MFs
 * 3. (mode: "history") Fetch full historical NAV from mfapi.in for all held funds → populate nav_history
 *
 * Called by:
 *  - pg_cron: daily at 22:00 IST (16:30 UTC) for latest NAV
 *  - pg_cron: weekly Sunday 06:00 IST for history refresh
 *  - Manual trigger for initial seeding
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const AMFI_NAV_URL = 'https://portal.amfiindia.com/spages/NAVAll.txt';
const MFAPI_BASE = 'https://api.mfapi.in/mf';
const CAPTNEMO_BASE = 'https://mf.captnemo.in';

interface FundMasterRow {
  amfi_code: number;
  isin_growth?: string;
  isin_div_reinvest?: string;
  fund_name: string;
  amc?: string;
  category?: string;
  fund_type?: string;
  tax_category?: string;
  plan_type?: string;
  latest_nav?: number;
  prev_nav?: number;
  nav_date?: string;
  nav_30d_high?: number;
}

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body = req.method === 'POST' ? await req.json().catch(() => ({})) : {};
    const mode = body.mode || 'latest';

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    if (mode === 'seed' || mode === 'latest') {
      await updateFromAmfiNavAll(supabase, mode === 'seed');

      // On daily refresh: also append today's NAV to nav_history for held funds
      if (mode === 'latest') {
        try {
          await appendDailyNavToHistory(supabase);
        } catch (e) {
          console.error('appendDailyNavToHistory error (non-fatal):', e);
        }
      }

      return new Response(JSON.stringify({ success: true, mode }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (mode === 'history') {
      const count = await fetchHistoryForHeldFunds(supabase);
      return new Response(JSON.stringify({ success: true, mode: 'history', fundsUpdated: count, timestamp: new Date().toISOString() }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (mode === 'single') {
      // On-demand history fetch for a single AMFI code (used by the screener
      // fund-detail screen so risk metrics work for any fund, not just held).
      const amfiCode = Number(body.amfi_code);
      if (!Number.isFinite(amfiCode)) {
        return new Response(JSON.stringify({ error: 'amfi_code required' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
      const points = await fetchAndStoreNavHistory(supabase, amfiCode);
      return new Response(
        JSON.stringify({ success: true, mode: 'single', amfi_code: amfiCode, points }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    return new Response(JSON.stringify({ error: 'Unknown mode' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('fetch-nav-batch error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

// ─── Parse and upsert AMFI NAVAll.txt ────────────────────────────────────────
async function updateFromAmfiNavAll(supabase: ReturnType<typeof createClient>, isSeed: boolean) {
  console.log('Fetching AMFI NAVAll.txt...');
  const response = await fetch(AMFI_NAV_URL);
  if (!response.ok) throw new Error(`AMFI fetch failed: ${response.status}`);
  const text = await response.text();

  const rows = parseAmfiNavAll(text);
  console.log(`Parsed ${rows.length} fund rows from AMFI NAVAll.txt`);

  // Batch upsert in chunks of 500
  const BATCH = 500;
  let updated = 0;
  const now = new Date().toISOString();

  if (!isSeed) {
    // Daily refresh: shift latest_nav → prev_nav in one SQL call
    console.log('Shifting latest_nav → prev_nav...');
    const { error: shiftErr } = await supabase.rpc('shift_nav_to_prev');
    if (shiftErr) console.error('shift_nav_to_prev error:', shiftErr.message);
  }

  for (let i = 0; i < rows.length; i += BATCH) {
    const chunk = rows.slice(i, i + BATCH);

    if (isSeed) {
      // On seed: full upsert with all metadata
      const upsertData = chunk.map((row) => ({
        amfi_code: row.amfi_code,
        fund_name: row.fund_name,
        isin_growth: row.isin_growth,
        isin_div_reinvest: row.isin_div_reinvest,
        amc: row.amc,
        category: row.category,
        plan_type: row.plan_type,
        fund_type: row.fund_type,
        tax_category: row.tax_category,
        latest_nav: row.latest_nav,
        nav_date: row.nav_date,
        is_active: true,
        nav_updated_at: now,
      }));

      const { error } = await supabase
        .from('fund_master')
        .upsert(upsertData, {
          onConflict: 'amfi_code',
          ignoreDuplicates: false,
        });
      if (error) console.error('Seed upsert error:', error.message);
    } else {
      // Daily refresh: batch upsert NAV data only (prev_nav already shifted)
      const upsertData = chunk
        .filter((r) => r.latest_nav != null)
        .map((row) => ({
          amfi_code: row.amfi_code,
          fund_name: row.fund_name,
          isin_growth: row.isin_growth,
          latest_nav: row.latest_nav,
          nav_date: row.nav_date,
          nav_updated_at: now,
        }));

      if (upsertData.length > 0) {
        const { error } = await supabase
          .from('fund_master')
          .upsert(upsertData, { onConflict: 'amfi_code' });
        if (error) console.error('Daily upsert error:', error.message);
      }
    }
    updated += chunk.length;
  }

  if (!isSeed) {
    // Update nav_30d_high in one SQL call
    console.log('Updating nav_30d_high...');
    const { error: highErr } = await supabase.rpc('update_nav_30d_high');
    if (highErr) console.error('update_nav_30d_high error:', highErr.message);
  }

  console.log(`Updated ${updated} funds`);
}

// ─── Parse AMFI NAVAll.txt format ────────────────────────────────────────────
// Format (semicolon-separated, with section headers):
// Scheme Code;ISIN Div Payout/ ISIN Growth;ISIN Div Reinvestment;Scheme Name;Net Asset Value;Date
// Section headers: "Open Ended Schemes(Debt Scheme - Banking and PSU Fund);"
function parseAmfiNavAll(text: string): FundMasterRow[] {
  const lines = text.split('\n');
  const rows: FundMasterRow[] = [];
  let currentCategory = '';
  let currentAmc = '';

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed) continue;

    // Section header: "Scheme Code;..."  — the header row
    if (trimmed.startsWith('Scheme Code;')) continue;

    // AMC/Category header — no semicolons in the main fields, but these lines
    // contain the mutual fund house name
    const parts = trimmed.split(';');
    if (parts.length < 5) {
      // Could be an AMC name or category line
      if (trimmed.includes('Fund') || trimmed.includes('Mutual') || trimmed.includes('AMC')) {
        currentAmc = trimmed.replace(/\s*\(.*\)\s*$/, '').trim();
      }
      if (trimmed.startsWith('Open Ended') || trimmed.startsWith('Close Ended') || trimmed.startsWith('Interval')) {
        currentCategory = extractCategory(trimmed);
      }
      continue;
    }

    const [codeStr, isinGrowth, isinDiv, schemeName, navStr, dateStr] = parts;
    const amfiCode = parseInt(codeStr.trim(), 10);
    if (isNaN(amfiCode)) continue;

    const nav = parseFloat(navStr?.trim() ?? '');
    const navDate = parseDateDDMMYYYY(dateStr?.trim() ?? '');

    // Heuristic: detect Plan type and fund type from scheme name
    const planType = schemeName?.includes('- Dir') || schemeName?.includes('Direct') ? 'Direct' : 'Regular';
    const fundType = inferFundType(currentCategory);
    const taxCategory = inferTaxCategory(currentCategory, fundType);

    rows.push({
      amfi_code: amfiCode,
      isin_growth: isinGrowth?.trim() || undefined,
      isin_div_reinvest: isinDiv?.trim() || undefined,
      fund_name: schemeName?.trim() ?? `Fund ${amfiCode}`,
      amc: currentAmc || undefined,
      category: currentCategory || undefined,
      fund_type: fundType,
      tax_category: taxCategory,
      plan_type: planType,
      latest_nav: isNaN(nav) ? undefined : nav,
      nav_date: navDate || undefined,
    });
  }

  return rows;
}

function extractCategory(line: string): string {
  const match = line.match(/\(([^)]+)\)/);
  return match ? match[1].trim() : line.trim();
}

function parseDateDDMMYYYY(s: string): string | undefined {
  if (!s) return undefined;
  const parts = s.split('-');
  if (parts.length === 3 && parts[2].length === 4) {
    return `${parts[2]}-${parts[1].padStart(2, '0')}-${parts[0].padStart(2, '0')}`;
  }
  // Try yyyy-mm-dd
  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
  return undefined;
}

function inferFundType(category: string): string {
  const c = category.toLowerCase();
  if (c.includes('debt') || c.includes('liquid') || c.includes('money market') || c.includes('overnight')) return 'Debt';
  if (c.includes('equity')) return 'Equity';
  if (c.includes('hybrid') || c.includes('balanced')) return 'Hybrid';
  if (c.includes('gold') || c.includes('commodity')) return 'Gold';
  if (c.includes('index') || c.includes('etf')) return 'Index';
  if (c.includes('international') || c.includes('overseas')) return 'InternationalFOF';
  return 'Other';
}

function inferTaxCategory(category: string, fundType: string): string {
  const c = category.toLowerCase();
  if (fundType === 'Gold') return 'Gold';
  if (fundType === 'Debt' || fundType === 'InternationalFOF') return 'Debt';
  if (fundType === 'Equity') {
    if (c.includes('flexi') || c.includes('large') || c.includes('mid') || c.includes('small') || c.includes('multi') || c.includes('elss')) {
      return 'Equity';
    }
    return 'Equity';
  }
  if (fundType === 'Hybrid') {
    if (c.includes('aggressive') || c.includes('equity savings')) return 'Hybrid-E';
    return 'Hybrid-D';
  }
  return 'Debt';
}

// ─── Append today's NAV to nav_history (runs during daily "latest" mode) ──────
async function appendDailyNavToHistory(supabase: ReturnType<typeof createClient>): Promise<void> {
  // Get all AMFI codes that have transactions (held funds)
  const allAmfiCodes = new Set<number>();
  let offset = 0;
  const PAGE = 1000;
  while (true) {
    const { data, error } = await supabase
      .from('transactions')
      .select('amfi_code')
      .not('amfi_code', 'is', null)
      .range(offset, offset + PAGE - 1);
    if (error) break;
    if (!data || data.length === 0) break;
    for (const r of data) {
      if (r.amfi_code) allAmfiCodes.add(r.amfi_code);
    }
    if (data.length < PAGE) break;
    offset += PAGE;
  }

  if (allAmfiCodes.size === 0) return;

  // Get today's NAV from fund_master for these funds
  const codes = [...allAmfiCodes];
  const BATCH = 100;
  const historyRows: Array<{ amfi_code: number; nav_date: string; nav: number }> = [];

  for (let i = 0; i < codes.length; i += BATCH) {
    const chunk = codes.slice(i, i + BATCH);
    const { data: funds } = await supabase
      .from('fund_master')
      .select('amfi_code, latest_nav, nav_date')
      .in('amfi_code', chunk);

    if (funds) {
      for (const f of funds) {
        if (f.latest_nav && f.nav_date) {
          historyRows.push({
            amfi_code: f.amfi_code,
            nav_date: f.nav_date,
            nav: f.latest_nav,
          });
        }
      }
    }
  }

  if (historyRows.length === 0) return;

  // Upsert into nav_history (ignore duplicates — same date won't overwrite)
  const UPSERT_BATCH = 500;
  for (let i = 0; i < historyRows.length; i += UPSERT_BATCH) {
    const chunk = historyRows.slice(i, i + UPSERT_BATCH);
    const { error } = await supabase.from('nav_history').upsert(chunk, {
      onConflict: 'amfi_code,nav_date',
      ignoreDuplicates: true,
    });
    if (error) console.error('Daily nav_history append error:', error.message);
  }

  console.log(`Appended ${historyRows.length} daily NAV points to nav_history`);
}

// ─── Fetch full NAV history for all held funds ────────────────────────────────
async function fetchHistoryForHeldFunds(supabase: ReturnType<typeof createClient>): Promise<number> {
  // Get ALL distinct AMFI codes from transactions (no limit)
  const allAmfiCodes = new Set<number>();
  let offset = 0;
  const PAGE = 1000;
  while (true) {
    const { data, error } = await supabase
      .from('transactions')
      .select('amfi_code')
      .not('amfi_code', 'is', null)
      .range(offset, offset + PAGE - 1);
    if (error) throw error;
    if (!data || data.length === 0) break;
    for (const r of data) {
      if (r.amfi_code) allAmfiCodes.add(r.amfi_code);
    }
    if (data.length < PAGE) break;
    offset += PAGE;
  }

  const amfiCodes = [...allAmfiCodes];
  console.log(`Fetching history for ${amfiCodes.length} held funds`);

  const results: Array<{ amfi_code: number; status: string; points: number; error?: string }> = [];
  let updated = 0;

  for (const amfiCode of amfiCodes) {
    try {
      const points = await fetchAndStoreNavHistory(supabase, amfiCode);
      results.push({ amfi_code: amfiCode, status: 'ok', points });
      if (points > 0) updated++;
    } catch (e) {
      const errMsg = String(e);
      console.error(`History fetch failed for AMFI ${amfiCode}: ${errMsg}`);
      results.push({ amfi_code: amfiCode, status: 'error', points: 0, error: errMsg });
    }
    // Rate limiting: 300ms between requests (be gentle on mfapi.in)
    await new Promise((r) => setTimeout(r, 300));
  }

  // Log summary
  const ok = results.filter(r => r.status === 'ok').length;
  const failed = results.filter(r => r.status === 'error').length;
  const totalPoints = results.reduce((s, r) => s + r.points, 0);
  console.log(`NAV history complete: ${ok} funds updated (${totalPoints} new points), ${failed} failed`);
  if (failed > 0) {
    console.warn('Failed funds:', results.filter(r => r.status === 'error').map(r => `${r.amfi_code}: ${r.error}`));
  }

  return updated;
}

/** Fetch with retry (up to 3 attempts with exponential backoff) */
async function fetchWithRetry(url: string, maxRetries = 3): Promise<Response> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const resp = await fetch(url);
      if (resp.ok) return resp;
      // 429 Too Many Requests → wait longer
      if (resp.status === 429 && attempt < maxRetries) {
        const waitMs = 2000 * attempt;
        console.warn(`Rate limited on ${url}, waiting ${waitMs}ms (attempt ${attempt}/${maxRetries})`);
        await new Promise(r => setTimeout(r, waitMs));
        continue;
      }
      // 5xx → retry
      if (resp.status >= 500 && attempt < maxRetries) {
        await new Promise(r => setTimeout(r, 1000 * attempt));
        continue;
      }
      return resp; // Return non-ok response for caller to handle
    } catch (e) {
      if (attempt === maxRetries) throw e;
      console.warn(`Fetch attempt ${attempt} failed for ${url}: ${e}. Retrying...`);
      await new Promise(r => setTimeout(r, 1000 * attempt));
    }
  }
  throw new Error(`All ${maxRetries} retries failed for ${url}`);
}

async function fetchAndStoreNavHistory(
  supabase: ReturnType<typeof createClient>,
  amfiCode: number
): Promise<number> {
  // ── Decide between incremental fetch and full backfill ──
  // Funds with ample history (≥ 200 rows) get incremental updates only —
  // anything less and we treat the table as a stub and pull the full history
  // from mfapi. This catches the common case where the daily "latest" cron
  // appended a single NAV row, fooling the old incremental logic into
  // believing the fund was already backfilled.
  const { count: existingCount } = await supabase
    .from('nav_history')
    .select('amfi_code', { count: 'exact', head: true })
    .eq('amfi_code', amfiCode);

  const FULL_BACKFILL_THRESHOLD = 200;
  let lastStoredDate: string | null = null;

  if ((existingCount ?? 0) >= FULL_BACKFILL_THRESHOLD) {
    const { data: latestRow } = await supabase
      .from('nav_history')
      .select('nav_date')
      .eq('amfi_code', amfiCode)
      .order('nav_date', { ascending: false })
      .limit(1)
      .single();
    lastStoredDate = latestRow?.nav_date ?? null;
  }
  // Otherwise lastStoredDate stays null → triggers a full backfill below.

  let navPoints: Array<{ date: string; nav: number }> = [];

  // ── Try mf.captnemo.in first ──
  try {
    const { data: fund } = await supabase
      .from('fund_master')
      .select('isin_growth')
      .eq('amfi_code', amfiCode)
      .single();

    if (fund?.isin_growth) {
      const captnemoUrl = `${CAPTNEMO_BASE}/nav/${fund.isin_growth}`;
      const resp = await fetchWithRetry(captnemoUrl);
      if (resp.ok) {
        const data = await resp.json();
        if (data?.historical_nav) {
          navPoints = data.historical_nav
            .map(([dateStr, navStr]: [string, string]) => ({
              date: parseDateDDMMYYYY(dateStr) || dateStr,
              nav: parseFloat(navStr),
            }))
            .filter((p: any) => p.date && !isNaN(p.nav));
        }
      }
    }
  } catch (e) {
    console.warn(`Captnemo failed for ${amfiCode}, trying mfapi:`, e);
  }

  // ── Fallback: mfapi.in (with date filter for incremental fetch) ──
  if (navPoints.length === 0) {
    let url = `${MFAPI_BASE}/${amfiCode}`;
    // If we already have data, only fetch new points (after last stored date)
    if (lastStoredDate) {
      // Add 1 day to avoid re-fetching the last stored date
      const d = new Date(lastStoredDate);
      d.setDate(d.getDate() + 1);
      const startDate = d.toISOString().split('T')[0]; // YYYY-MM-DD
      const endDate = new Date().toISOString().split('T')[0];
      url = `${MFAPI_BASE}/${amfiCode}?startDate=${startDate}&endDate=${endDate}`;
    }

    const resp = await fetchWithRetry(url);
    if (resp.ok) {
      const data = await resp.json();
      if (data?.status === 'SUCCESS') {
        navPoints = (data?.data || [])
          .map((p: { date: string; nav: string }) => ({
            date: parseDateDDMMYYYY(p.date) || p.date,
            nav: parseFloat(p.nav),
          }))
          .filter((p: any) => p.date && !isNaN(p.nav));
      } else {
        console.warn(`mfapi returned non-SUCCESS for ${amfiCode}:`, data?.status);
      }
    }
  }

  // ── Filter: only keep points newer than what's stored (incremental) ──
  if (lastStoredDate && navPoints.length > 0) {
    navPoints = navPoints.filter(p => p.date > lastStoredDate);
  }

  if (navPoints.length === 0) {
    // Already up to date
    return 0;
  }

  // ── Upsert nav_history in batches ──
  const BATCH = 500;
  let insertErrors = 0;
  for (let i = 0; i < navPoints.length; i += BATCH) {
    const chunk = navPoints.slice(i, i + BATCH);
    const { error } = await supabase.from('nav_history').upsert(
      chunk.map((p) => ({
        amfi_code: amfiCode,
        nav_date: p.date,
        nav: p.nav,
      })),
      { onConflict: 'amfi_code,nav_date', ignoreDuplicates: true }
    );
    if (error) {
      console.error(`DB upsert error for AMFI ${amfiCode} (batch ${i}):`, error.message);
      insertErrors++;
    }
  }

  console.log(`AMFI ${amfiCode}: stored ${navPoints.length} new NAV points${insertErrors > 0 ? ` (${insertErrors} batch errors)` : ''}`);

  // ── Backfill launch_date from earliest NAV row when missing ──
  // Kuvera only indexes Direct plans, so Regular-plan funds never get a
  // proper launch_date from the metadata refresh. The earliest date in
  // nav_history is a faithful proxy for fund inception (mfapi serves the
  // full history back to launch). We only set this when the column is null
  // so we never clobber a Kuvera-sourced value.
  if (lastStoredDate == null && navPoints.length > 0) {
    try {
      const earliest = navPoints
        .map((p) => p.date)
        .sort()[0];
      const { data: fmRow } = await supabase
        .from('fund_master')
        .select('launch_date')
        .eq('amfi_code', amfiCode)
        .maybeSingle();
      if (fmRow && (fmRow as any).launch_date == null) {
        await supabase
          .from('fund_master')
          .update({ launch_date: earliest })
          .eq('amfi_code', amfiCode);
      }
    } catch (e) {
      console.warn(`launch_date backfill failed for ${amfiCode}:`, (e as Error).message);
    }
  }

  return navPoints.length;
}
