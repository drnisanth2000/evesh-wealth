// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'deployment_plan_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DeploymentPlanModel _$DeploymentPlanModelFromJson(Map<String, dynamic> json) {
  return _DeploymentPlanModel.fromJson(json);
}

/// @nodoc
mixin _$DeploymentPlanModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'owner_id')
  String get ownerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'family_id')
  String? get familyId => throw _privateConstructorUsedError;
  @JsonKey(name: 'member_id')
  String? get memberId => throw _privateConstructorUsedError;
  @JsonKey(name: 'lumpsum_rupees')
  double get lumpsumRupees => throw _privateConstructorUsedError;
  @JsonKey(name: 'sip_rupees')
  double get sipRupees => throw _privateConstructorUsedError;
  @JsonKey(name: 'split_pct')
  double get splitPct => throw _privateConstructorUsedError;
  @JsonKey(name: 'plan_jsonb')
  Map<String, dynamic> get planJson => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'executed_at')
  String? get executedAt => throw _privateConstructorUsedError;

  /// Serializes this DeploymentPlanModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeploymentPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeploymentPlanModelCopyWith<DeploymentPlanModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeploymentPlanModelCopyWith<$Res> {
  factory $DeploymentPlanModelCopyWith(
          DeploymentPlanModel value, $Res Function(DeploymentPlanModel) then) =
      _$DeploymentPlanModelCopyWithImpl<$Res, DeploymentPlanModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'family_id') String? familyId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'lumpsum_rupees') double lumpsumRupees,
      @JsonKey(name: 'sip_rupees') double sipRupees,
      @JsonKey(name: 'split_pct') double splitPct,
      @JsonKey(name: 'plan_jsonb') Map<String, dynamic> planJson,
      String? notes,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'executed_at') String? executedAt});
}

/// @nodoc
class _$DeploymentPlanModelCopyWithImpl<$Res, $Val extends DeploymentPlanModel>
    implements $DeploymentPlanModelCopyWith<$Res> {
  _$DeploymentPlanModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeploymentPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? familyId = freezed,
    Object? memberId = freezed,
    Object? lumpsumRupees = null,
    Object? sipRupees = null,
    Object? splitPct = null,
    Object? planJson = null,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? executedAt = freezed,
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
      familyId: freezed == familyId
          ? _value.familyId
          : familyId // ignore: cast_nullable_to_non_nullable
              as String?,
      memberId: freezed == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String?,
      lumpsumRupees: null == lumpsumRupees
          ? _value.lumpsumRupees
          : lumpsumRupees // ignore: cast_nullable_to_non_nullable
              as double,
      sipRupees: null == sipRupees
          ? _value.sipRupees
          : sipRupees // ignore: cast_nullable_to_non_nullable
              as double,
      splitPct: null == splitPct
          ? _value.splitPct
          : splitPct // ignore: cast_nullable_to_non_nullable
              as double,
      planJson: null == planJson
          ? _value.planJson
          : planJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      executedAt: freezed == executedAt
          ? _value.executedAt
          : executedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeploymentPlanModelImplCopyWith<$Res>
    implements $DeploymentPlanModelCopyWith<$Res> {
  factory _$$DeploymentPlanModelImplCopyWith(_$DeploymentPlanModelImpl value,
          $Res Function(_$DeploymentPlanModelImpl) then) =
      __$$DeploymentPlanModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'family_id') String? familyId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'lumpsum_rupees') double lumpsumRupees,
      @JsonKey(name: 'sip_rupees') double sipRupees,
      @JsonKey(name: 'split_pct') double splitPct,
      @JsonKey(name: 'plan_jsonb') Map<String, dynamic> planJson,
      String? notes,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'executed_at') String? executedAt});
}

