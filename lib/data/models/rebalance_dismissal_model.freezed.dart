// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rebalance_dismissal_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RebalanceDismissalModel _$RebalanceDismissalModelFromJson(
    Map<String, dynamic> json) {
  return _RebalanceDismissalModel.fromJson(json);
}

/// @nodoc
mixin _$RebalanceDismissalModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'owner_id')
  String get ownerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'family_id')
  String? get familyId => throw _privateConstructorUsedError;
  @JsonKey(name: 'member_id')
  String? get memberId => throw _privateConstructorUsedError;
  @JsonKey(name: 'suggestion_hash')
  String get suggestionHash => throw _privateConstructorUsedError;
  @JsonKey(name: 'from_amfi_code')
  int? get fromAmfiCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_amfi_code')
  int? get toAmfiCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'drift_pct')
  double? get driftPct => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;
  @JsonKey(name: 'dismissed_at')
  String get dismissedAt => throw _privateConstructorUsedError;

  /// Serializes this RebalanceDismissalModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RebalanceDismissalModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RebalanceDismissalModelCopyWith<RebalanceDismissalModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RebalanceDismissalModelCopyWith<$Res> {
  factory $RebalanceDismissalModelCopyWith(RebalanceDismissalModel value,
          $Res Function(RebalanceDismissalModel) then) =
      _$RebalanceDismissalModelCopyWithImpl<$Res, RebalanceDismissalModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'family_id') String? familyId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'suggestion_hash') String suggestionHash,
      @JsonKey(name: 'from_amfi_code') int? fromAmfiCode,
      @JsonKey(name: 'to_amfi_code') int? toAmfiCode,
      @JsonKey(name: 'drift_pct') double? driftPct,
      String? reason,
      @JsonKey(name: 'dismissed_at') String dismissedAt});
}

/// @nodoc
class _$RebalanceDismissalModelCopyWithImpl<$Res,
        $Val extends RebalanceDismissalModel>
    implements $RebalanceDismissalModelCopyWith<$Res> {
  _$RebalanceDismissalModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RebalanceDismissalModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? familyId = freezed,
    Object? memberId = freezed,
    Object? suggestionHash = null,
    Object? fromAmfiCode = freezed,
    Object? toAmfiCode = freezed,
    Object? driftPct = freezed,
    Object? reason = freezed,
    Object? dismissedAt = null,
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
      suggestionHash: null == suggestionHash
          ? _value.suggestionHash
          : suggestionHash // ignore: cast_nullable_to_non_nullable
              as String,
      fromAmfiCode: freezed == fromAmfiCode
          ? _value.fromAmfiCode
          : fromAmfiCode // ignore: cast_nullable_to_non_nullable
              as int?,
      toAmfiCode: freezed == toAmfiCode
          ? _value.toAmfiCode
          : toAmfiCode // ignore: cast_nullable_to_non_nullable
              as int?,
      driftPct: freezed == driftPct
          ? _value.driftPct
          : driftPct // ignore: cast_nullable_to_non_nullable
              as double?,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      dismissedAt: null == dismissedAt
          ? _value.dismissedAt
          : dismissedAt // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RebalanceDismissalModelImplCopyWith<$Res>
    implements $RebalanceDismissalModelCopyWith<$Res> {
  factory _$$RebalanceDismissalModelImplCopyWith(
          _$RebalanceDismissalModelImpl value,
          $Res Function(_$RebalanceDismissalModelImpl) then) =
      __$$RebalanceDismissalModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'family_id') String? familyId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'suggestion_hash') String suggestionHash,
      @JsonKey(name: 'from_amfi_code') int? fromAmfiCode,
      @JsonKey(name: 'to_amfi_code') int? toAmfiCode,
      @JsonKey(name: 'drift_pct') double? driftPct,
      String? reason,
      @JsonKey(name: 'dismissed_at') String dismissedAt});
}

