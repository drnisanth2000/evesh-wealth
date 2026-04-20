import 'package:freezed_annotation/freezed_annotation.dart';

part 'family_model.freezed.dart';
part 'family_model.g.dart';

@freezed
class FamilyModel with _$FamilyModel {
  const factory FamilyModel({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'family_name') @Default('My Family') String familyName,
    @JsonKey(name: 'target_core_equity') @Default(40.0) double targetCoreEquity,
    @JsonKey(name: 'target_satellite_equity') @Default(20.0) double targetSatelliteEquity,
    @JsonKey(name: 'target_hybrid') @Default(5.0) double targetHybrid,
    @JsonKey(name: 'target_debt') @Default(20.0) double targetDebt,
    @JsonKey(name: 'target_liquid') @Default(5.0) double targetLiquid,
    @JsonKey(name: 'target_gold') @Default(5.0) double targetGold,
    @JsonKey(name: 'target_alternate') @Default(5.0) double targetAlternate,
    @JsonKey(name: 'rebalance_drift_threshold') @Default(5.0) double rebalanceDriftThreshold,
    @JsonKey(name: 'risk_profile') @Default('Moderate') String riskProfile,
    @JsonKey(name: 'risk_family_enabled') @Default(false) bool riskFamilyEnabled,
    @JsonKey(name: 'risk_target_equity_pct') @Default(55.0) double riskTargetEquityPct,
    @JsonKey(name: 'risk_target_debt_pct') @Default(45.0) double riskTargetDebtPct,
    @JsonKey(name: 'risk_profile_source') @Default('manual') String riskProfileSource,
    @JsonKey(name: 'risk_profile_updated_at') String? riskProfileUpdatedAt,
    @JsonKey(name: 'primary_email') String? primaryEmail,
    @JsonKey(name: 'sip_reminder_day') @Default(5) int sipReminderDay,
    @JsonKey(name: 'allocation_policy') Map<String, dynamic>? allocationPolicy,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _FamilyModel;

  factory FamilyModel.fromJson(Map<String, dynamic> json) =>
      _$FamilyModelFromJson(json);
}

@freezed
class FamilyMemberModel with _$FamilyMemberModel {
  const factory FamilyMemberModel({
    required String id,
    @JsonKey(name: 'family_id') required String familyId,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'display_name') required String displayName,
    String? pan,
    @JsonKey(name: 'date_of_birth') String? dateOfBirth,
    String? relationship,
    @JsonKey(name: 'risk_profile') @Default('Moderate') String riskProfile,
    @JsonKey(name: 'risk_target_equity_pct') @Default(55.0) double riskTargetEquityPct,
    @JsonKey(name: 'risk_target_debt_pct') @Default(45.0) double riskTargetDebtPct,
    @JsonKey(name: 'risk_questionnaire_answers') List<dynamic>? riskQuestionnaireAnswers,
    @JsonKey(name: 'risk_demographics') Map<String, dynamic>? riskDemographics,
    @JsonKey(name: 'risk_phase1_score') int? riskPhase1Score,
    @JsonKey(name: 'risk_phase2_adjustment') int? riskPhase2Adjustment,
    @JsonKey(name: 'risk_final_score') int? riskFinalScore,
    @JsonKey(name: 'risk_profile_source') @Default('manual') String riskProfileSource,
    @JsonKey(name: 'risk_profile_updated_at') String? riskProfileUpdatedAt,
    @JsonKey(name: 'tax_slab_pct') @Default(30.0) double taxSlabPct,
    @JsonKey(name: 'sip_day') @Default(5) int sipDay,
    @JsonKey(name: 'kyc_status') @Default('Complete') String kycStatus,
    @JsonKey(name: 'is_primary') @Default(false) bool isPrimary,
    @JsonKey(name: 'color_hex') @Default('#1B8A5A') String colorHex,
    String? email,
    String? mobile,
    String? address,
    @JsonKey(name: 'investment_goal') @Default('Wealth Building') String investmentGoal,
    @JsonKey(name: 'target_equity_pct') @Default(60.0) double targetEquityPct,
    @JsonKey(name: 'target_debt_pct') @Default(30.0) double targetDebtPct,
    @JsonKey(name: 'target_gold_pct') @Default(10.0) double targetGoldPct,
    // Wealth Planner — financial profile
    @JsonKey(name: 'retirement_age') @Default(60) int retirementAge,
    @JsonKey(name: 'life_expectancy') @Default(85) int lifeExpectancy,
    @JsonKey(name: 'monthly_expense') double? monthlyExpense,
    @JsonKey(name: 'annual_expenses') @Default([]) List<Map<String, dynamic>> annualExpenses,
    @JsonKey(name: 'income_type') @Default('steady') String incomeType,
    @JsonKey(name: 'monthly_income') double? monthlyIncome,
    @JsonKey(name: 'income_variability_pct') double? incomeVariabilityPct,
    @JsonKey(name: 'expected_increment_pct') @Default(8.0) double expectedIncrementPct,
    @JsonKey(name: 'expected_lumpsums') @Default([]) List<Map<String, dynamic>> expectedLumpsums,
    @JsonKey(name: 'risk_score_computed') int? riskScoreComputed,
    @JsonKey(name: 'drift_threshold_pct') @Default(5.0) double driftThresholdPct,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _FamilyMemberModel;

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberModelFromJson(json);
}

@freezed
class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    required String id,
    required String email,
    @JsonKey(name: 'full_name') String? fullName,
    String? pan,
    String? mobile,
    @Default('user') String role,
    @JsonKey(name: 'subscription_tier') @Default('free') String subscriptionTier,
    @JsonKey(name: 'subscription_status') @Default('active') String subscriptionStatus,
    @JsonKey(name: 'subscription_expires_at') String? subscriptionExpiresAt,
    @JsonKey(name: 'mfa_enabled') @Default(false) bool mfaEnabled,
    @JsonKey(name: 'onboarding_complete') @Default(false) bool onboardingComplete,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);

  const ProfileModel._();

  bool get isAdmin => role == 'admin';
  bool get isPaidTier => subscriptionTier != 'free';
  bool get isFamilyTier => subscriptionTier == 'family';
}
