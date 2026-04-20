# Portfolio Overlap & Concentration Analysis — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a portfolio intelligence system that scrapes fund holdings from Groww, computes stock/sector concentration and fund-pair overlap, shows results on Analytics + Fund Detail screens, and generates monthly alerts for concentration risks.

**Architecture:** Supabase `fund_holdings_cache` table stores scraped Groww holdings per scheme (refreshed monthly). A `fetch-fund-holdings` Edge Function resolves Groww slugs and scrapes `__NEXT_DATA__`. Pure Dart computation engine runs overlap/concentration analysis client-side. A `check-portfolio-overlap` Edge Function runs semi-monthly for batch alerting through the existing alert pipeline.

**Tech Stack:** Flutter 3.22+ / Dart 3.3+, Riverpod codegen, Freezed models, Supabase (PostgREST + Edge Functions + pg_cron), Groww web scraping.

**Important:** This project has no git repository — skip all git commands.

**Build command:** `export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && flutter build web`

**Codegen command:** `dart run build_runner build --delete-conflicting-outputs`

**Base path:** `/Users/nisanth/Nisanth MacM3Pro/Nisanth/Wealth Management/Wealth Management App/evesh_wealth`

---

### Task 1: Supabase Migration — fund_holdings_cache + groww_slug + prefs

**Files:**
- Create: `supabase/migrations/015_fund_holdings_cache.sql`

- [ ] **Step 1: Create migration file**

```sql
-- 015_fund_holdings_cache.sql
-- Fund holdings cache (Groww data) + groww_slug + notification prefs update

-- ══════════════════════════════════════════════════════════════
-- 1. fund_holdings_cache table
-- ══════════════════════════════════════════════════════════════

CREATE TABLE fund_holdings_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  amfi_code INT NOT NULL,
  company_name TEXT NOT NULL,
  sector_name TEXT,
  corpus_pct NUMERIC(8,4) NOT NULL,
  instrument_name TEXT,
  nature_name TEXT,
  rating TEXT,
  market_value NUMERIC(18,2),
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_holding UNIQUE (amfi_code, company_name)
);

CREATE INDEX idx_holdings_amfi ON fund_holdings_cache (amfi_code);
CREATE INDEX idx_holdings_fetched ON fund_holdings_cache (fetched_at);

-- No RLS — public fund data, not user-specific.

-- ══════════════════════════════════════════════════════════════
-- 2. Add groww_slug to fund_master
-- ══════════════════════════════════════════════════════════════

ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS groww_slug TEXT;

-- ══════════════════════════════════════════════════════════════
-- 3. Add overlap notification prefs for existing profiles
-- ════════════════════════════════════════════════════════════��═

UPDATE profiles
SET notification_prefs = notification_prefs
  || '{"stock_concentration": true, "sector_concentration": true, "fund_overlap": true}'::jsonb
WHERE notification_prefs IS NOT NULL;
```

- [ ] **Step 2: Verify** — Read the file back, confirm all 3 sections are present. Remind user to apply via Supabase Dashboard SQL Editor.

---

### Task 2: Overlap Models (Freezed) + Codegen

**Files:**
- Create: `lib/domain/models/overlap_models.dart`

- [ ] **Step 1: Create the models**

```dart
// lib/domain/models/overlap_models.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'overlap_models.freezed.dart';
part 'overlap_models.g.dart';

// ── Cached holding from Groww ────────────────────────────────────────────────

@freezed
class CachedFundHolding with _$CachedFundHolding {
  const factory CachedFundHolding({
    required int amfiCode,
    required String companyName,
    String? sectorName,
    required double corpusPct,
    String? instrumentName,
    String? natureName,
    String? rating,
    double? marketValue,
    required String fetchedAt,
  }) = _CachedFundHolding;

  factory CachedFundHolding.fromJson(Map<String, dynamic> json) =>
      _$CachedFundHoldingFromJson(json);
}

// ── Input for overlap computation ────────────────────────────────────────────

/// A fund + its cached holdings + its weight in the user's portfolio.
class FundWithHoldings {
  final int amfiCode;
  final String fundName;
  final double portfolioWeightPct; // fund's currentValue / total portfolio
  final List<CachedFundHolding> holdings;

  const FundWithHoldings({
    required this.amfiCode,
    required this.fundName,
    required this.portfolioWeightPct,
    required this.holdings,
  });
}

// ── Computation results ──────────────────────────────────────────────────────

enum RiskLevel { low, moderate, high }

class StockExposure {
  final String companyName;
  final String? sectorName;
  final double effectiveWeightPct;
  final RiskLevel risk;
  final List<String> heldInFunds; // fund names holding this stock

  const StockExposure({
    required this.companyName,
    this.sectorName,
    required this.effectiveWeightPct,
    required this.risk,
    required this.heldInFunds,
  });
}

class SectorExposure {
  final String sectorName;
  final double weightPct;
  final RiskLevel risk;

  const SectorExposure({
    required this.sectorName,
    required this.weightPct,
    required this.risk,
  });
}

class FundPairOverlap {
  final String fundNameA;
  final String fundNameB;
  final int amfiCodeA;
  final int amfiCodeB;
  final double overlapPct;
  final RiskLevel risk;

  const FundPairOverlap({
    required this.fundNameA,
    required this.fundNameB,
    required this.amfiCodeA,
    required this.amfiCodeB,
    required this.overlapPct,
    required this.risk,
  });
}

class OverlapResult {
  final List<StockExposure> stockExposures;
  final List<SectorExposure> sectorExposures;
  final List<FundPairOverlap> fundPairOverlaps;
  final RiskLevel overallRisk;
  final int issueCount;

  const OverlapResult({
    required this.stockExposures,
    required this.sectorExposures,
    required this.fundPairOverlaps,
    required this.overallRisk,
    required this.issueCount,
  });
}

/// Pre-buy delta analysis: how metrics change if a candidate fund is added.
class PreBuyAnalysis {
  final OverlapResult before;
  final OverlapResult after;
  final List<FundPairOverlap> newOverlaps; // overlaps involving the candidate
  final List<SectorDelta> sectorDeltas;
  final List<StockDelta> stockDeltas;
  final RiskLevel candidateRisk;

  const PreBuyAnalysis({
    required this.before,
    required this.after,
    required this.newOverlaps,
    required this.sectorDeltas,
    required this.stockDeltas,
    required this.candidateRisk,
  });
}

class SectorDelta {
  final String sectorName;
  final double beforePct;
  final double afterPct;
  final RiskLevel beforeRisk;
  final RiskLevel afterRisk;

  const SectorDelta({
    required this.sectorName,
    required this.beforePct,
    required this.afterPct,
    required this.beforeRisk,
    required this.afterRisk,
  });

  bool get changed => beforeRisk != afterRisk;
}

class StockDelta {
  final String companyName;
  final double beforePct;
  final double afterPct;
  final RiskLevel beforeRisk;
  final RiskLevel afterRisk;

  const StockDelta({
    required this.companyName,
    required this.beforePct,
    required this.afterPct,
    required this.beforeRisk,
    required this.afterRisk,
  });

  bool get changed => beforeRisk != afterRisk;
}
```

