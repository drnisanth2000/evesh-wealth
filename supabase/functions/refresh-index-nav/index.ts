/**
 * eVesh — Supabase Edge Function: refresh-index-nav
 *
 * Pulls daily index history from Yahoo Finance for every benchmark index that
 * we can map (AMFI canonical name → Yahoo ticker), and upserts into
 * `index_nav_history` (index_name, nav_date, nav).
 *
 * Modes:
 *   - default / "incremental": last ~60 days of data (used by daily cron)
 *   - "backfill":               last ~10 years (one-shot historical seeding)
 *
 * Yahoo's v8 chart endpoint gives us PRICE returns, not Total Return Index.
 * For Alpha / Beta / Tracking Error the daily covariance is essentially
 * identical to TRI-based numbers (the dividend drag is < ~1.5%/yr for Indian
 * equity indices) so this is good enough to light up the metrics.
 *
 * Indices that we can't map (most CRISIL bond indices, MCX gold, MSCI World)
 * are skipped gracefully and listed in the response under `unmapped`.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

interface NavPoint {
  date: string; // YYYY-MM-DD
  nav: number;
}

/**
 * AMFI canonical benchmark name → Yahoo Finance ticker.
 * Only equity indices have reliable free coverage. Debt/CRISIL/MCX skipped.
 *
 * Using PRICE-return tickers (no Yahoo TRI for Indian indices). Daily-return
 * covariance is what matters for Alpha/Beta/TE so this is fine.
 */
const AMFI_TO_YAHOO: Record<string, string> = {
  // ── NIFTY equity (10y verified) ───────────────────────────────────────────
  'NIFTY 50 TRI': '^NSEI',
  'NIFTY 100 TRI': '^CNX100',
  'NIFTY 500 TRI': '^CRSLDX',
  // ETF proxies (no Yahoo index symbol available)
  'NIFTY Midcap 150 TRI': 'MID150BEES.NS',     // Nippon India NIFTY Midcap 150 ETF
  'NIFTY Smallcap 250 TRI': 'HDFCSML250.NS',   // HDFC NIFTY Smallcap 250 ETF (~3y)

  // ── BSE equity ────────────────────────────────────────────────────────────
  'S&P BSE 100 TRI': 'BSE-100.BO',
  'S&P BSE 500 TRI': 'BSE-500.BO',

  // ── International ─────────────────────────────────────────────────────────
  'S&P 500 TRI': '^GSPC',
  'MSCI World Index': 'URTH',                  // ETF tracking MSCI World

  // ── Gold ──────────────────────────────────────────────────────────────────
  'Domestic Price of Gold': 'GOLDBEES.NS',     // Nippon India Gold ETF (INR)
  'MCX Gold': 'GOLDBEES.NS',

  // Unmapped (no reliable free source):
  //   - NIFTY LargeMidcap 250 TRI, NIFTY 500 Multicap 50:25:25 TRI
  //   - S&P BSE 150 MidCap / 250 LargeMidCap / 250 SmallCap TRI
  //   - All CRISIL bond / NIFTY debt / NIFTY hybrid / NIFTY money-market indices
  //   - Sectoral / Thematic / Underlying placeholders
};

interface YahooChartResult {
  chart: {
    result?: Array<{
      timestamp: number[];
      indicators: {
        quote: Array<{ close: (number | null)[] }>;
        adjclose?: Array<{ adjclose: (number | null)[] }>;
      };
    }>;
    error?: { code: string; description: string } | null;
  };
}

