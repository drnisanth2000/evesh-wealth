import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/domain/usecases/compute_ideal_allocation.dart';

void main() {
  group('IdealAllocationCalculator', () {
    group('risk profile base allocations', () {
      test('Moderate profile age 35 → ~70% core, ~30% satellite', () {
        final result = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        expect(result.riskProfile, equals('Moderate'));
        expect(result.age, equals(35));
        expect(result.corePct, closeTo(70.0, 0.01));
        expect(result.satellitePct, closeTo(30.0, 0.01));
      });

      test('Aggressive profile age 30 → ~55% core, ~45% satellite', () {
        final result = IdealAllocationCalculator.compute(
          riskProfile: 'Aggressive',
          age: 30,
        );
        expect(result.corePct, closeTo(55.0, 0.01));
        expect(result.satellitePct, closeTo(45.0, 0.01));
      });

      test('Conservative profile age 55 → ~80% core with reduced equity', () {
        final result = IdealAllocationCalculator.compute(
          riskProfile: 'Conservative',
          age: 55,
        );
        expect(result.corePct, closeTo(80.0, 0.01));
        // Conservative base equity is 40%, glide path reduces by 2.5% per year past 45
        // Age 55 → 10 years * 2.5% = 25% reduction, floor at 25%
        // equity should be <= 40% - but floor is 25%
        final coreEquityPct = result.idealForAssetClass('coreEquity');
        expect(coreEquityPct, lessThan(45.0));
      });
    });

    group('glide path', () {
      test('equity is not adjusted for age <= 45', () {
        final age40 = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 40,
        );
        final age45 = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 45,
        );
        // Both should have same equity allocation (no glide path)
        expect(
          age40.idealForAssetClass('coreEquity') +
              age40.idealForAssetClass('satelliteEquity'),
          closeTo(
            age45.idealForAssetClass('coreEquity') +
                age45.idealForAssetClass('satelliteEquity'),
            0.01,
          ),
        );
      });

      test('glide path reduces equity after age 45', () {
        final age45 = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 45,
        );
        final age55 = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 55,
        );
        final equity45 = age45.idealForAssetClass('coreEquity') +
            age45.idealForAssetClass('satelliteEquity');
        final equity55 = age55.idealForAssetClass('coreEquity') +
            age55.idealForAssetClass('satelliteEquity');
        expect(equity55, lessThan(equity45));
      });

      test('glide path caps at age 65 (20 years max reduction)', () {
        final age65 = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 65,
        );
        final age75 = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 75,
        );
        // After age 65, no further reduction
        final equity65 = age65.idealForAssetClass('coreEquity') +
            age65.idealForAssetClass('satelliteEquity');
        final equity75 = age75.idealForAssetClass('coreEquity') +
            age75.idealForAssetClass('satelliteEquity');
        expect(equity75, closeTo(equity65, 0.01));
      });

      test('equity never falls below 25% floor', () {
        // Very old age with aggressive profile to test floor
        final result = IdealAllocationCalculator.compute(
          riskProfile: 'Conservative',
          age: 70,
        );
        final totalEquity = result.idealForAssetClass('coreEquity') +
            result.idealForAssetClass('satelliteEquity');
        expect(totalEquity, greaterThanOrEqualTo(25.0 - 0.01));
      });
    });

    group('sub-buckets sum to 100%', () {
      for (final profile in [
        'Conservative',
        'Moderately Conservative',
        'Moderate',
        'Moderately Aggressive',
        'Aggressive',
      ]) {
        test('$profile age 35 sub-buckets sum to 100%', () {
          final result = IdealAllocationCalculator.compute(
            riskProfile: profile,
            age: 35,
          );
          final total = result.subBuckets.fold(
            0.0,
            (sum, b) => sum + b.idealPct,
          );
          expect(total, closeTo(100.0, 0.01));
          expect(result.subBuckets.length, equals(13));
        });
      }

      test('sub-buckets sum to 100% with glide path applied (age 55)', () {
        final result = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 55,
        );
        final total = result.subBuckets.fold(
          0.0,
          (sum, b) => sum + b.idealPct,
        );
        expect(total, closeTo(100.0, 0.01));
      });
    });

    group('all 5 risk profiles are supported', () {
      test('Conservative returns valid allocation', () {
        final result = IdealAllocationCalculator.compute(
          riskProfile: 'Conservative',
          age: 35,
        );
        expect(result.corePct, closeTo(80.0, 0.01));
        expect(result.satellitePct, closeTo(20.0, 0.01));
      });

      test('Moderately Conservative returns valid allocation', () {
        final result = IdealAllocationCalculator.compute(
          riskProfile: 'Moderately Conservative',
          age: 35,
        );
        expect(result.corePct, closeTo(75.0, 0.01));
        expect(result.satellitePct, closeTo(25.0, 0.01));
      });

      test('Moderate returns valid allocation', () {
        final result = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        expect(result.corePct, closeTo(70.0, 0.01));
        expect(result.satellitePct, closeTo(30.0, 0.01));
      });

      test('Moderately Aggressive returns valid allocation', () {
        final result = IdealAllocationCalculator.compute(
          riskProfile: 'Moderately Aggressive',
          age: 35,
        );
        expect(result.corePct, closeTo(65.0, 0.01));
        expect(result.satellitePct, closeTo(35.0, 0.01));
      });

      test('Aggressive returns valid allocation', () {
        final result = IdealAllocationCalculator.compute(
          riskProfile: 'Aggressive',
          age: 35,
        );
        expect(result.corePct, closeTo(55.0, 0.01));
        expect(result.satellitePct, closeTo(45.0, 0.01));
      });
    });

    group('unknown risk profile defaults to Moderate', () {
      test('unknown profile behaves like Moderate', () {
        final unknown = IdealAllocationCalculator.compute(
          riskProfile: 'Unknown Profile',
          age: 35,
        );
        final moderate = IdealAllocationCalculator.compute(
          riskProfile: 'Moderate',
          age: 35,
        );
        expect(unknown.corePct, closeTo(moderate.corePct, 0.01));
        expect(unknown.satellitePct, closeTo(moderate.satellitePct, 0.01));
        expect(
          unknown.subBuckets.fold(0.0, (s, b) => s + b.idealPct),
          closeTo(100.0, 0.01),
        );
      });
    });
  });
}
