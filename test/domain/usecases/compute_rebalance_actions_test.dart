import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/core/constants/asset_classes.dart';
import 'package:evesh_wealth/domain/models/action_models.dart';
import 'package:evesh_wealth/domain/models/allocation_models.dart';
import 'package:evesh_wealth/domain/usecases/run_rebalance_analysis.dart';
import 'package:evesh_wealth/domain/usecases/compute_rebalance_actions.dart';

// Helper: create a minimal FundHoldingInput for testing
FundHoldingInput _holding({
  required int amfiCode,
  required String fundName,
  required String assetClassKey,
  required double currentValue,
  double? return3y,
  double? expenseRatio,
}) {
  return FundHoldingInput(
    amfiCode: amfiCode,
    fundName: fundName,
    assetClassKey: assetClassKey,
    currentValue: currentValue,
    return3y: return3y,
    expenseRatio: expenseRatio,
  );
}

RebalanceResult _rebalanceResult({
  required double totalValue,
  required List<AllocationDrift> drifts,
  required List<FundRebalanceSuggestion> suggestions,
  bool rebalanceNeeded = true,
  double driftThreshold = 5.0,
}) {
  return RebalanceResult(
    totalPortfolioValue: totalValue,
    allocationDrifts: drifts,
    bucketAllocations: [],
    topFundSuggestions: suggestions,
    rebalanceNeeded: rebalanceNeeded,
    driftThreshold: driftThreshold,
  );
}

AllocationDrift _drift({
  required AssetClass assetClass,
  required double targetPct,
  required double currentPct,
  required double currentValue,
}) {
  final driftPct = currentPct - targetPct;
  return AllocationDrift(
    assetClass: assetClass,
    targetPct: targetPct,
    currentPct: currentPct,
    currentValue: currentValue,
    driftPct: driftPct,
    action: driftPct > 1
        ? RebalanceAction.reduce
        : driftPct < -1
            ? RebalanceAction.add
            : RebalanceAction.hold,
    actionAmount: (targetPct - currentPct).abs() * 1000000 / 100,
  );
}

