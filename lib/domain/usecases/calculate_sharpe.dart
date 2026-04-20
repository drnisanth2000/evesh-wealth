import 'dart:math' as math;
import '../../core/constants/app_constants.dart';
import '../../core/extensions/list_extensions.dart';

/// NAV data point for analytics calculations
class NavPoint {
  const NavPoint({required this.date, required this.nav});
  final DateTime date;
  final double nav;
}

/// Sharpe Ratio — risk-adjusted return vs risk-free rate
///
/// Formula:
///   Sharpe = (AnnualisedReturn - RiskFreeRate) / AnnualisedStdDev
///
/// Where daily returns are computed from NAV history and then annualised.
class SharpeCalculator {
  SharpeCalculator._();

  /// Compute Sharpe Ratio from NAV history.
  /// [riskFreeRate] defaults to 6.5% (10Y G-Sec yield). Pass as annual rate, e.g. 0.065.
  static double compute(
    List<NavPoint> navHistory, {
    double riskFreeRate = AppConstants.defaultRiskFreeRate,
  }) {
    final dailyReturns = _dailyReturns(navHistory);
    if (dailyReturns.length < 20) return double.nan; // need at least 20 trading days

    final annualisedReturn = _annualise(dailyReturns.mean);
    final annualisedStdDev = dailyReturns.stdDev * math.sqrt(252);

    if (annualisedStdDev <= 0) return double.nan;
    return (annualisedReturn - riskFreeRate) / annualisedStdDev;
  }

  /// Compute annualised standard deviation (volatility) from NAV history
  static double annualisedVolatility(List<NavPoint> navHistory) {
    final dailyReturns = _dailyReturns(navHistory);
    if (dailyReturns.length < 10) return double.nan;
    return dailyReturns.stdDev * math.sqrt(252);
  }

  /// Compute annualised return from NAV history
  static double annualisedReturn(List<NavPoint> navHistory) {
    final dailyReturns = _dailyReturns(navHistory);
    if (dailyReturns.isEmpty) return double.nan;
    return _annualise(dailyReturns.mean);
  }

  static List<double> _dailyReturns(List<NavPoint> navHistory) {
    if (navHistory.length < 2) return [];
    final sorted = List<NavPoint>.from(navHistory)
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted.consecutivePairs.map((pair) {
      final prev = pair.$1.nav;
      final curr = pair.$2.nav;
      if (prev <= 0) return 0.0;
      return (curr - prev) / prev;
    }).toList();
  }

  static double _annualise(double dailyMeanReturn) => dailyMeanReturn * 252;
}

/// Sortino Ratio — like Sharpe but uses only downside deviation
///
/// Formula:
///   Sortino = (AnnualisedReturn - RiskFreeRate) / AnnualisedDownsideDeviation
class SortinoCalculator {
  SortinoCalculator._();

  static double compute(
    List<NavPoint> navHistory, {
    double riskFreeRate = AppConstants.defaultRiskFreeRate,
  }) {
    if (navHistory.length < 2) return double.nan;

    final sorted = List<NavPoint>.from(navHistory)
      ..sort((a, b) => a.date.compareTo(b.date));

    final dailyReturns = sorted.consecutivePairs.map((pair) {
      final prev = pair.$1.nav;
      final curr = pair.$2.nav;
      if (prev <= 0) return 0.0;
      return (curr - prev) / prev;
    }).toList();

    if (dailyReturns.length < 20) return double.nan;

    final annualisedReturn = dailyReturns.mean * 252;
    final downsideDev = dailyReturns.downsideDeviation * math.sqrt(252);

    if (downsideDev <= 0) return double.nan;
    return (annualisedReturn - riskFreeRate) / downsideDev;
  }
}

/// Alpha and Beta vs benchmark
///
/// Beta = Cov(fund, benchmark) / Var(benchmark)
/// Alpha = fundReturn - (riskFree + Beta × (benchmarkReturn - riskFree))
class AlphaBetaCalculator {
  AlphaBetaCalculator._();

  static ({double alpha, double beta}) compute({
    required List<NavPoint> fundNav,
    required List<NavPoint> benchmarkNav,
    double riskFreeRate = AppConstants.defaultRiskFreeRate,
  }) {
    if (fundNav.length < 20 || benchmarkNav.length < 20) {
      return (alpha: double.nan, beta: double.nan);
    }

    // Align dates between fund and benchmark
    final fundMap = {for (final p in fundNav) p.date.isoString: p.nav};
    final benchMap = {for (final p in benchmarkNav) p.date.isoString: p.nav};
    final commonDates = fundMap.keys.where(benchMap.containsKey).toList()..sort();

    if (commonDates.length < 20) return (alpha: double.nan, beta: double.nan);

    final fundReturns = <double>[];
    final benchReturns = <double>[];

    for (var i = 1; i < commonDates.length; i++) {
      final prev = commonDates[i - 1];
      final curr = commonDates[i];
      final fPrev = fundMap[prev]!;
      final fCurr = fundMap[curr]!;
      final bPrev = benchMap[prev]!;
      final bCurr = benchMap[curr]!;
      if (fPrev <= 0 || bPrev <= 0) continue;
      fundReturns.add((fCurr - fPrev) / fPrev);
      benchReturns.add((bCurr - bPrev) / bPrev);
    }

    if (fundReturns.length < 10) return (alpha: double.nan, beta: double.nan);

    final covFB = _covariance(fundReturns, benchReturns);
    final varB = benchReturns.variance;

    if (varB <= 0) return (alpha: double.nan, beta: double.nan);

    final beta = covFB / varB;
    final annFundReturn = fundReturns.mean * 252;
    final annBenchReturn = benchReturns.mean * 252;
    final alpha = annFundReturn - (riskFreeRate + beta * (annBenchReturn - riskFreeRate));

    return (alpha: alpha, beta: beta);
  }

