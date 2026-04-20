/**
 * eVesh — Supabase Edge Function: parse-ais-pdf
 *
 * Parses the Income Tax Department's Annual Information Statement (AIS) PDF.
 * AIS covers ALL registrars (CAMS, KFintech) and ALL asset types (stocks, MF,
 * dividends, interest, salary) — the gold standard for tax computation.
 *
 * v2 — Robust numeric extraction: instead of fragile column-position mapping,
 * we extract all pure-numeric cells from each data row, sort by x-position,
 * and map to known column order per table type.
 *
 * Request: application/json
 *   - file_base64: base64-encoded PDF bytes
 *   - password:    PAN(lowercase) + DOB(DDMMYYYY) e.g. "adzpn9228p02101975"
 *   - owner_id:    the authenticated user's ID
 *   - member_id:   optional pre-matched member ID
 *   - file_name:   original file name
 *
 * Response: { success, sections_parsed, stock_sales, mf_sales, dividends, ... }
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

// ─── Types ──────────────────────────────────────────────────────────────────

interface TextItem {
  str: string;
  x: number;
  y: number;
  w: number;
  page: number;
}

interface TableRow {
  y: number;
  cells: { x: number; w: number; text: string }[];
  rawText: string;
}

interface SftSaleEntry {
  sr_no: number;
  date: string;
  security_name: string;
  isin: string | null;
  security_class: string;
  debit_type: string;
  credit_type: string;
  asset_type: string;  // "Short term" or "Long term"
  quantity: number;
  sale_price: number;
  sales_consideration: number;
  stt: number;
  cost_of_acquisition: number;
  unit_fmv: number;
  fair_market_value: number;
  indexed_cost: number;
  status: string;
  info_source: string;
}

interface MfPurchaseEntry {
  info_code: string;
  info_source: string;
  amc_name: string;
  client_id: string;
  quarter: string;
  purchase_amount: number;
  sales_value: number;
  holder_flag: string;
  status: string;
}

interface TaxPayment {
  financial_year: string;
  major_head: string;
  minor_head: string;
  tax_a: number;
  surcharge_b: number;
  education_cess_c: number;
  others_d: number;
  total: number;
  bsr_code: string;
  date_of_deposit: string;
  challan_serial: number;
  challan_id: string;
}

interface TdsSourceEntry {
  info_code: string;
  info_source: string;
  total_amount: number;
  count: number;
  tds_deducted: number;
  tds_deposited: number;
  quarters: {
    quarter: string;
    date: string;
    amount_paid: number;
    tds_deducted: number;
    tds_deposited: number;
    status: string;
  }[];
}

// ─── PDF Text Extraction ────────────────────────────────────────────────────

async function extractTextItems(fileBytes: Uint8Array, password?: string): Promise<TextItem[]> {
  const { getDocumentProxy } = await import('https://esm.sh/unpdf@0.12.1');
  const pdfProxy = await getDocumentProxy(fileBytes, password ? { password } : {});
  const numPages = pdfProxy.numPages;
  const items: TextItem[] = [];

  for (let p = 1; p <= numPages; p++) {
    const page = await pdfProxy.getPage(p);
    const content = await page.getTextContent();

    for (const item of content.items as any[]) {
      if (!('str' in item) || !(item.str as string)) continue;
      items.push({
        str: item.str as string,
        x: (item.transform?.[4] as number) || 0,
        y: (item.transform?.[5] as number) || 0,
        w: (item.width as number) || 0,
        page: p,
      });
    }
  }

  return items;
}

// ─── Group text items into rows ─────────────────────────────────────────────

function groupIntoRows(items: TextItem[]): TableRow[] {
  // Sort by page, then y descending (top to bottom), then x ascending
  items.sort((a, b) => {
    if (a.page !== b.page) return a.page - b.page;
    const yDiff = b.y - a.y;
    if (Math.abs(yDiff) > 2) return yDiff > 0 ? 1 : -1;
    return a.x - b.x;
  });

  const rows: TableRow[] = [];
  let currentRow: TextItem[] = [];
  let currentY: number | null = null;

  for (const item of items) {
    if (!item.str.trim()) continue;

    if (currentY !== null && Math.abs(item.y - currentY) > 2) {
      if (currentRow.length > 0) {
        const cells = currentRow.map(i => ({ x: i.x, w: i.w, text: i.str.trim() }));
        rows.push({
          y: currentY,
          cells,
          rawText: cells.map(c => c.text).join(' '),
        });
      }
      currentRow = [];
    }

    currentRow.push(item);
    currentY = item.y;
  }

  if (currentRow.length > 0 && currentY !== null) {
    const cells = currentRow.map(i => ({ x: i.x, w: i.w, text: i.str.trim() }));
    rows.push({
      y: currentY,
      cells,
      rawText: cells.map(c => c.text).join(' '),
    });
  }

  return rows;
}

// ─── Numeric helpers ────────────────────────────────────────────────────────

/** Returns true if text is a pure number (digits, commas, optional decimal) */
function isNumericText(text: string): boolean {
  const t = text.replace(/\s/g, '');
  return /^-?\d[\d,]*\.?\d*$/.test(t) || t === '0';
}

