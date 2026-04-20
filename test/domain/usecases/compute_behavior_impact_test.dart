// test/domain/usecases/compute_behavior_impact_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/domain/models/projection_models.dart';
import 'package:evesh_wealth/domain/usecases/compute_behavior_impact.dart';

void main() {
  group('Behavior Impact', () {
    test('produces 3 behavior scenarios', () {
      final result = BehaviorImpactCalculator.compute(
        currentValue: 1000000,
        monthlySip: 10000,
        horizonYears: 10,
        expectedReturn: 12.0,
      );
      expect(result, hasLength(3));
    });

    test('stay invested is baseline with zero cost', () {
      final result = BehaviorImpactCalculator.compute(
        currentValue: 1000000,
        monthlySip: 10000,
        horizonYears: 10,
        expectedReturn: 12.0,
      );
      final stayInvested = result.firstWhere((s) => s.name == 'Stay Invested');
      expect(stayInvested.costOfMistake, closeTo(0, 1));
      expect(stayInvested.projectedValue, stayInvested.baselineValue);
    });

    test('panic sell has positive cost of mistake', () {
      final result = BehaviorImpactCalculator.compute(
        currentValue: 1000000,
        monthlySip: 10000,
        horizonYears: 10,
        expectedReturn: 12.0,
      );
      final panic = result.firstWhere((s) => s.name == 'Panic Sell');
      expect(panic.costOfMistake, greaterThan(0));
      expect(panic.projectedValue, lessThan(panic.baselineValue));
    });

    test('stop SIP has positive cost of mistake', () {
      final result = BehaviorImpactCalculator.compute(
        currentValue: 1000000,
        monthlySip: 10000,
        horizonYears: 10,
        expectedReturn: 12.0,
      );
      final stopSip = result.firstWhere((s) => s.name == 'Stop SIP 1 Year');
      expect(stopSip.costOfMistake, greaterThan(0));
    });

    test('cost percentage is between 0 and 100', () {
      final result = BehaviorImpactCalculator.compute(
        currentValue: 1000000,
        monthlySip: 10000,
        horizonYears: 10,
        expectedReturn: 12.0,
      );
      for (final s in result) {
        expect(s.costPct, greaterThanOrEqualTo(0));
        expect(s.costPct, lessThanOrEqualTo(100));
      }
    });

    test('each scenario has non-empty insight', () {
      final result = BehaviorImpactCalculator.compute(
        currentValue: 1000000,
        monthlySip: 10000,
        horizonYears: 10,
        expectedReturn: 12.0,
      );
      for (final s in result) {
        expect(s.insight, isNotEmpty);
      }
    });

    test('zero SIP makes stop-SIP scenario have zero cost', () {
      final result = BehaviorImpactCalculator.compute(
        currentValue: 1000000,
        monthlySip: 0,
        horizonYears: 10,
        expectedReturn: 12.0,
      );
      final stopSip = result.firstWhere((s) => s.name == 'Stop SIP 1 Year');
      expect(stopSip.costOfMistake, closeTo(0, 1));
    });
  });
}
