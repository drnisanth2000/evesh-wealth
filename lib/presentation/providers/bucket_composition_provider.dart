import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/asset_class_resolver.dart';
import '../../core/constants/asset_classes.dart';
import '../../core/constants/bucket_mapping.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/other_asset_model.dart';
import '../../data/models/portfolio_summary_model.dart';
import '../../domain/models/allocation_models.dart';
import 'auth_provider.dart';
import 'goal_provider.dart';
import 'other_assets_provider.dart';
import 'portfolio_provider.dart';
import 'wealth_planner_provider.dart';

part 'bucket_composition_provider.g.dart';

class BucketCompositionResult {
  final List<BucketComposition> buckets;
  final double totalValue;

  const BucketCompositionResult({
    required this.buckets,
    required this.totalValue,
  });

  BucketComposition bucket(Bucket b) =>
      buckets.firstWhere((bc) => bc.bucket == b);
}

class BucketComposition {
  final Bucket bucket;
  final double currentValue;
  final double currentPct;
  final double targetPct;
  final double gapPct; // currentPct - targetPct (positive = overweight)
  final double gapRupees; // currentValue - targetValue (positive = overweight)
  final List<HoldingLine> funds;
  final List<OtherAssetLine> otherAssets;
  final List<GoalAlert> goalAlerts;

  const BucketComposition({
    required this.bucket,
    required this.currentValue,
    required this.currentPct,
    required this.targetPct,
    required this.gapPct,
    required this.gapRupees,
    required this.funds,
    required this.otherAssets,
    required this.goalAlerts,
  });
}

class HoldingLine {
  final FundHoldingSummary holding;
  final Bucket effectiveBucket;
  final bool isOverridden; // true when transactions.bucket_override is set

  const HoldingLine({
    required this.holding,
    required this.effectiveBucket,
    required this.isOverridden,
  });
}

class OtherAssetLine {
  final OtherAssetModel asset;
  final Bucket effectiveBucket;
  final bool isOverridden;

  const OtherAssetLine({
    required this.asset,
    required this.effectiveBucket,
    required this.isOverridden,
  });
}

class GoalAlert {
  final String goalId;
  final String goalName;
  final DateTime targetDate;
  final int monthsAway;
  final int amfiCode;
  final String fundName;
  final Bucket currentBucket;

  const GoalAlert({
    required this.goalId,
    required this.goalName,
    required this.targetDate,
    required this.monthsAway,
    required this.amfiCode,
    required this.fundName,
    required this.currentBucket,
  });
}

@riverpod
Future<BucketCompositionResult> bucketComposition(
  BucketCompositionRef ref,
  String? memberId,
) async {
  // Fetch upstream sources concurrently for cache friendliness.
  final results = await Future.wait([
    ref.watch(portfolioSummaryProvider(memberId).future),
    ref.watch(otherAssetsProvider(memberId).future),
    ref.watch(allocationHealthProvider(memberId).future),
    ref.watch(goalsProvider.future),
    ref.watch(goalFundLinksProvider.future),
    ref.watch(fundBucketOverridesProvider.future),
  ]);

  return composeBuckets(
    portfolio: results[0] as PortfolioSummary,
    otherAssets: (results[1] as List).cast<OtherAssetModel>(),
    health: results[2] as AllocationHealthResult,
    goals: (results[3] as List).cast<GoalModel>(),
    links: (results[4] as List).cast<GoalFundLink>(),
    memberId: memberId,
    now: DateTime.now(),
    fundBucketOverrides: (results[5] as Map).cast<int, Bucket>(),
  );
}

