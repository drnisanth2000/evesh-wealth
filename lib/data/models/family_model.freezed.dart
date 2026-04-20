// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FamilyModel _$FamilyModelFromJson(Map<String, dynamic> json) {
  return _FamilyModel.fromJson(json);
}

/// @nodoc
mixin _$FamilyModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'owner_id')
  String get ownerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'family_name')
  String get familyName => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_core_equity')
  double get targetCoreEquity => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_satellite_equity')
  double get targetSatelliteEquity => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_hybrid')
  double get targetHybrid => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_debt')
  double get targetDebt => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_liquid')
  double get targetLiquid => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_gold')
  double get targetGold => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_alternate')
  double get targetAlternate => throw _privateConstructorUsedError;
  @JsonKey(name: 'rebalance_drift_threshold')
  double get rebalanceDriftThreshold => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_profile')
  String get riskProfile => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_family_enabled')
  bool get riskFamilyEnabled => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_target_equity_pct')
  double get riskTargetEquityPct => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_target_debt_pct')
  double get riskTargetDebtPct => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_profile_source')
  String get riskProfileSource => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_profile_updated_at')
  String? get riskProfileUpdatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'primary_email')
  String? get primaryEmail => throw _privateConstructorUsedError;
  @JsonKey(name: 'sip_reminder_day')
  int get sipReminderDay => throw _privateConstructorUsedError;
  @JsonKey(name: 'allocation_policy')
  Map<String, dynamic>? get allocationPolicy =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this FamilyModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FamilyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FamilyModelCopyWith<FamilyModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FamilyModelCopyWith<$Res> {
  factory $FamilyModelCopyWith(
          FamilyModel value, $Res Function(FamilyModel) then) =
      _$FamilyModelCopyWithImpl<$Res, FamilyModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'family_name') String familyName,
      @JsonKey(name: 'target_core_equity') double targetCoreEquity,
      @JsonKey(name: 'target_satellite_equity') double targetSatelliteEquity,
      @JsonKey(name: 'target_hybrid') double targetHybrid,
      @JsonKey(name: 'target_debt') double targetDebt,
      @JsonKey(name: 'target_liquid') double targetLiquid,
      @JsonKey(name: 'target_gold') double targetGold,
      @JsonKey(name: 'target_alternate') double targetAlternate,
      @JsonKey(name: 'rebalance_drift_threshold')
      double rebalanceDriftThreshold,
      @JsonKey(name: 'risk_profile') String riskProfile,
      @JsonKey(name: 'risk_family_enabled') bool riskFamilyEnabled,
      @JsonKey(name: 'risk_target_equity_pct') double riskTargetEquityPct,
      @JsonKey(name: 'risk_target_debt_pct') double riskTargetDebtPct,
      @JsonKey(name: 'risk_profile_source') String riskProfileSource,
      @JsonKey(name: 'risk_profile_updated_at') String? riskProfileUpdatedAt,
      @JsonKey(name: 'primary_email') String? primaryEmail,
      @JsonKey(name: 'sip_reminder_day') int sipReminderDay,
      @JsonKey(name: 'allocation_policy')
      Map<String, dynamic>? allocationPolicy,
      @JsonKey(name: 'created_at') String? createdAt});
}

/// @nodoc
class _$FamilyModelCopyWithImpl<$Res, $Val extends FamilyModel>
    implements $FamilyModelCopyWith<$Res> {
  _$FamilyModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FamilyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? familyName = null,
    Object? targetCoreEquity = null,
    Object? targetSatelliteEquity = null,
    Object? targetHybrid = null,
    Object? targetDebt = null,
    Object? targetLiquid = null,
    Object? targetGold = null,
    Object? targetAlternate = null,
    Object? rebalanceDriftThreshold = null,
    Object? riskProfile = null,
    Object? riskFamilyEnabled = null,
    Object? riskTargetEquityPct = null,
    Object? riskTargetDebtPct = null,
    Object? riskProfileSource = null,
    Object? riskProfileUpdatedAt = freezed,
    Object? primaryEmail = freezed,
    Object? sipReminderDay = null,
    Object? allocationPolicy = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      familyName: null == familyName
          ? _value.familyName
          : familyName // ignore: cast_nullable_to_non_nullable
              as String,
      targetCoreEquity: null == targetCoreEquity
          ? _value.targetCoreEquity
          : targetCoreEquity // ignore: cast_nullable_to_non_nullable
              as double,
      targetSatelliteEquity: null == targetSatelliteEquity
          ? _value.targetSatelliteEquity
          : targetSatelliteEquity // ignore: cast_nullable_to_non_nullable
              as double,
      targetHybrid: null == targetHybrid
          ? _value.targetHybrid
          : targetHybrid // ignore: cast_nullable_to_non_nullable
              as double,
      targetDebt: null == targetDebt
          ? _value.targetDebt
          : targetDebt // ignore: cast_nullable_to_non_nullable
              as double,
      targetLiquid: null == targetLiquid
          ? _value.targetLiquid
          : targetLiquid // ignore: cast_nullable_to_non_nullable
              as double,
      targetGold: null == targetGold
          ? _value.targetGold
          : targetGold // ignore: cast_nullable_to_non_nullable
              as double,
      targetAlternate: null == targetAlternate
          ? _value.targetAlternate
          : targetAlternate // ignore: cast_nullable_to_non_nullable
              as double,
      rebalanceDriftThreshold: null == rebalanceDriftThreshold
          ? _value.rebalanceDriftThreshold
          : rebalanceDriftThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      riskProfile: null == riskProfile
          ? _value.riskProfile
          : riskProfile // ignore: cast_nullable_to_non_nullable
              as String,
      riskFamilyEnabled: null == riskFamilyEnabled
          ? _value.riskFamilyEnabled
          : riskFamilyEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      riskTargetEquityPct: null == riskTargetEquityPct
          ? _value.riskTargetEquityPct
          : riskTargetEquityPct // ignore: cast_nullable_to_non_nullable
              as double,
      riskTargetDebtPct: null == riskTargetDebtPct
          ? _value.riskTargetDebtPct
          : riskTargetDebtPct // ignore: cast_nullable_to_non_nullable
              as double,
      riskProfileSource: null == riskProfileSource
          ? _value.riskProfileSource
          : riskProfileSource // ignore: cast_nullable_to_non_nullable
              as String,
      riskProfileUpdatedAt: freezed == riskProfileUpdatedAt
          ? _value.riskProfileUpdatedAt
          : riskProfileUpdatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      primaryEmail: freezed == primaryEmail
          ? _value.primaryEmail
          : primaryEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      sipReminderDay: null == sipReminderDay
          ? _value.sipReminderDay
          : sipReminderDay // ignore: cast_nullable_to_non_nullable
              as int,
      allocationPolicy: freezed == allocationPolicy
          ? _value.allocationPolicy
          : allocationPolicy // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FamilyModelImplCopyWith<$Res>
    implements $FamilyModelCopyWith<$Res> {
  factory _$$FamilyModelImplCopyWith(
          _$FamilyModelImpl value, $Res Function(_$FamilyModelImpl) then) =
      __$$FamilyModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'family_name') String familyName,
      @JsonKey(name: 'target_core_equity') double targetCoreEquity,
      @JsonKey(name: 'target_satellite_equity') double targetSatelliteEquity,
      @JsonKey(name: 'target_hybrid') double targetHybrid,
      @JsonKey(name: 'target_debt') double targetDebt,
      @JsonKey(name: 'target_liquid') double targetLiquid,
      @JsonKey(name: 'target_gold') double targetGold,
      @JsonKey(name: 'target_alternate') double targetAlternate,
      @JsonKey(name: 'rebalance_drift_threshold')
      double rebalanceDriftThreshold,
      @JsonKey(name: 'risk_profile') String riskProfile,
      @JsonKey(name: 'risk_family_enabled') bool riskFamilyEnabled,
      @JsonKey(name: 'risk_target_equity_pct') double riskTargetEquityPct,
      @JsonKey(name: 'risk_target_debt_pct') double riskTargetDebtPct,
      @JsonKey(name: 'risk_profile_source') String riskProfileSource,
      @JsonKey(name: 'risk_profile_updated_at') String? riskProfileUpdatedAt,
      @JsonKey(name: 'primary_email') String? primaryEmail,
      @JsonKey(name: 'sip_reminder_day') int sipReminderDay,
      @JsonKey(name: 'allocation_policy')
      Map<String, dynamic>? allocationPolicy,
      @JsonKey(name: 'created_at') String? createdAt});
}

