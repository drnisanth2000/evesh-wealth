// lib/domain/usecases/compute_portfolio_overlap.dart

import '../models/overlap_models.dart';

/// SEBI-aligned thresholds.
class OverlapThresholds {
  static const double stockHigh = 10.0;   // SEBI 20/25 rule
  static const double stockModerate = 7.0;
  static const double sectorHigh = 25.0;  // industry standard
  static const double sectorModerate = 20.0;
  static const double fundOverlapHigh = 50.0;   // SEBI Feb 2026
  static const double fundOverlapModerate = 35.0;
}

class PortfolioOverlapCalculator {
  const PortfolioOverlapCalculator._();

  /// Compute full overlap analysis for the portfolio.
  static OverlapResult compute(List<FundWithHoldings> funds) {
    final stocks = computeStockExposures(funds);
    final sectors = computeSectorExposures(funds);
    final pairs = computeFundPairOverlaps(funds);

    final stockIssues = stocks.where((s) => s.risk == RiskLevel.high).length;
    final sectorIssues = sectors.where((s) => s.risk == RiskLevel.high).length;
    final pairIssues = pairs.where((p) => p.risk == RiskLevel.high).length;
    final issueCount = stockIssues + sectorIssues + pairIssues;

    final hasHigh = stocks.any((s) => s.risk == RiskLevel.high) ||
        sectors.any((s) => s.risk == RiskLevel.high) ||
        pairs.any((p) => p.risk == RiskLevel.high);
    final hasModerate = stocks.any((s) => s.risk == RiskLevel.moderate) ||
        sectors.any((s) => s.risk == RiskLevel.moderate) ||
        pairs.any((p) => p.risk == RiskLevel.moderate);

    return OverlapResult(
      stockExposures: stocks,
      sectorExposures: sectors,
      fundPairOverlaps: pairs,
      overallRisk: hasHigh
          ? RiskLevel.high
          : hasModerate
              ? RiskLevel.moderate
              : RiskLevel.low,
      issueCount: issueCount,
    );
  }

  /// Compute pre-buy analysis: compare before vs after adding a candidate fund.
  static PreBuyAnalysis computePreBuy({
    required List<FundWithHoldings> currentFunds,
    required FundWithHoldings candidateFund,
    double candidateWeightPct = 10.0,
  }) {
    final before = compute(currentFunds);

    // Reweight: reduce existing funds proportionally to make room for candidate
    final scaleFactor = (100.0 - candidateWeightPct) / 100.0;
    final adjustedFunds = currentFunds
        .map((f) => FundWithHoldings(
              amfiCode: f.amfiCode,
              fundName: f.fundName,
              portfolioWeightPct: f.portfolioWeightPct * scaleFactor,
              holdings: f.holdings,
            ))
        .toList();

    final withCandidate = [
      ...adjustedFunds,
      FundWithHoldings(
        amfiCode: candidateFund.amfiCode,
        fundName: candidateFund.fundName,
        portfolioWeightPct: candidateWeightPct,
        holdings: candidateFund.holdings,
      ),
    ];

    final after = compute(withCandidate);

    // New overlaps involving the candidate
    final newOverlaps = after.fundPairOverlaps
        .where((p) =>
            p.amfiCodeA == candidateFund.amfiCode ||
            p.amfiCodeB == candidateFund.amfiCode)
        .toList();

    // Sector deltas
    final beforeSectors = {for (final s in before.sectorExposures) s.sectorName: s};
    final afterSectors = {for (final s in after.sectorExposures) s.sectorName: s};
    final allSectorNames = {...beforeSectors.keys, ...afterSectors.keys};
    final sectorDeltas = allSectorNames.map((name) {
      final b = beforeSectors[name];
      final a = afterSectors[name];
      return SectorDelta(
        sectorName: name,
        beforePct: b?.weightPct ?? 0,
        afterPct: a?.weightPct ?? 0,
        beforeRisk: b?.risk ?? RiskLevel.low,
        afterRisk: a?.risk ?? RiskLevel.low,
      );
    }).where((d) => (d.afterPct - d.beforePct).abs() > 0.5).toList()
      ..sort((a, b) => (b.afterPct - b.beforePct).compareTo(a.afterPct - a.beforePct));

    // Stock deltas (top movers only)
    final beforeStocks = {for (final s in before.stockExposures) s.companyName: s};
    final afterStocks = {for (final s in after.stockExposures) s.companyName: s};
    final allStockNames = {...beforeStocks.keys, ...afterStocks.keys};
    final stockDeltas = allStockNames.map((name) {
      final b = beforeStocks[name];
      final a = afterStocks[name];
      return StockDelta(
        companyName: name,
        beforePct: b?.effectiveWeightPct ?? 0,
        afterPct: a?.effectiveWeightPct ?? 0,
        beforeRisk: b?.risk ?? RiskLevel.low,
        afterRisk: a?.risk ?? RiskLevel.low,
      );
    }).where((d) => d.changed || (d.afterPct - d.beforePct).abs() > 1.0).toList()
      ..sort((a, b) => (b.afterPct - b.beforePct).compareTo(a.afterPct - a.beforePct));

    final candidateRisk = newOverlaps.any((o) => o.risk == RiskLevel.high)
        ? RiskLevel.high
        : newOverlaps.any((o) => o.risk == RiskLevel.moderate)
            ? RiskLevel.moderate
            : RiskLevel.low;

    return PreBuyAnalysis(
      before: before,
      after: after,
      newOverlaps: newOverlaps,
      sectorDeltas: sectorDeltas,
      stockDeltas: stockDeltas,
      candidateRisk: candidateRisk,
    );
  }

