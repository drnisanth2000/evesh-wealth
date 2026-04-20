import '../models/simulation_models.dart';
import '../models/allocation_models.dart';
import 'compute_rebalance_actions.dart';
import 'compute_allocation_health.dart';
import '../../presentation/providers/tax_provider.dart';
import '../../core/constants/bucket_education.dart';

/// Pure-Dart engine that simulates portfolio consequences of user's slider
/// adjustments — independent of RebalanceActionsCalculator.
class SimulationCalculator {
  SimulationCalculator._();

  /// Compute [SimulationResult] from manual slider-adjusted fund amounts.
  ///
  /// [holdings]          – original fund holdings with current values.
  /// [adjustedAmounts]   – amfiCode → desired ₹ amount after user adjustment.
  /// [additionalLumpsum] – new one-off investment to add.
  /// [additionalSip]     – monthly SIP to add; annualised (×12) for portfolio value.
  /// [bucketStrategy]    – 3-bucket targets from [BucketStrategyCalculator].
  /// [driftThreshold]    – % above ideal that triggers overflow/overweight status.
  /// [exposures]         – unrealized tax exposure per fund (for sell tax calc).
  /// [idealAllocation]   – optional; used to compute health score via drift model.
  /// [currentHealthScore]– optional; used to compute healthDelta.
  static SimulationResult compute({
    required List<FundHoldingInput> holdings,
    required Map<int, double> adjustedAmounts,
    required double additionalLumpsum,
    required double additionalSip,
    required BucketStrategy bucketStrategy,
    required double driftThreshold,
    required List<UnrealizedExposure> exposures,
    IdealAllocation? idealAllocation,
    int? currentHealthScore,
  }) {
    // ── 1. Total portfolio value ─────────────────────────────────────────────
    final adjustedTotal = adjustedAmounts.values.fold(0.0, (s, v) => s + v);
    final totalPortfolioValue =
        adjustedTotal + additionalLumpsum + (additionalSip * 12);

    // ── 2. New allocation percentages by asset class ─────────────────────────
    final assetClassTotals = <String, double>{};
    for (final h in holdings) {
      final adjusted = adjustedAmounts[h.amfiCode] ?? h.currentValue;
      assetClassTotals[h.assetClassKey] =
          (assetClassTotals[h.assetClassKey] ?? 0) + adjusted;
    }

    final newAllocationPct = <String, double>{};
    if (adjustedTotal > 0) {
      for (final entry in assetClassTotals.entries) {
        newAllocationPct[entry.key] = (entry.value / adjustedTotal) * 100.0;
      }
    }

    // ── 3. Bucket composition ────────────────────────────────────────────────
    // Group asset classes by bucket number
    final bucketValues = <int, double>{};
    final bucketAssetClasses = <int, Map<String, double>>{};

    for (final entry in assetClassTotals.entries) {
      final bucket =
          BucketEducation.assetClassToBucket[entry.key] ?? 2; // default Stability
      bucketValues[bucket] = (bucketValues[bucket] ?? 0) + entry.value;
      bucketAssetClasses[bucket] = bucketAssetClasses[bucket] ?? {};
      bucketAssetClasses[bucket]![entry.key] =
          (bucketAssetClasses[bucket]![entry.key] ?? 0) + entry.value;
    }

    final bucketFills = <BucketComposition>[];
    for (int bucketNum = 1; bucketNum <= 3; bucketNum++) {
      final bucketValue = bucketValues[bucketNum] ?? 0.0;
      final currentPct =
          adjustedTotal > 0 ? (bucketValue / adjustedTotal) * 100.0 : 0.0;
      final idealPct = bucketStrategy.bucketTargets[bucketNum] ?? 0.0;
      final bucketName = BucketEducation.bucketNames[bucketNum] ?? 'Bucket $bucketNum';

      // Build asset class bands within this bucket
      final assetMap = bucketAssetClasses[bucketNum] ?? {};
      final bands = assetMap.entries.map((e) {
        final pctOfBucket = bucketValue > 0 ? (e.value / bucketValue) * 100.0 : 0.0;
        return AssetClassBand(
          assetClassKey: e.key,
          displayName: _displayName(e.key),
          valuePct: pctOfBucket,
          valueAmount: e.value,
        );
      }).toList();

      // Overflow and status
      final drift = currentPct - idealPct;
      final String status;
      final double overflowPct;

      if (drift > driftThreshold) {
        status = 'overweight';
        overflowPct = drift - driftThreshold;
      } else if (drift < -driftThreshold) {
        status = 'underweight';
        overflowPct = 0;
      } else {
        status = 'balanced';
        overflowPct = 0;
      }

      bucketFills.add(BucketComposition(
        bucketNumber: bucketNum,
        bucketName: bucketName,
        currentPct: currentPct,
        idealPct: idealPct,
        currentValue: bucketValue,
        status: status,
        bands: bands,
        overflowPct: overflowPct,
        spillsIntoBucket: status == 'overweight' && bucketNum < 3 ? bucketNum + 1 : null,
      ));
    }

    // ── 4. Tax impact for funds being sold (adjusted < current) ─────────────
    final taxImpacts = <FundTaxImpact>[];
    final exposureMap = <int, UnrealizedExposure>{
      for (final e in exposures) e.amfiCode: e,
    };

    for (final h in holdings) {
      final currentVal = h.currentValue;
      final adjustedVal = adjustedAmounts[h.amfiCode] ?? currentVal;
      final sellAmount = currentVal - adjustedVal;

      if (sellAmount <= 0) continue; // no sell

      final exposure = exposureMap[h.amfiCode];
      if (exposure == null) {
        // No exposure data — record a sell with zero tax
        taxImpacts.add(FundTaxImpact(
          amfiCode: h.amfiCode,
          fundName: h.fundName,
          sellAmount: sellAmount,
          stcgAmount: 0,
          ltcgAmount: 0,
          stcgTax: 0,
          ltcgTax: 0,
          exitLoadAmount: 0,
          netProceeds: sellAmount,
          holdingDays: 0,
        ));
        continue;
      }

      // Proportion of fund being sold
      final proportion = currentVal > 0 ? sellAmount / currentVal : 0.0;

      // Proportional gain breakdown
      final stcgGain = exposure.stcgGain * proportion;
      final ltcgGain = exposure.ltcgGain * proportion;
      final stcgTax = stcgGain * exposure.stcgTaxRate;
      final ltcgTax = ltcgGain * exposure.ltcgTaxRate;
      final exitLoad = exposure.exitLoadAmount * proportion;
      final totalTaxBurden = stcgTax + ltcgTax + exitLoad;

      taxImpacts.add(FundTaxImpact(
        amfiCode: h.amfiCode,
        fundName: h.fundName,
        sellAmount: sellAmount,
        stcgAmount: stcgGain,
        ltcgAmount: ltcgGain,
        stcgTax: stcgTax,
        ltcgTax: ltcgTax,
        exitLoadAmount: exitLoad,
        netProceeds: sellAmount - totalTaxBurden,
        holdingDays: exposure.holdingDays,
      ));
    }

    final totalTaxCost = taxImpacts.fold(0.0, (s, t) => s + t.totalTax);
    final totalExitLoad = taxImpacts.fold(0.0, (s, t) => s + t.exitLoadAmount);
    final netRebalanceCost = totalTaxCost + totalExitLoad;

    // ── 5. Health score ──────────────────────────────────────────────────────
    final int projectedHealthScore;

    if (idealAllocation != null && adjustedTotal > 0) {
      final healthResult = AllocationHealthCalculator.compute(
        currentAllocation: newAllocationPct,
        portfolioValue: adjustedTotal,
        ideal: idealAllocation,
      );
      projectedHealthScore = healthResult.healthScore;
    } else {
      // Drift-based estimate using bucket-level drift
      final totalBucketDrift = bucketFills.fold(
        0.0,
        (sum, b) => sum + (b.currentPct - b.idealPct).abs(),
      );
      final rawScore = 100.0 * (1.0 - totalBucketDrift / 200.0);
      projectedHealthScore = rawScore.clamp(0.0, 100.0).round();
    }

    final healthDelta = projectedHealthScore - (currentHealthScore ?? projectedHealthScore);

    // ── 6. Assemble result ───────────────────────────────────────────────────
    return SimulationResult(
      newAllocationPct: newAllocationPct,
      bucketFills: bucketFills,
      projectedHealthScore: projectedHealthScore,
      healthDelta: healthDelta,
      taxImpacts: taxImpacts,
      totalTaxCost: totalTaxCost,
      totalExitLoad: totalExitLoad,
      netRebalanceCost: netRebalanceCost,
      totalPortfolioValue: totalPortfolioValue,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static const _displayNames = <String, String>{
    'coreEquity': 'Core Equity',
    'satelliteEquity': 'Satellite Equity',
    'hybrid': 'Hybrid',
    'debt': 'Debt',
    'liquid': 'Liquid',
    'gold': 'Gold',
    'alternate': 'Alternate',
    'alternatives': 'Alternatives',
  };

  static String _displayName(String key) => _displayNames[key] ?? key;
}
