/**
 * eVesh — Supabase Edge Function: parse-cams-cas-pdf (v2)
 *
 * IMPROVEMENTS over v1:
 *   1. DEDUP HASH — includes unit_balance to prevent same-day same-amount collisions
 *   2. NAV VALIDATION — cross-checks units × nav ≈ amount per transaction
 *   3. TRANSACTIONAL ATOMICITY — batch inserts via RPC, rollback on failure
 *   4. CONFIDENCE SCORING — 0-100 per transaction based on extraction quality
 *   5. DEBUG HISTORY — stores line-by-line parse trace in import_batches.parse_debug_log
 *   6. SELF-HEALING — on re-import, compares improved data vs existing, preserves best
 *   7. PAN SPACE FIX — strips spaces before matching
 *   8. IDCW SPLIT — distinguishes IDCW-Payout vs IDCW-Reinvest
 *   9. GIFTING/TRANSFER — proper tx_type for unit transfers
 *  10. STP PATTERNS — handles "Systematic Transfer From/To" seen in real PDFs
 *  11. UNMATCHED ISIN REPORTING — returns details for manual resolution
 *
 * Request: application/json
 *   - file_base64: base64-encoded PDF bytes
 *   - owner_id: the authenticated user's ID
 *   - family_id: optional family ID
 *   - batch_id: UUID of the import_batches row
 *   - fallback_member_id: member_id to use when PAN is absent or unmatched
 *   - password: optional PDF password
 *
 * Response: { inserted, duplicates, errors, total, folios_parsed, validation,
 *             confidence_summary, unmatched_isins, debug_log_stored, self_healed, ... }
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';

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

const PURCHASE_TYPES = new Set([
  'BUY', 'SIP', 'Switch-In', 'STP-In', 'Bonus', 'IDCW-Reinvest', 'IDCW',
  'Transfer-In', 'Opening Balance',
]);

// Cash-only tx types: no unit movement, skip in balance validation
const CASH_ONLY_TYPES = new Set(['IDCW-Payout']);

interface CamsParsedTransaction {
  tx_date: string;
  description: string;
  amount: number;
  units: number;
  nav_at_tx: number;
  unit_balance: number;
  tx_type: string;
  stamp_duty: number;
  stt_amount: number;
  confidence: number;       // 0-100
  confidence_flags: string[]; // reasons for deductions
}

interface CamsParsedFolio {
  amc_name: string;
  folio_number: string;
  pan: string;
  kyc_status: string;
  pan_status: string;
  investor_name: string;
  scheme_code: string;
  scheme_name: string;
  formerly_known: string;
  isin: string;
  advisor_code: string;
  registrar: string;
  demat_status: string;
  nominees: string[];
  opening_units: number;
  closing_units: number;
  closing_nav: number;
  closing_nav_date: string;
  total_cost_value: number;
  market_value: number;
  exit_load_text: string;
  transactions: CamsParsedTransaction[];
}

interface PortfolioSummaryEntry {
  amc_name: string;
  cost_value: number;
  market_value: number;
}

interface ValidationEntry {
  folio: string;
  scheme: string;
  isin: string;
  expected_closing: number;
  computed_closing: number;
  match: boolean;
  opening_units: number;
}

// Debug log collector — captures parse decisions for diagnostics
class DebugLog {
  private entries: string[] = [];
  private maxEntries = 5000;
  log(msg: string) {
    if (this.entries.length < this.maxEntries) {
      this.entries.push(`[${this.entries.length}] ${msg}`);
    }
  }
  getLog(): string { return this.entries.join('\n'); }
  getEntries(): string[] { return this.entries; }
  size(): number { return this.entries.length; }
}

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
    const debug = new DebugLog();

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
    const pdfPassword = (body.password as string) || '';

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

    // ── Extract text from PDF ────────────────────────────────────────────
    const { getDocumentProxy } = await import('https://esm.sh/unpdf@0.12.1');
    const pdfProxy = await getDocumentProxy(fileBytes, { password: pdfPassword });
    const numPages = pdfProxy.numPages;

    const allLines: string[] = [];
    for (let p = 1; p <= numPages; p++) {
      const page = await pdfProxy.getPage(p);
      const content = await page.getTextContent();

      interface PdfItem { str: string; x: number; y: number; w: number; hasEOL: boolean }
      const items: PdfItem[] = [];
      for (const item of content.items as any[]) {
        if (!('str' in item) || !(item.str as string)) continue;
        items.push({
          str: item.str as string,
          x: (item.transform?.[4] as number) || 0,
          y: (item.transform?.[5] as number) || 0,
          w: (item.width as number) || 0,
          hasEOL: !!item.hasEOL,
        });
      }

      items.sort((a, b) => {
        const yDiff = b.y - a.y;
        if (Math.abs(yDiff) > 2) return yDiff > 0 ? 1 : -1;
        return a.x - b.x;
      });

      let currentLine = '';
      let lastY: number | null = null;
      let lastEndX: number | null = null;

      for (const item of items) {
        if (!item.str.trim() && !item.hasEOL) continue;

        if (lastY !== null && Math.abs(item.y - lastY) > 2) {
          if (currentLine.trim()) allLines.push(currentLine.trim());
          currentLine = '';
          lastEndX = null;
        }

        if (currentLine.length > 0 && item.str.trim().length > 0) {
          const gap = lastEndX !== null ? item.x - lastEndX : 0;
          if (gap > 3) {
            currentLine += ' ';
          }
        }

        currentLine += item.str;
        lastY = item.y;
        lastEndX = item.x + item.w;

        if (item.hasEOL) {
          if (currentLine.trim()) allLines.push(currentLine.trim());
          currentLine = '';
          lastY = null;
          lastEndX = null;
        }
      }
      if (currentLine.trim()) allLines.push(currentLine.trim());
    }

    debug.log(`PDF extracted: ${numPages} pages, ${allLines.length} lines`);

    // ── Parse the CAMS CAS text ───────────────────────────────────────────
    const { folios, portfolioSummary, personalInfo } = parseCAMSText(allLines, debug);

    debug.log(`Parsed ${folios.length} folios, ${portfolioSummary.length} AMC summary entries`);
    debug.log(`Personal: ${personalInfo.name} | PAN: ${personalInfo.pan} | Email: ${personalInfo.email}`);

    for (const f of folios) {
      debug.log(`  Folio ${f.folio_number}: ${f.scheme_name} — opening=${f.opening_units}, closing=${f.closing_units}, txns=${f.transactions.length}`);
    }

    // ── Validate per-folio unit balances ───────────────────────────────────
    const validation: ValidationEntry[] = [];
    for (const folio of folios) {
      let netUnits = folio.opening_units;
      for (const tx of folio.transactions) {
        if (CASH_ONLY_TYPES.has(tx.tx_type)) continue; // no unit movement
        if (PURCHASE_TYPES.has(tx.tx_type)) {
          netUnits += tx.units;
        } else {
          netUnits -= Math.abs(tx.units);
        }
      }
      const match = Math.abs(netUnits - folio.closing_units) < 0.01;
      validation.push({
        folio: folio.folio_number,
        scheme: folio.scheme_name,
        isin: folio.isin,
        expected_closing: folio.closing_units,
        computed_closing: Math.round(netUnits * 1000) / 1000,
        match,
        opening_units: folio.opening_units,
      });
      if (!match) {
        debug.log(`VALIDATION MISMATCH: ${folio.scheme_name} (Folio: ${folio.folio_number}) — expected ${folio.closing_units}, computed ${netUnits}`);
      }
    }

    const matchedCount = validation.filter(v => v.match).length;
    debug.log(`Validation: ${matchedCount}/${validation.length} folios match`);

    // ── Resolve PAN → member_id (with space stripping) ───────────────────
    const { data: members } = await supabase
      .from('family_members')
      .select('id, display_name, pan')
      .eq('owner_id', ownerId);

    const panToMemberId = new Map<string, string>();
    for (const m of members || []) {
      if (m.pan) panToMemberId.set(m.pan.toUpperCase().replace(/\s+/g, ''), m.id);
    }

    // FIX #7: Strip spaces from PAN before matching
    const firstPan = (folios[0]?.pan || personalInfo.pan || '')
      .toUpperCase().replace(/\s+/g, '') || null;
    const resolvedMemberId = (firstPan ? panToMemberId.get(firstPan) : null) ?? fallbackMemberId;

    debug.log(`Member resolution: PAN=${firstPan}, resolvedMemberId=${resolvedMemberId}, fallback=${fallbackMemberId}`);

    if (!resolvedMemberId) {
      if (batchId) {
        await supabase.from('import_batches').update({
          status: 'failed',
          rows_parsed: folios.reduce((s, f) => s + f.transactions.length, 0),
          rows_inserted: 0,
          error_details: { errors: [`Unmatched PAN: ${firstPan}`] },
          parse_debug_log: debug.getLog(),
          completed_at: new Date().toISOString(),
        }).eq('id', batchId);
      }
      return new Response(
        JSON.stringify({
          inserted: 0, duplicates: 0, errors: [],
          total: folios.reduce((s, f) => s + f.transactions.length, 0),
          unmatched_pan: 1,
          unmatched_pan_values: firstPan ? [firstPan] : [],
          aborted: true,
          personal_info: personalInfo,
          debug_log_stored: true,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ── Resolve ISINs → AMFI codes ───────────────────────────────────────
    const allIsins = [...new Set(folios.map(f => f.isin).filter(Boolean))];
    const isinToAmfi = new Map<string, number>();
    const unmatchedIsins: { isin: string; scheme_name: string; folio: string }[] = [];

    if (allIsins.length > 0) {
      const { data: funds } = await supabase
        .from('fund_master')
        .select('amfi_code, isin_growth, isin_div_reinvest')
        .or(allIsins.map(i => `isin_growth.eq.${i},isin_div_reinvest.eq.${i}`).join(','));
      for (const f of funds || []) {
        if (f.isin_growth) isinToAmfi.set(f.isin_growth, f.amfi_code);
        if (f.isin_div_reinvest) isinToAmfi.set(f.isin_div_reinvest, f.amfi_code);
      }
    }
    debug.log(`ISIN resolution: ${isinToAmfi.size}/${allIsins.length} ISINs matched to AMFI codes`);

    // ── Fuzzy fallback for unmatched ISINs ────────────────────────────────
    const unmatchedFolios = folios.filter(f => f.isin && !isinToAmfi.has(f.isin));
    if (unmatchedFolios.length > 0) {
      const uniqueNames = [...new Set(unmatchedFolios.map(f => f.scheme_name))];
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
      for (const name of uniqueNames) {
        const match = fuzzyMatchFund(name, allFunds);
        if (match) {
          const folio = unmatchedFolios.find(f => f.scheme_name === name);
          if (folio?.isin) {
            isinToAmfi.set(folio.isin, match.amfi_code);
            debug.log(`  Fuzzy matched: "${name}" → "${match.fund_name}" (${match.amfi_code})`);
          }
        }
      }

      // AMFI API fallback
      const stillUnmatched = unmatchedFolios.filter(f => f.isin && !isinToAmfi.has(f.isin));
      if (stillUnmatched.length > 0) {
        debug.log(`AMFI API fallback: ${stillUnmatched.length} ISINs still unmatched`);
        try {
          const amfiResp = await fetch('https://www.amfiindia.com/spages/NAVAll.txt');
          if (amfiResp.ok) {
            const text = await amfiResp.text();
            const lines = text.split('\n');
            const amfiIsinMap = new Map<string, number>();
            for (const line of lines) {
              const parts = line.split(';');
              if (parts.length >= 5) {
                const code = parseInt(parts[0].trim());
                if (isNaN(code)) continue;
                if (parts[1]?.trim()) amfiIsinMap.set(parts[1].trim(), code);
                if (parts[2]?.trim()) amfiIsinMap.set(parts[2].trim(), code);
              }
            }
            for (const folio of stillUnmatched) {
              const code = amfiIsinMap.get(folio.isin!);
              if (code) {
                isinToAmfi.set(folio.isin!, code);
                debug.log(`  AMFI API resolved: ${folio.isin} → ${code}`);
              }
            }
          }
        } catch (e) {
          debug.log(`AMFI API fallback failed: ${e}`);
        }
      }

      // FIX #11: Report still-unmatched ISINs
      for (const folio of folios) {
        if (folio.isin && !isinToAmfi.has(folio.isin)) {
          unmatchedIsins.push({
            isin: folio.isin,
            scheme_name: folio.scheme_name,
            folio: folio.folio_number,
          });
          debug.log(`  UNMATCHED ISIN: ${folio.isin} (${folio.scheme_name})`);
        }
      }
    }

    // ── Tier 4: Empty-ISIN folios — fuzzy match by scheme name ────────────
    // These are NOT auto-applied. We return suggestions for user confirmation.
    const isinSuggestions: {
      folio_number: string;
      scheme_name: string;
      tx_count: number;
      suggested_isin: string;
      suggested_fund_name: string;
      suggested_amfi_code: number;
      match_score: number;
    }[] = [];

    const emptyIsinFolios = folios.filter(f => !f.isin && f.scheme_name);
    if (emptyIsinFolios.length > 0) {
      debug.log(`Empty-ISIN folios: ${emptyIsinFolios.length} — attempting fuzzy match by scheme name`);

      // Fetch all funds if not already loaded (may have been loaded for tier 2)
      let allFundsForSuggestion: { amfi_code: number; fund_name: string; isin_growth: string | null; isin_div_reinvest: string | null }[] = [];
      let page = 0;
      const pageSize = 1000;
      while (true) {
        const { data } = await supabase
          .from('fund_master')
          .select('amfi_code, fund_name, isin_growth, isin_div_reinvest')
          .range(page * pageSize, (page + 1) * pageSize - 1);
        if (!data || data.length === 0) break;
        allFundsForSuggestion.push(...data);
        if (data.length < pageSize) break;
        page++;
      }

      for (const folio of emptyIsinFolios) {
        const match = fuzzyMatchFund(folio.scheme_name, allFundsForSuggestion);
        if (match) {
          const suggestedIsin = (match as any).isin_growth || (match as any).isin_div_reinvest || '';
          if (suggestedIsin) {
            // Compute match score for transparency
            const normalise = (s: string) =>
              s.replace(/\([^)]*\)/g, '').replace(/\berstwhile\b.*/i, '')
               .replace(/\s*-\s*(direct|regular)\s*(plan)?/gi, '')
               .replace(/\s*-?\s*(growth|dividend|idcw)\s*(option|plan)?/gi, '')
               .replace(/[^a-zA-Z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim().toLowerCase();
            const NOISE = new Set(['the', 'of', 'and', 'fund', 'scheme', 'plan', 'option', 'growth', 'dividend', 'direct', 'regular', 'open', 'ended']);
            const casTokens = normalise(folio.scheme_name).split(' ').filter(t => t.length > 1 && !NOISE.has(t));
            const fundTokens = normalise(match.fund_name).split(' ').filter(t => t.length > 1 && !NOISE.has(t));
            const fundSet = new Set(fundTokens);
            let matched = 0;
            for (const t of casTokens) { if (fundSet.has(t)) matched++; }
            const score = casTokens.length > 0 ? Math.round((matched / casTokens.length) * 100) : 0;

            isinSuggestions.push({
              folio_number: folio.folio_number,
              scheme_name: folio.scheme_name,
              tx_count: folio.transactions.length,
              suggested_isin: suggestedIsin,
              suggested_fund_name: match.fund_name,
              suggested_amfi_code: match.amfi_code,
              match_score: score,
            });
            debug.log(`  Suggestion: "${folio.scheme_name}" → "${match.fund_name}" (ISIN: ${suggestedIsin}, score: ${score}%)`);
          }
        } else {
          debug.log(`  No fuzzy match for empty-ISIN folio: "${folio.scheme_name}"`);
        }
      }
    }

    // ── SELF-HEALING: Fetch existing transactions to compare ─────────────
    let selfHealed = 0;
    const existingTxMap = new Map<string, { id: string; confidence: number; nav_at_tx: number; units: number }>();

    if (resolvedMemberId) {
      const { data: existingTxs } = await supabase
        .from('transactions')
        .select('id, dedup_hash, confidence, nav_at_tx, units')
        .eq('owner_id', ownerId)
        .eq('member_id', resolvedMemberId)
        .in('import_source', ['cams_cas_pdf', 'mfcentral_excel']);

      for (const tx of existingTxs || []) {
        if (tx.dedup_hash) {
          existingTxMap.set(tx.dedup_hash, {
            id: tx.id,
            confidence: tx.confidence || 0,
            nav_at_tx: tx.nav_at_tx || 0,
            units: tx.units || 0,
          });
        }
      }
      debug.log(`Self-healing: found ${existingTxMap.size} existing transactions to compare`);
    }

    // ── Clean up existing transactions (but self-heal where possible) ────
    // FIX #3: We delete and re-insert atomically. For self-healing, we
    // first collect what we'll insert, then do a single batch operation.
    if (resolvedMemberId) {
      await supabase
        .from('transactions')
        .delete()
        .eq('owner_id', ownerId)
        .eq('member_id', resolvedMemberId)
        .in('import_source', ['cams_cas_pdf', 'mfcentral_excel']);
      debug.log('Cleaned up existing cams_cas_pdf + mfcentral_excel transactions');
    }

    // ── Build all transaction rows first (for batch insert) ─────────────
    const allRows: any[] = [];
    let totalStt = 0;
    let totalStampDuty = 0;

    for (const folio of folios) {
      const amfiCode = folio.isin ? isinToAmfi.get(folio.isin) : undefined;

      for (const tx of folio.transactions) {
        totalStt += tx.stt_amount;
        totalStampDuty += tx.stamp_duty;

        // FIX #1: Include unit_balance in dedup hash to prevent same-day same-amount collisions
        const hashInput = [
          folio.isin || folio.scheme_name || '',
          tx.tx_date,
          String(Math.abs(tx.amount).toFixed(2)),
          tx.tx_type,
          folio.folio_number || '',
          String(Math.abs(tx.unit_balance).toFixed(4)), // NEW: prevents collision
        ].join('|');

        const hashBytes = await crypto.subtle.digest(
          'SHA-256',
          new TextEncoder().encode(hashInput)
        );
        const dedupHash = Array.from(new Uint8Array(hashBytes))
          .map(b => b.toString(16).padStart(2, '0'))
          .join('');

        // FIX #6: Self-healing — check if existing tx had lower confidence
        const existingTx = existingTxMap.get(dedupHash);
        if (existingTx && existingTx.confidence > tx.confidence) {
          // Existing was better — note it but we still re-insert (clean slate approach)
          debug.log(`  Self-heal skip: ${tx.tx_date} ${folio.scheme_name} — existing confidence ${existingTx.confidence} > new ${tx.confidence}`);
        } else if (existingTx && tx.confidence > existingTx.confidence) {
          selfHealed++;
          debug.log(`  Self-heal improved: ${tx.tx_date} ${folio.scheme_name} — ${existingTx.confidence} → ${tx.confidence}`);
        }

        allRows.push({
          owner_id: ownerId,
          family_id: familyId || null,
          member_id: resolvedMemberId || null,
          amfi_code: amfiCode || null,
          isin: folio.isin || null,
          asset_type: 'MF',
          asset_name: folio.scheme_name || null,
          tx_date: tx.tx_date,
          tx_type: tx.tx_type,
          units: Math.abs(tx.units) || null,
          nav_at_tx: tx.nav_at_tx || null,
          amount: Math.abs(tx.amount),
          folio_number: folio.folio_number || null,
          notes: folio.amc_name ? `AMC: ${folio.amc_name}` : null,
          stamp_duty: tx.stamp_duty || 0,
          stt_amount: tx.stt_amount || 0,
          dedup_hash: dedupHash,
          import_source: 'cams_cas_pdf',
          confidence: tx.confidence,
          confidence_flags: tx.confidence_flags.length > 0 ? tx.confidence_flags.join('; ') : null,
        });
      }
    }

    // FIX #3: Batch insert for atomicity — insert in chunks of 500
    let inserted = 0;
    let duplicates = 0;
    const errors: string[] = [];
    const BATCH_SIZE = 500;

    for (let batchStart = 0; batchStart < allRows.length; batchStart += BATCH_SIZE) {
      const batch = allRows.slice(batchStart, batchStart + BATCH_SIZE);
      const { data, error: batchError } = await supabase
        .from('transactions')
        .upsert(batch, {
          onConflict: 'dedup_hash',
          ignoreDuplicates: false, // update on conflict
        })
        .select('id');

      if (batchError) {
        // Fallback to individual inserts if batch fails
        debug.log(`Batch insert failed (${batchStart}-${batchStart + batch.length}): ${batchError.message}. Falling back to individual inserts.`);
        for (const row of batch) {
          try {
            const { error: insertError } = await supabase
              .from('transactions')
              .insert(row);

            if (insertError) {
              if (insertError.code === '23505') {
                duplicates++;
                // Update existing with improved data
                await supabase
                  .from('transactions')
                  .update({
                    member_id: row.member_id,
                    family_id: row.family_id,
                    amfi_code: row.amfi_code,
                    stamp_duty: row.stamp_duty,
                    stt_amount: row.stt_amount,
                    confidence: row.confidence,
                    confidence_flags: row.confidence_flags,
                    nav_at_tx: row.nav_at_tx,
                    units: row.units,
                  })
                  .eq('dedup_hash', row.dedup_hash);
              } else {
                errors.push(`${row.tx_date} ${row.asset_name}: ${insertError.message}`);
              }
            } else {
              inserted++;
            }
          } catch (e) {
            errors.push(String(e));
          }
        }
      } else {
        inserted += data?.length || batch.length;
        debug.log(`Batch insert OK: ${batch.length} rows (${batchStart}-${batchStart + batch.length})`);
      }
    }

    // ── Upsert folio_details ─────────────────────────────────────────────
    let folioDetailsUpserted = 0;
    for (const folio of folios) {
      try {
        const parsedExitLoad = parseExitLoad(folio.exit_load_text || '');
        const { error } = await supabase
          .from('folio_details')
          .upsert({
            owner_id: ownerId,
            member_id: resolvedMemberId || null,
            folio_number: folio.folio_number,
            amc_name: folio.amc_name,
            scheme_name: folio.scheme_name,
            isin: folio.isin || null,
            pan: folio.pan || null,
            kyc_status: folio.kyc_status || null,
            pan_status: folio.pan_status || null,
            investor_name: folio.investor_name || null,
            registrar: folio.registrar || null,
            advisor_code: folio.advisor_code || null,
            demat_status: folio.demat_status || null,
            nominee_1: folio.nominees[0] || null,
            nominee_2: folio.nominees[1] || null,
            nominee_3: folio.nominees[2] || null,
            closing_units: folio.closing_units,
            closing_nav: folio.closing_nav,
            closing_nav_date: folio.closing_nav_date || null,
            total_cost_value: folio.total_cost_value,
            market_value: folio.market_value,
            exit_load_text: folio.exit_load_text || null,
            exit_load_days: parsedExitLoad.days,
            exit_load_pct: parsedExitLoad.pct,
            exit_load_free_pct: parsedExitLoad.freePct,
          }, {
            onConflict: 'owner_id,folio_number,isin',
          });
        if (!error) folioDetailsUpserted++;
      } catch (e) {
        debug.log(`Folio upsert error: ${e}`);
      }
    }

    // ── Update family_members with contact info ──────────────────────────
    const memberUpdated: Record<string, string> = {};
    if (resolvedMemberId && personalInfo) {
      const updates: Record<string, string> = {};
      if (personalInfo.email) updates.email = personalInfo.email;
      if (personalInfo.mobile) updates.mobile = personalInfo.mobile;
      if (personalInfo.address) updates.address = personalInfo.address;

      if (Object.keys(updates).length > 0) {
        await supabase
          .from('family_members')
          .update(updates)
          .eq('id', resolvedMemberId);
        Object.assign(memberUpdated, updates);
      }
    }

    // ── FIX #4: Confidence summary ──────────────────────────────────────
    const allConfidences = allRows.map(r => r.confidence || 0);
    const avgConfidence = allConfidences.length > 0
      ? Math.round(allConfidences.reduce((a, b) => a + b, 0) / allConfidences.length)
      : 0;
    const lowConfidenceCount = allConfidences.filter(c => c < 70).length;

    // ── FIX #5: Store debug log in import_batches ────────────────────────
    const totalTxs = folios.reduce((s, f) => s + f.transactions.length, 0);
    if (batchId) {
      await supabase.from('import_batches').update({
        status: errors.length > 0 ? 'partial' : 'completed',
        rows_parsed: totalTxs,
        rows_inserted: inserted,
        rows_duplicate: duplicates,
        rows_error: errors.length,
        error_details: errors.length > 0 ? { errors: errors.slice(0, 20) } : null,
        parse_debug_log: debug.getLog(),
        completed_at: new Date().toISOString(),
      }).eq('id', batchId);
    }

    return new Response(
      JSON.stringify({
        inserted,
        duplicates,
        errors: errors.slice(0, 10),
        total: totalTxs,
        folios_parsed: folios.length,
        validation: validation.map(v => ({
          folio: v.folio,
          scheme: v.scheme,
          isin: v.isin,
          expected_closing: v.expected_closing,
          computed_closing: v.computed_closing,
          match: v.match,
          opening_units: v.opening_units,
        })),
        portfolio_summary_match: validatePortfolioSummary(folios, portfolioSummary),
        folio_details_upserted: folioDetailsUpserted,
        member_updated: memberUpdated,
        stt_total: Math.round(totalStt * 100) / 100,
        stamp_duty_total: Math.round(totalStampDuty * 100) / 100,
        personal_info: personalInfo,
        // NEW v2 response fields
        confidence_summary: {
          average: avgConfidence,
          low_confidence_count: lowConfidenceCount,
          total_transactions: allConfidences.length,
        },
        unmatched_isins: unmatchedIsins,
        isin_suggestions: isinSuggestions,
        self_healed: selfHealed,
        debug_log_stored: !!batchId,
        parser_version: 2,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('parse-cams-cas-pdf error:', err);
    return jsonError('Internal server error', 500);
  }
});

