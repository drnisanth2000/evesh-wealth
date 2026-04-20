import '../../core/constants/asset_class_resolver.dart';
import '../../core/constants/asset_classes.dart';
import '../../core/constants/bucket_mapping.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/other_asset_model.dart';
import '../../data/models/portfolio_summary_model.dart';
import '../models/allocation_models.dart';
import 'compute_goal_bucket_target.dart';

/// Per-bucket deficit/excess for a goal: positive gap = excess vs target,
/// negative gap = deficit.
class BucketGap {
  final Bucket bucket;
  final double currentValue;
  final double targetValue;
  final double gapRupees; // currentValue - targetValue
  final double gapPct;    // gapRupees / targetValue * 100 (0 when target=0)

  const BucketGap({
    required this.bucket,
    required this.currentValue,
    required this.targetValue,
    required this.gapRupees,
    required this.gapPct,
  });
}

enum GoalStatus { achieved, onTrack, watch, behind }

class GoalGapResult {
  final String goalId;
  final Map<Bucket, BucketGap> perBucket;
  final double currentTotal;
  final double targetTotal;
  final double overallProgressPct;
  final GoalStatus status;

  const GoalGapResult({
    required this.goalId,
    required this.perBucket,
    required this.currentTotal,
    required this.targetTotal,
    required this.overallProgressPct,
    required this.status,
  });
}

/// Pure: computes per-bucket deficit/excess for [goal] given its linked
/// funds + other assets + the user's risk-profile ideal (used by long-term
/// goals). Status logic mirrors `_ProgressBlock` on the Goals landing screen
/// (linear time-elapsed expectation with 10% slack).
GoalGapResult computeGoalGap({
  required GoalModel goal,
  required List<FundHoldingSummary> linkedFunds,
  required List<OtherAssetModel> linkedOtherAssets,
  required IdealAllocation riskIdeal,
  required DateTime now,
}) {
  final currentByBucket = <Bucket, double>{
    for (final b in Bucket.values) b: 0.0,
  };

  for (final f in linkedFunds) {
    final bucket = bucketFor(
      resolveAssetClass(
        amfiCategoryId: f.amfiCategoryId,
        assetClassLabel: f.assetClassLabel,
        category: f.category,
      ),
      TaxCategory.fromString(f.taxCategory),
    );
    currentByBucket[bucket] = (currentByBucket[bucket] ?? 0) + f.currentValue;
  }

  for (final a in linkedOtherAssets) {
    final override = bucketFromOverride(a.bucketOverride);
    final bucket = override ?? _bucketForOther(a);
    currentByBucket[bucket] = (currentByBucket[bucket] ?? 0) + a.effectiveValue;
  }

  final targetPctByBucket = computeGoalBucketTarget(goal, riskIdeal, now);
  final target = goal.targetAmount;

  final perBucket = <Bucket, BucketGap>{};
  for (final b in Bucket.values) {
    final current = currentByBucket[b] ?? 0;
    final targetPct = targetPctByBucket[b] ?? 0;
    final targetValue = target * (targetPct / 100.0);
    final gapRupees = current - targetValue;
    final gapPct = targetValue == 0 ? 0.0 : (gapRupees / targetValue) * 100.0;
    perBucket[b] = BucketGap(
      bucket: b,
      currentValue: current,
      targetValue: targetValue,
      gapRupees: gapRupees,
      gapPct: gapPct,
    );
  }

  final currentTotal =
      currentByBucket.values.fold<double>(0.0, (s, v) => s + v);
  final overallPct =
      target == 0 ? 0.0 : (currentTotal / target * 100).clamp(0.0, 999.0);

  return GoalGapResult(
    goalId: goal.id,
    perBucket: perBucket,
    currentTotal: currentTotal,
    targetTotal: target,
    overallProgressPct: overallPct.toDouble(),
    status: goalStatusFor(goal, currentTotal, now),
  );
}

/// Canonical status rule reused by every surface that renders a goal —
/// Goals page, Plan tab, Goal Rail. Keeps labels + colours consistent so the
/// same goal never reads "On track" on one screen and "Behind" on another.
///
/// Thresholds:
/// - `current >= targetAmount` → achieved
/// - `current >= expected * 0.9` → onTrack (10% slack)
/// - `current >= expected * 0.7` → watch
/// - otherwise → behind
/// where `expected = targetAmount * timeElapsed/totalDays`.
GoalStatus goalStatusFor(GoalModel goal, double current, DateTime now) {
  if (current >= goal.targetAmount && goal.targetAmount > 0) {
    return GoalStatus.achieved;
  }
  final created = DateTime.tryParse(goal.createdAt ?? '') ?? now;
  final totalDays = goal.targetDateTime.difference(created).inDays;
  if (totalDays <= 0) {
    return current >= goal.targetAmount ? GoalStatus.onTrack : GoalStatus.behind;
  }
  final elapsed = now.difference(created).inDays;
  final timeFrac = (elapsed / totalDays).clamp(0.0, 1.0);
  final expected = goal.targetAmount * timeFrac;
  if (current >= expected * 0.9) return GoalStatus.onTrack;
  if (current >= expected * 0.7) return GoalStatus.watch;
  return GoalStatus.behind;
}

Bucket _bucketForOther(OtherAssetModel a) {
  AssetType type;
  try {
    type = AssetType.values.firstWhere((t) => t.dbValue == a.assetType);
  } catch (_) {
    type = AssetType.other;
  }
  if (type == AssetType.mf) return Bucket.growth;
  return bucketForAssetType(type, subType: a.taxCategory);
}
