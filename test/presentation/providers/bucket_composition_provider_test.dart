import 'package:evesh_wealth/core/constants/bucket_mapping.dart';
import 'package:evesh_wealth/data/models/goal_model.dart';
import 'package:evesh_wealth/data/models/other_asset_model.dart';
import 'package:evesh_wealth/data/models/portfolio_summary_model.dart';
import 'package:evesh_wealth/domain/models/allocation_models.dart';
import 'package:evesh_wealth/presentation/providers/bucket_composition_provider.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Synthetic-data builders ──────────────────────────────────────────────────

FundHoldingSummary _fund({
  required int amfiCode,
  required String name,
  required String category,
  required String taxCategory,
  required double currentValue,
}) {
  return FundHoldingSummary(
    amfiCode: amfiCode,
    fundName: name,
    category: category,
    taxCategory: taxCategory,
    currentValue: currentValue,
    totalInvested: currentValue,
  );
}

OtherAssetModel _otherAsset({
  required String id,
  required String assetType,
  required double currentValue,
  String? bucketOverride,
  String? taxCategory,
}) {
  return OtherAssetModel(
    id: id,
    ownerId: 'owner1',
    assetType: assetType,
    description: '$assetType $id',
    currentValue: currentValue,
    bucketOverride: bucketOverride,
    taxCategory: taxCategory,
    createdAt: '2026-01-01T00:00:00Z',
  );
}

/// Build an `IdealAllocation` with the given target percentages per
/// asset-class key. Wraps the result in an `AllocationHealthResult` shell
/// (the rest of the fields aren't read by `composeBuckets`).
AllocationHealthResult _healthFor(Map<String, double> targets) {
  final subBuckets = [
    for (final e in targets.entries)
      SubBucketTarget(
        name: e.key,
        parentBucket: e.key,
        minPct: e.value,
        maxPct: e.value,
        idealPct: e.value,
      ),
  ];
  final ideal = IdealAllocation(
    riskProfile: 'Moderate',
    age: 35,
    corePct: 0,
    satellitePct: 0,
    subBuckets: subBuckets,
  );
  return AllocationHealthResult(
    healthScore: 0,
    healthLabel: 'Good',
    idealAllocation: ideal,
    currentAllocation: const {},
    driftAlerts: const [],
    nudges: const [],
  );
}

PortfolioSummary _portfolio(List<FundHoldingSummary> holdings) {
  final total = holdings.fold<double>(0.0, (s, h) => s + h.currentValue);
  return PortfolioSummary(
    currentValue: total,
    totalInvested: total,
    fundHoldings: holdings,
  );
}

GoalModel _goal({
  required String id,
  required String name,
  required DateTime targetDate,
  String? memberId,
}) {
  return GoalModel(
    id: id,
    ownerId: 'owner1',
    familyId: 'fam1',
    memberId: memberId,
    goalName: name,
    targetAmount: 100000.0,
    targetDate: targetDate.toIso8601String().substring(0, 10),
  );
}