/** Parse Indian-formatted number string → float */
function parseNum(text: string): number {
  return parseFloat(text.replace(/,/g, '').trim()) || 0;
}

/** Extract all pure-number cells from a row, sorted by x-position (L→R) */
function getRowNumbers(row: TableRow): { value: number; x: number }[] {
  const results: { value: number; x: number }[] = [];
  for (const cell of row.cells) {
    const t = cell.text.trim().replace(/\s/g, '');
    if (isNumericText(t)) {
      results.push({ value: parseNum(t), x: cell.x });
    }
  }
  // cells are already x-sorted from groupIntoRows
  return results;
}

// ─── Pattern extraction helpers ─────────────────────────────────────────────

function extractIsin(text: string): string | null {
  const match = text.match(/INF[A-Z0-9]{9}/);
  if (match) return match[0];
  const match2 = text.match(/INE[A-Z0-9]{9}/);
  return match2 ? match2[0] : null;
}

function extractDate(text: string): string {
  const match = text.match(/(\d{2}\/\d{2}\/\d{4})/);
  return match ? match[1] : '';
}

function extractAssetType(text: string): string {
  return text.toLowerCase().includes('short term') ? 'Short term' : 'Long term';
}

function extractStatus(text: string): string {
  return text.includes('Inactive') ? 'Inactive' : 'Active';
}

/** Build a clean security name from row cells, excluding known keywords and numbers */
function buildSecurityName(
  dataRow: TableRow,
  continuationTexts: string[],
): string {
  const excludePatterns = new Set([
    'listed equity share', 'unit of equity oriented mutual fund',
    'other units', 'market', 'off market',
    'amc (redemption)', 'amc (purchase)',
    'short term', 'long term', 'active', 'inactive',
  ]);

  const parts: string[] = [];
  let skipFirst = true; // skip sr_no
  let pastDate = false;

  for (const cell of dataRow.cells) {
    const text = cell.text.trim();
    if (!text) continue;
    if (skipFirst) { skipFirst = false; continue; }

    // Skip date
    if (/^\d{2}\/\d{2}\/\d{4}$/.test(text)) { pastDate = true; continue; }

    // Skip pure numbers
    if (isNumericText(text.replace(/\s/g, ''))) continue;

    // Skip known keywords
    if (excludePatterns.has(text.toLowerCase())) continue;

    // After the date, non-numeric non-keyword text is likely the security name
    if (pastDate) {
      // Don't include AMC-level text that comes before security name in MF tables
      // AMC names are short (e.g., "Quant MF(166)") — include them, they'll be part of the name
      parts.push(text);
    }
  }

  // Add continuation row text
  for (const ct of continuationTexts) {
    if (ct && !ct.startsWith('Page') && !ct.startsWith('Download') &&
        !ct.includes('SR. NO') && !ct.includes('DATE OF SALE') &&
        !ct.includes('SECURITY NAME') && !ct.includes('SALE PRICE') &&
        !ct.includes('INFORMATION') && !ct.includes('Part B') &&
        !ct.includes('SFT-')) {
      parts.push(ct);
    }
  }

  return parts.join(' ').trim();
}

// ─── Main AIS Parser (v2 — numeric extraction) ─────────────────────────────

