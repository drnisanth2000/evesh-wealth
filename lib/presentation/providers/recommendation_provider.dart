// lib/presentation/providers/recommendation_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/recommendation_models.dart';
import '../../domain/usecases/recommend_funds.dart';
import 'auth_provider.dart';
import 'portfolio_provider.dart';
import 'suggestion_provider.dart';
import 'wealth_planner_provider.dart';

part 'recommendation_provider.g.dart';

/// Maps portfolio allocationPct display-name keys → asset class keys.
const _displayToAssetClassKey = <String, String>{
  'Core Equity': 'coreEquity',
  'Satellite Equity': 'satelliteEquity',
  'Hybrid': 'hybrid',
  'Debt': 'debt',
  'Liquid': 'liquid',
  'Gold': 'gold',
  'Alternate': 'alternatives',
};

@riverpod
Future<RecommendationResult> fundRecommendations(
    FundRecommendationsRef ref) async {
  final surplus = ref.watch(surplusAmountNotifierProvider);
  final portfolio = await ref.watch(portfolioSummaryProvider(null).future);
  final health = await ref.watch(allocationHealthProvider(null).future);
  final client = ref.watch(supabaseClientProvider);

  // Fetch Direct plan active funds with essential fields
  final fundResponse = await client
      .from('fund_master')
      .select(
          'amfi_code, fund_name, category, sub_category, tax_category, '
          'amc, plan_type, return_1y, return_3y, return_5y, expense_ratio, '
          'volatility_1y, aum_cr, crisil_rating, fund_rating, launch_date')
      .eq('is_active', true)
      .eq('plan_type', 'Direct')
      .order('return_3y', ascending: false, nullsFirst: false)
      .limit(500);

  final funds = (fundResponse as List)
      .map((r) => r as Map<String, dynamic>)
      .toList();

  // Build current allocation from portfolio (display name → asset class key)
  final currentAllocation = <String, double>{};
  for (final entry in portfolio.allocationPct.entries) {
    final key = _displayToAssetClassKey[entry.key];
    if (key != null) {
      currentAllocation[key] = (currentAllocation[key] ?? 0) + entry.value;
    }
  }

  // Build ideal allocation from health result
  final idealAllocation = <String, double>{};
  for (final bucket in health.idealAllocation.subBuckets) {
    idealAllocation[bucket.parentBucket] =
        (idealAllocation[bucket.parentBucket] ?? 0) + bucket.idealPct;
  }

  // Collect held fund AMFI codes and details for overlap detection
  final heldAmfiCodes = portfolio.fundHoldings
      .map((h) => h.amfiCode)
      .toSet();

  final heldFundDetails = portfolio.fundHoldings
      .map((h) => <String, dynamic>{
            'amfi_code': h.amfiCode,
            'amc': null, // We don't have AMC on FundHoldingSummary
            'category': h.category,
          })
      .toList();

  // SIP recommendation: conservative heuristic based on allocation health
  // If portfolio is well-balanced (health ≥ 70), lumpsum ok; otherwise SIP
  final sipRecommended = health.healthScore < 70;

  return RecommendationEngine.recommend(
    funds: funds,
    surplusAmount: surplus,
    currentAllocation: currentAllocation,
    idealAllocation: idealAllocation,
    heldAmfiCodes: heldAmfiCodes,
    sipRecommended: sipRecommended,
    heldFundDetails: heldFundDetails,
  );
}
