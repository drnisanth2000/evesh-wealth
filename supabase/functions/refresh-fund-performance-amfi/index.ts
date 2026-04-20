/**
 * eVesh — Supabase Edge Function: refresh-fund-performance-amfi
 *
 * Pulls daily fund performance data directly from AMFI's official polling API
 * (the same backing API used by www.amfiindia.com's Fund Performance screen)
 * and upserts it into fund_master for the smart screener.
 *
 * Endpoint base: https://www.amfiindia.com/gateway/pollingsebi/api/amfi/
 *   GET  /isHoliday
 *   GET  /fundperformancefilters
 *   POST /getsubcategory
 *   POST /fundperformance
 *
 * maturityType:  1=Open Ended, 2=Close Ended, 3=Interval
 * category:      integer id, resolved at runtime from /fundperformancefilters
 * mfid:          0 = all AMCs
 *
 * The function fans out across every (maturityType, category, subCategory)
 * combination with at most CONCURRENCY parallel HTTP calls, aggregates
 * the rows, dedupes by schemeCode and bulk-upserts.
 *
 * Concurrency is capped at 4 and each request has 250 ms of jitter.
 *
 * The legacy refresh-fund-metadata Kuvera function remains in place as a
 * fallback — AMFI rows are flagged with returns_source = 'AMFI' so they
 * take priority in the screener UI.
 */

import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const AMFI_BASE = 'https://www.amfiindia.com/gateway/pollingsebi/api/amfi';
const CONCURRENCY = 4;
const JITTER_MAX_MS = 250;
const UPSERT_CHUNK = 500;

// ─── Types ──────────────────────────────────────────────────────────────────

// Confirmed actual response shape from
// POST /gateway/pollingsebi/api/amfi/fundperformance:
// the row exposes the *family* scheme name (no plan suffix), one row per
// (subCategory, scheme family) pair, with Regular + Direct + Benchmark
// columns side-by-side. There is NO schemeCode in the response — we have
// to match by normalized scheme name against fund_master.fund_name.
export interface AmfiFundPerformanceRow {
  schemeName: string;
  benchmark?: string | null;
  riskometerScheme?: string | null;
  riskometerBenchmark?: string | null;

  navDate?: string | null;
  navRegular?: number | string | null;
  navDirect?: number | string | null;
  preNavRegular?: number | string | null;
  preNavDirect?: number | string | null;
  preNavDate?: string | null;

  // Returns — Regular
  return7DaysRegular?: number | string | null;
  return15DaysRegular?: number | string | null;
  return1MonthRegular?: number | string | null;
  return3MonthRegular?: number | string | null;
  return6MonthRegular?: number | string | null;
  return1YearRegular?: number | string | null;
  return3YearRegular?: number | string | null;
  return5YearRegular?: number | string | null;
  return10YearRegular?: number | string | null;
  returnSinceLaunchRegular?: number | string | null;

  // Returns — Direct
  return7DaysDirect?: number | string | null;
  return15DaysDirect?: number | string | null;
  return1MonthDirect?: number | string | null;
  return3MonthDirect?: number | string | null;
  return6MonthDirect?: number | string | null;
  return1YearDirect?: number | string | null;
  return3YearDirect?: number | string | null;
  return5YearDirect?: number | string | null;
  return10YearDirect?: number | string | null;
  returnSinceLaunchDirect?: number | string | null;

  // Returns — Benchmark
  return7DaysBenchmark?: number | string | null;
  return15DaysBenchmark?: number | string | null;
  return1MonthBenchmark?: number | string | null;
  return3MonthBenchmark?: number | string | null;
  return6MonthBenchmark?: number | string | null;
  return1YearBenchmark?: number | string | null;
  return3YearBenchmark?: number | string | null;
  return5YearBenchmark?: number | string | null;
  return10YearBenchmark?: number | string | null;
  returnSinceLaunchBenchmarkRegular?: number | string | null;
  returnSinceLaunchBenchmarkDirect?: number | string | null;

