/**
 * eVesh — Supabase Edge Function: check-portfolio-overlap
 *
 * Runs semi-monthly (1st and 15th of each month) via pg_cron.
 * Performs three portfolio overlap / concentration checks for every user
 * who holds MF assets and inserts alerts into alert_log.
 *
 * Checks performed per user:
 *  1. STOCK_CONCENTRATION  — single company ≥ 10% of total MF portfolio
 *  2. SECTOR_CONCENTRATION — single sector  ≥ 25% of total MF portfolio
 *  3. FUND_OVERLAP         — two funds share ≥ 50% common holdings (by weight)
 *
 * Alert dedup key format:  overlap|{check_type}|{owner_id}|{YYYY-MM}
 * This ensures at most one alert of each type per user per calendar month.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';

// ── Environment ───────────────────────────────────────────────────────────────
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

// ── Thresholds ────────────────────────────────────────────────────────────────
const STOCK_CONCENTRATION_THRESHOLD = 10;  // percent
const SECTOR_CONCENTRATION_THRESHOLD = 25; // percent
const FUND_OVERLAP_THRESHOLD = 50;         // percent

// ── Types ─────────────────────────────────────────────────────────────────────

interface AlertCandidate {
  owner_id: string;
  alert_type: string;
  severity: 'URGENT' | 'MEDIUM' | 'LOW';
  title: string;
  body: string;
  amfi_code?: number;
  dedup_key: string;
}

/** One row from transactions, with latest_nav joined from fund_master. */
interface TxRow {
  owner_id: string;
  amfi_code: number;
  units: number;
  amount: number;
  tx_type: string;
  fund_master: { latest_nav: number | null; fund_name: string } | null;
}

/** Aggregated holding after netting BUY/SIP vs REDEEM. */
interface FundHolding {
  amfi_code: number;
  fund_name: string;
  units: number;
  current_value: number;
  weight_pct: number; // percentage of total MF portfolio
}

/** One row from fund_holdings_cache. */
interface CacheRow {
  amfi_code: number;
  company_name: string;
  sector_name: string | null;
  corpus_pct: number;
  fetched_at: string;
}

