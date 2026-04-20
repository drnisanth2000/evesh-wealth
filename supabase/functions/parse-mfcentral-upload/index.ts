/**
 * eVesh — Supabase Edge Function: parse-mfcentral-upload
 *
 * Parses uploaded MF Central / CAS statements (Excel .xlsx or PDF)
 * and inserts de-duplicated transactions into the transactions table.
 *
 * Validation: Cross-checks parsed transactions against the Portfolio sheet
 * (units balance, invested value) and auto-corrects misclassified tx_types.
 *
 * Request: application/json
 *   - file_base64: base64-encoded file bytes
 *   - file_name: original filename (.xlsx / .xls / .csv / .pdf)
 *   - owner_id: the authenticated user's ID
 *   - family_id: optional family ID
 *   - batch_id: UUID of the import_batches row (created before calling this function)
 *   - fallback_member_id: member_id to use when PAN is absent or unmatched
 *
 * Response: { inserted, duplicates, errors, total, validation, corrections }
 *
 * Deduplication: SHA-256(isin|txDate|amount|txType|folio)
 * Re-uploading the same file is safe — duplicates are silently skipped.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import * as XLSX from 'https://esm.sh/xlsx@0.18.5';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;

const MAX_UPLOAD_BYTES = 20 * 1024 * 1024; // 20 MB

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// ─── Types ────────────────────────────────────────────────────────────────────

interface ParsedTransaction {
  tx_date: string;
  isin?: string;
  amfi_code?: number;
  fund_name?: string;
  units?: number;
  nav_at_tx?: number;
  amount: number;
  tx_type: string;
  folio_number?: string;
  pan?: string;
  amc_name?: string;
  import_source: string;
}

interface PortfolioHolding {
  schemeName: string;
  amcName: string;
  category: string;
  folioNumber: string;
  investedValue: number;
  currentValue: number;
  returns: number;
  units: number;
}

interface ValidationEntry {
  folio: string;
  scheme: string;
  amc: string;
  expectedUnits: number;
  computedUnits: number;
  match: boolean;
  corrected: boolean;
  corrections: string[];
}

const PURCHASE_TYPES = new Set(['BUY', 'SIP', 'Switch-In', 'STP-In', 'Bonus', 'IDCW', 'Opening Balance']);

// ─── Main handler ─────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // ── Authenticate caller via JWT ──────────────────────────────────────
    const authHeader = req.headers.get('Authorization') || req.headers.get('authorization');
    if (!authHeader || !authHeader.toLowerCase().startsWith('bearer ')) {
      return jsonError('Unauthorized', 401);
    }
    const token = authHeader.slice(7).trim();

    const authClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    const { data: userResp, error: authErr } = await authClient.auth.getUser(token);
    if (authErr || !userResp?.user) {
      return jsonError('Unauthorized', 401);
    }
    const authedUserId = userResp.user.id;

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    const body = await req.json();
    // owner_id is ALWAYS derived from the verified JWT, never trusted from body.
    const bodyOwnerId = body.owner_id as string | undefined;
    if (bodyOwnerId && bodyOwnerId !== authedUserId) {
      return jsonError('Forbidden', 403);
    }
    const ownerId = authedUserId;
    const familyId = (body.family_id as string) || null;
    const batchId = (body.batch_id as string) || null;
    const fallbackMemberId = (body.fallback_member_id as string) || null;
    const fileBase64 = body.file_base64 as string;
    const fileName = ((body.file_name as string) ?? '').toLowerCase();

    if (!fileBase64) {
      return jsonError('file_base64 is required', 400);
    }

    // Size guard: base64 is ~4/3 of raw bytes. Reject before decoding.
    if (fileBase64.length > Math.ceil(MAX_UPLOAD_BYTES * 4 / 3) + 100) {
      return jsonError('File too large (max 20 MB)', 413);
    }

    // Decode base64 → Uint8Array
    const binaryString = atob(fileBase64);
    const fileBytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
      fileBytes[i] = binaryString.charCodeAt(i);
    }

    let parsed: ParsedTransaction[] = [];
    let portfolioHoldings: PortfolioHolding[] = [];
    let importSource = 'mfcentral_excel';

    if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls') || fileName.endsWith('.csv')) {
      const wb = XLSX.read(fileBytes, { type: 'array', cellDates: true });
      parsed = parseTransactionSheet(wb);
      portfolioHoldings = parsePortfolioSheet(wb);
      importSource = 'mfcentral_excel';
    } else if (fileName.endsWith('.pdf')) {
      parsed = await parsePdf(fileBytes);
      importSource = 'mfcentral_pdf';
    } else {
      return jsonError('Unsupported file type. Use .xlsx, .xls, .csv, or .pdf', 400);
    }

    console.log(`Parsed ${parsed.length} transactions from ${fileName}`);

    // ── Enrich transactions with AMC & folio from Portfolio sheet ────────────
    enrichWithPortfolioData(parsed, portfolioHoldings);

    // ── Validate against Portfolio sheet and auto-correct misclassifications ─
    const validation = validateAndCorrect(parsed, portfolioHoldings);

    // ── Generate Opening Balance transactions for partial-history funds ──────
    const partialHistoryFunds = generateOpeningBalances(parsed, portfolioHoldings, validation);

    // ── Resolve member IDs from PAN numbers ─────────────────────────────────
    const { data: members } = await supabase
      .from('family_members')
      .select('id, display_name, pan')
      .eq('owner_id', ownerId);

    const panToMemberId = new Map<string, string>();
    for (const m of members || []) {
      if (m.pan) {
        panToMemberId.set(m.pan.toUpperCase().trim(), m.id);
      }
    }

    // ── Resolve AMFI codes from ISINs ───────────────────────────────────────
    const isins = [...new Set(parsed.map((t) => t.isin).filter(Boolean))] as string[];
    const isinToAmfi = new Map<string, number>();
    if (isins.length > 0) {
      const { data: funds } = await supabase
        .from('fund_master')
        .select('amfi_code, isin_growth, isin_div_reinvest')
        .or(isins.map((i) => `isin_growth.eq.${i},isin_div_reinvest.eq.${i}`).join(','));
      for (const f of funds || []) {
        if (f.isin_growth) isinToAmfi.set(f.isin_growth, f.amfi_code);
        if (f.isin_div_reinvest) isinToAmfi.set(f.isin_div_reinvest, f.amfi_code);
      }
    }

    // ── Pre-check: resolve member for every transaction BEFORE inserting ────
    const unmatchedPanValues = new Set<string>();
    for (const tx of parsed) {
      const pan = tx.pan?.toUpperCase().trim();
      const memberId = (pan ? panToMemberId.get(pan) : null) ?? fallbackMemberId ?? null;
      if (!memberId && pan) unmatchedPanValues.add(pan);
    }

    if (unmatchedPanValues.size > 0 && !fallbackMemberId) {
      if (batchId) {
        await supabase.from('import_batches').update({
          status: 'failed',
          rows_parsed: parsed.length,
          rows_inserted: 0,
          error_details: { errors: [`Unmatched PAN: ${[...unmatchedPanValues].join(', ')}`] },
          completed_at: new Date().toISOString(),
        }).eq('id', batchId);
      }

      return new Response(
        JSON.stringify({
          inserted: 0, duplicates: 0, errors: [], total: parsed.length,
          unmatched_pan: parsed.length, unmatched_pan_values: [...unmatchedPanValues],
          aborted: true,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ── Resolve AMFI codes from fund names (fuzzy token matching) ───────────
    const uniqueFundNames = [
      ...new Set(
        parsed
          .filter((t) => !t.amfi_code && !t.isin && t.fund_name)
          .map((t) => t.fund_name!)
      ),
    ];
    const nameToAmfi = new Map<string, number>();
    if (uniqueFundNames.length > 0) {
      const allFunds: { amfi_code: number; fund_name: string }[] = [];
      let page = 0;
      const pageSize = 1000;
      while (true) {
        const { data } = await supabase
          .from('fund_master')
          .select('amfi_code, fund_name')
          .range(page * pageSize, (page + 1) * pageSize - 1);
        if (!data || data.length === 0) break;
        allFunds.push(...data);
        if (data.length < pageSize) break;
        page++;
      }
      console.log(`Fetched ${allFunds.length} fund_master records for name matching`);

      for (const casName of uniqueFundNames) {
        const match = fuzzyMatchFund(casName, allFunds);
        if (match) {
          nameToAmfi.set(casName, match.amfi_code);
          console.log(`  Matched: "${casName}" → "${match.fund_name}" (${match.amfi_code})`);
        } else {
          console.log(`  No match: "${casName}"`);
        }
      }
      console.log(`Resolved ${nameToAmfi.size}/${uniqueFundNames.length} fund names to AMFI codes`);
    }

    // ── Clean up stale Opening Balance transactions before inserting ────────
    if (partialHistoryFunds.length > 0) {
      // Resolve which member_id this upload targets
      const cleanupMemberId = fallbackMemberId
        ?? (parsed[0]?.pan ? panToMemberId.get(parsed[0].pan.toUpperCase().trim()) : null)
        ?? null;

      let deleteQuery = supabase
        .from('transactions')
        .delete()
        .eq('owner_id', ownerId)
        .eq('tx_type', 'Opening Balance')
        .eq('import_source', importSource);

      if (cleanupMemberId) {
        deleteQuery = deleteQuery.eq('member_id', cleanupMemberId);
      } else {
        deleteQuery = deleteQuery.is('member_id', null);
      }
      await deleteQuery;
      console.log(`Cleaned up existing Opening Balance transactions`);
    }

    // ── Insert transactions with dedup ──────────────────────────────────────
    let inserted = 0;
    let duplicates = 0;
    let unmatchedCount = 0;
    const errors: string[] = [];

    for (const tx of parsed) {
      try {
        const pan = tx.pan?.toUpperCase().trim();
        const memberId = (pan ? panToMemberId.get(pan) : null) ?? fallbackMemberId ?? null;
        const amfiCode = tx.amfi_code
          ?? (tx.isin ? isinToAmfi.get(tx.isin) : undefined)
          ?? (tx.fund_name ? nameToAmfi.get(tx.fund_name) : undefined);

        // tx.tx_type is already normalised during parsing (and possibly corrected
        // by portfolio validation). Do NOT re-normalise — that strips the isSell
        // context and can flip SELL back to BUY.
        const txType = tx.tx_type;

        // Dedup hash: fund + date + amount + type + folio
        const hashInput = [
          String(tx.isin ?? tx.fund_name ?? ''),
          tx.tx_date,
          String(Math.abs(tx.amount).toFixed(2)),
          txType,
          tx.folio_number ?? '',
        ].join('|');

        const hashBytes = await crypto.subtle.digest(
          'SHA-256',
          new TextEncoder().encode(hashInput)
        );
        const dedupHash = Array.from(new Uint8Array(hashBytes))
          .map((b) => b.toString(16).padStart(2, '0'))
          .join('');

        const row = {
          owner_id: ownerId,
          family_id: familyId || null,
          member_id: memberId || null,
          amfi_code: amfiCode || null,
          isin: tx.isin || null,
          asset_type: 'MF',
          asset_name: tx.fund_name || null,
          tx_date: tx.tx_date,
          tx_type: txType,
          units: tx.units || null,
          nav_at_tx: tx.nav_at_tx || null,
          amount: Math.abs(tx.amount),
          folio_number: tx.folio_number || null,
          notes: tx.amc_name ? `AMC: ${tx.amc_name}` : null,
          dedup_hash: dedupHash,
          import_source: importSource,
        };

        const { error: insertError } = await supabase
          .from('transactions')
          .insert(row);

        if (insertError) {
          if (insertError.code === '23505') {
            duplicates++;
            if (memberId) {
              await supabase
                .from('transactions')
                .update({
                  member_id: memberId,
                  family_id: familyId || null,
                  amfi_code: amfiCode || null,
                  notes: tx.amc_name ? `AMC: ${tx.amc_name}` : undefined,
                })
                .eq('dedup_hash', dedupHash);
            }
          } else {
            errors.push(`${tx.tx_date} ${tx.fund_name ?? ''}: ${insertError.message}`);
          }
        } else {
          inserted++;
          if (!memberId) unmatchedCount++;
        }
      } catch (e) {
        errors.push(String(e));
      }
    }

    // ── Update import_batches ───────────────────────────────────────────────
    if (batchId) {
      await supabase.from('import_batches').update({
        status: errors.length > 0 ? 'partial' : 'completed',
        rows_parsed: parsed.length,
        rows_inserted: inserted,
        rows_duplicate: duplicates,
        rows_error: errors.length,
        error_details: errors.length > 0 ? { errors: errors.slice(0, 20) } : null,
        completed_at: new Date().toISOString(),
      }).eq('id', batchId);
    }

    // Collect all corrections made during validation
    const allCorrections = validation.filter(v => v.corrected).flatMap(v => v.corrections);

    return new Response(
      JSON.stringify({
        inserted,
        duplicates,
        errors: errors.slice(0, 10),
        total: parsed.length,
        unmatched_pan: unmatchedCount,
        unmatched_pan_values: [...unmatchedPanValues],
        validation: validation.map(v => ({
          folio: v.folio,
          scheme: v.scheme,
          amc: v.amc,
          expected_units: v.expectedUnits,
          computed_units: v.computedUnits,
          match: v.match,
          corrected: v.corrected,
        })),
        corrections: allCorrections,
        partial_history_funds: partialHistoryFunds,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('parse-mfcentral-upload error:', err);
    return jsonError('Internal server error', 500);
  }
});

// ─── Portfolio sheet parser ─────────────────────────────────────────────────

function parsePortfolioSheet(wb: XLSX.WorkBook): PortfolioHolding[] {
  const portfolioSheetName = wb.SheetNames.find((n) =>
    n.toLowerCase().includes('portfolio')
  );
  if (!portfolioSheetName) return [];

  const ws = wb.Sheets[portfolioSheetName];
  const rows: any[][] = XLSX.utils.sheet_to_json(ws, { header: 1, raw: false, defval: '' });
  const holdings: PortfolioHolding[] = [];

  // Find header row: "Scheme Name | AMC Name | Category | Folio No. | ..."
  let headerIdx = -1;
  const cols = { scheme: -1, amc: -1, category: -1, folio: -1, invested: -1, current: -1, returns: -1, units: -1 };

  for (let i = 0; i < rows.length; i++) {
    const cells = rows[i].map((c: any) => String(c ?? '').toLowerCase().trim());
    if (cells.some(c => c.includes('scheme name')) && cells.some(c => c.includes('folio'))) {
      headerIdx = i;
      cols.scheme = cells.findIndex(c => c.includes('scheme name'));
      cols.amc = cells.findIndex(c => c.includes('amc'));
      cols.category = cells.findIndex(c => c === 'category');
      cols.folio = cells.findIndex(c => c.includes('folio'));
      cols.invested = cells.findIndex(c => c.includes('invested'));
      cols.current = cells.findIndex(c => c.includes('current'));
      cols.returns = cells.findIndex(c => c === 'returns');
      cols.units = cells.findIndex(c => c === 'units');
      break;
    }
  }

  if (headerIdx === -1) {
    console.log('Portfolio sheet: no header row found');
    return [];
  }

  for (let i = headerIdx + 1; i < rows.length; i++) {
    const row = rows[i];
    const schemeName = String(row[cols.scheme] ?? '').trim();
    if (!schemeName) continue;

    const parseNum = (idx: number) =>
      idx >= 0 ? parseFloat(String(row[idx] ?? '0').replace(/[^0-9.-]/g, '')) || 0 : 0;

    holdings.push({
      schemeName,
      amcName: cols.amc >= 0 ? String(row[cols.amc] ?? '').trim() : '',
      category: cols.category >= 0 ? String(row[cols.category] ?? '').trim() : '',
      folioNumber: cols.folio >= 0 ? String(row[cols.folio] ?? '').trim() : '',
      investedValue: parseNum(cols.invested),
      currentValue: parseNum(cols.current),
      returns: parseNum(cols.returns),
      units: parseNum(cols.units),
    });
  }

  console.log(`Portfolio sheet: ${holdings.length} holdings parsed`);
  for (const h of holdings) {
    console.log(`  ${h.schemeName} | ${h.amcName} | Folio: ${h.folioNumber} | Units: ${h.units} | Invested: ${h.investedValue} | Current: ${h.currentValue}`);
  }

  return holdings;
}

// ─── Enrich transactions with AMC & folio from Portfolio ────────────────────

function enrichWithPortfolioData(txs: ParsedTransaction[], holdings: PortfolioHolding[]) {
  if (holdings.length === 0) return;

  // Build lookup: normalised scheme key → PortfolioHolding
  const lookup = new Map<string, PortfolioHolding>();
  for (const h of holdings) {
    lookup.set(normaliseSchemeKey(h.schemeName), h);
  }

  for (const tx of txs) {
    const key = normaliseSchemeKey(tx.fund_name || '');
    const holding = lookup.get(key);
    if (!holding) continue;

    // Fill folio if missing on the transaction
    if (!tx.folio_number && holding.folioNumber) {
      tx.folio_number = holding.folioNumber;
    }
    // Attach AMC name for storage in notes
    if (holding.amcName) {
      tx.amc_name = holding.amcName;
    }
  }
}

// ─── Validate parsed transactions against Portfolio sheet ───────────────────
// Compares net units per fund. If mismatch found, tries to auto-correct by
// flipping misclassified tx_types (e.g. BUY→SELL for gifting transactions).

function validateAndCorrect(
  parsed: ParsedTransaction[],
  portfolio: PortfolioHolding[]
): ValidationEntry[] {
  if (portfolio.length === 0) return [];

  // Build portfolio lookup: normalised scheme key → holding
  const portfolioMap = new Map<string, PortfolioHolding>();
  for (const h of portfolio) {
    portfolioMap.set(normaliseSchemeKey(h.schemeName), h);
  }

  // Group parsed transactions by scheme
  const txGroups = new Map<string, ParsedTransaction[]>();
  for (const tx of parsed) {
    const key = normaliseSchemeKey(tx.fund_name || '');
    if (!key) continue;
    const group = txGroups.get(key) || [];
    group.push(tx);
    txGroups.set(key, group);
  }

  const results: ValidationEntry[] = [];

  for (const [key, holding] of portfolioMap) {
    const txs = txGroups.get(key);
    if (!txs || txs.length === 0) {
      // No transactions for this fund in the CAS date range.
      // If portfolio has units, it's partial history (purchases predate CAS range).
      const isPartial = holding.units > 0;
      results.push({
        folio: holding.folioNumber,
        scheme: holding.schemeName,
        amc: holding.amcName,
        expectedUnits: holding.units,
        computedUnits: 0,
        match: holding.units === 0 || isPartial,
        corrected: false,
        corrections: isPartial
          ? ['Partial history — all transactions predate CAS date range']
          : [],
      });
      continue;
    }

    let netUnits = computeNetUnits(txs);
    const expectedUnits = holding.units;
    const isMatch = Math.abs(netUnits - expectedUnits) < 0.01;

    // ── Partial history detection ───────────────────────────────────────
    // CAS extracts cover a date range. If older purchases are missing:
    //   - Fully exited fund (expected=0): computed will be negative
    //     (sells in range > buys in range). Mark as match — fund IS exited.
    //   - Active fund (expected>0): computed < expected because older
    //     buys are missing. Accept if all transactions make directional sense.
    const isPartialHistory =
      !isMatch &&
      (
        // Case 1: fully exited fund, computed negative (sells > buys in range)
        (expectedUnits === 0 && netUnits < 0) ||
        // Case 2: active fund, computed < expected but computed > 0
        //         (some buys missing from before CAS date range)
        (expectedUnits > 0 && netUnits >= 0 && netUnits < expectedUnits)
      );

    const entry: ValidationEntry = {
      folio: holding.folioNumber,
      scheme: holding.schemeName,
      amc: holding.amcName,
      expectedUnits,
      computedUnits: Math.round(netUnits * 1000) / 1000,
      match: isMatch || isPartialHistory,
      corrected: false,
      corrections: isPartialHistory
        ? ['Partial history — older transactions predate CAS date range']
        : [],
    };

    if (isPartialHistory) {
      console.log(`PARTIAL HISTORY: ${holding.schemeName} — expected ${expectedUnits}, computed ${netUnits} (older txns predate CAS range)`);
    } else if (!isMatch) {
      console.log(`VALIDATION MISMATCH: ${holding.schemeName} (Folio: ${holding.folioNumber})`);
      console.log(`  Expected: ${expectedUnits} units, Computed: ${netUnits} units, Diff: ${netUnits - expectedUnits}`);

      // Try auto-correction: greedily flip transactions one at a time
      let correctionsMade = 0;
      const MAX_CORRECTIONS = Math.min(txs.length, 20);

      while (correctionsMade < MAX_CORRECTIONS) {
        const currentNet = computeNetUnits(txs);
        if (Math.abs(currentNet - expectedUnits) < 0.01) break;

        let bestIdx = -1;
        let bestDistance = Math.abs(currentNet - expectedUnits);

        for (let i = 0; i < txs.length; i++) {
          const tx = txs[i];
          const u = tx.units || 0;
          if (u === 0) continue;

          const isPurchase = PURCHASE_TYPES.has(tx.tx_type);
          // Compute what net would be if this tx direction was flipped
          const testNet = isPurchase
            ? currentNet - 2 * u  // remove purchase, add sell
            : currentNet + 2 * u; // remove sell, add purchase

          const testDistance = Math.abs(testNet - expectedUnits);
          if (testDistance < bestDistance) {
            bestDistance = testDistance;
            bestIdx = i;
          }
        }

        if (bestIdx === -1 || bestDistance >= Math.abs(currentNet - expectedUnits)) {
          // No single flip improves the situation
          break;
        }

        // Apply the best correction
        const tx = txs[bestIdx];
        const oldType = tx.tx_type;
        const newType = flipTxType(oldType);
        tx.tx_type = newType;
        correctionsMade++;

        const correction = `${tx.tx_date} "${tx.fund_name}": ${oldType} → ${newType}`;
        entry.corrections.push(correction);
        console.log(`  AUTO-CORRECTED: ${correction}`);
      }

      // Recompute after corrections
      netUnits = computeNetUnits(txs);
      entry.computedUnits = Math.round(netUnits * 1000) / 1000;
      entry.match = Math.abs(netUnits - expectedUnits) < 0.01;
      entry.corrected = correctionsMade > 0;

      if (!entry.match) {
        console.log(`  UNRESOLVED: still ${netUnits} vs expected ${expectedUnits} after ${correctionsMade} corrections`);
      }
    }

    results.push(entry);
  }

  const matched = results.filter(r => r.match).length;
  const corrected = results.filter(r => r.corrected).length;
  const unresolved = results.filter(r => !r.match).length;
  console.log(`Validation summary: ${matched} matched, ${corrected} auto-corrected, ${unresolved} unresolved (of ${results.length} funds)`);

  return results;
}

function computeNetUnits(txs: ParsedTransaction[]): number {
  let net = 0;
  for (const tx of txs) {
    const u = tx.units || 0;
    if (PURCHASE_TYPES.has(tx.tx_type)) {
      net += u;
    } else {
      net -= u;
    }
  }
  return net;
}

function flipTxType(txType: string): string {
  switch (txType) {
    case 'BUY': return 'SELL';
    case 'SELL': return 'BUY';
    case 'SIP': return 'SWP';
    case 'SWP': return 'SIP';
    case 'Switch-In': return 'Switch-Out';
    case 'Switch-Out': return 'Switch-In';
    case 'STP-In': return 'STP-Out';
    case 'STP-Out': return 'STP-In';
    default: return PURCHASE_TYPES.has(txType) ? 'SELL' : 'BUY';
  }
}

// ─── Compute invested cost using weighted-average cost basis ─────────────────
function computeInvestedCost(txs: ParsedTransaction[]): number {
  const sorted = [...txs].sort((a, b) => a.tx_date.localeCompare(b.tx_date));
  let units = 0;
  let invested = 0;
  for (const tx of sorted) {
    const u = tx.units || 0;
    if (PURCHASE_TYPES.has(tx.tx_type)) {
      units += u;
      invested += Math.abs(tx.amount);
    } else {
      if (units > 0 && u > 0) {
        const sellRatio = Math.min(u / units, 1);
        invested -= invested * sellRatio;
      }
      units -= u;
    }
  }
  return invested;
}

// ─── Generate Opening Balance transactions for partial-history funds ─────────
interface PartialHistoryFund {
  scheme: string;
  folio: string;
  invested_gap: number;
  units_gap: number;
}

function generateOpeningBalances(
  parsed: ParsedTransaction[],
  portfolio: PortfolioHolding[],
  validation: ValidationEntry[],
): PartialHistoryFund[] {
  if (portfolio.length === 0) return [];

  const partialFunds: PartialHistoryFund[] = [];

  // Build transaction groups by normalised scheme key
  const txGroups = new Map<string, ParsedTransaction[]>();
  for (const tx of parsed) {
    const key = normaliseSchemeKey(tx.fund_name || '');
    if (!key) continue;
    const group = txGroups.get(key) || [];
    group.push(tx);
    txGroups.set(key, group);
  }

  for (const holding of portfolio) {
    const key = normaliseSchemeKey(holding.schemeName);
    const txs = txGroups.get(key) || [];

    // Only process funds with positive units (active holdings)
    if (holding.units <= 0) continue;

    // Compute what we have from transactions
    const computedUnits = computeNetUnits(txs);
    const computedInvested = txs.length > 0 ? computeInvestedCost(txs) : 0;

    // Compute gaps
    const unitsGap = holding.units - computedUnits;
    const investedGap = holding.investedValue - computedInvested;

    // Only create Opening Balance if there's a meaningful invested gap
    // and the portfolio shows more invested than our transactions
    if (investedGap < 1 || unitsGap < 0.001) continue;

    // Determine tx_date: one day before earliest transaction, or 2022-12-31
    let txDate = '2022-12-31';
    if (txs.length > 0) {
      const dates = txs.map(t => t.tx_date).sort();
      const earliest = new Date(dates[0]);
      earliest.setDate(earliest.getDate() - 1);
      txDate = earliest.toISOString().split('T')[0];
    }

    // Implied NAV at opening
    const impliedNav = unitsGap > 0 ? investedGap / unitsGap : 0;

    // Get fund details from first matching transaction or holding
    const refTx = txs.length > 0 ? txs[0] : null;

    const openingTx: ParsedTransaction = {
      tx_date: txDate,
      isin: refTx?.isin,
      amfi_code: refTx?.amfi_code,
      fund_name: refTx?.fund_name || holding.schemeName,
      units: Math.round(unitsGap * 10000) / 10000,
      nav_at_tx: Math.round(impliedNav * 10000) / 10000,
      amount: Math.round(investedGap * 100) / 100,
      tx_type: 'Opening Balance',
      folio_number: refTx?.folio_number || holding.folioNumber,
      pan: refTx?.pan,
      amc_name: refTx?.amc_name || holding.amcName,
      import_source: 'mfcentral_excel',
    };

    parsed.push(openingTx);

    // Update the validation entry corrections
    const valEntry = validation.find(v => normaliseSchemeKey(v.scheme) === key);
    if (valEntry) {
      valEntry.corrections.push(
        `Opening Balance created: ₹${investedGap.toFixed(0)} invested, ${unitsGap.toFixed(4)} units (pre-CAS purchases)`
      );
    }

    partialFunds.push({
      scheme: holding.schemeName,
      folio: holding.folioNumber,
      invested_gap: Math.round(investedGap * 100) / 100,
      units_gap: Math.round(unitsGap * 10000) / 10000,
    });

    console.log(`OPENING BALANCE: ${holding.schemeName} — ₹${investedGap.toFixed(2)} invested, ${unitsGap.toFixed(4)} units gap`);
  }

  return partialFunds;
}

function normaliseSchemeKey(schemeName: string): string {
  return (schemeName || '')
    .replace(/\([^)]*\)/g, '')        // remove parenthetical notes (erstwhile, merged, etc.)
    .replace(/\berstwhile\b.*/i, '')  // remove "erstwhile..." suffix
    .replace(/\s*-\s*(direct|regular)\s*(plan)?/gi, '') // remove plan type
    .replace(/\s*-?\s*(growth|dividend|idcw)\s*(option|plan)?/gi, '') // remove growth/dividend
    .replace(/\s*-?\s*payout\b/gi, '')
    .replace(/\s*-?\s*reinvestment\b/gi, '')
    .replace(/[^a-zA-Z0-9\s]/g, ' ') // punctuation → space
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase();
}

