import 'package:freezed_annotation/freezed_annotation.dart';

part 'overlap_models.freezed.dart';
part 'overlap_models.g.dart';

// ── Cached holding from Groww ────────────────────────────────────────────────

@freezed
class CachedFundHolding with _$CachedFundHolding {
  const factory CachedFundHolding({
    required int amfiCode,
    required String companyName,
    String? sectorName,
    required double corpusPct,
    String? instrumentName,
    String? natureName,
    String? rating,
    double? marketValue,
    required String fetchedAt,
  }) = _CachedFundHolding;

  factory CachedFundHolding.fromJson(Map<String, dynamic> json) =>
      _$CachedFundHoldingFromJson(json);
}

// ── Input for overlap computation ────────────────────────────────────────────

class FundWithHoldings {
  final int amfiCode;
  final String fundName;
  final double portfolioWeightPct;
  final List<CachedFundHolding> holdings;

  const FundWithHoldings({
    required this.amfiCode,
    required this.fundName,
    required this.portfolioWeightPct,
    required this.holdings,
  });
}

// ── Computation results ──────────────────────────────────────────────────────

enum RiskLevel { low, moderate, high }

class StockExposure {
  final String companyName;
  final String? sectorName;
  final double effectiveWeightPct;
  final RiskLevel risk;
  final List<String> heldInFunds;

  const StockExposure({
    required this.companyName,
    this.sectorName,
    required this.effectiveWeightPct,
    required this.risk,
    required this.heldInFunds,
  });
}

class SectorExposure {
  final String sectorName;
  final double weightPct;
  final RiskLevel risk;

  const SectorExposure({
    required this.sectorName,
    required this.weightPct,
    required this.risk,
  });
}

/// A single common holding between two funds.
class CommonHolding {
  final String companyName;
  final double weightA;
  final double weightB;
  final double overlapContribution; // min(weightA, weightB)

  const CommonHolding({
    required this.companyName,
    required this.weightA,
    required this.weightB,
    required this.overlapContribution,
  });
}

class FundPairOverlap {
  final String fundNameA;
  final String fundNameB;
  final int amfiCodeA;
  final int amfiCodeB;
  final double overlapPct;
  final RiskLevel risk;
  final List<CommonHolding> commonHoldings;

  const FundPairOverlap({
    required this.fundNameA,
    required this.fundNameB,
    required this.amfiCodeA,
    required this.amfiCodeB,
    required this.overlapPct,
    required this.risk,
    this.commonHoldings = const [],
  });
}

class OverlapResult {
  final List<StockExposure> stockExposures;
  final List<SectorExposure> sectorExposures;
  final List<FundPairOverlap> fundPairOverlaps;
  final RiskLevel overallRisk;
  final int issueCount;

  const OverlapResult({
    required this.stockExposures,
    required this.sectorExposures,
    required this.fundPairOverlaps,
    required this.overallRisk,
    required this.issueCount,
  });
}

class PreBuyAnalysis {
  final OverlapResult before;
  final OverlapResult after;
  final List<FundPairOverlap> newOverlaps;
  final List<SectorDelta> sectorDeltas;
  final List<StockDelta> stockDeltas;
  final RiskLevel candidateRisk;

  const PreBuyAnalysis({
    required this.before,
    required this.after,
    required this.newOverlaps,
    required this.sectorDeltas,
    required this.stockDeltas,
    required this.candidateRisk,
  });
}

class SectorDelta {
  final String sectorName;
  final double beforePct;
  final double afterPct;
  final RiskLevel beforeRisk;
  final RiskLevel afterRisk;

  const SectorDelta({
    required this.sectorName,
    required this.beforePct,
    required this.afterPct,
    required this.beforeRisk,
    required this.afterRisk,
  });

  bool get changed => beforeRisk != afterRisk;
}

class StockDelta {
  final String companyName;
  final double beforePct;
  final double afterPct;
  final RiskLevel beforeRisk;
  final RiskLevel afterRisk;

  const StockDelta({
    required this.companyName,
    required this.beforePct,
    required this.afterPct,
    required this.beforeRisk,
    required this.afterRisk,
  });

  bool get changed => beforeRisk != afterRisk;
}