// ── Main handler ──────────────────────────────────────────────────────────────

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // Month stamp used in every dedup key — YYYY-MM
    const monthStamp = new Date().toISOString().substring(0, 7);

    // ── Step 1: Fetch all distinct owner_ids with active MF holdings ──────────
    const { data: ownerRows, error: ownerErr } = await supabase
      .from('transactions')
      .select('owner_id')
      .eq('asset_type', 'MF')
      .in('tx_type', ['BUY', 'SIP', 'REDEEM']);

    if (ownerErr) {
      throw new Error(`Failed to fetch owners: ${ownerErr.message}`);
    }

    const ownerIds: string[] = [
      ...new Set((ownerRows ?? []).map((r: { owner_id: string }) => r.owner_id)),
    ];

    if (ownerIds.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: 'No MF holders found', alerts_inserted: 0 }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    console.log(`Found ${ownerIds.length} MF holder(s)`);

    // ── Step 2: Collect all unique AMFI codes across every user ───────────────
    const { data: amfiRows, error: amfiErr } = await supabase
      .from('transactions')
      .select('amfi_code, fund_master(fund_name)')
      .eq('asset_type', 'MF')
      .in('tx_type', ['BUY', 'SIP', 'REDEEM'])
      .not('amfi_code', 'is', null);

    if (amfiErr) {
      throw new Error(`Failed to fetch AMFI codes: ${amfiErr.message}`);
    }

    // Build a map of amfi_code → fund_name for later use
    const fundNameMap = new Map<number, string>();
    for (const row of amfiRows ?? []) {
      const code = (row as any).amfi_code as number;
      const name: string = (row as any).fund_master?.fund_name ?? `Fund ${code}`;
      if (!fundNameMap.has(code)) {
        fundNameMap.set(code, name);
      }
    }

    const allAmfiCodes = [...fundNameMap.keys()];
    console.log(`Found ${allAmfiCodes.length} unique AMFI code(s)`);

    // ── Step 3: Refresh stale holdings cache (>30 days) ───────────────────────
    const staleThreshold = new Date();
    staleThreshold.setDate(staleThreshold.getDate() - 30);

    // Fetch one fetched_at per amfi_code (most recent row is sufficient)
    const { data: cacheAgeRows } = await supabase
      .from('fund_holdings_cache')
      .select('amfi_code, fetched_at')
      .in('amfi_code', allAmfiCodes);

    // Build a map: amfi_code → most recent fetched_at
    const latestFetchedAt = new Map<number, Date>();
    for (const row of cacheAgeRows ?? []) {
      const code = (row as any).amfi_code as number;
      const fetched = new Date((row as any).fetched_at as string);
      const existing = latestFetchedAt.get(code);
      if (!existing || fetched > existing) {
        latestFetchedAt.set(code, fetched);
      }
    }

    // Codes that are either not cached at all or stale
    const staleCodes = allAmfiCodes.filter((code) => {
      const lastFetch = latestFetchedAt.get(code);
      return !lastFetch || lastFetch < staleThreshold;
    });

    if (staleCodes.length > 0) {
      console.log(`Refreshing ${staleCodes.length} stale/missing holdings cache entries...`);
      for (let i = 0; i < staleCodes.length; i++) {
        const amfiCode = staleCodes[i];
        const fundName = fundNameMap.get(amfiCode) ?? '';
        console.log(
          `  Fetching holdings for AMFI ${amfiCode} (${fundName}) [${i + 1}/${staleCodes.length}]`,
        );
        try {
          await fetch(`${SUPABASE_URL}/functions/v1/fetch-fund-holdings`, {
            method: 'POST',
            headers: {
              Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({ amfi_code: amfiCode, fund_name: fundName }),
          });
        } catch (fetchErr) {
          console.warn(`  Warning: fetch-fund-holdings failed for ${amfiCode}:`, fetchErr);
        }
        // Rate-limit: 500 ms between Groww fetches
        if (i < staleCodes.length - 1) {
          await new Promise((resolve) => setTimeout(resolve, 500));
        }
      }
    }

    // ── Step 4: Load the full holdings cache for all relevant AMFI codes ──────
    const { data: allCacheRows, error: cacheErr } = await supabase
      .from('fund_holdings_cache')
      .select('amfi_code, company_name, sector_name, corpus_pct, fetched_at')
      .in('amfi_code', allAmfiCodes);

    if (cacheErr) {
      throw new Error(`Failed to load fund_holdings_cache: ${cacheErr.message}`);
    }

    // Group cache rows by amfi_code for O(1) lookup
    const holdingsByFund = new Map<number, CacheRow[]>();
    for (const row of (allCacheRows ?? []) as CacheRow[]) {
      const list = holdingsByFund.get(row.amfi_code) ?? [];
      list.push(row);
      holdingsByFund.set(row.amfi_code, list);
    }

    // ── Step 5: Process each user ─────────────────────────────────────────────
    const allAlerts: AlertCandidate[] = [];

    for (let i = 0; i < ownerIds.length; i++) {
      const ownerId = ownerIds[i];
      console.log(`Processing user ${i + 1} of ${ownerIds.length} (${ownerId})`);

      const userAlerts = await processUser(
        supabase,
        ownerId,
        monthStamp,
        fundNameMap,
        holdingsByFund,
      );
      allAlerts.push(...userAlerts);
    }

    // ── Step 6: Insert alerts with dedup ──────────────────────────────────────
    let insertedCount = 0;

    for (const alert of allAlerts) {
      const { error: insertErr } = await supabase
        .from('alert_log')
        .insert({
          ...alert,
          is_read: false,
          created_at: new Date().toISOString(),
        });

      if (insertErr?.code === '23505') {
        // Duplicate — skip silently
        continue;
      }
      if (insertErr) {
        console.error('Alert insert error:', insertErr.message, '| dedup_key:', alert.dedup_key);
        continue;
      }
      insertedCount++;
    }

    const summary = {
      success: true,
      users_processed: ownerIds.length,
      alerts_generated: allAlerts.length,
      alerts_inserted: insertedCount,
    };
    console.log(
      `Done — ${summary.users_processed} users, ${summary.alerts_generated} generated, ${summary.alerts_inserted} inserted`,
    );

    return new Response(JSON.stringify(summary), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('check-portfolio-overlap error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

// ── Per-user processing ───────────────────────────────────────────────────────

async function processUser(
  supabase: ReturnType<typeof createClient>,
  ownerId: string,
  monthStamp: string,
  fundNameMap: Map<number, string>,
  holdingsByFund: Map<number, CacheRow[]>,
): Promise<AlertCandidate[]> {
  // 5a. Load this user's MF transactions
  const { data: txRows, error: txErr } = await supabase
    .from('transactions')
    .select('owner_id, amfi_code, units, amount, tx_type, fund_master(latest_nav, fund_name)')
    .eq('owner_id', ownerId)
    .eq('asset_type', 'MF')
    .in('tx_type', ['BUY', 'SIP', 'REDEEM']);

  if (txErr) {
    console.warn(`  Failed to load transactions for ${ownerId}: ${txErr.message}`);
    return [];
  }

  // 5b. Compute current units and value per fund
  const fundHoldings = computeFundHoldings(txRows ?? []);

  // Filter out zero / near-zero holdings
  const activeFunds = fundHoldings.filter((f) => f.current_value > 0.01);

  if (activeFunds.length === 0) return [];

  // Compute portfolio weights
  const totalValue = activeFunds.reduce((sum, f) => sum + f.current_value, 0);
  for (const f of activeFunds) {
    f.weight_pct = totalValue > 0 ? (f.current_value / totalValue) * 100 : 0;
    // Fill in fund_name from global map if missing
    if (!f.fund_name && fundNameMap.has(f.amfi_code)) {
      f.fund_name = fundNameMap.get(f.amfi_code)!;
    }
  }

  const alerts: AlertCandidate[] = [];

  // 5c. Stock concentration check
  const stockAlerts = checkStockConcentration(ownerId, monthStamp, activeFunds, holdingsByFund);
  alerts.push(...stockAlerts);

  // 5d. Sector concentration check
  const sectorAlerts = checkSectorConcentration(ownerId, monthStamp, activeFunds, holdingsByFund);
  alerts.push(...sectorAlerts);

  // 5e. Fund pair overlap check
  const overlapAlerts = checkFundPairOverlap(ownerId, monthStamp, activeFunds, holdingsByFund);
  alerts.push(...overlapAlerts);

  return alerts;
}

// ── Portfolio weight computation ──────────────────────────────────────────────

function computeFundHoldings(txRows: TxRow[]): FundHolding[] {
  const map = new Map<
    number,
    { fund_name: string; units: number; invested: number; latest_nav: number }
  >();

  for (const tx of txRows) {
    const code = tx.amfi_code;
    if (!code) continue;

    const nav = tx.fund_master?.latest_nav ?? 0;
    const fundName = tx.fund_master?.fund_name ?? `Fund ${code}`;
    const txUnits = tx.units ?? (nav > 0 ? tx.amount / nav : 0);
    const isPurchase = ['BUY', 'SIP'].includes((tx.tx_type ?? '').toUpperCase());

    const existing = map.get(code);
    if (existing) {
      if (isPurchase) {
        existing.units += txUnits;
        existing.invested += tx.amount ?? 0;
      } else {
        // REDEEM
        const ratio = existing.units > 0 ? Math.min(txUnits / existing.units, 1) : 0;
        existing.invested = Math.max(0, existing.invested - existing.invested * ratio);
        existing.units = Math.max(0, existing.units - txUnits);
      }
      // Update nav in case there are newer rows
      if (nav > 0) existing.latest_nav = nav;
    } else {
      map.set(code, {
        fund_name: fundName,
        units: isPurchase ? txUnits : -txUnits,
        invested: isPurchase ? (tx.amount ?? 0) : -(tx.amount ?? 0),
        latest_nav: nav,
      });
    }
  }

  const result: FundHolding[] = [];
  for (const [amfi_code, data] of map) {
    const current_value = data.units > 0 ? data.units * data.latest_nav : 0;
    result.push({
      amfi_code,
      fund_name: data.fund_name,
      units: data.units,
      current_value,
      weight_pct: 0, // filled in by caller
    });
  }
  return result;
}

// ── Check 1: Stock concentration ─────────────────────────────────────────────

function checkStockConcentration(
  ownerId: string,
  monthStamp: string,
  activeFunds: FundHolding[],
  holdingsByFund: Map<number, CacheRow[]>,
): AlertCandidate[] {
  // effectiveWeight per company = Σ (fundWeightPct × holdingCorpusPct / 100)
  const companyWeight = new Map<string, number>();

  for (const fund of activeFunds) {
    const holdings = holdingsByFund.get(fund.amfi_code) ?? [];
    for (const h of holdings) {
      if (!h.company_name) continue;
      const contribution = (fund.weight_pct * h.corpus_pct) / 100;
      companyWeight.set(
        h.company_name,
        (companyWeight.get(h.company_name) ?? 0) + contribution,
      );
    }
  }

  const alerts: AlertCandidate[] = [];

  for (const [company, effectivePct] of companyWeight) {
    if (effectivePct >= STOCK_CONCENTRATION_THRESHOLD) {
      const pctStr = effectivePct.toFixed(1);
      alerts.push({
        owner_id: ownerId,
        alert_type: 'STOCK_CONCENTRATION',
        severity: 'URGENT',
        title: `High stock concentration: ${company}`,
        body: `High stock concentration: ${company} is ${pctStr}% of your portfolio (SEBI limit: 10%). Consider diversifying.`,
        dedup_key: `overlap|STOCK_CONCENTRATION|${ownerId}|${monthStamp}`,
      });
      // One alert per user per month — stop after first breach
      break;
    }
  }

  return alerts;
}

// ── Check 2: Sector concentration ────────────────────────────────────────────

function checkSectorConcentration(
  ownerId: string,
  monthStamp: string,
  activeFunds: FundHolding[],
  holdingsByFund: Map<number, CacheRow[]>,
): AlertCandidate[] {
  const sectorWeight = new Map<string, number>();

  for (const fund of activeFunds) {
    const holdings = holdingsByFund.get(fund.amfi_code) ?? [];
    for (const h of holdings) {
      const sector = h.sector_name;
      if (!sector) continue;
      const contribution = (fund.weight_pct * h.corpus_pct) / 100;
      sectorWeight.set(sector, (sectorWeight.get(sector) ?? 0) + contribution);
    }
  }

  const alerts: AlertCandidate[] = [];

  for (const [sector, effectivePct] of sectorWeight) {
    if (effectivePct >= SECTOR_CONCENTRATION_THRESHOLD) {
      const pctStr = effectivePct.toFixed(1);
      alerts.push({
        owner_id: ownerId,
        alert_type: 'SECTOR_CONCENTRATION',
        severity: 'MEDIUM',
        title: `Sector concentration: ${sector}`,
        body: `Sector concentration: ${sector} is ${pctStr}% of your portfolio. Industry recommends below 25%.`,
        dedup_key: `overlap|SECTOR_CONCENTRATION|${ownerId}|${monthStamp}`,
      });
      // One alert per user per month
      break;
    }
  }

  return alerts;
}

// ── Check 3: Fund pair overlap ────────────────────────────────────────────────

function checkFundPairOverlap(
  ownerId: string,
  monthStamp: string,
  activeFunds: FundHolding[],
  holdingsByFund: Map<number, CacheRow[]>,
): AlertCandidate[] {
  if (activeFunds.length < 2) return [];

  const alerts: AlertCandidate[] = [];

  for (let i = 0; i < activeFunds.length; i++) {
    for (let j = i + 1; j < activeFunds.length; j++) {
      const fundA = activeFunds[i];
      const fundB = activeFunds[j];

      const holdingsA = holdingsByFund.get(fundA.amfi_code) ?? [];
      const holdingsB = holdingsByFund.get(fundB.amfi_code) ?? [];

      if (holdingsA.length === 0 || holdingsB.length === 0) continue;

      // Build company → corpus_pct maps for each fund
      const mapA = new Map<string, number>();
      const mapB = new Map<string, number>();

      for (const h of holdingsA) mapA.set(h.company_name, h.corpus_pct);
      for (const h of holdingsB) mapB.set(h.company_name, h.corpus_pct);

      // overlap = Σ min(weightInA, weightInB) for all common companies
      let overlapPct = 0;
      for (const [company, pctA] of mapA) {
        const pctB = mapB.get(company);
        if (pctB !== undefined) {
          overlapPct += Math.min(pctA, pctB);
        }
      }

      if (overlapPct >= FUND_OVERLAP_THRESHOLD) {
        const pctStr = overlapPct.toFixed(1);
        const nameA = fundA.fund_name ?? `AMFI ${fundA.amfi_code}`;
        const nameB = fundB.fund_name ?? `AMFI ${fundB.amfi_code}`;

        alerts.push({
          owner_id: ownerId,
          alert_type: 'FUND_OVERLAP',
          severity: 'MEDIUM',
          title: `Fund overlap: ${nameA.substring(0, 35)} & ${nameB.substring(0, 35)}`,
          body: `${nameA} and ${nameB} have ${pctStr}% portfolio overlap (SEBI ceiling: 50%). These funds hold very similar stocks.`,
          amfi_code: fundA.amfi_code,
          dedup_key: `overlap|FUND_OVERLAP|${ownerId}|${monthStamp}`,
        });
        // One FUND_OVERLAP alert per user per month — stop scanning pairs
        return alerts;
      }
    }
  }

  return alerts;
}
