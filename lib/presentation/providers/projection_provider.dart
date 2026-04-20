// lib/presentation/providers/projection_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/projection_models.dart';
import '../../domain/usecases/compute_portfolio_projection.dart';
import '../../domain/usecases/compute_stress_test.dart';
import '../../domain/usecases/compute_behavior_impact.dart';
import 'family_provider.dart';
import 'portfolio_provider.dart';
import 'wealth_planner_provider.dart';

part 'projection_provider.g.dart';

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

/// Maps risk profile → expected annual return %.
const _riskProfileReturn = <String, double>{
  'Conservative': 9.0,
  'Moderately Conservative': 10.0,
  'Moderate': 11.0,
  'Moderately Aggressive': 12.0,
  'Aggressive': 13.0,
};

@riverpod
class ProjectionHorizonNotifier extends _$ProjectionHorizonNotifier {
  @override
  int build() => 10; // default 10 years
  void set(int v) => state = v;
}

@riverpod
class ProjectionSipNotifier extends _$ProjectionSipNotifier {
  @override
  double build() => 0; // will be initialised from member data
  void set(double v) => state = v;
}

@riverpod
Future<ProjectionResult> projectionResult(ProjectionResultRef ref, String? memberId) async {
  final horizonYears = ref.watch(projectionHorizonNotifierProvider);
  final sipOverride = ref.watch(projectionSipNotifierProvider);
  final portfolio = await ref.watch(portfolioSummaryProvider(memberId).future);
  // Watch allocation health so the projection refreshes when it changes.
  await ref.watch(allocationHealthProvider(memberId).future);
  final members = await ref.watch(familyMembersProvider.future);
  final self = memberId != null
      ? members.where((m) => m.id == memberId).firstOrNull
      : members.where((m) => m.relationship == 'Self').firstOrNull;

  // Resolve expected return from risk profile
  final riskProfile = self?.riskProfile ?? 'Moderate';
  final expectedReturn = _riskProfileReturn[riskProfile] ?? 11.0;

  // Resolve monthly SIP: use override if set, else member's investable surplus
  double monthlySip = sipOverride;
  if (monthlySip <= 0 && self != null) {
    final income = self.monthlyIncome ?? 0;
    final expense = self.monthlyExpense ?? 0;
    monthlySip = (income - expense).clamp(0, double.infinity);
  }

  // Build current allocation (display name → asset class key)
  final allocationPct = <String, double>{};
  for (final entry in portfolio.allocationPct.entries) {
    final key = _displayToAssetClassKey[entry.key];
    if (key != null) {
      allocationPct[key] = (allocationPct[key] ?? 0) + entry.value;
    }
  }

  final taxSlabPct = self?.taxSlabPct ?? 30.0;

  final input = ProjectionInput(
    currentPortfolioValue: portfolio.currentValue,
    monthlySip: monthlySip,
    horizonYears: horizonYears,
    expectedReturn: expectedReturn,
    allocationPct: allocationPct,
    taxSlabPct: taxSlabPct,
  );

  // Compute all three engines
  final projectionResult = PortfolioProjectionCalculator.compute(input);
  final stressTests = StressTestCalculator.compute(
    portfolioValue: portfolio.currentValue,
    allocationPct: allocationPct,
  );
  final behaviorScenarios = BehaviorImpactCalculator.compute(
    currentValue: portfolio.currentValue,
    monthlySip: monthlySip,
    horizonYears: horizonYears,
    expectedReturn: expectedReturn,
  );

  return ProjectionResult(
    input: input,
    scenarios: projectionResult.scenarios,
    waterfall: projectionResult.waterfall,
    benchmarks: projectionResult.benchmarks,
    stressTests: stressTests,
    behaviorScenarios: behaviorScenarios,
  );
}