// ─── Transaction sheet parser ───────────────────────────────────────────────
// Handles MF Central CAS format:
//   - Two sheets: "Portfolio Details" and "Transaction Details"
//   - Transaction sheet may be a flat table or multi-section (one per scheme)
//   - Top rows contain investor metadata; header row detected by column keywords

function parseTransactionSheet(wb: XLSX.WorkBook): ParsedTransaction[] {
  const results: ParsedTransaction[] = [];

  console.log(`Workbook sheets: ${wb.SheetNames.join(', ')}`);

  // Prefer the "Transaction" sheet; fall back to all sheets
  const txSheetName = wb.SheetNames.find((n) => n.toLowerCase().includes('transaction'));
  const sheetsToProcess = txSheetName ? [txSheetName] : wb.SheetNames;
  console.log(`Processing sheets: ${sheetsToProcess.join(', ')}`);

  for (const sheetName of sheetsToProcess) {
    const ws = wb.Sheets[sheetName];
    const rows: any[][] = XLSX.utils.sheet_to_json(ws, { header: 1, raw: false, defval: '' });
    if (rows.length < 2) continue;

    console.log(`Sheet "${sheetName}": ${rows.length} rows`);
    for (let i = 0; i < Math.min(5, rows.length); i++) {
      console.log(`  Row[${i}]: ${JSON.stringify(rows[i])}`);
    }

    // ── Extract sheet-level PAN from metadata header ──
    let sheetPan: string | undefined;
    for (let i = 0; i < Math.min(10, rows.length); i++) {
      const cells = rows[i].map((v: any) => String(v ?? '').trim());
      const panLabelIdx = cells.findIndex((c: string) => /^PAN$/i.test(c));
      if (panLabelIdx >= 0) {
        for (let j = panLabelIdx + 1; j < cells.length; j++) {
          if (cells[j]) {
            sheetPan = cells[j].toUpperCase().trim();
            break;
          }
        }
        if (sheetPan) {
          console.log(`  Sheet-level PAN found: ${sheetPan}`);
          break;
        }
      }
    }

    // Find ALL header rows (CAS may have one per folio section)
    const headerRowIndices: number[] = [];
    for (let i = 0; i < rows.length; i++) {
      if (isHeaderRow(rows[i])) headerRowIndices.push(i);
    }

    console.log(`  Header rows found at indices: [${headerRowIndices.join(', ')}]`);

    if (headerRowIndices.length === 0) {
      console.log(`  No header rows found — skipping sheet "${sheetName}"`);
      continue;
    }

    for (let h = 0; h < headerRowIndices.length; h++) {
      const headerRowIndex = headerRowIndices[h];
      const nextHeaderIndex = headerRowIndices[h + 1] ?? rows.length;
      const headerRow = rows[headerRowIndex];
      const cols = detectColumns(headerRow);
      if (cols.date === -1 || cols.amount === -1) continue;

      // Look above this header for fund name / folio context
      let contextFundName: string | undefined;
      let contextFolio: string | undefined;
      let contextPan: string | undefined;
      for (let c = headerRowIndex - 1; c >= Math.max(0, headerRowIndex - 5); c--) {
        const ctx = rows[c].map((v: any) => String(v ?? '').trim()).join(' ');
        const folioMatch = ctx.match(/(?:Folio\s*(?:No|Number)?[:\s]+)?([0-9]+[/\-][0-9]+)/i);
        if (folioMatch && !contextFolio) contextFolio = folioMatch[1];
        const fundMatch = ctx.match(/Fund\s*(?:Name)?[:\s]+(.+)/i);
        if (fundMatch && !contextFundName) contextFundName = fundMatch[1].trim();
        const panMatch = ctx.match(/[A-Z]{5}[0-9]{4}[A-Z]/);
        if (panMatch && !contextPan) contextPan = panMatch[0];
        if (!contextPan) {
          const labelMatch = ctx.match(/\bPAN\b[:\s]+(\S+)/i);
          if (labelMatch) contextPan = labelMatch[1].toUpperCase().trim();
        }
        if (!contextFundName && ctx.length > 20 && ctx.length < 200) {
          const candidate = rows[c].find((v: any) => String(v).trim().length > 15);
          if (candidate) contextFundName = String(candidate).trim();
        }
      }

      for (let i = headerRowIndex + 1; i < nextHeaderIndex; i++) {
        const row = rows[i];
        const rawDate = String(row[cols.date] ?? '').trim();
        const rawAmount = String(row[cols.amount] ?? '').replace(/[^0-9.-]/g, '');
        const rawUnits = cols.units >= 0 ? String(row[cols.units] ?? '').replace(/[^0-9.-]/g, '') : '';
        const rawNav = cols.nav >= 0 ? String(row[cols.nav] ?? '').replace(/[^0-9.-]/g, '') : '';

        if (!rawDate) continue;
        const txDate = parseDate(rawDate);
        if (!txDate) continue;
        const amount = parseFloat(rawAmount);
        const units = parseFloat(rawUnits);
        const nav = parseFloat(rawNav);
        if ((isNaN(amount) || amount === 0) && (isNaN(units) || units === 0)) continue;

        const isin = cols.isin >= 0 ? String(row[cols.isin] ?? '').trim() || undefined : undefined;
        const rowFundName = cols.fundName >= 0 ? String(row[cols.fundName] ?? '').trim() || undefined : undefined;
        const description = cols.txType >= 0 ? String(row[cols.txType] ?? '').trim() : '';
        const rowFolio = cols.folio >= 0 ? String(row[cols.folio] ?? '').trim() || undefined : undefined;
        const rowPan = cols.pan >= 0 ? String(row[cols.pan] ?? '').trim() || undefined : undefined;

        // Primary: sign of units/amount determines BUY vs SELL
        // Secondary: refine using description for SIP, SWP, STP, Switch, etc.
        const isSell = (units < 0) || (amount < 0);
        const txType = normaliseType(description, isSell);

        results.push({
          tx_date: txDate,
          isin,
          fund_name: rowFundName || contextFundName,
          units: isNaN(units) ? undefined : Math.abs(units),
          nav_at_tx: isNaN(nav) || nav === 0 ? undefined : nav,
          amount: isNaN(amount) ? 0 : Math.abs(amount),
          tx_type: txType,
          folio_number: rowFolio || contextFolio,
          pan: rowPan || contextPan || sheetPan,
          import_source: 'mfcentral_excel',
        });
      }
    }
  }

  return results;
}

