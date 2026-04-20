import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/extensions/list_extensions.dart';
import '../../domain/usecases/calculate_sharpe.dart';
import '../../domain/usecases/calculate_rolling_returns.dart';
import 'auth_provider.dart';
import 'fund_provider.dart';

part 'analytics_provider.g.dart';

@riverpod
Future<FundAnalytics> fundAnalytics(FundAnalyticsRef ref, int amfiCode) async {
  final client = ref.read(supabaseClientProvider);

  // ── 1. Fund daily NAV history ────────────────────────────────────────────
  // navHistoryProvider owns the on-demand backfill (see fund_provider.dart),
  // so by the time this future resolves we either have ≥60 rows of real
  // history or it has propagated a real error to the caller. No more silent
  // empty fall-throughs that masquerade as "no data".
  final navHistoryRaw = await ref.watch(navHistoryProvider(amfiCode).future);

  final navPoints = navHistoryRaw.map((r) {
    return NavPoint(
      date: DateTime.parse(r['nav_date'] as String),
      nav: (r['nav'] as num).toDouble(),
    );
  }).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  if (navPoints.isEmpty) return FundAnalytics(amfiCode: amfiCode);

  // ── 2. Pull AMFI period returns + benchmark from fund_master row ─────────
  String? benchmarkName;
  double? amfiReturn1y, amfiReturn3y, amfiReturn5y;
  double? benchReturn1y, benchReturn3y, benchReturn5y;
  try {
    final row = await client
        .from('fund_master')
        .select(
            'benchmark_index, benchmark_tier1, return_1y, return_3y, return_5y, return_bench_1y, return_bench_3y, return_bench_5y')
        .eq('amfi_code', amfiCode)
        .maybeSingle();
    if (row != null) {
      benchmarkName = (row['benchmark_tier1'] as String?) ??
          (row['benchmark_index'] as String?);
      double? pct(dynamic v) =>
          v == null ? null : (v as num).toDouble() / 100.0;
      amfiReturn1y = pct(row['return_1y']);
      amfiReturn3y = pct(row['return_3y']);
      amfiReturn5y = pct(row['return_5y']);
      benchReturn1y = pct(row['return_bench_1y']);
      benchReturn3y = pct(row['return_bench_3y']);
      benchReturn5y = pct(row['return_bench_5y']);
    }
  } catch (_) {
    // non-fatal
  }

  // ── 3. Try to fetch benchmark daily NAV from index_nav_history ───────────
  List<NavPoint> benchmarkPoints = const [];
  if (benchmarkName != null && benchmarkName.isNotEmpty) {
    try {
      final fromDate =
          navPoints.first.date.toIso8601String().substring(0, 10);
      final raw = await client
          .from('index_nav_history')
          .select('nav_date, nav')
          .eq('index_name', benchmarkName)
          .gte('nav_date', fromDate)
          .order('nav_date', ascending: true);
      benchmarkPoints = (raw as List)
          .map((r) {
            final m = r as Map<String, dynamic>;
            return NavPoint(
              date: DateTime.parse(m['nav_date'] as String),
              nav: (m['nav'] as num).toDouble(),
            );
          })
          .toList();
    } catch (_) {
      // non-fatal
    }
  }

  // ── 4. Compute fund-only metrics ─────────────────────────────────────────
  final dailyReturns = _dailyReturns(navPoints);
  final meanAnn =
      dailyReturns.isEmpty ? double.nan : dailyReturns.mean * 252;
  final stdDevAnn = SharpeCalculator.annualisedVolatility(navPoints);
  final cagrFromHistory = _cagrFromHistory(navPoints);
  final sharpe = SharpeCalculator.compute(navPoints);
  final sortino = SortinoCalculator.compute(navPoints);
  final maxDrawdown = MaxDrawdownCalculator.compute(navPoints);
  final rolling = RollingReturnsCalculator.compute(navPoints);

  // ── 5. Benchmark-relative metrics ────────────────────────────────────────
  double alpha = double.nan;
  double beta = double.nan;
  double trackingError = double.nan;
  double excessReturn = double.nan;

  if (benchmarkPoints.length >= 20) {
    final ab = AlphaBetaCalculator.compute(
      fundNav: navPoints,
      benchmarkNav: benchmarkPoints,
    );
    alpha = ab.alpha;
    beta = ab.beta;
    trackingError = TrackingErrorCalculator.compute(
      fundNav: navPoints,
      benchmarkNav: benchmarkPoints,
    );
    excessReturn = ExcessReturnCalculator.computeFromDaily(
      fundNav: navPoints,
      benchmarkNav: benchmarkPoints,
    );
  }

  // Fallback for excess return: use the longest available AMFI window
  if (excessReturn.isNaN) {
    final fromWindow = ExcessReturnCalculator.computeFromWindow(
      fundReturn: amfiReturn5y ?? amfiReturn3y ?? amfiReturn1y,
      benchmarkReturn: benchReturn5y ?? benchReturn3y ?? benchReturn1y,
    );
    if (!fromWindow.isNaN) excessReturn = fromWindow;
  }

  // Prefer AMFI-published 5y CAGR over the daily-derived one when present
  // (matches what the screener shows).
  final cagr = amfiReturn5y ?? amfiReturn3y ?? amfiReturn1y ?? cagrFromHistory;

  double? clean(double v) => v.isNaN || v.isInfinite ? null : v;

  return FundAnalytics(
    amfiCode: amfiCode,
    cagr: clean(cagr),
    meanAnnualised: clean(meanAnn),
    stdDev: clean(stdDevAnn),
    sharpe: clean(sharpe),
    sortino: clean(sortino),
    maxDrawdown: clean(maxDrawdown),
    alpha: clean(alpha),
    beta: clean(beta),
    trackingError: clean(trackingError),
    excessReturn: clean(excessReturn),
    benchmarkName: benchmarkName,
    benchmarkReturn1y: benchReturn1y,
    benchmarkReturn3y: benchReturn3y,
    benchmarkReturn5y: benchReturn5y,
    rollingReturns: rolling,
    navPoints: navPoints,
    benchmarkPoints: benchmarkPoints,
  );
}

