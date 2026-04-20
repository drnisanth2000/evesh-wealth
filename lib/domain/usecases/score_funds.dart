import 'dart:math' as math;
import '../models/recommendation_models.dart';

/// Layers 1-3 of the Fund Recommendation Engine:
///   1. Quality Gate — filters out unsuitable funds
///   2. 100-point Scoring — percentile-based multi-dimensional scoring
///   3. Category Adjustments — bonus/penalty based on fund category
class FundScorer {
  /// Accepts raw fund maps (matching FundModel JSON keys from Supabase)
  /// and returns scored funds sorted by score descending.
  static List<FundScore> score(List<Map<String, dynamic>> funds) {
    // Layer 1: Quality Gate
    final gated = funds.where(_passesQualityGate).toList();
    if (gated.isEmpty) return [];

    // Layer 2: Percentile-based scoring within each category
    final categoryGroups = <String, List<Map<String, dynamic>>>{};
    for (final f in gated) {
      final cat = (f['category'] as String?) ?? 'Unknown';
      categoryGroups.putIfAbsent(cat, () => []).add(f);
    }

    final scored = <FundScore>[];
    for (final entry in categoryGroups.entries) {
      scored.addAll(_scoreCategory(entry.key, entry.value));
    }

    // Sort by score descending
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  // ── Layer 1: Quality Gate ──────────────────────────────────────────────────

  static bool _passesQualityGate(Map<String, dynamic> f) {
    // Must be Direct plan
    final planType = (f['plan_type'] as String?) ?? '';
    if (planType != 'Direct') return false;

    // AUM ≥ 500 Cr
    final aum = (f['aum_cr'] as num?)?.toDouble() ?? 0;
    if (aum < 500) return false;

    // Track record ≥ 3 years
    final launchStr = f['launch_date'] as String?;
    if (launchStr != null && launchStr.isNotEmpty) {
      final launch = DateTime.tryParse(launchStr);
      if (launch != null) {
        final yearsOld = DateTime.now().difference(launch).inDays / 365.25;
        if (yearsOld < 3) return false;
      }
    }

    // Must have at least return_1y or return_3y
    final r1y = f['return_1y'] as num?;
    final r3y = f['return_3y'] as num?;
    if (r1y == null && r3y == null) return false;

    // ER cap by category type
    final er = (f['expense_ratio'] as num?)?.toDouble();
    if (er != null) {
      final cat = ((f['category'] as String?) ?? '').toLowerCase();
      if (cat.contains('liquid') || cat.contains('overnight')) {
        if (er > 0.50) return false;
      } else if (cat.contains('debt') || cat.contains('gilt') ||
          cat.contains('money market') || cat.contains('corporate bond') ||
          cat.contains('banking')) {
        if (er > 1.00) return false;
      } else {
        if (er > 2.00) return false;
      }
    }

    return true;
  }

  // ── Layer 2: 100-point Scoring ─────────────────────────────────────────────

  static List<FundScore> _scoreCategory(
    String category,
    List<Map<String, dynamic>> funds,
  ) {
    if (funds.isEmpty) return [];

    final catLower = category.toLowerCase();
    final isLiquidCategory = catLower.contains('liquid') ||
        catLower.contains('overnight') ||
        catLower.contains('money market');

    // Collect raw values for percentile computation
    final r1yVals = _nonNullDoubles(funds, 'return_1y');
    final r3yVals = _nonNullDoubles(funds, 'return_3y');
    final r5yVals = _nonNullDoubles(funds, 'return_5y');
    final erVals = _nonNullDoubles(funds, 'expense_ratio');
    final volVals = _nonNullDoubles(funds, 'volatility_1y');

    final scored = <FundScore>[];
    for (final f in funds) {
      // ── Returns (40 pts) ──
      final r1y = (f['return_1y'] as num?)?.toDouble();
      final r3y = (f['return_3y'] as num?)?.toDouble();
      final r5y = (f['return_5y'] as num?)?.toDouble();

      final r1yScore = r1y != null ? _percentileScore(r1y, r1yVals) * 10 : 0.0;
      final r3yScore = r3y != null ? _percentileScore(r3y, r3yVals) * 15 : 0.0;
      final r5yScore = r5y != null ? _percentileScore(r5y, r5yVals) * 15 : 0.0;

      // Normalize: if missing 5Y, redistribute to available
      double returnsMax = 0;
      double returnsActual = 0;
      if (r1y != null) { returnsMax += 10; returnsActual += r1yScore; }
      if (r3y != null) { returnsMax += 15; returnsActual += r3yScore; }
      if (r5y != null) { returnsMax += 15; returnsActual += r5yScore; }

      final returnsScore = returnsMax > 0
          ? (returnsActual / returnsMax) * 40
          : 0.0;

      // ── Risk-adjusted (25 pts) ──
      final vol = (f['volatility_1y'] as num?)?.toDouble();
      double riskScore = 12.5; // default mid-range if no volatility data

      if (vol != null && vol > 0 && r3y != null) {
        final sharpe = r3y / vol;
        final sharpeVals = <double>[];
        for (final g in funds) {
          final gVol = (g['volatility_1y'] as num?)?.toDouble();
          final gR3 = (g['return_3y'] as num?)?.toDouble();
          if (gVol != null && gVol > 0 && gR3 != null) {
            sharpeVals.add(gR3 / gVol);
          }
        }
        final sharpePctile = sharpeVals.length > 1
            ? _percentileScore(sharpe, sharpeVals)
            : 0.5;

        final volPctile = volVals.length > 1
            ? (1.0 - _percentileScore(vol, volVals))
            : 0.5;

        riskScore = sharpePctile * 15 + volPctile * 10;
      }

      // ── Cost (15 pts, or up to 55 pts for liquid/overnight categories) ──
      // For liquid/money market funds, ER is the dominant factor — returns
      // are nearly identical across funds, so cost weight is increased.
      final er = (f['expense_ratio'] as num?)?.toDouble();
      double costScore = 7.5;
      if (er != null && erVals.length > 1) {
        final erPctile = 1.0 - _percentileScore(er, erVals);
        costScore = isLiquidCategory ? erPctile * 55 : erPctile * 15;
      }

      // ── Rating (10 pts) ──
      final crisilScore = _crisilPoints(f['crisil_rating']?.toString()) * 6;
      final fundRatingScore = _fundRatingPoints(f['fund_rating']?.toString()) * 4;
      final ratingScore = crisilScore + fundRatingScore;

      // ── Fund House (10 pts) ──
      final fundHouseScore = _fundHousePoints(f['amc'] as String?, funds);

      // For liquid funds, cost can be up to 55 pts; cap breakdown.cost at 55
      // but keep the overall score clamped to 100 after adjustments.
      final costMax = isLiquidCategory ? 55.0 : 15.0;
      final breakdown = ScoreBreakdown(
        returns: _clamp(returnsScore, 0, 40),
        riskAdjusted: _clamp(riskScore, 0, 25),
        cost: _clamp(costScore, 0, costMax),
        rating: _clamp(ratingScore, 0, 10),
        fundHouse: _clamp(fundHouseScore, 0, 10),
      );

      // Layer 3: Category adjustments
      final rawScore = breakdown.total;
      final adjusted = _applyCategoryAdjustments(rawScore, f, category);

      scored.add(FundScore(
        amfiCode: (f['amfi_code'] as num).toInt(),
        fundName: f['fund_name'] as String,
        category: category,
        subCategory: f['sub_category'] as String?,
        taxCategory: f['tax_category'] as String?,
        amc: f['amc'] as String?,
        score: _clamp(adjusted, 0, 100),
        breakdown: breakdown,
        return1y: r1y,
        return3y: r3y,
        return5y: r5y,
        expenseRatio: er,
        volatility1y: vol,
        aumCr: (f['aum_cr'] as num?)?.toDouble(),
        crisilRating: f['crisil_rating']?.toString(),
        fundRating: f['fund_rating']?.toString(),
      ));
    }

    return scored;
  }

  // ── Layer 3: Category Adjustments ──────────────────────────────────────────

  static double _applyCategoryAdjustments(
    double rawScore,
    Map<String, dynamic> f,
    String category,
  ) {
    double adj = rawScore;
    final catLower = category.toLowerCase();
    final subCat = ((f['sub_category'] as String?) ?? '').toLowerCase();
    final fundName = ((f['fund_name'] as String?) ?? '').toLowerCase();
    final er = (f['expense_ratio'] as num?)?.toDouble() ?? 1.0;

    final isIndex = subCat.contains('index') ||
        fundName.contains('index') ||
        fundName.contains('nifty') ||
        fundName.contains('sensex') ||
        fundName.contains('etf');

    if (catLower.contains('large cap') || catLower == 'large cap') {
      if (isIndex && er < 0.30) adj += 5;
      if (!isIndex && er > 1.5) adj -= 3;
    }

    if (catLower.contains('liquid') || catLower.contains('overnight') ||
        catLower.contains('money market')) {
      if (er < 0.10) adj += 5;
      if (er > 0.25) adj -= 3;
    }

    if (catLower.contains('debt') || catLower.contains('gilt') ||
        catLower.contains('corporate bond') || catLower.contains('banking')) {
      final crisil = f['crisil_rating']?.toString();
      if (crisil != null && (crisil.contains('1') || crisil.contains('2'))) {
        adj += 3;
      }
    }

    if (catLower.contains('mid cap') || catLower.contains('small cap') ||
        catLower.contains('flexi cap')) {
      final r3y = (f['return_3y'] as num?)?.toDouble() ?? 0;
      if (r3y > 20) adj += 3;
    }

    return adj;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static double _percentileScore(double value, List<double> values) {
    if (values.isEmpty) return 0.5;
    if (values.length == 1) return 0.5;
    final sorted = List<double>.from(values)..sort();
    final rank = sorted.where((v) => v <= value).length;
    return (rank - 1) / (sorted.length - 1);
  }

  static double _crisilPoints(String? rating) {
    if (rating == null) return 0.3;
    if (rating.contains('1')) return 1.0;
    if (rating.contains('2')) return 0.8;
    if (rating.contains('3')) return 0.6;
    if (rating.contains('4')) return 0.4;
    if (rating.contains('5')) return 0.2;
    return 0.3;
  }

  static double _fundRatingPoints(String? rating) {
    if (rating == null) return 0.3;
    final val = double.tryParse(rating);
    if (val == null) return 0.3;
    return (val / 5.0).clamp(0, 1);
  }

  static double _fundHousePoints(String? amc, List<Map<String, dynamic>> peers) {
    if (amc == null || amc.isEmpty) return 5.0;
    final amcFunds = peers.where((f) => f['amc'] == amc).toList();
    if (amcFunds.isEmpty) return 5.0;

    double totalCrisil = 0;
    int count = 0;
    for (final f in amcFunds) {
      final c = _crisilPoints(f['crisil_rating']?.toString());
      totalCrisil += c;
      count++;
    }
    return count > 0 ? (totalCrisil / count) * 10 : 5.0;
  }

  static List<double> _nonNullDoubles(
      List<Map<String, dynamic>> funds, String key) {
    return funds
        .map((f) => (f[key] as num?)?.toDouble())
        .where((v) => v != null)
        .cast<double>()
        .toList();
  }

  static double _clamp(double value, double min, double max) {
    return value.clamp(min, max);
  }
}
