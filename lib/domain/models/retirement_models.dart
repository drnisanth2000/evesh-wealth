/// Domain models for retirement planning engine.
library;

/// A single annual expense item with a flag for retirement inclusion.
class RetirementExpenseItem {
  final String name;
  final double amount;

  /// 'monthly', 'quarterly', or 'annual'
  final String frequency;
  final bool includeInRetirement;

  const RetirementExpenseItem({
    required this.name,
    required this.amount,
    required this.frequency,
    required this.includeInRetirement,
  });

  /// Returns the annualised equivalent of [amount] based on [frequency].
  double get annualised {
    switch (frequency) {
      case 'monthly':
        return amount * 12;
      case 'quarterly':
        return amount * 4;
      case 'annual':
      default:
        return amount;
    }
  }

  factory RetirementExpenseItem.fromJson(Map<String, dynamic> json) {
    return RetirementExpenseItem(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      frequency: json['frequency'] as String,
      includeInRetirement: json['include_in_retirement'] as bool,
    );
  }
}

/// An expected lumpsum inflow with a confidence weighting.
class ExpectedLumpsum {
  final double amount;

  /// ISO date string, nullable.
  final String? expectedDate;

  /// 'confirmed', 'likely', or 'tentative'
  final String confidence;
  final String? source;
  final int? horizonYears;
  final String? linkedGoalId;

  const ExpectedLumpsum({
    required this.amount,
    this.expectedDate,
    required this.confidence,
    this.source,
    this.horizonYears,
    this.linkedGoalId,
  });

  /// Confidence-weighted amount: confirmed=100%, likely=70%, tentative=40%.
  double get weightedAmount {
    switch (confidence) {
      case 'confirmed':
        return amount * 1.0;
      case 'likely':
        return amount * 0.7;
      case 'tentative':
      default:
        return amount * 0.4;
    }
  }

  factory ExpectedLumpsum.fromJson(Map<String, dynamic> json) {
    return ExpectedLumpsum(
      amount: (json['amount'] as num).toDouble(),
      expectedDate: json['expected_date'] as String?,
      confidence: json['confidence'] as String,
      source: json['source'] as String?,
      horizonYears: json['horizon_years'] as int?,
      linkedGoalId: json['linked_goal_id'] as String?,
    );
  }
}

/// Result of a corpus requirement calculation.
class RetirementCorpus {
  final double monthlyExpenseAtRetirement;
  final double annualRetirementExpenses;
  final double totalMonthlyNeedAtRetirement;
  final double requiredCorpus;
  final int yearsToRetirement;
  final int retirementYears;
  final double inflationRate;
  final double postRetirementRealReturn;

  const RetirementCorpus({
    required this.monthlyExpenseAtRetirement,
    required this.annualRetirementExpenses,
    required this.totalMonthlyNeedAtRetirement,
    required this.requiredCorpus,
    required this.yearsToRetirement,
    required this.retirementYears,
    required this.inflationRate,
    required this.postRetirementRealReturn,
  });
}

/// Result of a retirement gap analysis.
class RetirementGap {
  final RetirementCorpus corpus;
  final double currentPortfolioValue;
  final double projectedPortfolioValue;
  final double projectedLumpsumValue;
  final double totalProjectedValue;
  final double gap;
  final double requiredMonthlySip;
  final double investableSurplus;
  final bool isSipAffordable;
  final double fundedPct;
  final double expectedReturn;
  final String incomeType;

  const RetirementGap({
    required this.corpus,
    required this.currentPortfolioValue,
    required this.projectedPortfolioValue,
    required this.projectedLumpsumValue,
    required this.totalProjectedValue,
    required this.gap,
    required this.requiredMonthlySip,
    required this.investableSurplus,
    required this.isSipAffordable,
    required this.fundedPct,
    required this.expectedReturn,
    required this.incomeType,
  });
}

/// Single year snapshot used in distribution phase projections.
class YearlyProjection {
  final int year;
  final double corpusStart;
  final double withdrawal;
  final double growth;
  final double corpusEnd;

  const YearlyProjection({
    required this.year,
    required this.corpusStart,
    required this.withdrawal,
    required this.growth,
    required this.corpusEnd,
  });
}

/// Post-retirement income / distribution phase model.
class DistributionPhase {
  final double debtPct;
  final double equityPct;
  final double incomePct;
  final double cashPct;
  final double monthlyIncome;
  final String sustainabilityLabel;
  final List<YearlyProjection> yearlyProjections;

  const DistributionPhase({
    required this.debtPct,
    required this.equityPct,
    required this.incomePct,
    required this.cashPct,
    required this.monthlyIncome,
    required this.sustainabilityLabel,
    required this.yearlyProjections,
  });
}

/// Aggregated retirement readiness result for dashboard display.
class RetirementReadiness {
  final double fundedPct;
  final String statusLabel;
  final double requiredCorpus;
  final double currentTrajectory;
  final double gap;
  final double requiredMonthlySip;
  final double investableSurplus;
  final int yearsToRetirement;
  final int retirementAge;
  final RetirementGap gapAnalysis;
  final DistributionPhase distributionPhase;

  const RetirementReadiness({
    required this.fundedPct,
    required this.statusLabel,
    required this.requiredCorpus,
    required this.currentTrajectory,
    required this.gap,
    required this.requiredMonthlySip,
    required this.investableSurplus,
    required this.yearsToRetirement,
    required this.retirementAge,
    required this.gapAnalysis,
    required this.distributionPhase,
  });
}