void main() {
  // Frozen "now" so date-based assertions are deterministic.
  final now = DateTime(2026, 4, 18);

  group('composeBuckets — math & classification', () {
    test('happy path: 1 equity fund + 1 PPF + 60/30/10 ideal', () {
      final portfolio = _portfolio([
        _fund(
          amfiCode: 100,
          name: 'Nifty 50 Index',
          category: 'Core Equity',
          taxCategory: 'Equity',
          currentValue: 100000,
        ),
      ]);
      final others = [
        _otherAsset(id: 'ppf1', assetType: 'PPF', currentValue: 50000),
      ];
      final health = _healthFor({
        'coreEquity': 60.0,
        'debt': 30.0,
        'liquid': 10.0,
      });

      final r = composeBuckets(
        portfolio: portfolio,
        otherAssets: others,
        health: health,
        goals: const [],
        links: const [],
        memberId: null,
        now: now,
      );

      expect(r.totalValue, closeTo(150000.0, 0.01));

      final growth = r.bucket(Bucket.growth);
      expect(growth.currentValue, closeTo(100000.0, 0.01));
      expect(growth.currentPct, closeTo(66.6667, 0.01));
      expect(growth.targetPct, closeTo(60.0, 0.01));
      expect(growth.gapPct, closeTo(6.6667, 0.01));
      expect(growth.funds, hasLength(1));
      expect(growth.otherAssets, isEmpty);

      final fi = r.bucket(Bucket.fixedIncome);
      expect(fi.currentValue, closeTo(50000.0, 0.01));
      expect(fi.currentPct, closeTo(33.3333, 0.01));
      expect(fi.targetPct, closeTo(30.0, 0.01));
      expect(fi.otherAssets, hasLength(1));

      final liq = r.bucket(Bucket.liquid);
      expect(liq.currentValue, 0.0);
      expect(liq.targetPct, closeTo(10.0, 0.01));
      // target value = 150_000 * 10% = 15_000 → gapRupees = 0 - 15_000 = -15_000
      expect(liq.gapRupees, closeTo(-15000.0, 0.01));
    });

    test('hybrid-E fund lands in Growth (current value side)', () {
      final portfolio = _portfolio([
        _fund(
          amfiCode: 200,
          name: 'BAF',
          category: 'Hybrid',
          taxCategory: 'Hybrid-E',
          currentValue: 75000,
        ),
      ]);
      final r = composeBuckets(
        portfolio: portfolio,
        otherAssets: const [],
        health: _healthFor({'coreEquity': 100.0}),
        goals: const [],
        links: const [],
        memberId: null,
        now: now,
      );
      expect(r.bucket(Bucket.growth).currentValue, 75000.0);
      expect(r.bucket(Bucket.fixedIncome).currentValue, 0.0);
    });

    test('bucket_override on other asset wins over auto-mapping', () {
      // PPF would normally be Fixed Income; override → Liquid.
      final others = [
        _otherAsset(
          id: 'ppf-override',
          assetType: 'PPF',
          currentValue: 25000,
          bucketOverride: 'liquid',
        ),
      ];
      final r = composeBuckets(
        portfolio: _portfolio(const []),
        otherAssets: others,
        health: _healthFor({'liquid': 100.0}),
        goals: const [],
        links: const [],
        memberId: null,
        now: now,
      );
      expect(r.bucket(Bucket.liquid).currentValue, 25000.0);
      expect(r.bucket(Bucket.fixedIncome).currentValue, 0.0);
      final liqLine = r.bucket(Bucket.liquid).otherAssets.single;
      expect(liqLine.isOverridden, isTrue);
      expect(liqLine.effectiveBucket, Bucket.liquid);
    });

    test('composeBuckets respects fundBucketOverrides', () {
      // Equity fund would auto-bucket to Growth. Override forces it to Liquid.
      final equityFund = _fund(
        amfiCode: 999,
        name: 'Flexi Cap (override → liquid)',
        category: 'Core Equity',
        taxCategory: 'Equity',
        currentValue: 80000,
      );
      final r = composeBuckets(
        portfolio: _portfolio([equityFund]),
        otherAssets: const [],
        health: _healthFor({'liquid': 100.0}),
        goals: const [],
        links: const [],
        memberId: null,
        now: now,
        fundBucketOverrides: const {999: Bucket.liquid},
      );
      final liq = r.bucket(Bucket.liquid);
      expect(liq.currentValue, 80000.0);
      expect(liq.funds, hasLength(1));
      expect(liq.funds.single.isOverridden, isTrue);
      expect(liq.funds.single.effectiveBucket, Bucket.liquid);
      expect(r.bucket(Bucket.growth).currentValue, 0.0);
    });

    test('empty portfolio + empty other assets → 0 totals, targets still set', () {
      final r = composeBuckets(
        portfolio: _portfolio(const []),
        otherAssets: const [],
        health: _healthFor({
          'coreEquity': 60.0,
          'debt': 30.0,
          'liquid': 10.0,
        }),
        goals: const [],
        links: const [],
        memberId: null,
        now: now,
      );
      expect(r.totalValue, 0.0);
      for (final b in Bucket.values) {
        expect(r.bucket(b).currentValue, 0.0);
        expect(r.bucket(b).currentPct, 0.0);
        expect(r.bucket(b).gapRupees, 0.0); // 0 - (0 * targetPct) = 0
      }
      expect(r.bucket(Bucket.growth).targetPct, closeTo(60.0, 0.01));
      expect(r.bucket(Bucket.fixedIncome).targetPct, closeTo(30.0, 0.01));
      expect(r.bucket(Bucket.liquid).targetPct, closeTo(10.0, 0.01));
    });
  });

  group('composeBuckets — goal alerts', () {
    test('goal 6 months out, fund in Growth → alert on Growth bucket', () {
      final equityFund = _fund(
        amfiCode: 300,
        name: 'Flexi Cap',
        category: 'Core Equity',
        taxCategory: 'Equity',
        currentValue: 200000,
      );
      final goal = _goal(
        id: 'g1',
        name: 'Car',
        targetDate: now.add(const Duration(days: 183)), // ~6 months
      );
      const link = GoalFundLink(
        id: 'gl1',
        ownerId: 'owner1',
        goalId: 'g1',
        amfiCode: 300,
      );

      final r = composeBuckets(
        portfolio: _portfolio([equityFund]),
        otherAssets: const [],
        health: _healthFor({'coreEquity': 100.0}),
        goals: [goal],
        links: [link],
        memberId: null,
        now: now,
      );
      final alerts = r.bucket(Bucket.growth).goalAlerts;
      expect(alerts, hasLength(1));
      expect(alerts.single.goalId, 'g1');
      expect(alerts.single.amfiCode, 300);
      expect(alerts.single.currentBucket, Bucket.growth);
      // 183 / 30.44 ≈ 6.01 → rounded to 6
      expect(alerts.single.monthsAway, 6);
      // No alert on the other buckets.
      expect(r.bucket(Bucket.liquid).goalAlerts, isEmpty);
      expect(r.bucket(Bucket.fixedIncome).goalAlerts, isEmpty);
    });

    test('goal already in Liquid → no alert (already safe)', () {
      final liqFund = _fund(
        amfiCode: 400,
        name: 'Liquid Fund',
        category: 'Liquid',
        taxCategory: 'Debt',
        currentValue: 50000,
      );
      final goal = _goal(
        id: 'g2',
        name: 'Vacation',
        targetDate: now.add(const Duration(days: 90)),
      );
      const link = GoalFundLink(
        id: 'gl2',
        ownerId: 'owner1',
        goalId: 'g2',
        amfiCode: 400,
      );
      final r = composeBuckets(
        portfolio: _portfolio([liqFund]),
        otherAssets: const [],
        health: _healthFor({'liquid': 100.0}),
        goals: [goal],
        links: [link],
        memberId: null,
        now: now,
      );
      for (final b in Bucket.values) {
        expect(r.bucket(b).goalAlerts, isEmpty);
      }
    });

    test('goal more than 12 months out → no alert', () {
      final equityFund = _fund(
        amfiCode: 500,
        name: 'Equity',
        category: 'Core Equity',
        taxCategory: 'Equity',
        currentValue: 100000,
      );
      final goal = _goal(
        id: 'g3',
        name: 'House',
        targetDate: now.add(const Duration(days: 400)),
      );
      const link = GoalFundLink(
        id: 'gl3',
        ownerId: 'owner1',
        goalId: 'g3',
        amfiCode: 500,
      );
      final r = composeBuckets(
        portfolio: _portfolio([equityFund]),
        otherAssets: const [],
        health: _healthFor({'coreEquity': 100.0}),
        goals: [goal],
        links: [link],
        memberId: null,
        now: now,
      );
      for (final b in Bucket.values) {
        expect(r.bucket(b).goalAlerts, isEmpty);
      }
    });
  });
}
