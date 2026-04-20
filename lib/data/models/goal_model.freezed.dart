// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goal_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GoalModel _$GoalModelFromJson(Map<String, dynamic> json) {
  return _GoalModel.fromJson(json);
}

/// @nodoc
mixin _$GoalModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'owner_id')
  String get ownerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'family_id')
  String get familyId => throw _privateConstructorUsedError;
  @JsonKey(name: 'member_id')
  String? get memberId => throw _privateConstructorUsedError;
  @JsonKey(name: 'goal_name')
  String get goalName => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_amount')
  double get targetAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_date')
  String get targetDate => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this GoalModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GoalModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GoalModelCopyWith<GoalModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoalModelCopyWith<$Res> {
  factory $GoalModelCopyWith(GoalModel value, $Res Function(GoalModel) then) =
      _$GoalModelCopyWithImpl<$Res, GoalModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'family_id') String familyId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'goal_name') String goalName,
      @JsonKey(name: 'target_amount') double targetAmount,
      @JsonKey(name: 'target_date') String targetDate,
      String? notes,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt});
}

/// @nodoc
class _$GoalModelCopyWithImpl<$Res, $Val extends GoalModel>
    implements $GoalModelCopyWith<$Res> {
  _$GoalModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GoalModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? familyId = null,
    Object? memberId = freezed,
    Object? goalName = null,
    Object? targetAmount = null,
    Object? targetDate = null,
    Object? notes = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
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
      familyId: null == familyId
          ? _value.familyId
          : familyId // ignore: cast_nullable_to_non_nullable
              as String,
      memberId: freezed == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String?,
      goalName: null == goalName
          ? _value.goalName
          : goalName // ignore: cast_nullable_to_non_nullable
              as String,
      targetAmount: null == targetAmount
          ? _value.targetAmount
          : targetAmount // ignore: cast_nullable_to_non_nullable
              as double,
      targetDate: null == targetDate
          ? _value.targetDate
          : targetDate // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GoalModelImplCopyWith<$Res>
    implements $GoalModelCopyWith<$Res> {
  factory _$$GoalModelImplCopyWith(
          _$GoalModelImpl value, $Res Function(_$GoalModelImpl) then) =
      __$$GoalModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'family_id') String familyId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'goal_name') String goalName,
      @JsonKey(name: 'target_amount') double targetAmount,
      @JsonKey(name: 'target_date') String targetDate,
      String? notes,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt});
}

/// @nodoc
class __$$GoalModelImplCopyWithImpl<$Res>
    extends _$GoalModelCopyWithImpl<$Res, _$GoalModelImpl>
    implements _$$GoalModelImplCopyWith<$Res> {
  __$$GoalModelImplCopyWithImpl(
      _$GoalModelImpl _value, $Res Function(_$GoalModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of GoalModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? familyId = null,
    Object? memberId = freezed,
    Object? goalName = null,
    Object? targetAmount = null,
    Object? targetDate = null,
    Object? notes = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$GoalModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      familyId: null == familyId
          ? _value.familyId
          : familyId // ignore: cast_nullable_to_non_nullable
              as String,
      memberId: freezed == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String?,
      goalName: null == goalName
          ? _value.goalName
          : goalName // ignore: cast_nullable_to_non_nullable
              as String,
      targetAmount: null == targetAmount
          ? _value.targetAmount
          : targetAmount // ignore: cast_nullable_to_non_nullable
              as double,
      targetDate: null == targetDate
          ? _value.targetDate
          : targetDate // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GoalModelImpl implements _GoalModel {
  const _$GoalModelImpl(
      {required this.id,
      @JsonKey(name: 'owner_id') required this.ownerId,
      @JsonKey(name: 'family_id') required this.familyId,
      @JsonKey(name: 'member_id') this.memberId,
      @JsonKey(name: 'goal_name') required this.goalName,
      @JsonKey(name: 'target_amount') required this.targetAmount,
      @JsonKey(name: 'target_date') required this.targetDate,
      this.notes,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt});

  factory _$GoalModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GoalModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @override
  @JsonKey(name: 'family_id')
  final String familyId;
  @override
  @JsonKey(name: 'member_id')
  final String? memberId;
  @override
  @JsonKey(name: 'goal_name')
  final String goalName;
  @override
  @JsonKey(name: 'target_amount')
  final double targetAmount;
  @override
  @JsonKey(name: 'target_date')
  final String targetDate;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  @override
  String toString() {
    return 'GoalModel(id: $id, ownerId: $ownerId, familyId: $familyId, memberId: $memberId, goalName: $goalName, targetAmount: $targetAmount, targetDate: $targetDate, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.goalName, goalName) ||
                other.goalName == goalName) &&
            (identical(other.targetAmount, targetAmount) ||
                other.targetAmount == targetAmount) &&
            (identical(other.targetDate, targetDate) ||
                other.targetDate == targetDate) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, ownerId, familyId, memberId,
      goalName, targetAmount, targetDate, notes, createdAt, updatedAt);

  /// Create a copy of GoalModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalModelImplCopyWith<_$GoalModelImpl> get copyWith =>
      __$$GoalModelImplCopyWithImpl<_$GoalModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GoalModelImplToJson(
      this,
    );
  }
}

