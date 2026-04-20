// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'watchlist_rule_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WatchlistRuleModel _$WatchlistRuleModelFromJson(Map<String, dynamic> json) {
  return _WatchlistRuleModel.fromJson(json);
}

/// @nodoc
mixin _$WatchlistRuleModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'owner_id')
  String get ownerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'member_id')
  String? get memberId => throw _privateConstructorUsedError;
  @JsonKey(name: 'amfi_code')
  int? get amfiCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'fund_name')
  String? get fundName => throw _privateConstructorUsedError;
  @JsonKey(name: 'rule_type')
  String get ruleType => throw _privateConstructorUsedError;
  @JsonKey(name: 'threshold_type')
  String get thresholdType => throw _privateConstructorUsedError;
  @JsonKey(name: 'threshold_value')
  double get thresholdValue => throw _privateConstructorUsedError;
  String get direction => throw _privateConstructorUsedError;
  @JsonKey(name: 'asset_class_key')
  String? get assetClassKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_triggered_at')
  String? get lastTriggeredAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'cooldown_hours')
  int get cooldownHours => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this WatchlistRuleModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WatchlistRuleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WatchlistRuleModelCopyWith<WatchlistRuleModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WatchlistRuleModelCopyWith<$Res> {
  factory $WatchlistRuleModelCopyWith(
          WatchlistRuleModel value, $Res Function(WatchlistRuleModel) then) =
      _$WatchlistRuleModelCopyWithImpl<$Res, WatchlistRuleModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'amfi_code') int? amfiCode,
      @JsonKey(name: 'fund_name') String? fundName,
      @JsonKey(name: 'rule_type') String ruleType,
      @JsonKey(name: 'threshold_type') String thresholdType,
      @JsonKey(name: 'threshold_value') double thresholdValue,
      String direction,
      @JsonKey(name: 'asset_class_key') String? assetClassKey,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'last_triggered_at') String? lastTriggeredAt,
      @JsonKey(name: 'cooldown_hours') int cooldownHours,
      String? note,
      @JsonKey(name: 'created_at') String? createdAt});
}

/// @nodoc
class _$WatchlistRuleModelCopyWithImpl<$Res, $Val extends WatchlistRuleModel>
    implements $WatchlistRuleModelCopyWith<$Res> {
  _$WatchlistRuleModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WatchlistRuleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? memberId = freezed,
    Object? amfiCode = freezed,
    Object? fundName = freezed,
    Object? ruleType = null,
    Object? thresholdType = null,
    Object? thresholdValue = null,
    Object? direction = null,
    Object? assetClassKey = freezed,
    Object? isActive = null,
    Object? lastTriggeredAt = freezed,
    Object? cooldownHours = null,
    Object? note = freezed,
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
      memberId: freezed == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String?,
      amfiCode: freezed == amfiCode
          ? _value.amfiCode
          : amfiCode // ignore: cast_nullable_to_non_nullable
              as int?,
      fundName: freezed == fundName
          ? _value.fundName
          : fundName // ignore: cast_nullable_to_non_nullable
              as String?,
      ruleType: null == ruleType
          ? _value.ruleType
          : ruleType // ignore: cast_nullable_to_non_nullable
              as String,
      thresholdType: null == thresholdType
          ? _value.thresholdType
          : thresholdType // ignore: cast_nullable_to_non_nullable
              as String,
      thresholdValue: null == thresholdValue
          ? _value.thresholdValue
          : thresholdValue // ignore: cast_nullable_to_non_nullable
              as double,
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as String,
      assetClassKey: freezed == assetClassKey
          ? _value.assetClassKey
          : assetClassKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      lastTriggeredAt: freezed == lastTriggeredAt
          ? _value.lastTriggeredAt
          : lastTriggeredAt // ignore: cast_nullable_to_non_nullable
              as String?,
      cooldownHours: null == cooldownHours
          ? _value.cooldownHours
          : cooldownHours // ignore: cast_nullable_to_non_nullable
              as int,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WatchlistRuleModelImplCopyWith<$Res>
    implements $WatchlistRuleModelCopyWith<$Res> {
  factory _$$WatchlistRuleModelImplCopyWith(_$WatchlistRuleModelImpl value,
          $Res Function(_$WatchlistRuleModelImpl) then) =
      __$$WatchlistRuleModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'amfi_code') int? amfiCode,
      @JsonKey(name: 'fund_name') String? fundName,
      @JsonKey(name: 'rule_type') String ruleType,
      @JsonKey(name: 'threshold_type') String thresholdType,
      @JsonKey(name: 'threshold_value') double thresholdValue,
      String direction,
      @JsonKey(name: 'asset_class_key') String? assetClassKey,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'last_triggered_at') String? lastTriggeredAt,
      @JsonKey(name: 'cooldown_hours') int cooldownHours,
      String? note,
      @JsonKey(name: 'created_at') String? createdAt});
}