- [ ] **Step 2: Run codegen**

Run: `cd "/Users/nisanth/Nisanth MacM3Pro/Nisanth/Wealth Management/Wealth Management App/evesh_wealth" && dart run build_runner build --delete-conflicting-outputs`

Verify: `overlap_models.freezed.dart` and `overlap_models.g.dart` are generated.

---

### Task 3: Edge Function — fetch-fund-holdings (Groww Scraper)

**Files:**
- Create: `supabase/functions/fetch-fund-holdings/index.ts`

- [ ] **Step 1: Create the Edge Function**

```typescript
// supabase/functions/fetch-fund-holdings/index.ts
// Fetches and caches fund holdings from Groww for a given AMFI code.
// 1. Resolves Groww slug (search API → cache in fund_master.groww_slug)
// 2. Fetches scheme page, extracts __NEXT_DATA__ holdings
// 3. Upserts into fund_holdings_cache

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { DOMParser } from 'https://deno.land/x/deno_dom@v0.1.38/deno-dom-wasm.ts'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface GrowwHolding {
  company_name: string
  corpus_per: number
  sector_name: string
  instrument_name: string
  rating: string
  market_value: number
  nature_name: string
}

interface FetchResult {
  amfi_code: number
  holdings_count: number
  fetched_at: string
  slug: string | null
  error?: string
}

Deno.serve(async (req) => {
  const supabase = createClient(supabaseUrl, supabaseServiceKey)

  let body: { amfi_code?: number; amfi_codes?: number[]; fund_name?: string }
  try {
    body = await req.json()
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), { status: 400 })
  }

  // Support single or batch mode
  const amfiCodes = body.amfi_codes ?? (body.amfi_code ? [body.amfi_code] : [])
  if (amfiCodes.length === 0) {
    return new Response(JSON.stringify({ error: 'amfi_code or amfi_codes required' }), { status: 400 })
  }

  const results: FetchResult[] = []

  for (const amfiCode of amfiCodes) {
    try {
      const result = await fetchAndCacheHoldings(supabase, amfiCode, body.fund_name)
      results.push(result)
    } catch (e) {
      results.push({
        amfi_code: amfiCode,
        holdings_count: 0,
        fetched_at: new Date().toISOString(),
        slug: null,
        error: String(e),
      })
    }

    // Rate limit: 500ms between Groww fetches
    if (amfiCodes.length > 1) {
      await new Promise(resolve => setTimeout(resolve, 500))
    }
  }

  return new Response(JSON.stringify({ results }))
})

async function fetchAndCacheHoldings(
  supabase: any,
  amfiCode: number,
  fundNameHint?: string,
): Promise<FetchResult> {
  const now = new Date().toISOString()

  // 1. Check for existing slug
  const { data: fundRow } = await supabase
    .from('fund_master')
    .select('groww_slug, fund_name')
    .eq('amfi_code', amfiCode)
    .single()

  let slug: string | null = fundRow?.groww_slug ?? null
  const fundName = fundNameHint ?? fundRow?.fund_name ?? ''

  // 2. Resolve slug via Groww search if needed
  if (!slug && fundName) {
    slug = await resolveGrowwSlug(fundName)
    if (slug) {
      await supabase
        .from('fund_master')
        .update({ groww_slug: slug })
        .eq('amfi_code', amfiCode)
    }
  }

  if (!slug) {
    return { amfi_code: amfiCode, holdings_count: 0, fetched_at: now, slug: null, error: 'Could not resolve Groww slug' }
  }

  // 3. Fetch scheme page
  const pageUrl = `https://groww.in/mutual-funds/${slug}`
  const resp = await fetch(pageUrl, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      'Accept': 'text/html',
    },
  })

  if (!resp.ok) {
    return { amfi_code: amfiCode, holdings_count: 0, fetched_at: now, slug, error: `HTTP ${resp.status}` }
  }

  const html = await resp.text()

  // 4. Extract __NEXT_DATA__
  const holdings = extractHoldings(html)

  if (holdings.length === 0) {
    return { amfi_code: amfiCode, holdings_count: 0, fetched_at: now, slug, error: 'No holdings found in __NEXT_DATA__' }
  }

  // 5. Upsert holdings (delete old, insert new)
  await supabase
    .from('fund_holdings_cache')
    .delete()
    .eq('amfi_code', amfiCode)

  const rows = holdings.map((h: GrowwHolding) => ({
    amfi_code: amfiCode,
    company_name: h.company_name ?? 'Unknown',
    sector_name: h.sector_name ?? null,
    corpus_pct: h.corpus_per ?? 0,
    instrument_name: h.instrument_name ?? null,
    nature_name: h.nature_name ?? null,
    rating: h.rating ?? null,
    market_value: h.market_value ?? null,
    fetched_at: now,
  }))

  const { error: insertErr } = await supabase
    .from('fund_holdings_cache')
    .upsert(rows, { onConflict: 'amfi_code,company_name' })

  if (insertErr) {
    console.error('Insert error:', insertErr)
  }

  return { amfi_code: amfiCode, holdings_count: holdings.length, fetched_at: now, slug }
}