  // Information ratios
  ir1YrRegular?: number | string | null;
  ir3YrRegular?: number | string | null;
  ir5YrRegular?: number | string | null;
  ir10YrRegular?: number | string | null;
  ir1YrDirect?: number | string | null;
  ir3YrDirect?: number | string | null;
  ir5YrDirect?: number | string | null;
  ir10YrDirect?: number | string | null;

  // AUM (in crore)
  dailyAUM?: number | string | null;
  preMonthAUM?: number | string | null;
  preMonthAvgAUM?: number | string | null;
  specialCharAum?: unknown;

  [key: string]: unknown;
}

interface FundPerfFilter {
  categoryId: number;
  categoryName: string;
  maturityType: number;
}

interface SubCategory {
  subCategoryId: number;
  subCategoryName: string;
}

interface RunError {
  ctx: string;
  message: string;
}

// ─── Main handler ───────────────────────────────────────────────────────────

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
  const errors: RunError[] = [];

  try {
    // 1. Compute report date — previous business day (skip Sat/Sun).
    //    AMFI publishes T+1 morning, so today's "Go" actually loads yesterday's NAVs.
    const reportDate = previousBusinessDay(new Date());
    const reportDateStr = formatDdMmmYyyy(reportDate);

    // 2. Discover filters (maturityType × category)
    const filters = await fetchFilters();
    console.log(`Discovered ${filters.length} (maturityType, category) pairs`);

    // 3. Expand subcategories
    const combos: {
      maturityType: number;
      categoryId: number;
      subCategoryId: number;
      categoryName: string;
      subCategoryName: string;
    }[] = [];

    await runWithConcurrency(filters, CONCURRENCY, async (f) => {
      try {
        const subs = await fetchSubCategories(f.maturityType, f.categoryId);
        for (const s of subs) {
          combos.push({
            maturityType: f.maturityType,
            categoryId: f.categoryId,
            subCategoryId: s.subCategoryId,
            categoryName: f.categoryName,
            subCategoryName: s.subCategoryName,
          });
        }
      } catch (e) {
        errors.push({
          ctx: `subcat mt=${f.maturityType} cat=${f.categoryId}`,
          message: String(e),
        });
      }
    });

    console.log(`Expanded to ${combos.length} (maturity, category, subcategory) combos`);

    // 4. Fetch performance rows for each combo. Carry forward the
    //    category/subCategory names from the loop context since the row
    //    payload itself doesn't include them.
    type EnrichedRow = {
      row: AmfiFundPerformanceRow;
      categoryName: string;
      subCategoryName: string;
    };
    const allRows: EnrichedRow[] = [];
    await runWithConcurrency(combos, CONCURRENCY, async (c) => {
      try {
        const rows = await fetchFundPerformance({
          maturityType: c.maturityType,
          category: c.categoryId,
          subCategory: c.subCategoryId,
          reportDate: reportDateStr,
        });
        for (const r of rows) {
          allRows.push({
            row: r,
            categoryName: c.categoryName,
            subCategoryName: c.subCategoryName,
          });
        }
      } catch (e) {
        errors.push({
          ctx: `perf mt=${c.maturityType} cat=${c.categoryId} sub=${c.subCategoryId}`,
          message: String(e),
        });
      }
    });

    // 5. Dedupe by normalized scheme name (one AMFI row per scheme family)
    const byFamily = new Map<string, EnrichedRow>();
    for (const e of allRows) {
      const name = (e.row as Record<string, unknown>).schemeName as string | undefined;
      if (!name) continue;
      const key = normalizeSchemeName(name);
      if (!byFamily.has(key)) byFamily.set(key, e);
    }
    console.log(`Aggregated ${allRows.length} rows → ${byFamily.size} unique scheme families`);

    // 6. Pull the entire fund_master scheme list once and build a name index.
    //    One AMFI family row maps to N fund_master rows (Regular + Direct
    //    plans, Growth + IDCW options, etc).
    const fundMasterIndex = await buildFundMasterIndex(supabase);
    console.log(`fund_master index: ${fundMasterIndex.size} family keys`);

    // 7. For each AMFI family row, look up matching fund_master rows and
    //    emit one upsert payload per row, choosing Regular vs Direct columns
    //    based on the plan_type.
    const nowIso = new Date().toISOString();
    const payload: Record<string, unknown>[] = [];
    let unmatched = 0;

    let skippedIncome = 0;
    for (const [key, e] of byFamily) {
      const matches = fundMasterIndex.get(key);
      if (!matches || matches.length === 0) {
        unmatched += 1;
        continue;
      }
      for (const m of matches) {
        // Skip IDCW/Dividend variants — see isIncomeDistributionVariant
        // doc-comment for the catastrophic prev_nav corruption this prevents.
        if (isIncomeDistributionVariant(m.fundName)) {
          skippedIncome += 1;
          continue;
        }
        payload.push(
          toFundMasterUpdate(
            e.row,
            m.amfiCode,
            m.planType,
            m.fundName,
            e.categoryName,
            e.subCategoryName,
            nowIso,
          ),
        );
      }
    }
    console.log(`Skipped ${skippedIncome} IDCW/Dividend rows from AMFI refresh`);

    console.log(
      `Built ${payload.length} upsert rows; ${unmatched} families had no fund_master match`,
    );

    let updated = 0;
    for (let i = 0; i < payload.length; i += UPSERT_CHUNK) {
      const chunk = payload.slice(i, i + UPSERT_CHUNK);
      const { error } = await supabase
        .from('fund_master')
        .upsert(chunk, { onConflict: 'amfi_code' });
      if (error) {
        errors.push({ ctx: `upsert chunk ${i}`, message: error.message });
      } else {
        updated += chunk.length;
      }
    }

    // 8. Refresh amfi_category_id / benchmark_tier1/2 via RPC.
    const uniqueSubCats = new Set<string>();
    for (const e of byFamily.values()) {
      if (e.subCategoryName) uniqueSubCats.add(e.subCategoryName);
    }
    for (const subCat of uniqueSubCats) {
      try {
        const { data: matchedId } = await supabase.rpc('match_amfi_category', {
          p_text: subCat,
        });
        if (!matchedId) continue;
        const { data: catRow } = await supabase
          .from('amfi_category')
          .select('tier1_benchmark, tier2_benchmark')
          .eq('id', matchedId as string)
          .maybeSingle();
        await supabase
          .from('fund_master')
          .update({
            amfi_category_id: matchedId,
            benchmark_tier1: (catRow as { tier1_benchmark?: string } | null)?.tier1_benchmark ?? null,
            benchmark_tier2: (catRow as { tier2_benchmark?: string } | null)?.tier2_benchmark ?? null,
          })
          .eq('sub_category', subCat)
          .eq('returns_source', 'AMFI');
      } catch (e) {
        errors.push({ ctx: `amfi_category lookup ${subCat}`, message: String(e) });
      }
    }

    // 9. Log sync
    await supabase.from('fund_perf_sync_log').insert({
      report_date: reportDate.toISOString().slice(0, 10),
      total_funds: byFamily.size,
      updated,
      errors: errors.length > 0 ? { items: errors.slice(0, 50) } : null,
    });

    return json(
      {
        ok: true,
        reportDate: reportDateStr,
        totalFamilies: byFamily.size,
        unmatched,
        upserts: payload.length,
        updated,
        errors: errors.length,
        errorSamples: errors.slice(0, 5),
      },
      corsHeaders,
    );
  } catch (err) {
    console.error('refresh-fund-performance-amfi fatal:', err);
    try {
      await supabase.from('fund_perf_sync_log').insert({
        report_date: null,
        total_funds: 0,
        updated: 0,
        errors: { fatal: String(err), partial: errors.slice(0, 20) },
      });
    } catch {
      // swallow
    }
    return json({ ok: false, error: String(err) }, corsHeaders, 500);
  }
});

