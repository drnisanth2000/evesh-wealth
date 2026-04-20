// test/domain/usecases/compute_stress_test_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/domain/models/projection_models.dart';
import 'package:evesh_wealth/domain/usecases/compute_stress_test.dart';

void main() {
  final allocation = {
    'coreEquity': 60.0,
    'debt': 25.0,
    'gold': 7.0,
    'liquid': 8.0,
  };

  group('Stress Test', () {
    test('produces 3 historical scenarios', () {
      final result = StressTestCalculator.compute(
        portfolioValue: 1000000,
        allocationPct: allocation,
      );
      expect(result, hasLength(3));
    });

    test('includes GFC, COVID, and 2015 correction', () {
      final result = StressTestCalculator.compute(
        portfolioValue: 1000000,
        allocationPct: allocation,
      );
      final names = result.map((s) => s.name).toSet();
      expect(names, containsAll(['2008 GFC', '2020 COVID', '2015 Correction']));
    });

    test('portfolio drawdown is allocation-weighted', () {
      // All-equity portfolio should have highest drawdown
      final equityOnly = StressTestCalculator.compute(
        portfolioValue: 1000000,
        allocationPct: {'coreEquity': 100.0},
      );
      final balanced = StressTestCalculator.compute(
        portfolioValue: 1000000,
        allocationPct: {'coreEquity': 50.0, 'debt': 40.0, 'liquid': 10.0},
      );
      final gfcEquity = equityOnly.firstWhere((s) => s.name == '2008 GFC');
      final gfcBalanced = balanced.firstWhere((s) => s.name == '2008 GFC');
      expect(gfcEquity.portfolioDrawdownPct.abs(),
          greaterThan(gfcBalanced.portfolioDrawdownPct.abs()));
    });

    test('nadir equals portfolio value minus loss', () {
      final result = StressTestCalculator.compute(
        portfolioValue: 1000000,
        allocationPct: allocation,
      );
      for (final s in result) {
        expect(s.nadir, closeTo(1000000 - s.portfolioLoss, 1));
      }
    });

    test('recovery months are positive', () {
      final result = StressTestCalculator.compute(
        portfolioValue: 1000000,
        allocationPct: allocation,
      );
      for (final s in result) {
        expect(s.recoveryMonths, greaterThan(0));
      }
    });

    test('all-debt portfolio has minimal equity drawdown', () {
      final result = StressTestCalculator.compute(
        portfolioValue: 1000000,
        allocationPct: {'debt': 80.0, 'liquid': 20.0},
      );
      for (final s in result) {
        expect(s.portfolioDrawdownPct.abs(), lessThan(15));
      }
    });
  });
}