function parseAIS(rows: TableRow[]) {
  const result = {
    pan: null as string | null,
    name: null as string | null,
    dob: null as string | null,
    email: null as string | null,
    mobile: null as string | null,
    address: null as string | null,
    financialYear: '',
    // Part B1 — TDS Income
    salaryEntries: [] as TdsSourceEntry[],
    dividendEntries: [] as TdsSourceEntry[],
    interestEntries: [] as TdsSourceEntry[],
    totalSalary: 0,
    totalDividends: 0,
    totalInterest: 0,
    totalTds: 0,
    // Part B2 — SFT
    stockSales: [] as SftSaleEntry[],
    equityMfSales: [] as SftSaleEntry[],
    debtMfSales: [] as SftSaleEntry[],
    mfPurchases: [] as MfPurchaseEntry[],
    // Part B3
    taxPayments: [] as TaxPayment[],
    // Debug
    sectionHeaders: [] as string[],
  };

  // ── Extract header info from first ~40 rows ──
  for (let i = 0; i < Math.min(rows.length, 40); i++) {
    const text = rows[i].rawText;

    // Financial year
    const fyMatch = text.match(/(\d{4})-(\d{2})/);
    if (fyMatch && (text.includes('Financial Year') || text.includes('2025-26') || text.includes('2024-25'))) {
      result.financialYear = `FY${fyMatch[1].slice(2)}${fyMatch[2]}`;
    }

    // PAN
    if (!result.pan) {
      const panMatch = text.match(/[A-Z]{5}\d{4}[A-Z]/);
      if (panMatch) result.pan = panMatch[0];
    }

    // Name (row after "Name of Assessee")
    if (text.includes('Name of Assessee') && i + 1 < rows.length) {
      const nextText = rows[i + 1]?.rawText?.trim();
      if (nextText && !nextText.includes('Date of Birth') && nextText.length > 2) {
        result.name = nextText;
      }
    }

    // DOB
    const dobMatch = text.match(/(\d{2}\/\d{2}\/\d{4})/);
    if (dobMatch && text.includes('Date of Birth')) {
      result.dob = dobMatch[1];
    }
  }

  // ── Process rows sequentially ──
  let currentSection = '';
  let currentTdsType = ''; // 'salary' | 'dividend' | 'interest'
  let currentTdsEntry: TdsSourceEntry | null = null;
  let sftTableType = ''; // 'stock_sale' | 'eq_mf_sale' | 'debt_mf_sale' | 'purchase'
  let sftTableTypeAtEntry = ''; // captured at entry start so section changes don't corrupt
  let currentInfoSource = '';
  let pendingEntry: Partial<SftSaleEntry> | null = null;
  let pendingEntryRows: TableRow[] = []; // ALL rows for current entry (data + continuations)
  let lastSrNo = 0; // track sequential sr_no for validation

  function flushPendingEntry() {
    if (!pendingEntry || !pendingEntry.date || pendingEntryRows.length === 0) {
      pendingEntry = null;
      pendingEntryRows = [];
      return;
    }

    // ── Merge ALL numeric cells from all rows of this entry ──
    const allNums: { value: number; x: number }[] = [];
    let isFirstRow = true;
    for (const row of pendingEntryRows) {
      const nums = getRowNumbers(row);
      if (isFirstRow) {
        // Skip sr_no (first number on first row)
        allNums.push(...nums.slice(1));
        isFirstRow = false;
      } else {
        // All numbers from continuation rows are data
        allNums.push(...nums);
      }
    }

    // Sort by x-position → gives correct column order
    allNums.sort((a, b) => a.x - b.x);
    const dataNums = allNums.map(n => n.value);

    // ── Map numerics to fields based on table type ──
    const tableType = sftTableTypeAtEntry || sftTableType;
    if (tableType === 'stock_sale') {
      // SFT-17-LES: 7 numeric fields (no STT)
      const n = dataNums.length >= 7 ? dataNums.slice(-7) : dataNums;
      pendingEntry.quantity = n[0] || 0;
      pendingEntry.sale_price = n[1] || 0;
      pendingEntry.sales_consideration = n[2] || 0;
      pendingEntry.cost_of_acquisition = n[3] || 0;
      pendingEntry.unit_fmv = n[4] || 0;
      pendingEntry.fair_market_value = n[5] || 0;
      pendingEntry.indexed_cost = n[6] || 0;
      pendingEntry.stt = 0;
    } else {
      // SFT-17-EMF, SFT-18-OTU: 8 numeric fields (includes STT)
      const n = dataNums.length >= 8 ? dataNums.slice(-8) : dataNums;
      pendingEntry.quantity = n[0] || 0;
      pendingEntry.sale_price = n[1] || 0;
      pendingEntry.sales_consideration = n[2] || 0;
      pendingEntry.stt = n[3] || 0;
      pendingEntry.cost_of_acquisition = n[4] || 0;
      pendingEntry.unit_fmv = n[5] || 0;
      pendingEntry.fair_market_value = n[6] || 0;
      pendingEntry.indexed_cost = n[7] || 0;
    }

    // ── Merge text from ALL rows for asset_type, status, ISIN, name ──
    const allText = pendingEntryRows.map(r => r.rawText).join(' ');
    pendingEntry.asset_type = extractAssetType(allText);
    pendingEntry.status = extractStatus(allText);
    if (!pendingEntry.isin) {
      pendingEntry.isin = extractIsin(allText);
    }

    // Build security name from all rows
    const contTexts = pendingEntryRows.slice(1)
      .map(r => r.rawText)
      .filter(t =>
        !t.startsWith('Page') && !t.startsWith('Download') &&
        !t.includes('SR. NO') && !t.includes('DATE OF SALE') &&
        !t.includes('SECURITY NAME') && !t.includes('SALE PRICE') &&
        !t.includes('INFORMATION') && !t.includes('Part B') &&
        !t.includes('SFT-') && !t.includes('COST OF') &&
        !t.includes('UNIT FMV') && !t.includes('FAIR MARKET') &&
        !t.includes('INDEXED') && !t.includes('SALES CONSIDERATION') &&
        !t.includes('CREDIT TYPE') && !t.includes('DEBIT TYPE') &&
        !t.includes('ASSET TYPE') && !t.includes('QUANTITY') &&
        !t.includes('AMC NAME') && !t.includes('SECURITY CLASS')
      );
    pendingEntry.security_name = buildSecurityName(pendingEntryRows[0], contTexts);

    // Security class based on table type
    if (!pendingEntry.security_class) {
      pendingEntry.security_class = tableType === 'stock_sale'
        ? 'Listed Equity Share'
        : tableType === 'eq_mf_sale'
          ? 'Unit of Equity Oriented Mutual Fund'
          : 'Other Units';
    }

    console.log(`AIS-PARSE: Entry #${pendingEntry.sr_no} [${tableType}] date=${pendingEntry.date} isin=${pendingEntry.isin} type=${pendingEntry.asset_type} qty=${pendingEntry.quantity} price=${pendingEntry.sale_price} consideration=${pendingEntry.sales_consideration} cost=${pendingEntry.cost_of_acquisition} fmv=${pendingEntry.fair_market_value} [${dataNums.length} nums from ${pendingEntryRows.length} rows]`);

    pushSaleEntry(result, tableType, pendingEntry as SftSaleEntry);
    pendingEntry = null;
    pendingEntryRows = [];
  }

  function flushTdsEntry() {
    if (currentTdsEntry) {
      switch (currentTdsType) {
        case 'salary':
          result.salaryEntries.push(currentTdsEntry);
          break;
        case 'dividend':
          result.dividendEntries.push(currentTdsEntry);
          break;
        case 'interest':
          result.interestEntries.push(currentTdsEntry);
          break;
      }
      currentTdsEntry = null;
    }
  }

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    const text = row.rawText;
    const firstCell = row.cells[0]?.text.trim() || '';

    // ═══════ Section detection ═══════
    if (text.includes('Part B1') || (text.includes('tax deducted') && text.includes('collected at source'))) {
      currentSection = 'B1';
      flushPendingEntry();
      flushTdsEntry();
      result.sectionHeaders.push('Part B1');
      sftTableType = '';
      continue;
    }
    if (text.includes('Part B2') || (text.includes('specified financial transaction') && !text.includes('Part B1'))) {
      currentSection = 'B2';
      flushPendingEntry();
      flushTdsEntry();
      result.sectionHeaders.push('Part B2');
      continue;
    }
    if (text.includes('Part B3') || (text.includes('payment of taxes') && !text.includes('Part B2'))) {
      currentSection = 'B3';
      flushPendingEntry();
      flushTdsEntry();
      result.sectionHeaders.push('Part B3');
      sftTableType = '';
      continue;
    }
    if (text.includes('Part B4') || text.includes('demand and refund')) {
      currentSection = 'B4';
      flushPendingEntry();
      sftTableType = '';
      continue;
    }
    if (text.includes('Part B7') || text.includes('other information')) {
      currentSection = 'B7';
      flushPendingEntry();
      sftTableType = '';
      continue;
    }

    // ═══════ SFT sub-section detection (within B2) ═══════
    if (text.includes('SFT-17-LES') || text.includes('Sale of listed equity share')) {
      flushPendingEntry();
      sftTableType = 'stock_sale';
      continue;
    }
    if (text.includes('SFT-17-EMF') || text.includes('Sale of unit of equity oriented mutual fund')) {
      flushPendingEntry();
      sftTableType = 'eq_mf_sale';
      continue;
    }
    if ((text.includes('SFT-18-OTU') || text.includes('Sale of other unit')) && !text.includes('SFT-18(Pur)')) {
      flushPendingEntry();
      sftTableType = 'debt_mf_sale';
      continue;
    }
    if (text.includes('SFT-18(Pur)') || text.includes('SFT18(Pur)') || text.includes('Purchase of mutual funds')) {
      flushPendingEntry();
      sftTableType = 'purchase';
      continue;
    }

    // ═══════ TDS sub-section detection (within B1) ═══════
    if (currentSection === 'B1') {
      if (text.includes('Salary') && (text.includes('Section 192') || text.includes('TDS-192'))) {
        flushTdsEntry();
        currentTdsType = 'salary';
      } else if (text.includes('Dividend') && (text.includes('Section 194') || text.includes('TDS-194'))) {
        flushTdsEntry();
        currentTdsType = 'dividend';
      } else if (text.includes('Interest') && (text.includes('Section 194A') || text.includes('TDS-194A'))) {
        flushTdsEntry();
        currentTdsType = 'interest';
      }
    }

    // ═══════ Information source detection ═══════
    if (text.includes('CENTRAL DEPOSITORY') || text.includes('CDSL') || text.includes('NSDL')) {
      currentInfoSource = 'Depository';
    }
    if (text.includes('KFin Technologies')) {
      currentInfoSource = 'KFintech';
    }
    if (text.includes('Computer Age Management')) {
      currentInfoSource = 'CAMS';
    }

    // ═══════ B1: TDS Parsing ═══════
    if (currentSection === 'B1' && currentTdsType) {
      // Detect TDS summary rows (contain TDS-192/194/194A info codes)
      if (text.includes('TDS-192') || text.includes('TDS-194')) {
        const nums = getRowNumbers(row);
        if (nums.length >= 3) {
          const amount = nums[nums.length - 1].value;
          const count = nums.length >= 3 ? nums[nums.length - 2].value : 0;

          // Extract info source name from text
          let infoSource = '';
          for (const cell of row.cells) {
            const ct = cell.text.trim();
            if (ct.length > 10 && !ct.includes('TDS-') && !ct.includes('Section') &&
                !ct.includes('received') && !ct.includes('Interest') &&
                !ct.includes('Dividend') && !ct.includes('Salary') &&
                !isNumericText(ct.replace(/\s/g, ''))) {
              infoSource = ct;
              break;
            }
          }

          flushTdsEntry();
          currentTdsEntry = {
            info_code: text.includes('TDS-194A') ? 'TDS-194A' :
                       text.includes('TDS-194') ? 'TDS-194' : 'TDS-192',
            info_source: infoSource,
            total_amount: amount,
            count: count,
            tds_deducted: 0,
            tds_deposited: 0,
            quarters: [],
          };

          // Accumulate totals
          if (text.includes('TDS-194A')) {
            result.totalInterest += amount;
          } else if (text.includes('TDS-194')) {
            result.totalDividends += amount;
          } else if (text.includes('TDS-192')) {
            result.totalSalary += amount;
          }
        }
        continue;
      }

      // Parse TDS detail rows (quarter rows)
      // Format: sr_no, Q1-Q4(quarter), DD/MM/YYYY, amount_paid, tds_deducted, tds_deposited, status
      const hasQuarter = /Q[1-4]/.test(text);
      const hasDate = /\d{2}\/\d{2}\/\d{4}/.test(text);
      const isDigitStart = /^\d+$/.test(firstCell);

      if (hasQuarter && hasDate && isDigitStart && currentTdsEntry) {
        const nums = getRowNumbers(row);
        // After sr_no, expect: amount_paid, tds_deducted, tds_deposited
        const dataNums = nums.slice(1); // skip sr_no
        const amountPaid = dataNums.length >= 1 ? dataNums[0].value : 0;
        const tdsDeducted = dataNums.length >= 2 ? dataNums[1].value : 0;
        const tdsDeposited = dataNums.length >= 3 ? dataNums[2].value : 0;

        // Extract quarter label
        const qMatch = text.match(/(Q[1-4]\([^)]*\))/);
        const quarter = qMatch ? qMatch[1] : '';
        const date = extractDate(text);

        currentTdsEntry.quarters.push({
          quarter,
          date,
          amount_paid: amountPaid,
          tds_deducted: tdsDeducted,
          tds_deposited: tdsDeposited,
          status: extractStatus(text),
        });

        currentTdsEntry.tds_deducted += tdsDeducted;
        currentTdsEntry.tds_deposited += tdsDeposited;
        result.totalTds += tdsDeducted;
        continue;
      }
    }

    // ═══════ B2: SFT Sale Table Parsing ═══════
    if (currentSection === 'B2' && ['stock_sale', 'eq_mf_sale', 'debt_mf_sale'].includes(sftTableType)) {
      // Data row detection:
      //   - First cell is a small integer (serial number, 1-999)
      //   - Row contains a date in DD/MM/YYYY format
      //   - Row doesn't contain SFT codes or INFORMATION keywords (those are summary rows)
      const srNoCandidate = parseInt(firstCell);
      const isDataRow = /^\d+$/.test(firstCell) &&
                        srNoCandidate >= 1 && srNoCandidate <= 999 &&
                        /\d{2}\/\d{2}\/\d{4}/.test(text) &&
                        !text.includes('SFT-') &&
                        !text.includes('INFORMATION');

      if (isDataRow) {
        // ── Flush previous entry (processes all its accumulated rows) ──
        flushPendingEntry();

        // ── Start new entry — just record metadata, numbers extracted at flush ──
        pendingEntry = {
          sr_no: srNoCandidate,
          date: extractDate(text),
          security_name: '',
          isin: extractIsin(text),
          security_class: '',
          debit_type: 'Market',
          credit_type: 'Market',
          asset_type: 'Long term', // will be overridden at flush from all rows
          quantity: 0,
          sale_price: 0,
          sales_consideration: 0,
          stt: 0,
          cost_of_acquisition: 0,
          unit_fmv: 0,
          fair_market_value: 0,
          indexed_cost: 0,
          status: 'Active',
          info_source: currentInfoSource,
        };
        sftTableTypeAtEntry = sftTableType; // capture table type at entry creation
        pendingEntryRows = [row];
        lastSrNo = srNoCandidate;
      } else if (pendingEntry) {
        // ── Continuation row: accumulate for later processing ──
        // MINIMAL filter: only exclude page navigation and totals.
        // Section boundaries (SFT-, Part B) are already handled at the top
        // of the loop, so by this point pendingEntry would be null if we hit one.
        const trimmed = text.trim();
        if (trimmed &&
            !trimmed.startsWith('Page') &&
            !trimmed.startsWith('Download') &&
            !/\btotal\b/i.test(trimmed)) {
          pendingEntryRows.push(row);
        }
      }
    }

    // ═══════ B2: Purchase Parsing (SFT-18(Pur)) ═══════
    if (currentSection === 'B2' && sftTableType === 'purchase') {
      // Purchase detail rows start with Q1-Q4
      if (text.startsWith('Q1') || text.startsWith('Q2') || text.startsWith('Q3') || text.startsWith('Q4') ||
          (firstCell.startsWith('Q') && /^Q[1-4]/.test(firstCell))) {
        const parts = row.cells.map(c => c.text.trim());
        const nums = getRowNumbers(row);
        const purchaseEntry: MfPurchaseEntry = {
          info_code: 'SFT-18(Pur)',
          info_source: currentInfoSource,
          quarter: parts[0] || '',
          client_id: parts[1] || '',
          amc_name: parts[2] || '',
          holder_flag: parts[3] || 'First',
          purchase_amount: nums.length >= 2 ? nums[nums.length - 2].value : 0,
          sales_value: nums.length >= 1 ? nums[nums.length - 1].value : 0,
          status: extractStatus(text),
        };
        result.mfPurchases.push(purchaseEntry);
      }
      // Also handle numeric-start rows (sr_no based purchase rows from some AIS versions)
      else if (/^\d+$/.test(firstCell) && text.includes('Q') && /Q[1-4]/.test(text)) {
        const nums = getRowNumbers(row);
        const dataNums = nums.slice(1); // skip sr_no
        const purchaseEntry: MfPurchaseEntry = {
          info_code: 'SFT-18(Pur)',
          info_source: currentInfoSource,
          quarter: text.match(/Q[1-4]\([^)]*\)/)?.[0] || '',
          client_id: '',
          amc_name: '',
          holder_flag: 'First',
          purchase_amount: dataNums.length >= 2 ? dataNums[dataNums.length - 2].value : 0,
          sales_value: dataNums.length >= 1 ? dataNums[dataNums.length - 1].value : 0,
          status: extractStatus(text),
        };
        // Try to extract AMC name from cells
        for (const cell of row.cells) {
          if (cell.text.length > 5 && !isNumericText(cell.text.replace(/\s/g, '')) &&
              !cell.text.includes('Q') && cell.text !== 'First' && cell.text !== 'Active') {
            purchaseEntry.amc_name = cell.text;
            break;
          }
        }
        result.mfPurchases.push(purchaseEntry);
      }
    }

    // ═══════ B3: Tax Payment Parsing ═══════
    if (currentSection === 'B3') {
      // Tax payment rows have a financial year pattern and numeric amounts
      const fyMatch = text.match(/(\d{4}-\d{2})/);
      const isDataRow = /^\d+$/.test(firstCell) && fyMatch;

      if (isDataRow) {
        const nums = getRowNumbers(row);
        const dataNums = nums.slice(1).map(n => n.value); // skip sr_no

        // Expected: tax_a, surcharge_b, cess_c, others_d, total, bsr_code(?), challan_serial(?)
        // At minimum we need 5 numbers: tax, surcharge, cess, others, total
        if (dataNums.length >= 5) {
          // Extract major/minor head text
          let majorHead = '';
          let minorHead = '';
          for (const cell of row.cells) {
            const ct = cell.text.trim().toLowerCase();
            if (ct.includes('income tax')) majorHead = 'Income Tax';
            if (ct.includes('self') && ct.includes('assessment')) minorHead = 'Self Assessment';
            if (ct.includes('advance')) minorHead = 'Advance Tax';
          }

          const payment: TaxPayment = {
            financial_year: fyMatch![1],
            major_head: majorHead || 'Income Tax',
            minor_head: minorHead || 'Self Assessment',
            tax_a: dataNums[0] || 0,
            surcharge_b: dataNums[1] || 0,
            education_cess_c: dataNums[2] || 0,
            others_d: dataNums[3] || 0,
            total: dataNums[4] || 0,
            bsr_code: dataNums.length > 5 ? dataNums[5].toString() : '',
            date_of_deposit: extractDate(text),
            challan_serial: dataNums.length > 6 ? dataNums[6] : 0,
            challan_id: dataNums.length > 7 ? dataNums[7].toString() : '',
          };
          result.taxPayments.push(payment);
        }
      }
    }
  }

  // ── Flush final entries ──
  flushPendingEntry();
  flushTdsEntry();

  return result;
}

