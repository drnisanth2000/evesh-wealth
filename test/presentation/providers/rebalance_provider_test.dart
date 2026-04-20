import 'package:evesh_wealth/data/models/family_model.dart';
import 'package:evesh_wealth/data/models/portfolio_summary_model.dart';
import 'package:evesh_wealth/domain/models/allocation_models.dart';
import 'package:evesh_wealth/domain/models/simulation_models.dart';
import 'package:evesh_wealth/domain/usecases/run_rebalance_analysis.dart';
import 'package:evesh_wealth/presentation/providers/family_provider.dart';
import 'package:evesh_wealth/presentation/providers/portfolio_provider.dart';
import 'package:evesh_wealth/presentation/providers/rebalance_provider.dart';
import 'package:evesh_wealth/presentation/providers/simulation_provider.dart';
import 'package:evesh_wealth/presentation/providers/wealth_planner_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AllocationHealthResult _stubHealth({
  Map<String, double> ideal = const {
    'coreEquity': 40,
    'satelliteEquity': 10,
    'hybrid': 10,
    'debt': 20,
    'liquid': 5,
    'gold': 5,
    'alternatives': 10,
  },
}) {
  final subBuckets = ideal.entries
      .map((e) => SubBucketTarget(
            name: e.key,
            parentBucket: e.key,
            minPct: e.value,
            maxPct: e.value,
            idealPct: e.value,
          ))
      .toList();
  return AllocationHealthResult(
    healthScore: 100,
    healthLabel: 'Excellent',
    idealAllocation: IdealAllocation(
      riskProfile: 'Moderate',
      age: 35,
      corePct: 40,
      satellitePct: 10,
      subBuckets: subBuckets,
    ),
    currentAllocation: const {},
    driftAlerts: const [],
    nudges: const [],
  );
}

// ── Fakes ──────────────────────────────────────────────────────────────────

FamilyModel _defaultFamily() => const FamilyModel(
      id: 'fam-1',
      ownerId: 'owner-1',
      // Defaults that should NOT appear when sim/frozen take precedence.
      targetCoreEquity: 40,
      targetSatelliteEquity: 10,
      targetHybrid: 10,
      targetDebt: 20,
      targetLiquid: 5,
      targetGold: 5,
      targetAlternate: 10,
      rebalanceDriftThreshold: 5,
    );

FundHoldingSummary _fund({
  required int amfiCode,
  required String name,
  required String label,
  required double value,
}) =>
    FundHoldingSummary(
      amfiCode: amfiCode,
      fundName: name,
      assetClassLabel: label,
      currentValue: value,
      totalInvested: value,
    );

PortfolioSummary _portfolio(List<FundHoldingSummary> holdings) {
  final total = holdings.fold<double>(0.0, (s, h) => s + h.currentValue);
  return PortfolioSummary(
    currentValue: total,
    totalInvested: total,
    fundHoldings: holdings,
  );
}

ProviderContainer _container({
  required Map<String, double> simTargets,
  required FrozenPlan? frozen,
  required FamilyModel? family,
  required PortfolioSummary portfolio,
  AllocationHealthResult? health,
}) {
  final c = ProviderContainer(overrides: [
    portfolioSummaryProvider(null).overrideWith((ref) async => portfolio),
    familyProvider.overrideWith((ref) async => family),
    activeFrozenPlanProvider(null).overrideWith((ref) async => frozen),
    allocationHealthProvider(null)
        .overrideWith((ref) async => health ?? _stubHealth()),
  ]);
  // Seed the real SimulationStateNotifier via its public mutator. Empty map
  // keeps `targetAllocations` empty so the priority chain falls through.
  if (simTargets.isNotEmpty) {
    final notifier = c.read(simulationStateProvider(null).notifier);
    simTargets.forEach(notifier.setTargetAllocation);
  }
  return c;
}

