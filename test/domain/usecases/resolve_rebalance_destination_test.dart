import 'package:evesh_wealth/core/constants/bucket_mapping.dart';
import 'package:evesh_wealth/data/models/portfolio_summary_model.dart';
import 'package:evesh_wealth/domain/usecases/resolve_rebalance_destination.dart';
import 'package:evesh_wealth/presentation/providers/bucket_composition_provider.dart';
import 'package:flutter_test/flutter_test.dart';

HoldingLine _line({
  required int amfiCode,
  required String name,
  required double value,
  required Bucket bucket,
}) {
  return HoldingLine(
    holding: FundHoldingSummary(
      amfiCode: amfiCode,
      fundName: name,
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
  List<HoldingLine> funds = const [],
}) {
  return BucketComposition(
    bucket: bucket,
    currentValue: 0,
    currentPct: currentPct,
    targetPct: targetPct,
    gapPct: currentPct - targetPct,
    gapRupees: 0,
    funds: List.unmodifiable(funds),
    otherAssets: const [],
    goalAlerts: const [],
  );
}

BucketCompositionResult _result(List<BucketComposition> bs) =>
    BucketCompositionResult(buckets: List.unmodifiable(bs), totalValue: 100);

void main() {
  group('resolveReduceDestination', () {
    test('picks largest-held fund in the most underweight bucket', () {
      final composition = _result([
        _bc(bucket: Bucket.growth, currentPct: 80, targetPct: 60), // overweight
        _bc(
          bucket: Bucket.fixedIncome,
          currentPct: 10,
          targetPct: 30, // -20 underweight
          funds: [
            _line(amfiCode: 11, name: 'Small Debt', value: 5000, bucket: Bucket.fixedIncome),
            _line(amfiCode: 12, name: 'Big Debt', value: 50000, bucket: Bucket.fixedIncome),
          ],
        ),
        _bc(bucket: Bucket.liquid, currentPct: 10, targetPct: 10),
      ]);

      final dest = resolveReduceDestination(
        composition: composition,
        fromAmfiCode: 999,
      );

      expect(dest, isNotNull);
      expect(dest!.toAmfiCode, 12);
      expect(dest.toFundName, 'Big Debt');
      expect(dest.toBucket, Bucket.fixedIncome);
      expect(dest.parksInBank, isFalse);
    });

    test('all buckets at/above target → park in bank', () {
      final composition = _result([
        _bc(bucket: Bucket.growth, currentPct: 60, targetPct: 60),
        _bc(bucket: Bucket.fixedIncome, currentPct: 30, targetPct: 30),
        _bc(bucket: Bucket.liquid, currentPct: 10, targetPct: 10),
      ]);

      final dest = resolveReduceDestination(
        composition: composition,
        fromAmfiCode: 1,
      );

      expect(dest, isNotNull);
      expect(dest!.parksInBank, isTrue);
      expect(dest.toAmfiCode, isNull);
      expect(dest.toBucket, Bucket.liquid);
      expect(dest.toFundName, contains('Park in bank'));
    });

    test('underweight bucket has no holdings → park in that bucket, null amfi', () {
      final composition = _result([
        _bc(bucket: Bucket.growth, currentPct: 90, targetPct: 60),
        _bc(bucket: Bucket.fixedIncome, currentPct: 10, targetPct: 30),
        _bc(bucket: Bucket.liquid, currentPct: 0, targetPct: 10), // underweight, no funds
      ]);

      final dest = resolveReduceDestination(
        composition: composition,
        fromAmfiCode: 1,
      );

      expect(dest, isNotNull);
      // Most underweight is FI (-20) but it has no funds → falls into the
      // "no candidates" branch.
      expect(dest!.toAmfiCode, isNull);
      expect(dest.toBucket, Bucket.fixedIncome);
      expect(dest.toFundName, contains('Park in'));
    });

    test('skips the from-fund when picking destination', () {
      final composition = _result([
        _bc(bucket: Bucket.growth, currentPct: 80, targetPct: 60),
        _bc(
          bucket: Bucket.fixedIncome,
          currentPct: 10,
          targetPct: 30,
          funds: [
            // The largest-held fund IS the from-fund — must be skipped.
            _line(amfiCode: 42, name: 'Self', value: 100000, bucket: Bucket.fixedIncome),
            _line(amfiCode: 43, name: 'Other', value: 5000, bucket: Bucket.fixedIncome),
          ],
        ),
      ]);

      final dest = resolveReduceDestination(
        composition: composition,
        fromAmfiCode: 42,
      );

      expect(dest, isNotNull);
      expect(dest!.toAmfiCode, 43);
      expect(dest.toFundName, 'Other');
    });

    test('empty composition returns null', () {
      final dest = resolveReduceDestination(
        composition: _result(const []),
        fromAmfiCode: 1,
      );
      expect(dest, isNull);
    });

    test(
      'per-fund targets steer destination: fund with largest target-minus-current deficit wins',
      () {
        final composition = BucketCompositionResult(
          buckets: List.unmodifiable([
            _bc(
              bucket: Bucket.growth,
              currentPct: 80,
              targetPct: 60,
            ),
            _bc(
              bucket: Bucket.fixedIncome,
              currentPct: 10,
              targetPct: 30,
              funds: [
                _line(
                  amfiCode: 11,
                  name: 'Big Debt',
                  value: 50000, // current 50k
                  bucket: Bucket.fixedIncome,
                ),
                _line(
                  amfiCode: 12,
                  name: 'Small Debt',
                  value: 5000, // current 5k
                  bucket: Bucket.fixedIncome,
                ),
              ],
            ),
          ]),
          totalValue: 100000,
        );

        // User's Fund-tab sliders: Small Debt should grow to 40k (deficit 35k);
        // Big Debt stays at current (deficit 0). Resolver picks Small Debt.
        final dest = resolveReduceDestination(
          composition: composition,
          fromAmfiCode: 999,
          perFundTargets: const {11: 50000, 12: 40000},
        );

        expect(dest, isNotNull);
        expect(dest!.toAmfiCode, 12);
        expect(dest.toFundName, 'Small Debt');
        expect(dest.reason, contains('Fund-tab target'));
      },
    );

    test(
      'claimedByAmfi prevents piling every suggestion into the same fund',
      () {
        final composition = BucketCompositionResult(
          buckets: List.unmodifiable([
            _bc(
              bucket: Bucket.growth,
              currentPct: 80,
              targetPct: 60,
            ),
            _bc(
              bucket: Bucket.fixedIncome,
              currentPct: 10,
              targetPct: 30,
              funds: [
                _line(
                  amfiCode: 11,
                  name: 'Fund A',
                  value: 10000,
                  bucket: Bucket.fixedIncome,
                ),
                _line(
                  amfiCode: 12,
                  name: 'Fund B',
                  value: 10000,
                  bucket: Bucket.fixedIncome,
                ),
              ],
            ),
          ]),
          totalValue: 100000,
        );

        // User wants both funds to reach 60k (equal target).
        const targets = {11: 60000.0, 12: 60000.0};

        // First call: tied deficit; resolver's sort is stable so Fund A wins.
        final first = resolveReduceDestination(
          composition: composition,
          fromAmfiCode: 999,
          perFundTargets: targets,
        );
        expect(first!.toAmfiCode, anyOf(11, 12));
        final firstPick = first.toAmfiCode!;
        final secondPick = firstPick == 11 ? 12 : 11;

        // Second call: claimed pushes first pick near its target, so the
        // other fund now has the bigger deficit.
        final second = resolveReduceDestination(
          composition: composition,
          fromAmfiCode: 999,
          perFundTargets: targets,
          claimedByAmfi: {firstPick: 40000},
        );
        expect(second, isNotNull);
        expect(second!.toAmfiCode, secondPick,
            reason:
                'After claiming 40k into fund $firstPick, fund $secondPick should have the larger deficit');
      },
    );

    test(
      'fallback to largest-current when no fund is below its target',
      () {
        final composition = BucketCompositionResult(
          buckets: List.unmodifiable([
            _bc(
              bucket: Bucket.growth,
              currentPct: 80,
              targetPct: 60,
            ),
            _bc(
              bucket: Bucket.fixedIncome,
              currentPct: 10,
              targetPct: 30,
              funds: [
                _line(
                  amfiCode: 11,
                  name: 'Small',
                  value: 5000,
                  bucket: Bucket.fixedIncome,
                ),
                _line(
                  amfiCode: 12,
                  name: 'Big',
                  value: 50000,
                  bucket: Bucket.fixedIncome,
                ),
              ],
            ),
          ]),
          totalValue: 100000,
        );

        // Targets unset (or == current via no entries) → every deficit is 0
        // or negative → fallback to largest-current-value (Big).
        final dest = resolveReduceDestination(
          composition: composition,
          fromAmfiCode: 999,
        );
        expect(dest, isNotNull);
        expect(dest!.toAmfiCode, 12);
        expect(dest.toFundName, 'Big');
      },
    );
  });
}
