import '../models/recommendation_models.dart';
import 'score_funds.dart';

/// Layers 4-6 of the Fund Recommendation Engine:
///   4. Portfolio Fit — maps scored funds to allocation gaps
///   5. Diversification — AMC concentration, overlap detection
///   6. Explainability — human-readable reasons and warnings
class RecommendationEngine {
  /// Max funds per asset class in final recommendations.
  static const _maxPerAssetClass = 3;

  /// Max funds from same AMC across all recommendations.
  static const _maxPerAmc = 2;

  /// Maps tax_category → asset class key (matching wealth_planner_provider.dart).
  static const _taxCatToAssetClass = <String, String>{
    'equity': 'coreEquity',
    'hybrid-e': 'hybrid',
    'hybrid-d': 'hybrid',
    'debt': 'debt',
    'gold': 'gold',
    'gold-fof': 'gold',
    'international': 'satelliteEquity',
    'sgb': 'gold',
  };

  /// Display labels for asset class keys.
  static const _assetClassLabels = <String, String>{
    'coreEquity': 'Core Equity',
    'satelliteEquity': 'Satellite Equity',
    'hybrid': 'Hybrid',
    'debt': 'Debt',
    'liquid': 'Liquid',
    'gold': 'Gold',
    'alternatives': 'Alternate',
  };

  static RecommendationResult recommend({
    required List<Map<String, dynamic>> funds,
    required double surplusAmount,
    required Map<String, double> currentAllocation,
    required Map<String, double> idealAllocation,
    required Set<int> heldAmfiCodes,
    required bool sipRecommended,
    List<Map<String, dynamic>>? heldFundDetails,
  }) {
    final fundsEvaluated = funds.length;

    if (surplusAmount <= 0 || funds.isEmpty) {
      return RecommendationResult(
        surplusAmount: surplusAmount,
        sipRecommended: sipRecommended,
        sipRationale: sipRecommended
            ? 'SIP recommended to average cost over time.'
            : 'Lumpsum is suitable at current valuations.',
        recommendations: [],
        fundsEvaluated: fundsEvaluated,
        fundsPassedGate: 0,
        allocationGaps: {},
      );
    }

    // Score all funds (Layers 1-3)
    final scored = FundScorer.score(funds);
    final fundsPassedGate = scored.length;

    // Layer 4: Portfolio Fit — compute allocation gaps
    final allocationGaps = <String, double>{};
    for (final entry in idealAllocation.entries) {
      final current = currentAllocation[entry.key] ?? 0;
      final gap = entry.value - current;
      if (gap > 0.5) {
        allocationGaps[entry.key] = gap;
      }
    }

    if (allocationGaps.isEmpty) {
      return RecommendationResult(
        surplusAmount: surplusAmount,
        sipRecommended: sipRecommended,
        sipRationale: sipRecommended
            ? 'SIP recommended to average cost over time.'
            : 'Lumpsum is suitable at current valuations.',
        recommendations: [],
        fundsEvaluated: fundsEvaluated,
        fundsPassedGate: fundsPassedGate,
        allocationGaps: {},
      );
    }

    // Proportional surplus allocation per gap
    final totalGap = allocationGaps.values.fold(0.0, (a, b) => a + b);
    final surplusPerClass = <String, double>{};
    for (final entry in allocationGaps.entries) {
      surplusPerClass[entry.key] = surplusAmount * (entry.value / totalGap);
    }

    // Map scored funds to asset classes
    final fundsByAssetClass = <String, List<FundScore>>{};
    for (final fs in scored) {
      final assetClass = _resolveAssetClass(fs);
      if (assetClass != null && allocationGaps.containsKey(assetClass)) {
        fundsByAssetClass.putIfAbsent(assetClass, () => []).add(fs);
      }
    }

    // Layer 5: Diversification
    final recommendations = <FundRecommendation>[];
    final amcCount = <String, int>{};

    for (final entry in fundsByAssetClass.entries) {
      final assetClass = entry.key;
      final classFunds = entry.value;
      final classSurplus = surplusPerClass[assetClass] ?? 0;
      if (classSurplus < 500) continue;

      var picked = 0;
      for (final fs in classFunds) {
        if (picked >= _maxPerAssetClass) break;

        final amc = fs.amc ?? 'Unknown';
        final currentAmcCount = amcCount[amc] ?? 0;
        if (currentAmcCount >= _maxPerAmc) continue;

        if (heldAmfiCodes.contains(fs.amfiCode)) continue;

        // Layer 6: Explainability
        final reasons = _buildReasons(fs, assetClass, allocationGaps[assetClass]!);
        final warnings = _buildWarnings(fs, amc, heldFundDetails);

        final perFundAmount = classSurplus / _maxPerAssetClass;

        recommendations.add(FundRecommendation(
          fundScore: fs,
          targetAssetClass: assetClass,
          targetAssetClassLabel: _assetClassLabels[assetClass] ?? assetClass,
          allocationGapPct: allocationGaps[assetClass]!,
          suggestedAmount: perFundAmount,
          isSip: sipRecommended,
          reasons: reasons,
          warnings: warnings,
        ));

        amcCount[amc] = currentAmcCount + 1;
        picked++;
      }
    }

    // Re-distribute surplus evenly among actual picks per class
    final picksByClass = <String, List<FundRecommendation>>{};
    for (final rec in recommendations) {
      picksByClass.putIfAbsent(rec.targetAssetClass, () => []).add(rec);
    }
    final adjusted = <FundRecommendation>[];
    for (final entry in picksByClass.entries) {
      final classSurplus = surplusPerClass[entry.key] ?? 0;
      final perFund = classSurplus / entry.value.length;
      for (final rec in entry.value) {
        adjusted.add(FundRecommendation(
          fundScore: rec.fundScore,
          targetAssetClass: rec.targetAssetClass,
          targetAssetClassLabel: rec.targetAssetClassLabel,
          allocationGapPct: rec.allocationGapPct,
          suggestedAmount: perFund,
          isSip: rec.isSip,
          reasons: rec.reasons,
          warnings: rec.warnings,
        ));
      }
    }

    // Sort by gap size (biggest gap first), then by score within
    adjusted.sort((a, b) {
      final gapCmp = b.allocationGapPct.compareTo(a.allocationGapPct);
      if (gapCmp != 0) return gapCmp;
      return b.fundScore.score.compareTo(a.fundScore.score);
    });

    return RecommendationResult(
      surplusAmount: surplusAmount,
      sipRecommended: sipRecommended,
      sipRationale: sipRecommended
          ? 'SIP recommended to average cost over time.'
          : 'Lumpsum is suitable at current valuations.',
      recommendations: adjusted,
      fundsEvaluated: fundsEvaluated,
      fundsPassedGate: fundsPassedGate,
      allocationGaps: allocationGaps,
    );
  }

