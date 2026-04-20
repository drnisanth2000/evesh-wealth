import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/overlap_models.dart';
import 'auth_provider.dart';
import 'portfolio_provider.dart';

part 'overlap_provider.g.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TASK 4: Portfolio Overlap Analysis — Fund Holdings Cache & Fetching
//
// This provider file implements the core data layers for overlap detection:
// 1. fundHoldingsCacheProvider — fetch cached holdings from fund_holdings_cache
// 2. isHoldingsCacheStaleProvider — check if cache is >30 days old
// 3. portfolioHoldingsProvider — fetch holdings for ALL held funds
// 4. candidateFundHoldingsProvider — fetch holdings for a single candidate fund
// ═════════════════════════════════════════════════════════════════════════════

// ─── HELPER: Convert snake_case DB rows to camelCase for Freezed ─────────────
Map<String, dynamic> _snakeToCamelMap(Map<String, dynamic> row) {
  final camel = <String, dynamic>{};
  for (final entry in row.entries) {
    final key = entry.key;
    final value = entry.value;
    // Convert snake_case to camelCase
    final camelKey = key.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (m) => m.group(1)!.toUpperCase(),
    );
    camel[camelKey] = value;
  }
  return camel;
}

// ─── PROVIDER 1: Fund holdings cache (fetch cached holdings from DB) ────────
// Signature: fundHoldingsCacheProvider(int amfiCode) → Future<List<CachedFundHolding>>
// Returns the last cached snapshot of fund holdings from fund_holdings_cache table.
// Used to minimize Edge Function calls and provide fast access to common funds.
@riverpod
Future<List<CachedFundHolding>> fundHoldingsCache(
  FundHoldingsCacheRef ref,
  int amfiCode,
) async {
  final client = ref.watch(supabaseClientProvider);

  // Each row in fund_holdings_cache is one holding (company) for a fund.
  // Fetch all rows for this amfi_code.
  final response = await client
      .from('fund_holdings_cache')
      .select()
      .eq('amfi_code', amfiCode)
      .order('corpus_pct', ascending: false);

  final responseList = response as List;
  if (responseList.isEmpty) {
    return [];
  }

  return responseList
      .map((row) => CachedFundHolding.fromJson(
            _snakeToCamelMap(row as Map<String, dynamic>),
          ))
      .toList();
}

// ─── PROVIDER 2: Check if holdings cache is stale (>30 days old) ────────────
// Signature: isHoldingsCacheStaleProvider(int amfiCode) → Future<bool>
// Returns true if the last cached entry is older than 30 days.
// Used to decide whether to trigger an Edge Function refresh.
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
      .order('fetched_at', ascending: false)
      .limit(1);

  final responseList = response as List;
  if (responseList.isEmpty) {
    return true; // no cache entry → stale
  }

  final cached = responseList.first as Map<String, dynamic>;
  final fetchedAtStr = cached['fetched_at'] as String?;

  if (fetchedAtStr == null) {
    return true;
  }

  final fetchedAt = DateTime.tryParse(fetchedAtStr);
  if (fetchedAt == null) {
    return true;
  }

  final daysSinceFetch = DateTime.now().difference(fetchedAt).inDays;
  return daysSinceFetch > 30;
}