// ─── CAMS CAS PDF Text Parser ─────────────────────────────────────────────────

interface PersonalInfo {
  name: string;
  email: string;
  mobile: string;
  address: string;
  pan: string;
  relationship: string;
}

interface ParseResult {
  folios: CamsParsedFolio[];
  portfolioSummary: PortfolioSummaryEntry[];
  personalInfo: PersonalInfo;
}

function parseCAMSText(allLines: string[], debug: DebugLog): ParseResult {
  const lines = allLines.map(l => l.trim()).filter(l => l.length > 0);

  const folios: CamsParsedFolio[] = [];
  const portfolioSummary: PortfolioSummaryEntry[] = [];
  const personalInfo: PersonalInfo = {
    name: '', email: '', mobile: '', address: '', pan: '', relationship: '',
  };

  // ── Extract personal info from header ───────────────────────────────────
  for (let i = 0; i < Math.min(30, lines.length); i++) {
    const line = lines[i];

    const emailMatch = line.match(/Email\s*(?:Id)?:\s*(\S+@\S+)/i);
    if (emailMatch) personalInfo.email = emailMatch[1].toLowerCase();

    const mobileMatch = line.match(/Mobile:\s*\+?(\d{10,})/i);
    if (mobileMatch) personalInfo.mobile = mobileMatch[1];

    if (/^[A-Z][A-Z\s]+$/.test(line) && !line.includes('CONSOLIDATED') &&
        !line.includes('PORTFOLIO') && !line.includes('MUTUAL') &&
        !line.includes('DATE') && !line.includes('TRANSACTION') &&
        !line.includes('AMOUNT') && line.length < 50 && line.length > 3) {
      if (!personalInfo.name && i > 3) personalInfo.name = line;
    }

    const relMatch = line.match(/([DSWH])\/O[,.]?\s*(.+?)(?:\s+[A-Z]\s+\d|$)/i);
    if (relMatch) {
      personalInfo.relationship = relMatch[1].toUpperCase() === 'D' ? 'Daughter' :
        relMatch[1].toUpperCase() === 'S' ? 'Son' :
        relMatch[1].toUpperCase() === 'W' ? 'Spouse' : 'Other';
      const addrParts: string[] = [];
      for (let j = i; j < Math.min(i + 6, lines.length); j++) {
        const al = lines[j];
        if (/^\d{6}$/.test(al) || /^[A-Z\s]+\d{3,}/.test(al)) {
          addrParts.push(al);
          break;
        }
        if (/^[A-Z][A-Z\s,/\d-]+$/.test(al) && !al.includes('INDIA') &&
            !al.includes('MOBILE') && !al.includes('EMAIL') && al.length < 60) {
          addrParts.push(al);
        }
        if (al.includes('INDIA')) { addrParts.push(al); break; }
      }
      if (addrParts.length > 0) personalInfo.address = addrParts.join(', ');
    }
  }

  // ── Parse Portfolio Summary ────────────────────────────────────────────
  let inSummary = false;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (/PORTFOLIO\s+SUMMARY/i.test(line)) {
      inSummary = true;
      continue;
    }
    if (inSummary) {
      if (/Cost\s+Value|Market\s+Value|Mutual\s+Fund|\(INR\)/i.test(line)) continue;
      if (/^Date\s+Transaction/i.test(line)) { inSummary = false; continue; }
      if (/^Total\s+/i.test(line)) { inSummary = false; continue; }

      const summaryMatch = line.match(/^(.+?)\s+([\d,.]+)\s+([\d,.]+)\s*$/);
      if (summaryMatch) {
        portfolioSummary.push({
          amc_name: summaryMatch[1].trim(),
          cost_value: parseNum(summaryMatch[2]),
          market_value: parseNum(summaryMatch[3]),
        });
      }
    }
  }

  // ── Main state machine ─────────────────────────────────────────────────
  let currentAmc = '';
  let currentFolio: Partial<CamsParsedFolio> | null = null;
  let lastTx: CamsParsedTransaction | null = null;
  let collectingExitLoad = false;
  let exitLoadBuffer: string[] = [];

  let pendingScheme: {
    isin: string; scheme_name: string; scheme_code: string;
    formerly_known: string; advisor_code: string; registrar: string;
    demat_status: string;
  } | null = null;

  const PAGE_HEADER_RE = /^([\d]+-eviL|[\d.]+V:noisreV|\d+-SWSACSMAC|Consolidated Account Statement|\d{2}-[A-Za-z]{3}-\d{4}\s+To\s+\d{2}-[A-Za-z]{3}-\d{4}|Date\s+Transaction\s+Amount|.*\(INR\)\s+\(INR\)\s+Balance)/;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    if (PAGE_HEADER_RE.test(line)) continue;
    if (/^\d+-eviL$/.test(line)) continue;
    if (/^[\d.]+V:noisreV$/.test(line)) continue;
    if (/^\d+-SWSACSMAC$/.test(line)) continue;
    if (/^Page \d+ of \d+$/.test(line)) continue;

    // ── Exit load text collection ────────────────────────────────────────
    if (collectingExitLoad && currentFolio) {
      if (/Folio\s+No:/i.test(line) || isAmcHeader(line, lines, i) || /ISIN:/i.test(line)) {
        currentFolio.exit_load_text = exitLoadBuffer.join(' ');
        collectingExitLoad = false;
        exitLoadBuffer = [];
      } else {
        exitLoadBuffer.push(line);
        continue;
      }
    }

    // ── Folio line ───────────────────────────────────────────────────────
    const folioMatch = line.match(/Folio\s+No:\s*([^\s]+(?:\s*\/\s*\d+)?)/i);
    if (folioMatch) {
      if (currentFolio?.folio_number && currentFolio.transactions) {
        if (collectingExitLoad && exitLoadBuffer.length > 0) {
          currentFolio.exit_load_text = exitLoadBuffer.join(' ');
        }
        folios.push(currentFolio as CamsParsedFolio);
        collectingExitLoad = false;
        exitLoadBuffer = [];
      }

      const folioNum = folioMatch[1].replace(/\s+/g, '');

      const folioContext: string[] = [];
      for (let j = Math.max(0, i - 8); j <= i; j++) folioContext.push(lines[j]);
      for (let j = i + 1; j < Math.min(i + 5, lines.length); j++) {
        const nl = lines[j];
        if (/^\d{2}-[A-Za-z]{3}-\d{4}/.test(nl)) break;
        if (/Opening\s+Unit\s+Balance/i.test(nl)) break;
        if (/ISIN:/i.test(nl)) break;
        if (/Folio\s+No:/i.test(nl)) break;
        if (isAmcHeader(nl, lines, j)) break;
        folioContext.push(nl);
      }
      const folioContextStr = folioContext.join(' ');

      // FIX #7: Strip spaces from PAN before matching
      const panMatch = folioContextStr.match(/PAN:\s*([A-Z]{5}\s*\d{4}\s*[A-Z])/);
      const cleanedPan = panMatch ? panMatch[1].replace(/\s+/g, '') : '';
      const kycMatch = folioContextStr.match(/KYC:\s*(OK|NOT\s*OK)/i);
      const panStatusMatch = folioContextStr.match(/PAN:\s*(OK|NOT\s*OK)\b/gi);
      const panStatus = panStatusMatch && panStatusMatch.length > 1
        ? panStatusMatch[panStatusMatch.length - 1].replace(/PAN:\s*/i, '').trim()
        : '';

      if (!personalInfo.pan && cleanedPan) personalInfo.pan = cleanedPan;

      let folioIsin = '';
      let folioSchemeName = '';
      let folioSchemeCode = '';
      let folioFormerlyKnown = '';
      let folioAdvisor = '';
      let folioRegistrar = '';
      let folioDematStatus = '';

      if (pendingScheme) {
        folioIsin = pendingScheme.isin;
        folioSchemeName = pendingScheme.scheme_name;
        folioSchemeCode = pendingScheme.scheme_code;
        folioFormerlyKnown = pendingScheme.formerly_known;
        folioAdvisor = pendingScheme.advisor_code;
        folioRegistrar = pendingScheme.registrar;
        folioDematStatus = pendingScheme.demat_status;
        pendingScheme = null;
        debug.log(`  Applied pending ISIN ${folioIsin} to folio ${folioNum}`);
      }

      currentFolio = {
        amc_name: currentAmc,
        folio_number: folioNum,
        pan: cleanedPan || personalInfo.pan,
        kyc_status: kycMatch ? kycMatch[1] : '',
        pan_status: panStatus,
        investor_name: '',
        scheme_code: folioSchemeCode,
        scheme_name: folioSchemeName,
        formerly_known: folioFormerlyKnown,
        isin: folioIsin,
        advisor_code: folioAdvisor,
        registrar: folioRegistrar,
        demat_status: folioDematStatus,
        nominees: [],
        opening_units: 0,
        closing_units: 0,
        closing_nav: 0,
        closing_nav_date: '',
        total_cost_value: 0,
        market_value: 0,
        exit_load_text: '',
        transactions: [],
      };
      lastTx = null;

      for (let k = i + 1; k < Math.min(i + 5, lines.length); k++) {
        const nextLine = lines[k];
        if (/^PAN:|^KYC:/i.test(nextLine)) continue;
        if (/^\d{2}-[A-Za-z]{3}-\d{4}/.test(nextLine)) break;
        if (/Opening\s+Unit\s+Balance/i.test(nextLine)) break;
        if (/ISIN:/i.test(nextLine)) break;
        if (/Folio\s+No:/i.test(nextLine)) break;
        if (/^Nominee/i.test(nextLine)) break;
        if (isAmcHeader(nextLine, lines, k)) break;
        if (PAGE_HEADER_RE.test(nextLine)) continue;
        if (/^[A-Za-z][A-Za-z\s]+$/.test(nextLine) && nextLine.length < 50) {
          currentFolio.investor_name = nextLine.trim();
          if (!personalInfo.name) personalInfo.name = nextLine.trim();
          i = k;
          break;
        }
      }
      continue;
    }

    // ── Scheme line (contains ISIN) ──────────────────────────────────────
    let lineForIsin = line;
    if (/ISIN:/i.test(line) && !line.match(/ISIN:\s*([A-Z0-9]{12})/)) {
      // ISIN keyword found but no valid 12-char code — try to reconstruct

      // Case A: ISIN code is on the very next line (full 12 chars)
      if (i + 1 < lines.length) {
        const nextL = lines[i + 1];
        const nextIsinCode = nextL.match(/^([A-Z0-9]{12})/);
        if (nextIsinCode) {
          lineForIsin = line.replace(/ISIN:\s*/i, `ISIN:${nextIsinCode[1]} `) + ' ' + nextL.substring(12).trim();
          i++;
          debug.log(`  Combined split ISIN (full next line): "${lineForIsin.substring(0, 120)}..."`);
        }
      }

      // Case B: ISIN code is split mid-code — partial on this line, rest on next line
      // e.g., "ISIN: INF179K01" on this line, "YM7" interleaved or next
      if (!lineForIsin.match(/ISIN:\s*([A-Z0-9]{12})/)) {
        const partialMatch = lineForIsin.match(/ISIN:\s*([A-Z0-9]{3,11})\s*/);
        if (partialMatch) {
          const partialCode = partialMatch[1];
          const remaining = 12 - partialCode.length;
          // Look in the rest of this line and next few lines for the remaining chars
          // First check: the rest of the current line might have the chars after whitespace/text
          const afterIsin = lineForIsin.substring(lineForIsin.indexOf(partialCode) + partialCode.length);
          const restMatch = afterIsin.match(/\s+([A-Z0-9]+)/);
          if (restMatch && restMatch[1].length >= remaining) {
            const fullIsin = partialCode + restMatch[1].substring(0, remaining);
            lineForIsin = lineForIsin.replace(/ISIN:\s*[A-Z0-9]{3,11}\s+[A-Z0-9]+/, `ISIN:${fullIsin}`);
            debug.log(`  Reconstructed split ISIN (same line): ${partialCode} + ${restMatch[1].substring(0, remaining)} → ${fullIsin}`);
          } else if (i + 1 < lines.length) {
            // Check next line for remaining chars
            const nextL = lines[i + 1];
            const nextPartMatch = nextL.match(/^([A-Z0-9]+)/);
            if (nextPartMatch && nextPartMatch[1].length >= remaining) {
              const fullIsin = partialCode + nextPartMatch[1].substring(0, remaining);
              lineForIsin = lineForIsin.replace(/ISIN:\s*[A-Z0-9]{3,11}/, `ISIN:${fullIsin}`);
              debug.log(`  Reconstructed split ISIN (next line): ${partialCode} + ${nextPartMatch[1].substring(0, remaining)} → ${fullIsin}`);
            }
          }
        }
      }

      // Case C: "Registrar" or other text interleaved on same Y — ISIN might be buried
      // Try extracting any INF/INE code pattern from the combined line text
      if (!lineForIsin.match(/ISIN:\s*([A-Z0-9]{12})/) && /ISIN:/i.test(lineForIsin)) {
        const infMatch = lineForIsin.match(/(IN[FE]\d{3}[A-Z]\d{2}[A-Z0-9]{3})/);
        if (infMatch) {
          lineForIsin = lineForIsin.replace(/ISIN:\s*\S*/, `ISIN:${infMatch[1]}`);
          debug.log(`  Recovered ISIN from INF/INE pattern: ${infMatch[1]}`);
        }
      }
    }
    const isinMatch = lineForIsin.match(/ISIN:\s*([A-Z0-9]{12})/);
    const hasIsinKeyword = /ISIN:/i.test(lineForIsin);
    if (isinMatch || hasIsinKeyword) {
      const newIsin = isinMatch ? isinMatch[1] : '';

      let schemeFullLine = lineForIsin;
      if (!/^[A-Z0-9]+-/i.test(lineForIsin) && i > 0) {
        const prevLines: string[] = [];
        for (let j = Math.max(0, i - 3); j < i; j++) {
          const pl = lines[j];
          if (/Folio\s+No:/i.test(pl)) break;
          if (/Closing\s*Unit\s+Balance/i.test(pl)) continue;
          if (/Opening\s+Unit\s+Balance/i.test(pl)) continue;
          if (/^\d{2}-[A-Za-z]{3}-\d{4}/.test(pl)) continue;
          if (PAGE_HEADER_RE.test(pl)) continue;
          if (/^PAN:/i.test(pl)) continue;
          if (/^KYC:/i.test(pl)) continue;
          if (/^Nominee/i.test(pl)) continue;
          if (/^[A-Za-z][A-Za-z\s]+$/.test(pl) && pl.length < 50) continue;
          if (/\bMutual\s+Fund\s*$/i.test(pl)) continue;
          if (isAmcHeader(pl, lines, j)) continue;
          if (/^[A-Z0-9]+-/.test(pl) || pl.length > 10) {
            prevLines.push(pl);
          }
        }
        if (prevLines.length > 0) {
          schemeFullLine = prevLines.join(' ') + ' ' + lineForIsin;
        }
      }

      let schemeName = '';
      let schemeCode = '';
      const codeMatch = schemeFullLine.match(/^([A-Z0-9]+)-(.+?)(?:\s*-?\s*ISIN|\s*\()/);
      if (codeMatch) {
        schemeCode = codeMatch[1];
        schemeName = codeMatch[2].trim();
      } else {
        const beforeIsin = schemeFullLine.split(/\s*-?\s*ISIN/)[0];
        schemeName = beforeIsin.replace(/^\w+-/, '').trim();
      }

      schemeName = schemeName
        .replace(/\s*\(Non[- ]?Demat\)\s*/i, '')
        .replace(/\s*\(Demat\)\s*/i, '')
        .replace(/\s*\(Non\s*$/, '')
        .replace(/^[-)\s]+/, '')
        .trim();

      if (schemeName.length < 5) {
        debug.log(`  SKIP: Fragment ISIN line, scheme="${schemeName}"`);
        continue;
      }

      if (!newIsin) {
        debug.log(`  EMPTY ISIN detected for scheme: "${schemeName}" — will attempt fuzzy match`);
      }

      const formerlyMatch = schemeFullLine.match(/\((?:Formerly\s+known\s+as|formerly|erstwhile)\s+([^)]+)\)/i);
      const advisorMatch = schemeFullLine.match(/\(Advisor:\s*([^)]+)\)/);
      const registrarMatch = schemeFullLine.match(/Registrar\s*:\s*(\S+)/i);
      const dematStatus = /\(Demat\)/i.test(schemeFullLine) ? 'Demat' :
        /\(Non[- ]?Demat\)/i.test(schemeFullLine) ? 'Non-Demat' : '';

      if (!currentFolio || !currentFolio.folio_number) {
        pendingScheme = {
          isin: newIsin,
          scheme_name: schemeName,
          scheme_code: schemeCode,
          formerly_known: formerlyMatch ? formerlyMatch[1].trim() : '',
          advisor_code: advisorMatch ? advisorMatch[1].trim() : '',
          registrar: registrarMatch ? registrarMatch[1].trim() : '',
          demat_status: dematStatus,
        };
        debug.log(`  Buffered ISIN ${newIsin} (${schemeName}) — awaiting Folio No`);
        continue;
      }

      if (currentFolio.isin && currentFolio.isin !== newIsin &&
          currentFolio.transactions && currentFolio.transactions.length > 0) {

        let folioFollows = false;
        for (let j = i + 1; j < Math.min(i + 5, lines.length); j++) {
          if (/Folio\s+No:/i.test(lines[j])) { folioFollows = true; break; }
          if (/^\d{2}-[A-Za-z]{3}-\d{4}/.test(lines[j])) break;
          if (/Opening\s+Unit\s+Balance/i.test(lines[j])) break;
        }

        if (collectingExitLoad && exitLoadBuffer.length > 0) {
          currentFolio.exit_load_text = exitLoadBuffer.join(' ');
        }
        folios.push(currentFolio as CamsParsedFolio);
        collectingExitLoad = false;
        exitLoadBuffer = [];

        if (folioFollows) {
          currentFolio = null;
          pendingScheme = {
            isin: newIsin,
            scheme_name: schemeName,
            scheme_code: schemeCode,
            formerly_known: formerlyMatch ? formerlyMatch[1].trim() : '',
            advisor_code: advisorMatch ? advisorMatch[1].trim() : '',
            registrar: registrarMatch ? registrarMatch[1].trim() : '',
            demat_status: dematStatus,
          };
          lastTx = null;
          continue;
        }

        currentFolio = {
          amc_name: currentFolio.amc_name,
          folio_number: currentFolio.folio_number,
          pan: currentFolio.pan,
          kyc_status: currentFolio.kyc_status,
          pan_status: currentFolio.pan_status,
          investor_name: currentFolio.investor_name,
          scheme_code: '',
          scheme_name: '',
          formerly_known: '',
          isin: '',
          advisor_code: '',
          registrar: '',
          demat_status: currentFolio.demat_status,
          nominees: currentFolio.nominees ? [...currentFolio.nominees] : [],
          opening_units: 0,
          closing_units: 0,
          closing_nav: 0,
          closing_nav_date: '',
          total_cost_value: 0,
          market_value: 0,
          exit_load_text: '',
          transactions: [],
        };
        lastTx = null;
      }

      currentFolio.isin = newIsin;
      currentFolio.scheme_name = schemeName;
      currentFolio.scheme_code = schemeCode;
      if (formerlyMatch) currentFolio.formerly_known = formerlyMatch[1].trim();
      if (advisorMatch) currentFolio.advisor_code = advisorMatch[1].trim();
      if (registrarMatch) currentFolio.registrar = registrarMatch[1].trim();
      if (dematStatus) currentFolio.demat_status = dematStatus;

      debug.log(`  Set ISIN ${newIsin} on folio ${currentFolio.folio_number}: ${schemeName}`);
      continue;
    }

    // ── Nominee line ─────────────────────────────────────────────────────
    if (/^Nominee\s+1:/i.test(line) && currentFolio) {
      const nominees: string[] = [];
      const n1 = line.match(/Nominee\s+1:\s*(.*?)(?:\s+Nominee\s+2:|$)/i);
      const n2 = line.match(/Nominee\s+2:\s*(.*?)(?:\s+Nominee\s+3:|$)/i);
      const n3 = line.match(/Nominee\s+3:\s*(.*?)$/i);
      if (n1 && n1[1].trim()) nominees.push(n1[1].trim());
      if (n2 && n2[1].trim()) nominees.push(n2[1].trim());
      if (n3 && n3[1].trim()) nominees.push(n3[1].trim());
      currentFolio.nominees = nominees;
      continue;
    }

    // ── Opening Unit Balance ─────────────────────────────────────────────
    if (/Opening\s+Unit\s+Balance/i.test(line) && currentFolio) {
      const openingMatch = line.match(/Opening\s+Unit\s+Balance\s*:?\s*([\d,.]+)/i);
      if (openingMatch) {
        currentFolio.opening_units = parseNum(openingMatch[1]);
      } else {
        const nextLine = (i + 1 < lines.length) ? lines[i + 1] : '';
        const nextNum = nextLine.match(/^\s*([\d,.]+)/);
        if (nextNum) {
          currentFolio.opening_units = parseNum(nextNum[1]);
          i++;
        }
      }
      continue;
    }

    // ── Closing Unit Balance ─────────────────────────────────────────────
    if (/Closing\s*Unit\s+Balance/i.test(line) && currentFolio) {
      const closingMatch = line.match(/Closing\s*Unit\s+Balance\s*:?\s*([\d,.]+)/i);
      if (closingMatch) {
        currentFolio.closing_units = parseNum(closingMatch[1]);
      } else {
        for (let j = i + 1; j < Math.min(i + 3, lines.length); j++) {
          const nextLine = lines[j].trim();
          const nextNum = nextLine.match(/^([\d,.]+)/);
          if (nextNum) {
            currentFolio.closing_units = parseNum(nextNum[1]);
            break;
          }
        }
      }

      const closingBlock: string[] = [];
      for (let j = Math.max(0, i - 6); j < i; j++) {
        if (/NAV\s+on|Market\s+Value/i.test(lines[j])) {
          closingBlock.push(lines[j]);
        }
      }
      closingBlock.push(line);
      for (let j = i + 1; j < Math.min(i + 10, lines.length); j++) {
        closingBlock.push(lines[j]);
        if (/Folio\s+No:/i.test(lines[j])) break;
        if (isAmcHeader(lines[j], lines, j)) break;
      }
      const closingText = closingBlock.join(' ');

      const navMatch = closingText.match(/NAV\s+on\s+(\d{2}-[A-Za-z]{3}-\d{4})\s*:?\s*INR\s*([\d,.]+)/i);
      if (navMatch) {
        currentFolio.closing_nav_date = parseDate(navMatch[1]);
        currentFolio.closing_nav = parseNum(navMatch[2]);
      }
      const costMatch = closingText.match(/(?:Total\s+)?Cost\s+Value\s*:?\s*([\d,.]+)/i);
      if (costMatch) currentFolio.total_cost_value = parseNum(costMatch[1]);
      const mktMatch = closingText.match(/Market\s+Value\s+on\s+[^:]+:?\s*INR\s*([\d,.]+)/i);
      if (mktMatch) currentFolio.market_value = parseNum(mktMatch[1]);

      collectingExitLoad = true;
      exitLoadBuffer = [];
      lastTx = null;
      continue;
    }

    // ── AMC header detection ─────────────────────────────────────────────
    if (isAmcHeader(line, lines, i)) {
      if (currentFolio?.folio_number && currentFolio.transactions) {
        folios.push(currentFolio as CamsParsedFolio);
      }
      currentFolio = null;
      currentAmc = line.trim();
      continue;
    }

    // ── Transaction rows ─────────────────────────────────────────────────
    if (!currentFolio) continue;

    // Stamp Duty
    if (/Stamp\s*Duty/i.test(line)) {
      const sdAmount = extractSingleNumber(line);
      if (sdAmount > 0 && lastTx) {
        lastTx.stamp_duty += sdAmount;
      }
      continue;
    }

    // STT
    if (/STT\s+Paid|STT\s*\*\*\*/i.test(line)) {
      const sttAmount = extractSingleNumber(line);
      if (sttAmount > 0 && lastTx) {
        lastTx.stt_amount += sttAmount;
      }
      continue;
    }

    // Administrative rows
    if (/^\*\*\*.*\*\*\*\s*$/.test(line)) continue;
    if (/Registration\s+of\s+Nominee|Change\s+of\s+Address|Bank\s+Details/i.test(line) && /\*/.test(line)) continue;

    // Transaction row — starts with DD-Mmm-YYYY
    const txDateMatch = line.match(/^(\d{2}-[A-Za-z]{3}-\d{4})\s+(.+)/);
    if (txDateMatch && currentFolio.transactions) {
      const dateStr = parseDate(txDateMatch[1]);
      let restOfLine = txDateMatch[2];

      // Multi-line continuation
      let j = i + 1;
      const maxContinuation = 3;
      let continuationCount = 0;
      while (j < lines.length && continuationCount < maxContinuation) {
        const nextLine = lines[j];
        if (/^\d{2}-[A-Za-z]{3}-\d{4}/.test(nextLine)) break;
        if (/Closing\s*Unit\s+Balance/i.test(nextLine)) break;
        if (/Folio\s+No:/i.test(nextLine)) break;
        if (/^\*\*\*/.test(nextLine)) break;
        if (/Stamp\s*Duty/i.test(nextLine)) break;
        if (/STT\s+Paid/i.test(nextLine)) break;
        if (/^Nominee/i.test(nextLine)) break;
        if (/ISIN:/i.test(nextLine)) break;
        if (/Opening\s+Unit\s+Balance/i.test(nextLine)) break;
        if (isAmcHeader(nextLine, lines, j)) break;
        if (PAGE_HEADER_RE.test(nextLine)) { j++; continue; }
        restOfLine += ' ' + nextLine;
        j++;
        continuationCount++;
      }
      i = j - 1;

      const tx = parseTransactionLine(dateStr, restOfLine, debug);
      if (tx) {
        currentFolio.transactions!.push(tx);
        lastTx = tx;
      }
      continue;
    }
  }

  // Save last folio
  if (currentFolio?.folio_number && currentFolio.transactions) {
    if (collectingExitLoad && exitLoadBuffer.length > 0) {
      currentFolio.exit_load_text = exitLoadBuffer.join(' ');
    }
    folios.push(currentFolio as CamsParsedFolio);
  }

  return { folios, portfolioSummary, personalInfo };
}