async function resolveGrowwSlug(fundName: string): Promise<string | null> {
  try {
    // Clean fund name for search
    const query = fundName
      .replace(/\s*-\s*(Direct|Regular)\s*Plan\s*/i, ' ')
      .replace(/\s*-\s*(Growth|IDCW|Dividend)\s*/i, '')
      .trim()
      .slice(0, 60)

    const searchUrl = `https://groww.in/v1/api/search/v1/entity?q=${encodeURIComponent(query)}&entity_type=mutual_fund&size=5`
    const resp = await fetch(searchUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Accept': 'application/json',
      },
    })

    if (!resp.ok) return null

    const data = await resp.json()
    const results = data?.content ?? data?.data ?? []

    if (results.length === 0) return null

    // Return first result's slug (search_id or url field)
    const first = results[0]
    // Groww search returns an entity with url or search_id
    const slug = first.url ?? first.search_id ?? first.slug ?? null

    // Slug might be a full path like "/mutual-funds/xyz" — extract just the slug
    if (slug?.startsWith('/mutual-funds/')) {
      return slug.replace('/mutual-funds/', '')
    }

    return slug
  } catch (e) {
    console.warn('Groww search failed:', e)
    return null
  }
}

function extractHoldings(html: string): GrowwHolding[] {
  try {
    // Find __NEXT_DATA__ script tag content
    const marker = '"__NEXT_DATA__"'
    const scriptStart = html.indexOf('<script id="__NEXT_DATA__"')
    if (scriptStart === -1) {
      // Try alternate pattern
      const altStart = html.indexOf('__NEXT_DATA__')
      if (altStart === -1) return []
    }

    // Extract JSON between <script> tags
    const jsonStart = html.indexOf('>', scriptStart) + 1
    const jsonEnd = html.indexOf('</script>', jsonStart)
    if (jsonStart <= 0 || jsonEnd <= jsonStart) return []

    const jsonStr = html.substring(jsonStart, jsonEnd).trim()
    const nextData = JSON.parse(jsonStr)

    // Navigate to holdings
    const holdings =
      nextData?.props?.pageProps?.mfServerSideData?.holdings ??
      nextData?.props?.pageProps?.holdings ??
      nextData?.props?.pageProps?.schemeData?.holdings ??
      []

    return holdings as GrowwHolding[]
  } catch (e) {
    console.warn('Failed to parse __NEXT_DATA__:', e)
    return []
  }
}
```

- [ ] **Step 2: Verify** — Read the file back, confirm all sections are present.

---

### Task 4: Overlap Providers (Fetch Cache + Trigger Refresh)

**Files:**
- Create: `lib/presentation/providers/overlap_provider.dart`

- [ ] **Step 1: Create overlap providers**

```dart
// lib/presentation/providers/overlap_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/overlap_models.dart';
import 'auth_provider.dart';
import 'portfolio_provider.dart';

part 'overlap_provider.g.dart';

/// Fetches cached holdings for a single fund.
/// Returns empty list if cache is stale or missing.
@riverpod
Future<List<CachedFundHolding>> fundHoldingsCache(
  FundHoldingsCacheRef ref,
  int amfiCode,
) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('fund_holdings_cache')
      .select()
      .eq('amfi_code', amfiCode)
      .order('corpus_pct', ascending: false);

  return (response as List)
      .map((row) => CachedFundHolding.fromJson(_snakeToCamelMap(row as Map<String, dynamic>)))
      .toList();
}

/// Checks if cached holdings for a fund are stale (>30 days).
@riverpod
Future<bool> isHoldingsCacheStale(
  IsHoldingsCacheStaleRef ref,
  int amfiCode,
) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('fund_holdings_cache')
      .select('fetched_at')
      .eq('amfi_code', amfiCode)
      .limit(1);

  if ((response as List).isEmpty) return true;

  final fetchedAt = DateTime.parse(response[0]['fetched_at'] as String);
  return DateTime.now().difference(fetchedAt).inDays > 30;
}

/// Fetches cached holdings for ALL funds in the user's portfolio.
/// Triggers refresh for stale funds via Edge Function.
@riverpod
Future<List<FundWithHoldings>> portfolioHoldings(
  PortfolioHoldingsRef ref,
  String? memberId,
) async {
  final portfolio = await ref.watch(portfolioSummaryProvider(memberId).future);
  final client = ref.watch(supabaseClientProvider);

  if (portfolio.fundHoldings.isEmpty) return [];

  final totalValue = portfolio.currentValue;
  if (totalValue <= 0) return [];

  // Collect AMFI codes for held MF funds
  final heldFunds = portfolio.fundHoldings
      .where((f) => f.assetType == 'MF' && f.currentValue > 0)
      .toList();

  // Check which funds need a refresh
  final staleCodes = <int>[];
  for (final fund in heldFunds) {
    final isStale = await ref.watch(isHoldingsCacheStaleProvider(fund.amfiCode).future);
    if (isStale) staleCodes.add(fund.amfiCode);
  }

  // Trigger batch refresh for stale funds
  if (staleCodes.isNotEmpty) {
    try {
      await client.functions.invoke(
        'fetch-fund-holdings',
        body: {'amfi_codes': staleCodes},
      );
      // Invalidate cache providers for refreshed funds
      for (final code in staleCodes) {
        ref.invalidate(fundHoldingsCacheProvider(code));
        ref.invalidate(isHoldingsCacheStaleProvider(code));
      }
    } catch (e) {
      // Graceful degradation: use stale cache if refresh fails
    }
  }

  // Build FundWithHoldings for each held fund
  final result = <FundWithHoldings>[];
  for (final fund in heldFunds) {
    final holdings = await ref.watch(fundHoldingsCacheProvider(fund.amfiCode).future);
    if (holdings.isEmpty) continue;

    result.add(FundWithHoldings(
      amfiCode: fund.amfiCode,
      fundName: fund.fundName,
      portfolioWeightPct: (fund.currentValue / totalValue) * 100,
      holdings: holdings,
    ));
  }

  return result;
}

