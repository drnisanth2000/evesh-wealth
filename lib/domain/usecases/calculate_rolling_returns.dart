import 'dart:math' as math;

import 'calculate_sharpe.dart';

/// Rolling returns data point
class RollingReturnPoint {
  const RollingReturnPoint({
    required this.date,
    this.rolling1y,
    this.rolling3y,
    this.rolling5y,
  });

  final DateTime date;
  final double? rolling1y;   // 1-year rolling return ending on this date
  final double? rolling3y;   // 3-year rolling return ending on this date
  final double? rolling5y;   // 5-year rolling return ending on this date
}

/// Rolling Returns Calculator
///
/// For each date T, computes the CAGR from T-N years to T.
/// This shows how consistently a fund delivers returns across different time windows.
class RollingReturnsCalculator {
  RollingReturnsCalculator._();

  static List<RollingReturnPoint> compute(List<NavPoint> navHistory) {
    if (navHistory.length < 2) return [];

    // Sort once. The list is mostly already sorted; List.sort is stable & fast.
    final sorted = List<NavPoint>.from(navHistory)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Pre-extract parallel arrays of (normalised epoch ms, nav) so we can
    // do binary search (O(log n)) instead of relying on a HashMap that
    // requires the start date to be exactly a trading day.
    final n = sorted.length;
    final epochMs = List<int>.filled(n, 0);
    final navs = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      epochMs[i] = _normaliseDate(sorted[i].date).millisecondsSinceEpoch;
      navs[i] = sorted[i].nav;
    }

    final firstDate = sorted.first.date;

    final result = <RollingReturnPoint>[];
    for (int i = 0; i < n; i++) {
      final point = sorted[i];
      final endNav = navs[i];

      result.add(RollingReturnPoint(
        date: point.date,
        rolling1y: _rollingReturn(
          epochMs: epochMs,
          navs: navs,
          firstDate: firstDate,
          endIndex: i,
          endNav: endNav,
          years: 1,
        ),
        rolling3y: _rollingReturn(
          epochMs: epochMs,
          navs: navs,
          firstDate: firstDate,
          endIndex: i,
          endNav: endNav,
          years: 3,
        ),
        rolling5y: _rollingReturn(
          epochMs: epochMs,
          navs: navs,
          firstDate: firstDate,
          endIndex: i,
          endNav: endNav,
          years: 5,
        ),
      ));
    }

    return result;
  }

  /// Returns the CAGR over the last `years` years ending at `endIndex`,
  /// or null if the window is not yet covered by the history.
  ///
  /// We pick the NAV row whose normalised date is *closest* to the target
  /// start date, with no fixed-day tolerance — if the fund has any history
  /// at that point, we use it. The previous ±7 day window silently dropped
  /// any rolling point whose lookup landed on a long holiday cluster.
  static double? _rollingReturn({
    required List<int> epochMs,
    required List<double> navs,
    required DateTime firstDate,
    required int endIndex,
    required double endNav,
    required int years,
  }) {
    final endEpoch = epochMs[endIndex];
    final targetStart = DateTime.fromMillisecondsSinceEpoch(endEpoch)
        .subtract(Duration(days: (365.25 * years).round()));

    // Bail if the requested window predates the entire history (with a
    // small grace period — 14 days — so we don't lose the very first
    // qualifying point to off-by-a-week effects).
    if (targetStart.isBefore(firstDate.subtract(const Duration(days: 14)))) {
      return null;
    }

    final targetMs = targetStart.millisecondsSinceEpoch;
    final idx = _binarySearchNearest(epochMs, 0, endIndex, targetMs);
    if (idx < 0) return null;
    final startNav = navs[idx];

    // Reject if the matched row drifted by more than 30 days from target —
    // anything beyond that means the period really isn't covered.
    final drift = (epochMs[idx] - targetMs).abs();
    if (drift > const Duration(days: 30).inMilliseconds) return null;

    return _cagr(startNav, endNav, years.toDouble());
  }

  /// Binary search within epochMs[lo..hi] for the index whose value is
  /// closest to `target`. Returns -1 if the range is empty.
  static int _binarySearchNearest(
      List<int> epochMs, int lo, int hi, int target) {
    if (hi < lo) return -1;
    int low = lo;
    int high = hi;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (epochMs[mid] < target) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    // `low` is the first index whose epoch ≥ target. The nearest is either
    // `low` or `low - 1`.
    if (low <= lo) return lo;
    if (low > hi) return hi;
    final dHi = (epochMs[low] - target).abs();
    final dLo = (epochMs[low - 1] - target).abs();
    return dLo <= dHi ? low - 1 : low;
  }

  static double _cagr(double start, double end, double years) {
    if (start <= 0 || end <= 0 || years <= 0) return double.nan;
    final ratio = end / start;
    if (ratio <= 0) return double.nan;
    return math.pow(ratio, 1.0 / years).toDouble() - 1.0;
  }

  static DateTime _normaliseDate(DateTime dt) =>
      DateTime.utc(dt.year, dt.month, dt.day);
}