/// @nodoc
class __$$FamilyModelImplCopyWithImpl<$Res>
    extends _$FamilyModelCopyWithImpl<$Res, _$FamilyModelImpl>
    implements _$$FamilyModelImplCopyWith<$Res> {
  __$$FamilyModelImplCopyWithImpl(
      _$FamilyModelImpl _value, $Res Function(_$FamilyModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of FamilyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? familyName = null,
    Object? targetCoreEquity = null,
    Object? targetSatelliteEquity = null,
    Object? targetHybrid = null,
    Object? targetDebt = null,
    Object? targetLiquid = null,
    Object? targetGold = null,
    Object? targetAlternate = null,
    Object? rebalanceDriftThreshold = null,
    Object? riskProfile = null,
    Object? riskFamilyEnabled = null,
    Object? riskTargetEquityPct = null,
    Object? riskTargetDebtPct = null,
    Object? riskProfileSource = null,
    Object? riskProfileUpdatedAt = freezed,
    Object? primaryEmail = freezed,
    Object? sipReminderDay = null,
    Object? allocationPolicy = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$FamilyModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      familyName: null == familyName
          ? _value.familyName
          : familyName // ignore: cast_nullable_to_non_nullable
              as String,
      targetCoreEquity: null == targetCoreEquity
          ? _value.targetCoreEquity
          : targetCoreEquity // ignore: cast_nullable_to_non_nullable
              as double,
      targetSatelliteEquity: null == targetSatelliteEquity
          ? _value.targetSatelliteEquity
          : targetSatelliteEquity // ignore: cast_nullable_to_non_nullable
              as double,
      targetHybrid: null == targetHybrid
          ? _value.targetHybrid
          : targetHybrid // ignore: cast_nullable_to_non_nullable
              as double,
      targetDebt: null == targetDebt
          ? _value.targetDebt
          : targetDebt // ignore: cast_nullable_to_non_nullable
              as double,
      targetLiquid: null == targetLiquid
          ? _value.targetLiquid
          : targetLiquid // ignore: cast_nullable_to_non_nullable
              as double,
      targetGold: null == targetGold
          ? _value.targetGold
          : targetGold // ignore: cast_nullable_to_non_nullable
              as double,
      targetAlternate: null == targetAlternate
          ? _value.targetAlternate
          : targetAlternate // ignore: cast_nullable_to_non_nullable
              as double,
      rebalanceDriftThreshold: null == rebalanceDriftThreshold
          ? _value.rebalanceDriftThreshold
          : rebalanceDriftThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      riskProfile: null == riskProfile
          ? _value.riskProfile
          : riskProfile // ignore: cast_nullable_to_non_nullable
              as String,
      riskFamilyEnabled: null == riskFamilyEnabled
          ? _value.riskFamilyEnabled
          : riskFamilyEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      riskTargetEquityPct: null == riskTargetEquityPct
          ? _value.riskTargetEquityPct
          : riskTargetEquityPct // ignore: cast_nullable_to_non_nullable
              as double,
      riskTargetDebtPct: null == riskTargetDebtPct
          ? _value.riskTargetDebtPct
          : riskTargetDebtPct // ignore: cast_nullable_to_non_nullable
              as double,
      riskProfileSource: null == riskProfileSource
          ? _value.riskProfileSource
          : riskProfileSource // ignore: cast_nullable_to_non_nullable
              as String,
      riskProfileUpdatedAt: freezed == riskProfileUpdatedAt
          ? _value.riskProfileUpdatedAt
          : riskProfileUpdatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      primaryEmail: freezed == primaryEmail
          ? _value.primaryEmail
          : primaryEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      sipReminderDay: null == sipReminderDay
          ? _value.sipReminderDay
          : sipReminderDay // ignore: cast_nullable_to_non_nullable
              as int,
      allocationPolicy: freezed == allocationPolicy
          ? _value._allocationPolicy
          : allocationPolicy // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FamilyModelImpl implements _FamilyModel {
  const _$FamilyModelImpl(
      {required this.id,
      @JsonKey(name: 'owner_id') required this.ownerId,
      @JsonKey(name: 'family_name') this.familyName = 'My Family',
      @JsonKey(name: 'target_core_equity') this.targetCoreEquity = 40.0,
      @JsonKey(name: 'target_satellite_equity')
      this.targetSatelliteEquity = 20.0,
      @JsonKey(name: 'target_hybrid') this.targetHybrid = 5.0,
      @JsonKey(name: 'target_debt') this.targetDebt = 20.0,
      @JsonKey(name: 'target_liquid') this.targetLiquid = 5.0,
      @JsonKey(name: 'target_gold') this.targetGold = 5.0,
      @JsonKey(name: 'target_alternate') this.targetAlternate = 5.0,
      @JsonKey(name: 'rebalance_drift_threshold')
      this.rebalanceDriftThreshold = 5.0,
      @JsonKey(name: 'risk_profile') this.riskProfile = 'Moderate',
      @JsonKey(name: 'risk_family_enabled') this.riskFamilyEnabled = false,
      @JsonKey(name: 'risk_target_equity_pct') this.riskTargetEquityPct = 55.0,
      @JsonKey(name: 'risk_target_debt_pct') this.riskTargetDebtPct = 45.0,
      @JsonKey(name: 'risk_profile_source') this.riskProfileSource = 'manual',
      @JsonKey(name: 'risk_profile_updated_at') this.riskProfileUpdatedAt,
      @JsonKey(name: 'primary_email') this.primaryEmail,
      @JsonKey(name: 'sip_reminder_day') this.sipReminderDay = 5,
      @JsonKey(name: 'allocation_policy')
      final Map<String, dynamic>? allocationPolicy,
      @JsonKey(name: 'created_at') this.createdAt})
      : _allocationPolicy = allocationPolicy;

  factory _$FamilyModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FamilyModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @override
  @JsonKey(name: 'family_name')
  final String familyName;
  @override
  @JsonKey(name: 'target_core_equity')
  final double targetCoreEquity;
  @override
  @JsonKey(name: 'target_satellite_equity')
  final double targetSatelliteEquity;
  @override
  @JsonKey(name: 'target_hybrid')
  final double targetHybrid;
  @override
  @JsonKey(name: 'target_debt')
  final double targetDebt;
  @override
  @JsonKey(name: 'target_liquid')
  final double targetLiquid;
  @override
  @JsonKey(name: 'target_gold')
  final double targetGold;
  @override
  @JsonKey(name: 'target_alternate')
  final double targetAlternate;
  @override
  @JsonKey(name: 'rebalance_drift_threshold')
  final double rebalanceDriftThreshold;
  @override
  @JsonKey(name: 'risk_profile')
  final String riskProfile;
  @override
  @JsonKey(name: 'risk_family_enabled')
  final bool riskFamilyEnabled;
  @override
  @JsonKey(name: 'risk_target_equity_pct')
  final double riskTargetEquityPct;
  @override
  @JsonKey(name: 'risk_target_debt_pct')
  final double riskTargetDebtPct;
  @override
  @JsonKey(name: 'risk_profile_source')
  final String riskProfileSource;
  @override
  @JsonKey(name: 'risk_profile_updated_at')
  final String? riskProfileUpdatedAt;
  @override
  @JsonKey(name: 'primary_email')
  final String? primaryEmail;
  @override
  @JsonKey(name: 'sip_reminder_day')
  final int sipReminderDay;
  final Map<String, dynamic>? _allocationPolicy;
  @override
  @JsonKey(name: 'allocation_policy')
  Map<String, dynamic>? get allocationPolicy {
    final value = _allocationPolicy;
    if (value == null) return null;
    if (_allocationPolicy is EqualUnmodifiableMapView) return _allocationPolicy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @override
  String toString() {
    return 'FamilyModel(id: $id, ownerId: $ownerId, familyName: $familyName, targetCoreEquity: $targetCoreEquity, targetSatelliteEquity: $targetSatelliteEquity, targetHybrid: $targetHybrid, targetDebt: $targetDebt, targetLiquid: $targetLiquid, targetGold: $targetGold, targetAlternate: $targetAlternate, rebalanceDriftThreshold: $rebalanceDriftThreshold, riskProfile: $riskProfile, riskFamilyEnabled: $riskFamilyEnabled, riskTargetEquityPct: $riskTargetEquityPct, riskTargetDebtPct: $riskTargetDebtPct, riskProfileSource: $riskProfileSource, riskProfileUpdatedAt: $riskProfileUpdatedAt, primaryEmail: $primaryEmail, sipReminderDay: $sipReminderDay, allocationPolicy: $allocationPolicy, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FamilyModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.familyName, familyName) ||
                other.familyName == familyName) &&
            (identical(other.targetCoreEquity, targetCoreEquity) ||
                other.targetCoreEquity == targetCoreEquity) &&
            (identical(other.targetSatelliteEquity, targetSatelliteEquity) ||
                other.targetSatelliteEquity == targetSatelliteEquity) &&
            (identical(other.targetHybrid, targetHybrid) ||
                other.targetHybrid == targetHybrid) &&
            (identical(other.targetDebt, targetDebt) ||
                other.targetDebt == targetDebt) &&
            (identical(other.targetLiquid, targetLiquid) ||
                other.targetLiquid == targetLiquid) &&
            (identical(other.targetGold, targetGold) ||
                other.targetGold == targetGold) &&
            (identical(other.targetAlternate, targetAlternate) ||
                other.targetAlternate == targetAlternate) &&
            (identical(
                    other.rebalanceDriftThreshold, rebalanceDriftThreshold) ||
                other.rebalanceDriftThreshold == rebalanceDriftThreshold) &&
            (identical(other.riskProfile, riskProfile) ||
                other.riskProfile == riskProfile) &&
            (identical(other.riskFamilyEnabled, riskFamilyEnabled) ||
                other.riskFamilyEnabled == riskFamilyEnabled) &&
            (identical(other.riskTargetEquityPct, riskTargetEquityPct) ||
                other.riskTargetEquityPct == riskTargetEquityPct) &&
            (identical(other.riskTargetDebtPct, riskTargetDebtPct) ||
                other.riskTargetDebtPct == riskTargetDebtPct) &&
            (identical(other.riskProfileSource, riskProfileSource) ||
                other.riskProfileSource == riskProfileSource) &&
            (identical(other.riskProfileUpdatedAt, riskProfileUpdatedAt) ||
                other.riskProfileUpdatedAt == riskProfileUpdatedAt) &&
            (identical(other.primaryEmail, primaryEmail) ||
                other.primaryEmail == primaryEmail) &&
            (identical(other.sipReminderDay, sipReminderDay) ||
                other.sipReminderDay == sipReminderDay) &&
            const DeepCollectionEquality()
                .equals(other._allocationPolicy, _allocationPolicy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        ownerId,
        familyName,
        targetCoreEquity,
        targetSatelliteEquity,
        targetHybrid,
        targetDebt,
        targetLiquid,
        targetGold,
        targetAlternate,
        rebalanceDriftThreshold,
        riskProfile,
        riskFamilyEnabled,
        riskTargetEquityPct,
        riskTargetDebtPct,
        riskProfileSource,
        riskProfileUpdatedAt,
        primaryEmail,
        sipReminderDay,
        const DeepCollectionEquality().hash(_allocationPolicy),
        createdAt
      ]);

  /// Create a copy of FamilyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FamilyModelImplCopyWith<_$FamilyModelImpl> get copyWith =>
      __$$FamilyModelImplCopyWithImpl<_$FamilyModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FamilyModelImplToJson(
      this,
    );
  }
}

abstract class _FamilyModel implements FamilyModel {
  const factory _FamilyModel(
      {required final String id,
      @JsonKey(name: 'owner_id') required final String ownerId,
      @JsonKey(name: 'family_name') final String familyName,
      @JsonKey(name: 'target_core_equity') final double targetCoreEquity,
      @JsonKey(name: 'target_satellite_equity')
      final double targetSatelliteEquity,
      @JsonKey(name: 'target_hybrid') final double targetHybrid,
      @JsonKey(name: 'target_debt') final double targetDebt,
      @JsonKey(name: 'target_liquid') final double targetLiquid,
      @JsonKey(name: 'target_gold') final double targetGold,
      @JsonKey(name: 'target_alternate') final double targetAlternate,
      @JsonKey(name: 'rebalance_drift_threshold')
      final double rebalanceDriftThreshold,
      @JsonKey(name: 'risk_profile') final String riskProfile,
      @JsonKey(name: 'risk_family_enabled') final bool riskFamilyEnabled,
      @JsonKey(name: 'risk_target_equity_pct') final double riskTargetEquityPct,
      @JsonKey(name: 'risk_target_debt_pct') final double riskTargetDebtPct,
      @JsonKey(name: 'risk_profile_source') final String riskProfileSource,
      @JsonKey(name: 'risk_profile_updated_at')
      final String? riskProfileUpdatedAt,
      @JsonKey(name: 'primary_email') final String? primaryEmail,
      @JsonKey(name: 'sip_reminder_day') final int sipReminderDay,
      @JsonKey(name: 'allocation_policy')
      final Map<String, dynamic>? allocationPolicy,
      @JsonKey(name: 'created_at')
      final String? createdAt}) = _$FamilyModelImpl;

  factory _FamilyModel.fromJson(Map<String, dynamic> json) =
      _$FamilyModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'owner_id')
  String get ownerId;
  @override
  @JsonKey(name: 'family_name')
  String get familyName;
  @override
  @JsonKey(name: 'target_core_equity')
  double get targetCoreEquity;
  @override
  @JsonKey(name: 'target_satellite_equity')
  double get targetSatelliteEquity;
  @override
  @JsonKey(name: 'target_hybrid')
  double get targetHybrid;
  @override
  @JsonKey(name: 'target_debt')
  double get targetDebt;
  @override
  @JsonKey(name: 'target_liquid')
  double get targetLiquid;
  @override
  @JsonKey(name: 'target_gold')
  double get targetGold;
  @override
  @JsonKey(name: 'target_alternate')
  double get targetAlternate;
  @override
  @JsonKey(name: 'rebalance_drift_threshold')
  double get rebalanceDriftThreshold;
  @override
  @JsonKey(name: 'risk_profile')
  String get riskProfile;
  @override
  @JsonKey(name: 'risk_family_enabled')
  bool get riskFamilyEnabled;
  @override
  @JsonKey(name: 'risk_target_equity_pct')
  double get riskTargetEquityPct;
  @override
  @JsonKey(name: 'risk_target_debt_pct')
  double get riskTargetDebtPct;
  @override
  @JsonKey(name: 'risk_profile_source')
  String get riskProfileSource;
  @override
  @JsonKey(name: 'risk_profile_updated_at')
  String? get riskProfileUpdatedAt;
  @override
  @JsonKey(name: 'primary_email')
  String? get primaryEmail;
  @override
  @JsonKey(name: 'sip_reminder_day')
  int get sipReminderDay;
  @override
  @JsonKey(name: 'allocation_policy')
  Map<String, dynamic>? get allocationPolicy;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;

  /// Create a copy of FamilyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FamilyModelImplCopyWith<_$FamilyModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FamilyMemberModel _$FamilyMemberModelFromJson(Map<String, dynamic> json) {
  return _FamilyMemberModel.fromJson(json);
}