/** True if a row looks like a transaction table header */
function isHeaderRow(row: any[]): boolean {
  const cells = row.map((c) => String(c ?? '').toLowerCase().trim());
  const hasDate = cells.some((c) =>
    c === 'date' || c === 'txn date' || c === 'trans date' ||
    c.includes('transaction date') || c.includes('trxn date') || c.includes('trade date')
  );
  const hasAmount = cells.some((c) =>
    c.includes('amount') || c === 'value' || c === 'net amount' ||
    c === 'transaction amount' || c === 'purchase amount'
  );
  const hasUnits = cells.some((c) => c === 'units' || c === 'unit' || c.includes('unit'));
  const hasScheme = cells.some((c) =>
    c.includes('scheme') || c.includes('fund name') || c.includes('fund')
  );
  return hasDate && (hasAmount || hasUnits || hasScheme);
}

// ─── PDF parser stub ────────────────────────────────────────────────────────
async function parsePdf(_bytes: Uint8Array): Promise<ParsedTransaction[]> {
  console.warn('PDF parsing: stub implementation. No transactions extracted.');
  return [];
}

// ─── Column detection ───────────────────────────────────────────────────────
function detectColumns(headerRow: any[]) {
  const cells = headerRow.map((c) => String(c ?? '').toLowerCase().trim());
  console.log(`  detectColumns header: ${JSON.stringify(cells)}`);

  const find = (keywords: string[]) =>
    cells.findIndex((c) => keywords.some((kw) => c.includes(kw)));

  return {
    date:     find(['transaction date', 'txn date', 'trans date', 'trade date', 'date']),
    isin:     find(['isin']),
    fundName: find(['scheme name', 'fund name', 'scheme', 'fund']),
    units:    find(['units', 'unit', 'quantity']),
    nav:      find(['nav', 'price']),
    amount:   find(['net amount', 'transaction amount', 'purchase amount', 'amount', 'value']),
    txType:   find(['transaction type', 'txn type', 'trans type', 'type', 'description', 'narration', 'particulars']),
    folio:    find(['folio']),
    pan:      find(['pan']),
  };
}