/// @nodoc
class __$$RebalanceDismissalModelImplCopyWithImpl<$Res>
    extends _$RebalanceDismissalModelCopyWithImpl<$Res,
        _$RebalanceDismissalModelImpl>
    implements _$$RebalanceDismissalModelImplCopyWith<$Res> {
  __$$RebalanceDismissalModelImplCopyWithImpl(
      _$RebalanceDismissalModelImpl _value,
      $Res Function(_$RebalanceDismissalModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of RebalanceDismissalModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? familyId = freezed,
    Object? memberId = freezed,
    Object? suggestionHash = null,
    Object? fromAmfiCode = freezed,
    Object? toAmfiCode = freezed,
    Object? driftPct = freezed,
    Object? reason = freezed,
    Object? dismissedAt = null,
  }) {
    return _then(_$RebalanceDismissalModelImpl(
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
      suggestionHash: null == suggestionHash
          ? _value.suggestionHash
          : suggestionHash // ignore: cast_nullable_to_non_nullable
              as String,
      fromAmfiCode: freezed == fromAmfiCode
          ? _value.fromAmfiCode
          : fromAmfiCode // ignore: cast_nullable_to_non_nullable
              as int?,
      toAmfiCode: freezed == toAmfiCode
          ? _value.toAmfiCode
          : toAmfiCode // ignore: cast_nullable_to_non_nullable
              as int?,
      driftPct: freezed == driftPct
          ? _value.driftPct
          : driftPct // ignore: cast_nullable_to_non_nullable
              as double?,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      dismissedAt: null == dismissedAt
          ? _value.dismissedAt
          : dismissedAt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RebalanceDismissalModelImpl implements _RebalanceDismissalModel {
  const _$RebalanceDismissalModelImpl(
      {required this.id,
      @JsonKey(name: 'owner_id') required this.ownerId,
      @JsonKey(name: 'family_id') this.familyId,
      @JsonKey(name: 'member_id') this.memberId,
      @JsonKey(name: 'suggestion_hash') required this.suggestionHash,
      @JsonKey(name: 'from_amfi_code') this.fromAmfiCode,
      @JsonKey(name: 'to_amfi_code') this.toAmfiCode,
      @JsonKey(name: 'drift_pct') this.driftPct,
      this.reason,
      @JsonKey(name: 'dismissed_at') required this.dismissedAt});

  factory _$RebalanceDismissalModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RebalanceDismissalModelImplFromJson(json);

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
  @JsonKey(name: 'suggestion_hash')
  final String suggestionHash;
  @override
  @JsonKey(name: 'from_amfi_code')
  final int? fromAmfiCode;
  @override
  @JsonKey(name: 'to_amfi_code')
  final int? toAmfiCode;
  @override
  @JsonKey(name: 'drift_pct')
  final double? driftPct;
  @override
  final String? reason;
  @override
  @JsonKey(name: 'dismissed_at')
  final String dismissedAt;

  @override
  String toString() {
    return 'RebalanceDismissalModel(id: $id, ownerId: $ownerId, familyId: $familyId, memberId: $memberId, suggestionHash: $suggestionHash, fromAmfiCode: $fromAmfiCode, toAmfiCode: $toAmfiCode, driftPct: $driftPct, reason: $reason, dismissedAt: $dismissedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RebalanceDismissalModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.suggestionHash, suggestionHash) ||
                other.suggestionHash == suggestionHash) &&
            (identical(other.fromAmfiCode, fromAmfiCode) ||
                other.fromAmfiCode == fromAmfiCode) &&
            (identical(other.toAmfiCode, toAmfiCode) ||
                other.toAmfiCode == toAmfiCode) &&
            (identical(other.driftPct, driftPct) ||
                other.driftPct == driftPct) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.dismissedAt, dismissedAt) ||
                other.dismissedAt == dismissedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, ownerId, familyId, memberId,
      suggestionHash, fromAmfiCode, toAmfiCode, driftPct, reason, dismissedAt);

  /// Create a copy of RebalanceDismissalModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RebalanceDismissalModelImplCopyWith<_$RebalanceDismissalModelImpl>
      get copyWith => __$$RebalanceDismissalModelImplCopyWithImpl<
          _$RebalanceDismissalModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RebalanceDismissalModelImplToJson(
      this,
    );
  }
}

abstract class _RebalanceDismissalModel implements RebalanceDismissalModel {
  const factory _RebalanceDismissalModel(
      {required final String id,
      @JsonKey(name: 'owner_id') required final String ownerId,
      @JsonKey(name: 'family_id') final String? familyId,
      @JsonKey(name: 'member_id') final String? memberId,
      @JsonKey(name: 'suggestion_hash') required final String suggestionHash,
      @JsonKey(name: 'from_amfi_code') final int? fromAmfiCode,
      @JsonKey(name: 'to_amfi_code') final int? toAmfiCode,
      @JsonKey(name: 'drift_pct') final double? driftPct,
      final String? reason,
      @JsonKey(name: 'dismissed_at')
      required final String dismissedAt}) = _$RebalanceDismissalModelImpl;

  factory _RebalanceDismissalModel.fromJson(Map<String, dynamic> json) =
      _$RebalanceDismissalModelImpl.fromJson;

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
  @JsonKey(name: 'suggestion_hash')
  String get suggestionHash;
  @override
  @JsonKey(name: 'from_amfi_code')
  int? get fromAmfiCode;
  @override
  @JsonKey(name: 'to_amfi_code')
  int? get toAmfiCode;
  @override
  @JsonKey(name: 'drift_pct')
  double? get driftPct;
  @override
  String? get reason;
  @override
  @JsonKey(name: 'dismissed_at')
  String get dismissedAt;

  /// Create a copy of RebalanceDismissalModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RebalanceDismissalModelImplCopyWith<_$RebalanceDismissalModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