/// @nodoc
class __$$WatchlistRuleModelImplCopyWithImpl<$Res>
    extends _$WatchlistRuleModelCopyWithImpl<$Res, _$WatchlistRuleModelImpl>
    implements _$$WatchlistRuleModelImplCopyWith<$Res> {
  __$$WatchlistRuleModelImplCopyWithImpl(_$WatchlistRuleModelImpl _value,
      $Res Function(_$WatchlistRuleModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of WatchlistRuleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? memberId = freezed,
    Object? amfiCode = freezed,
    Object? fundName = freezed,
    Object? ruleType = null,
    Object? thresholdType = null,
    Object? thresholdValue = null,
    Object? direction = null,
    Object? assetClassKey = freezed,
    Object? isActive = null,
    Object? lastTriggeredAt = freezed,
    Object? cooldownHours = null,
    Object? note = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$WatchlistRuleModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      memberId: freezed == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String?,
      amfiCode: freezed == amfiCode
          ? _value.amfiCode
          : amfiCode // ignore: cast_nullable_to_non_nullable
              as int?,
      fundName: freezed == fundName
          ? _value.fundName
          : fundName // ignore: cast_nullable_to_non_nullable
              as String?,
      ruleType: null == ruleType
          ? _value.ruleType
          : ruleType // ignore: cast_nullable_to_non_nullable
              as String,
      thresholdType: null == thresholdType
          ? _value.thresholdType
          : thresholdType // ignore: cast_nullable_to_non_nullable
              as String,
      thresholdValue: null == thresholdValue
          ? _value.thresholdValue
          : thresholdValue // ignore: cast_nullable_to_non_nullable
              as double,
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as String,
      assetClassKey: freezed == assetClassKey
          ? _value.assetClassKey
          : assetClassKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      lastTriggeredAt: freezed == lastTriggeredAt
          ? _value.lastTriggeredAt
          : lastTriggeredAt // ignore: cast_nullable_to_non_nullable
              as String?,
      cooldownHours: null == cooldownHours
          ? _value.cooldownHours
          : cooldownHours // ignore: cast_nullable_to_non_nullable
              as int,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WatchlistRuleModelImpl extends _WatchlistRuleModel {
  const _$WatchlistRuleModelImpl(
      {required this.id,
      @JsonKey(name: 'owner_id') required this.ownerId,
      @JsonKey(name: 'member_id') this.memberId,
      @JsonKey(name: 'amfi_code') this.amfiCode,
      @JsonKey(name: 'fund_name') this.fundName,
      @JsonKey(name: 'rule_type') required this.ruleType,
      @JsonKey(name: 'threshold_type') required this.thresholdType,
      @JsonKey(name: 'threshold_value') required this.thresholdValue,
      this.direction = 'below',
      @JsonKey(name: 'asset_class_key') this.assetClassKey,
      @JsonKey(name: 'is_active') this.isActive = true,
      @JsonKey(name: 'last_triggered_at') this.lastTriggeredAt,
      @JsonKey(name: 'cooldown_hours') this.cooldownHours = 24,
      this.note,
      @JsonKey(name: 'created_at') this.createdAt})
      : super._();

  factory _$WatchlistRuleModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$WatchlistRuleModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @override
  @JsonKey(name: 'member_id')
  final String? memberId;
  @override
  @JsonKey(name: 'amfi_code')
  final int? amfiCode;
  @override
  @JsonKey(name: 'fund_name')
  final String? fundName;
  @override
  @JsonKey(name: 'rule_type')
  final String ruleType;
  @override
  @JsonKey(name: 'threshold_type')
  final String thresholdType;
  @override
  @JsonKey(name: 'threshold_value')
  final double thresholdValue;
  @override
  @JsonKey()
  final String direction;
  @override
  @JsonKey(name: 'asset_class_key')
  final String? assetClassKey;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  @override
  @JsonKey(name: 'last_triggered_at')
  final String? lastTriggeredAt;
  @override
  @JsonKey(name: 'cooldown_hours')
  final int cooldownHours;
  @override
  final String? note;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @override
  String toString() {
    return 'WatchlistRuleModel(id: $id, ownerId: $ownerId, memberId: $memberId, amfiCode: $amfiCode, fundName: $fundName, ruleType: $ruleType, thresholdType: $thresholdType, thresholdValue: $thresholdValue, direction: $direction, assetClassKey: $assetClassKey, isActive: $isActive, lastTriggeredAt: $lastTriggeredAt, cooldownHours: $cooldownHours, note: $note, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WatchlistRuleModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.amfiCode, amfiCode) ||
                other.amfiCode == amfiCode) &&
            (identical(other.fundName, fundName) ||
                other.fundName == fundName) &&
            (identical(other.ruleType, ruleType) ||
                other.ruleType == ruleType) &&
            (identical(other.thresholdType, thresholdType) ||
                other.thresholdType == thresholdType) &&
            (identical(other.thresholdValue, thresholdValue) ||
                other.thresholdValue == thresholdValue) &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.assetClassKey, assetClassKey) ||
                other.assetClassKey == assetClassKey) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.lastTriggeredAt, lastTriggeredAt) ||
                other.lastTriggeredAt == lastTriggeredAt) &&
            (identical(other.cooldownHours, cooldownHours) ||
                other.cooldownHours == cooldownHours) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      ownerId,
      memberId,
      amfiCode,
      fundName,
      ruleType,
      thresholdType,
      thresholdValue,
      direction,
      assetClassKey,
      isActive,
      lastTriggeredAt,
      cooldownHours,
      note,
      createdAt);

  /// Create a copy of WatchlistRuleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WatchlistRuleModelImplCopyWith<_$WatchlistRuleModelImpl> get copyWith =>
      __$$WatchlistRuleModelImplCopyWithImpl<_$WatchlistRuleModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WatchlistRuleModelImplToJson(
      this,
    );
  }
}