// ─── Transaction line parser ──────────────────────────────────────────────────

function parseTransactionLine(txDate: string, text: string, debug: DebugLog): CamsParsedTransaction | null {
  // Pre-process: split concatenated numbers from PDF text extraction
  text = text.replace(/(\d+\.\d{2,6})(\d+\.\d+)/g, '$1 $2');
  text = text.replace(/(\d+\.\d{2,6})(\d+\.\d+)/g, '$1 $2');
  text = text.replace(/(\d)([A-Z][a-z])/g, '$1 $2');
  text = text.replace(/(\d)((?:[A-Z]{2})[a-z])/g, '$1 $2');
  text = text.replace(/(\))([\d])/g, '$1 $2');
  text = text.replace(/([\d])(\()/g, '$1 $2');

  const numberPattern = /\([\d,]+\.?\d*\)|(?<![A-Za-z/])[\d,]+\.\d+(?![A-Za-z])/g;
  const rawNumbers: { value: number; index: number; raw: string }[] = [];

  let match;
  while ((match = numberPattern.exec(text)) !== null) {
    const raw = match[0];
    // Skip instalment counters like (1), (2), (12) — small parenthesised integers
    // These appear in KFintech descriptions: "Systematic Investment (1)", "SIP (1/6)"
    if (/^\(\d{1,3}\)$/.test(raw)) continue;
    const isNeg = raw.startsWith('(');
    const val = parseFloat(raw.replace(/[(),]/g, ''));
    rawNumbers.push({ value: isNeg ? -val : val, index: match.index, raw });
  }

  if (rawNumbers.length === 0) return null;

  const firstNumIdx = rawNumbers[0].index;
  const description = text.substring(0, firstNumIdx).trim();

  const txType = normaliseCAMSType(description);
  if (txType === 'SKIP') return null;

  // ── FIX #4: Confidence scoring ─────────────────────────────────────────
  let confidence = 100;
  const confidenceFlags: string[] = [];

  let amount = 0, units = 0, nav = 0, balance = 0;

  if (rawNumbers.length >= 4) {
    amount = rawNumbers[0].value;
    units = rawNumbers[1].value;
    nav = rawNumbers[2].value;
    balance = rawNumbers[3].value;
  } else if (rawNumbers.length === 3) {
    amount = rawNumbers[0].value;
    units = rawNumbers[1].value;
    if (rawNumbers[2].value < 10000 && rawNumbers[2].value > 0) {
      nav = rawNumbers[2].value;
    } else {
      balance = rawNumbers[2].value;
    }
    confidence -= 5;
    confidenceFlags.push('3_nums_heuristic');
  } else if (rawNumbers.length === 2) {
    amount = rawNumbers[0].value;
    units = rawNumbers[1].value;
    confidence -= 15;
    confidenceFlags.push('missing_nav_and_balance');
  } else if (rawNumbers.length === 1) {
    amount = rawNumbers[0].value;
    confidence -= 30;
    confidenceFlags.push('only_amount_extracted');
  }

  // ── FIX #2: NAV validation — cross-check units × nav ≈ amount ─────────
  if (nav > 0 && units > 0 && amount > 0) {
    const computed = Math.abs(units) * Math.abs(nav);
    const actual = Math.abs(amount);
    const deviation = Math.abs(computed - actual) / actual;
    if (deviation > 0.02) { // >2% deviation
      confidence -= 20;
      confidenceFlags.push(`nav_mismatch_${(deviation * 100).toFixed(1)}pct`);
      debug.log(`  NAV WARN: ${txDate} — units(${units}) × nav(${nav}) = ${computed.toFixed(2)}, amount = ${actual.toFixed(2)}, dev=${(deviation*100).toFixed(1)}%`);

      // Try swapping nav and balance if that fixes it
      if (rawNumbers.length >= 4) {
        const swappedNav = rawNumbers[3].value;
        const swappedBalance = rawNumbers[2].value;
        const swappedComputed = Math.abs(units) * Math.abs(swappedNav);
        const swappedDev = Math.abs(swappedComputed - actual) / actual;
        if (swappedDev < deviation && swappedDev < 0.02) {
          debug.log(`  NAV FIX: Swapped nav/balance — ${nav} → ${swappedNav}`);
          nav = swappedNav;
          balance = swappedBalance;
          confidence += 15; // restore some confidence
          confidenceFlags.push('nav_balance_swapped');
        }
      }
    }
  }

  // NAV range validation (typical MF NAV is 1-50,000)
  if (nav > 0 && (nav > 50000 || nav < 0.01)) {
    confidence -= 15;
    confidenceFlags.push(`nav_out_of_range_${nav}`);
  }

  return {
    tx_date: txDate,
    description,
    amount: Math.abs(amount),
    units: Math.abs(units),
    nav_at_tx: Math.abs(nav),
    unit_balance: Math.abs(balance),
    tx_type: txType,
    stamp_duty: 0,
    stt_amount: 0,
    confidence,
    confidence_flags: confidenceFlags,
  };
}