// ─── HTTP helpers ───────────────────────────────────────────────────────────

function json(body: unknown, cors: Record<string, string>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'content-type': 'application/json' },
  });
}

async function amfiFetch(
  path: string,
  init: RequestInit,
  attempt = 0,
): Promise<Response> {
  // Add jitter to avoid hammering.
  await sleep(Math.floor(Math.random() * JITTER_MAX_MS));
  const resp = await fetch(`${AMFI_BASE}${path}`, {
    ...init,
    headers: {
      'accept': 'application/json, text/plain, */*',
      'accept-language': 'en-US,en;q=0.9',
      'content-type': 'application/json',
      'origin': 'https://www.amfiindia.com',
      'referer': 'https://www.amfiindia.com/otherdata/fund-performance',
      'user-agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      'sec-ch-ua': '"Chromium";v="124", "Google Chrome";v="124", "Not-A.Brand";v="99"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"macOS"',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'same-origin',
      ...(init.headers ?? {}),
    },
  });
  if ((resp.status === 429 || resp.status >= 500) && attempt < 3) {
    const backoff = 500 * Math.pow(2, attempt) + Math.random() * 250;
    await sleep(backoff);
    return amfiFetch(path, init, attempt + 1);
  }
  return resp;
}

export async function checkHoliday(): Promise<null | Record<string, unknown>> {
  try {
    const resp = await amfiFetch('/isHoliday', { method: 'GET' });
    if (!resp.ok) return null;
    const data = await resp.json().catch(() => null);
    if (!data) return null;
    // Response shape varies; treat common forms as holiday-true.
    const isHol =
      data === true ||
      data?.isHoliday === true ||
      data?.holiday === true ||
      (typeof data?.status === 'string' && data.status.toLowerCase().includes('holiday'));
    return isHol ? (data as Record<string, unknown>) : null;
  } catch {
    return null;
  }
}

