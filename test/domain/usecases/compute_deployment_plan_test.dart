import 'package:evesh_wealth/core/constants/bucket_mapping.dart';
import 'package:evesh_wealth/data/models/portfolio_summary_model.dart';
import 'package:evesh_wealth/domain/usecases/compute_deployment_plan.dart';
import 'package:evesh_wealth/presentation/providers/bucket_composition_provider.dart';
import 'package:flutter_test/flutter_test.dart';

HoldingLine _holding({
  required int amfiCode,
  required String name,
  required String category,
  required double value,
  required Bucket bucket,
}) {
  return HoldingLine(
    holding: FundHoldingSummary(
      amfiCode: amfiCode,
      fundName: name,
      category: category,
      taxCategory: 'equity',
      currentValue: value,
      totalInvested: value,
    ),
    effectiveBucket: bucket,
    isOverridden: false,
  );
}

BucketComposition _bc({
  required Bucket bucket,
  required double currentPct,
  required double targetPct,
  required double currentValue,
  List<HoldingLine> funds = const [],
}) {
  return BucketComposition(
    bucket: bucket,
    currentValue: currentValue,
    currentPct: currentPct,
    targetPct: targetPct,
    gapPct: currentPct - targetPct,
    gapRupees: 0,
    funds: funds,
    otherAssets: const [],
    goalAlerts: const [],
  );
}

BucketCompositionResult _result(List<BucketComposition> bs) =>
    BucketCompositionResult(buckets: bs, totalValue: 100000);

void main() {
  group('computeDeploymentPlan', () {
    test('empty input → empty plan', () {
      final plan = computeDeploymentPlan(
        lumpsum: 0,
        sip: 0,
        splitPct: 50,
        composition: _result(const []),
      );
      expect(plan.buckets, isEmpty);
      expect(plan.totalLumpsum, 0);
      expect(plan.totalSip, 0);
    });

    test('Liquid (-5%) and Growth (-10%) → Growth gets 2x Liquid allocation',
        () {
      final composition = _result([
        _bc(
          bucket: Bucket.liquid,
          currentPct: 5,
          targetPct: 10,
          currentValue: 5000,
          funds: [
            _holding(
                amfiCode: 1,
                name: 'Liq A',
                category: 'liquid',
                value: 5000,
                bucket: Bucket.liquid),
          ],
        ),
        _bc(
          bucket: Bucket.fixedIncome,
          currentPct: 30,
          targetPct: 30,
          currentValue: 30000,
        ),
        _bc(
          bucket: Bucket.growth,
          currentPct: 50,
          targetPct: 60,
          currentValue: 50000,
          funds: [
            _holding(
                amfiCode: 2,
                name: 'Growth A',
                category: 'core equity',
                value: 50000,
                bucket: Bucket.growth),
          ],
        ),
      ]);

      final plan = computeDeploymentPlan(
        lumpsum: 30000,
        sip: 0,
        splitPct: 100,
        composition: composition,
      );

      expect(plan.buckets.length, 2);
      final liq = plan.buckets.firstWhere((b) => b.bucket == Bucket.liquid);
      final grw = plan.buckets.firstWhere((b) => b.bucket == Bucket.growth);
      expect(grw.totalAmount, closeTo(liq.totalAmount * 2, 0.01));
      // Sum equals combined (= lumpsum since sip=0)
      expect(liq.totalAmount + grw.totalAmount, closeTo(30000, 0.01));
    });

    test('all balanced → fallback proportional to targetPct', () {
      final composition = _result([
        _bc(
          bucket: Bucket.liquid,
          currentPct: 10,
          targetPct: 10,
          currentValue: 10000,
          funds: [
            _holding(
                amfiCode: 1,
                name: 'L',
                category: 'liquid',
                value: 10000,
                bucket: Bucket.liquid),
          ],
        ),
        _bc(
          bucket: Bucket.growth,
          currentPct: 90,
          targetPct: 90,
          currentValue: 90000,
          funds: [
            _holding(
                amfiCode: 2,
                name: 'G',
                category: 'core equity',
                value: 90000,
                bucket: Bucket.growth),
          ],
        ),
      ]);

      final plan = computeDeploymentPlan(
        lumpsum: 10000,
        sip: 0,
        splitPct: 100,
        composition: composition,
      );

      expect(plan.buckets.length, 2);
      final liq = plan.buckets.firstWhere((b) => b.bucket == Bucket.liquid);
      final grw = plan.buckets.firstWhere((b) => b.bucket == Bucket.growth);
      // 10% vs 90% → 9x.
      expect(grw.totalAmount, closeTo(liq.totalAmount * 9, 0.01));
    });

    test('SIP-only (lumpsum=0, splitPct=0): all lumpsum=0, all sip>0', () {
      final composition = _result([
        _bc(
          bucket: Bucket.growth,
          currentPct: 50,
          targetPct: 60,
          currentValue: 50000,
          funds: [
            _holding(
                amfiCode: 2,
                name: 'G',
                category: 'core equity',
                value: 50000,
                bucket: Bucket.growth),
          ],
        ),
      ]);

      final plan = computeDeploymentPlan(
        lumpsum: 0,
        sip: 10000,
        splitPct: 0,
        composition: composition,
      );

      expect(plan.buckets, isNotEmpty);
      for (final b in plan.buckets) {
        for (final l in b.lines) {
          expect(l.lumpsum, 0);
          expect(l.sip, greaterThan(0));
        }
      }
    });

    test('Bucket with no holdings emits a placeholder line', () {
      final composition = _result([
        _bc(
          bucket: Bucket.liquid,
          currentPct: 0,
          targetPct: 10,
          currentValue: 0,
          funds: const [],
        ),
      ]);

      final plan = computeDeploymentPlan(
        lumpsum: 1000,
        sip: 0,
        splitPct: 100,
        composition: composition,
      );

      expect(plan.buckets.length, 1);
      expect(plan.buckets.first.lines.length, 1);
      expect(plan.buckets.first.lines.first.isPlaceholder, isTrue);
      expect(plan.buckets.first.lines.first.amfiCode, isNull);
    });

    test('empty-bucket placeholder leaves fundName blank for UI to resolve',
        () {
      final composition = _result([
        _bc(
          bucket: Bucket.growth,
          currentPct: 0,
          targetPct: 60,
          currentValue: 0,
          funds: const [],
        ),
      ]);

      final plan = computeDeploymentPlan(
        lumpsum: 5000,
        sip: 0,
        splitPct: 100,
        composition: composition,
      );

      final line = plan.buckets.first.lines.first;
      expect(line.isPlaceholder, isTrue);
      expect(line.fundName, isEmpty);
      expect(line.amfiCode, isNull);
      // Asset-class label is preserved for FundSearchDropdown filtering.
      expect(line.assetClassLabel, 'Growth');
      expect(line.lumpsum, closeTo(5000, 0.01));
    });
  });
}