// ─── Push sale entry to appropriate array ───────────────────────────────────

function pushSaleEntry(
  result: ReturnType<typeof parseAIS>,
  tableType: string,
  entry: SftSaleEntry
) {
  if (!entry.security_name) entry.security_name = 'Unknown';
  if (!entry.asset_type) entry.asset_type = 'Long term';
  if (!entry.isin) entry.isin = extractIsin(entry.security_name || '') || null;

  switch (tableType) {
    case 'stock_sale':
      result.stockSales.push(entry);
      break;
    case 'eq_mf_sale':
      result.equityMfSales.push(entry);
      break;
    case 'debt_mf_sale':
      result.debtMfSales.push(entry);
      break;
  }
}

// ─── Compute capital gains from sale entries ────────────────────────────────

function computeGains(entries: SftSaleEntry[]) {
  let stcg = 0;
  let ltcg = 0;

  for (const e of entries) {
    const sale = e.sales_consideration || 0;
    const cost = e.cost_of_acquisition || 0;
    const fmv = e.fair_market_value || 0;

    if (e.asset_type?.toLowerCase().includes('short')) {
      // STCG: simple gain, no grandfathering
      stcg += sale - cost;
    } else {
      // LTCG: apply grandfathering if FMV available
      if (fmv > 0 && fmv > cost) {
        // FMV is higher than cost — use FMV as cost basis
        // But cap at sale price to prevent artificial loss
        const effectiveCost = Math.min(fmv, sale);
        ltcg += sale - effectiveCost;
      } else {
        // COA is higher or FMV not available — use COA
        ltcg += sale - cost;
      }
    }
  }

  return { stcg, ltcg };
}