// ─── Helpers ────────────────────────────────────────────────────────────────

function parseDate(s: string): string | undefined {
  if (!s) return undefined;
  const dmy = s.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/);
  if (dmy) return `${dmy[3]}-${dmy[2].padStart(2, '0')}-${dmy[1].padStart(2, '0')}`;
  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
  const dmonY = s.match(/^(\d{1,2})[\/\-]([A-Za-z]{3})[\/\-](\d{4})$/);
  if (dmonY) {
    const months: Record<string, string> = {
      jan:'01',feb:'02',mar:'03',apr:'04',may:'05',jun:'06',
      jul:'07',aug:'08',sep:'09',oct:'10',nov:'11',dec:'12',
    };
    const m = months[dmonY[2].toLowerCase()];
    if (m) return `${dmonY[3]}-${m}-${dmonY[1].padStart(2, '0')}`;
  }
  const serial = parseFloat(s);
  if (!isNaN(serial) && serial > 1) {
    const d = new Date(new Date(1899, 11, 30).getTime() + serial * 86400000);
    return d.toISOString().substring(0, 10);
  }
  return undefined;
}

// ─── Fuzzy fund name matching ───────────────────────────────────────────────
function fuzzyMatchFund(
  casName: string,
  allFunds: { amfi_code: number; fund_name: string }[]
): { amfi_code: number; fund_name: string } | null {
  const cleaned = casName
    .replace(/\([^)]*(?:formerly|erstwhile|earlier|merged)[^)]*\)/gi, '')
    .replace(/\s+/g, ' ')
    .trim()
    .toUpperCase();

  const noise = new Set(['THE', 'OF', 'AND', 'FOR', 'IN', 'A', 'AN', 'TO', 'OR']);
  const casTokens = cleaned.split(/[\s\-–/]+/).filter(t => t.length > 1 && !noise.has(t));
  if (casTokens.length === 0) return null;

  const isRegular = /REGULAR/i.test(casName);
  const isDirect = /DIRECT/i.test(casName);
  const isGrowth = /GROWTH/i.test(casName);

  let bestMatch: { amfi_code: number; fund_name: string } | null = null;
  let bestScore = 0;

  for (const fund of allFunds) {
    const masterUpper = fund.fund_name.toUpperCase();

    let matched = 0;
    for (const token of casTokens) {
      if (masterUpper.includes(token)) matched++;
    }

    const ratio = matched / casTokens.length;
    if (ratio < 0.6) continue;

    let score = ratio * 100;

    if (isRegular && masterUpper.includes('REGULAR')) score += 10;
    if (isDirect && masterUpper.includes('DIRECT')) score += 10;
    if (isRegular && masterUpper.includes('DIRECT')) score -= 20;
    if (isDirect && masterUpper.includes('REGULAR')) score -= 20;
    if (isGrowth && masterUpper.includes('GROWTH')) score += 5;
    if (isGrowth && (masterUpper.includes('IDCW') || masterUpper.includes('DIVIDEND'))) score -= 15;

    if (score > bestScore) {
      bestScore = score;
      bestMatch = fund;
    }
  }

  return bestScore >= 60 ? bestMatch : null;
}

