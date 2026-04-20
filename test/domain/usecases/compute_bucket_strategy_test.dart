import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/domain/usecases/compute_bucket_strategy.dart';

void main() {
  group('BucketStrategyCalculator', () {
    test('young aggressive accumulator (age 28) gets high growth allocation', () {
      final strategy = BucketStrategyCalculator.compute(age: 28, riskProfile: 'Aggressive', retirementAge: 60);
      expect(strategy.scenario, 'accumulation');
      expect(strategy.bucketTargets[3]!, greaterThanOrEqualTo(75.0));
      expect(strategy.bucketTargets[1]!, lessThanOrEqualTo(8.0));
      expect(strategy.corePct, 75.0);
      expect(strategy.satellitePct, 25.0);
    });

    test('conservative age 28 gets lower growth than aggressive', () {
      final aggressive = BucketStrategyCalculator.compute(age: 28, riskProfile: 'Aggressive', retirementAge: 60);
      final conservative = BucketStrategyCalculator.compute(age: 28, riskProfile: 'Conservative', retirementAge: 60);
      expect(conservative.bucketTargets[3]!, lessThan(aggressive.bucketTargets[3]!));
      expect(conservative.bucketTargets[1]!, greaterThan(aggressive.bucketTargets[1]!));
    });

    test('mid-career moderate (age 40) gets balanced allocation', () {
      final strategy = BucketStrategyCalculator.compute(age: 40, riskProfile: 'Moderate', retirementAge: 60);
      expect(strategy.scenario, 'accumulation');
      expect(strategy.bucketTargets[3]!, greaterThanOrEqualTo(60.0));
      expect(strategy.bucketTargets[3]!, lessThanOrEqualTo(70.0));
      expect(strategy.bucketTargets[2]!, greaterThanOrEqualTo(20.0));
    });

    test('pre-retirement (age 55) shifts toward stability', () {
      final strategy = BucketStrategyCalculator.compute(age: 55, riskProfile: 'Moderate', retirementAge: 60);
      expect(strategy.scenario, 'accumulation');
      expect(strategy.bucketTargets[1]!, greaterThanOrEqualTo(15.0));
      expect(strategy.bucketTargets[2]!, greaterThanOrEqualTo(35.0));
      expect(strategy.corePct, 80.0);
      expect(strategy.satellitePct, 20.0);
    });

    test('retired member (age 65) gets distribution allocation', () {
      final strategy = BucketStrategyCalculator.compute(age: 65, riskProfile: 'Moderate', retirementAge: 60);
      expect(strategy.scenario, 'distribution');
      expect(strategy.bucketTargets[1]!, greaterThanOrEqualTo(20.0));
      expect(strategy.bucketTargets[2]!, greaterThanOrEqualTo(40.0));
      expect(strategy.bucketTargets[3]!, lessThanOrEqualTo(30.0));
      expect(strategy.corePct, 80.0);
    });

    test('aggressive retiree gets more growth than conservative retiree', () {
      final aggressive = BucketStrategyCalculator.compute(age: 65, riskProfile: 'Aggressive', retirementAge: 60);
      final conservative = BucketStrategyCalculator.compute(age: 65, riskProfile: 'Conservative', retirementAge: 60);
      expect(aggressive.bucketTargets[3]!, greaterThan(conservative.bucketTargets[3]!));
    });

    test('bucket targets always sum to 100', () {
      for (final age in [25, 30, 40, 50, 58, 62, 70, 80]) {
        for (final risk in ['Conservative', 'Moderate', 'Aggressive']) {
          final strategy = BucketStrategyCalculator.compute(age: age, riskProfile: risk, retirementAge: 60);
          final sum = strategy.bucketTargets.values.fold(0.0, (s, v) => s + v);
          expect(sum, closeTo(100.0, 0.1), reason: 'age=$age risk=$risk sum=$sum');
        }
      }
    });

    test('core + satellite always sums to 100', () {
      final strategy = BucketStrategyCalculator.compute(age: 35, riskProfile: 'Moderate', retirementAge: 60);
      expect(strategy.corePct + strategy.satellitePct, 100.0);
    });

    test('education notes populated for accumulation', () {
      final strategy = BucketStrategyCalculator.compute(age: 30, riskProfile: 'Moderate', retirementAge: 60);
      expect(strategy.educationNotes, isNotEmpty);
      expect(strategy.educationNotes.any((n) => n.contains('SIP')), isTrue);
    });

    test('education notes populated for distribution', () {
      final strategy = BucketStrategyCalculator.compute(age: 65, riskProfile: 'Moderate', retirementAge: 60);
      expect(strategy.educationNotes, isNotEmpty);
      expect(strategy.educationNotes.any((n) => n.contains('SWP')), isTrue);
    });
  });
}
