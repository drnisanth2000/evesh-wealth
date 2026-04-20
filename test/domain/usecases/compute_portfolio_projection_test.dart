// test/domain/usecases/compute_portfolio_projection_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/domain/models/projection_models.dart';
import 'package:evesh_wealth/domain/usecases/compute_portfolio_projection.dart';

ProjectionInput _input({
  double currentValue = 1000000,
  double monthlySip = 10000,
  int horizonYears = 10,
  double expectedReturn = 12.0,
  double inflationRate = 6.0,
  double taxSlabPct = 30.0,
}) {
  return ProjectionInput(
    currentPortfolioValue: currentValue,
    monthlySip: monthlySip,
    horizonYears: horizonYears,
    expectedReturn: expectedReturn,
    inflationRate: inflationRate,
    allocationPct: {'coreEquity': 60, 'debt': 25, 'gold': 7, 'liquid': 8},
    taxSlabPct: taxSlabPct,
  );
}

void main() {
  group('Growth Scenarios', () {
    test('produces exactly 3 scenarios', () {
      final result = PortfolioProjectionCalculator.compute(_input());
      expect(result.scenarios, hasLength(3));
      expect(result.scenarios[0].name, 'Conservative');
      expect(result.scenarios[1].name, 'Moderate');
      expect(result.scenarios[2].name, 'Aggressive');
    });

    test('aggressive scenario has highest final value', () {
      final result = PortfolioProjectionCalculator.compute(_input());
      expect(result.scenarios[2].finalValue,
          greaterThan(result.scenarios[1].finalValue));
      expect(result.scenarios[1].finalValue,
          greaterThan(result.scenarios[0].finalValue));
    });

    test('each scenario has correct number of yearly points', () {
      final input = _input(horizonYears: 10);
      final result = PortfolioProjectionCalculator.compute(input);
      for (final s in result.scenarios) {
        expect(s.points, hasLength(10));
        expect(s.points.first.year, 1);
        expect(s.points.last.year, 10);
      }
    });

    test('total invested includes SIP contributions', () {
      final input = _input(currentValue: 100000, monthlySip: 10000, horizonYears: 5);
      final result = PortfolioProjectionCalculator.compute(input);
      final totalInvested = 100000 + (10000 * 12 * 5);
      expect(result.scenarios.first.totalInvested, closeTo(totalInvested, 1));
    });

    test('wealth multiple is greater than 1 for positive returns', () {
      final result = PortfolioProjectionCalculator.compute(_input());
      for (final s in result.scenarios) {
        expect(s.wealthMultiple, greaterThan(1.0));
      }
    });

    test('zero SIP still projects growth from existing portfolio', () {
      final input = _input(monthlySip: 0);
      final result = PortfolioProjectionCalculator.compute(input);
      for (final s in result.scenarios) {
        expect(s.finalValue, greaterThan(input.currentPortfolioValue));
        expect(s.totalInvested, closeTo(input.currentPortfolioValue, 1));
      }
    });

    test('year 1 start value equals current portfolio value', () {
      final input = _input(currentValue: 500000);
      final result = PortfolioProjectionCalculator.compute(input);
      for (final s in result.scenarios) {
        expect(s.points.first.startValue, closeTo(500000, 1));
      }
    });
  });

  group('Waterfall', () {
    test('waterfall has expected steps', () {
      final result = PortfolioProjectionCalculator.compute(_input());
      expect(result.waterfall.length, greaterThanOrEqualTo(4));
      expect(result.waterfall.first.label, 'Current Portfolio');
      expect(result.waterfall.last.label, 'Real Value');
    });

    test('SIP contributions step is positive', () {
      final result = PortfolioProjectionCalculator.compute(_input(monthlySip: 10000));
      final sipStep = result.waterfall.firstWhere((s) => s.label == 'SIP Contributions');
      expect(sipStep.isPositive, true);
      expect(sipStep.value, greaterThan(0));
    });

    test('inflation erosion step is negative', () {
      final result = PortfolioProjectionCalculator.compute(_input());
      final inflationStep = result.waterfall.firstWhere((s) => s.label == 'Inflation Erosion');
      expect(inflationStep.isPositive, false);
    });
  });

  group('Benchmarks', () {
    test('produces benchmark lines for portfolio, Nifty, FD, PPF', () {
      final result = PortfolioProjectionCalculator.compute(_input());
      expect(result.benchmarks.length, greaterThanOrEqualTo(4));
      final names = result.benchmarks.map((b) => b.name).toSet();
      expect(names, containsAll(['Your Portfolio', 'Nifty 50', 'FD (Post-Tax)', 'PPF']));
    });

    test('each benchmark has correct number of yearly values', () {
      final input = _input(horizonYears: 10);
      final result = PortfolioProjectionCalculator.compute(input);
      for (final b in result.benchmarks) {
        expect(b.yearlyValues, hasLength(10));
      }
    });

    test('portfolio benchmark uses expected return', () {
      final input = _input(expectedReturn: 12.0);
      final result = PortfolioProjectionCalculator.compute(input);
      final portfolio = result.benchmarks.firstWhere((b) => b.name == 'Your Portfolio');
      expect(portfolio.annualReturn, closeTo(12.0, 0.01));
    });

    test('FD post-tax return is lower than pre-tax', () {
      final result = PortfolioProjectionCalculator.compute(_input(taxSlabPct: 30.0));
      final fd = result.benchmarks.firstWhere((b) => b.name == 'FD (Post-Tax)');
      // FD at ~7% pre-tax, 30% slab → ~4.9% post-tax
      expect(fd.annualReturn, lessThan(7.0));
    });
  });
}