/// @nodoc
mixin _$FamilyMemberModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'family_id')
  String get familyId => throw _privateConstructorUsedError;
  @JsonKey(name: 'owner_id')
  String get ownerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String get displayName => throw _privateConstructorUsedError;
  String? get pan => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_of_birth')
  String? get dateOfBirth => throw _privateConstructorUsedError;
  String? get relationship => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_profile')
  String get riskProfile => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_target_equity_pct')
  double get riskTargetEquityPct => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_target_debt_pct')
  double get riskTargetDebtPct => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_questionnaire_answers')
  List<dynamic>? get riskQuestionnaireAnswers =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_demographics')
  Map<String, dynamic>? get riskDemographics =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_phase1_score')
  int? get riskPhase1Score => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_phase2_adjustment')
  int? get riskPhase2Adjustment => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_final_score')
  int? get riskFinalScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_profile_source')
  String get riskProfileSource => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_profile_updated_at')
  String? get riskProfileUpdatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'tax_slab_pct')
  double get taxSlabPct => throw _privateConstructorUsedError;
  @JsonKey(name: 'sip_day')
  int get sipDay => throw _privateConstructorUsedError;
  @JsonKey(name: 'kyc_status')
  String get kycStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_primary')
  bool get isPrimary => throw _privateConstructorUsedError;
  @JsonKey(name: 'color_hex')
  String get colorHex => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get mobile => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  @JsonKey(name: 'investment_goal')
  String get investmentGoal => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_equity_pct')
  double get targetEquityPct => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_debt_pct')
  double get targetDebtPct => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_gold_pct')
  double get targetGoldPct =>
      throw _privateConstructorUsedError; // Wealth Planner — financial profile
  @JsonKey(name: 'retirement_age')
  int get retirementAge => throw _privateConstructorUsedError;
  @JsonKey(name: 'life_expectancy')
  int get lifeExpectancy => throw _privateConstructorUsedError;
  @JsonKey(name: 'monthly_expense')
  double? get monthlyExpense => throw _privateConstructorUsedError;
  @JsonKey(name: 'annual_expenses')
  List<Map<String, dynamic>> get annualExpenses =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'income_type')
  String get incomeType => throw _privateConstructorUsedError;
  @JsonKey(name: 'monthly_income')
  double? get monthlyIncome => throw _privateConstructorUsedError;
  @JsonKey(name: 'income_variability_pct')
  double? get incomeVariabilityPct => throw _privateConstructorUsedError;
  @JsonKey(name: 'expected_increment_pct')
  double get expectedIncrementPct => throw _privateConstructorUsedError;
  @JsonKey(name: 'expected_lumpsums')
  List<Map<String, dynamic>> get expectedLumpsums =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_score_computed')
  int? get riskScoreComputed => throw _privateConstructorUsedError;
  @JsonKey(name: 'drift_threshold_pct')
  double get driftThresholdPct => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this FamilyMemberModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FamilyMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FamilyMemberModelCopyWith<FamilyMemberModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FamilyMemberModelCopyWith<$Res> {
  factory $FamilyMemberModelCopyWith(
          FamilyMemberModel value, $Res Function(FamilyMemberModel) then) =
      _$FamilyMemberModelCopyWithImpl<$Res, FamilyMemberModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'family_id') String familyId,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'display_name') String displayName,
      String? pan,
      @JsonKey(name: 'date_of_birth') String? dateOfBirth,
      String? relationship,
      @JsonKey(name: 'risk_profile') String riskProfile,
      @JsonKey(name: 'risk_target_equity_pct') double riskTargetEquityPct,
      @JsonKey(name: 'risk_target_debt_pct') double riskTargetDebtPct,
      @JsonKey(name: 'risk_questionnaire_answers')
      List<dynamic>? riskQuestionnaireAnswers,
      @JsonKey(name: 'risk_demographics')
      Map<String, dynamic>? riskDemographics,
      @JsonKey(name: 'risk_phase1_score') int? riskPhase1Score,
      @JsonKey(name: 'risk_phase2_adjustment') int? riskPhase2Adjustment,
      @JsonKey(name: 'risk_final_score') int? riskFinalScore,
      @JsonKey(name: 'risk_profile_source') String riskProfileSource,
      @JsonKey(name: 'risk_profile_updated_at') String? riskProfileUpdatedAt,
      @JsonKey(name: 'tax_slab_pct') double taxSlabPct,
      @JsonKey(name: 'sip_day') int sipDay,
      @JsonKey(name: 'kyc_status') String kycStatus,
      @JsonKey(name: 'is_primary') bool isPrimary,
      @JsonKey(name: 'color_hex') String colorHex,
      String? email,
      String? mobile,
      String? address,
      @JsonKey(name: 'investment_goal') String investmentGoal,
      @JsonKey(name: 'target_equity_pct') double targetEquityPct,
      @JsonKey(name: 'target_debt_pct') double targetDebtPct,
      @JsonKey(name: 'target_gold_pct') double targetGoldPct,
      @JsonKey(name: 'retirement_age') int retirementAge,
      @JsonKey(name: 'life_expectancy') int lifeExpectancy,
      @JsonKey(name: 'monthly_expense') double? monthlyExpense,
      @JsonKey(name: 'annual_expenses')
      List<Map<String, dynamic>> annualExpenses,
      @JsonKey(name: 'income_type') String incomeType,
      @JsonKey(name: 'monthly_income') double? monthlyIncome,
      @JsonKey(name: 'income_variability_pct') double? incomeVariabilityPct,
      @JsonKey(name: 'expected_increment_pct') double expectedIncrementPct,
      @JsonKey(name: 'expected_lumpsums')
      List<Map<String, dynamic>> expectedLumpsums,
      @JsonKey(name: 'risk_score_computed') int? riskScoreComputed,
      @JsonKey(name: 'drift_threshold_pct') double driftThresholdPct,
      @JsonKey(name: 'created_at') String? createdAt});
}