export async function fetchFilters(): Promise<FundPerfFilter[]> {
  // Confirmed via reverse-engineering the AMFI page (iframe at
  // /polling/amfi/fund-performance): POST with empty body returns
  // { data: { maturityTypeList: [{id,name}], investmentTypeList: [{id,name}], mutualFundList: [...] } }
  const resp = await amfiFetch('/fundperformancefilters', {
    method: 'POST',
    body: '{}',
  });
  if (!resp.ok) throw new Error(`filters HTTP ${resp.status}`);
  const json = await resp.json();
  const data = json?.data ?? json;
  const maturityTypes =
    (data?.maturityTypeList as Array<Record<string, unknown>> | undefined) ?? [];
  const categories =
    (data?.investmentTypeList as Array<Record<string, unknown>> | undefined) ?? [];
  const out: FundPerfFilter[] = [];
  for (const m of maturityTypes) {
    const mtId = Number(m.id);
    if (!Number.isFinite(mtId)) continue;
    for (const c of categories) {
      const catId = Number(c.id);
      const catName = String(c.name ?? '');
      if (!Number.isFinite(catId)) continue;
      out.push({ maturityType: mtId, categoryId: catId, categoryName: catName });
    }
  }
  return out;
}

export async function fetchSubCategories(
  maturityType: number,
  categoryId: number,
): Promise<SubCategory[]> {
  const resp = await amfiFetch('/getsubcategory', {
    method: 'POST',
    body: JSON.stringify({ maturityType, category: categoryId }),
  });
  if (!resp.ok) throw new Error(`subcat HTTP ${resp.status}`);
  const json = await resp.json();
  // Confirmed shape: { data: [ {id, name}, ... ] }
  const raw = json?.data ?? json;
  const out: SubCategory[] = [];
  for (const s of Array.isArray(raw) ? raw : []) {
    const id = Number((s as Record<string, unknown>).id ?? (s as Record<string, unknown>).subCategoryId);
    const name = String((s as Record<string, unknown>).name ?? (s as Record<string, unknown>).subCategoryName ?? '');
    if (!Number.isFinite(id)) continue;
    out.push({ subCategoryId: id, subCategoryName: name });
  }
  return out;
}