  static double _covariance(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0;
    final meanX = x.mean;
    final meanY = y.mean;
    double sum = 0;
    for (var i = 0; i < x.length; i++) {
      sum += (x[i] - meanX) * (y[i] - meanY);
    }
    return sum / (x.length - 1);
  }
}

/// Tracking Error — annualised standard deviation of (fund − benchmark) daily
/// returns. Measures how closely the fund tracks its benchmark.
///
///   TE = stdDev(fundReturns_t − benchmarkReturns_t) × √252
class TrackingErrorCalculator {
  TrackingErrorCalculator._();

  static double compute({
    required List<NavPoint> fundNav,
    required List<NavPoint> benchmarkNav,
  }) {
    if (fundNav.length < 20 || benchmarkNav.length < 20) return double.nan;

    final fundMap = {for (final p in fundNav) p.date.isoString: p.nav};
    final benchMap = {for (final p in benchmarkNav) p.date.isoString: p.nav};
    final commonDates = fundMap.keys.where(benchMap.containsKey).toList()..sort();
    if (commonDates.length < 20) return double.nan;

    final diffs = <double>[];
    for (var i = 1; i < commonDates.length; i++) {
      final fPrev = fundMap[commonDates[i - 1]]!;
      final fCurr = fundMap[commonDates[i]]!;
      final bPrev = benchMap[commonDates[i - 1]]!;
      final bCurr = benchMap[commonDates[i]]!;
      if (fPrev <= 0 || bPrev <= 0) continue;
      final fr = (fCurr - fPrev) / fPrev;
      final br = (bCurr - bPrev) / bPrev;
      diffs.add(fr - br);
    }
    if (diffs.length < 20) return double.nan;
    return diffs.stdDev * math.sqrt(252);
  }
}

/// Excess Return vs Benchmark — annualised fund CAGR minus annualised benchmark CAGR.
/// Falls back to point-in-time return windows when daily benchmark data is missing.
class ExcessReturnCalculator {
  ExcessReturnCalculator._();

  /// Compute from aligned daily NAV series (preferred path).
  static double computeFromDaily({
    required List<NavPoint> fundNav,
    required List<NavPoint> benchmarkNav,
  }) {
    if (fundNav.length < 20 || benchmarkNav.length < 20) return double.nan;
    final fundMap = {for (final p in fundNav) p.date.isoString: p.nav};
    final benchMap = {for (final p in benchmarkNav) p.date.isoString: p.nav};
    final common = fundMap.keys.where(benchMap.containsKey).toList()..sort();
    if (common.length < 20) return double.nan;

    final fundReturns = <double>[];
    final benchReturns = <double>[];
    for (var i = 1; i < common.length; i++) {
      final fPrev = fundMap[common[i - 1]]!;
      final fCurr = fundMap[common[i]]!;
      final bPrev = benchMap[common[i - 1]]!;
      final bCurr = benchMap[common[i]]!;
      if (fPrev <= 0 || bPrev <= 0) continue;
      fundReturns.add((fCurr - fPrev) / fPrev);
      benchReturns.add((bCurr - bPrev) / bPrev);
    }
    if (fundReturns.isEmpty) return double.nan;
    return (fundReturns.mean - benchReturns.mean) * 252;
  }

  /// Fallback: subtract a single window's return (e.g. 3-year) directly.
  /// Inputs are decimal percentages (e.g. 0.1234 for 12.34%).
  static double computeFromWindow({
    required double? fundReturn,
    required double? benchmarkReturn,
  }) {
    if (fundReturn == null || benchmarkReturn == null) return double.nan;
    return fundReturn - benchmarkReturn;
  }
}

/// Maximum Drawdown — largest peak-to-trough decline in NAV
class MaxDrawdownCalculator {
  MaxDrawdownCalculator._();

  /// Returns max drawdown as a decimal (e.g. -0.35 = -35%)
  static double compute(List<NavPoint> navHistory) {
    if (navHistory.isEmpty) return double.nan;
    final sorted = List<NavPoint>.from(navHistory)
      ..sort((a, b) => a.date.compareTo(b.date));

    double peak = sorted.first.nav;
    double maxDrawdown = 0;

    for (final point in sorted) {
      if (point.nav > peak) peak = point.nav;
      final drawdown = peak > 0 ? (point.nav - peak) / peak : 0.0;
      if (drawdown < maxDrawdown) maxDrawdown = drawdown;
    }

    return maxDrawdown;
  }
}

extension on DateTime {
  String get isoString => toIso8601String().substring(0, 10);
}
