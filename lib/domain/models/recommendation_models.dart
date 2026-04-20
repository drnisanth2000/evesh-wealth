// lib/domain/models/recommendation_models.dart

/// Score breakdown for a single fund across all scoring dimensions.
class ScoreBreakdown {
  final double returns;       // 0-40: percentile rank (1Y: 10, 3Y: 15, 5Y: 15)
  final double riskAdjusted;  // 0-25: return/volatility ratio (15) + low vol (10)
  final double cost;          // 0-15: ER inverse percentile within category
  final double rating;        // 0-10: CRISIL (6) + fund rating (4)
  final double fundHouse;     // 0-10: AMC quality proxy

  const ScoreBreakdown({
    required this.returns,
    required this.riskAdjusted,
    required this.cost,
    required this.rating,
    required this.fundHouse,
  });

  double get total => returns + riskAdjusted + cost + rating + fundHouse;
}

/// A scored fund that passed the quality gate.
class FundScore {
  final int amfiCode;
  final String fundName;
  final String category;
  final String? subCategory;
  final String? taxCategory;
  final String? amc;
  final double score;               // 0-100 after category adjustments
  final ScoreBreakdown breakdown;
  final double? return1y;
  final double? return3y;
  final double? return5y;
  final double? expenseRatio;
  final double? volatility1y;
  final double? aumCr;
  final String? crisilRating;
  final String? fundRating;

  const FundScore({
    required this.amfiCode,
    required this.fundName,
    required this.category,
    this.subCategory,
    this.taxCategory,
    this.amc,
    required this.score,
    required this.breakdown,
    this.return1y,
    this.return3y,
    this.return5y,
    this.expenseRatio,
    this.volatility1y,
    this.aumCr,
    this.crisilRating,
    this.fundRating,
  });
}

/// A single fund recommendation with allocation context + explanations.
class FundRecommendation {
  final FundScore fundScore;
  final String targetAssetClass;     // e.g. 'coreEquity', 'debt'
  final String targetAssetClassLabel; // e.g. 'Core Equity', 'Debt'
  final double allocationGapPct;     // ideal% - current% for this asset class
  final double suggestedAmount;      // ₹ to invest in this fund
  final bool isSip;                  // SIP preferred?
  final List<String> reasons;        // human-readable explanations
  final List<String> warnings;       // caution notes (e.g. AMC overlap)

  const FundRecommendation({
    required this.fundScore,
    required this.targetAssetClass,
    required this.targetAssetClassLabel,
    required this.allocationGapPct,
    required this.suggestedAmount,
    required this.isSip,
    required this.reasons,
    this.warnings = const [],
  });
}

/// Final output of the recommendation engine.
class RecommendationResult {
  final double surplusAmount;
  final bool sipRecommended;
  final String sipRationale;          // why SIP or lumpsum
  final List<FundRecommendation> recommendations;
  final int fundsEvaluated;           // total before quality gate
  final int fundsPassedGate;          // after quality gate
  final Map<String, double> allocationGaps; // assetClassKey → gap%

  const RecommendationResult({
    required this.surplusAmount,
    required this.sipRecommended,
    required this.sipRationale,
    required this.recommendations,
    required this.fundsEvaluated,
    required this.fundsPassedGate,
    required this.allocationGaps,
  });
}