void main() {
  group('rebalanceAnalysisProvider — target priority', () {
    test('1. live sim-state targets win over frozen + family', () async {
      final container = _container(
        simTargets: const {
          'coreEquity': 100,
          'satelliteEquity': 0,
          'hybrid': 0,
          'debt': 0,
          'liquid': 0,
          'gold': 0,
          'alternate': 0,
        },
        frozen: FrozenPlan(
          ownerId: 'owner-1',
          fundAllocations: const {},
          additionalLumpsum: 0,
          additionalSip: 0,
          assetClassTargets: const {'hybrid': 30},
          status: 'active',
        ),
        family: _defaultFamily(),
        portfolio: _portfolio([
          _fund(amfiCode: 1, name: 'Equity', label: 'Core Equity', value: 100000),
        ]),
      );
      addTearDown(container.dispose);

      final result =
          await container.read(rebalanceAnalysisProvider(null).future);
      final hybridDrift = result.allocationDrifts
          .firstWhere((d) => d.assetClass.name == 'hybrid');
      // Sim-state hybrid = 0 → target should be 0, NOT 30 (frozen) or 10 (family).
      expect(hybridDrift.targetPct, 0.0);
    });

    test('2. frozen wins when sim-state.targetAllocations is empty', () async {
      final container = _container(
        simTargets: const {},
        frozen: FrozenPlan(
          ownerId: 'owner-1',
          fundAllocations: const {},
          additionalLumpsum: 0,
          additionalSip: 0,
          assetClassTargets: const {
            'coreEquity': 50,
            'hybrid': 25,
            'debt': 25,
          },
          status: 'active',
        ),
        family: _defaultFamily(),
        portfolio: _portfolio([
          _fund(amfiCode: 1, name: 'Eq', label: 'Core Equity', value: 100000),
        ]),
      );
      addTearDown(container.dispose);

      final result =
          await container.read(rebalanceAnalysisProvider(null).future);
      final hybridDrift = result.allocationDrifts
          .firstWhere((d) => d.assetClass.name == 'hybrid');
      // Frozen hybrid = 25, NOT family's 10.
      expect(hybridDrift.targetPct, 25.0);
    });

    test('3. ideal-allocation fallback when both sim-state and frozen are absent',
        () async {
      final container = _container(
        simTargets: const {},
        frozen: null,
        family: _defaultFamily(),
        portfolio: _portfolio([
          _fund(amfiCode: 1, name: 'Eq', label: 'Core Equity', value: 100000),
        ]),
        // Risk-derived ideal puts coreEquity at 55 (vs family default 40).
        health: _stubHealth(ideal: const {
          'coreEquity': 55,
          'satelliteEquity': 10,
          'hybrid': 10,
          'debt': 15,
          'liquid': 5,
          'gold': 5,
          'alternatives': 0,
        }),
      );
      addTearDown(container.dispose);

      final result =
          await container.read(rebalanceAnalysisProvider(null).future);
      final coreDrift = result.allocationDrifts
          .firstWhere((d) => d.assetClass.name == 'coreEquity');
      // Ideal wins, NOT the family default of 40.
      expect(coreDrift.targetPct, 55.0);
    });
  });

  group('rebalanceAnalysisProvider — bug regression', () {
    test('Hybrid sim target = 0 with held Hybrid fund → action is REDUCE',
        () async {
      // Portfolio: ₹36L Equity + ₹1.9L Hybrid (≈5% hybrid).
      // Sim targets: Hybrid 0%, Equity 60%, Debt 30%, Liquid 10%.
      // Expectation: hybrid is overweight (5% vs 0%) → suggest Reduce, not Add.
      final container = _container(
        simTargets: const {
          'coreEquity': 60,
          'satelliteEquity': 0,
          'hybrid': 0,
          'debt': 30,
          'liquid': 10,
          'gold': 0,
          'alternate': 0,
        },
        frozen: null,
        family: _defaultFamily(),
        portfolio: _portfolio([
          _fund(amfiCode: 100, name: 'Equity', label: 'Core Equity', value: 3600000),
          _fund(amfiCode: 200, name: 'Hybrid Fund', label: 'Hybrid', value: 190000),
        ]),
      );
      addTearDown(container.dispose);

      final result =
          await container.read(rebalanceAnalysisProvider(null).future);
      final hybridSuggestion = result.topFundSuggestions
          .firstWhere((s) => s.amfiCode == 200);
      expect(hybridSuggestion.suggestedAction, RebalanceAction.reduce);
    });

    test('Alternate sim target = 0 with held Alternate fund → REDUCE',
        () async {
      final container = _container(
        simTargets: const {
          'coreEquity': 70,
          'satelliteEquity': 0,
          'hybrid': 0,
          'debt': 20,
          'liquid': 10,
          'gold': 0,
          'alternate': 0,
        },
        frozen: null,
        family: _defaultFamily(),
        portfolio: _portfolio([
          _fund(amfiCode: 100, name: 'Equity', label: 'Core Equity', value: 3600000),
          _fund(amfiCode: 300, name: 'REIT', label: 'Alternate', value: 190000),
        ]),
      );
      addTearDown(container.dispose);

      final result =
          await container.read(rebalanceAnalysisProvider(null).future);
      final altSuggestion = result.topFundSuggestions
          .firstWhere((s) => s.amfiCode == 300);
      expect(altSuggestion.suggestedAction, RebalanceAction.reduce);
    });
  });
}
