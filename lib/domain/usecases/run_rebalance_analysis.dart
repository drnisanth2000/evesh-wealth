import '../../core/constants/asset_classes.dart';
import '../../core/constants/bucket_education.dart';
import '../models/simulation_models.dart';

/// Current portfolio allocation vs target
class AllocationDrift {
  const AllocationDrift({
    required this.assetClass,
    required this.targetPct,
    required this.currentPct,
    required this.currentValue,
    required this.driftPct,
    required this.action,
    required this.actionAmount,
  });

  final AssetClass assetClass;
  final double targetPct;   // e.g. 40.0 = 40%
  final double currentPct;
  final double currentValue;
  final double driftPct;    // currentPct - targetPct; positive = overweight
  final RebalanceAction action;
  final double actionAmount; // Rs amount to add or reduce
}

enum RebalanceAction { hold, add, reduce }

/// 3-bucket allocation
class BucketAllocation {
  const BucketAllocation({
    required this.bucketNumber,
    required this.bucketName,
    required this.currentValue,
    required this.targetPct,
    required this.currentPct,
    required this.driftPct,
  });

  final int bucketNumber;
  final String bucketName;
  final double currentValue;
  final double targetPct;
  final double currentPct;
  final double driftPct;
}

/// Fund-level rebalance suggestion
class FundRebalanceSuggestion {
  const FundRebalanceSuggestion({
    required this.amfiCode,
    required this.fundName,
    required this.assetClass,
    required this.driftPct,
    required this.currentValue,
    required this.suggestedAction,
    required this.suggestedAmount,
  });

  final int amfiCode;
  final String fundName;
  final AssetClass assetClass;
  final double driftPct;
  final double currentValue;
  final RebalanceAction suggestedAction;
  final double suggestedAmount;
}

class RebalanceResult {
  const RebalanceResult({
    required this.totalPortfolioValue,
    required this.allocationDrifts,
    required this.bucketAllocations,
    required this.topFundSuggestions,
    required this.rebalanceNeeded,
    required this.driftThreshold,
  });

  final double totalPortfolioValue;
  final List<AllocationDrift> allocationDrifts;
  final List<BucketAllocation> bucketAllocations;
  final List<FundRebalanceSuggestion> topFundSuggestions;
  final bool rebalanceNeeded;
  final double driftThreshold;
}

/// Portfolio input for rebalancing analysis
class PortfolioHolding {
  const PortfolioHolding({
    required this.amfiCode,
    required this.fundName,
    required this.assetClass,
    required this.currentValue,
    this.bucket,
  });

  final int amfiCode;
  final String fundName;
  final AssetClass assetClass;
  final double currentValue;
  final int? bucket; // 1, 2, or 3
}

/// Target allocation from family config
class AllocationTarget {
  const AllocationTarget({
    required this.coreEquityPct,
    required this.satelliteEquityPct,
    required this.hybridPct,
    required this.debtPct,
    required this.liquidPct,
    required this.goldPct,
    required this.alternatePct,
    required this.driftThreshold,
  });

  final double coreEquityPct;
  final double satelliteEquityPct;
  final double hybridPct;
  final double debtPct;
  final double liquidPct;
  final double goldPct;
  final double alternatePct;
  final double driftThreshold; // 5.0 = 5%

  double targetFor(AssetClass cls) {
    switch (cls) {
      case AssetClass.coreEquity: return coreEquityPct;
      case AssetClass.satelliteEquity: return satelliteEquityPct;
      case AssetClass.hybrid: return hybridPct;
      case AssetClass.debt: return debtPct;
      case AssetClass.liquid: return liquidPct;
      case AssetClass.gold: return goldPct;
      case AssetClass.alternate: return alternatePct;
    }
  }
}

class RebalanceAnalyzer {
  RebalanceAnalyzer._();