/// @nodoc
class _$FamilyMemberModelCopyWithImpl<$Res, $Val extends FamilyMemberModel>
    implements $FamilyMemberModelCopyWith<$Res> {
  _$FamilyMemberModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FamilyMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? ownerId = null,
    Object? displayName = null,
    Object? pan = freezed,
    Object? dateOfBirth = freezed,
    Object? relationship = freezed,
    Object? riskProfile = null,
    Object? riskTargetEquityPct = null,
    Object? riskTargetDebtPct = null,
    Object? riskQuestionnaireAnswers = freezed,
    Object? riskDemographics = freezed,
    Object? riskPhase1Score = freezed,
    Object? riskPhase2Adjustment = freezed,
    Object? riskFinalScore = freezed,
    Object? riskProfileSource = null,
    Object? riskProfileUpdatedAt = freezed,
    Object? taxSlabPct = null,
    Object? sipDay = null,
    Object? kycStatus = null,
    Object? isPrimary = null,
    Object? colorHex = null,
    Object? email = freezed,
    Object? mobile = freezed,
    Object? address = freezed,
    Object? investmentGoal = null,
    Object? targetEquityPct = null,
    Object? targetDebtPct = null,
    Object? targetGoldPct = null,
    Object? retirementAge = null,
    Object? lifeExpectancy = null,
    Object? monthlyExpense = freezed,
    Object? annualExpenses = null,
    Object? incomeType = null,
    Object? monthlyIncome = freezed,
    Object? incomeVariabilityPct = freezed,
    Object? expectedIncrementPct = null,
    Object? expectedLumpsums = null,
    Object? riskScoreComputed = freezed,
    Object? driftThresholdPct = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      familyId: null == familyId
          ? _value.familyId
          : familyId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      pan: freezed == pan
          ? _value.pan
          : pan // ignore: cast_nullable_to_non_nullable
              as String?,
      dateOfBirth: freezed == dateOfBirth
          ? _value.dateOfBirth
          : dateOfBirth // ignore: cast_nullable_to_non_nullable
              as String?,
      relationship: freezed == relationship
          ? _value.relationship
          : relationship // ignore: cast_nullable_to_non_nullable
              as String?,
      riskProfile: null == riskProfile
          ? _value.riskProfile
          : riskProfile // ignore: cast_nullable_to_non_nullable
              as String,
      riskTargetEquityPct: null == riskTargetEquityPct
          ? _value.riskTargetEquityPct
          : riskTargetEquityPct // ignore: cast_nullable_to_non_nullable
              as double,
      riskTargetDebtPct: null == riskTargetDebtPct
          ? _value.riskTargetDebtPct
          : riskTargetDebtPct // ignore: cast_nullable_to_non_nullable
              as double,
      riskQuestionnaireAnswers: freezed == riskQuestionnaireAnswers
          ? _value.riskQuestionnaireAnswers
          : riskQuestionnaireAnswers // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
      riskDemographics: freezed == riskDemographics
          ? _value.riskDemographics
          : riskDemographics // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      riskPhase1Score: freezed == riskPhase1Score
          ? _value.riskPhase1Score
          : riskPhase1Score // ignore: cast_nullable_to_non_nullable
              as int?,
      riskPhase2Adjustment: freezed == riskPhase2Adjustment
          ? _value.riskPhase2Adjustment
          : riskPhase2Adjustment // ignore: cast_nullable_to_non_nullable
              as int?,
      riskFinalScore: freezed == riskFinalScore
          ? _value.riskFinalScore
          : riskFinalScore // ignore: cast_nullable_to_non_nullable
              as int?,
      riskProfileSource: null == riskProfileSource
          ? _value.riskProfileSource
          : riskProfileSource // ignore: cast_nullable_to_non_nullable
              as String,
      riskProfileUpdatedAt: freezed == riskProfileUpdatedAt
          ? _value.riskProfileUpdatedAt
          : riskProfileUpdatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      taxSlabPct: null == taxSlabPct
          ? _value.taxSlabPct
          : taxSlabPct // ignore: cast_nullable_to_non_nullable
              as double,
      sipDay: null == sipDay
          ? _value.sipDay
          : sipDay // ignore: cast_nullable_to_non_nullable
              as int,
      kycStatus: null == kycStatus
          ? _value.kycStatus
          : kycStatus // ignore: cast_nullable_to_non_nullable
              as String,
      isPrimary: null == isPrimary
          ? _value.isPrimary
          : isPrimary // ignore: cast_nullable_to_non_nullable
              as bool,
      colorHex: null == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      mobile: freezed == mobile
          ? _value.mobile
          : mobile // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      investmentGoal: null == investmentGoal
          ? _value.investmentGoal
          : investmentGoal // ignore: cast_nullable_to_non_nullable
              as String,
      targetEquityPct: null == targetEquityPct
          ? _value.targetEquityPct
          : targetEquityPct // ignore: cast_nullable_to_non_nullable
              as double,
      targetDebtPct: null == targetDebtPct
          ? _value.targetDebtPct
          : targetDebtPct // ignore: cast_nullable_to_non_nullable
              as double,
      targetGoldPct: null == targetGoldPct
          ? _value.targetGoldPct
          : targetGoldPct // ignore: cast_nullable_to_non_nullable
              as double,
      retirementAge: null == retirementAge
          ? _value.retirementAge
          : retirementAge // ignore: cast_nullable_to_non_nullable
              as int,
      lifeExpectancy: null == lifeExpectancy
          ? _value.lifeExpectancy
          : lifeExpectancy // ignore: cast_nullable_to_non_nullable
              as int,
      monthlyExpense: freezed == monthlyExpense
          ? _value.monthlyExpense
          : monthlyExpense // ignore: cast_nullable_to_non_nullable
              as double?,
      annualExpenses: null == annualExpenses
          ? _value.annualExpenses
          : annualExpenses // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      incomeType: null == incomeType
          ? _value.incomeType
          : incomeType // ignore: cast_nullable_to_non_nullable
              as String,
      monthlyIncome: freezed == monthlyIncome
          ? _value.monthlyIncome
          : monthlyIncome // ignore: cast_nullable_to_non_nullable
              as double?,
      incomeVariabilityPct: freezed == incomeVariabilityPct
          ? _value.incomeVariabilityPct
          : incomeVariabilityPct // ignore: cast_nullable_to_non_nullable
              as double?,
      expectedIncrementPct: null == expectedIncrementPct
          ? _value.expectedIncrementPct
          : expectedIncrementPct // ignore: cast_nullable_to_non_nullable
              as double,
      expectedLumpsums: null == expectedLumpsums
          ? _value.expectedLumpsums
          : expectedLumpsums // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      riskScoreComputed: freezed == riskScoreComputed
          ? _value.riskScoreComputed
          : riskScoreComputed // ignore: cast_nullable_to_non_nullable
              as int?,
      driftThresholdPct: null == driftThresholdPct
          ? _value.driftThresholdPct
          : driftThresholdPct // ignore: cast_nullable_to_non_nullable
              as double,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FamilyMemberModelImplCopyWith<$Res>
    implements $FamilyMemberModelCopyWith<$Res> {
  factory _$$FamilyMemberModelImplCopyWith(_$FamilyMemberModelImpl value,
          $Res Function(_$FamilyMemberModelImpl) then) =
      __$$FamilyMemberModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'family_id') String familyId,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'display_name') String displayName,
      String? pan,
      @JsonKey(name: 'date_of_birth') String? dateOfBirth,
      String? relationship,
      @JsonKey(name: 'risk_profile') String riskProfile,
      @JsonKey(name: 'risk_target_equity_pct') double riskTargetEquityPct,
      @JsonKey(name: 'risk_target_debt_pct') double riskTargetDebtPct,
      @JsonKey(name: 'risk_questionnaire_answers')
      List<dynamic>? riskQuestionnaireAnswers,
      @JsonKey(name: 'risk_demographics')
      Map<String, dynamic>? riskDemographics,
      @JsonKey(name: 'risk_phase1_score') int? riskPhase1Score,
      @JsonKey(name: 'risk_phase2_adjustment') int? riskPhase2Adjustment,
      @JsonKey(name: 'risk_final_score') int? riskFinalScore,
      @JsonKey(name: 'risk_profile_source') String riskProfileSource,
      @JsonKey(name: 'risk_profile_updated_at') String? riskProfileUpdatedAt,
      @JsonKey(name: 'tax_slab_pct') double taxSlabPct,
      @JsonKey(name: 'sip_day') int sipDay,
      @JsonKey(name: 'kyc_status') String kycStatus,
      @JsonKey(name: 'is_primary') bool isPrimary,
      @JsonKey(name: 'color_hex') String colorHex,
      String? email,
      String? mobile,
      String? address,
      @JsonKey(name: 'investment_goal') String investmentGoal,
      @JsonKey(name: 'target_equity_pct') double targetEquityPct,
      @JsonKey(name: 'target_debt_pct') double targetDebtPct,
      @JsonKey(name: 'target_gold_pct') double targetGoldPct,
      @JsonKey(name: 'retirement_age') int retirementAge,
      @JsonKey(name: 'life_expectancy') int lifeExpectancy,
      @JsonKey(name: 'monthly_expense') double? monthlyExpense,
      @JsonKey(name: 'annual_expenses')
      List<Map<String, dynamic>> annualExpenses,
      @JsonKey(name: 'income_type') String incomeType,
      @JsonKey(name: 'monthly_income') double? monthlyIncome,
      @JsonKey(name: 'income_variability_pct') double? incomeVariabilityPct,
      @JsonKey(name: 'expected_increment_pct') double expectedIncrementPct,
      @JsonKey(name: 'expected_lumpsums')
      List<Map<String, dynamic>> expectedLumpsums,
      @JsonKey(name: 'risk_score_computed') int? riskScoreComputed,
      @JsonKey(name: 'drift_threshold_pct') double driftThresholdPct,
      @JsonKey(name: 'created_at') String? createdAt});
}