abstract class _WatchlistRuleModel extends WatchlistRuleModel {
  const factory _WatchlistRuleModel(
      {required final String id,
      @JsonKey(name: 'owner_id') required final String ownerId,
      @JsonKey(name: 'member_id') final String? memberId,
      @JsonKey(name: 'amfi_code') final int? amfiCode,
      @JsonKey(name: 'fund_name') final String? fundName,
      @JsonKey(name: 'rule_type') required final String ruleType,
      @JsonKey(name: 'threshold_type') required final String thresholdType,
      @JsonKey(name: 'threshold_value') required final double thresholdValue,
      final String direction,
      @JsonKey(name: 'asset_class_key') final String? assetClassKey,
      @JsonKey(name: 'is_active') final bool isActive,
      @JsonKey(name: 'last_triggered_at') final String? lastTriggeredAt,
      @JsonKey(name: 'cooldown_hours') final int cooldownHours,
      final String? note,
      @JsonKey(name: 'created_at')
      final String? createdAt}) = _$WatchlistRuleModelImpl;
  const _WatchlistRuleModel._() : super._();

  factory _WatchlistRuleModel.fromJson(Map<String, dynamic> json) =
      _$WatchlistRuleModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'owner_id')
  String get ownerId;
  @override
  @JsonKey(name: 'member_id')
  String? get memberId;
  @override
  @JsonKey(name: 'amfi_code')
  int? get amfiCode;
  @override
  @JsonKey(name: 'fund_name')
  String? get fundName;
  @override
  @JsonKey(name: 'rule_type')
  String get ruleType;
  @override
  @JsonKey(name: 'threshold_type')
  String get thresholdType;
  @override
  @JsonKey(name: 'threshold_value')
  double get thresholdValue;
  @override
  String get direction;
  @override
  @JsonKey(name: 'asset_class_key')
  String? get assetClassKey;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;
  @override
  @JsonKey(name: 'last_triggered_at')
  String? get lastTriggeredAt;
  @override
  @JsonKey(name: 'cooldown_hours')
  int get cooldownHours;
  @override
  String? get note;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;

  /// Create a copy of WatchlistRuleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WatchlistRuleModelImplCopyWith<_$WatchlistRuleModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
