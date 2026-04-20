import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/domain/usecases/compute_simulation.dart';
import 'package:evesh_wealth/domain/usecases/compute_bucket_strategy.dart';
import 'package:evesh_wealth/domain/models/simulation_models.dart';
import 'package:evesh_wealth/domain/usecases/compute_rebalance_actions.dart';
import 'package:evesh_wealth/presentation/providers/tax_provider.dart';
import 'package:evesh_wealth/domain/usecases/run_fifo_tax_calculator.dart';

void main() {
  final holdings = [
    FundHoldingInput(amfiCode: 122639, fundName: 'Parag Parikh Flexi Cap', assetClassKey: 'coreEquity', currentValue: 300000),
    FundHoldingInput(amfiCode: 120197, fundName: 'ICICI Pru Liquid Fund', assetClassKey: 'liquid', currentValue: 100000),
    FundHoldingInput(amfiCode: 100356, fundName: 'ICICI Pru Equity & Debt', assetClassKey: 'hybrid', currentValue: 50000),
    FundHoldingInput(amfiCode: 114758, fundName: 'Kotak Gold Fund', assetClassKey: 'gold', currentValue: 50000),
  ];

  final strategy = BucketStrategyCalculator.compute(age: 35, riskProfile: 'Moderate', retirementAge: 60);

  group('SimulationCalculator', () {
    test('no changes produces zero tax impact and same portfolio value', () {
      final adjusted = {122639: 300000.0, 120197: 100000.0, 100356: 50000.0, 114758: 50000.0};
      final result = SimulationCalculator.compute(
        holdings: holdings, adjustedAmounts: adjusted, additionalLumpsum: 0, additionalSip: 0,
        bucketStrategy: strategy, driftThreshold: 5.0, exposures: [],
      );
      expect(result.taxImpacts, isEmpty);
      expect(result.totalTaxCost, 0);
      expect(result.totalExitLoad, 0);
      expect(result.totalPortfolioValue, 500000);
    });

    test('adding lumpsum increases portfolio value', () {
      final adjusted = {122639: 300000.0, 120197: 100000.0, 100356: 50000.0, 114758: 50000.0};
      final result = SimulationCalculator.compute(
        holdings: holdings, adjustedAmounts: adjusted, additionalLumpsum: 100000, additionalSip: 0,
        bucketStrategy: strategy, driftThreshold: 5.0, exposures: [],
      );
      expect(result.totalPortfolioValue, 600000);
    });

    test('reducing a fund produces tax impact', () {
      final adjusted = {122639: 200000.0, 120197: 100000.0, 100356: 50000.0, 114758: 50000.0};
      final exposure = UnrealizedExposure(
        fundName: 'Parag Parikh Flexi Cap', memberId: 'mem1', memberName: 'Test', amfiCode: 122639,
        taxCategory: TaxCategory.equity, holdingDays: 400, totalUnits: 1000,
        costBasis: 250000, currentValue: 300000, unrealisedGain: 50000,
        gainType: 'LTCG', estimatedTax: 0, ltcgDaysRemaining: 0,
        stcgGain: 0, ltcgGain: 50000, stcgTax: 0, ltcgTax: 0,
        stcgTaxRate: 0.20, ltcgTaxRate: 0.125, postTaxGain: 50000, exitLoadAmount: 0,
      );
      final result = SimulationCalculator.compute(
        holdings: holdings, adjustedAmounts: adjusted, additionalLumpsum: 0, additionalSip: 0,
        bucketStrategy: strategy, driftThreshold: 5.0, exposures: [exposure],
      );
      expect(result.taxImpacts, hasLength(1));
      expect(result.taxImpacts.first.sellAmount, 100000);
      expect(result.taxImpacts.first.amfiCode, 122639);
      expect(result.totalPortfolioValue, 400000);
    });

    test('bucket composition reflects adjusted allocations', () {
      final adjusted = {122639: 300000.0, 120197: 100000.0, 100356: 50000.0, 114758: 50000.0};
      final result = SimulationCalculator.compute(
        holdings: holdings, adjustedAmounts: adjusted, additionalLumpsum: 0, additionalSip: 0,
        bucketStrategy: strategy, driftThreshold: 5.0, exposures: [],
      );
      expect(result.bucketFills, hasLength(3));
      final b1 = result.bucketFills.firstWhere((b) => b.bucketNumber == 1);
      expect(b1.currentValue, 100000);
      expect(b1.currentPct, closeTo(20.0, 0.1));
      final b3 = result.bucketFills.firstWhere((b) => b.bucketNumber == 3);
      expect(b3.currentValue, 300000);
      expect(b3.currentPct, closeTo(60.0, 0.1));
    });

    test('overflow detected when bucket exceeds ideal + threshold', () {
      final adjusted = {122639: 450000.0, 120197: 20000.0, 100356: 15000.0, 114758: 15000.0};
      final result = SimulationCalculator.compute(
        holdings: holdings, adjustedAmounts: adjusted, additionalLumpsum: 0, additionalSip: 0,
        bucketStrategy: strategy, driftThreshold: 5.0, exposures: [],
      );
      final b3 = result.bucketFills.firstWhere((b) => b.bucketNumber == 3);
      expect(b3.overflowPct, greaterThan(0));
      expect(b3.status, 'overweight');
    });

    test('health score is computed and valid', () {
      final adjusted = {122639: 200000.0, 120197: 100000.0, 100356: 100000.0, 114758: 100000.0};
      final result = SimulationCalculator.compute(
        holdings: holdings, adjustedAmounts: adjusted, additionalLumpsum: 0, additionalSip: 0,
        bucketStrategy: strategy, driftThreshold: 5.0, exposures: [],
      );
      expect(result.projectedHealthScore, isA<int>());
      expect(result.projectedHealthScore, greaterThanOrEqualTo(0));
      expect(result.projectedHealthScore, lessThanOrEqualTo(100));
    });

    test('new allocation percentages are correct', () {
      final adjusted = {122639: 250000.0, 120197: 100000.0, 100356: 75000.0, 114758: 75000.0};
      final result = SimulationCalculator.compute(
        holdings: holdings, adjustedAmounts: adjusted, additionalLumpsum: 0, additionalSip: 0,
        bucketStrategy: strategy, driftThreshold: 5.0, exposures: [],
      );
      expect(result.totalPortfolioValue, 500000);
      expect(result.newAllocationPct['coreEquity'], closeTo(50.0, 0.1));
      expect(result.newAllocationPct['liquid'], closeTo(20.0, 0.1));
      expect(result.newAllocationPct['hybrid'], closeTo(15.0, 0.1));
      expect(result.newAllocationPct['gold'], closeTo(15.0, 0.1));
    });

    test('SIP amount added to portfolio value (annualized)', () {
      final adjusted = {122639: 300000.0, 120197: 100000.0, 100356: 50000.0, 114758: 50000.0};
      final result = SimulationCalculator.compute(
        holdings: holdings, adjustedAmounts: adjusted, additionalLumpsum: 0, additionalSip: 10000,
        bucketStrategy: strategy, driftThreshold: 5.0, exposures: [],
      );
      expect(result.totalPortfolioValue, 620000); // 500K + 10K*12
    });
  });
}