abstract class _GoalModel implements GoalModel {
  const factory _GoalModel(
      {required final String id,
      @JsonKey(name: 'owner_id') required final String ownerId,
      @JsonKey(name: 'family_id') required final String familyId,
      @JsonKey(name: 'member_id') final String? memberId,
      @JsonKey(name: 'goal_name') required final String goalName,
      @JsonKey(name: 'target_amount') required final double targetAmount,
      @JsonKey(name: 'target_date') required final String targetDate,
      final String? notes,
      @JsonKey(name: 'created_at') final String? createdAt,
      @JsonKey(name: 'updated_at') final String? updatedAt}) = _$GoalModelImpl;

  factory _GoalModel.fromJson(Map<String, dynamic> json) =
      _$GoalModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'owner_id')
  String get ownerId;
  @override
  @JsonKey(name: 'family_id')
  String get familyId;
  @override
  @JsonKey(name: 'member_id')
  String? get memberId;
  @override
  @JsonKey(name: 'goal_name')
  String get goalName;
  @override
  @JsonKey(name: 'target_amount')
  double get targetAmount;
  @override
  @JsonKey(name: 'target_date')
  String get targetDate;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String? get updatedAt;

  /// Create a copy of GoalModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GoalModelImplCopyWith<_$GoalModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GoalFundLink _$GoalFundLinkFromJson(Map<String, dynamic> json) {
  return _GoalFundLink.fromJson(json);
}

/// @nodoc
mixin _$GoalFundLink {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'owner_id')
  String get ownerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'goal_id')
  String get goalId => throw _privateConstructorUsedError;
  @JsonKey(name: 'amfi_code')
  int get amfiCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'allocation_pct')
  double get allocationPct => throw _privateConstructorUsedError;

  /// Serializes this GoalFundLink to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GoalFundLink
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GoalFundLinkCopyWith<GoalFundLink> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoalFundLinkCopyWith<$Res> {
  factory $GoalFundLinkCopyWith(
          GoalFundLink value, $Res Function(GoalFundLink) then) =
      _$GoalFundLinkCopyWithImpl<$Res, GoalFundLink>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'goal_id') String goalId,
      @JsonKey(name: 'amfi_code') int amfiCode,
      @JsonKey(name: 'allocation_pct') double allocationPct});
}

/// @nodoc
class _$GoalFundLinkCopyWithImpl<$Res, $Val extends GoalFundLink>
    implements $GoalFundLinkCopyWith<$Res> {
  _$GoalFundLinkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GoalFundLink
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? goalId = null,
    Object? amfiCode = null,
    Object? allocationPct = null,
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
      goalId: null == goalId
          ? _value.goalId
          : goalId // ignore: cast_nullable_to_non_nullable
              as String,
      amfiCode: null == amfiCode
          ? _value.amfiCode
          : amfiCode // ignore: cast_nullable_to_non_nullable
              as int,
      allocationPct: null == allocationPct
          ? _value.allocationPct
          : allocationPct // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GoalFundLinkImplCopyWith<$Res>
    implements $GoalFundLinkCopyWith<$Res> {
  factory _$$GoalFundLinkImplCopyWith(
          _$GoalFundLinkImpl value, $Res Function(_$GoalFundLinkImpl) then) =
      __$$GoalFundLinkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'goal_id') String goalId,
      @JsonKey(name: 'amfi_code') int amfiCode,
      @JsonKey(name: 'allocation_pct') double allocationPct});
}