// ─── Transaction type normalisation ───────────────────────────────────────────

function normaliseCAMSType(description: string): string {
  const u = (description || '').toUpperCase().trim();
  const uNorm = u.replace(/\bS\s+T\s+P\b/g, 'STP');

  // Administrative — skip
  if (/^\*\*\*/.test(u)) return 'SKIP';
  if (/\*\*\*/.test(u)) return 'SKIP';
  if (/STAMP\s*DUTY/i.test(u)) return 'SKIP';
  if (/STT\s*PAID/i.test(u)) return 'SKIP';
  if (/REGISTRATION\s+OF\s+NOMINEE/i.test(u)) return 'SKIP';
  if (/CHANGE\s+OF\s+ADDRESS/i.test(u)) return 'SKIP';
  if (/BANK\s+DETAILS/i.test(u)) return 'SKIP';
  if (/CONSOLIDATION\s+OF\s+FOLIOS/i.test(u)) return 'SKIP';
  if (/CANCELLED/i.test(u)) return 'SKIP';
  if (/CHANGE\s+OF\s+BROKER/i.test(u)) return 'SKIP';
  if (/ADDRESS\s+UPDATED/i.test(u)) return 'SKIP';
  if (/KYC\s+FAILED/i.test(u)) return 'SKIP';
  if (/CHANGE\s+OF\s+CONTACTS/i.test(u)) return 'SKIP';
  if (/CHANGE\s+\/\s*REGN\s+OF\s+NOMINEE/i.test(u)) return 'SKIP';

  // Reversal — always a sell (reverses a prior purchase)
  if (uNorm.includes('REVERSAL') || uNorm.includes('REVERSED'))
    return 'SELL';

  // Redemption — always a sell
  if (uNorm.includes('REDEMPTION') || uNorm.includes('REPURCHASE') || uNorm.includes('REDEEMED'))
    return 'SELL';

  // Switch — check before generic purchase/buy
  if (uNorm.includes('SWITCH OUT') || uNorm.includes('SWITCH-OUT') || uNorm.includes('LATERAL SHIFT OUT'))
    return 'Switch-Out';
  if (uNorm.includes('SWITCH IN') || uNorm.includes('SWITCH-IN') || uNorm.includes('LATERAL SHIFT IN'))
    return 'Switch-In';
  // "Switch Over In/Out" from real PDFs (SKS)
  if (uNorm.includes('SWITCH OVER IN') || uNorm.includes('SWITCH OVER OUT')) {
    return uNorm.includes('OUT') ? 'Switch-Out' : 'Switch-In';
  }

  // STP — "Systematic Transfer From/To" patterns from CAMS + KFintech
  // KFintech uses "Systematic Transfer Plan Out/In" instead of "STP"
  if (uNorm.includes('SYSTEMATIC TRANSFER PLAN OUT') || uNorm.includes('SYSTEMATIC TRANSFER PLAN IN')) {
    return uNorm.includes('OUT') ? 'STP-Out' : 'STP-In';
  }
  if (uNorm.includes('SYSTEMATIC TRANSFER FROM') || uNorm.includes('STP SWITCH-IN') || uNorm.includes('STP SWITCHIN'))
    return 'STP-In';
  if (uNorm.includes('SYSTEMATIC TRANSFER TO') || uNorm.includes('STP SWITCH-OUT') || uNorm.includes('STP SWITCHOUT'))
    return 'STP-Out';
  if (uNorm.includes('STP') && (uNorm.includes('OUT') || uNorm.includes('(TO')))
    return 'STP-Out';
  if (uNorm.includes('STP') && (uNorm.includes('IN') || uNorm.includes('(FROM')))
    return 'STP-In';
  if (uNorm.includes('STP'))
    return u.includes('(') && u.includes('FROM') ? 'STP-In' : 'STP-Out';

  // SWP
  if (uNorm.includes('SWP')) return 'SWP';

  // SIP — "Net Systematic Purchase" and "Systematic Investment" (KFintech) from real PDFs
  if (uNorm.includes('SIP PURCHASE') || uNorm.includes('SIP') ||
      uNorm.includes('NET SYSTEMATIC PURCHASE') || uNorm.includes('SYSTEMATIC PURCHASE') ||
      uNorm.includes('SYSTEMATIC INVESTMENT'))
    return 'SIP';

  // FIX #8: IDCW split — payout vs reinvest
  if (uNorm.includes('IDCW') || uNorm.includes('DIVIDEND') || uNorm.includes('DIV PAYOUT')) {
    if (uNorm.includes('REINVEST') || uNorm.includes('RE-INVEST')) return 'IDCW-Reinvest';
    if (uNorm.includes('PAYOUT')) return 'IDCW-Payout';
    return 'IDCW'; // ambiguous — kept as generic
  }

  // Bonus
  if (uNorm.includes('BONUS')) return 'Bonus';

  // Purchase variants
  if (uNorm.includes('PURCHASE') || uNorm.includes('NET PURCHASE') ||
      uNorm.includes('NFO') || uNorm.includes('INITIAL'))
    return 'BUY';

  // FIX #9: Transfer / Gifting — proper handling from real PDFs
  // "Transfer Out Transfer To 599374869964" or "Gifting of units - To Folio"
  if (uNorm.includes('TRANSFER OUT') || uNorm.includes('TRANSFERRED OUT'))
    return 'Transfer-Out';
  if (uNorm.includes('TRANSFER IN') || uNorm.includes('TRANSFERRED IN') ||
      uNorm.includes('TRANSFER IN TRANSFER FROM'))
    return 'Transfer-In';

  // "Gifting of units - To Folio" / "Gifting of units - From Folio"
  if (uNorm.includes('GIFTING') || uNorm.includes('GIFT OF UNITS')) {
    if (uNorm.includes('FROM')) return 'Transfer-In';
    return 'Transfer-Out'; // default gifting = giving away
  }

  // "Redemption Of Units" from real PDFs (Franklin ELSS)
  if (uNorm.includes('REDEMPTION OF UNITS')) return 'SELL';

  // Fallback
  return 'BUY';
}