/// Pulls the current user's `transactions.bucket_override` rows and folds them
/// into a per-AMFI map. The latest non-null override wins (we just take any).
@riverpod
Future<Map<int, Bucket>> fundBucketOverrides(
  FundBucketOverridesRef ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const {};
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('transactions')
      .select('amfi_code, bucket_override')
      .eq('owner_id', userId)
      .not('bucket_override', 'is', null);
  final map = <int, Bucket>{};
  for (final row in (response as List)) {
    final code = (row as Map)['amfi_code'];
    final override = row['bucket_override'] as String?;
    if (code is! int) continue;
    final bucket = bucketFromOverride(override);
    if (bucket == null) continue;
    map[code] = bucket;
  }
  return map;
}

/// Mutator: writes/clears `bucket_override` on transactions or other_assets
/// rows and invalidates dependent providers.
@riverpod
class BucketOverrideMutator extends _$BucketOverrideMutator {
  @override
  void build() {}

  Future<void> setForFund({
    required int amfiCode,
    required Bucket? bucket,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not signed in');
    }
    await client
        .from('transactions')
        .update({'bucket_override': bucket?.name})
        .eq('owner_id', userId)
        .eq('amfi_code', amfiCode);
    ref.invalidate(fundBucketOverridesProvider);
    ref.invalidate(bucketCompositionProvider);
    ref.invalidate(portfolioSummaryProvider);
  }