/// Fetches cached holdings for a SINGLE candidate fund (pre-buy).
@riverpod
Future<FundWithHoldings?> candidateFundHoldings(
  CandidateFundHoldingsRef ref,
  int amfiCode,
  String fundName,
) async {
  final client = ref.watch(supabaseClientProvider);

  // Check if stale or missing
  final isStale = await ref.watch(isHoldingsCacheStaleProvider(amfiCode).future);
  if (isStale) {
    try {
      await client.functions.invoke(
        'fetch-fund-holdings',
        body: {'amfi_code': amfiCode, 'fund_name': fundName},
      );
      ref.invalidate(fundHoldingsCacheProvider(amfiCode));
      ref.invalidate(isHoldingsCacheStaleProvider(amfiCode));
    } catch (_) {}
  }

  final holdings = await ref.watch(fundHoldingsCacheProvider(amfiCode).future);
  if (holdings.isEmpty) return null;

  return FundWithHoldings(
    amfiCode: amfiCode,
    fundName: fundName,
    portfolioWeightPct: 10.0, // default assumed weight for pre-buy
    holdings: holdings,
  );
}

/// Helper: convert snake_case DB row keys to camelCase for Freezed fromJson.
Map<String, dynamic> _snakeToCamelMap(Map<String, dynamic> row) {
  return {
    'amfiCode': row['amfi_code'],
    'companyName': row['company_name'],
    'sectorName': row['sector_name'],
    'corpusPct': (row['corpus_pct'] as num?)?.toDouble() ?? 0.0,
    'instrumentName': row['instrument_name'],
    'natureName': row['nature_name'],
    'rating': row['rating'],
    'marketValue': (row['market_value'] as num?)?.toDouble(),
    'fetchedAt': row['fetched_at']?.toString() ?? '',
  };
}
```

- [ ] **Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

Verify: `overlap_provider.g.dart` is generated.

---

### Task 5: Computation Engine — Pure Dart

**Files:**
- Create: `lib/domain/usecases/compute_portfolio_overlap.dart`

- [ ] **Step 1: Create the computation engine**

```dart
// lib/domain/usecases/compute_portfolio_overlap.dart

import '../models/overlap_models.dart';

/// SEBI-aligned thresholds.
class OverlapThresholds {
  static const double stockHigh = 10.0;   // SEBI 20/25 rule
  static const double stockModerate = 7.0;
  static const double sectorHigh = 25.0;  // industry standard
  static const double sectorModerate = 20.0;
  static const double fundOverlapHigh = 50.0;   // SEBI Feb 2026
  static const double fundOverlapModerate = 35.0;
}

class PortfolioOverlapCalculator {
  const PortfolioOverlapCalculator._();

  /// Compute full overlap analysis for the portfolio.
  static OverlapResult compute(List<FundWithHoldings> funds) {
    final stocks = computeStockExposures(funds);
    final sectors = computeSectorExposures(funds);
    final pairs = computeFundPairOverlaps(funds);

    final stockIssues = stocks.where((s) => s.risk == RiskLevel.high).length;
    final sectorIssues = sectors.where((s) => s.risk == RiskLevel.high).length;
    final pairIssues = pairs.where((p) => p.risk == RiskLevel.high).length;
    final issueCount = stockIssues + sectorIssues + pairIssues;

    final hasHigh = stocks.any((s) => s.risk == RiskLevel.high) ||
        sectors.any((s) => s.risk == RiskLevel.high) ||
        pairs.any((p) => p.risk == RiskLevel.high);
    final hasModerate = stocks.any((s) => s.risk == RiskLevel.moderate) ||
        sectors.any((s) => s.risk == RiskLevel.moderate) ||
        pairs.any((p) => p.risk == RiskLevel.moderate);

    return OverlapResult(
      stockExposures: stocks,
      sectorExposures: sectors,
      fundPairOverlaps: pairs,
      overallRisk: hasHigh
          ? RiskLevel.high
          : hasModerate
              ? RiskLevel.moderate
              : RiskLevel.low,
      issueCount: issueCount,
    );
  }