export async function fetchFundPerformance(opts: {
  maturityType: number;
  category: number;
  subCategory: number;
  reportDate: string;
  mfid?: number;
}): Promise<AmfiFundPerformanceRow[]> {
  const body = {
    maturityType: opts.maturityType,
    category: opts.category,
    subCategory: opts.subCategory,
    mfid: opts.mfid ?? 0,
    reportDate: opts.reportDate,
  };
  const resp = await amfiFetch('/fundperformance', {
    method: 'POST',
    body: JSON.stringify(body),
  });
  if (!resp.ok) throw new Error(`perf HTTP ${resp.status}`);
  const data = await resp.json();
  // Response is commonly an array; sometimes wrapped as { data: [...] }
  if (Array.isArray(data)) return data as AmfiFundPerformanceRow[];
  if (Array.isArray(data?.data)) return data.data as AmfiFundPerformanceRow[];
  if (Array.isArray(data?.schemes)) return data.schemes as AmfiFundPerformanceRow[];
  return [];
}

// ─── Row parser / upsert mapper ─────────────────────────────────────────────

/** Coerce numeric-ish values to finite number or null. */
function toNum(v: unknown): number | null {
  if (v == null || v === '' || v === '-' || v === 'N.A.' || v === 'NA') return null;
  const n = typeof v === 'number' ? v : Number(String(v).replace(/,/g, ''));
  return Number.isFinite(n) ? n : null;
}

function toTxt(v: unknown): string | null {
  if (v == null) return null;
  const s = String(v).trim();
  return s.length === 0 ? null : s;
}

/**
 * Normalize a scheme name for cross-source matching.
 *
 * AMFI's fund-performance API exposes a "family" name (no plan/option suffix),
 * while fund_master.fund_name typically encodes plan + option (e.g.
 * "ICICI Prudential Bluechip Fund - Direct Plan - Growth"). Normalize both
 * sides by stripping plan/option/dividend qualifiers and punctuation, then
 * compare lowercase tokens.
 */
export function normalizeSchemeName(name: string): string {
  let s = String(name ?? '').toLowerCase();
  // Strip parenthetical qualifiers like "(g)", "(idcw)", "(d)", "(growth)"
  s = s.replace(/\([^)]*\)/g, ' ');
  // Strip common plan / option markers
  const drop = [
    'direct plan',
    'regular plan',
    'direct',
    'regular',
    'growth option',
    'growth',
    'idcw payout',
    'idcw reinvestment',
    'idcw',
    'dividend payout',
    'dividend reinvestment',
    'dividend',
    'payout',
    'reinvestment',
    'plan',
    'option',
  ];
  for (const d of drop) {
    s = s.replace(new RegExp(`\\b${d}\\b`, 'g'), ' ');
  }
  // Normalize "&" / "and"
  s = s.replace(/&/g, ' and ');
  // Drop punctuation and collapse whitespace
  s = s.replace(/[^a-z0-9]+/g, ' ').replace(/\s+/g, ' ').trim();
  return s;
}

/** Detect plan_type from a fund_master row name when the column is missing. */
function inferPlanType(name: string | null | undefined): string {
  const s = (name ?? '').toLowerCase();
  if (s.includes('direct')) return 'Direct';
  return 'Regular';
}

