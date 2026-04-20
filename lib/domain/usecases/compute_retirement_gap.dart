import 'dart:math' as math;

import '../models/retirement_models.dart';

/// Calculates the retirement gap — the shortfall between projected wealth and
/// the corpus needed to sustain retirement — and models the post-retirement
/// distribution phase.
///
/// Usage:
/// ```dart
/// final gap = RetirementGapCalculator.compute(
///   corpus: corpus,
///   currentPortfolioValue: 500000,
///   expectedReturn: 0.12,
///   monthlyIncome: 100000,
///   monthlyExpense: 50000,
///   annualExpenseItems: [],
///   expectedLumpsums: [],
///   incomeType: 'steady',
///   incomeVariabilityPct: null,
/// );
/// ```
class RetirementGapCalculator {
  RetirementGapCalculator._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Compute the retirement gap.
  ///
  /// Parameters:
  /// - [corpus]                : Output of [RetirementCorpusCalculator.compute].
  /// - [currentPortfolioValue] : Current investment portfolio value (₹).
  /// - [expectedReturn]        : Expected annual portfolio return (e.g. 0.12).
  /// - [monthlyIncome]         : Gross monthly take-home income (₹).
  /// - [monthlyExpense]        : Current monthly living expense (₹).
  /// - [annualExpenseItems]    : List of periodic expense items (used for surplus calc).
  /// - [expectedLumpsums]      : Anticipated one-time inflows.
  /// - [incomeType]            : 'steady', 'variable', or 'mixed'.
  /// - [incomeVariabilityPct]  : Variability % for variable/mixed income (nullable).
  static RetirementGap compute({
    required RetirementCorpus corpus,
    required double currentPortfolioValue,
    required double expectedReturn,
    required double monthlyIncome,
    required double monthlyExpense,
    required List<RetirementExpenseItem> annualExpenseItems,
    required List<ExpectedLumpsum> expectedLumpsums,
    required String incomeType,
    double? incomeVariabilityPct,
  }) {
    final years = corpus.yearsToRetirement;

    // ------------------------------------------------------------------
    // Step 1: Project portfolio to retirement date
    // ------------------------------------------------------------------
    final projectedPortfolio = years > 0
        ? currentPortfolioValue * math.pow(1 + expectedReturn, years)
        : currentPortfolioValue.toDouble();

    // ------------------------------------------------------------------
    // Step 2: Project lumpsums to retirement date
    // ------------------------------------------------------------------
    double projectedLumpsums = 0;
    for (final lumpsum in expectedLumpsums) {
      int compoundYears;
      if (lumpsum.expectedDate != null) {
        try {
          final date = DateTime.parse(lumpsum.expectedDate!);
          final retirementDate =
              DateTime.now().add(Duration(days: (years * 365.25).round()));
          final diff = retirementDate.difference(date).inDays;
          compoundYears = math.max((diff / 365.25).round(), 0);
        } catch (_) {
          compoundYears = years;
        }
      } else if (lumpsum.horizonYears != null) {
        final remainingYears = years - lumpsum.horizonYears!;
        compoundYears = math.max(remainingYears, 0);
      } else {
        compoundYears = years;
      }

      final projected = compoundYears > 0
          ? lumpsum.weightedAmount * math.pow(1 + expectedReturn, compoundYears)
          : lumpsum.weightedAmount;
      projectedLumpsums += projected;
    }

    // ------------------------------------------------------------------
    // Step 3: Total projected value
    // ------------------------------------------------------------------
    final totalProjected = projectedPortfolio + projectedLumpsums;

    // ------------------------------------------------------------------
    // Step 4: Gap = requiredCorpus − totalProjected (positive = shortfall)
    // ------------------------------------------------------------------
    final requiredCorpus = corpus.requiredCorpus;
    final gap = requiredCorpus - totalProjected;

    // ------------------------------------------------------------------
    // Step 5: Investable surplus
    // ------------------------------------------------------------------
    final annualExpensesSum = annualExpenseItems.fold(
      0.0,
      (sum, e) => sum + e.annualised,
    );
    final effectiveIncome = _effectiveIncome(
      monthlyIncome: monthlyIncome,
      incomeType: incomeType,
      variabilityPct: incomeVariabilityPct,
    );
    final rawSurplus =
        effectiveIncome - monthlyExpense - (annualExpensesSum / 12);
    final investableSurplus = math.max(rawSurplus, 0.0);

    // ------------------------------------------------------------------
    // Step 6: Required monthly SIP (FV annuity formula)
    // PMT = FV × r / [(1 + r)^n − 1]
    // ------------------------------------------------------------------
    double requiredMonthlySip = 0;
    if (gap > 0 && years > 0) {
      final monthlyRate = expectedReturn / 12;
      final n = years * 12;
      if (monthlyRate.abs() < 1e-9) {
        // No growth: simple division
        requiredMonthlySip = gap / n;
      } else {
        requiredMonthlySip =
            gap * monthlyRate / (math.pow(1 + monthlyRate, n) - 1);
      }
    }

    // ------------------------------------------------------------------
    // Step 7: Funded percentage
    // ------------------------------------------------------------------
    final fundedPct = requiredCorpus > 0
        ? (totalProjected / requiredCorpus) * 100
        : 100.0;

    // ------------------------------------------------------------------
    // Step 8: SIP affordability
    // ------------------------------------------------------------------
    final isSipAffordable = requiredMonthlySip <= investableSurplus;

    return RetirementGap(
      corpus: corpus,
      currentPortfolioValue: currentPortfolioValue,
      projectedPortfolioValue: projectedPortfolio,
      projectedLumpsumValue: projectedLumpsums,
      totalProjectedValue: totalProjected,
      gap: gap,
      requiredMonthlySip: requiredMonthlySip,
      investableSurplus: investableSurplus,
      isSipAffordable: isSipAffordable,
      fundedPct: fundedPct,
      expectedReturn: expectedReturn,
      incomeType: incomeType,
    );
  }