/// @nodoc
class __$$FamilyMemberModelImplCopyWithImpl<$Res>
    extends _$FamilyMemberModelCopyWithImpl<$Res, _$FamilyMemberModelImpl>
    implements _$$FamilyMemberModelImplCopyWith<$Res> {
  __$$FamilyMemberModelImplCopyWithImpl(_$FamilyMemberModelImpl _value,
      $Res Function(_$FamilyMemberModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of FamilyMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? ownerId = null,
    Object? displayName = null,
    Object? pan = freezed,
    Object? dateOfBirth = freezed,
    Object? relationship = freezed,
    Object? riskProfile = null,
    Object? riskTargetEquityPct = null,
    Object? riskTargetDebtPct = null,
    Object? riskQuestionnaireAnswers = freezed,
    Object? riskDemographics = freezed,
    Object? riskPhase1Score = freezed,
    Object? riskPhase2Adjustment = freezed,
    Object? riskFinalScore = freezed,
    Object? riskProfileSource = null,
    Object? riskProfileUpdatedAt = freezed,
    Object? taxSlabPct = null,
    Object? sipDay = null,
    Object? kycStatus = null,
    Object? isPrimary = null,
    Object? colorHex = null,
    Object? email = freezed,
    Object? mobile = freezed,
    Object? address = freezed,
    Object? investmentGoal = null,
    Object? targetEquityPct = null,
    Object? targetDebtPct = null,
    Object? targetGoldPct = null,
    Object? retirementAge = null,
    Object? lifeExpectancy = null,
    Object? monthlyExpense = freezed,
    Object? annualExpenses = null,
    Object? incomeType = null,
    Object? monthlyIncome = freezed,
    Object? incomeVariabilityPct = freezed,
    Object? expectedIncrementPct = null,
    Object? expectedLumpsums = null,
    Object? riskScoreComputed = freezed,
    Object? driftThresholdPct = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$FamilyMemberModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      familyId: null == familyId
          ? _value.familyId
          : familyId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      pan: freezed == pan
          ? _value.pan
          : pan // ignore: cast_nullable_to_non_nullable
              as String?,
      dateOfBirth: freezed == dateOfBirth
          ? _value.dateOfBirth
          : dateOfBirth // ignore: cast_nullable_to_non_nullable
              as String?,
      relationship: freezed == relationship
          ? _value.relationship
          : relationship // ignore: cast_nullable_to_non_nullable
              as String?,
      riskProfile: null == riskProfile
          ? _value.riskProfile
          : riskProfile // ignore: cast_nullable_to_non_nullable
              as String,
      riskTargetEquityPct: null == riskTargetEquityPct
          ? _value.riskTargetEquityPct
          : riskTargetEquityPct // ignore: cast_nullable_to_non_nullable
              as double,
      riskTargetDebtPct: null == riskTargetDebtPct
          ? _value.riskTargetDebtPct
          : riskTargetDebtPct // ignore: cast_nullable_to_non_nullable
              as double,
      riskQuestionnaireAnswers: freezed == riskQuestionnaireAnswers
          ? _value._riskQuestionnaireAnswers
          : riskQuestionnaireAnswers // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
      riskDemographics: freezed == riskDemographics
          ? _value._riskDemographics
          : riskDemographics // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      riskPhase1Score: freezed == riskPhase1Score
          ? _value.riskPhase1Score
          : riskPhase1Score // ignore: cast_nullable_to_non_nullable
              as int?,
      riskPhase2Adjustment: freezed == riskPhase2Adjustment
          ? _value.riskPhase2Adjustment
          : riskPhase2Adjustment // ignore: cast_nullable_to_non_nullable
              as int?,
      riskFinalScore: freezed == riskFinalScore
          ? _value.riskFinalScore
          : riskFinalScore // ignore: cast_nullable_to_non_nullable
              as int?,
      riskProfileSource: null == riskProfileSource
          ? _value.riskProfileSource
          : riskProfileSource // ignore: cast_nullable_to_non_nullable
              as String,
      riskProfileUpdatedAt: freezed == riskProfileUpdatedAt
          ? _value.riskProfileUpdatedAt
          : riskProfileUpdatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      taxSlabPct: null == taxSlabPct
          ? _value.taxSlabPct
          : taxSlabPct // ignore: cast_nullable_to_non_nullable
              as double,
      sipDay: null == sipDay
          ? _value.sipDay
          : sipDay // ignore: cast_nullable_to_non_nullable
              as int,
      kycStatus: null == kycStatus
          ? _value.kycStatus
          : kycStatus // ignore: cast_nullable_to_non_nullable
              as String,
      isPrimary: null == isPrimary
          ? _value.isPrimary
          : isPrimary // ignore: cast_nullable_to_non_nullable
              as bool,
      colorHex: null == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      mobile: freezed == mobile
          ? _value.mobile
          : mobile // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      investmentGoal: null == investmentGoal
          ? _value.investmentGoal
          : investmentGoal // ignore: cast_nullable_to_non_nullable
              as String,
      targetEquityPct: null == targetEquityPct
          ? _value.targetEquityPct
          : targetEquityPct // ignore: cast_nullable_to_non_nullable
              as double,
      targetDebtPct: null == targetDebtPct
          ? _value.targetDebtPct
          : targetDebtPct // ignore: cast_nullable_to_non_nullable
              as double,
      targetGoldPct: null == targetGoldPct
          ? _value.targetGoldPct
          : targetGoldPct // ignore: cast_nullable_to_non_nullable
              as double,
      retirementAge: null == retirementAge
          ? _value.retirementAge
          : retirementAge // ignore: cast_nullable_to_non_nullable
              as int,
      lifeExpectancy: null == lifeExpectancy
          ? _value.lifeExpectancy
          : lifeExpectancy // ignore: cast_nullable_to_non_nullable
              as int,
      monthlyExpense: freezed == monthlyExpense
          ? _value.monthlyExpense
          : monthlyExpense // ignore: cast_nullable_to_non_nullable
              as double?,
      annualExpenses: null == annualExpenses
          ? _value._annualExpenses
          : annualExpenses // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      incomeType: null == incomeType
          ? _value.incomeType
          : incomeType // ignore: cast_nullable_to_non_nullable
              as String,
      monthlyIncome: freezed == monthlyIncome
          ? _value.monthlyIncome
          : monthlyIncome // ignore: cast_nullable_to_non_nullable
              as double?,
      incomeVariabilityPct: freezed == incomeVariabilityPct
          ? _value.incomeVariabilityPct
          : incomeVariabilityPct // ignore: cast_nullable_to_non_nullable
              as double?,
      expectedIncrementPct: null == expectedIncrementPct
          ? _value.expectedIncrementPct
          : expectedIncrementPct // ignore: cast_nullable_to_non_nullable
              as double,
      expectedLumpsums: null == expectedLumpsums
          ? _value._expectedLumpsums
          : expectedLumpsums // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      riskScoreComputed: freezed == riskScoreComputed
          ? _value.riskScoreComputed
          : riskScoreComputed // ignore: cast_nullable_to_non_nullable
              as int?,
      driftThresholdPct: null == driftThresholdPct
          ? _value.driftThresholdPct
          : driftThresholdPct // ignore: cast_nullable_to_non_nullable
              as double,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FamilyMemberModelImpl implements _FamilyMemberModel {
  const _$FamilyMemberModelImpl(
      {required this.id,
      @JsonKey(name: 'family_id') required this.familyId,
      @JsonKey(name: 'owner_id') required this.ownerId,
      @JsonKey(name: 'display_name') required this.displayName,
      this.pan,
      @JsonKey(name: 'date_of_birth') this.dateOfBirth,
      this.relationship,
      @JsonKey(name: 'risk_profile') this.riskProfile = 'Moderate',
      @JsonKey(name: 'risk_target_equity_pct') this.riskTargetEquityPct = 55.0,
      @JsonKey(name: 'risk_target_debt_pct') this.riskTargetDebtPct = 45.0,
      @JsonKey(name: 'risk_questionnaire_answers')
      final List<dynamic>? riskQuestionnaireAnswers,
      @JsonKey(name: 'risk_demographics')
      final Map<String, dynamic>? riskDemographics,
      @JsonKey(name: 'risk_phase1_score') this.riskPhase1Score,
      @JsonKey(name: 'risk_phase2_adjustment') this.riskPhase2Adjustment,
      @JsonKey(name: 'risk_final_score') this.riskFinalScore,
      @JsonKey(name: 'risk_profile_source') this.riskProfileSource = 'manual',
      @JsonKey(name: 'risk_profile_updated_at') this.riskProfileUpdatedAt,
      @JsonKey(name: 'tax_slab_pct') this.taxSlabPct = 30.0,
      @JsonKey(name: 'sip_day') this.sipDay = 5,
      @JsonKey(name: 'kyc_status') this.kycStatus = 'Complete',
      @JsonKey(name: 'is_primary') this.isPrimary = false,
      @JsonKey(name: 'color_hex') this.colorHex = '#1B8A5A',
      this.email,
      this.mobile,
      this.address,
      @JsonKey(name: 'investment_goal') this.investmentGoal = 'Wealth Building',
      @JsonKey(name: 'target_equity_pct') this.targetEquityPct = 60.0,
      @JsonKey(name: 'target_debt_pct') this.targetDebtPct = 30.0,
      @JsonKey(name: 'target_gold_pct') this.targetGoldPct = 10.0,
      @JsonKey(name: 'retirement_age') this.retirementAge = 60,
      @JsonKey(name: 'life_expectancy') this.lifeExpectancy = 85,
      @JsonKey(name: 'monthly_expense') this.monthlyExpense,
      @JsonKey(name: 'annual_expenses')
      final List<Map<String, dynamic>> annualExpenses = const [],
      @JsonKey(name: 'income_type') this.incomeType = 'steady',
      @JsonKey(name: 'monthly_income') this.monthlyIncome,
      @JsonKey(name: 'income_variability_pct') this.incomeVariabilityPct,
      @JsonKey(name: 'expected_increment_pct') this.expectedIncrementPct = 8.0,
      @JsonKey(name: 'expected_lumpsums')
      final List<Map<String, dynamic>> expectedLumpsums = const [],
      @JsonKey(name: 'risk_score_computed') this.riskScoreComputed,
      @JsonKey(name: 'drift_threshold_pct') this.driftThresholdPct = 5.0,
      @JsonKey(name: 'created_at') this.createdAt})
      : _riskQuestionnaireAnswers = riskQuestionnaireAnswers,
        _riskDemographics = riskDemographics,
        _annualExpenses = annualExpenses,
        _expectedLumpsums = expectedLumpsums;

  factory _$FamilyMemberModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FamilyMemberModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'family_id')
  final String familyId;
  @override
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @override
  @JsonKey(name: 'display_name')
  final String displayName;
  @override
  final String? pan;
  @override
  @JsonKey(name: 'date_of_birth')
  final String? dateOfBirth;
  @override
  final String? relationship;
  @override
  @JsonKey(name: 'risk_profile')
  final String riskProfile;
  @override
  @JsonKey(name: 'risk_target_equity_pct')
  final double riskTargetEquityPct;
  @override
  @JsonKey(name: 'risk_target_debt_pct')
  final double riskTargetDebtPct;
  final List<dynamic>? _riskQuestionnaireAnswers;
  @override
  @JsonKey(name: 'risk_questionnaire_answers')
  List<dynamic>? get riskQuestionnaireAnswers {
    final value = _riskQuestionnaireAnswers;
    if (value == null) return null;
    if (_riskQuestionnaireAnswers is EqualUnmodifiableListView)
      return _riskQuestionnaireAnswers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _riskDemographics;
  @override
  @JsonKey(name: 'risk_demographics')
  Map<String, dynamic>? get riskDemographics {
    final value = _riskDemographics;
    if (value == null) return null;
    if (_riskDemographics is EqualUnmodifiableMapView) return _riskDemographics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'risk_phase1_score')
  final int? riskPhase1Score;
  @override
  @JsonKey(name: 'risk_phase2_adjustment')
  final int? riskPhase2Adjustment;
  @override
  @JsonKey(name: 'risk_final_score')
  final int? riskFinalScore;
  @override
  @JsonKey(name: 'risk_profile_source')
  final String riskProfileSource;
  @override
  @JsonKey(name: 'risk_profile_updated_at')
  final String? riskProfileUpdatedAt;
  @override
  @JsonKey(name: 'tax_slab_pct')
  final double taxSlabPct;
  @override
  @JsonKey(name: 'sip_day')
  final int sipDay;
  @override
  @JsonKey(name: 'kyc_status')
  final String kycStatus;
  @override
  @JsonKey(name: 'is_primary')
  final bool isPrimary;
  @override
  @JsonKey(name: 'color_hex')
  final String colorHex;
  @override
  final String? email;
  @override
  final String? mobile;
  @override
  final String? address;
  @override
  @JsonKey(name: 'investment_goal')
  final String investmentGoal;
  @override
  @JsonKey(name: 'target_equity_pct')
  final double targetEquityPct;
  @override
  @JsonKey(name: 'target_debt_pct')
  final double targetDebtPct;
  @override
  @JsonKey(name: 'target_gold_pct')
  final double targetGoldPct;
// Wealth Planner — financial profile
  @override
  @JsonKey(name: 'retirement_age')
  final int retirementAge;
  @override
  @JsonKey(name: 'life_expectancy')
  final int lifeExpectancy;
  @override
  @JsonKey(name: 'monthly_expense')
  final double? monthlyExpense;
  final List<Map<String, dynamic>> _annualExpenses;
  @override
  @JsonKey(name: 'annual_expenses')
  List<Map<String, dynamic>> get annualExpenses {
    if (_annualExpenses is EqualUnmodifiableListView) return _annualExpenses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_annualExpenses);
  }

  @override
  @JsonKey(name: 'income_type')
  final String incomeType;
  @override
  @JsonKey(name: 'monthly_income')
  final double? monthlyIncome;
  @override
  @JsonKey(name: 'income_variability_pct')
  final double? incomeVariabilityPct;
  @override
  @JsonKey(name: 'expected_increment_pct')
  final double expectedIncrementPct;
  final List<Map<String, dynamic>> _expectedLumpsums;
  @override
  @JsonKey(name: 'expected_lumpsums')
  List<Map<String, dynamic>> get expectedLumpsums {
    if (_expectedLumpsums is EqualUnmodifiableListView)
      return _expectedLumpsums;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_expectedLumpsums);
  }

  @override
  @JsonKey(name: 'risk_score_computed')
  final int? riskScoreComputed;
  @override
  @JsonKey(name: 'drift_threshold_pct')
  final double driftThresholdPct;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @override
  String toString() {
    return 'FamilyMemberModel(id: $id, familyId: $familyId, ownerId: $ownerId, displayName: $displayName, pan: $pan, dateOfBirth: $dateOfBirth, relationship: $relationship, riskProfile: $riskProfile, riskTargetEquityPct: $riskTargetEquityPct, riskTargetDebtPct: $riskTargetDebtPct, riskQuestionnaireAnswers: $riskQuestionnaireAnswers, riskDemographics: $riskDemographics, riskPhase1Score: $riskPhase1Score, riskPhase2Adjustment: $riskPhase2Adjustment, riskFinalScore: $riskFinalScore, riskProfileSource: $riskProfileSource, riskProfileUpdatedAt: $riskProfileUpdatedAt, taxSlabPct: $taxSlabPct, sipDay: $sipDay, kycStatus: $kycStatus, isPrimary: $isPrimary, colorHex: $colorHex, email: $email, mobile: $mobile, address: $address, investmentGoal: $investmentGoal, targetEquityPct: $targetEquityPct, targetDebtPct: $targetDebtPct, targetGoldPct: $targetGoldPct, retirementAge: $retirementAge, lifeExpectancy: $lifeExpectancy, monthlyExpense: $monthlyExpense, annualExpenses: $annualExpenses, incomeType: $incomeType, monthlyIncome: $monthlyIncome, incomeVariabilityPct: $incomeVariabilityPct, expectedIncrementPct: $expectedIncrementPct, expectedLumpsums: $expectedLumpsums, riskScoreComputed: $riskScoreComputed, driftThresholdPct: $driftThresholdPct, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FamilyMemberModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.pan, pan) || other.pan == pan) &&
            (identical(other.dateOfBirth, dateOfBirth) ||
                other.dateOfBirth == dateOfBirth) &&
            (identical(other.relationship, relationship) ||
                other.relationship == relationship) &&
            (identical(other.riskProfile, riskProfile) ||
                other.riskProfile == riskProfile) &&
            (identical(other.riskTargetEquityPct, riskTargetEquityPct) ||
                other.riskTargetEquityPct == riskTargetEquityPct) &&
            (identical(other.riskTargetDebtPct, riskTargetDebtPct) ||
                other.riskTargetDebtPct == riskTargetDebtPct) &&
            const DeepCollectionEquality().equals(
                other._riskQuestionnaireAnswers, _riskQuestionnaireAnswers) &&
            const DeepCollectionEquality()
                .equals(other._riskDemographics, _riskDemographics) &&
            (identical(other.riskPhase1Score, riskPhase1Score) ||
                other.riskPhase1Score == riskPhase1Score) &&
            (identical(other.riskPhase2Adjustment, riskPhase2Adjustment) ||
                other.riskPhase2Adjustment == riskPhase2Adjustment) &&
            (identical(other.riskFinalScore, riskFinalScore) ||
                other.riskFinalScore == riskFinalScore) &&
            (identical(other.riskProfileSource, riskProfileSource) ||
                other.riskProfileSource == riskProfileSource) &&
            (identical(other.riskProfileUpdatedAt, riskProfileUpdatedAt) ||
                other.riskProfileUpdatedAt == riskProfileUpdatedAt) &&
            (identical(other.taxSlabPct, taxSlabPct) ||
                other.taxSlabPct == taxSlabPct) &&
            (identical(other.sipDay, sipDay) || other.sipDay == sipDay) &&
            (identical(other.kycStatus, kycStatus) ||
                other.kycStatus == kycStatus) &&
            (identical(other.isPrimary, isPrimary) ||
                other.isPrimary == isPrimary) &&
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.mobile, mobile) || other.mobile == mobile) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.investmentGoal, investmentGoal) ||
                other.investmentGoal == investmentGoal) &&
            (identical(other.targetEquityPct, targetEquityPct) ||
                other.targetEquityPct == targetEquityPct) &&
            (identical(other.targetDebtPct, targetDebtPct) ||
                other.targetDebtPct == targetDebtPct) &&
            (identical(other.targetGoldPct, targetGoldPct) ||
                other.targetGoldPct == targetGoldPct) &&
            (identical(other.retirementAge, retirementAge) ||
                other.retirementAge == retirementAge) &&
            (identical(other.lifeExpectancy, lifeExpectancy) ||
                other.lifeExpectancy == lifeExpectancy) &&
            (identical(other.monthlyExpense, monthlyExpense) ||
                other.monthlyExpense == monthlyExpense) &&
            const DeepCollectionEquality()
                .equals(other._annualExpenses, _annualExpenses) &&
            (identical(other.incomeType, incomeType) ||
                other.incomeType == incomeType) &&
            (identical(other.monthlyIncome, monthlyIncome) ||
                other.monthlyIncome == monthlyIncome) &&
            (identical(other.incomeVariabilityPct, incomeVariabilityPct) ||
                other.incomeVariabilityPct == incomeVariabilityPct) &&
            (identical(other.expectedIncrementPct, expectedIncrementPct) ||
                other.expectedIncrementPct == expectedIncrementPct) &&
            const DeepCollectionEquality()
                .equals(other._expectedLumpsums, _expectedLumpsums) &&
            (identical(other.riskScoreComputed, riskScoreComputed) ||
                other.riskScoreComputed == riskScoreComputed) &&
            (identical(other.driftThresholdPct, driftThresholdPct) ||
                other.driftThresholdPct == driftThresholdPct) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        familyId,
        ownerId,
        displayName,
        pan,
        dateOfBirth,
        relationship,
        riskProfile,
        riskTargetEquityPct,
        riskTargetDebtPct,
        const DeepCollectionEquality().hash(_riskQuestionnaireAnswers),
        const DeepCollectionEquality().hash(_riskDemographics),
        riskPhase1Score,
        riskPhase2Adjustment,
        riskFinalScore,
        riskProfileSource,
        riskProfileUpdatedAt,
        taxSlabPct,
        sipDay,
        kycStatus,
        isPrimary,
        colorHex,
        email,
        mobile,
        address,
        investmentGoal,
        targetEquityPct,
        targetDebtPct,
        targetGoldPct,
        retirementAge,
        lifeExpectancy,
        monthlyExpense,
        const DeepCollectionEquality().hash(_annualExpenses),
        incomeType,
        monthlyIncome,
        incomeVariabilityPct,
        expectedIncrementPct,
        const DeepCollectionEquality().hash(_expectedLumpsums),
        riskScoreComputed,
        driftThresholdPct,
        createdAt
      ]);

  /// Create a copy of FamilyMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FamilyMemberModelImplCopyWith<_$FamilyMemberModelImpl> get copyWith =>
      __$$FamilyMemberModelImplCopyWithImpl<_$FamilyMemberModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FamilyMemberModelImplToJson(
      this,
    );
  }
}

