import '../../core/constants/bucket_mapping.dart';
import '../../data/models/goal_model.dart';
import '../models/allocation_models.dart';

/// Derives the target 3-bucket mix for a single goal.
///
/// Rule matrix (user-confirmed):
/// - **Short** (<3y to target): 70 Liquid / 30 FI / 0 Growth.
/// - **Medium** (3–7y): 20 / 50 / 30.
/// - **Long** (>=7y): risk-profile ideal rolled up to 3 buckets.
///
/// Rolling glide: when the goal is <2y away, linearly blend the short-term
/// mix into a fully-liquid mix so money is pulled out of equity/debt risk as
/// the target date approaches. At t=2y: 70/30/0. At t=0: 100/0/0.
Map<Bucket, double> computeGoalBucketTarget(
  GoalModel goal,
  IdealAllocation riskIdeal,
  DateTime now,
) {
  final target = DateTime.tryParse(goal.targetDate);
  if (target == null) {
    return const {Bucket.liquid: 100, Bucket.fixedIncome: 0, Bucket.growth: 0};
  }
  final years = target.difference(now).inDays / 365.25;

  Map<Bucket, double> base;
  if (years >= 7) {
    base = _longTermFromRiskIdeal(riskIdeal);
  } else if (years >= 3) {
    base = {Bucket.liquid: 20, Bucket.fixedIncome: 50, Bucket.growth: 30};
  } else {
    base = {Bucket.liquid: 70, Bucket.fixedIncome: 30, Bucket.growth: 0};
  }

  // Rolling glide inside the last 2y: blend toward fully-liquid.
  if (years < 2) {
    final t = (years / 2).clamp(0.0, 1.0);
    final liquidBase = base[Bucket.liquid] ?? 0;
    final fiBase = base[Bucket.fixedIncome] ?? 0;
    final growthBase = base[Bucket.growth] ?? 0;
    base = {
      Bucket.liquid: liquidBase + (100 - liquidBase) * (1 - t),
      Bucket.fixedIncome: fiBase * t,
      Bucket.growth: growthBase * t,
    };
  }

  return _normalise(base);
}

Map<Bucket, double> _longTermFromRiskIdeal(IdealAllocation ideal) {
  double sumFor(Iterable<String> keys) => keys.fold<double>(
        0.0,
        (s, k) => s + ideal.idealForAssetClass(k),
      );
  return {
    Bucket.liquid: sumFor(['liquid']),
    Bucket.fixedIncome: sumFor(['debt', 'hybrid']),
    Bucket.growth: sumFor(['coreEquity', 'satelliteEquity', 'gold', 'alternatives']),
  };
}

Map<Bucket, double> _normalise(Map<Bucket, double> m) {
  final total = m.values.fold<double>(0.0, (s, v) => s + v);
  if (total <= 0) {
    return const {Bucket.liquid: 100, Bucket.fixedIncome: 0, Bucket.growth: 0};
  }
  return {for (final e in m.entries) e.key: e.value / total * 100};
}
