import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/family_model.dart';
import '../../domain/models/allocation_models.dart';
import '../../domain/usecases/compute_allocation_health.dart';
import '../../domain/usecases/compute_ideal_allocation.dart';
import 'family_provider.dart';
import 'portfolio_provider.dart';

part 'wealth_planner_provider.g.dart';

/// Maps portfolio allocationPct display-name keys → asset class keys
/// used by [AllocationHealthCalculator].
const _displayToAssetClassKey = <String, String>{
  'Core Equity':      'coreEquity',
  'Satellite Equity': 'satelliteEquity',
  'Hybrid':           'hybrid',
  'Debt':             'debt',
  'Liquid':           'liquid',
  'Gold':             'gold',
  'Alternate':        'alternatives',
};

/// Computes [AllocationHealthResult] for a given member (or the family view).
///
/// - [memberId] null → family view: uses primary member's risk profile & age.
/// - [memberId] non-null → individual view: uses that member's data.
@riverpod
Future<AllocationHealthResult> allocationHealth(
  AllocationHealthRef ref,
  String? memberId,
) async {
  final members = await ref.watch(familyMembersProvider.future);
  final portfolio = await ref.watch(portfolioSummaryProvider(memberId).future);

  // Resolve the member whose risk profile and age we use.
  final FamilyMemberModel? targetMember;
  if (memberId == null) {
    // Family view: use primary member (isPrimary == true, fallback to 'Self').
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

  final riskProfile = targetMember?.riskProfile ?? 'Moderate';
  final age = _ageFromDob(targetMember?.dateOfBirth);

  // Compute ideal allocation.
  final idealAllocation = IdealAllocationCalculator.compute(
    riskProfile: riskProfile,
    age: age,
  );

  // Map portfolio allocationPct (display-name keys) → asset class keys.
  final currentAllocation = <String, double>{};
  for (final entry in portfolio.allocationPct.entries) {
    final key = _displayToAssetClassKey[entry.key];
    if (key != null) {
      currentAllocation[key] = (currentAllocation[key] ?? 0) + entry.value;
    }
  }

  // Compute and return allocation health.
  return AllocationHealthCalculator.compute(
    currentAllocation: currentAllocation,
    portfolioValue: portfolio.currentValue,
    ideal: idealAllocation,
  );
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