abstract class _FamilyMemberModel implements FamilyMemberModel {
  const factory _FamilyMemberModel(
      {required final String id,
      @JsonKey(name: 'family_id') required final String familyId,
      @JsonKey(name: 'owner_id') required final String ownerId,
      @JsonKey(name: 'display_name') required final String displayName,
      final String? pan,
      @JsonKey(name: 'date_of_birth') final String? dateOfBirth,
      final String? relationship,
      @JsonKey(name: 'risk_profile') final String riskProfile,
      @JsonKey(name: 'risk_target_equity_pct') final double riskTargetEquityPct,
      @JsonKey(name: 'risk_target_debt_pct') final double riskTargetDebtPct,
      @JsonKey(name: 'risk_questionnaire_answers')
      final List<dynamic>? riskQuestionnaireAnswers,
      @JsonKey(name: 'risk_demographics')
      final Map<String, dynamic>? riskDemographics,
      @JsonKey(name: 'risk_phase1_score') final int? riskPhase1Score,
      @JsonKey(name: 'risk_phase2_adjustment') final int? riskPhase2Adjustment,
      @JsonKey(name: 'risk_final_score') final int? riskFinalScore,
      @JsonKey(name: 'risk_profile_source') final String riskProfileSource,
      @JsonKey(name: 'risk_profile_updated_at')
      final String? riskProfileUpdatedAt,
      @JsonKey(name: 'tax_slab_pct') final double taxSlabPct,
      @JsonKey(name: 'sip_day') final int sipDay,
      @JsonKey(name: 'kyc_status') final String kycStatus,
      @JsonKey(name: 'is_primary') final bool isPrimary,
      @JsonKey(name: 'color_hex') final String colorHex,
      final String? email,
      final String? mobile,
      final String? address,
      @JsonKey(name: 'investment_goal') final String investmentGoal,
      @JsonKey(name: 'target_equity_pct') final double targetEquityPct,
      @JsonKey(name: 'target_debt_pct') final double targetDebtPct,
      @JsonKey(name: 'target_gold_pct') final double targetGoldPct,
      @JsonKey(name: 'retirement_age') final int retirementAge,
      @JsonKey(name: 'life_expectancy') final int lifeExpectancy,
      @JsonKey(name: 'monthly_expense') final double? monthlyExpense,
      @JsonKey(name: 'annual_expenses')
      final List<Map<String, dynamic>> annualExpenses,
      @JsonKey(name: 'income_type') final String incomeType,
      @JsonKey(name: 'monthly_income') final double? monthlyIncome,
      @JsonKey(name: 'income_variability_pct')
      final double? incomeVariabilityPct,
      @JsonKey(name: 'expected_increment_pct')
      final double expectedIncrementPct,
      @JsonKey(name: 'expected_lumpsums')
      final List<Map<String, dynamic>> expectedLumpsums,
      @JsonKey(name: 'risk_score_computed') final int? riskScoreComputed,
      @JsonKey(name: 'drift_threshold_pct') final double driftThresholdPct,
      @JsonKey(name: 'created_at')
      final String? createdAt}) = _$FamilyMemberModelImpl;