/**
 * Detect whether a fund_master row is an income-distribution (IDCW/Dividend)
 * variant rather than the Growth option.
 *
 * The AMFI scheme performance file only publishes Growth-plan NAVs and
 * returns. If we blindly copy those values onto IDCW rows, we stomp the
 * IDCW's true NAV (which lives on a different AMFI code and is updated from
 * the per-scheme mfapi.in refresh) with the Growth NAV. The mfapi refresh
 * later corrects `latest_nav` back to the IDCW value but *not* `prev_nav`,
 * leaving a catastrophic fake day-change (e.g. IDCW 26 vs stale prev 82 →
 * -68%). We therefore skip IDCW variants from this refresh entirely.
 */
export function isIncomeDistributionVariant(name: string | null | undefined): boolean {
  const s = (name ?? '').toLowerCase();
  return /\bidcw\b|\bdividend\b|\bdiv\b|\bpayout\b|\breinvest/.test(s);
}

/**
 * Build an index of fund_master rows keyed by normalized scheme name.
 * Returns a map: normalizedName → array of {amfiCode, planType, fundName}.
 */
export async function buildFundMasterIndex(
  supabase: SupabaseClient,
): Promise<Map<string, Array<{ amfiCode: number; planType: string; fundName: string }>>> {
  const index = new Map<string, Array<{ amfiCode: number; planType: string; fundName: string }>>();
  const PAGE = 1000;
  let from = 0;
  for (;;) {
    const { data, error } = await supabase
      .from('fund_master')
      .select('amfi_code, fund_name, plan_type')
      .range(from, from + PAGE - 1);
    if (error) throw new Error(`fund_master fetch: ${error.message}`);
    if (!data || data.length === 0) break;
    for (const row of data as Array<Record<string, unknown>>) {
      const amfiCode = Number(row.amfi_code);
      const fundName = String(row.fund_name ?? '');
      if (!Number.isFinite(amfiCode) || !fundName) continue;
      const planType =
        (row.plan_type as string | null | undefined)?.trim() ||
        inferPlanType(fundName);
      const key = normalizeSchemeName(fundName);
      if (!key) continue;
      const bucket = index.get(key);
      const entry = { amfiCode, planType, fundName };
      if (bucket) bucket.push(entry);
      else index.set(key, [entry]);
    }
    if (data.length < PAGE) break;
    from += PAGE;
  }
  return index;
}

/**
 * Map an AMFI family row + a single matched fund_master row into an upsert
 * payload for fund_master, choosing Regular vs Direct columns by plan_type.
 * Exported for unit tests.
 */
