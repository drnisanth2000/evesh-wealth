import 'package:evesh_wealth/core/constants/bucket_mapping.dart';
import 'package:evesh_wealth/data/models/goal_model.dart';
import 'package:evesh_wealth/data/models/portfolio_summary_model.dart';
import 'package:evesh_wealth/domain/models/allocation_models.dart';
import 'package:evesh_wealth/domain/usecases/compute_goal_gap.dart';
import 'package:evesh_wealth/domain/usecases/compute_ideal_allocation.dart';
import 'package:flutter_test/flutter_test.dart';

GoalModel _goal({
  required String targetDate,
  double amount = 1000000,
  String? createdAt,
}) =>
    GoalModel(
      id: 'g1',
      ownerId: 'o',
      familyId: 'f',
      goalName: 'Down payment',
      targetAmount: amount,
      targetDate: targetDate,
      createdAt: createdAt,
    );

FundHoldingSummary _fund({
  required int amfi,
  required String name,
  required String category,
  required String taxCategory,
  required double value,
}) =>
    FundHoldingSummary(
      amfiCode: amfi,
      fundName: name,
      category: category,
      taxCategory: taxCategory,
      currentValue: value,
      totalInvested: value,
    );

IdealAllocation _ideal() =>
    IdealAllocationCalculator.compute(riskProfile: 'Moderate', age: 35);

void main() {
  final now = DateTime(2026, 4, 19);

  group('computeGoalGap', () {
    test('zero linked funds with time elapsed → behind', () {
      // 7y goal created 2y ago → medium-term (5y out), 29% elapsed.
      // Zero current → 0% of expected → behind.
      final created = now.subtract(const Duration(days: 365 * 2));
      final target = now.add(const Duration(days: 365 * 5 + 30));
      final g = _goal(
        targetDate: target.toIso8601String(),
        createdAt: created.toIso8601String(),
      );
      final r = computeGoalGap(
        goal: g,
        linkedFunds: const [],
        linkedOtherAssets: const [],
        riskIdeal: _ideal(),
        now: now,
      );
      expect(r.currentTotal, 0);
      expect(r.overallProgressPct, 0);
      // Medium mix 20/50/30 → all three targets non-zero → all deficient.
      expect(r.perBucket[Bucket.liquid]!.gapRupees, lessThan(0));
      expect(r.perBucket[Bucket.fixedIncome]!.gapRupees, lessThan(0));
      expect(r.perBucket[Bucket.growth]!.gapRupees, lessThan(0));
      expect(r.status, GoalStatus.behind);
    });

    test('over-funded goal → achieved', () {
      final g = _goal(
        targetDate: now.add(const Duration(days: 365 * 5)).toIso8601String(),
        amount: 500000,
      );
      final r = computeGoalGap(
        goal: g,
        linkedFunds: [
          _fund(
              amfi: 1,
              name: 'Liq',
              category: 'liquid',
              taxCategory: 'debt',
              value: 600000),
        ],
        linkedOtherAssets: const [],
        riskIdeal: _ideal(),
        now: now,
      );
      expect(r.status, GoalStatus.achieved);
      expect(r.currentTotal, 600000);
    });

    test('under-funded but early in timeline → onTrack (90% of expected)', () {
      // 10y goal, created 1y ago (10% elapsed). Expected = 10% of target.
      // Current = 15% of target → 150% of expected → onTrack.
      final created = now.subtract(const Duration(days: 365));
      final target = now.add(const Duration(days: 365 * 9));
      final g = _goal(
        targetDate: target.toIso8601String(),
        amount: 1000000,
        createdAt: created.toIso8601String(),
      );
      final r = computeGoalGap(
        goal: g,
        linkedFunds: [
          _fund(
              amfi: 1,
              name: 'Eq',
              category: 'core equity',
              taxCategory: 'equity',
              value: 150000),
        ],
        linkedOtherAssets: const [],
        riskIdeal: _ideal(),
        now: now,
      );
      expect(r.status, GoalStatus.onTrack);
    });

    test('split across buckets attributes current to the correct bucket', () {
      final g = _goal(
        targetDate: now.add(const Duration(days: 365 * 5)).toIso8601String(),
        amount: 1000000,
      );
      final r = computeGoalGap(
        goal: g,
        linkedFunds: [
          _fund(
              amfi: 1,
              name: 'Liq',
              category: 'liquid',
              taxCategory: 'debt',
              value: 100000),
          _fund(
              amfi: 2,
              name: 'Debt',
              category: 'debt',
              taxCategory: 'debt',
              value: 200000),
          _fund(
              amfi: 3,
              name: 'Eq',
              category: 'core equity',
              taxCategory: 'equity',
              value: 300000),
        ],
        linkedOtherAssets: const [],
        riskIdeal: _ideal(),
        now: now,
      );
      expect(r.perBucket[Bucket.liquid]!.currentValue, 100000);
      expect(r.perBucket[Bucket.fixedIncome]!.currentValue, 200000);
      expect(r.perBucket[Bucket.growth]!.currentValue, 300000);
      expect(r.currentTotal, 600000);
    });

    test('gapPct = gapRupees / targetValue * 100; 0 when target=0', () {
      // Short-term goal so Growth target = 0.
      final g = _goal(
        targetDate: now.add(const Duration(days: 400)).toIso8601String(),
        amount: 100000,
      );
      final r = computeGoalGap(
        goal: g,
        linkedFunds: [
          _fund(
              amfi: 3,
              name: 'Eq',
              category: 'core equity',
              taxCategory: 'equity',
              value: 10000),
        ],
        linkedOtherAssets: const [],
        riskIdeal: _ideal(),
        now: now,
      );
      // Growth target is 0 for this short-term goal → gapPct is 0 by contract.
      expect(r.perBucket[Bucket.growth]!.targetValue, 0);
      expect(r.perBucket[Bucket.growth]!.gapPct, 0);
      // But current is still 10000 (excess).
      expect(r.perBucket[Bucket.growth]!.gapRupees, 10000);
    });
  });
}