  /// Compute pre-buy analysis: compare before vs after adding a candidate fund.
  static PreBuyAnalysis computePreBuy({
    required List<FundWithHoldings> currentFunds,
    required FundWithHoldings candidateFund,
    double candidateWeightPct = 10.0,
  }) {
    final before = compute(currentFunds);

    // Reweight: reduce existing funds proportionally to make room for candidate
    final scaleFactor = (100.0 - candidateWeightPct) / 100.0;
    final adjustedFunds = currentFunds
        .map((f) => FundWithHoldings(
              amfiCode: f.amfiCode,
              fundName: f.fundName,
              portfolioWeightPct: f.portfolioWeightPct * scaleFactor,
              holdings: f.holdings,
            ))
        .toList();

    final withCandidate = [
      ...adjustedFunds,
      FundWithHoldings(
        amfiCode: candidateFund.amfiCode,
        fundName: candidateFund.fundName,
        portfolioWeightPct: candidateWeightPct,
        holdings: candidateFund.holdings,
      ),
    ];

    final after = compute(withCandidate);

    // New overlaps involving the candidate
    final newOverlaps = after.fundPairOverlaps
        .where((p) =>
            p.amfiCodeA == candidateFund.amfiCode ||
            p.amfiCodeB == candidateFund.amfiCode)
        .toList();

    // Sector deltas
    final beforeSectors = {for (final s in before.sectorExposures) s.sectorName: s};
    final afterSectors = {for (final s in after.sectorExposures) s.sectorName: s};
    final allSectorNames = {...beforeSectors.keys, ...afterSectors.keys};
    final sectorDeltas = allSectorNames.map((name) {
      final b = beforeSectors[name];
      final a = afterSectors[name];
      return SectorDelta(
        sectorName: name,
        beforePct: b?.weightPct ?? 0,
        afterPct: a?.weightPct ?? 0,
        beforeRisk: b?.risk ?? RiskLevel.low,
        afterRisk: a?.risk ?? RiskLevel.low,
      );
    }).where((d) => (d.afterPct - d.beforePct).abs() > 0.5).toList()
      ..sort((a, b) => (b.afterPct - b.beforePct).compareTo(a.afterPct - a.beforePct));

    // Stock deltas (top movers only)
    final beforeStocks = {for (final s in before.stockExposures) s.companyName: s};
    final afterStocks = {for (final s in after.stockExposures) s.companyName: s};
    final allStockNames = {...beforeStocks.keys, ...afterStocks.keys};
    final stockDeltas = allStockNames.map((name) {
      final b = beforeStocks[name];
      final a = afterStocks[name];
      return StockDelta(
        companyName: name,
        beforePct: b?.effectiveWeightPct ?? 0,
        afterPct: a?.effectiveWeightPct ?? 0,
        beforeRisk: b?.risk ?? RiskLevel.low,
        afterRisk: a?.risk ?? RiskLevel.low,
      );
    }).where((d) => d.changed || (d.afterPct - d.beforePct).abs() > 1.0).toList()
      ..sort((a, b) => (b.afterPct - b.beforePct).compareTo(a.afterPct - a.beforePct));

    final candidateRisk = newOverlaps.any((o) => o.risk == RiskLevel.high)
        ? RiskLevel.high
        : newOverlaps.any((o) => o.risk == RiskLevel.moderate)
            ? RiskLevel.moderate
            : RiskLevel.low;

    return PreBuyAnalysis(
      before: before,
      after: after,
      newOverlaps: newOverlaps,
      sectorDeltas: sectorDeltas,
      stockDeltas: stockDeltas,
      candidateRisk: candidateRisk,
    );
  }

  // ── Stock Concentration ──────────────────────────────────────────────────

  static List<StockExposure> computeStockExposures(List<FundWithHoldings> funds) {
    final stockMap = <String, _StockAccum>{};

    for (final fund in funds) {
      for (final h in fund.holdings) {
        final name = h.companyName.trim();
        if (name.isEmpty) continue;

        final effective = fund.portfolioWeightPct * h.corpusPct / 100.0;
        final accum = stockMap.putIfAbsent(name, () => _StockAccum(sectorName: h.sectorName));
        accum.effectiveWeight += effective;
        accum.fundNames.add(fund.fundName);
      }
    }

    final result = stockMap.entries.map((e) {
      final risk = e.value.effectiveWeight > OverlapThresholds.stockHigh
          ? RiskLevel.high
          : e.value.effectiveWeight > OverlapThresholds.stockModerate
              ? RiskLevel.moderate
              : RiskLevel.low;
      return StockExposure(
        companyName: e.key,
        sectorName: e.value.sectorName,
        effectiveWeightPct: e.value.effectiveWeight,
        risk: risk,
        heldInFunds: e.value.fundNames.toList(),
      );
    }).toList()
      ..sort((a, b) => b.effectiveWeightPct.compareTo(a.effectiveWeightPct));

    return result.take(20).toList();
  }

  // ── Sector Concentration ─────────────────────────────────────────────────

  static List<SectorExposure> computeSectorExposures(List<FundWithHoldings> funds) {
    final sectorMap = <String, double>{};

    for (final fund in funds) {
      for (final h in fund.holdings) {
        final sector = (h.sectorName ?? 'Other').trim();
        if (sector.isEmpty) continue;

        final effective = fund.portfolioWeightPct * h.corpusPct / 100.0;
        sectorMap[sector] = (sectorMap[sector] ?? 0) + effective;
      }
    }

    final result = sectorMap.entries.map((e) {
      final risk = e.value > OverlapThresholds.sectorHigh
          ? RiskLevel.high
          : e.value > OverlapThresholds.sectorModerate
              ? RiskLevel.moderate
              : RiskLevel.low;
      return SectorExposure(
        sectorName: e.key,
        weightPct: e.value,
        risk: risk,
      );
    }).toList()
      ..sort((a, b) => b.weightPct.compareTo(a.weightPct));

    return result;
  }

  // ── Fund Pair Overlap ────────────────────────────────────────────────────

  static List<FundPairOverlap> computeFundPairOverlaps(List<FundWithHoldings> funds) {
    if (funds.length < 2) return [];

    final pairs = <FundPairOverlap>[];

    for (int i = 0; i < funds.length; i++) {
      for (int j = i + 1; j < funds.length; j++) {
        final a = funds[i];
        final b = funds[j];

        // Build weight maps by company name
        final weightsA = <String, double>{
          for (final h in a.holdings) h.companyName.trim(): h.corpusPct,
        };
        final weightsB = <String, double>{
          for (final h in b.holdings) h.companyName.trim(): h.corpusPct,
        };

        // Overlap = sum of min(weightA, weightB) for common stocks
        double overlap = 0;
        for (final name in weightsA.keys) {
          if (weightsB.containsKey(name)) {
            overlap += (weightsA[name]! < weightsB[name]!)
                ? weightsA[name]!
                : weightsB[name]!;
          }
        }

        final risk = overlap > OverlapThresholds.fundOverlapHigh
            ? RiskLevel.high
            : overlap > OverlapThresholds.fundOverlapModerate
                ? RiskLevel.moderate
                : RiskLevel.low;

        pairs.add(FundPairOverlap(
          fundNameA: a.fundName,
          fundNameB: b.fundName,
          amfiCodeA: a.amfiCode,
          amfiCodeB: b.amfiCode,
          overlapPct: overlap,
          risk: risk,
        ));
      }
    }

    pairs.sort((a, b) => b.overlapPct.compareTo(a.overlapPct));
    return pairs;
  }
}

