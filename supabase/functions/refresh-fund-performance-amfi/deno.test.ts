/**
 * Unit tests for refresh-fund-performance-amfi.
 *
 * Run with:
 *   deno test --allow-net --allow-env --allow-read supabase/functions/refresh-fund-performance-amfi/deno.test.ts
 */

import {
  assert,
  assertEquals,
} from 'https://deno.land/std@0.208.0/assert/mod.ts';

import {
  fetchFundPerformance,
  formatDdMmmYyyy,
  previousBusinessDay,
  toFundMasterUpdate,
  type AmfiFundPerformanceRow,
} from './index.ts';

const fixtureUrl = new URL(
  './__fixtures__/fundperformance_equity_largecap.json',
  import.meta.url,
);
const fixtureText = await Deno.readTextFile(fixtureUrl);
const fixtureRows = JSON.parse(fixtureText) as AmfiFundPerformanceRow[];

// ─── formatDdMmmYyyy ───────────────────────────────────────────────────────
Deno.test('formatDdMmmYyyy pads day and uses 3-letter month', () => {
  const d = new Date(Date.UTC(2025, 0, 7)); // 7 Jan 2025
  assertEquals(formatDdMmmYyyy(d), '07-Jan-2025');
});

// ─── previousBusinessDay ───────────────────────────────────────────────────
Deno.test('previousBusinessDay skips weekends', () => {
  // Monday 6 Apr 2026 → Friday 3 Apr 2026
  const mon = new Date(Date.UTC(2026, 3, 6));
  const prev = previousBusinessDay(mon);
  assertEquals(prev.getUTCDay(), 5); // Friday
  assertEquals(prev.getUTCDate(), 3);
});

// ─── toFundMasterUpdate ────────────────────────────────────────────────────
Deno.test('toFundMasterUpdate extracts schemeCode, NAV and returns', () => {
  const nowIso = '2026-04-07T03:30:00.000Z';
  const payload = toFundMasterUpdate(fixtureRows[0], nowIso);

  assertEquals(payload.amfi_code, 119551);
  assertEquals(payload.fund_name, 'Axis Bluechip Fund - Regular Plan - Growth');
  assertEquals(payload.latest_nav, 62.8412);
  assertEquals(payload.nav_direct, 68.1923);
  assertEquals(payload.return_1y, 18.74);
  assertEquals(payload.return_3y, 14.22);
  assertEquals(payload.return_5y, 13.81);
  assertEquals(payload.return_3m, 5.82);
  assertEquals(payload.return_6m, 11.45);
  assertEquals(payload.return_direct_1y, 19.92);
  assertEquals(payload.return_bench_1y, 17.66);
  assertEquals(payload.info_ratio_3y, 0.41);
  assertEquals(payload.info_ratio_5y, 0.38);
  assertEquals(payload.riskometer_scheme, 'Very High');
  assertEquals(payload.returns_source, 'AMFI');
  assertEquals(payload.returns_updated_at, nowIso);
  assertEquals(payload.aum_cr, 34211.56);
  assertEquals(payload.benchmark_index, 'NIFTY 100 TRI');
});

Deno.test('toFundMasterUpdate tolerates missing optional fields', () => {
  const payload = toFundMasterUpdate(fixtureRows[1], '2026-04-07T03:30:00.000Z');
  assertEquals(payload.amfi_code, 120505);
  assertEquals(payload.return_1y, 17.22);
  // Missing fields should be null, not undefined (except fund_name-like fields)
  assertEquals(payload.return_7d, null);
  assertEquals(payload.info_ratio_1y, null);
  assertEquals(payload.return_direct_1y, null);
});

Deno.test('toFundMasterUpdate coerces numeric strings and dashes', () => {
  const row: AmfiFundPerformanceRow = {
    schemeCode: '999',
    schemeName: 'Test Fund',
    return1YearRegular: '12.34',
    return3YearRegular: '-',
    return5YearRegular: 'N.A.',
    navRegular: '1,234.56',
    dailyAUM: '500.00',
  };
  const payload = toFundMasterUpdate(row, '2026-04-07T00:00:00Z');
  assertEquals(payload.amfi_code, 999);
  assertEquals(payload.return_1y, 12.34);
  assertEquals(payload.return_3y, null);
  assertEquals(payload.return_5y, null);
  assertEquals(payload.latest_nav, 1234.56);
  assertEquals(payload.aum_cr, 500);
});

// ─── fetchFundPerformance with stubbed fetch ───────────────────────────────
Deno.test('fetchFundPerformance parses array response from stubbed fetch', async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl = '';
  let capturedBody = '';
  globalThis.fetch = ((input: string | URL | Request, init?: RequestInit) => {
    capturedUrl = typeof input === 'string' ? input : input.toString();
    capturedBody = (init?.body as string) ?? '';
    return Promise.resolve(
      new Response(fixtureText, {
        status: 200,
        headers: { 'content-type': 'application/json' },
      }),
    );
  }) as typeof fetch;

  try {
    const rows = await fetchFundPerformance({
      maturityType: 1,
      category: 1,
      subCategory: 101,
      reportDate: '06-Apr-2026',
    });
    assertEquals(rows.length, 2);
    assertEquals(rows[0].schemeCode, 119551);
    assert(capturedUrl.includes('/fundperformance'));
    const body = JSON.parse(capturedBody);
    assertEquals(body.maturityType, 1);
    assertEquals(body.category, 1);
    assertEquals(body.subCategory, 101);
    assertEquals(body.mfid, 0);
    assertEquals(body.reportDate, '06-Apr-2026');
  } finally {
    globalThis.fetch = originalFetch;
  }
});

// ─── Upsert payload shape ──────────────────────────────────────────────────
Deno.test('toFundMasterUpdate payload keys match fund_master schema', () => {
  const payload = toFundMasterUpdate(fixtureRows[0], new Date().toISOString());
  const expectedKeys = new Set([
    'amfi_code',
    'fund_name',
    'amc',
    'category',
    'sub_category',
    'benchmark_index',
    'latest_nav',
    'nav_direct',
    'aum_cr',
    'return_7d',
    'return_15d',
    'return_1m',
    'return_3m',
    'return_6m',
    'return_1y',
    'return_3y',
    'return_5y',
    'return_10y',
    'return_inception',
    'return_direct_1y',
    'return_direct_3y',
    'return_direct_5y',
    'return_direct_10y',
    'return_bench_1y',
    'return_bench_3y',
    'return_bench_5y',
    'return_bench_10y',
    'info_ratio_1y',
    'info_ratio_3y',
    'info_ratio_5y',
    'info_ratio_10y',
    'riskometer_scheme',
    'riskometer_bench',
    'crisil_rating',
    'returns_source',
    'returns_updated_at',
  ]);
  for (const key of expectedKeys) {
    assert(
      Object.prototype.hasOwnProperty.call(payload, key),
      `missing key: ${key}`,
    );
  }
});