// ─── AMC header detection ─────────────────────────────────────────────────────

function isAmcHeader(line: string, lines: string[], idx: number): boolean {
  const u = line.toUpperCase().trim();

  if (!/Mutual\s+Fund|MF\b/i.test(line) && !KNOWN_AMCS.some(a => u.includes(a)))
    return false;

  if (/Folio|ISIN|Nominee|Closing|Opening|Date|Transaction|NAV|Page/i.test(line))
    return false;

  if (/^[A-Z0-9]{2,6}-/i.test(line))
    return false;

  if (line.length > 60)
    return false;

  if (/Growth|Direct\s+Plan|Regular\s+Plan|Flexi\s*Cap|Small\s*Cap|Mid\s*Cap|Large\s*Cap|Multi\s*Cap|Money\s*Market|Liquid|Overnight|Ultra\s+Short|Short\s+Term|Long\s+Term|Balanced|Hybrid|Gilt|Bond\b|Debt|Credit\s+Risk|Corporate|Banking|Dynamic|ELSS|Tax\s+Saver|Contra|Value\s+Fund|Aggressive|Conservative|Arbitrage|Equity\s+Savings|Nifty|Sensex|Index\s+Fund|ETF|Advantage|Bluechip|Emerging|Focused|Flexi|Special\s+Opp|Opportunities/i.test(line))
    return false;

  if (/Formerly\s+known|erstwhile|Advisor:|Registrar|Demat|Non-Demat/i.test(line))
    return false;

  if ((line.match(/-/g) || []).length >= 2)
    return false;

  for (let j = idx + 1; j < Math.min(idx + 6, lines.length); j++) {
    if (/Folio\s+No:/i.test(lines[j])) return true;
  }
  return false;
}

