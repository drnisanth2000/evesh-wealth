// Domain models for the Interactive Simulator + Action Persistence.
// Plain Dart classes (no Freezed) — these are computation intermediaries.

class SimulationState {
  const SimulationState({
    required this.fundAmounts,
    required this.additionalLumpsum,
    required this.additionalSip,
    required this.isDirty,
    this.targetAllocations = const {},
    this.bucketTargets = const {},
    this.pendingDeployments = const {},
    this.pendingFundNames = const {},
    this.pendingFundAssetClass = const {},
    this.touchedFundAmounts = const {},
  });

  final Map<int, double> fundAmounts; // amfiCode → desired ₹ amount
  final double additionalLumpsum;
  final double additionalSip;
  final bool isDirty; // user changed something?
  final Map<String, double> targetAllocations; // asset class key → target %

  /// Bucket enum name → target %. Keys are the three `Bucket.name` strings
  /// (`liquid`, `fixedIncome`, `growth`). Editable from the Asset Allocation
  /// → Bucket tab; persisted via Hive alongside the asset-class targets.
  /// Missing keys fall back to the ideal allocation derived from risk
  /// profile so the UI has a sensible default.
  final Map<String, double> bucketTargets;

  /// AMFI codes whose fund target the user has explicitly edited. Funds
  /// NOT in this set get a pro-rata suggestion auto-derived from the
  /// class target — the Fund tab reads [fundAmounts] only for touched
  /// funds. This lets the per-fund breakdown start balanced at the class
  /// target without locking users into the suggestion; dragging a slider
  /// flips the bit on just that fund.
  final Set<int> touchedFundAmounts;

  /// AMFI codes added via the Fund tab's "Add Fund" flow that haven't yet
  /// been executed into a `pending_orders` row. Drives the "pending
  /// deployment" badge on each fund sub-card; ignored by rebalance/sim
  /// calculations so these candidates don't inflate drift until real.
  final Set<int> pendingDeployments;

  /// amfiCode → fund name for pending-deployment funds. Needed because
  /// pending funds have no row in `portfolio.fundHoldings` yet, so we can't
  /// derive their display name from the portfolio.
  final Map<int, String> pendingFundNames;

  /// amfiCode → asset class NAME (enum .name, e.g. 'coreEquity') for
  /// pending-deployment funds. `asset_class_override` can't help here
  /// because pending funds have no transaction rows to attach the override
  /// to; this map is the sole source of truth for which card the virtual
  /// fund lives under until it's executed.
  final Map<int, String> pendingFundAssetClass;

  SimulationState copyWith({
    Map<int, double>? fundAmounts,
    double? additionalLumpsum,
    double? additionalSip,
    bool? isDirty,
    Map<String, double>? targetAllocations,
    Map<String, double>? bucketTargets,
    Set<int>? pendingDeployments,
    Map<int, String>? pendingFundNames,
    Map<int, String>? pendingFundAssetClass,
    Set<int>? touchedFundAmounts,
  }) {
    return SimulationState(
      fundAmounts: fundAmounts ?? this.fundAmounts,
      additionalLumpsum: additionalLumpsum ?? this.additionalLumpsum,
      additionalSip: additionalSip ?? this.additionalSip,
      isDirty: isDirty ?? this.isDirty,
      targetAllocations: targetAllocations ?? this.targetAllocations,
      bucketTargets: bucketTargets ?? this.bucketTargets,
      pendingDeployments: pendingDeployments ?? this.pendingDeployments,
      pendingFundNames: pendingFundNames ?? this.pendingFundNames,
      pendingFundAssetClass:
          pendingFundAssetClass ?? this.pendingFundAssetClass,
      touchedFundAmounts: touchedFundAmounts ?? this.touchedFundAmounts,
    );
  }
}

class RefillRule {
  const RefillRule({
    required this.fromBucket,
    required this.toBucket,
    required this.trigger,
    required this.frequency,
    required this.description,
  });

  final int fromBucket;
  final int toBucket;
  final String trigger;
  final String frequency;
  final String description;
}

class BucketStrategy {
  const BucketStrategy({
    required this.scenario,
    required this.bucketTargets,
    required this.bucketNames,
    required this.bucketInstruments,
    required this.corePct,
    required this.satellitePct,
    required this.educationNotes,
    required this.refillRules,
  });

  final String scenario; // 'accumulation' | 'distribution'
  final Map<int, double> bucketTargets; // {1: 8.0, 2: 22.0, 3: 70.0}
  final Map<int, String> bucketNames; // {1: 'Liquidity (0-2yr)', ...}
  final Map<int, List<String>> bucketInstruments;
  final double corePct;
  final double satellitePct;
  final List<String> educationNotes;
  final List<RefillRule> refillRules;
}

class AssetClassBand {
  const AssetClassBand({
    required this.assetClassKey,
    required this.displayName,
    required this.valuePct,
    required this.valueAmount,
  });

  final String assetClassKey;
  final String displayName;
  final double valuePct; // % of this bucket
  final double valueAmount; // ₹
}

class BucketComposition {
  const BucketComposition({
    required this.bucketNumber,
    required this.bucketName,
    required this.currentPct,
    required this.idealPct,
    required this.currentValue,
    required this.status,
    required this.bands,
    this.overflowPct = 0,
    this.spillsIntoBucket,
  });

  final int bucketNumber;
  final String bucketName;
  final double currentPct;
  final double idealPct;
  final double currentValue;
  final String status; // 'overweight', 'underweight', 'balanced'
  final List<AssetClassBand> bands;
  final double overflowPct; // >0 if spilling (default 0)
  final int? spillsIntoBucket; // which bucket to pour into
}

