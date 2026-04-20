/// Domain models for Core-Satellite allocation engine.
/// Plain Dart classes (no Freezed) — these are computation intermediaries, not DB entities.

/// A single sub-bucket target range within Core or Satellite.
class SubBucketTarget {
  final String name;       // e.g. 'Nifty 50 Index'
  final String parentBucket; // 'coreEquity', 'satelliteEquity', 'debt', etc.
  final double minPct;
  final double maxPct;
  final double idealPct;   // midpoint or risk-adjusted

  const SubBucketTarget({
    required this.name,
    required this.parentBucket,
    required this.minPct,
    required this.maxPct,
    required this.idealPct,
  });
}

/// The full ideal allocation for a member, containing all sub-buckets.
class IdealAllocation {
  final String riskProfile;
  final int age;
  final double corePct;        // total core %
  final double satellitePct;   // total satellite %
  final List<SubBucketTarget> subBuckets;

  const IdealAllocation({
    required this.riskProfile,
    required this.age,
    required this.corePct,
    required this.satellitePct,
    required this.subBuckets,
  });

  /// Lookup ideal % for an AssetClass (summing matching sub-buckets).
  double idealForAssetClass(String assetClassKey) {
    return subBuckets
        .where((b) => b.parentBucket == assetClassKey)
        .fold(0.0, (sum, b) => sum + b.idealPct);
  }
}

/// A single drift alert for one asset class.
class DriftAlert {
  final String assetClass;     // display name
  final String assetClassKey;  // enum key
  final double currentPct;
  final double idealPct;
  final double driftPct;       // current - ideal (positive = overweight)
  final String severity;       // 'ok', 'warning', 'critical'
  final String message;        // e.g. "Overexposed to Core Equity by 12%"

  const DriftAlert({
    required this.assetClass,
    required this.assetClassKey,
    required this.currentPct,
    required this.idealPct,
    required this.driftPct,
    required this.severity,
    required this.message,
  });
}

/// Result of allocation health computation.
class AllocationHealthResult {
  final int healthScore;             // 0-100
  final String healthLabel;          // 'Excellent', 'Good', 'Needs Attention', 'Critical'
  final IdealAllocation idealAllocation;
  final Map<String, double> currentAllocation; // assetClassKey → current %
  final List<DriftAlert> driftAlerts;
  final List<String> nudges;         // smart nudge messages

  const AllocationHealthResult({
    required this.healthScore,
    required this.healthLabel,
    required this.idealAllocation,
    required this.currentAllocation,
    required this.driftAlerts,
    required this.nudges,
  });
}