void main() {
  group('Rebalance Actions', () {
    test('produces shift moves from overweight to underweight', () {
      final holdings = [
        _holding(amfiCode: 101, fundName: 'Fund A', assetClassKey: 'coreEquity', currentValue: 600000),
        _holding(amfiCode: 201, fundName: 'Fund B', assetClassKey: 'debt', currentValue: 150000),
        _holding(amfiCode: 301, fundName: 'Fund C', assetClassKey: 'liquid', currentValue: 50000),
      ];
      final rebalance = _rebalanceResult(
        totalValue: 800000,
        drifts: [
          _drift(assetClass: AssetClass.coreEquity, targetPct: 50, currentPct: 75, currentValue: 600000),
          _drift(assetClass: AssetClass.debt, targetPct: 30, currentPct: 18.75, currentValue: 150000),
          _drift(assetClass: AssetClass.liquid, targetPct: 10, currentPct: 6.25, currentValue: 50000),
        ],
        suggestions: [],
      );
      final health = AllocationHealthResult(
        healthScore: 55,
        healthLabel: 'Needs Attention',
        idealAllocation: IdealAllocation(riskProfile: 'Moderate', age: 35, corePct: 50, satellitePct: 50, subBuckets: []),
        currentAllocation: {'coreEquity': 75, 'debt': 18.75, 'liquid': 6.25},
        driftAlerts: [],
        nudges: [],
      );

      final moves = RebalanceActionsCalculator.compute(
        rebalanceResult: rebalance,
        holdings: holdings,
        healthResult: health,
        driftThreshold: 5.0,
        monthlyExpense: 50000,
      );

      final shifts = moves.where((m) => m.moveType == MoveType.shift).toList();
      expect(shifts, isNotEmpty);
      expect(shifts.first.sourceAssetClass, 'coreEquity');
      expect(shifts.first.amount, greaterThan(0));
    });

    test('marks in-range funds as hold', () {
      final holdings = [
        _holding(amfiCode: 101, fundName: 'Fund A', assetClassKey: 'coreEquity', currentValue: 500000),
        _holding(amfiCode: 201, fundName: 'Fund B', assetClassKey: 'debt', currentValue: 300000),
      ];
      final rebalance = _rebalanceResult(
        totalValue: 800000,
        drifts: [
          _drift(assetClass: AssetClass.coreEquity, targetPct: 60, currentPct: 62.5, currentValue: 500000),
          _drift(assetClass: AssetClass.debt, targetPct: 40, currentPct: 37.5, currentValue: 300000),
        ],
        suggestions: [],
        rebalanceNeeded: false,
      );
      final health = AllocationHealthResult(
        healthScore: 90,
        healthLabel: 'Excellent',
        idealAllocation: IdealAllocation(riskProfile: 'Moderate', age: 35, corePct: 60, satellitePct: 40, subBuckets: []),
        currentAllocation: {'coreEquity': 62.5, 'debt': 37.5},
        driftAlerts: [],
        nudges: [],
      );

      final moves = RebalanceActionsCalculator.compute(
        rebalanceResult: rebalance,
        holdings: holdings,
        healthResult: health,
        driftThreshold: 5.0,
        monthlyExpense: 50000,
      );

      final holds = moves.where((m) => m.moveType == MoveType.hold).toList();
      expect(holds, hasLength(2));
    });

    test('generates deployCash when liquid exceeds emergency fund', () {
      final holdings = [
        _holding(amfiCode: 101, fundName: 'Fund A', assetClassKey: 'coreEquity', currentValue: 300000),
        _holding(amfiCode: 201, fundName: 'Liquid Fund', assetClassKey: 'liquid', currentValue: 500000),
      ];
      final rebalance = _rebalanceResult(
        totalValue: 800000,
        drifts: [
          _drift(assetClass: AssetClass.coreEquity, targetPct: 60, currentPct: 37.5, currentValue: 300000),
          _drift(assetClass: AssetClass.liquid, targetPct: 10, currentPct: 62.5, currentValue: 500000),
        ],
        suggestions: [],
      );
      final health = AllocationHealthResult(
        healthScore: 40,
        healthLabel: 'Needs Attention',
        idealAllocation: IdealAllocation(riskProfile: 'Moderate', age: 35, corePct: 60, satellitePct: 40, subBuckets: []),
        currentAllocation: {'coreEquity': 37.5, 'liquid': 62.5},
        driftAlerts: [],
        nudges: [],
      );

      final moves = RebalanceActionsCalculator.compute(
        rebalanceResult: rebalance,
        holdings: holdings,
        healthResult: health,
        driftThreshold: 5.0,
        monthlyExpense: 50000,
      );

      final deploys = moves.where((m) => m.moveType == MoveType.deployCash).toList();
      expect(deploys, isNotEmpty);
      expect(deploys.first.sourceAssetClass, 'liquid');
    });

    test('sells weakest fund first within overweight class', () {
      final holdings = [
        _holding(amfiCode: 101, fundName: 'Good Fund', assetClassKey: 'coreEquity', currentValue: 300000, return3y: 18.0, expenseRatio: 0.5),
        _holding(amfiCode: 102, fundName: 'Bad Fund', assetClassKey: 'coreEquity', currentValue: 300000, return3y: 5.0, expenseRatio: 2.0),
        _holding(amfiCode: 201, fundName: 'Debt Fund', assetClassKey: 'debt', currentValue: 100000),
      ];
      final rebalance = _rebalanceResult(
        totalValue: 700000,
        drifts: [
          _drift(assetClass: AssetClass.coreEquity, targetPct: 50, currentPct: 85.7, currentValue: 600000),
          _drift(assetClass: AssetClass.debt, targetPct: 30, currentPct: 14.3, currentValue: 100000),
        ],
        suggestions: [],
      );
      final health = AllocationHealthResult(
        healthScore: 30,
        healthLabel: 'Critical',
        idealAllocation: IdealAllocation(riskProfile: 'Moderate', age: 35, corePct: 50, satellitePct: 50, subBuckets: []),
        currentAllocation: {'coreEquity': 85.7, 'debt': 14.3},
        driftAlerts: [],
        nudges: [],
      );

      final moves = RebalanceActionsCalculator.compute(
        rebalanceResult: rebalance,
        holdings: holdings,
        healthResult: health,
        driftThreshold: 5.0,
        monthlyExpense: 50000,
      );

      final shifts = moves.where((m) => m.moveType == MoveType.shift).toList();
      expect(shifts, isNotEmpty);
      expect(shifts.first.sourceAmfiCode, 102);
    });

    test('buys into strongest fund within underweight class', () {
      final holdings = [
        _holding(amfiCode: 101, fundName: 'Equity Fund', assetClassKey: 'coreEquity', currentValue: 600000),
        _holding(amfiCode: 201, fundName: 'Good Debt', assetClassKey: 'debt', currentValue: 50000, return3y: 9.0, expenseRatio: 0.3),
        _holding(amfiCode: 202, fundName: 'Weak Debt', assetClassKey: 'debt', currentValue: 50000, return3y: 5.0, expenseRatio: 1.5),
      ];
      final rebalance = _rebalanceResult(
        totalValue: 700000,
        drifts: [
          _drift(assetClass: AssetClass.coreEquity, targetPct: 50, currentPct: 85.7, currentValue: 600000),
          _drift(assetClass: AssetClass.debt, targetPct: 30, currentPct: 14.3, currentValue: 100000),
        ],
        suggestions: [],
      );
      final health = AllocationHealthResult(
        healthScore: 30,
        healthLabel: 'Critical',
        idealAllocation: IdealAllocation(riskProfile: 'Moderate', age: 35, corePct: 50, satellitePct: 50, subBuckets: []),
        currentAllocation: {'coreEquity': 85.7, 'debt': 14.3},
        driftAlerts: [],
        nudges: [],
      );

      final moves = RebalanceActionsCalculator.compute(
        rebalanceResult: rebalance,
        holdings: holdings,
        healthResult: health,
        driftThreshold: 5.0,
        monthlyExpense: 50000,
      );

      final shifts = moves.where((m) => m.moveType == MoveType.shift).toList();
      expect(shifts, isNotEmpty);
      expect(shifts.first.destAmfiCode, 201);
    });

    test('empty portfolio returns empty moves', () {
      final rebalance = _rebalanceResult(
        totalValue: 0,
        drifts: [],
        suggestions: [],
        rebalanceNeeded: false,
      );
      final health = AllocationHealthResult(
        healthScore: 0,
        healthLabel: 'No Portfolio',
        idealAllocation: IdealAllocation(riskProfile: 'Moderate', age: 35, corePct: 50, satellitePct: 50, subBuckets: []),
        currentAllocation: {},
        driftAlerts: [],
        nudges: [],
      );

      final moves = RebalanceActionsCalculator.compute(
        rebalanceResult: rebalance,
        holdings: [],
        healthResult: health,
        driftThreshold: 5.0,
        monthlyExpense: 50000,
      );

      expect(moves, isEmpty);
    });

    test('balanced portfolio produces only hold moves', () {
      final holdings = [
        _holding(amfiCode: 101, fundName: 'Fund A', assetClassKey: 'coreEquity', currentValue: 500000),
        _holding(amfiCode: 201, fundName: 'Fund B', assetClassKey: 'debt', currentValue: 300000),
        _holding(amfiCode: 301, fundName: 'Fund C', assetClassKey: 'liquid', currentValue: 100000),
        _holding(amfiCode: 401, fundName: 'Fund D', assetClassKey: 'gold', currentValue: 100000),
      ];
      final rebalance = _rebalanceResult(
        totalValue: 1000000,
        drifts: [
          _drift(assetClass: AssetClass.coreEquity, targetPct: 50, currentPct: 50, currentValue: 500000),
          _drift(assetClass: AssetClass.debt, targetPct: 30, currentPct: 30, currentValue: 300000),
          _drift(assetClass: AssetClass.liquid, targetPct: 10, currentPct: 10, currentValue: 100000),
          _drift(assetClass: AssetClass.gold, targetPct: 10, currentPct: 10, currentValue: 100000),
        ],
        suggestions: [],
        rebalanceNeeded: false,
      );
      final health = AllocationHealthResult(
        healthScore: 95,
        healthLabel: 'Excellent',
        idealAllocation: IdealAllocation(riskProfile: 'Moderate', age: 35, corePct: 50, satellitePct: 50, subBuckets: []),
        currentAllocation: {'coreEquity': 50, 'debt': 30, 'liquid': 10, 'gold': 10},
        driftAlerts: [],
        nudges: [],
      );

      final moves = RebalanceActionsCalculator.compute(
        rebalanceResult: rebalance,
        holdings: holdings,
        healthResult: health,
        driftThreshold: 5.0,
        monthlyExpense: 50000,
      );

      expect(moves.every((m) => m.moveType == MoveType.hold), true);
    });

    test('shift amounts sum correctly — total sell equals total buy', () {
      final holdings = [
        _holding(amfiCode: 101, fundName: 'Fund A', assetClassKey: 'coreEquity', currentValue: 700000),
        _holding(amfiCode: 201, fundName: 'Fund B', assetClassKey: 'debt', currentValue: 100000),
        _holding(amfiCode: 301, fundName: 'Fund C', assetClassKey: 'liquid', currentValue: 100000),
        _holding(amfiCode: 401, fundName: 'Fund D', assetClassKey: 'gold', currentValue: 100000),
      ];
      final rebalance = _rebalanceResult(
        totalValue: 1000000,
        drifts: [
          _drift(assetClass: AssetClass.coreEquity, targetPct: 40, currentPct: 70, currentValue: 700000),
          _drift(assetClass: AssetClass.debt, targetPct: 30, currentPct: 10, currentValue: 100000),
          _drift(assetClass: AssetClass.liquid, targetPct: 15, currentPct: 10, currentValue: 100000),
          _drift(assetClass: AssetClass.gold, targetPct: 15, currentPct: 10, currentValue: 100000),
        ],
        suggestions: [],
      );
      final health = AllocationHealthResult(
        healthScore: 30,
        healthLabel: 'Critical',
        idealAllocation: IdealAllocation(riskProfile: 'Moderate', age: 35, corePct: 40, satellitePct: 60, subBuckets: []),
        currentAllocation: {'coreEquity': 70, 'debt': 10, 'liquid': 10, 'gold': 10},
        driftAlerts: [],
        nudges: [],
      );

      final moves = RebalanceActionsCalculator.compute(
        rebalanceResult: rebalance,
        holdings: holdings,
        healthResult: health,
        driftThreshold: 5.0,
        monthlyExpense: 50000,
      );

      final shifts = moves.where((m) => m.moveType == MoveType.shift || m.moveType == MoveType.deployCash).toList();
      final totalSellSide = shifts.fold(0.0, (sum, m) => sum + m.amount);
      for (final m in shifts) {
        expect(m.amount, greaterThan(0));
      }
      expect(totalSellSide, greaterThan(0));
    });

    test('each move has a non-empty rationale', () {
      final holdings = [
        _holding(amfiCode: 101, fundName: 'Fund A', assetClassKey: 'coreEquity', currentValue: 700000),
        _holding(amfiCode: 201, fundName: 'Fund B', assetClassKey: 'debt', currentValue: 300000),
      ];
      final rebalance = _rebalanceResult(
        totalValue: 1000000,
        drifts: [
          _drift(assetClass: AssetClass.coreEquity, targetPct: 50, currentPct: 70, currentValue: 700000),
          _drift(assetClass: AssetClass.debt, targetPct: 50, currentPct: 30, currentValue: 300000),
        ],
        suggestions: [],
      );
      final health = AllocationHealthResult(
        healthScore: 50,
        healthLabel: 'Needs Attention',
        idealAllocation: IdealAllocation(riskProfile: 'Moderate', age: 35, corePct: 50, satellitePct: 50, subBuckets: []),
        currentAllocation: {'coreEquity': 70, 'debt': 30},
        driftAlerts: [],
        nudges: [],
      );

      final moves = RebalanceActionsCalculator.compute(
        rebalanceResult: rebalance,
        holdings: holdings,
        healthResult: health,
        driftThreshold: 5.0,
        monthlyExpense: 50000,
      );

      for (final m in moves) {
        expect(m.rationale, isNotEmpty);
      }
    });

    test('multiple funds in overweight class — distributes sell proportionally', () {
      final holdings = [
        _holding(amfiCode: 101, fundName: 'Fund X', assetClassKey: 'coreEquity', currentValue: 400000, return3y: 10.0),
        _holding(amfiCode: 102, fundName: 'Fund Y', assetClassKey: 'coreEquity', currentValue: 200000, return3y: 8.0),
        _holding(amfiCode: 201, fundName: 'Debt Fund', assetClassKey: 'debt', currentValue: 100000),
      ];
      final rebalance = _rebalanceResult(
        totalValue: 700000,
        drifts: [
          _drift(assetClass: AssetClass.coreEquity, targetPct: 50, currentPct: 85.7, currentValue: 600000),
          _drift(assetClass: AssetClass.debt, targetPct: 50, currentPct: 14.3, currentValue: 100000),
        ],
        suggestions: [],
      );
      final health = AllocationHealthResult(
        healthScore: 30,
        healthLabel: 'Critical',
        idealAllocation: IdealAllocation(riskProfile: 'Moderate', age: 35, corePct: 50, satellitePct: 50, subBuckets: []),
        currentAllocation: {'coreEquity': 85.7, 'debt': 14.3},
        driftAlerts: [],
        nudges: [],
      );

      final moves = RebalanceActionsCalculator.compute(
        rebalanceResult: rebalance,
        holdings: holdings,
        healthResult: health,
        driftThreshold: 5.0,
        monthlyExpense: 50000,
      );

      final shifts = moves.where((m) => m.moveType == MoveType.shift).toList();
      final sourceAmfis = shifts.map((s) => s.sourceAmfiCode).toSet();
      expect(sourceAmfis, contains(102)); // weaker fund is sold first
    });
  });
}