/// @nodoc
class __$$DeploymentPlanModelImplCopyWithImpl<$Res>
    extends _$DeploymentPlanModelCopyWithImpl<$Res, _$DeploymentPlanModelImpl>
    implements _$$DeploymentPlanModelImplCopyWith<$Res> {
  __$$DeploymentPlanModelImplCopyWithImpl(_$DeploymentPlanModelImpl _value,
      $Res Function(_$DeploymentPlanModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of DeploymentPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? familyId = freezed,
    Object? memberId = freezed,
    Object? lumpsumRupees = null,
    Object? sipRupees = null,
    Object? splitPct = null,
    Object? planJson = null,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? executedAt = freezed,
  }) {
    return _then(_$DeploymentPlanModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      familyId: freezed == familyId
          ? _value.familyId
          : familyId // ignore: cast_nullable_to_non_nullable
              as String?,
      memberId: freezed == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String?,
      lumpsumRupees: null == lumpsumRupees
          ? _value.lumpsumRupees
          : lumpsumRupees // ignore: cast_nullable_to_non_nullable
              as double,
      sipRupees: null == sipRupees
          ? _value.sipRupees
          : sipRupees // ignore: cast_nullable_to_non_nullable
              as double,
      splitPct: null == splitPct
          ? _value.splitPct
          : splitPct // ignore: cast_nullable_to_non_nullable
              as double,
      planJson: null == planJson
          ? _value._planJson
          : planJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      executedAt: freezed == executedAt
          ? _value.executedAt
          : executedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeploymentPlanModelImpl implements _DeploymentPlanModel {
  const _$DeploymentPlanModelImpl(
      {required this.id,
      @JsonKey(name: 'owner_id') required this.ownerId,
      @JsonKey(name: 'family_id') this.familyId,
      @JsonKey(name: 'member_id') this.memberId,
      @JsonKey(name: 'lumpsum_rupees') this.lumpsumRupees = 0.0,
      @JsonKey(name: 'sip_rupees') this.sipRupees = 0.0,
      @JsonKey(name: 'split_pct') this.splitPct = 30.0,
      @JsonKey(name: 'plan_jsonb') required final Map<String, dynamic> planJson,
      this.notes,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'executed_at') this.executedAt})
      : _planJson = planJson;

  factory _$DeploymentPlanModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeploymentPlanModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @override
  @JsonKey(name: 'family_id')
  final String? familyId;
  @override
  @JsonKey(name: 'member_id')
  final String? memberId;
  @override
  @JsonKey(name: 'lumpsum_rupees')
  final double lumpsumRupees;
  @override
  @JsonKey(name: 'sip_rupees')
  final double sipRupees;
  @override
  @JsonKey(name: 'split_pct')
  final double splitPct;
  final Map<String, dynamic> _planJson;
  @override
  @JsonKey(name: 'plan_jsonb')
  Map<String, dynamic> get planJson {
    if (_planJson is EqualUnmodifiableMapView) return _planJson;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_planJson);
  }

  @override
  final String? notes;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  @JsonKey(name: 'executed_at')
  final String? executedAt;

  @override
  String toString() {
    return 'DeploymentPlanModel(id: $id, ownerId: $ownerId, familyId: $familyId, memberId: $memberId, lumpsumRupees: $lumpsumRupees, sipRupees: $sipRupees, splitPct: $splitPct, planJson: $planJson, notes: $notes, createdAt: $createdAt, executedAt: $executedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeploymentPlanModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.lumpsumRupees, lumpsumRupees) ||
                other.lumpsumRupees == lumpsumRupees) &&
            (identical(other.sipRupees, sipRupees) ||
                other.sipRupees == sipRupees) &&
            (identical(other.splitPct, splitPct) ||
                other.splitPct == splitPct) &&
            const DeepCollectionEquality().equals(other._planJson, _planJson) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.executedAt, executedAt) ||
                other.executedAt == executedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      ownerId,
      familyId,
      memberId,
      lumpsumRupees,
      sipRupees,
      splitPct,
      const DeepCollectionEquality().hash(_planJson),
      notes,
      createdAt,
      executedAt);

  /// Create a copy of DeploymentPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeploymentPlanModelImplCopyWith<_$DeploymentPlanModelImpl> get copyWith =>
      __$$DeploymentPlanModelImplCopyWithImpl<_$DeploymentPlanModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeploymentPlanModelImplToJson(
      this,
    );
  }
}

abstract class _DeploymentPlanModel implements DeploymentPlanModel {
  const factory _DeploymentPlanModel(
      {required final String id,
      @JsonKey(name: 'owner_id') required final String ownerId,
      @JsonKey(name: 'family_id') final String? familyId,
      @JsonKey(name: 'member_id') final String? memberId,
      @JsonKey(name: 'lumpsum_rupees') final double lumpsumRupees,
      @JsonKey(name: 'sip_rupees') final double sipRupees,
      @JsonKey(name: 'split_pct') final double splitPct,
      @JsonKey(name: 'plan_jsonb') required final Map<String, dynamic> planJson,
      final String? notes,
      @JsonKey(name: 'created_at') required final String createdAt,
      @JsonKey(name: 'executed_at')
      final String? executedAt}) = _$DeploymentPlanModelImpl;

  factory _DeploymentPlanModel.fromJson(Map<String, dynamic> json) =
      _$DeploymentPlanModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'owner_id')
  String get ownerId;
  @override
  @JsonKey(name: 'family_id')
  String? get familyId;
  @override
  @JsonKey(name: 'member_id')
  String? get memberId;
  @override
  @JsonKey(name: 'lumpsum_rupees')
  double get lumpsumRupees;
  @override
  @JsonKey(name: 'sip_rupees')
  double get sipRupees;
  @override
  @JsonKey(name: 'split_pct')
  double get splitPct;
  @override
  @JsonKey(name: 'plan_jsonb')
  Map<String, dynamic> get planJson;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  @JsonKey(name: 'executed_at')
  String? get executedAt;

  /// Create a copy of DeploymentPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeploymentPlanModelImplCopyWith<_$DeploymentPlanModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
