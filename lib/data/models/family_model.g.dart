// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FamilyModelImpl _$$FamilyModelImplFromJson(Map<String, dynamic> json) =>
    _$FamilyModelImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      familyName: json['family_name'] as String? ?? 'My Family',
      targetCoreEquity:
          (json['target_core_equity'] as num?)?.toDouble() ?? 40.0,
      targetSatelliteEquity:
          (json['target_satellite_equity'] as num?)?.toDouble() ?? 20.0,
      targetHybrid: (json['target_hybrid'] as num?)?.toDouble() ?? 5.0,
      targetDebt: (json['target_debt'] as num?)?.toDouble() ?? 20.0,
      targetLiquid: (json['target_liquid'] as num?)?.toDouble() ?? 5.0,
      targetGold: (json['target_gold'] as num?)?.toDouble() ?? 5.0,
      targetAlternate: (json['target_alternate'] as num?)?.toDouble() ?? 5.0,
      rebalanceDriftThreshold:
          (json['rebalance_drift_threshold'] as num?)?.toDouble() ?? 5.0,
      riskProfile: json['risk_profile'] as String? ?? 'Moderate',
      riskFamilyEnabled: json['risk_family_enabled'] as bool? ?? false,
      riskTargetEquityPct:
          (json['risk_target_equity_pct'] as num?)?.toDouble() ?? 55.0,
      riskTargetDebtPct:
          (json['risk_target_debt_pct'] as num?)?.toDouble() ?? 45.0,
      riskProfileSource: json['risk_profile_source'] as String? ?? 'manual',
      riskProfileUpdatedAt: json['risk_profile_updated_at'] as String?,
      primaryEmail: json['primary_email'] as String?,
      sipReminderDay: (json['sip_reminder_day'] as num?)?.toInt() ?? 5,
      allocationPolicy: json['allocation_policy'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$FamilyModelImplToJson(_$FamilyModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'family_name': instance.familyName,
      'target_core_equity': instance.targetCoreEquity,
      'target_satellite_equity': instance.targetSatelliteEquity,
      'target_hybrid': instance.targetHybrid,
      'target_debt': instance.targetDebt,
      'target_liquid': instance.targetLiquid,
      'target_gold': instance.targetGold,
      'target_alternate': instance.targetAlternate,
      'rebalance_drift_threshold': instance.rebalanceDriftThreshold,
      'risk_profile': instance.riskProfile,
      'risk_family_enabled': instance.riskFamilyEnabled,
      'risk_target_equity_pct': instance.riskTargetEquityPct,
      'risk_target_debt_pct': instance.riskTargetDebtPct,
      'risk_profile_source': instance.riskProfileSource,
      'risk_profile_updated_at': instance.riskProfileUpdatedAt,
      'primary_email': instance.primaryEmail,
      'sip_reminder_day': instance.sipReminderDay,
      'allocation_policy': instance.allocationPolicy,
      'created_at': instance.createdAt,
    };

_$FamilyMemberModelImpl _$$FamilyMemberModelImplFromJson(
        Map<String, dynamic> json) =>
    _$FamilyMemberModelImpl(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      ownerId: json['owner_id'] as String,
      displayName: json['display_name'] as String,
      pan: json['pan'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      relationship: json['relationship'] as String?,
      riskProfile: json['risk_profile'] as String? ?? 'Moderate',
      riskTargetEquityPct:
          (json['risk_target_equity_pct'] as num?)?.toDouble() ?? 55.0,
      riskTargetDebtPct:
          (json['risk_target_debt_pct'] as num?)?.toDouble() ?? 45.0,
      riskQuestionnaireAnswers:
          json['risk_questionnaire_answers'] as List<dynamic>?,
      riskDemographics: json['risk_demographics'] as Map<String, dynamic>?,
      riskPhase1Score: (json['risk_phase1_score'] as num?)?.toInt(),
      riskPhase2Adjustment: (json['risk_phase2_adjustment'] as num?)?.toInt(),
      riskFinalScore: (json['risk_final_score'] as num?)?.toInt(),
      riskProfileSource: json['risk_profile_source'] as String? ?? 'manual',
      riskProfileUpdatedAt: json['risk_profile_updated_at'] as String?,
      taxSlabPct: (json['tax_slab_pct'] as num?)?.toDouble() ?? 30.0,
      sipDay: (json['sip_day'] as num?)?.toInt() ?? 5,
      kycStatus: json['kyc_status'] as String? ?? 'Complete',
      isPrimary: json['is_primary'] as bool? ?? false,
      colorHex: json['color_hex'] as String? ?? '#1B8A5A',
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      address: json['address'] as String?,
      investmentGoal: json['investment_goal'] as String? ?? 'Wealth Building',
      targetEquityPct: (json['target_equity_pct'] as num?)?.toDouble() ?? 60.0,
      targetDebtPct: (json['target_debt_pct'] as num?)?.toDouble() ?? 30.0,
      targetGoldPct: (json['target_gold_pct'] as num?)?.toDouble() ?? 10.0,
      retirementAge: (json['retirement_age'] as num?)?.toInt() ?? 60,
      lifeExpectancy: (json['life_expectancy'] as num?)?.toInt() ?? 85,
      monthlyExpense: (json['monthly_expense'] as num?)?.toDouble(),
      annualExpenses: (json['annual_expenses'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      incomeType: json['income_type'] as String? ?? 'steady',
      monthlyIncome: (json['monthly_income'] as num?)?.toDouble(),
      incomeVariabilityPct:
          (json['income_variability_pct'] as num?)?.toDouble(),
      expectedIncrementPct:
          (json['expected_increment_pct'] as num?)?.toDouble() ?? 8.0,
      expectedLumpsums: (json['expected_lumpsums'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      riskScoreComputed: (json['risk_score_computed'] as num?)?.toInt(),
      driftThresholdPct:
          (json['drift_threshold_pct'] as num?)?.toDouble() ?? 5.0,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$FamilyMemberModelImplToJson(
        _$FamilyMemberModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'family_id': instance.familyId,
      'owner_id': instance.ownerId,
      'display_name': instance.displayName,
      'pan': instance.pan,
      'date_of_birth': instance.dateOfBirth,
      'relationship': instance.relationship,
      'risk_profile': instance.riskProfile,
      'risk_target_equity_pct': instance.riskTargetEquityPct,
      'risk_target_debt_pct': instance.riskTargetDebtPct,
      'risk_questionnaire_answers': instance.riskQuestionnaireAnswers,
      'risk_demographics': instance.riskDemographics,
      'risk_phase1_score': instance.riskPhase1Score,
      'risk_phase2_adjustment': instance.riskPhase2Adjustment,
      'risk_final_score': instance.riskFinalScore,
      'risk_profile_source': instance.riskProfileSource,
      'risk_profile_updated_at': instance.riskProfileUpdatedAt,
      'tax_slab_pct': instance.taxSlabPct,
      'sip_day': instance.sipDay,
      'kyc_status': instance.kycStatus,
      'is_primary': instance.isPrimary,
      'color_hex': instance.colorHex,
      'email': instance.email,
      'mobile': instance.mobile,
      'address': instance.address,
      'investment_goal': instance.investmentGoal,
      'target_equity_pct': instance.targetEquityPct,
      'target_debt_pct': instance.targetDebtPct,
      'target_gold_pct': instance.targetGoldPct,
      'retirement_age': instance.retirementAge,
      'life_expectancy': instance.lifeExpectancy,
      'monthly_expense': instance.monthlyExpense,
      'annual_expenses': instance.annualExpenses,
      'income_type': instance.incomeType,
      'monthly_income': instance.monthlyIncome,
      'income_variability_pct': instance.incomeVariabilityPct,
      'expected_increment_pct': instance.expectedIncrementPct,
      'expected_lumpsums': instance.expectedLumpsums,
      'risk_score_computed': instance.riskScoreComputed,
      'drift_threshold_pct': instance.driftThresholdPct,
      'created_at': instance.createdAt,
    };

_$ProfileModelImpl _$$ProfileModelImplFromJson(Map<String, dynamic> json) =>
    _$ProfileModelImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      pan: json['pan'] as String?,
      mobile: json['mobile'] as String?,
      role: json['role'] as String? ?? 'user',
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      subscriptionStatus: json['subscription_status'] as String? ?? 'active',
      subscriptionExpiresAt: json['subscription_expires_at'] as String?,
      mfaEnabled: json['mfa_enabled'] as bool? ?? false,
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$ProfileModelImplToJson(_$ProfileModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
      'pan': instance.pan,
      'mobile': instance.mobile,
      'role': instance.role,
      'subscription_tier': instance.subscriptionTier,
      'subscription_status': instance.subscriptionStatus,
      'subscription_expires_at': instance.subscriptionExpiresAt,
      'mfa_enabled': instance.mfaEnabled,
      'onboarding_complete': instance.onboardingComplete,
      'created_at': instance.createdAt,
    };
