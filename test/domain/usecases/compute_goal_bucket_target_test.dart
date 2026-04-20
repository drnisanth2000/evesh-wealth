import 'package:evesh_wealth/core/constants/bucket_mapping.dart';
import 'package:evesh_wealth/data/models/goal_model.dart';
import 'package:evesh_wealth/domain/models/allocation_models.dart';
import 'package:evesh_wealth/domain/usecases/compute_goal_bucket_target.dart';
import 'package:evesh_wealth/domain/usecases/compute_ideal_allocation.dart';
import 'package:flutter_test/flutter_test.dart';

GoalModel _goal(String dateIso) => GoalModel(
      id: 'g1',
      ownerId: 'o',
      familyId: 'f',
      goalName: 'Test',
      targetAmount: 1000000,
      targetDate: dateIso,
    );

IdealAllocation _ideal({String risk = 'Moderate', int age = 35}) =>
    IdealAllocationCalculator.compute(riskProfile: risk, age: age);

void main() {
  final now = DateTime(2026, 4, 19);

  group('computeGoalBucketTarget', () {
    test('short term (<3y) → 70 / 30 / 0', () {
      final target = now.add(const Duration(days: 365 * 2 + 200)); // ~2.55y
      final mix = computeGoalBucketTarget(_goal(target.toIso8601String()),
          _ideal(), now);
      expect(mix[Bucket.liquid], closeTo(70, 0.1));
      expect(mix[Bucket.fixedIncome], closeTo(30, 0.1));
      expect(mix[Bucket.growth], closeTo(0, 0.1));
    });

    test('medium term (3–7y) → 20 / 50 / 30', () {
      final target = now.add(const Duration(days: 365 * 5));
      final mix = computeGoalBucketTarget(_goal(target.toIso8601String()),
          _ideal(), now);
      expect(mix[Bucket.liquid], closeTo(20, 0.1));
      expect(mix[Bucket.fixedIncome], closeTo(50, 0.1));
      expect(mix[Bucket.growth], closeTo(30, 0.1));
    });

    test('long term (>=7y) → rolls up risk ideal into 3 buckets, sums to 100',
        () {
      final target = now.add(const Duration(days: 365 * 15));
      final mix = computeGoalBucketTarget(_goal(target.toIso8601String()),
          _ideal(), now);
      final total = mix.values.fold<double>(0, (s, v) => s + v);
      expect(total, closeTo(100, 0.5));
      // Moderate age 35 → growth bucket should dominate.
      expect(mix[Bucket.growth]!, greaterThan(mix[Bucket.fixedIncome]!));
      expect(mix[Bucket.growth]!, greaterThan(mix[Bucket.liquid]!));
    });

    test('rolling glide: <2y tilts toward liquid', () {
      final near = now.add(const Duration(days: 365));
      final mix = computeGoalBucketTarget(_goal(near.toIso8601String()),
          _ideal(), now);
      // At t=1y: blend of short (70/30/0) toward full-liquid.
      expect(mix[Bucket.liquid]!, greaterThan(70));
      expect(mix[Bucket.fixedIncome]!, lessThan(30));
      expect(mix[Bucket.growth], closeTo(0, 0.1));
    });

    test('rolling glide: t=0 → 100% liquid', () {
      final imminent = now.add(const Duration(days: 1));
      final mix = computeGoalBucketTarget(_goal(imminent.toIso8601String()),
          _ideal(), now);
      expect(mix[Bucket.liquid]!, greaterThan(99));
      expect(mix[Bucket.fixedIncome]!, lessThan(1));
      expect(mix[Bucket.growth]!, lessThan(1));
    });

    test('past target date → fully liquid fallback', () {
      final past = now.subtract(const Duration(days: 30));
      final mix = computeGoalBucketTarget(_goal(past.toIso8601String()),
          _ideal(), now);
      expect(mix[Bucket.liquid]!, greaterThan(99));
    });

    test('term boundary at ~3y — medium side', () {
      final target = now.add(const Duration(days: 365 * 3 + 30));
      final mix = computeGoalBucketTarget(_goal(target.toIso8601String()),
          _ideal(), now);
      expect(mix[Bucket.growth], closeTo(30, 0.1));
    });

    test('term boundary at ~7y — long side delegates to risk ideal', () {
      final target = now.add(const Duration(days: 365 * 7 + 30));
      final mix = computeGoalBucketTarget(_goal(target.toIso8601String()),
          _ideal(), now);
      // Long term: growth should exceed 30 (medium's max) for a Moderate-aged-35.
      expect(mix[Bucket.growth]!, greaterThan(30));
    });

    test('age 65+ (retirement glide floor) still produces valid mix', () {
      final target = now.add(const Duration(days: 365 * 15));
      final mix = computeGoalBucketTarget(_goal(target.toIso8601String()),
          _ideal(age: 65), now);
      final total = mix.values.fold<double>(0, (s, v) => s + v);
      expect(total, closeTo(100, 0.5));
      // Retirement glide still floors equity at 25 → growth stays positive.
      expect(mix[Bucket.growth]!, greaterThan(0));
    });
  });
}