  static String? _resolveAssetClass(FundScore fs) {
    final taxCat = (fs.taxCategory ?? '').toLowerCase();
    if (_taxCatToAssetClass.containsKey(taxCat)) {
      return _taxCatToAssetClass[taxCat];
    }

    final cat = (fs.category).toLowerCase();
    if (cat.contains('liquid') || cat.contains('overnight') ||
        cat.contains('money market')) {
      return 'liquid';
    }
    if (cat.contains('debt') || cat.contains('gilt') ||
        cat.contains('corporate bond') || cat.contains('banking') ||
        cat.contains('credit risk')) {
      return 'debt';
    }
    if (cat.contains('hybrid') || cat.contains('balanced') ||
        cat.contains('dynamic asset')) {
      return 'hybrid';
    }
    if (cat.contains('gold')) return 'gold';
    if (cat.contains('international') || cat.contains('global')) {
      return 'satelliteEquity';
    }

    if (cat.contains('large') || cat.contains('mid') || cat.contains('small') ||
        cat.contains('flexi') || cat.contains('multi') || cat.contains('elss') ||
        cat.contains('value') || cat.contains('contra') || cat.contains('focused') ||
        cat.contains('dividend yield') || cat.contains('sectoral') ||
        cat.contains('thematic')) {
      return 'coreEquity';
    }

    return null;
  }

  static List<String> _buildReasons(
    FundScore fs,
    String assetClass,
    double gapPct,
  ) {
    final reasons = <String>[];

    final label = _assetClassLabels[assetClass] ?? assetClass;
    reasons.add('Fills $label gap (${gapPct.toStringAsFixed(1)}% below target)');

    if (fs.score >= 80) {
      reasons.add('Top-rated fund (score ${fs.score.toStringAsFixed(0)}/100)');
    } else if (fs.score >= 60) {
      reasons.add('Well-rated fund (score ${fs.score.toStringAsFixed(0)}/100)');
    }

    if (fs.return3y != null && fs.return3y! > 15) {
      reasons.add('Strong 3Y return: ${fs.return3y!.toStringAsFixed(1)}%');
    }

    if (fs.expenseRatio != null && fs.expenseRatio! < 0.30) {
      reasons.add('Low cost: ER ${fs.expenseRatio!.toStringAsFixed(2)}%');
    }

    if (fs.crisilRating != null &&
        (fs.crisilRating!.contains('1') || fs.crisilRating!.contains('2'))) {
      reasons.add('CRISIL Rank ${fs.crisilRating}');
    }

    return reasons;
  }

  static List<String> _buildWarnings(
    FundScore fs,
    String amc,
    List<Map<String, dynamic>>? heldFundDetails,
  ) {
    final warnings = <String>[];

    if (heldFundDetails != null) {
      final hasOverlap = heldFundDetails.any((held) =>
          held['amc'] == amc && held['category'] == fs.category);
      if (hasOverlap) {
        warnings.add('You already hold a $amc fund in ${fs.category}');
      }
    }

    if (fs.volatility1y != null && fs.volatility1y! > 25) {
      warnings.add('High volatility (${fs.volatility1y!.toStringAsFixed(1)}%)');
    }

    return warnings;
  }
}
