import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/action_models.dart';
import '../../domain/models/retirement_models.dart';
import '../../domain/usecases/compute_rebalance_actions.dart';
import '../../domain/usecases/compute_unified_actions.dart';
import 'family_provider.dart';
import 'portfolio_provider.dart';
import 'rebalance_provider.dart';
import 'retirement_provider.dart';
import 'simulation_provider.dart';
import 'wealth_planner_provider.dart';

part 'action_center_provider.g.dart';

/// Maps display-name allocation keys → asset class keys.
const _displayToAssetClassKey = <String, String>{
  'Core Equity': 'coreEquity',
  'Satellite Equity': 'satelliteEquity',
  'Hybrid': 'hybrid',
  'Debt': 'debt',
  'Liquid': 'liquid',
  'Gold': 'gold',
  'Alternate': 'alternate',
};

@riverpod
Future<RebalancePlan> actionCenterPlan(ActionCenterPlanRef ref, String? memberId) async {
  final portfolio = await ref.watch(portfolioSummaryProvider(memberId).future);
  final health = await ref.watch(allocationHealthProvider(memberId).future);
  final rebalance = await ref.watch(rebalanceAnalysisProvider(memberId).future);

  final members = await ref.watch(familyMembersProvider.future);
  final member = memberId != null
      ? members.where((m) => m.id == memberId).firstOrNull
      : members.where((m) => m.relationship == 'Self').firstOrNull;
  final monthlyExpense = member?.monthlyExpense ?? 50000;

  final bucketStrategy = await ref.watch(memberBucketStrategyProvider(memberId).future);

  // Retirement readiness (nullable — may not be configured)
  RetirementReadiness? retirementReadiness;
  try {
    retirementReadiness = await ref.watch(retirementReadinessProvider(memberId).future);
  } catch (_) {
    retirementReadiness = null;
  }

  // Build FundHoldingInput list from portfolio
  final holdings = portfolio.fundHoldings.map((f) {
    final acLabel = f.assetClassLabel ?? f.taxCategory ?? 'Alternate';
    final acKey = _displayToAssetClassKey[acLabel] ?? 'alternate';
    return FundHoldingInput(
      amfiCode: f.amfiCode,
      fundName: f.fundName,
      assetClassKey: acKey,
      currentValue: f.currentValue,
      return3y: f.xirr,
      expenseRatio: f.expenseRatio,
    );
  }).toList();

  // Build current allocation map (display name → asset class key)
  final currentAllocation = <String, double>{};
  for (final entry in portfolio.allocationPct.entries) {
    final key = _displayToAssetClassKey[entry.key];
    if (key != null) {
      currentAllocation[key] = (currentAllocation[key] ?? 0) + entry.value;
    }
  }

  // Layer 1: Fund-to-fund moves
  final fundMoves = RebalanceActionsCalculator.compute(
    rebalanceResult: rebalance,
    holdings: holdings,
    healthResult: health,
    driftThreshold: rebalance.driftThreshold,
    monthlyExpense: monthlyExpense,
  );

  // Layer 2: Unified actions
  final plan = UnifiedActionsCalculator.compute(
    fundMoves: fundMoves,
    healthResult: health,
    retirementGap: retirementReadiness?.gapAnalysis,
    currentAllocation: currentAllocation,
    totalPortfolioValue: portfolio.currentValue,
    bucketStrategy: bucketStrategy,
  );

  return plan;
}