  static RebalanceResult analyze({
    required List<PortfolioHolding> holdings,
    required AllocationTarget target,
    BucketStrategy? bucketStrategy,
  }) {
    final totalValue = holdings.fold(0.0, (sum, h) => sum + h.currentValue);
    if (totalValue <= 0) {
      return RebalanceResult(
        totalPortfolioValue: 0,
        allocationDrifts: [],
        bucketAllocations: [],
        topFundSuggestions: [],
        rebalanceNeeded: false,
        driftThreshold: target.driftThreshold,
      );
    }

    // ── Asset class allocation ──────────────────────────────────────────────
    final valueByClass = <AssetClass, double>{};
    for (final h in holdings) {
      valueByClass[h.assetClass] = (valueByClass[h.assetClass] ?? 0) + h.currentValue;
    }

    final drifts = <AllocationDrift>[];
    bool rebalanceNeeded = false;

    for (final assetClass in AssetClass.values) {
      final currentValue = valueByClass[assetClass] ?? 0;
      final currentPct = (currentValue / totalValue) * 100;
      final targetPct = target.targetFor(assetClass);
      final driftPct = currentPct - targetPct;

      if (driftPct.abs() > target.driftThreshold) rebalanceNeeded = true;

      // Gate on the user's drift threshold symmetrically — otherwise any
      // sub-threshold drift (even 0.01%) surfaces a sell/buy suggestion.
      final action = driftPct > target.driftThreshold
          ? RebalanceAction.reduce
          : driftPct < -target.driftThreshold
              ? RebalanceAction.add
              : RebalanceAction.hold;

      final actionAmount = (targetPct - currentPct).abs() * totalValue / 100;

      drifts.add(AllocationDrift(
        assetClass: assetClass,
        targetPct: targetPct,
        currentPct: currentPct,
        currentValue: currentValue,
        driftPct: driftPct,
        action: action,
        actionAmount: actionAmount,
      ));
    }

    // Sort by absolute drift descending
    drifts.sort((a, b) => b.driftPct.abs().compareTo(a.driftPct.abs()));

    // ── 3-Bucket breakdown ──────────────────────────────────────────────────
    final bucketValues = <int, double>{1: 0, 2: 0, 3: 0};
    for (final h in holdings) {
      final bucket = h.bucket ?? _defaultBucket(h.assetClass);
      bucketValues[bucket] = (bucketValues[bucket] ?? 0) + h.currentValue;
    }

    // Default bucket targets (approximately)
    final effectiveTargets = bucketStrategy?.bucketTargets ?? {1: 20.0, 2: 30.0, 3: 50.0};
    final effectiveNames = bucketStrategy?.bucketNames ?? {1: 'Stability (0-3yr)', 2: 'Income (3-7yr)', 3: 'Growth (7yr+)'};

    final buckets = [1, 2, 3].map((b) {
      final val = bucketValues[b] ?? 0;
      final pct = totalValue > 0 ? (val / totalValue) * 100 : 0.0;
      final tgt = effectiveTargets[b] ?? 33.33;
      return BucketAllocation(
        bucketNumber: b,
        bucketName: effectiveNames[b] ?? 'Bucket $b',
        currentValue: val,
        targetPct: tgt,
        currentPct: pct,
        driftPct: pct - tgt,
      );
    }).toList();

    // ── Top fund suggestions ────────────────────────────────────────────────
    // Flag overweight funds for reduction, underweight asset classes for addition
    final suggestions = <FundRebalanceSuggestion>[];

    for (final h in holdings) {
      final drift = drifts.firstWhere((d) => d.assetClass == h.assetClass);
      if (drift.action == RebalanceAction.reduce) {
        // Proportional reduction for each fund in overweight class
        final proportion = drift.currentValue > 0 ? h.currentValue / drift.currentValue : 0.0;
        suggestions.add(FundRebalanceSuggestion(
          amfiCode: h.amfiCode,
          fundName: h.fundName,
          assetClass: h.assetClass,
          driftPct: drift.driftPct,
          currentValue: h.currentValue,
          suggestedAction: RebalanceAction.reduce,
          suggestedAmount: drift.actionAmount * proportion,
        ));
      }
    }

    // Add suggestions for underweight classes
    for (final drift in drifts.where((d) => d.action == RebalanceAction.add)) {
      suggestions.add(FundRebalanceSuggestion(
        amfiCode: 0,
        fundName: '${drift.assetClass.displayName} fund (to be selected)',
        assetClass: drift.assetClass,
        driftPct: drift.driftPct,
        currentValue: drift.currentValue,
        suggestedAction: RebalanceAction.add,
        suggestedAmount: drift.actionAmount,
      ));
    }

    suggestions.sort((a, b) => b.driftPct.abs().compareTo(a.driftPct.abs()));

    return RebalanceResult(
      totalPortfolioValue: totalValue,
      allocationDrifts: drifts,
      bucketAllocations: buckets,
      topFundSuggestions: suggestions.take(10).toList(),
      rebalanceNeeded: rebalanceNeeded,
      driftThreshold: target.driftThreshold,
    );
  }

  static int _defaultBucket(AssetClass cls) {
    return BucketEducation.assetClassToBucket[cls.name] ?? 2;
  }
}
