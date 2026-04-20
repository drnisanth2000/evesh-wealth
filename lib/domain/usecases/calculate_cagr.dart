import 'dart:math' as math;

/// Compound Annual Growth Rate calculations
class CagrCalculator {
  CagrCalculator._();

  /// Basic CAGR: ((endValue / startValue) ^ (1 / years)) - 1
  ///
  /// Returns the annualised growth rate (e.g. 0.145 = 14.5%)
  /// Returns [double.nan] for invalid inputs.
  static double compute({
    required double startValue,
    required double endValue,
    required double years,
  }) {
    if (startValue <= 0 || endValue <= 0 || years <= 0) return double.nan;
    return math.pow(endValue / startValue, 1.0 / years) - 1.0;
  }

  /// CAGR from investment amount + current value + holding days
  static double fromHoldingDays({
    required double invested,
    required double currentValue,
    required int holdingDays,
  }) {
    if (invested <= 0 || currentValue <= 0 || holdingDays <= 0) return double.nan;
    return compute(
      startValue: invested,
      endValue: currentValue,
      years: holdingDays / 365.0,
    );
  }

  /// CAGR from two NAV values and the date range
  static double fromNAV({
    required double navStart,
    required double navEnd,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final days = endDate.difference(startDate).inDays;
    if (days <= 0) return double.nan;
    return compute(
      startValue: navStart,
      endValue: navEnd,
      years: days / 365.0,
    );
  }

  /// Absolute return: (currentValue - invested) / invested
  static double absoluteReturn({
    required double invested,
    required double currentValue,
  }) {
    if (invested <= 0) return double.nan;
    return (currentValue - invested) / invested;
  }

  /// Annualised return from absolute return % and holding years
  static double annualise(double absoluteReturn, double years) {
    if (years <= 0) return double.nan;
    return math.pow(1 + absoluteReturn, 1.0 / years) - 1.0;
  }

  /// SIP CAGR approximation using XIRR under the hood
  /// (simply calls XirrCalculator for SIP scenarios)
  static double sipCagr({
    required List<double> sipAmounts,  // each SIP instalment
    required List<DateTime> sipDates,
    required double currentValue,
  }) {
    // SIP CAGR is better computed as XIRR — use XirrCalculator
    // This is a simplified annualised approximation for quick display
    final totalInvested = sipAmounts.fold(0.0, (a, b) => a + b);
    if (totalInvested <= 0 || sipDates.isEmpty) return double.nan;
    final firstDate = sipDates.reduce((a, b) => a.isBefore(b) ? a : b);
    final years = DateTime.now().difference(firstDate).inDays / 365.0;
    return fromHoldingDays(
      invested: totalInvested,
      currentValue: currentValue,
      holdingDays: DateTime.now().difference(firstDate).inDays,
    );
  }
}