class _StockAccum {
  final String? sectorName;
  double effectiveWeight = 0;
  final Set<String> fundNames = {};

  _StockAccum({this.sectorName});
}
```

---

### Task 6: Traffic Light Widget + Common Overlap UI Components

**Files:**
- Create: `lib/presentation/widgets/overlap/traffic_light.dart`
- Create: `lib/presentation/widgets/overlap/educational_cards.dart`

- [ ] **Step 1: Create TrafficLight widget**

```dart
// lib/presentation/widgets/overlap/traffic_light.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/overlap_models.dart';

/// Displays a risk indicator: 🟢🟡🔴 with percentage and label.
class TrafficLight extends StatelessWidget {
  const TrafficLight({
    super.key,
    required this.risk,
    required this.valuePct,
    this.label,
    this.compact = false,
  });

  final RiskLevel risk;
  final double valuePct;
  final String? label;
  final bool compact;

  Color get _color => switch (risk) {
    RiskLevel.low => AppColors.gain,
    RiskLevel.moderate => AppColors.warning,
    RiskLevel.high => AppColors.loss,
  };

  String get _emoji => switch (risk) {
    RiskLevel.low => '🟢',
    RiskLevel.moderate => '🟡',
    RiskLevel.high => '🔴',
  };

  String get _label => label ?? switch (risk) {
    RiskLevel.low => 'Low',
    RiskLevel.moderate => 'Moderate',
    RiskLevel.high => 'High',
  };

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '${valuePct.toStringAsFixed(1)}%',
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${valuePct.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: _color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                _label,
                style: TextStyle(
                  color: _color.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Overall portfolio health badge.
class PortfolioHealthBadge extends StatelessWidget {
  const PortfolioHealthBadge({
    super.key,
    required this.risk,
    required this.issueCount,
  });

  final RiskLevel risk;
  final int issueCount;

  @override
  Widget build(BuildContext context) {
    final emoji = switch (risk) {
      RiskLevel.low => '🟢',
      RiskLevel.moderate => '🟡',
      RiskLevel.high => '🔴',
    };
    final label = switch (risk) {
      RiskLevel.low => 'LOW RISK',
      RiskLevel.moderate => 'MODERATE',
      RiskLevel.high => 'HIGH RISK',
    };
    final color = switch (risk) {
      RiskLevel.low => AppColors.gain,
      RiskLevel.moderate => AppColors.warning,
      RiskLevel.high => AppColors.loss,
    };
    final subtitle = issueCount == 0
        ? 'Portfolio is well diversified'
        : '$issueCount issue${issueCount == 1 ? '' : 's'} need${issueCount == 1 ? 's' : ''} attention';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio Health: $label',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Arrow indicator for pre-buy deltas (e.g., 22% → 28%).
class DeltaIndicator extends StatelessWidget {
  const DeltaIndicator({
    super.key,
    required this.beforePct,
    required this.afterPct,
    required this.beforeRisk,
    required this.afterRisk,
  });

  final double beforePct;
  final double afterPct;
  final RiskLevel beforeRisk;
  final RiskLevel afterRisk;

  Color _riskColor(RiskLevel r) => switch (r) {
    RiskLevel.low => AppColors.gain,
    RiskLevel.moderate => AppColors.warning,
    RiskLevel.high => AppColors.loss,
  };

  String _riskEmoji(RiskLevel r) => switch (r) {
    RiskLevel.low => '🟢',
    RiskLevel.moderate => '🟡',
    RiskLevel.high => '🔴',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${beforePct.toStringAsFixed(1)}%',
          style: TextStyle(color: _riskColor(beforeRisk), fontSize: 13),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('→', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        ),
        Text(
          '${afterPct.toStringAsFixed(1)}%',
          style: TextStyle(
            color: _riskColor(afterRisk),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 4),
        Text(_riskEmoji(afterRisk), style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
```

- [ ] **Step 2: Create educational cards**

```dart
// lib/presentation/widgets/overlap/educational_cards.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Collapsible educational card explaining overlap/concentration concepts.
class EducationalCard extends StatelessWidget {
  const EducationalCard({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.school_outlined,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, size: 18, color: AppColors.info),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          Text(
            body,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pre-built educational cards for the overlap screen.
class OverlapEducation extends StatelessWidget {
  const OverlapEducation({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'LEARN',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        EducationalCard(
          title: 'Why does fund overlap matter?',
          body: 'When two or more funds hold the same stocks, your portfolio '
              'is less diversified than it appears. A 10% drop in HDFC Bank '
              'would hit every fund that holds it — if 3 of your funds each '
              'hold 8% HDFC Bank, your effective exposure could be over 10% '
              'of your entire portfolio. True diversification means owning '
              'funds with distinct underlying holdings.',
        ),
        EducationalCard(
          title: 'SEBI\'s 50% overlap rule (2026)',
          icon: Icons.gavel_outlined,
          body: 'In February 2026, SEBI mandated that no two equity mutual fund '
              'schemes from the same AMC can have more than 50% portfolio '
              'overlap. AMCs must disclose overlap monthly and comply within '
              '3 years. As an investor, you should apply the same discipline '
              'across your portfolio — even across different AMCs.',
        ),
        EducationalCard(
          title: 'Stock concentration risk',
          icon: Icons.warning_amber_outlined,
          body: 'SEBI\'s 20/25 rule limits how much a single fund can invest '
              'in one stock. But across YOUR portfolio, the same stock can '
              'appear in many funds. If any single stock exceeds 10% of your '
              'total portfolio value, a company-specific event (earnings miss, '
              'fraud, regulatory action) could disproportionately impact your '
              'wealth. This is hidden concentration risk.',
        ),
      ],
    );
  }
}
```

---

### Task 7: Analytics Screen — Overlap Tab

**Files:**
- Create: `lib/presentation/widgets/overlap/sector_chart.dart`
- Create: `lib/presentation/widgets/overlap/stock_exposure_list.dart`
- Create: `lib/presentation/widgets/overlap/fund_overlap_list.dart`
- Modify: `lib/presentation/screens/analytics/analytics_screen.dart`

- [ ] **Step 1: Create sector chart widget**

Create `lib/presentation/widgets/overlap/sector_chart.dart`:

A widget that displays sector exposures as horizontal bars. Each bar shows:
- Sector name (left)
- Colored bar proportional to weightPct (middle)
- Percentage + traffic light emoji (right)
- Bar color: `AppColors.gain` for low, `AppColors.warning` for moderate, `AppColors.loss` for high

Constructor: `SectorChart({required List<SectorExposure> sectors})`

Use `AppColors.bgCard` for bar track background, 8px bar height, `BorderRadius.circular(4)`.

- [ ] **Step 2: Create stock exposure list widget**

Create `lib/presentation/widgets/overlap/stock_exposure_list.dart`:

A widget that displays top stock exposures. Each item shows:
- Stock name (bold), sector name below in secondary text
- TrafficLight widget (compact) on the right with effective weight %
- "Held in: Fund A, Fund B" below in tertiary text
- Background highlight (`AppColors.loss.withValues(alpha: 0.06)`) if risk is high

Constructor: `StockExposureList({required List<StockExposure> stocks})`

Show max 20 items. Use `ListView.separated` with `Divider`.

- [ ] **Step 3: Create fund overlap list widget**

Create `lib/presentation/widgets/overlap/fund_overlap_list.dart`:

A widget that displays fund pair overlaps. Each item shows:
- "Fund A ↔ Fund B" as title
- TrafficLight widget (compact) on the right with overlap %
- Subtitle: risk description ("Exceeds SEBI 50% limit" for high, "Significant overlap" for moderate, "Distinct portfolios" for low)

Constructor: `FundOverlapList({required List<FundPairOverlap> pairs})`

Use `AppColors.bgCard` container for each pair, 8px spacing between items.

- [ ] **Step 4: Add Overlap tab to Analytics screen**

Modify `lib/presentation/screens/analytics/analytics_screen.dart`:

1. Change `TabController(length: 2` → `TabController(length: 3`
2. Add tab: `Tab(text: 'Overlap')` after 'Risk Metrics'
3. Add `_OverlapTab(memberId: _selectedMemberId)` as third child in `TabBarView`

Add imports at top:
```dart
import '../../providers/overlap_provider.dart';
import '../../widgets/overlap/sector_chart.dart';
import '../../widgets/overlap/stock_exposure_list.dart';
import '../../widgets/overlap/fund_overlap_list.dart';
import '../../widgets/overlap/traffic_light.dart';
import '../../widgets/overlap/educational_cards.dart';
import '../../../domain/usecases/compute_portfolio_overlap.dart';
```

Create `_OverlapTab` as a `ConsumerWidget` within the file:
- Watches `portfolioHoldingsProvider(memberId)`
- When data arrives, calls `PortfolioOverlapCalculator.compute(funds)` to get `OverlapResult`
- Shows:
  1. `PortfolioHealthBadge` at top (overall risk + issue count)
  2. Section "Sector Allocation" → `SectorChart`
  3. Section "Top Stock Exposures" → `StockExposureList`
  4. Section "Fund Overlap" → `FundOverlapList`
  5. `OverlapEducation` at bottom
- Loading state: `CircularProgressIndicator`
- Empty state: "Add mutual fund holdings to see overlap analysis"
- If `portfolioHoldings` returns empty (no cached holdings): show "Fetching fund holdings data..." with progress indicator

---

### Task 8: Fund Detail Screen — Portfolio Fit Section

**Files:**
- Create: `lib/presentation/widgets/overlap/portfolio_fit_section.dart`
- Modify: `lib/presentation/screens/fund_master/fund_detail_screen.dart`

- [ ] **Step 1: Create PortfolioFitSection widget**

Create `lib/presentation/widgets/overlap/portfolio_fit_section.dart`:

A `ConsumerWidget` that takes `int amfiCode`, `String fundName`, `String? memberId`.

Logic:
1. Watch `portfolioSummaryProvider(memberId)` — check if this fund is already held (amfiCode in holdings). If held → return `SizedBox.shrink()` (don't show).
2. Watch `portfolioHoldingsProvider(memberId)` for current portfolio's fund+holdings data.
3. Watch `candidateFundHoldingsProvider(amfiCode, fundName)` for the candidate.
4. If both loaded → call `PortfolioOverlapCalculator.computePreBuy(currentFunds, candidateFund)`.
5. Display:
   - Section header "Portfolio Fit"
   - Overall: `TrafficLight` badge with candidate risk level
   - One-line summary: "This fund has {high/moderate/low} overlap with your portfolio"
   - "Overlap with held funds:" — list of `FundPairOverlap` involving candidate, each with `TrafficLight(compact: true)`
   - "Sector impact:" — list of `SectorDelta` items where `changed` is true, each with `DeltaIndicator`
   - "Stock impact:" — list of top 5 `StockDelta` items, each with `DeltaIndicator`
   - Collapsible "What does this mean?" educational tooltip

Loading state: small `CircularProgressIndicator` with "Analyzing portfolio fit..."
Error state: "Could not load fund holdings" in secondary text

- [ ] **Step 2: Add to Fund Detail screen**

Modify `lib/presentation/screens/fund_master/fund_detail_screen.dart`:

After the `_FundAlertSection` widget (around line 317), add:

```dart
// ── Portfolio Fit ─────────────────────────────────────────────
PortfolioFitSection(
  amfiCode: amfiCode,
  fundName: fundAsync.valueOrNull?.fundName ?? '',
  memberId: _selectedMemberId,
),
```

Add import at top:
```dart
import '../../widgets/overlap/portfolio_fit_section.dart';
```

---

### Task 9: Edge Function — check-portfolio-overlap (Batch Detection)

**Files:**
- Create: `supabase/functions/check-portfolio-overlap/index.ts`

- [ ] **Step 1: Create the Edge Function**

A Supabase Edge Function that runs semi-monthly (1st and 15th):
1. Fetches all users with active MF holdings
2. For each user's held funds: checks `fund_holdings_cache` freshness, calls `fetch-fund-holdings` for stale ones
3. Computes stock concentration, sector concentration, fund pair overlap (same formulas as client-side)
4. Inserts alerts into `alert_log` for breached thresholds
5. Uses monthly dedup: `dedup_key = 'overlap|{check_type}|{owner_id}|{YYYY-MM}'`

**Key logic (TypeScript equivalents of Dart computation):**

Stock effective weight: `Σ (fundWeightPct × holdingCorpusPct / 100)` per company
Sector weight: `Σ (fundWeightPct × holdingCorpusPct / 100)` per sector
Fund pair overlap: `Σ min(weightInA, weightInB)` for common companies

**Alert types:**
- `STOCK_CONCENTRATION` severity `URGENT` — stock > 10%
- `SECTOR_CONCENTRATION` severity `MEDIUM` — sector > 25%
- `FUND_OVERLAP` severity `MEDIUM` — pair > 50%

**Alert templates:**
- Stock: "High stock concentration: {company} is {pct}% of your portfolio (SEBI limit: 10%). Consider diversifying."
- Sector: "Sector concentration: {sector} is {pct}% of your portfolio. Industry recommends below 25%."
- Overlap: "{fundA} and {fundB} have {pct}% portfolio overlap (SEBI ceiling: 50%). These funds hold very similar stocks."

The function should handle rate limiting gracefully — if fetching many funds from Groww, add 500ms delay between fetches. Log progress: "Processing user X of Y".

---

### Task 10: Modify send-alert-email — 3 New Alert Type Mappings

**Files:**
- Modify: `supabase/functions/send-alert-email/index.ts`

- [ ] **Step 1: Read the existing function**

Read the full `supabase/functions/send-alert-email/index.ts`.

- [ ] **Step 2: Add new alert type mappings**

In the `alertTypeToPrefsKey` function (or wherever alert types are mapped to notification_prefs keys), add:

```typescript
case 'STOCK_CONCENTRATION': return 'stock_concentration'
case 'SECTOR_CONCENTRATION': return 'sector_concentration'
case 'FUND_OVERLAP': return 'fund_overlap'
```

Also update the `defaultNotificationPrefs` (or wherever defaults are defined in that file) to include these three keys as `true`.

No other changes needed — the existing email/push logic handles URGENT and MEDIUM severity correctly.

---

### Task 11: pg_cron Schedule for check-portfolio-overlap

**Files:**
- Create: `supabase/migrations/016_overlap_cron.sql`

- [ ] **Step 1: Create cron migration**

```sql
-- 016_overlap_cron.sql
-- Schedule check-portfolio-overlap semi-monthly (1st and 15th)

-- 1st of month at 23:00 IST (17:30 UTC)
SELECT cron.schedule(
  'check-portfolio-overlap-1st',
  '30 17 1 * *',
  $$SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/check-portfolio-overlap',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  )$$
);

-- 15th of month at 23:00 IST (17:30 UTC)
SELECT cron.schedule(
  'check-portfolio-overlap-15th',
  '30 17 15 * *',
  $$SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/check-portfolio-overlap',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  )$$
);
```

- [ ] **Step 2: Verify** — Remind user to apply migrations (015 + 016) via Supabase Dashboard SQL Editor, and deploy Edge Functions via `supabase functions deploy fetch-fund-holdings` and `supabase functions deploy check-portfolio-overlap`.

---

### Task 12: Update notification_prefs_provider defaults

**Files:**
- Modify: `lib/presentation/providers/notification_prefs_provider.dart`

- [ ] **Step 1: Add new default keys**

Read the file. In the `defaultNotificationPrefs` map, add the three new keys:

```dart
'stock_concentration': true,
'sector_concentration': true,
'fund_overlap': true,
```

Add them after the existing `'price_target': true,` line.

---

### Task 13: Build + Deploy

- [ ] **Step 1: Run codegen** (if not already up to date)

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 2: Build**

Run: `export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && flutter build web`

Fix any compilation errors.

- [ ] **Step 3: Deploy**

Run: `export PATH="/usr/local/bin:/Users/nisanth/.npm-global/bin:/opt/homebrew/bin:$PATH" && netlify deploy --prod --dir=build/web`

- [ ] **Step 4: Post-deploy checklist**

Remind user:
1. Apply `015_fund_holdings_cache.sql` in Supabase Dashboard SQL Editor
2. Apply `016_overlap_cron.sql` in Supabase Dashboard SQL Editor
3. Deploy Edge Functions:
   - `supabase functions deploy fetch-fund-holdings`
   - `supabase functions deploy check-portfolio-overlap`
4. Test overlap analysis:
   - Navigate to Analytics → Overlap tab
   - Verify fund holdings are fetched from Groww
   - Check sector/stock/fund pair analysis displays correctly
5. Test pre-buy:
   - Navigate to a fund you don't hold in Portfolio → Fund Detail
   - Verify "Portfolio Fit" section appears with overlap analysis
6. Pending from earlier slices:
   - Apply `012_frozen_plans.sql` migration
   - Apply `013_watchlist_rules.sql` migration
   - Apply `014_watchlist_cron.sql` migration