// ─── Main handler ───────────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
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

    const body = await req.json();
    const { file_base64: fileBase64, password, owner_id: bodyOwnerId, member_id: memberId, file_name: fileName } = body;

    // owner_id is ALWAYS derived from the verified JWT, never trusted from body.
    if (bodyOwnerId && bodyOwnerId !== authedUserId) {
      return jsonError('Forbidden', 403);
    }
    const ownerId = authedUserId;

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

    console.log(`AIS-PARSE: Starting, file size ${fileBytes.length} bytes, password ${password ? 'provided' : 'none'}`);

    // ── Extract text from PDF ──
    const textItems = await extractTextItems(fileBytes, password);
    console.log(`AIS-PARSE: Extracted ${textItems.length} text items`);

    // ── Group into rows ──
    const rows = groupIntoRows(textItems);
    console.log(`AIS-PARSE: Grouped into ${rows.length} rows`);

    // ── Parse AIS structure ──
    const parsed = parseAIS(rows);
    console.log(`AIS-PARSE: FY=${parsed.financialYear} PAN=${parsed.pan}`);
    console.log(`AIS-PARSE: Sections found: ${parsed.sectionHeaders.join(', ')}`);
    console.log(`AIS-PARSE: Stock sales: ${parsed.stockSales.length}`);
    console.log(`AIS-PARSE: Equity MF sales: ${parsed.equityMfSales.length}`);
    console.log(`AIS-PARSE: Debt MF sales: ${parsed.debtMfSales.length}`);
    console.log(`AIS-PARSE: MF purchases: ${parsed.mfPurchases.length}`);
    console.log(`AIS-PARSE: Tax payments: ${parsed.taxPayments.length}`);
    console.log(`AIS-PARSE: Salary=${parsed.totalSalary}, Dividends=${parsed.totalDividends}, Interest=${parsed.totalInterest}, TDS=${parsed.totalTds}`);

    // Log a sample entry for each type
    if (parsed.stockSales.length > 0) {
      const s = parsed.stockSales[0];
      console.log(`AIS-PARSE: Sample stock: ${s.security_name} isin=${s.isin} qty=${s.quantity} price=${s.sale_price} consideration=${s.sales_consideration} cost=${s.cost_of_acquisition} fmv=${s.fair_market_value}`);
    }
    if (parsed.equityMfSales.length > 0) {
      const s = parsed.equityMfSales[0];
      console.log(`AIS-PARSE: Sample eq-mf: ${s.security_name} isin=${s.isin} qty=${s.quantity} price=${s.sale_price} consideration=${s.sales_consideration} cost=${s.cost_of_acquisition} stt=${s.stt}`);
    }
    if (parsed.debtMfSales.length > 0) {
      const s = parsed.debtMfSales[0];
      console.log(`AIS-PARSE: Sample debt-mf: ${s.security_name} isin=${s.isin} qty=${s.quantity} price=${s.sale_price} consideration=${s.sales_consideration} cost=${s.cost_of_acquisition}`);
    }

    // ── Compute gains ──
    const stockGains = computeGains(parsed.stockSales);
    const eqMfGains = computeGains(parsed.equityMfSales);
    const debtMfGains = computeGains(parsed.debtMfSales);

    console.log(`AIS-PARSE: Stock gains STCG=${stockGains.stcg}, LTCG=${stockGains.ltcg}`);
    console.log(`AIS-PARSE: Eq MF gains STCG=${eqMfGains.stcg}, LTCG=${eqMfGains.ltcg}`);
    console.log(`AIS-PARSE: Debt MF gains STCG=${debtMfGains.stcg}, LTCG=${debtMfGains.ltcg}`);

    // ── Match PAN to member ──
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    let resolvedMemberId = memberId || null;
    if (!resolvedMemberId && parsed.pan) {
      const { data: members } = await supabase
        .from('family_members')
        .select('id, display_name, pan')
        .eq('owner_id', ownerId);

      const match = members?.find(
        (m: any) => m.pan?.replace(/\s/g, '').toUpperCase() === parsed.pan?.toUpperCase()
      );
      if (match) {
        resolvedMemberId = match.id;
        console.log(`AIS-PARSE: Matched PAN ${parsed.pan} → member ${match.display_name}`);
      }
    }

    // ── Derive FY if not detected ──
    if (!parsed.financialYear) {
      const now = new Date();
      const y = now.getMonth() >= 3 ? now.getFullYear() : now.getFullYear() - 1;
      parsed.financialYear = `FY${(y % 100).toString().padStart(2, '0')}${((y + 1) % 100).toString().padStart(2, '0')}`;
    }

    // ── Upsert into ais_statements ──
    const upsertData = {
      owner_id: ownerId,
      member_id: resolvedMemberId,
      financial_year: parsed.financialYear,
      pan: parsed.pan,
      investor_name: parsed.name,
      salary_income: parsed.salaryEntries,
      dividend_income: parsed.dividendEntries,
      interest_income: parsed.interestEntries,
      stock_sales: parsed.stockSales,
      equity_mf_sales: parsed.equityMfSales,
      debt_mf_sales: parsed.debtMfSales,
      mf_purchases: parsed.mfPurchases,
      tax_payments: parsed.taxPayments,
      stock_stcg: stockGains.stcg,
      stock_ltcg: stockGains.ltcg,
      eq_mf_stcg: eqMfGains.stcg,
      eq_mf_ltcg: eqMfGains.ltcg,
      debt_mf_stcg: debtMfGains.stcg,
      debt_mf_ltcg: debtMfGains.ltcg,
      total_salary: parsed.totalSalary,
      total_tds: parsed.totalTds,
      total_dividends: parsed.totalDividends,
      total_interest: parsed.totalInterest,
      stock_sale_count: parsed.stockSales.length,
      mf_sale_count: parsed.equityMfSales.length + parsed.debtMfSales.length,
      purchase_count: parsed.mfPurchases.length,
      source_file: fileName || 'AIS_PDF',
    };

    const { error: upsertError } = await supabase
      .from('ais_statements')
      .upsert(upsertData, { onConflict: 'owner_id, member_id, financial_year' });

    if (upsertError) {
      console.error('AIS-PARSE: Upsert error:', upsertError);
      throw new Error(`Failed to store AIS data: ${upsertError.message}`);
    }

    // ── Also update member DOB if available ──
    if (resolvedMemberId && parsed.dob) {
      const [day, month, year] = parsed.dob.split('/');
      if (day && month && year) {
        await supabase
          .from('family_members')
          .update({ date_of_birth: `${year}-${month}-${day}` })
          .eq('id', resolvedMemberId)
          .is('date_of_birth', null);
      }
    }

    console.log('AIS-PARSE: Successfully stored AIS statement');

    const responseData = {
      success: true,
      financial_year: parsed.financialYear,
      pan: parsed.pan,
      member_id: resolvedMemberId,
      sections_found: parsed.sectionHeaders,
      stock_sales: parsed.stockSales.length,
      equity_mf_sales: parsed.equityMfSales.length,
      debt_mf_sales: parsed.debtMfSales.length,
      mf_purchases: parsed.mfPurchases.length,
      tax_payments: parsed.taxPayments.length,
      salary: parsed.totalSalary,
      dividends: parsed.totalDividends,
      interest: parsed.totalInterest,
      tds_deducted: parsed.totalTds,
      gains: {
        stock: stockGains,
        equity_mf: eqMfGains,
        debt_mf: debtMfGains,
      },
      total_gain: stockGains.stcg + stockGains.ltcg + eqMfGains.stcg + eqMfGains.ltcg + debtMfGains.stcg + debtMfGains.ltcg,
    };

    return new Response(
      JSON.stringify(responseData),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error: any) {
    console.error('AIS-PARSE: Error:', error);
    return jsonError('Internal server error', 500);
  }
});