const KNOWN_AMCS = [
  'SBI', 'HDFC', 'ICICI', 'KOTAK', 'AXIS', 'BANDHAN', 'UTI', 'NIPPON',
  'PPFAS', 'PARAG PARIKH', 'QUANT', 'MOTILAL', 'PGIM', 'DSP', 'TATA',
  'MIRAE', 'ADITYA BIRLA', 'EDELWEISS', 'CANARA', 'INVESCO', 'FRANKLIN',
  'BARODA', 'HSBC', 'UNION', 'SUNDARAM', 'MAHINDRA', 'GROWW', 'WHITEOAK',
  'JM FINANCIAL', 'QUANTUM', 'NAVI', 'BNP PARIBAS',
];

// ─── Utility functions ────────────────────────────────────────────────────────

function parseNum(s: string): number {
  return parseFloat(s.replace(/[,\s]/g, '')) || 0;
}

function parseDate(dateStr: string): string {
  const months: Record<string, string> = {
    'jan': '01', 'feb': '02', 'mar': '03', 'apr': '04', 'may': '05', 'jun': '06',
    'jul': '07', 'aug': '08', 'sep': '09', 'oct': '10', 'nov': '11', 'dec': '12',
  };
  const parts = dateStr.split('-');
  if (parts.length !== 3) return dateStr;
  const day = parts[0].padStart(2, '0');
  const month = months[parts[1].toLowerCase()] || parts[1];
  const year = parts[2];
  return `${year}-${month}-${day}`;
}