async function fetchYahoo(ticker: string, fromSec: number, toSec: number): Promise<NavPoint[]> {
  const url =
    `https://query1.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(ticker)}` +
    `?period1=${fromSec}&period2=${toSec}&interval=1d&events=div,splits`;
  try {
    const r = await fetch(url, {
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' +
          '(KHTML, like Gecko) Chrome/120.0 Safari/537.36',
        Accept: 'application/json',
      },
    });
    if (!r.ok) {
      console.warn(`yahoo ${ticker} -> HTTP ${r.status}`);
      return [];
    }
    const json = (await r.json()) as YahooChartResult;
    if (json.chart.error) {
      console.warn(`yahoo ${ticker} error:`, json.chart.error.code);
      return [];
    }
    const res = json.chart.result?.[0];
    if (!res) return [];
    const ts = res.timestamp ?? [];
    // Prefer adjusted close (handles splits) when available, else raw close.
    const adj = res.indicators.adjclose?.[0]?.adjclose;
    const close = res.indicators.quote?.[0]?.close;
    const series = adj ?? close ?? [];
    const out: NavPoint[] = [];
    for (let i = 0; i < ts.length; i++) {
      const v = series[i];
      if (v == null || !isFinite(v)) continue;
      const d = new Date(ts[i] * 1000).toISOString().substring(0, 10);
      out.push({ date: d, nav: v });
    }
    return out;
  } catch (err) {
    console.error(`fetchYahoo(${ticker}) failed:`, (err as Error).message);
    return [];
  }
}

async function chunkedUpsert(
  supabase: ReturnType<typeof createClient>,
  rows: Array<{ index_name: string; nav_date: string; nav: number }>,
  chunk = 500,
): Promise<{ inserted: number; error?: string }> {
  let inserted = 0;
  for (let i = 0; i < rows.length; i += chunk) {
    const slice = rows.slice(i, i + chunk);
    const { error } = await supabase
      .from('index_nav_history')
      .upsert(slice, { onConflict: 'index_name,nav_date' });
    if (error) return { inserted, error: error.message };
    inserted += slice.length;
  }
  return { inserted };
}

serve(async (req) => {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  let mode = 'incremental';
  let onlyName: string | null = null;
  if (req.method === 'POST') {
    try {
      const body = await req.json();
      if (body?.mode) mode = String(body.mode);
      if (body?.index_name) onlyName = String(body.index_name);
    } catch { /* ignore */ }
  } else {
    const u = new URL(req.url);
    if (u.searchParams.get('mode')) mode = u.searchParams.get('mode')!;
  }

  // Discover the universe of benchmark names actually used by amfi_category.
  const { data: cats, error } = await supabase
    .from('amfi_category')
    .select('tier1_benchmark, tier2_benchmark');
  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'content-type': 'application/json' },
    });
  }

  const allIndices = new Set<string>();
  for (const c of (cats ?? []) as { tier1_benchmark?: string; tier2_benchmark?: string }[]) {
    if (c.tier1_benchmark) allIndices.add(c.tier1_benchmark.trim());
    if (c.tier2_benchmark) allIndices.add(c.tier2_benchmark.trim());
  }

  // Date window
  const now = Math.floor(Date.now() / 1000);
  const days = mode === 'backfill' ? 365 * 10 : 60;
  const fromSec = now - days * 24 * 60 * 60;

  const refreshed: Record<string, number> = {};
  const errors: Record<string, string> = {};
  const unmapped: string[] = [];

  for (const indexName of allIndices) {
    if (onlyName && indexName !== onlyName) continue;
    const ticker = AMFI_TO_YAHOO[indexName];
    if (!ticker) {
      unmapped.push(indexName);
      continue;
    }
    const points = await fetchYahoo(ticker, fromSec, now);
    if (points.length === 0) {
      errors[indexName] = `no data from ${ticker}`;
      continue;
    }
    const rows = points.map((p) => ({
      index_name: indexName,
      nav_date: p.date,
      nav: p.nav,
    }));
    const { inserted, error: upErr } = await chunkedUpsert(supabase, rows);
    if (upErr) {
      errors[indexName] = upErr;
    } else {
      refreshed[indexName] = inserted;
    }
    // Be polite to Yahoo
    await new Promise((res) => setTimeout(res, 200));
  }

  const totalRows = Object.values(refreshed).reduce((a, b) => a + b, 0);
  return new Response(
    JSON.stringify({
      mode,
      universeSize: allIndices.size,
      mappedCount: Object.keys(refreshed).length,
      unmappedCount: unmapped.length,
      totalRows,
      refreshed,
      errors,
      unmapped,
    }),
    { headers: { 'content-type': 'application/json' } },
  );
});