class FundTaxImpact {
  const FundTaxImpact({
    required this.amfiCode,
    required this.fundName,
    required this.sellAmount,
    required this.stcgAmount,
    required this.ltcgAmount,
    required this.stcgTax,
    required this.ltcgTax,
    required this.exitLoadAmount,
    required this.netProceeds,
    required this.holdingDays,
  });

  final int amfiCode;
  final String fundName;
  final double sellAmount;
  final double stcgAmount;
  final double ltcgAmount;
  final double stcgTax;
  final double ltcgTax;
  final double exitLoadAmount;
  final double netProceeds;
  final int holdingDays;

  double get totalTax => stcgTax + ltcgTax;
}

class SimulationResult {
  const SimulationResult({
    required this.newAllocationPct,
    required this.bucketFills,
    required this.projectedHealthScore,
    required this.healthDelta,
    required this.taxImpacts,
    required this.totalTaxCost,
    required this.totalExitLoad,
    required this.netRebalanceCost,
    required this.totalPortfolioValue,
  });

  final Map<String, double> newAllocationPct; // asset class → %
  final List<BucketComposition> bucketFills;
  final int projectedHealthScore;
  final int healthDelta; // vs current
  final List<FundTaxImpact> taxImpacts;
  final double totalTaxCost;
  final double totalExitLoad;
  final double netRebalanceCost;
  final double totalPortfolioValue; // including new money
}

class FrozenPlan {
  const FrozenPlan({
    this.id,
    required this.ownerId,
    this.memberId,
    required this.fundAllocations,
    required this.additionalLumpsum,
    required this.additionalSip,
    this.healthScore,
    this.healthDelta,
    this.totalTaxImpact,
    this.totalExitLoad,
    this.bucketTargets,
    this.assetClassTargets,
    this.actionItems,
    required this.status,
    this.createdAt,
    this.completedAt,
  });

  final String? id;
  final String ownerId;
  final String? memberId;
  final Map<int, double> fundAllocations; // amfiCode → amount
  final double additionalLumpsum;
  final double additionalSip;
  final int? healthScore;
  final int? healthDelta;
  final double? totalTaxImpact;
  final double? totalExitLoad;
  final Map<int, double>? bucketTargets;
  /// Per-asset-class target percentages (sim-state keys → pct).
  /// Snapshot of [SimulationState.targetAllocations] at freeze time.
  /// Nullable for backward compatibility.
  final Map<String, double>? assetClassTargets;
  final List<Map<String, dynamic>>? actionItems;
  final String status; // 'active', 'completed', 'superseded'
  final DateTime? createdAt;
  final DateTime? completedAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'owner_id': ownerId,
      if (memberId != null) 'member_id': memberId,
      'fund_allocations': fundAllocations.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'additional_lumpsum': additionalLumpsum,
      'additional_sip': additionalSip,
      if (healthScore != null) 'health_score': healthScore,
      if (healthDelta != null) 'health_delta': healthDelta,
      if (totalTaxImpact != null) 'total_tax_impact': totalTaxImpact,
      if (totalExitLoad != null) 'total_exit_load': totalExitLoad,
      if (bucketTargets != null)
        'bucket_targets': bucketTargets!.map(
          (k, v) => MapEntry(k.toString(), v),
        ),
      if (assetClassTargets != null)
        'asset_class_targets': assetClassTargets,
      if (actionItems != null) 'action_items': actionItems,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
    };
  }

  factory FrozenPlan.fromJson(Map<String, dynamic> json) {
    final rawFundAllocations =
        (json['fund_allocations'] as Map<String, dynamic>?) ?? {};
    final rawBucketTargets =
        (json['bucket_targets'] as Map<String, dynamic>?);
    final rawAssetClassTargets =
        (json['asset_class_targets'] as Map<String, dynamic>?);

    return FrozenPlan(
      id: json['id'] as String?,
      ownerId: json['owner_id'] as String,
      memberId: json['member_id'] as String?,
      fundAllocations: rawFundAllocations.map(
        (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
      ),
      additionalLumpsum: (json['additional_lumpsum'] as num).toDouble(),
      additionalSip: (json['additional_sip'] as num).toDouble(),
      healthScore: json['health_score'] as int?,
      healthDelta: json['health_delta'] as int?,
      totalTaxImpact: (json['total_tax_impact'] as num?)?.toDouble(),
      totalExitLoad: (json['total_exit_load'] as num?)?.toDouble(),
      bucketTargets: rawBucketTargets?.map(
        (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
      ),
      assetClassTargets: rawAssetClassTargets?.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      actionItems: (json['action_items'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
      status: json['status'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  FrozenPlan copyWith({
    String? id,
    String? ownerId,
    String? memberId,
    Map<int, double>? fundAllocations,
    double? additionalLumpsum,
    double? additionalSip,
    int? healthScore,
    int? healthDelta,
    double? totalTaxImpact,
    double? totalExitLoad,
    Map<int, double>? bucketTargets,
    Map<String, double>? assetClassTargets,
    List<Map<String, dynamic>>? actionItems,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return FrozenPlan(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      memberId: memberId ?? this.memberId,
      fundAllocations: fundAllocations ?? this.fundAllocations,
      additionalLumpsum: additionalLumpsum ?? this.additionalLumpsum,
      additionalSip: additionalSip ?? this.additionalSip,
      healthScore: healthScore ?? this.healthScore,
      healthDelta: healthDelta ?? this.healthDelta,
      totalTaxImpact: totalTaxImpact ?? this.totalTaxImpact,
      totalExitLoad: totalExitLoad ?? this.totalExitLoad,
      bucketTargets: bucketTargets ?? this.bucketTargets,
      assetClassTargets: assetClassTargets ?? this.assetClassTargets,
      actionItems: actionItems ?? this.actionItems,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