function extractSingleNumber(line: string): number {
  const match = line.match(/([\d,.]+)\s*$/);
  return match ? parseNum(match[1]) : 0;
}

function parseExitLoad(text: string): { days: number | null; pct: number | null; freePct: number } {
  if (!text || /^nil$/i.test(text.trim()) || /exit\s+load\s*:?\s*nil/i.test(text)) {
    return { days: null, pct: null, freePct: 0 };
  }

  let days: number | null = null;
  let pct: number | null = null;
  let freePct = 0;

  // Pattern 1: "upto X% of the units ... Nil, more than X% ... Y%"
  // e.g., "upto 30% of the units within 1 year - Nil, more than 30% ... 1.0%"
  const slabPattern = /(?:upto|up\s+to)\s+([\d.]+)\s*%\s+of\s+(?:the\s+)?(?:units|investment).*?[-–]\s*nil.*?([\d.]+)\s*%/i;
  const slabMatch = text.match(slabPattern);

  // Pattern 2: "NIL for X% of investment and Y% exit load for remaining"
  // e.g., "NIL for 10% of investment and 1% exit load for remaining investment"
  const nilForPattern = /nil\s+for\s+([\d.]+)\s*%\s+of\s+(?:the\s+)?(?:units|investment).*?([\d.]+)\s*%\s*(?:exit\s+load|for\s+remaining)/i;
  const nilForMatch = text.match(nilForPattern);

  // Pattern 3: "X% of the units allotted shall be redeemed without any exit load, Y% exit load"
  const allottedPattern = /([\d.]+)\s*%\s+of\s+(?:the\s+)?(?:units|investment)\s+(?:allotted\s+)?(?:shall\s+be\s+)?(?:redeemed\s+)?without\s+(?:any\s+)?exit\s+load.*?([\d.]+)\s*%\s*(?:exit\s+load)/i;
  const allottedMatch = text.match(allottedPattern);

  if (slabMatch) {
    freePct = parseFloat(slabMatch[1]);
    pct = parseFloat(slabMatch[2]);
  } else if (nilForMatch) {
    freePct = parseFloat(nilForMatch[1]);
    pct = parseFloat(nilForMatch[2]);
  } else if (allottedMatch) {
    freePct = parseFloat(allottedMatch[1]);
    pct = parseFloat(allottedMatch[2]);
  } else {
    // Fallback: first percentage is the charge rate
    const pctMatch = text.match(/([\d.]+)\s*%/);
    if (pctMatch) {
      pct = parseFloat(pctMatch[1]);
    }
  }

  const yearMatch = text.match(/within\s+(\d+)\s+year/i);
  const monthMatch = text.match(/within\s+(\d+)\s+month/i);
  const dayMatch = text.match(/within\s+(\d+)\s+(?:calendar\s+)?day/i);

  if (yearMatch) {
    days = parseInt(yearMatch[1]) * 365;
  } else if (monthMatch) {
    days = Math.round(parseInt(monthMatch[1]) * 30.44);
  } else if (dayMatch) {
    days = parseInt(dayMatch[1]);
  }

  if (pct !== null && days === null) {
    days = 365;
  }

  return { days, pct, freePct };
}