  // ── Stock Concentration ──────────────────────────────────────────────────

  static List<StockExposure> computeStockExposures(List<FundWithHoldings> funds) {
    final stockMap = <String, _StockAccum>{};

    for (final fund in funds) {
      for (final h in fund.holdings) {
        final name = h.companyName.trim();
        if (name.isEmpty) continue;

        final effective = fund.portfolioWeightPct * h.corpusPct / 100.0;
        final accum = stockMap.putIfAbsent(name, () => _StockAccum(sectorName: h.sectorName));
        accum.effectiveWeight += effective;
        accum.fundNames.add(fund.fundName);
      }
    }

    final result = stockMap.entries.map((e) {
      final risk = e.value.effectiveWeight > OverlapThresholds.stockHigh
          ? RiskLevel.high
          : e.value.effectiveWeight > OverlapThresholds.stockModerate
              ? RiskLevel.moderate
              : RiskLevel.low;
      return StockExposure(
        companyName: e.key,
        sectorName: e.value.sectorName,
        effectiveWeightPct: e.value.effectiveWeight,
        risk: risk,
        heldInFunds: e.value.fundNames.toList(),
      );
    }).toList()
      ..sort((a, b) => b.effectiveWeightPct.compareTo(a.effectiveWeightPct));

    return result.take(20).toList();
  }

  // ── Sector Concentration ─────────────────────────────────────────────────

  static List<SectorExposure> computeSectorExposures(List<FundWithHoldings> funds) {
    final sectorMap = <String, double>{};

    for (final fund in funds) {
      for (final h in fund.holdings) {
        final sector = (h.sectorName ?? 'Other').trim();
        if (sector.isEmpty) continue;

        final effective = fund.portfolioWeightPct * h.corpusPct / 100.0;
        sectorMap[sector] = (sectorMap[sector] ?? 0) + effective;
      }
    }

    final result = sectorMap.entries.map((e) {
      final risk = e.value > OverlapThresholds.sectorHigh
          ? RiskLevel.high
          : e.value > OverlapThresholds.sectorModerate
              ? RiskLevel.moderate
              : RiskLevel.low;
      return SectorExposure(
        sectorName: e.key,
        weightPct: e.value,
        risk: risk,
      );
    }).toList()
      ..sort((a, b) => b.weightPct.compareTo(a.weightPct));

    return result;
  }

  // ── Fund Pair Overlap ────────────────────────────────────────────────────

  static List<FundPairOverlap> computeFundPairOverlaps(List<FundWithHoldings> funds) {
    if (funds.length < 2) return [];

    final pairs = <FundPairOverlap>[];

    for (int i = 0; i < funds.length; i++) {
      for (int j = i + 1; j < funds.length; j++) {
        final a = funds[i];
        final b = funds[j];

        // Skip pairs where either fund has no holdings data.
        // This avoids misleading "0% overlap" when data simply hasn't
        // been fetched yet. Genuine 0% overlap between two funds WITH
        // data will still be computed and shown.
        if (a.holdings.isEmpty || b.holdings.isEmpty) continue;

        // Build weight maps by company name
        final weightsA = <String, double>{
          for (final h in a.holdings) h.companyName.trim(): h.corpusPct,
        };
        final weightsB = <String, double>{
          for (final h in b.holdings) h.companyName.trim(): h.corpusPct,
        };

        // Overlap = sum of min(weightA, weightB) for common stocks
        double overlap = 0;
        final common = <CommonHolding>[];
        for (final name in weightsA.keys) {
          if (weightsB.containsKey(name)) {
            final wA = weightsA[name]!;
            final wB = weightsB[name]!;
            final contribution = wA < wB ? wA : wB;
            overlap += contribution;
            common.add(CommonHolding(
              companyName: name,
              weightA: wA,
              weightB: wB,
              overlapContribution: contribution,
            ));
          }
        }
        // Sort by overlap contribution descending
        common.sort((a, b) => b.overlapContribution.compareTo(a.overlapContribution));

        final risk = overlap > OverlapThresholds.fundOverlapHigh
            ? RiskLevel.high
            : overlap > OverlapThresholds.fundOverlapModerate
                ? RiskLevel.moderate
                : RiskLevel.low;

        pairs.add(FundPairOverlap(
          fundNameA: a.fundName,
          fundNameB: b.fundName,
          amfiCodeA: a.amfiCode,
          amfiCodeB: b.amfiCode,
          overlapPct: overlap,
          risk: risk,
          commonHoldings: common,
        ));
      }
    }

    pairs.sort((a, b) => b.overlapPct.compareTo(a.overlapPct));
    return pairs;
  }
}

class _StockAccum {
  final String? sectorName;
  double effectiveWeight = 0;
  final Set<String> fundNames = {};

  _StockAccum({this.sectorName});
}