// ─── PROVIDER 3: Portfolio holdings (fetch ALL held funds' holdings) ────────
// Signature: portfolioHoldingsProvider(String? memberId) → Future<List<FundWithHoldings>>
// Fetches the complete list of holdings for all funds currently held in the portfolio.
// - If memberId is null, aggregates holdings across all family members.
// - If a fund's cache is stale (>30 days old), triggers Edge Function refresh.
// - Returns list of FundWithHoldings (fund info + holdings + portfolio weight).
@riverpod
Future<List<FundWithHoldings>> portfolioHoldings(
  PortfolioHoldingsRef ref,
  String? memberId,
) async {
  final client = ref.watch(supabaseClientProvider);

  // 1. Fetch the portfolio summary to get current holdings
  final summary = await ref.watch(portfolioSummaryProvider(memberId).future);

  if (summary.fundHoldings.isEmpty) {
    return [];
  }

  // 2. Filter to equity-relevant MF holdings only.
  //    Liquid & Gold funds have no stock holdings on Groww — exclude them.
  //    NOTE: Many equity funds have NULL tax_category in fund_master and
  //    default to 'Debt' in portfolio_provider, so we can't exclude 'Debt'
  //    here. We use assetClassLabel which is more reliably mapped.
  const skipAssetClasses = {'Liquid', 'Gold'};
  final mfHoldings = summary.fundHoldings.where((h) {
    if (h.amfiCode == 0) return false;
    return !skipAssetClasses.contains(h.assetClassLabel);
  }).toList();
  final totalMfValue = mfHoldings.fold(0.0, (sum, h) => sum + h.currentValue);

  // 3. Check staleness for all funds FIRST, then batch-refresh stale ones.
  //    IMPORTANT: We avoid calling ref.invalidate inside a loop which can
  //    trigger provider rebuild and cause the loop to restart endlessly.
  final staleAmfiCodes = <int>[];
  for (final holding in mfHoldings) {
    final isCacheStale = await ref.watch(
      isHoldingsCacheStaleProvider(holding.amfiCode).future,
    );
    if (isCacheStale) {
      staleAmfiCodes.add(holding.amfiCode);
    }
  }

  // 4. Batch-refresh all stale funds in a single Edge Function call
  if (staleAmfiCodes.isNotEmpty) {
    try {
      debugPrint('Batch-refreshing ${staleAmfiCodes.length} stale funds: $staleAmfiCodes');
      final fnResponse = await client.functions.invoke(
        'fetch-fund-holdings',
        body: {'amfi_codes': staleAmfiCodes},
      );
      debugPrint('fetch-fund-holdings batch: status=${fnResponse.status}');
      // Invalidate all cache providers for refreshed funds
      for (final amfiCode in staleAmfiCodes) {
        ref.invalidate(fundHoldingsCacheProvider(amfiCode));
      }
    } catch (e) {
      debugPrint('Batch Edge Function refresh failed: $e');
    }
  }

  // 5. Now fetch holdings from cache for ALL equity funds
  final fundsList = <FundWithHoldings>[];
  for (final holding in mfHoldings) {
    final holdings = await ref.watch(
      fundHoldingsCacheProvider(holding.amfiCode).future,
    );

    final portfolioWeight = totalMfValue > 0
        ? (holding.currentValue / totalMfValue) * 100
        : 0.0;

    fundsList.add(FundWithHoldings(
      amfiCode: holding.amfiCode,
      fundName: holding.fundName,
      portfolioWeightPct: portfolioWeight,
      holdings: holdings,
    ));
  }

  return fundsList;
}

// ─── PROVIDER 4: Candidate fund holdings (for pre-buy analysis) ──────────────
// Signature: candidateFundHoldingsProvider(int amfiCode, String fundName) → Future<FundWithHoldings?>
// Fetches holdings for a single fund (not yet in portfolio, for "what-if" analysis).
// - Triggers Edge Function refresh if cache is stale.
// - Returns a single FundWithHoldings with weight = 0 (candidate not yet held).
// - Returns null if fund not found or holdings fetch fails.
@riverpod
Future<FundWithHoldings?> candidateFundHoldings(
  CandidateFundHoldingsRef ref,
  int amfiCode,
  String fundName,
) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    // 1. Check if cache is stale; if so, trigger Edge Function refresh
    final isCacheStale = await ref.watch(
      isHoldingsCacheStaleProvider(amfiCode).future,
    );

    if (isCacheStale) {
      try {
        // Invoke Edge Function to refresh holdings cache
        await client.functions.invoke(
          'fetch-fund-holdings',
          body: {'amfi_code': amfiCode, 'fund_name': fundName},
        );
        // Invalidate the cache provider so it re-fetches from DB
        ref.invalidate(fundHoldingsCacheProvider(amfiCode));
      } catch (e) {
        // Log but continue — use stale cache if refresh fails
        debugPrint('Edge Function refresh failed for amfi_code=$amfiCode: $e');
      }
    }

    // 2. Fetch holdings from cache
    final holdings = await ref.watch(
      fundHoldingsCacheProvider(amfiCode).future,
    );

    // 3. Return FundWithHoldings with weight=0 (not yet held)
    return FundWithHoldings(
      amfiCode: amfiCode,
      fundName: fundName,
      portfolioWeightPct: 0.0, // candidate not yet held
      holdings: holdings,
    );
  } catch (e) {
    debugPrint('Error fetching candidate fund holdings for amfi_code=$amfiCode: $e');
    return null;
  }
}