List<double> _dailyReturns(List<NavPoint> sorted) {
  if (sorted.length < 2) return const [];
  return sorted.consecutivePairs.map((pair) {
    final prev = pair.$1.nav;
    final curr = pair.$2.nav;
    if (prev <= 0) return 0.0;
    return (curr - prev) / prev;
  }).toList();
}

double _cagrFromHistory(List<NavPoint> sorted) {
  if (sorted.length < 2) return double.nan;
  final first = sorted.first;
  final last = sorted.last;
  if (first.nav <= 0 || last.nav <= 0) return double.nan;
  final years = last.date.difference(first.date).inDays / 365.25;
  if (years <= 0) return double.nan;
  return math.pow(last.nav / first.nav, 1.0 / years).toDouble() - 1.0;
}

class FundAnalytics {
  const FundAnalytics({
    required this.amfiCode,
    this.cagr,
    this.meanAnnualised,
    this.stdDev,
    this.sharpe,
    this.sortino,
    this.alpha,
    this.beta,
    this.maxDrawdown,
    this.trackingError,
    this.excessReturn,
    this.benchmarkName,
    this.benchmarkReturn1y,
    this.benchmarkReturn3y,
    this.benchmarkReturn5y,
    this.rollingReturns = const [],
    this.navPoints = const [],
    this.benchmarkPoints = const [],
  });

  final int amfiCode;

  /// CAGR / annualised return (decimal, e.g. 0.124 = 12.4%).
  final double? cagr;

  /// Mean of daily returns × 252 (decimal).
  final double? meanAnnualised;

  /// Annualised standard deviation of daily returns (decimal).
  final double? stdDev;

  final double? sharpe;
  final double? sortino;
  final double? alpha;
  final double? beta;

  /// Max drawdown as a decimal (negative, e.g. -0.34 = -34%).
  final double? maxDrawdown;

  /// Annualised tracking error (decimal).
  final double? trackingError;

  /// Annualised excess return vs benchmark (decimal).
  final double? excessReturn;

  /// Display name of the benchmark used (when known).
  final String? benchmarkName;

  /// Benchmark window returns from AMFI (decimal).
  final double? benchmarkReturn1y;
  final double? benchmarkReturn3y;
  final double? benchmarkReturn5y;

  final List<RollingReturnPoint> rollingReturns;
  final List<NavPoint> navPoints;
  final List<NavPoint> benchmarkPoints;
}