/// @nodoc
class __$$GoalFundLinkImplCopyWithImpl<$Res>
    extends _$GoalFundLinkCopyWithImpl<$Res, _$GoalFundLinkImpl>
    implements _$$GoalFundLinkImplCopyWith<$Res> {
  __$$GoalFundLinkImplCopyWithImpl(
      _$GoalFundLinkImpl _value, $Res Function(_$GoalFundLinkImpl) _then)
      : super(_value, _then);

  /// Create a copy of GoalFundLink
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? goalId = null,
    Object? amfiCode = null,
    Object? allocationPct = null,
  }) {
    return _then(_$GoalFundLinkImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      goalId: null == goalId
          ? _value.goalId
          : goalId // ignore: cast_nullable_to_non_nullable
              as String,
      amfiCode: null == amfiCode
          ? _value.amfiCode
          : amfiCode // ignore: cast_nullable_to_non_nullable
              as int,
      allocationPct: null == allocationPct
          ? _value.allocationPct
          : allocationPct // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GoalFundLinkImpl implements _GoalFundLink {
  const _$GoalFundLinkImpl(
      {required this.id,
      @JsonKey(name: 'owner_id') required this.ownerId,
      @JsonKey(name: 'goal_id') required this.goalId,
      @JsonKey(name: 'amfi_code') required this.amfiCode,
      @JsonKey(name: 'allocation_pct') this.allocationPct = 100.0});

  factory _$GoalFundLinkImpl.fromJson(Map<String, dynamic> json) =>
      _$$GoalFundLinkImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @override
  @JsonKey(name: 'goal_id')
  final String goalId;
  @override
  @JsonKey(name: 'amfi_code')
  final int amfiCode;
  @override
  @JsonKey(name: 'allocation_pct')
  final double allocationPct;

  @override
  String toString() {
    return 'GoalFundLink(id: $id, ownerId: $ownerId, goalId: $goalId, amfiCode: $amfiCode, allocationPct: $allocationPct)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalFundLinkImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.goalId, goalId) || other.goalId == goalId) &&
            (identical(other.amfiCode, amfiCode) ||
                other.amfiCode == amfiCode) &&
            (identical(other.allocationPct, allocationPct) ||
                other.allocationPct == allocationPct));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, ownerId, goalId, amfiCode, allocationPct);

  /// Create a copy of GoalFundLink
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalFundLinkImplCopyWith<_$GoalFundLinkImpl> get copyWith =>
      __$$GoalFundLinkImplCopyWithImpl<_$GoalFundLinkImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GoalFundLinkImplToJson(
      this,
    );
  }
}

abstract class _GoalFundLink implements GoalFundLink {
  const factory _GoalFundLink(
          {required final String id,
          @JsonKey(name: 'owner_id') required final String ownerId,
          @JsonKey(name: 'goal_id') required final String goalId,
          @JsonKey(name: 'amfi_code') required final int amfiCode,
          @JsonKey(name: 'allocation_pct') final double allocationPct}) =
      _$GoalFundLinkImpl;

  factory _GoalFundLink.fromJson(Map<String, dynamic> json) =
      _$GoalFundLinkImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'owner_id')
  String get ownerId;
  @override
  @JsonKey(name: 'goal_id')
  String get goalId;
  @override
  @JsonKey(name: 'amfi_code')
  int get amfiCode;
  @override
  @JsonKey(name: 'allocation_pct')
  double get allocationPct;

  /// Create a copy of GoalFundLink
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GoalFundLinkImplCopyWith<_$GoalFundLinkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
