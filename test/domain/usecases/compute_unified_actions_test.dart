import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/domain/models/action_models.dart';
import 'package:evesh_wealth/domain/models/allocation_models.dart';
import 'package:evesh_wealth/domain/models/retirement_models.dart';
import 'package:evesh_wealth/domain/models/simulation_models.dart';
import 'package:evesh_wealth/domain/usecases/compute_unified_actions.dart';

final _testBucketStrategy = BucketStrategy(
  scenario: 'accumulation',
  bucketTargets: {1: 25.0, 2: 15.0, 3: 60.0},
  bucketNames: {1: 'Liquidity (0-2yr)', 2: 'Stability (3-7yr)', 3: 'Growth (7yr+)'},
  bucketInstruments: {1: ['Liquid funds'], 2: ['Debt funds'], 3: ['Equity']},
  corePct: 75.0,
  satellitePct: 25.0,
  educationNotes: ['Test note'],
  refillRules: [],
);

void main() {
  final baseHealth = AllocationHealthResult(
    healthScore: 60,
    healthLabel: 'Needs Attention',
    idealAllocation: IdealAllocation(
      riskProfile: 'Moderate', age: 35, corePct: 50, satellitePct: 50,
      subBuckets: [],
    ),
    currentAllocation: {'coreEquity': 60, 'debt': 20, 'liquid': 10, 'gold': 10},
    driftAlerts: [
      DriftAlert(
        assetClass: 'Core Equity', assetClassKey: 'coreEquity',
        currentPct: 60, idealPct: 50, driftPct: 10,
        severity: 'warning', message: 'Overexposed to Core Equity by 10%',
      ),
    ],
    nudges: [],
  );

  final baseAllocation = {
    'coreEquity': 60.0, 'satelliteEquity': 0.0,
    'hybrid': 0.0, 'debt': 20.0, 'liquid': 10.0, 'gold': 10.0, 'alternate': 0.0,
  };

  group('Unified Actions', () {
    test('converts shift moves into rebalance action items', () {
      final moves = [
        FundMove(
          sourceAmfiCode: 101, sourceFundName: 'Fund A', sourceAssetClass: 'coreEquity',
          destAmfiCode: 201, destFundName: 'Fund B', destAssetClass: 'debt',
          amount: 50000, moveType: MoveType.shift,
          rationale: 'Core Equity overweight',
        ),
      ];

      final plan = UnifiedActionsCalculator.compute(
        fundMoves: moves,
        healthResult: baseHealth,
        retirementGap: null,
        currentAllocation: baseAllocation,
        totalPortfolioValue: 1000000,
        bucketStrategy: _testBucketStrategy,
      );

      final rebalanceItems = plan.actionItems
          .where((a) => a.source == ActionSource.rebalance)
          .toList();
      expect(rebalanceItems, isNotEmpty);
      expect(rebalanceItems.first.actionType, ActionType.sell);
    });

    test('adds retirement gap action when gap exists', () {
      final gap = RetirementGap(
        corpus: RetirementCorpus(
          monthlyExpenseAtRetirement: 100000, annualRetirementExpenses: 1200000,
          totalMonthlyNeedAtRetirement: 100000, requiredCorpus: 30000000,
          yearsToRetirement: 25, retirementYears: 25,
          inflationRate: 0.06, postRetirementRealReturn: 0.02,
        ),
        currentPortfolioValue: 1000000, projectedPortfolioValue: 15000000,
        projectedLumpsumValue: 0, totalProjectedValue: 15000000,
        gap: 15000000, requiredMonthlySip: 8000,
        investableSurplus: 20000, isSipAffordable: true,
        fundedPct: 50, expectedReturn: 0.12, incomeType: 'steady',
      );

      final plan = UnifiedActionsCalculator.compute(
        fundMoves: [],
        healthResult: baseHealth,
        retirementGap: gap,
        currentAllocation: baseAllocation,
        totalPortfolioValue: 1000000,
        bucketStrategy: _testBucketStrategy,
      );

      final retirementItems = plan.actionItems
          .where((a) => a.source == ActionSource.retirement)
          .toList();
      expect(retirementItems, hasLength(1));
      expect(retirementItems.first.actionType, ActionType.increaseSip);
      expect(retirementItems.first.amount, 8000);
    });

    test('adds drift alert actions for warning/critical drifts', () {
      final plan = UnifiedActionsCalculator.compute(
        fundMoves: [],
        healthResult: baseHealth,
        retirementGap: null,
        currentAllocation: baseAllocation,
        totalPortfolioValue: 1000000,
        bucketStrategy: _testBucketStrategy,
      );

      final driftItems = plan.actionItems
          .where((a) => a.source == ActionSource.drift)
          .toList();
      expect(driftItems, isNotEmpty);
    });

    test('builds 3 bucket summaries', () {
      final plan = UnifiedActionsCalculator.compute(
        fundMoves: [],
        healthResult: baseHealth,
        retirementGap: null,
        currentAllocation: baseAllocation,
        totalPortfolioValue: 1000000,
        bucketStrategy: _testBucketStrategy,
      );

      expect(plan.bucketSummary, hasLength(3));
      final bucketNames = plan.bucketSummary.map((b) => b.bucketNumber).toSet();
      expect(bucketNames, containsAll([1, 2, 3]));
    });

    test('action items sorted by priority — critical first', () {
      final healthCritical = AllocationHealthResult(
        healthScore: 30,
        healthLabel: 'Critical',
        idealAllocation: IdealAllocation(
          riskProfile: 'Moderate', age: 35, corePct: 50, satellitePct: 50, subBuckets: [],
        ),
        currentAllocation: {'coreEquity': 80, 'debt': 20},
        driftAlerts: [
          DriftAlert(
            assetClass: 'Core Equity', assetClassKey: 'coreEquity',
            currentPct: 80, idealPct: 50, driftPct: 30,
            severity: 'critical', message: 'Overexposed to Core Equity by 30%',
          ),
          DriftAlert(
            assetClass: 'Debt', assetClassKey: 'debt',
            currentPct: 20, idealPct: 30, driftPct: -10,
            severity: 'warning', message: 'Underweight Debt by 10%',
          ),
        ],
        nudges: [],
      );

      final plan = UnifiedActionsCalculator.compute(
        fundMoves: [],
        healthResult: healthCritical,
        retirementGap: null,
        currentAllocation: {'coreEquity': 80.0, 'debt': 20.0},
        totalPortfolioValue: 1000000,
        bucketStrategy: _testBucketStrategy,
      );

      final priorities = plan.actionItems.map((a) => a.priority).toList();
      if (priorities.length >= 2) {
        expect(priorities.first, ActionPriority.critical);
      }
    });

    test('each action item has platform links', () {
      final moves = [
        FundMove(
          sourceAmfiCode: 101, sourceFundName: 'Fund A', sourceAssetClass: 'coreEquity',
          destAmfiCode: 201, destFundName: 'Fund B', destAssetClass: 'debt',
          amount: 50000, moveType: MoveType.shift,
          rationale: 'Rebalance',
        ),
      ];

      final plan = UnifiedActionsCalculator.compute(
        fundMoves: moves,
        healthResult: baseHealth,
        retirementGap: null,
        currentAllocation: baseAllocation,
        totalPortfolioValue: 1000000,
        bucketStrategy: _testBucketStrategy,
      );

      final rebalanceItems = plan.actionItems
          .where((a) => a.source == ActionSource.rebalance)
          .toList();
      for (final item in rebalanceItems) {
        expect(item.platformLinks, isNotEmpty);
      }
    });

    test('rationale list is populated', () {
      final moves = [
        FundMove(
          sourceAmfiCode: 101, sourceFundName: 'Fund A', sourceAssetClass: 'coreEquity',
          destAmfiCode: 201, destFundName: 'Fund B', destAssetClass: 'debt',
          amount: 50000, moveType: MoveType.shift,
          rationale: 'Core Equity overweight → rebalance into Debt',
        ),
      ];

      final plan = UnifiedActionsCalculator.compute(
        fundMoves: moves,
        healthResult: baseHealth,
        retirementGap: null,
        currentAllocation: baseAllocation,
        totalPortfolioValue: 1000000,
        bucketStrategy: _testBucketStrategy,
      );

      expect(plan.rationale, isNotEmpty);
    });

    test('no retirement action when gap is zero or negative', () {
      final gap = RetirementGap(
        corpus: RetirementCorpus(
          monthlyExpenseAtRetirement: 100000, annualRetirementExpenses: 1200000,
          totalMonthlyNeedAtRetirement: 100000, requiredCorpus: 10000000,
          yearsToRetirement: 25, retirementYears: 25,
          inflationRate: 0.06, postRetirementRealReturn: 0.02,
        ),
        currentPortfolioValue: 50000000, projectedPortfolioValue: 50000000,
        projectedLumpsumValue: 0, totalProjectedValue: 50000000,
        gap: -40000000, requiredMonthlySip: 0,
        investableSurplus: 50000, isSipAffordable: true,
        fundedPct: 500, expectedReturn: 0.12, incomeType: 'steady',
      );

      final plan = UnifiedActionsCalculator.compute(
        fundMoves: [],
        healthResult: baseHealth,
        retirementGap: gap,
        currentAllocation: baseAllocation,
        totalPortfolioValue: 50000000,
        bucketStrategy: _testBucketStrategy,
      );

      final retirementItems = plan.actionItems
          .where((a) => a.source == ActionSource.retirement)
          .toList();
      expect(retirementItems, isEmpty);
    });
  });
}