  factory _FamilyMemberModel.fromJson(Map<String, dynamic> json) =
      _$FamilyMemberModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'family_id')
  String get familyId;
  @override
  @JsonKey(name: 'owner_id')
  String get ownerId;
  @override
  @JsonKey(name: 'display_name')
  String get displayName;
  @override
  String? get pan;
  @override
  @JsonKey(name: 'date_of_birth')
  String? get dateOfBirth;
  @override
  String? get relationship;
  @override
  @JsonKey(name: 'risk_profile')
  String get riskProfile;
  @override
  @JsonKey(name: 'risk_target_equity_pct')
  double get riskTargetEquityPct;
  @override
  @JsonKey(name: 'risk_target_debt_pct')
  double get riskTargetDebtPct;
  @override
  @JsonKey(name: 'risk_questionnaire_answers')
  List<dynamic>? get riskQuestionnaireAnswers;
  @override
  @JsonKey(name: 'risk_demographics')
  Map<String, dynamic>? get riskDemographics;
  @override
  @JsonKey(name: 'risk_phase1_score')
  int? get riskPhase1Score;
  @override
  @JsonKey(name: 'risk_phase2_adjustment')
  int? get riskPhase2Adjustment;
  @override
  @JsonKey(name: 'risk_final_score')
  int? get riskFinalScore;
  @override
  @JsonKey(name: 'risk_profile_source')
  String get riskProfileSource;
  @override
  @JsonKey(name: 'risk_profile_updated_at')
  String? get riskProfileUpdatedAt;
  @override
  @JsonKey(name: 'tax_slab_pct')
  double get taxSlabPct;
  @override
  @JsonKey(name: 'sip_day')
  int get sipDay;
  @override
  @JsonKey(name: 'kyc_status')
  String get kycStatus;
  @override
  @JsonKey(name: 'is_primary')
  bool get isPrimary;
  @override
  @JsonKey(name: 'color_hex')
  String get colorHex;
  @override
  String? get email;
  @override
  String? get mobile;
  @override
  String? get address;
  @override
  @JsonKey(name: 'investment_goal')
  String get investmentGoal;
  @override
  @JsonKey(name: 'target_equity_pct')
  double get targetEquityPct;
  @override
  @JsonKey(name: 'target_debt_pct')
  double get targetDebtPct;
  @override
  @JsonKey(name: 'target_gold_pct')
  double get targetGoldPct; // Wealth Planner — financial profile
  @override
  @JsonKey(name: 'retirement_age')
  int get retirementAge;
  @override
  @JsonKey(name: 'life_expectancy')
  int get lifeExpectancy;
  @override
  @JsonKey(name: 'monthly_expense')
  double? get monthlyExpense;
  @override
  @JsonKey(name: 'annual_expenses')
  List<Map<String, dynamic>> get annualExpenses;
  @override
  @JsonKey(name: 'income_type')
  String get incomeType;
  @override
  @JsonKey(name: 'monthly_income')
  double? get monthlyIncome;
  @override
  @JsonKey(name: 'income_variability_pct')
  double? get incomeVariabilityPct;
  @override
  @JsonKey(name: 'expected_increment_pct')
  double get expectedIncrementPct;
  @override
  @JsonKey(name: 'expected_lumpsums')
  List<Map<String, dynamic>> get expectedLumpsums;
  @override
  @JsonKey(name: 'risk_score_computed')
  int? get riskScoreComputed;
  @override
  @JsonKey(name: 'drift_threshold_pct')
  double get driftThresholdPct;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;

  /// Create a copy of FamilyMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FamilyMemberModelImplCopyWith<_$FamilyMemberModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) {
  return _ProfileModel.fromJson(json);
}

