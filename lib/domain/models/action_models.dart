/// Enums for the Action Center engine.
library action_models;

enum MoveType { sell, buy, hold, shift, deployCash }

enum ActionSource { rebalance, retirement, drift, cashOptimization, fundReplace }

enum ActionPriority { critical, warning, info }

enum ActionType { sell, buy, hold, increaseSip, startSip, deployIdle }

enum Platform { mfCentral, groww, kuvera, indmoney, zerodha }

// ── Fund Move ────────────────────────────────────────────────────────────────

/// A single fund-to-fund money movement (one arrow in the flow diagram).
class FundMove {
  final int? sourceAmfiCode;      // null if deploying cash/savings
  final String? sourceFundName;
  final String? sourceAssetClass;  // asset class key e.g. 'coreEquity'
  final int? destAmfiCode;         // null if selling to cash
  final String? destFundName;
  final String? destAssetClass;
  final double amount;             // ₹ to move
  final MoveType moveType;
  final String rationale;

  const FundMove({
    this.sourceAmfiCode,
    this.sourceFundName,
    this.sourceAssetClass,
    this.destAmfiCode,
    this.destFundName,
    this.destAssetClass,
    required this.amount,
    required this.moveType,
    required this.rationale,
  });
}

// ── Platform Link ────────────────────────────────────────────────────────────

/// An external execution link to a broker/platform.
class PlatformLink {
  final Platform platform;
  final String url;
  final String label;

  const PlatformLink({
    required this.platform,
    required this.url,
    required this.label,
  });
}

// ── Action Item ──────────────────────────────────────────────────────────────

/// The universal action unit — every engine produces these.
class ActionItem {
  final String id;                 // deterministic from source+amfiCode+actionType
  final ActionSource source;
  final ActionPriority priority;
  final String title;              // "Reduce HDFC Midcap by ₹20K"
  final String subtitle;           // "Overweight in Satellite Equity by 12%"
  final ActionType actionType;
  final int? amfiCode;
  final double? amount;
  final String rationale;
  final String impactDescription;  // "Drift: 12% → 2%"
  final List<PlatformLink> platformLinks;
  final bool isCompleted;

  const ActionItem({
    required this.id,
    required this.source,
    required this.priority,
    required this.title,
    required this.subtitle,
    required this.actionType,
    this.amfiCode,
    this.amount,
    required this.rationale,
    required this.impactDescription,
    required this.platformLinks,
    this.isCompleted = false,
  });

  /// Returns a copy with isCompleted toggled.
  ActionItem copyWith({bool? isCompleted}) => ActionItem(
        id: id,
        source: source,
        priority: priority,
        title: title,
        subtitle: subtitle,
        actionType: actionType,
        amfiCode: amfiCode,
        amount: amount,
        rationale: rationale,
        impactDescription: impactDescription,
        platformLinks: platformLinks,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

// ── Bucket Status ────────────────────────────────────────────────────────────

/// Status of one of the 3 investment buckets.
class BucketStatus {
  final int bucketNumber;
  final String bucketName;
  final double currentPct;
  final double idealPct;
  final double currentValue;
  final String status; // 'overweight', 'underweight', 'balanced'

  const BucketStatus({
    required this.bucketNumber,
    required this.bucketName,
    required this.currentPct,
    required this.idealPct,
    required this.currentValue,
    required this.status,
  });
}

// ── Rebalance Plan ──────────────────────────────────────────────────────────

/// Complete output of the Action Center engines.
class RebalancePlan {
  final int healthScore;
  final String healthLabel;
  final String? topDriftAlert;
  final double? retirementGapMonthly;
  final List<BucketStatus> bucketSummary;
  final List<FundMove> fundMoves;
  final List<ActionItem> actionItems;
  final List<String> rationale;
  final double totalSellAmount;
  final double totalBuyAmount;
  final double netCashFlow;

  const RebalancePlan({
    required this.healthScore,
    required this.healthLabel,
    this.topDriftAlert,
    this.retirementGapMonthly,
    required this.bucketSummary,
    required this.fundMoves,
    required this.actionItems,
    required this.rationale,
    required this.totalSellAmount,
    required this.totalBuyAmount,
    required this.netCashFlow,
  });
}
