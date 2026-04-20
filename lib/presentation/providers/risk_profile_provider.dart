import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/risk_tiers.dart';
import '../../domain/usecases/compute_risk_score.dart';
import 'auth_provider.dart';
import 'family_provider.dart';

part 'risk_profile_provider.g.dart';

/// Which member\'s risk profile is currently being viewed.
/// `null` → the family-level "ALL" tab.
@riverpod
class SelectedRiskMember extends _$SelectedRiskMember {
  @override
  String? build() => null;

  void select(String? memberId) => state = memberId;
}

@riverpod
class RiskProfileMutator extends _$RiskProfileMutator {
  @override
  void build() {}

  Future<void> saveManual({
    required String? memberId,
    required RiskTier tier,
    required double equityPct,
    required double debtPct,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final now = DateTime.now().toIso8601String();

    if (memberId == null) {
      final family = await ref.read(familyProvider.future);
      if (family == null) throw StateError('No family exists for user');
      await client.from('families').update({
        'risk_profile': tier.dbValue,
        'risk_target_equity_pct': equityPct,
        'risk_target_debt_pct': debtPct,
        'risk_profile_source': 'manual',
        'risk_profile_updated_at': now,
      }).eq('id', family.id);
    } else {
      await client.from('family_members').update({
        'risk_profile': tier.dbValue,
        'risk_target_equity_pct': equityPct,
        'risk_target_debt_pct': debtPct,
        'risk_profile_source': 'manual',
        'risk_profile_updated_at': now,
      }).eq('id', memberId);
    }

    ref.invalidate(familyProvider);
    ref.invalidate(familyMembersProvider);
  }

  Future<void> saveFromQuestionnaire({
    required String? memberId,
    required List<int> answers,
    required Map<String, String> demographics,
    required RiskScoreResult result,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final now = DateTime.now().toIso8601String();

    final memberPayload = {
      'risk_profile': result.tier.dbValue,
      'risk_target_equity_pct': result.tier.defaultEquity.toDouble(),
      'risk_target_debt_pct': result.tier.defaultDebt.toDouble(),
      'risk_questionnaire_answers': answers,
      'risk_demographics': demographics,
      'risk_phase1_score': result.phase1Score,
      'risk_phase2_adjustment': result.phase2Adjustment,
      'risk_final_score': result.totalScore,
      'risk_profile_source': 'questionnaire',
      'risk_profile_updated_at': now,
    };

    if (memberId == null) {
      final family = await ref.read(familyProvider.future);
      if (family == null) throw StateError('No family exists for user');
      await client.from('families').update({
        'risk_profile': result.tier.dbValue,
        'risk_target_equity_pct': result.tier.defaultEquity.toDouble(),
        'risk_target_debt_pct': result.tier.defaultDebt.toDouble(),
        'risk_profile_source': 'questionnaire',
        'risk_profile_updated_at': now,
      }).eq('id', family.id);
    } else {
      await client
          .from('family_members')
          .update(memberPayload)
          .eq('id', memberId);
    }

    ref.invalidate(familyProvider);
    ref.invalidate(familyMembersProvider);
  }

  Future<void> toggleFamilyEnabled(bool enabled) async {
    final client = ref.read(supabaseClientProvider);
    final family = await ref.read(familyProvider.future);
    if (family == null) throw StateError('No family exists for user');
    await client
        .from('families')
        .update({'risk_family_enabled': enabled}).eq('id', family.id);
    ref.invalidate(familyProvider);
  }
}
