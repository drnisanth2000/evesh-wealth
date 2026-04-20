/// Pure-Dart reallocator for the Fund tab.
///
/// Behavior: when the user drags ONE fund's target in an asset class to
/// [editedNewTarget], scale every OTHER fund's target proportional to its
/// prior target so the class sum stays pegged to [classTargetRupees]. This
/// keeps the class total at exactly 100% of the user's class target (and
/// preserves the portfolio's equity/debt invariant) across every edit.
///
/// Math:
/// * `newEdited = clamp(editedNewTarget, 0, classTargetRupees)`
/// * `remaining = classTargetRupees − newEdited`
/// * Let `priorSumOthers = Σ priorTargets[other]` across others.
/// * If `priorSumOthers > 0`: `newOther = priorOther × remaining /
///   priorSumOthers` (same ratio of existing weights).
/// * Else if `remaining > 0`: fall back to distribution by current value
///   (weights = `currentValues[other]`). If those are all zero too, split
///   [remaining] equally.
/// * `remaining ≤ 0` ⇒ all others go to 0 and Rebalance proposes sells.
///
/// Inputs:
/// * [amfiCodes]         – ids of every fund in this asset class.
/// * [currentValues]     – current ₹ value per fund.
/// * [priorTargets]      – last-committed targets (amfi → ₹). Missing ⇒ use
///                         current value as the prior.
/// * [editedAmfi]        – the fund the user just dragged.
/// * [editedNewTarget]   – ₹ the user dragged to.
/// * [classTargetRupees] – `classTargetPct × portfolioTotal / 100`.
///
/// Output: fresh `Map<int, double>` of per-fund targets. The edited fund
/// keeps `newEdited`; peers scale pro-rata. Sum equals [classTargetRupees]
/// to within ₹1 whenever both `remaining > 0` and peers exist.
Map<int, double> reallocateToInvariant({
  required List<int> amfiCodes,
  required Map<int, double> currentValues,
  required Map<int, double> priorTargets,
  required int editedAmfi,
  required double editedNewTarget,
  required double classTargetRupees,
}) {
  final result = <int, double>{};
  final classCap = classTargetRupees <= 0 ? 0.0 : classTargetRupees;
  final pinned = editedNewTarget.clamp(0.0, classCap == 0 ? double.infinity : classCap).toDouble();
  result[editedAmfi] = pinned;

  final others = amfiCodes.where((a) => a != editedAmfi).toList();
  if (others.isEmpty) {
    // Only fund in the class — it must absorb the whole class target.
    if (classCap > 0) result[editedAmfi] = classCap;
    return result;
  }

  final remaining = (classCap - pinned).clamp(0.0, double.infinity).toDouble();

  if (remaining <= 1.0) {
    for (final a in others) {
      result[a] = 0;
    }
    return result;
  }

  // Primary strategy: pro-rata to each peer's PRIOR TARGET.
  double priorSumOthers = 0;
  final priorOther = <int, double>{};
  for (final a in others) {
    final p = priorTargets[a] ?? currentValues[a] ?? 0;
    final safe = p < 0 ? 0.0 : p;
    priorOther[a] = safe;
    priorSumOthers += safe;
  }

  if (priorSumOthers > 0) {
    for (final a in others) {
      result[a] = remaining * ((priorOther[a] ?? 0) / priorSumOthers);
    }
    return result;
  }

  // Fallback: distribute by current value.
  double currentSum = 0;
  for (final a in others) {
    currentSum += currentValues[a] ?? 0;
  }
  if (currentSum > 0) {
    for (final a in others) {
      result[a] = remaining * ((currentValues[a] ?? 0) / currentSum);
    }
    return result;
  }

  // Last-ditch: equal split.
  final equal = remaining / others.length;
  for (final a in others) {
    result[a] = equal;
  }
  return result;
}