  /// Compute the post-retirement distribution phase.
  ///
  /// Parameters:
  /// - [corpus]          : The required retirement corpus amount (₹).
  /// - [retirementYears] : Number of years in retirement.
  /// - [inflationRate]   : Expected annual inflation (e.g. 0.06).
  static DistributionPhase computeDistributionPhase({
    required double corpus,
    required int retirementYears,
    required double inflationRate,
  }) {
    // Fixed allocation
    const debtPct = 50.0;
    const equityPct = 25.0;
    const incomePct = 15.0;
    const cashPct = 10.0;

    // Blended nominal return
    const nominalReturn = 0.075;
    final realMonthlyRate = (nominalReturn - inflationRate) / 12;
    final totalMonths = retirementYears * 12;

    // Monthly income from corpus (PV annuity → monthly withdrawal)
    double monthlyIncome;
    if (totalMonths == 0 || corpus <= 0) {
      monthlyIncome = 0;
    } else if (realMonthlyRate.abs() < 1e-9) {
      monthlyIncome = corpus / totalMonths;
    } else {
      monthlyIncome = corpus *
          realMonthlyRate /
          (1 - math.pow(1 + realMonthlyRate, -totalMonths));
    }

    // Year-by-year projection
    final projections = <YearlyProjection>[];
    double runningCorpus = corpus;
    for (int year = 1; year <= retirementYears; year++) {
      final corpusStart = runningCorpus;
      final withdrawal =
          monthlyIncome * 12 * math.pow(1 + inflationRate, year - 1);
      final growth = corpusStart * nominalReturn;
      final corpusEnd = math.max(corpusStart + growth - withdrawal, 0.0);

      projections.add(YearlyProjection(
        year: year,
        corpusStart: corpusStart,
        withdrawal: withdrawal,
        growth: growth,
        corpusEnd: corpusEnd,
      ));

      runningCorpus = corpusEnd;
    }

    // Sustainability label
    final corpusFmt = _compact(corpus);
    final monthlyFmt = _compact(monthlyIncome);
    final sustainabilityLabel =
        '$corpusFmt corpus generates $monthlyFmt/month for $retirementYears years';

    return DistributionPhase(
      debtPct: debtPct,
      equityPct: equityPct,
      incomePct: incomePct,
      cashPct: cashPct,
      monthlyIncome: monthlyIncome,
      sustainabilityLabel: sustainabilityLabel,
      yearlyProjections: projections,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns the effective monthly income adjusted for income type.
  static double _effectiveIncome({
    required double monthlyIncome,
    required String incomeType,
    double? variabilityPct,
  }) {
    switch (incomeType) {
      case 'variable':
        final variability = variabilityPct ?? 30.0;
        return monthlyIncome * (1 - variability / 100);
      case 'mixed':
        final variability = variabilityPct ?? 30.0;
        // 60% treated as steady, 40% discounted by variability
        final steadyPortion = monthlyIncome * 0.60;
        final variablePortion = monthlyIncome * 0.40 * (1 - variability / 100);
        return steadyPortion + variablePortion;
      case 'steady':
      default:
        return monthlyIncome;
    }
  }

  /// Compact number formatter: ≥1Cr → "₹X.XCr", ≥1L → "₹X.XL", ≥1K → "₹X.XK".
  static String _compact(double value) {
    if (value >= 1e7) {
      return '₹${(value / 1e7).toStringAsFixed(1)}Cr';
    } else if (value >= 1e5) {
      return '₹${(value / 1e5).toStringAsFixed(1)}L';
    } else if (value >= 1e3) {
      return '₹${(value / 1e3).toStringAsFixed(1)}K';
    }
    return '₹${value.toStringAsFixed(0)}';
  }
}