  Future<void> setForOtherAsset({
    required String id,
    required Bucket? bucket,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client
        .from('other_assets')
        .update({'bucket_override': bucket?.name})
        .eq('id', id);
    ref.invalidate(bucketCompositionProvider);
    ref.invalidate(otherAssetsProvider);
  }
}

/// Pure computation: given the four upstream snapshots, derives the 3-bucket
/// composition, including per-bucket totals, gaps, holdings, other assets,
/// and goal-approaching alerts. Tested directly without Riverpod overrides.
BucketCompositionResult composeBuckets({
  required PortfolioSummary portfolio,
  required List<OtherAssetModel> otherAssets,
  required AllocationHealthResult health,
  required List<GoalModel> goals,
  required List<GoalFundLink> links,
  required String? memberId,
  required DateTime now,
  Map<int, Bucket> fundBucketOverrides = const {},
}) {
  // 1. Bucket every fund holding.
  final fundsByBucket = <Bucket, List<HoldingLine>>{
    for (final b in Bucket.values) b: <HoldingLine>[],
  };
  for (final h in portfolio.fundHoldings) {
    final override = fundBucketOverrides[h.amfiCode];
    final bucket = override ??
        bucketFor(
          resolveAssetClass(
            amfiCategoryId: h.amfiCategoryId,
            assetClassLabel: h.assetClassLabel,
            category: h.category,
          ),
          TaxCategory.fromString(h.taxCategory),
        );
    fundsByBucket[bucket]!.add(HoldingLine(
      holding: h,
      effectiveBucket: bucket,
      isOverridden: override != null,
    ));
  }

  // 2. Bucket every other asset.
  final otherByBucket = <Bucket, List<OtherAssetLine>>{
    for (final b in Bucket.values) b: <OtherAssetLine>[],
  };
  for (final a in otherAssets) {
    final override = bucketFromOverride(a.bucketOverride);
    final bucket = override ?? _bucketForAsset(a);
    otherByBucket[bucket]!.add(OtherAssetLine(
      asset: a,
      effectiveBucket: bucket,
      isOverridden: override != null,
    ));
  }

  // 3. Goal alerts for goals < 12 months away whose linked fund sits outside Liquid.
  // Strict scoping: member view → that member's goals only; ALL view → family
  // goals only. Matches goal_landing_screen + plan_tab + goal_rail.
  final scopedGoals = memberId == null
      ? goals.where((g) => g.memberId == null).toList()
      : goals.where((g) => g.memberId == memberId).toList();
  final goalAlertsByBucket = <Bucket, List<GoalAlert>>{
    for (final b in Bucket.values) b: <GoalAlert>[],
  };
  for (final g in scopedGoals) {
    final target = DateTime.tryParse(g.targetDate);
    if (target == null) continue;
    final days = target.difference(now).inDays;
    if (days < 0 || days > 365) continue;
    final months = (days / 30.44).round();
    final goalLinks = links.where((l) => l.goalId == g.id);
    for (final link in goalLinks) {
      // Find the fund's bucket via the holdings we've already classified.
      HoldingLine? line;
      for (final entries in fundsByBucket.values) {
        for (final l in entries) {
          if (l.holding.amfiCode == link.amfiCode) {
            line = l;
            break;
          }
        }
        if (line != null) break;
      }
      if (line == null) continue;
      if (line.effectiveBucket == Bucket.liquid) continue; // already safe
      goalAlertsByBucket[line.effectiveBucket]!.add(GoalAlert(
        goalId: g.id,
        goalName: g.goalName,
        targetDate: target,
        monthsAway: months,
        amfiCode: link.amfiCode,
        fundName: line.holding.fundName,
        currentBucket: line.effectiveBucket,
      ));
    }
  }

  // 4. Per-bucket totals, gap math.
  final totalValue = portfolio.currentValue +
      otherAssets.fold<double>(0.0, (s, a) => s + a.effectiveValue);

  final targetPctByBucket = _targetPctByBucket(health);

  final list = <BucketComposition>[];
  for (final b in Bucket.values) {
    final fundValue = fundsByBucket[b]!
        .fold<double>(0.0, (s, l) => s + l.holding.currentValue);
    final otherValue = otherByBucket[b]!
        .fold<double>(0.0, (s, l) => s + l.asset.effectiveValue);
    final value = fundValue + otherValue;
    final currentPct = totalValue == 0 ? 0.0 : (value / totalValue) * 100.0;
    final targetPct = targetPctByBucket[b] ?? 0.0;
    final targetValue = totalValue * (targetPct / 100.0);
    list.add(BucketComposition(
      bucket: b,
      currentValue: value,
      currentPct: currentPct,
      targetPct: targetPct,
      gapPct: currentPct - targetPct,
      gapRupees: value - targetValue,
      funds: List.unmodifiable(fundsByBucket[b]!),
      otherAssets: List.unmodifiable(otherByBucket[b]!),
      goalAlerts: List.unmodifiable(goalAlertsByBucket[b]!),
    ));
  }

  return BucketCompositionResult(
    buckets: List.unmodifiable(list),
    totalValue: totalValue,
  );
}

/// Maps an `OtherAssetModel.assetType` (DB string like 'FD','PPF','SGB',
/// 'RealEstate') to the `AssetType` enum and then to a bucket. Falls back to
/// Growth on unrecognised types (matches `bucketForAssetType`'s semantics
/// for `other`).
Bucket _bucketForAsset(OtherAssetModel a) {
  AssetType type;
  try {
    type = AssetType.values.firstWhere((t) => t.dbValue == a.assetType);
  } catch (_) {
    type = AssetType.other;
  }
  // MF is impossible here (other_assets cannot be MF), but guard anyway.
  if (type == AssetType.mf) return Bucket.growth;
  return bucketForAssetType(type, subType: a.taxCategory);
}

/// Folds the 7-asset-class `AllocationHealthResult.idealAllocation` into the
/// 3-bucket target percentages.
///
/// Hybrid → Fixed Income at the *target* level is conservative. Individual
/// hybrid-E funds end up in Growth via `bucketFor`, so their *current* value
/// lands in Growth. This means current vs target for hybrid-heavy portfolios
/// will look slightly off — accepted v1 trade-off.
Map<Bucket, double> _targetPctByBucket(AllocationHealthResult health) {
  double sumFor(Iterable<String> keys) => keys.fold<double>(
        0.0,
        (s, k) => s + health.idealAllocation.idealForAssetClass(k),
      );
  return {
    Bucket.liquid: sumFor(['liquid']),
    Bucket.fixedIncome: sumFor(['debt', 'hybrid']),
    Bucket.growth: sumFor([
      'coreEquity',
      'satelliteEquity',
      'gold',
      'alternatives',
    ]),
  };
}