function normaliseType(description: string, isSell: boolean): string {
  const u = (description || '').toUpperCase().trim();
  // Normalise "S T P" → "STP" (some AMCs space it out)
  const uNorm = u.replace(/\bS\s+T\s+P\b/g, 'STP');

  // ── Outflow keywords: always treat as SELL regardless of sign ──────────
  if (uNorm.includes('REDEMPTION') || uNorm.includes('REPURCHASE') || uNorm.includes('REDEEMED')) return 'SELL';
  if (uNorm.includes('GIFTING') || uNorm.includes('GIFT OF UNITS') || uNorm.includes('GIFTED')) return 'SELL';
  if (uNorm.includes('TRANSFER OUT') || uNorm.includes('TRANSFERRED OUT') || uNorm.includes('TRANSFER-OUT')) return 'SELL';

  // ── Inflow keywords ───────────────────────────────────────────────────
  if (uNorm.includes('TRANSFER IN') || uNorm.includes('TRANSFERRED IN') || uNorm.includes('TRANSFER-IN')) return 'BUY';

  // ── SWP ────────────────────────────────────────────────────────────────
  if (uNorm.includes('SWP')) return 'SWP';

  // ── STP — check explicit "IN"/"OUT" in the text ────────────────────────
  if (uNorm.includes('STP') && uNorm.includes('OUT')) return 'STP-Out';
  if (uNorm.includes('STP') && uNorm.includes('IN')) return 'STP-In';
  if (uNorm.includes('STP')) return isSell ? 'STP-Out' : 'STP-In';

  // ── Switch / Lateral Shift ────────────────────────────────────────────
  // CRITICAL: Check explicit "SWITCH IN" / "SWITCH OUT" FIRST.
  // MF Central uses "Switch In - From [source fund]" and
  // "Switch Out - To [target fund]". The FROM/TO refers to the
  // counterpart fund, NOT the direction — so never use FROM/TO to infer direction.
  if (uNorm.includes('SWITCH IN') || uNorm.includes('SWITCH-IN') || uNorm.includes('LATERAL SHIFT IN')) return 'Switch-In';
  if (uNorm.includes('SWITCH OUT') || uNorm.includes('SWITCH-OUT') || uNorm.includes('LATERAL SHIFT OUT')) return 'Switch-Out';
  if (uNorm.includes('SWITCH') || uNorm.includes('LATERAL SHIFT')) return isSell ? 'Switch-Out' : 'Switch-In';

  // ── Dividend / Bonus ──────────────────────────────────────────────────
  if (uNorm.includes('IDCW') || uNorm.includes('DIVIDEND') || uNorm.includes('DIV PAYOUT')) return 'IDCW';
  if (uNorm.includes('BONUS')) return 'Bonus';
  if (uNorm.includes('SYSTEMATIC') || uNorm.includes('SIP')) return isSell ? 'SELL' : 'SIP';

  // ── Ultimate fallback: sign of units/amount decides direction ─────────
  return isSell ? 'SELL' : 'BUY';
}
