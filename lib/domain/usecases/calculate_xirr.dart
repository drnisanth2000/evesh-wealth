import 'dart:math' as math;

/// Cash flow entry for XIRR calculation
class CashFlow {
  const CashFlow({required this.amount, required this.date});

  /// Negative = investment (outflow); Positive = current value / redemption (inflow)
  final double amount;
  final DateTime date;
}

/// XIRR — Extended Internal Rate of Return
///
/// Ported from evesh_apps_script.js [computeXIRR] — Newton-Raphson, 200 iterations.
///
/// Usage:
/// ```dart
/// final flows = [
///   CashFlow(amount: -10000, date: DateTime(2022, 1, 1)),
///   CashFlow(amount: -10000, date: DateTime(2022, 7, 1)),
///   CashFlow(amount: 25000, date: DateTime.now()),   // current portfolio value
/// ];
/// final xirr = XirrCalculator.compute(flows); // e.g. 0.1545 = 15.45%
/// ```
class XirrCalculator {
  XirrCalculator._();

  static const int _maxIterations = 200;
  static const double _convergenceThreshold = 1e-7;
  static const double _initialGuess = 0.1; // 10% starting guess

  /// Compute XIRR. Returns the annualised rate or [double.nan] if it fails to converge.
  static double compute(List<CashFlow> cashflows) {
    if (cashflows.length < 2) return double.nan;

    // Validate: must have at least one positive and one negative cash flow
    final hasOutflow = cashflows.any((cf) => cf.amount < 0);
    final hasInflow = cashflows.any((cf) => cf.amount > 0);
    if (!hasOutflow || !hasInflow) return double.nan;

    // Use the first cash flow date as the base reference
    final baseDate = cashflows.first.date;

    // Convert dates to year fractions from base date
    final yearFractions = cashflows.map((cf) {
      return cf.date.difference(baseDate).inDays / 365.0;
    }).toList();

    double rate = _initialGuess;

    for (int i = 0; i < _maxIterations; i++) {
      final npv = _npv(rate, cashflows, yearFractions);
      final derivNpv = _derivativeNpv(rate, cashflows, yearFractions);

      if (derivNpv.abs() < 1e-12) break; // avoid division by near-zero

      final newRate = rate - npv / derivNpv;

      if ((newRate - rate).abs() < _convergenceThreshold) {
        return newRate; // converged
      }
      rate = newRate;

      // If rate goes wildly off, clamp to reasonable range
      if (rate < -0.9999) rate = -0.9999;
      if (rate > 100) rate = 100;
    }

    // Try with negative initial guess if positive didn't converge
    return _tryWithGuess(-0.1, cashflows, yearFractions);
  }

  static double _tryWithGuess(
    double guess,
    List<CashFlow> cashflows,
    List<double> yearFractions,
  ) {
    double rate = guess;
    for (int i = 0; i < _maxIterations; i++) {
      final npv = _npv(rate, cashflows, yearFractions);
      final derivNpv = _derivativeNpv(rate, cashflows, yearFractions);
      if (derivNpv.abs() < 1e-12) break;
      final newRate = rate - npv / derivNpv;
      if ((newRate - rate).abs() < _convergenceThreshold) return newRate;
      rate = newRate;
      if (rate < -0.9999) rate = -0.9999;
      if (rate > 100) rate = 100;
    }
    return double.nan;
  }

  /// Net Present Value at a given rate
  static double _npv(
    double rate,
    List<CashFlow> cashflows,
    List<double> yearFractions,
  ) {
    double sum = 0;
    for (int i = 0; i < cashflows.length; i++) {
      final base = 1 + rate;
      if (base <= 0) return double.infinity;
      sum += cashflows[i].amount / math.pow(base, yearFractions[i]);
    }
    return sum;
  }

  /// dNPV/d(rate) for Newton-Raphson
  static double _derivativeNpv(
    double rate,
    List<CashFlow> cashflows,
    List<double> yearFractions,
  ) {
    double sum = 0;
    for (int i = 0; i < cashflows.length; i++) {
      final t = yearFractions[i];
      final base = 1 + rate;
      if (base <= 0) return double.infinity;
      sum += -t * cashflows[i].amount / math.pow(base, t + 1);
    }
    return sum;
  }

  /// Quick helper: build XIRR cash flows from a list of transactions + current value
  static List<CashFlow> buildCashFlows({
    required List<({DateTime date, double amount, bool isPurchase})> transactions,
    required double currentValue,
    DateTime? asOfDate,
  }) {
    final flows = <CashFlow>[];
    for (final tx in transactions) {
      flows.add(CashFlow(
        amount: tx.isPurchase ? -tx.amount.abs() : tx.amount.abs(),
        date: tx.date,
      ));
    }
    if (currentValue > 0) {
      flows.add(CashFlow(
        amount: currentValue,
        date: asOfDate ?? DateTime.now(),
      ));
    }
    return flows;
  }
}
