import 'dart:math' as math;

import '../models/retirement_models.dart';

/// Calculates the retirement corpus required to sustain a given monthly
/// expense through the retirement horizon, adjusting for inflation.
///
/// Usage:
/// ```dart
/// final corpus = RetirementCorpusCalculator.compute(
///   currentAge: 30,
///   retirementAge: 60,
///   lifeExpectancy: 85,
///   monthlyExpense: 50000,
///   annualExpenseItems: [],
/// );
/// ```
class RetirementCorpusCalculator {
  RetirementCorpusCalculator._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Compute the required retirement corpus.
  ///
  /// Parameters:
  /// - [currentAge]          : Current age of the investor (years).
  /// - [retirementAge]       : Target retirement age (years).
  /// - [lifeExpectancy]      : Expected age at death (years).
  /// - [monthlyExpense]      : Current monthly living expense (₹).
  /// - [annualExpenseItems]  : List of periodic expense items with inclusion flag.
  /// - [inflationRate]       : Expected annual inflation (default 6%).
  /// - [postRetirementReturn]: Expected portfolio return post-retirement (default 8%).
  ///
  /// Returns a [RetirementCorpus] with all intermediate values populated.
  static RetirementCorpus compute({
    required int currentAge,
    required int retirementAge,
    required int lifeExpectancy,
    required double monthlyExpense,
    required List<RetirementExpenseItem> annualExpenseItems,
    double inflationRate = 0.06,
    double postRetirementReturn = 0.08,
  }) {
    // ------------------------------------------------------------------
    // Step 1: Time periods
    // ------------------------------------------------------------------
    final yearsToRetirement = math.max(retirementAge - currentAge, 0);
    final effectiveRetirementAge = math.max(currentAge, retirementAge);
    final retirementYears = math.max(lifeExpectancy - effectiveRetirementAge, 0);

    // ------------------------------------------------------------------
    // Step 2: Short-circuit on zero expense
    // ------------------------------------------------------------------
    final includedItems = annualExpenseItems
        .where((e) => e.includeInRetirement)
        .toList();
    final baseAnnualExpenses =
        includedItems.fold(0.0, (sum, e) => sum + e.annualised);

    if (monthlyExpense <= 0 && baseAnnualExpenses <= 0) {
      return RetirementCorpus(
        monthlyExpenseAtRetirement: 0,
        annualRetirementExpenses: 0,
        totalMonthlyNeedAtRetirement: 0,
        requiredCorpus: 0,
        yearsToRetirement: yearsToRetirement,
        retirementYears: retirementYears,
        inflationRate: inflationRate,
        postRetirementRealReturn: postRetirementReturn - inflationRate,
      );
    }

    // ------------------------------------------------------------------
    // Step 3: Inflate to retirement date
    // ------------------------------------------------------------------
    final inflationFactor = math.pow(1 + inflationRate, yearsToRetirement);

    final inflatedMonthly = monthlyExpense * inflationFactor;
    final inflatedAnnualExpenses = baseAnnualExpenses * inflationFactor;

    // ------------------------------------------------------------------
    // Step 4: Total monthly need at retirement
    // ------------------------------------------------------------------
    final totalMonthlyNeed = inflatedMonthly + inflatedAnnualExpenses / 12;

    // ------------------------------------------------------------------
    // Step 5: Required corpus — PV of annuity
    // Real return (Fisher approximation): r_real ≈ r_nominal − inflation
    // PMT  = totalMonthlyNeed
    // r    = realReturn / 12
    // n    = retirementYears × 12
    // PV   = PMT × [(1 − (1+r)^−n) / r]   if r ≠ 0
    //      = PMT × n                         if r ≈ 0
    // ------------------------------------------------------------------
    final realReturn = postRetirementReturn - inflationRate;
    final n = retirementYears * 12;

    double requiredCorpus;
    if (n == 0) {
      requiredCorpus = 0;
    } else if (realReturn.abs() < 1e-9) {
      // Fallback: zero real return → simple multiplication
      requiredCorpus = totalMonthlyNeed * n;
    } else {
      final r = realReturn / 12;
      requiredCorpus = totalMonthlyNeed * (1 - math.pow(1 + r, -n)) / r;
    }

    return RetirementCorpus(
      monthlyExpenseAtRetirement: inflatedMonthly,
      annualRetirementExpenses: inflatedAnnualExpenses,
      totalMonthlyNeedAtRetirement: totalMonthlyNeed,
      requiredCorpus: requiredCorpus,
      yearsToRetirement: yearsToRetirement,
      retirementYears: retirementYears,
      inflationRate: inflationRate,
      postRetirementRealReturn: realReturn,
    );
  }
}
