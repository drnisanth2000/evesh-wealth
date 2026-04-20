import '../../core/constants/bucket_mapping.dart';
import '../../presentation/providers/bucket_composition_provider.dart';

/// A resolved destination for a "reduce" rebalance suggestion.
///
/// When [toAmfiCode] is non-null, the redemption should be wired as a
/// **switch** into [toFundName] (which sits in [toBucket]). When null, the
/// user has no underweight fund to switch into and the redemption is parked
/// in the bank (Liquid bucket).
class RebalanceDestination {
  final int? toAmfiCode;
  final String toFundName;
  final Bucket toBucket;
  final String reason;

  const RebalanceDestination({
    required this.toAmfiCode,
    required this.toFundName,
    required this.toBucket,
    required this.reason,
  });

  bool get parksInBank => toAmfiCode == null;
}

/// Picks a destination fund for a "reduce" suggestion.
///
/// Algorithm:
/// 1. Find the most underweight bucket (largest negative `gapPct`).
/// 2. For each candidate fund in that bucket (excluding [fromAmfiCode]):
///    - `target = perFundTargets[amfi] ?? currentValue`. The user's Asset
///      Allocation → Fund slider (persisted in `simulationStateProvider
///      (memberId).fundAmounts`) is the authoritative per-fund target. If
///      unset, the fund stays at its current value (deficit = 0).
///    - `deficit = target − currentValue − claimedByAmfi[amfi]`.
///      [claimedByAmfi] carries already-routed rupees from prior suggestions
///      in the current batch so back-to-back routes don't pile every rupee
///      into the same fund (concentration fix).
/// 3. Pick the fund with the largest **positive** deficit.
/// 4. Fallback: when every candidate is at/above its target (or targets are
///    unset), pick the largest-current-value fund — preserves the legacy
///    behaviour on untouched portfolios.
///
/// If no bucket is underweight, the redemption is parked in Liquid.
/// If the underweight bucket has no holdings, returns "park in <bucket>"
/// with `toAmfiCode == null` so the UI renders an inline fund search.
RebalanceDestination? resolveReduceDestination({
  required BucketCompositionResult composition,
  required int fromAmfiCode,
  Map<int, double> perFundTargets = const {},
  Map<int, double> claimedByAmfi = const {},
}) {
  if (composition.buckets.isEmpty) return null;

  BucketComposition? mostUnder;
  for (final b in composition.buckets) {
    if (b.gapPct < -0.5) {
      if (mostUnder == null || b.gapPct < mostUnder.gapPct) {
        mostUnder = b;
      }
    }
  }

  if (mostUnder == null) {
    return const RebalanceDestination(
      toAmfiCode: null,
      toFundName: 'Park in bank (Liquid)',
      toBucket: Bucket.liquid,
      reason: 'All buckets at or above target — hold in Liquid until redeployed.',
    );
  }

  final candidates = mostUnder.funds
      .where((l) => l.holding.amfiCode != fromAmfiCode)
      .toList();

  if (candidates.isEmpty) {
    return RebalanceDestination(
      toAmfiCode: null,
      toFundName: 'Park in ${mostUnder.bucket.displayName}',
      toBucket: mostUnder.bucket,
      reason:
          '${mostUnder.bucket.displayName} is underweight by ${(-mostUnder.gapPct).toStringAsFixed(1)}% — no existing fund to switch into.',
    );
  }

  double deficitOf(HoldingLine l) {
    final amfi = l.holding.amfiCode;
    final target = perFundTargets[amfi] ?? l.holding.currentValue;
    final claimed = claimedByAmfi[amfi] ?? 0;
    return target - l.holding.currentValue - claimed;
  }

  candidates.sort((a, b) => deficitOf(b).compareTo(deficitOf(a)));

  final topDeficit = deficitOf(candidates.first);
  final pickLine = topDeficit > 0
      ? candidates.first
      : (candidates.toList()
            ..sort((a, b) =>
                b.holding.currentValue.compareTo(a.holding.currentValue)))
          .first;

  final pick = pickLine.holding;
  final reason = topDeficit > 0
      ? '${mostUnder.bucket.displayName} underweight by ${(-mostUnder.gapPct).toStringAsFixed(1)}% — ${pick.fundName} is furthest below its Fund-tab target.'
      : '${mostUnder.bucket.displayName} underweight by ${(-mostUnder.gapPct).toStringAsFixed(1)}%.';

  return RebalanceDestination(
    toAmfiCode: pick.amfiCode,
    toFundName: pick.fundName,
    toBucket: mostUnder.bucket,
    reason: reason,
  );
}