/// @nodoc
mixin _$ProfileModel {
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  @JsonKey(name: 'full_name')
  String? get fullName => throw _privateConstructorUsedError;
  String? get pan => throw _privateConstructorUsedError;
  String? get mobile => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  @JsonKey(name: 'subscription_tier')
  String get subscriptionTier => throw _privateConstructorUsedError;
  @JsonKey(name: 'subscription_status')
  String get subscriptionStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'subscription_expires_at')
  String? get subscriptionExpiresAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'mfa_enabled')
  bool get mfaEnabled => throw _privateConstructorUsedError;
  @JsonKey(name: 'onboarding_complete')
  bool get onboardingComplete => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ProfileModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileModelCopyWith<ProfileModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileModelCopyWith<$Res> {
  factory $ProfileModelCopyWith(
          ProfileModel value, $Res Function(ProfileModel) then) =
      _$ProfileModelCopyWithImpl<$Res, ProfileModel>;
  @useResult
  $Res call(
      {String id,
      String email,
      @JsonKey(name: 'full_name') String? fullName,
      String? pan,
      String? mobile,
      String role,
      @JsonKey(name: 'subscription_tier') String subscriptionTier,
      @JsonKey(name: 'subscription_status') String subscriptionStatus,
      @JsonKey(name: 'subscription_expires_at') String? subscriptionExpiresAt,
      @JsonKey(name: 'mfa_enabled') bool mfaEnabled,
      @JsonKey(name: 'onboarding_complete') bool onboardingComplete,
      @JsonKey(name: 'created_at') String? createdAt});
}

/// @nodoc
class _$ProfileModelCopyWithImpl<$Res, $Val extends ProfileModel>
    implements $ProfileModelCopyWith<$Res> {
  _$ProfileModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? fullName = freezed,
    Object? pan = freezed,
    Object? mobile = freezed,
    Object? role = null,
    Object? subscriptionTier = null,
    Object? subscriptionStatus = null,
    Object? subscriptionExpiresAt = freezed,
    Object? mfaEnabled = null,
    Object? onboardingComplete = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      pan: freezed == pan
          ? _value.pan
          : pan // ignore: cast_nullable_to_non_nullable
              as String?,
      mobile: freezed == mobile
          ? _value.mobile
          : mobile // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      subscriptionTier: null == subscriptionTier
          ? _value.subscriptionTier
          : subscriptionTier // ignore: cast_nullable_to_non_nullable
              as String,
      subscriptionStatus: null == subscriptionStatus
          ? _value.subscriptionStatus
          : subscriptionStatus // ignore: cast_nullable_to_non_nullable
              as String,
      subscriptionExpiresAt: freezed == subscriptionExpiresAt
          ? _value.subscriptionExpiresAt
          : subscriptionExpiresAt // ignore: cast_nullable_to_non_nullable
              as String?,
      mfaEnabled: null == mfaEnabled
          ? _value.mfaEnabled
          : mfaEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      onboardingComplete: null == onboardingComplete
          ? _value.onboardingComplete
          : onboardingComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfileModelImplCopyWith<$Res>
    implements $ProfileModelCopyWith<$Res> {
  factory _$$ProfileModelImplCopyWith(
          _$ProfileModelImpl value, $Res Function(_$ProfileModelImpl) then) =
      __$$ProfileModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String email,
      @JsonKey(name: 'full_name') String? fullName,
      String? pan,
      String? mobile,
      String role,
      @JsonKey(name: 'subscription_tier') String subscriptionTier,
      @JsonKey(name: 'subscription_status') String subscriptionStatus,
      @JsonKey(name: 'subscription_expires_at') String? subscriptionExpiresAt,
      @JsonKey(name: 'mfa_enabled') bool mfaEnabled,
      @JsonKey(name: 'onboarding_complete') bool onboardingComplete,
      @JsonKey(name: 'created_at') String? createdAt});
}

/// @nodoc
class __$$ProfileModelImplCopyWithImpl<$Res>
    extends _$ProfileModelCopyWithImpl<$Res, _$ProfileModelImpl>
    implements _$$ProfileModelImplCopyWith<$Res> {
  __$$ProfileModelImplCopyWithImpl(
      _$ProfileModelImpl _value, $Res Function(_$ProfileModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? fullName = freezed,
    Object? pan = freezed,
    Object? mobile = freezed,
    Object? role = null,
    Object? subscriptionTier = null,
    Object? subscriptionStatus = null,
    Object? subscriptionExpiresAt = freezed,
    Object? mfaEnabled = null,
    Object? onboardingComplete = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$ProfileModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      pan: freezed == pan
          ? _value.pan
          : pan // ignore: cast_nullable_to_non_nullable
              as String?,
      mobile: freezed == mobile
          ? _value.mobile
          : mobile // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      subscriptionTier: null == subscriptionTier
          ? _value.subscriptionTier
          : subscriptionTier // ignore: cast_nullable_to_non_nullable
              as String,
      subscriptionStatus: null == subscriptionStatus
          ? _value.subscriptionStatus
          : subscriptionStatus // ignore: cast_nullable_to_non_nullable
              as String,
      subscriptionExpiresAt: freezed == subscriptionExpiresAt
          ? _value.subscriptionExpiresAt
          : subscriptionExpiresAt // ignore: cast_nullable_to_non_nullable
              as String?,
      mfaEnabled: null == mfaEnabled
          ? _value.mfaEnabled
          : mfaEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      onboardingComplete: null == onboardingComplete
          ? _value.onboardingComplete
          : onboardingComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfileModelImpl extends _ProfileModel {
  const _$ProfileModelImpl(
      {required this.id,
      required this.email,
      @JsonKey(name: 'full_name') this.fullName,
      this.pan,
      this.mobile,
      this.role = 'user',
      @JsonKey(name: 'subscription_tier') this.subscriptionTier = 'free',
      @JsonKey(name: 'subscription_status') this.subscriptionStatus = 'active',
      @JsonKey(name: 'subscription_expires_at') this.subscriptionExpiresAt,
      @JsonKey(name: 'mfa_enabled') this.mfaEnabled = false,
      @JsonKey(name: 'onboarding_complete') this.onboardingComplete = false,
      @JsonKey(name: 'created_at') this.createdAt})
      : super._();

  factory _$ProfileModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfileModelImplFromJson(json);

  @override
  final String id;
  @override
  final String email;
  @override
  @JsonKey(name: 'full_name')
  final String? fullName;
  @override
  final String? pan;
  @override
  final String? mobile;
  @override
  @JsonKey()
  final String role;
  @override
  @JsonKey(name: 'subscription_tier')
  final String subscriptionTier;
  @override
  @JsonKey(name: 'subscription_status')
  final String subscriptionStatus;
  @override
  @JsonKey(name: 'subscription_expires_at')
  final String? subscriptionExpiresAt;
  @override
  @JsonKey(name: 'mfa_enabled')
  final bool mfaEnabled;
  @override
  @JsonKey(name: 'onboarding_complete')
  final bool onboardingComplete;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @override
  String toString() {
    return 'ProfileModel(id: $id, email: $email, fullName: $fullName, pan: $pan, mobile: $mobile, role: $role, subscriptionTier: $subscriptionTier, subscriptionStatus: $subscriptionStatus, subscriptionExpiresAt: $subscriptionExpiresAt, mfaEnabled: $mfaEnabled, onboardingComplete: $onboardingComplete, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.pan, pan) || other.pan == pan) &&
            (identical(other.mobile, mobile) || other.mobile == mobile) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.subscriptionTier, subscriptionTier) ||
                other.subscriptionTier == subscriptionTier) &&
            (identical(other.subscriptionStatus, subscriptionStatus) ||
                other.subscriptionStatus == subscriptionStatus) &&
            (identical(other.subscriptionExpiresAt, subscriptionExpiresAt) ||
                other.subscriptionExpiresAt == subscriptionExpiresAt) &&
            (identical(other.mfaEnabled, mfaEnabled) ||
                other.mfaEnabled == mfaEnabled) &&
            (identical(other.onboardingComplete, onboardingComplete) ||
                other.onboardingComplete == onboardingComplete) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      email,
      fullName,
      pan,
      mobile,
      role,
      subscriptionTier,
      subscriptionStatus,
      subscriptionExpiresAt,
      mfaEnabled,
      onboardingComplete,
      createdAt);

  /// Create a copy of ProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileModelImplCopyWith<_$ProfileModelImpl> get copyWith =>
      __$$ProfileModelImplCopyWithImpl<_$ProfileModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfileModelImplToJson(
      this,
    );
  }
}

abstract class _ProfileModel extends ProfileModel {
  const factory _ProfileModel(
          {required final String id,
          required final String email,
          @JsonKey(name: 'full_name') final String? fullName,
          final String? pan,
          final String? mobile,
          final String role,
          @JsonKey(name: 'subscription_tier') final String subscriptionTier,
          @JsonKey(name: 'subscription_status') final String subscriptionStatus,
          @JsonKey(name: 'subscription_expires_at')
          final String? subscriptionExpiresAt,
          @JsonKey(name: 'mfa_enabled') final bool mfaEnabled,
          @JsonKey(name: 'onboarding_complete') final bool onboardingComplete,
          @JsonKey(name: 'created_at') final String? createdAt}) =
      _$ProfileModelImpl;
  const _ProfileModel._() : super._();

  factory _ProfileModel.fromJson(Map<String, dynamic> json) =
      _$ProfileModelImpl.fromJson;

  @override
  String get id;
  @override
  String get email;
  @override
  @JsonKey(name: 'full_name')
  String? get fullName;
  @override
  String? get pan;
  @override
  String? get mobile;
  @override
  String get role;
  @override
  @JsonKey(name: 'subscription_tier')
  String get subscriptionTier;
  @override
  @JsonKey(name: 'subscription_status')
  String get subscriptionStatus;
  @override
  @JsonKey(name: 'subscription_expires_at')
  String? get subscriptionExpiresAt;
  @override
  @JsonKey(name: 'mfa_enabled')
  bool get mfaEnabled;
  @override
  @JsonKey(name: 'onboarding_complete')
  bool get onboardingComplete;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;

  /// Create a copy of ProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileModelImplCopyWith<_$ProfileModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
