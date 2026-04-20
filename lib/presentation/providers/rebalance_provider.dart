import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/asset_classes.dart';
import '../../data/models/family_model.dart';
import '../../domain/models/allocation_models.dart';
import '../../domain/models/simulation_models.dart';
import '../../domain/usecases/run_rebalance_analysis.dart';
import 'family_provider.dart';
import 'portfolio_provider.dart';
import 'simulation_provider.dart';
import 'wealth_planner_provider.dart';

part 'rebalance_provider.g.dart';

/// Rebalance analysis keyed by [memberId] (null = family/all view).
///
/// Target priority (highest → lowest):
///   1. Live `simulationStateProvider(memberId).targetAllocations` — slider
///      currently held by the user wins.
///   2. `activeFrozenPlanProvider(memberId).assetClassTargets` — last frozen
///      per-asset-class target snapshot.
///   3. `allocationHealthProvider(memberId).idealAllocation` — risk-derived
///      defaults (same source the Asset slider tab seeds from on first open).
///      This is what the user sees on the Asset tab when they haven't touched
///      anything; rebalance must agree.
///   4. `family.target*` static defaults — last-resort fallback only.
@riverpod
Future<RebalanceResult> rebalanceAnalysis(
  RebalanceAnalysisRef ref,
  String? memberId,
) async {
  final portfolio = await ref.watch(portfolioSummaryProvider(memberId).future);
  final family = await ref.watch(familyProvider.future);
  final simState = ref.watch(simulationStateProvider(memberId));
  final frozen = await ref.watch(activeFrozenPlanProvider(memberId).future);
  final health = await ref.watch(allocationHealthProvider(memberId).future);

  final holdings = portfolio.fundHoldings.map((f) {
    final ac = _labelToAssetClass(f.assetClassLabel ?? f.taxCategory ?? '');
    return PortfolioHolding(
      amfiCode: f.amfiCode,
      fundName: f.fundName,
      assetClass: ac,
      currentValue: f.currentValue,
    );
  }).toList();

  final target = _buildTarget(simState, frozen, health.idealAllocation, family);
  return RebalanceAnalyzer.analyze(holdings: holdings, target: target);
}

AllocationTarget _buildTarget(
  SimulationState simState,
  FrozenPlan? frozen,
  IdealAllocation ideal,
  FamilyModel? family,
) {
  final drift = family?.rebalanceDriftThreshold ?? 5.0;

  // 1. Live sim-state wins — the slider you're holding right now.
  if (simState.targetAllocations.isNotEmpty) {
    return _fromMap(simState.targetAllocations, drift);
  }
  // 2. Frozen plan's per-asset-class targets — persisted across reloads.
  final frozenMap = frozen?.assetClassTargets;
  if (frozenMap != null && frozenMap.isNotEmpty) {
    return _fromMap(frozenMap, drift);
  }
  // 3. Risk-derived ideal allocation — matches what the Asset tab seeds.
  //    (Note: idealAllocation uses 'alternatives' key; we map it back to
  //    'alternate' to match AllocationTarget.alternatePct.)
  return AllocationTarget(
    coreEquityPct: ideal.idealForAssetClass('coreEquity'),
    satelliteEquityPct: ideal.idealForAssetClass('satelliteEquity'),
    hybridPct: ideal.idealForAssetClass('hybrid'),
    debtPct: ideal.idealForAssetClass('debt'),
    liquidPct: ideal.idealForAssetClass('liquid'),
    goldPct: ideal.idealForAssetClass('gold'),
    alternatePct: ideal.idealForAssetClass('alternatives'),
    driftThreshold: drift,
  );
}

AllocationTarget _fromMap(Map<String, double> m, double drift) =>
    AllocationTarget(
      coreEquityPct: m['coreEquity'] ?? 0,
      satelliteEquityPct: m['satelliteEquity'] ?? 0,
      hybridPct: m['hybrid'] ?? 0,
      debtPct: m['debt'] ?? 0,
      liquidPct: m['liquid'] ?? 0,
      goldPct: m['gold'] ?? 0,
      alternatePct: m['alternate'] ?? 0,
      driftThreshold: drift,
    );

AssetClass _labelToAssetClass(String label) {
  final l = label.toLowerCase();
  if (l.contains('core equity') || l.contains('equity')) {
    return AssetClass.coreEquity;
  }
  if (l.contains('satellite')) return AssetClass.satelliteEquity;
  if (l.contains('hybrid')) return AssetClass.hybrid;
  if (l.contains('debt')) return AssetClass.debt;
  if (l.contains('liquid')) return AssetClass.liquid;
  if (l.contains('gold')) return AssetClass.gold;
  return AssetClass.alternate;
}