export function toFundMasterUpdate(
  r: AmfiFundPerformanceRow,
  amfiCode: number,
  planType: string,
  fundName: string,
  categoryName: string,
  subCategoryName: string,
  nowIso: string,
): Record<string, unknown> {
  const isDirect = (planType ?? '').toLowerCase().startsWith('direct');

  // Pick the NAV / return / IR columns relevant for this plan.
  const nav = isDirect ? r.navDirect : r.navRegular;
  const prevNav = isDirect ? r.preNavDirect : r.preNavRegular;
  const r7 = isDirect ? r.return7DaysDirect : r.return7DaysRegular;
  const r15 = isDirect ? r.return15DaysDirect : r.return15DaysRegular;
  const r1m = isDirect ? r.return1MonthDirect : r.return1MonthRegular;
  const r3m = isDirect ? r.return3MonthDirect : r.return3MonthRegular;
  const r6m = isDirect ? r.return6MonthDirect : r.return6MonthRegular;
  const r1y = isDirect ? r.return1YearDirect : r.return1YearRegular;
  const r3y = isDirect ? r.return3YearDirect : r.return3YearRegular;
  const r5y = isDirect ? r.return5YearDirect : r.return5YearRegular;
  const r10y = isDirect ? r.return10YearDirect : r.return10YearRegular;
  const rIncept = isDirect ? r.returnSinceLaunchDirect : r.returnSinceLaunchRegular;
  const ir1 = isDirect ? r.ir1YrDirect : r.ir1YrRegular;
  const ir3 = isDirect ? r.ir3YrDirect : r.ir3YrRegular;
  const ir5 = isDirect ? r.ir5YrDirect : r.ir5YrRegular;
  const ir10 = isDirect ? r.ir10YrDirect : r.ir10YrRegular;

  const payload: Record<string, unknown> = {
    amfi_code: amfiCode,
    fund_name: fundName,
    category: toTxt(categoryName) ?? undefined,
    sub_category: toTxt(subCategoryName) ?? undefined,
    benchmark_index: toTxt(r.benchmark) ?? undefined,

    latest_nav: toNum(nav),
    prev_nav: toNum(prevNav),

    aum_cr: toNum(r.dailyAUM),

    // Plan-aware short window returns
    return_7d: toNum(r7),
    return_15d: toNum(r15),
    return_1m: toNum(r1m),
    return_3m: toNum(r3m),
    return_6m: toNum(r6m),

    // Plan-aware long window returns (legacy columns)
    return_1y: toNum(r1y),
    return_3y: toNum(r3y),
    return_5y: toNum(r5y),
    return_10y: toNum(r10y),
    return_inception: toNum(rIncept),

    // Benchmark returns (shared across plans)
    return_bench_1y: toNum(r.return1YearBenchmark),
    return_bench_3y: toNum(r.return3YearBenchmark),
    return_bench_5y: toNum(r.return5YearBenchmark),
    return_bench_10y: toNum(r.return10YearBenchmark),

    // Information ratios — plan aware
    info_ratio_1y: toNum(ir1),
    info_ratio_3y: toNum(ir3),
    info_ratio_5y: toNum(ir5),
    info_ratio_10y: toNum(ir10),

    // Riskometer
    riskometer_scheme: toTxt(r.riskometerScheme),
    riskometer_bench: toTxt(r.riskometerBenchmark),
    crisil_rating: toTxt(r.riskometerScheme) ?? undefined,

    // Source tracking
    returns_source: 'AMFI',
    returns_updated_at: nowIso,
  };

  // Direct-plan rows additionally populate the dedicated direct columns so
  // the screener can show Regular vs Direct side-by-side without joining.
  if (isDirect) {
    payload.nav_direct = toNum(nav);
    payload.return_direct_1y = toNum(r1y);
    payload.return_direct_3y = toNum(r3y);
    payload.return_direct_5y = toNum(r5y);
    payload.return_direct_10y = toNum(r10y);
  }

  return payload;
}

// ─── Date helpers ───────────────────────────────────────────────────────────

const MONTH_ABBR = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

export function formatDdMmmYyyy(d: Date): string {
  const dd = String(d.getUTCDate()).padStart(2, '0');
  const mmm = MONTH_ABBR[d.getUTCMonth()];
  const yyyy = d.getUTCFullYear();
  return `${dd}-${mmm}-${yyyy}`;
}

/** Previous business day (skip Sat=6 and Sun=0). */
export function previousBusinessDay(from: Date): Date {
  const d = new Date(Date.UTC(from.getUTCFullYear(), from.getUTCMonth(), from.getUTCDate()));
  do {
    d.setUTCDate(d.getUTCDate() - 1);
  } while (d.getUTCDay() === 0 || d.getUTCDay() === 6);
  return d;
}

// ─── Concurrency helper ─────────────────────────────────────────────────────

async function runWithConcurrency<T>(
  items: T[],
  limit: number,
  worker: (item: T) => Promise<void>,
): Promise<void> {
  let i = 0;
  const workers = new Array(Math.min(limit, items.length)).fill(0).map(async () => {
    while (i < items.length) {
      const idx = i++;
      await worker(items[idx]);
    }
  });
  await Promise.all(workers);
}

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

// Silence unused warnings for SupabaseClient import when type-checking.
export type { SupabaseClient };
