import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/family_model.dart';
import '../../domain/models/retirement_models.dart';
import '../../domain/usecases/compute_retirement_corpus.dart';
import '../../domain/usecases/compute_retirement_gap.dart';
import 'family_provider.dart';
import 'portfolio_provider.dart';

part 'retirement_provider.g.dart';

/// Computes [RetirementReadiness] for a given member (or family primary).
///
/// - [memberId] null → uses primary member.
/// - [memberId] non-null → uses that member's data.
@riverpod
Future<RetirementReadiness> retirementReadiness(
  RetirementReadinessRef ref,
  String? memberId,
) async {
  final members = await ref.watch(familyMembersProvider.future);
  final portfolio = await ref.watch(portfolioSummaryProvider(memberId).future);

  // Resolve target member (same pattern as wealth_planner_provider.dart)
  final FamilyMemberModel? targetMember;
  if (memberId == null) {
    targetMember = members.cast<FamilyMemberModel?>().firstWhere(
          (m) => m?.isPrimary == true,
          orElse: () => members.cast<FamilyMemberModel?>().firstWhere(
                (m) => m?.relationship == 'Self',
                orElse: () => members.isEmpty ? null : members.first,
              ),
        );
  } else {
    targetMember = members.cast<FamilyMemberModel?>().firstWhere(
          (m) => m?.id == memberId,
          orElse: () => null,
        );
  }

  final age = _ageFromDob(targetMember?.dateOfBirth);
  final retirementAge = targetMember?.retirementAge ?? 60;
  final lifeExpectancy = targetMember?.lifeExpectancy ?? 85;
  final monthlyExpense = targetMember?.monthlyExpense ?? 0;
  final monthlyIncome = targetMember?.monthlyIncome ?? 0;
  final incomeType = targetMember?.incomeType ?? 'steady';
  final incomeVariabilityPct = targetMember?.incomeVariabilityPct;

  // Parse annual expense items from JSONB
  final annualExpenseItems = (targetMember?.annualExpenses ?? [])
      .map((json) => RetirementExpenseItem.fromJson(json))
      .toList();

  // Parse expected lumpsums from JSONB
  final expectedLumpsums = (targetMember?.expectedLumpsums ?? [])
      .map((json) => ExpectedLumpsum.fromJson(json))
      .toList();

  // Risk-profile based expected return for accumulation
  final expectedReturn = _expectedReturnForProfile(
    targetMember?.riskProfile ?? 'Moderate',
  );

  // Step 1: Compute corpus
  final corpus = RetirementCorpusCalculator.compute(
    currentAge: age,
    retirementAge: retirementAge,
    lifeExpectancy: lifeExpectancy,
    monthlyExpense: monthlyExpense,
    annualExpenseItems: annualExpenseItems,
    inflationRate: 0.06,
  );

  // Step 2: Compute gap
  final gap = RetirementGapCalculator.compute(
    corpus: corpus,
    currentPortfolioValue: portfolio.currentValue,
    expectedReturn: expectedReturn,
    monthlyIncome: monthlyIncome,
    monthlyExpense: monthlyExpense,
    annualExpenseItems: annualExpenseItems,
    expectedLumpsums: expectedLumpsums,
    incomeType: incomeType,
    incomeVariabilityPct: incomeVariabilityPct,
  );

  // Step 3: Compute distribution phase
  final distribution = RetirementGapCalculator.computeDistributionPhase(
    corpus: corpus.requiredCorpus,
    retirementYears: corpus.retirementYears,
    inflationRate: corpus.inflationRate,
  );

  // Step 4: Determine status label
  final statusLabel = _statusFromFunded(gap.fundedPct);

  return RetirementReadiness(
    fundedPct: gap.fundedPct,
    statusLabel: statusLabel,
    requiredCorpus: corpus.requiredCorpus,
    currentTrajectory: gap.totalProjectedValue,
    gap: gap.gap,
    requiredMonthlySip: gap.requiredMonthlySip,
    investableSurplus: gap.investableSurplus,
    yearsToRetirement: corpus.yearsToRetirement,
    retirementAge: retirementAge,
    gapAnalysis: gap,
    distributionPhase: distribution,
  );
}

/// Expected accumulation-phase return based on risk profile.
double _expectedReturnForProfile(String riskProfile) {
  switch (riskProfile) {
    case 'Conservative':
      return 0.09;
    case 'Moderately Conservative':
      return 0.10;
    case 'Moderate':
      return 0.11;
    case 'Moderately Aggressive':
      return 0.12;
    case 'Aggressive':
      return 0.13;
    default:
      return 0.11;
  }
}

/// Status label from funded percentage.
String _statusFromFunded(double fundedPct) {
  if (fundedPct >= 90) return 'On Track';
  if (fundedPct >= 60) return 'Needs Attention';
  if (fundedPct >= 30) return 'Behind';
  return 'Critical';
}

/// Derives age in whole years from an ISO date string (yyyy-MM-dd).
/// Returns 35 as a sensible default if DOB is absent or unparseable.
int _ageFromDob(String? dateOfBirth) {
  if (dateOfBirth == null || dateOfBirth.isEmpty) return 35;
  final dob = DateTime.tryParse(dateOfBirth);
  if (dob == null) return 35;
  final today = DateTime.now();
  int age = today.year - dob.year;
  if (today.month < dob.month ||
      (today.month == dob.month && today.day < dob.day)) {
    age--;
  }
  return age.clamp(18, 100);
}