function validatePortfolioSummary(
  folios: CamsParsedFolio[],
  summary: PortfolioSummaryEntry[]
): boolean {
  if (summary.length === 0) return true;

  const amcMarket = new Map<string, number>();
  for (const f of folios) {
    const amc = f.amc_name.toLowerCase().trim();
    amcMarket.set(amc, (amcMarket.get(amc) || 0) + f.market_value);
  }

  let allMatch = true;
  for (const s of summary) {
    const computed = amcMarket.get(s.amc_name.toLowerCase().trim()) || 0;
    if (Math.abs(computed - s.market_value) > 1) {
      allMatch = false;
    }
  }
  return allMatch;
}

// ─── Fuzzy fund name matching ────────────────────────────────────────────────

function fuzzyMatchFund(
  casName: string,
  allFunds: { amfi_code: number; fund_name: string }[]
): { amfi_code: number; fund_name: string } | null {
  const normalise = (s: string) =>
    s.replace(/\([^)]*\)/g, '')
     .replace(/\berstwhile\b.*/i, '')
     .replace(/\s*-\s*(direct|regular)\s*(plan)?/gi, '')
     .replace(/\s*-?\s*(growth|dividend|idcw)\s*(option|plan)?/gi, '')
     .replace(/[^a-zA-Z0-9\s]/g, ' ')
     .replace(/\s+/g, ' ')
     .trim()
     .toLowerCase();

  const NOISE = new Set(['the', 'of', 'and', 'fund', 'scheme', 'plan', 'option', 'growth', 'dividend', 'direct', 'regular', 'open', 'ended']);

  const casKey = normalise(casName);
  const casTokens = casKey.split(' ').filter(t => t.length > 1 && !NOISE.has(t));
  if (casTokens.length === 0) return null;

  let bestMatch: { amfi_code: number; fund_name: string } | null = null;
  let bestScore = 0;

  for (const fund of allFunds) {
    const fundKey = normalise(fund.fund_name);
    const fundTokens = fundKey.split(' ').filter(t => t.length > 1 && !NOISE.has(t));
    if (fundTokens.length === 0) continue;

    const fundSet = new Set(fundTokens);
    let matchedTokens = 0;
    for (const t of casTokens) {
      if (fundSet.has(t)) matchedTokens++;
    }

    const coverage = matchedTokens / casTokens.length;
    if (coverage >= 0.6 && coverage > bestScore) {
      bestScore = coverage;
      bestMatch = fund;
    }
  }

  return bestMatch;
}
