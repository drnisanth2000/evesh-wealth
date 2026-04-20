import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/domain/usecases/compute_allocation_health.dart';
import 'package:evesh_wealth/domain/usecases/compute_ideal_allocation.dart';

void main() {
  // Helper: build a current allocation that exactly mirrors the ideal.
  Map<String, double> perfectAllocation(
      Map<String, double> idealByClass) {
    return Map<String, double>.from(idealByClass);
  }

  // Helper: compute ideal per-asset-class percentages from IdealAllocation.
  Map<String, double> idealMap(dynamic ideal) {
    const keys = [
      'coreEquity',
      'debt',
      'gold',
      'satelliteEquity',
      'hybrid',
      'liquid',
      'alternatives',
    ];
    return {for (final k in keys) k: ideal.idealForAssetClass(k)};
  }

  group('AllocationHealthCalculator', () {
    // ------------------------------------------------------------------
    // 1. Perfect allocation → score 100, "Excellent", no actionable alerts
    // ------------------------------------------------------------------
    group('perfect allocation', () {
      test('score is 100 and label is Excellent', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        final current = perfectAllocation(idealMap(ideal));

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        expect(result.healthScore, equals(100));
        expect(result.healthLabel, equals('Excellent'));
      });

      test('no critical or warning drift alerts', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        final current = perfectAllocation(idealMap(ideal));

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        final actionable = result.driftAlerts
            .where((a) => a.severity != 'ok')
            .toList();
        expect(actionable, isEmpty);
      });

      test('all drift alerts have severity ok', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Aggressive',
          age: 30,
        );
        final current = perfectAllocation(idealMap(ideal));

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 200000,
          ideal: ideal,
        );

        for (final alert in result.driftAlerts) {
          expect(alert.severity, equals('ok'));
        }
      });
    });

    // ------------------------------------------------------------------
    // 2. Empty portfolio → score 0, label "No Portfolio", nudge present
    // ------------------------------------------------------------------
    group('empty portfolio', () {
      test('zero portfolio value → score 0', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );

        final result = AllocationHealthCalculator.compute(
          currentAllocation: const {},
          portfolioValue: 0,
          ideal: ideal,
        );

        expect(result.healthScore, equals(0));
      });

      test('zero portfolio value → label is No Portfolio', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );

        final result = AllocationHealthCalculator.compute(
          currentAllocation: const {},
          portfolioValue: 0,
          ideal: ideal,
        );

        expect(result.healthLabel, equals('No Portfolio'));
      });

      test('zero portfolio value → nudge contains start investing text', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );

        final result = AllocationHealthCalculator.compute(
          currentAllocation: const {},
          portfolioValue: 0,
          ideal: ideal,
        );

        expect(result.nudges, isNotEmpty);
        expect(
          result.nudges.first.toLowerCase(),
          contains('start investing'),
        );
      });

      test('negative portfolio value also treated as empty', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );

        final result = AllocationHealthCalculator.compute(
          currentAllocation: const {},
          portfolioValue: -100,
          ideal: ideal,
        );

        expect(result.healthScore, equals(0));
        expect(result.healthLabel, equals('No Portfolio'));
      });
    });

    // ------------------------------------------------------------------
    // 3. Large drift → score < 60, critical alerts present
    // ------------------------------------------------------------------
    group('large drift', () {
      test('80% in one bucket → score below 60', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );

        // Stuff 80% into coreEquity, spread rest thin
        const current = <String, double>{
          'coreEquity': 80.0,
          'debt': 10.0,
          'gold': 5.0,
          'satelliteEquity': 2.0,
          'hybrid': 1.5,
          'liquid': 1.0,
          'alternatives': 0.5,
        };

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        expect(result.healthScore, lessThanOrEqualTo(60));
      });

      test('80% in one bucket → at least one critical alert', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );

        const current = <String, double>{
          'coreEquity': 80.0,
          'debt': 10.0,
          'gold': 5.0,
          'satelliteEquity': 2.0,
          'hybrid': 1.5,
          'liquid': 1.0,
          'alternatives': 0.5,
        };

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        final criticals =
            result.driftAlerts.where((a) => a.severity == 'critical').toList();
        expect(criticals, isNotEmpty);
      });

      test('critical alert nudge contains rebalancing recommended', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );

        const current = <String, double>{
          'coreEquity': 80.0,
          'debt': 10.0,
          'gold': 5.0,
          'satelliteEquity': 2.0,
          'hybrid': 1.5,
          'liquid': 1.0,
          'alternatives': 0.5,
        };

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        expect(
          result.nudges.any((n) =>
              n.toLowerCase().contains('rebalancing recommended')),
          isTrue,
        );
      });
    });

    // ------------------------------------------------------------------
    // 4. Score always 0–100
    // ------------------------------------------------------------------
    group('score bounds', () {
      test('perfect allocation → score == 100 (not above)', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Aggressive',
          age: 30,
        );
        final current = perfectAllocation(idealMap(ideal));

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 1000000,
          ideal: ideal,
        );

        expect(result.healthScore, lessThanOrEqualTo(100));
        expect(result.healthScore, greaterThanOrEqualTo(0));
      });

      test('extreme drift → score == 0 (not below)', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );

        // All in one bucket, every other bucket at 0
        const current = <String, double>{
          'coreEquity': 100.0,
          'debt': 0.0,
          'gold': 0.0,
          'satelliteEquity': 0.0,
          'hybrid': 0.0,
          'liquid': 0.0,
          'alternatives': 0.0,
        };

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        expect(result.healthScore, greaterThanOrEqualTo(0));
        expect(result.healthScore, lessThanOrEqualTo(100));
      });

      test('score is always an integer', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 40,
        );

        const current = <String, double>{
          'coreEquity': 45.0,
          'debt': 30.0,
          'gold': 8.0,
          'satelliteEquity': 10.0,
          'hybrid': 4.0,
          'liquid': 2.0,
          'alternatives': 1.0,
        };

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 300000,
          ideal: ideal,
        );

        expect(result.healthScore, isA<int>());
      });
    });

    // ------------------------------------------------------------------
    // 5. Correct overweight / underweight in drift messages
    // ------------------------------------------------------------------
    group('drift message direction', () {
      test('current > ideal → Overexposed message', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        final allocationMap = idealMap(ideal);
        final coreIdeal = allocationMap['coreEquity']!;

        // Put current coreEquity 20 points above ideal
        final current = Map<String, double>.from(allocationMap);
        current['coreEquity'] = coreIdeal + 20.0;
        // Reduce another bucket to keep total at 100
        current['debt'] = (allocationMap['debt']! - 20.0).clamp(0.0, 100.0);

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        final coreAlert = result.driftAlerts
            .firstWhere((a) => a.assetClassKey == 'coreEquity');
        expect(coreAlert.message.toLowerCase(), contains('overexposed'));
      });

      test('current < ideal → Underweight message', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        final allocationMap = idealMap(ideal);
        final coreIdeal = allocationMap['coreEquity']!;

        // Put current coreEquity 20 points below ideal
        final current = Map<String, double>.from(allocationMap);
        current['coreEquity'] = (coreIdeal - 20.0).clamp(0.0, 100.0);
        current['debt'] = allocationMap['debt']! + 20.0;

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        final coreAlert = result.driftAlerts
            .firstWhere((a) => a.assetClassKey == 'coreEquity');
        expect(coreAlert.message.toLowerCase(), contains('underweight'));
      });

      test('drift message contains asset class display name', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        final allocationMap = idealMap(ideal);
        final goldIdeal = allocationMap['gold']!;

        final current = Map<String, double>.from(allocationMap);
        current['gold'] = goldIdeal + 15.0;
        current['debt'] = (allocationMap['debt']! - 15.0).clamp(0.0, 100.0);

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        final goldAlert =
            result.driftAlerts.firstWhere((a) => a.assetClassKey == 'gold');
        expect(goldAlert.message, contains('Gold'));
      });

      test('drift message contains percentage value', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        final allocationMap = idealMap(ideal);
        final debtIdeal = allocationMap['debt']!;

        final current = Map<String, double>.from(allocationMap);
        current['debt'] = (debtIdeal - 16.0).clamp(0.0, 100.0);
        current['coreEquity'] = allocationMap['coreEquity']! + 16.0;

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        final debtAlert =
            result.driftAlerts.firstWhere((a) => a.assetClassKey == 'debt');
        // Message should contain a number representing the drift %
        expect(debtAlert.message, matches(RegExp(r'\d+(\.\d+)?%')));
      });
    });

    // ------------------------------------------------------------------
    // 6. Health labels
    // ------------------------------------------------------------------
    group('health labels', () {
      test('score >= 85 → Excellent', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        final current = perfectAllocation(idealMap(ideal));

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        expect(result.healthLabel, equals('Excellent'));
      });

      test('small drift → label is Good or better', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        final allocationMap = idealMap(ideal);

        // Introduce a small drift (~3% off in coreEquity)
        final current = Map<String, double>.from(allocationMap);
        current['coreEquity'] = allocationMap['coreEquity']! + 3.0;
        current['debt'] = (allocationMap['debt']! - 3.0).clamp(0.0, 100.0);

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        expect(
          ['Excellent', 'Good'].contains(result.healthLabel),
          isTrue,
          reason: 'Small drift should yield Excellent or Good, '
              'got ${result.healthLabel}',
        );
      });
    });

    // ------------------------------------------------------------------
    // 7. Nudge: multiple warnings
    // ------------------------------------------------------------------
    group('nudges', () {
      test('2+ warning alerts → portfolio review nudge', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        final allocationMap = idealMap(ideal);

        // Create warning-level drifts (8%) in 3 asset classes
        final current = Map<String, double>.from(allocationMap);
        current['coreEquity'] = allocationMap['coreEquity']! + 8.0;
        current['satelliteEquity'] = allocationMap['satelliteEquity']! + 8.0;
        current['debt'] = (allocationMap['debt']! - 16.0).clamp(0.0, 100.0);

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        expect(
          result.nudges.any((n) =>
              n.toLowerCase().contains('portfolio review') ||
              n.toLowerCase().contains('drifted')),
          isTrue,
        );
      });

      test('low liquid + large portfolio → emergency fund nudge', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        final allocationMap = idealMap(ideal);

        final current = Map<String, double>.from(allocationMap);
        // Set liquid to 1% (below 3%)
        final liquidNow = allocationMap['liquid']!;
        current['liquid'] = 1.0;
        current['debt'] = allocationMap['debt']! + (liquidNow - 1.0);

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 200000, // > ₹1L
          ideal: ideal,
        );

        expect(
          result.nudges.any((n) =>
              n.toLowerCase().contains('emergency fund') ||
              n.toLowerCase().contains('liquid')),
          isTrue,
        );
      });

      test('low liquid but small portfolio → no emergency fund nudge', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        final allocationMap = idealMap(ideal);

        final current = Map<String, double>.from(allocationMap);
        final liquidNow = allocationMap['liquid']!;
        current['liquid'] = 1.0;
        current['debt'] = allocationMap['debt']! + (liquidNow - 1.0);

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 50000, // < ₹1L
          ideal: ideal,
        );

        expect(
          result.nudges.every((n) =>
              !n.toLowerCase().contains('emergency fund')),
          isTrue,
        );
      });
    });

    // ------------------------------------------------------------------
    // 8. Drift alert completeness
    // ------------------------------------------------------------------
    group('drift alert structure', () {
      test('returns a DriftAlert for every tracked asset class', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        final current = perfectAllocation(idealMap(ideal));

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        const expectedKeys = [
          'coreEquity',
          'debt',
          'gold',
          'satelliteEquity',
          'hybrid',
          'liquid',
          'alternatives',
        ];
        final returnedKeys =
            result.driftAlerts.map((a) => a.assetClassKey).toSet();
        for (final key in expectedKeys) {
          expect(returnedKeys, contains(key));
        }
      });

      test('driftPct is positive when overweight', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        final allocationMap = idealMap(ideal);
        final current = Map<String, double>.from(allocationMap);
        current['gold'] = allocationMap['gold']! + 10.0;
        current['debt'] = (allocationMap['debt']! - 10.0).clamp(0.0, 100.0);

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        final goldAlert =
            result.driftAlerts.firstWhere((a) => a.assetClassKey == 'gold');
        expect(goldAlert.driftPct, greaterThan(0));
      });

      test('driftPct is negative when underweight', () {
        final ideal = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        final allocationMap = idealMap(ideal);
        final current = Map<String, double>.from(allocationMap);
        current['gold'] = (allocationMap['gold']! - 5.0).clamp(0.0, 100.0);
        current['debt'] = allocationMap['debt']! + 5.0;

        final result = AllocationHealthCalculator.compute(
          currentAllocation: current,
          portfolioValue: 500000,
          ideal: ideal,
        );

        final goldAlert =
            result.driftAlerts.firstWhere((a) => a.assetClassKey == 'gold');
        expect(goldAlert.driftPct, lessThan(0));
      });
    });
  });
}
