// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fund_alert_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FundAlertModel _$FundAlertModelFromJson(Map<String, dynamic> json) {
  return _FundAlertModel.fromJson(json);
}

/// @nodoc
mixin _$FundAlertModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'amfi_code')
  int get amfiCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'alert_type')
  String get alertType => throw _privateConstructorUsedError;
  @JsonKey(name: 'old_value')
  String? get oldValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'new_value')
  String? get newValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'detected_at')
  String get detectedAt => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this FundAlertModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FundAlertModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FundAlertModelCopyWith<FundAlertModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FundAlertModelCopyWith<$Res> {
  factory $FundAlertModelCopyWith(
          FundAlertModel value, $Res Function(FundAlertModel) then) =
      _$FundAlertModelCopyWithImpl<$Res, FundAlertModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'amfi_code') int amfiCode,
      @JsonKey(name: 'alert_type') String alertType,
      @JsonKey(name: 'old_value') String? oldValue,
      @JsonKey(name: 'new_value') String? newValue,
      @JsonKey(name: 'detected_at') String detectedAt,
      Map<String, dynamic>? metadata,
      @JsonKey(name: 'created_at') String? createdAt});
}

/// @nodoc
class _$FundAlertModelCopyWithImpl<$Res, $Val extends FundAlertModel>
    implements $FundAlertModelCopyWith<$Res> {
  _$FundAlertModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FundAlertModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? amfiCode = null,
    Object? alertType = null,
    Object? oldValue = freezed,
    Object? newValue = freezed,
    Object? detectedAt = null,
    Object? metadata = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      amfiCode: null == amfiCode
          ? _value.amfiCode
          : amfiCode // ignore: cast_nullable_to_non_nullable
              as int,
      alertType: null == alertType
          ? _value.alertType
          : alertType // ignore: cast_nullable_to_non_nullable
              as String,
      oldValue: freezed == oldValue
          ? _value.oldValue
          : oldValue // ignore: cast_nullable_to_non_nullable
              as String?,
      newValue: freezed == newValue
          ? _value.newValue
          : newValue // ignore: cast_nullable_to_non_nullable
              as String?,
      detectedAt: null == detectedAt
          ? _value.detectedAt
          : detectedAt // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FundAlertModelImplCopyWith<$Res>
    implements $FundAlertModelCopyWith<$Res> {
  factory _$$FundAlertModelImplCopyWith(_$FundAlertModelImpl value,
          $Res Function(_$FundAlertModelImpl) then) =
      __$$FundAlertModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'amfi_code') int amfiCode,
      @JsonKey(name: 'alert_type') String alertType,
      @JsonKey(name: 'old_value') String? oldValue,
      @JsonKey(name: 'new_value') String? newValue,
      @JsonKey(name: 'detected_at') String detectedAt,
      Map<String, dynamic>? metadata,
      @JsonKey(name: 'created_at') String? createdAt});
}

/// @nodoc
class __$$FundAlertModelImplCopyWithImpl<$Res>
    extends _$FundAlertModelCopyWithImpl<$Res, _$FundAlertModelImpl>
    implements _$$FundAlertModelImplCopyWith<$Res> {
  __$$FundAlertModelImplCopyWithImpl(
      _$FundAlertModelImpl _value, $Res Function(_$FundAlertModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of FundAlertModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? amfiCode = null,
    Object? alertType = null,
    Object? oldValue = freezed,
    Object? newValue = freezed,
    Object? detectedAt = null,
    Object? metadata = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$FundAlertModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      amfiCode: null == amfiCode
          ? _value.amfiCode
          : amfiCode // ignore: cast_nullable_to_non_nullable
              as int,
      alertType: null == alertType
          ? _value.alertType
          : alertType // ignore: cast_nullable_to_non_nullable
              as String,
      oldValue: freezed == oldValue
          ? _value.oldValue
          : oldValue // ignore: cast_nullable_to_non_nullable
              as String?,
      newValue: freezed == newValue
          ? _value.newValue
          : newValue // ignore: cast_nullable_to_non_nullable
              as String?,
      detectedAt: null == detectedAt
          ? _value.detectedAt
          : detectedAt // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
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
class _$FundAlertModelImpl extends _FundAlertModel {
  const _$FundAlertModelImpl(
      {required this.id,
      @JsonKey(name: 'amfi_code') required this.amfiCode,
      @JsonKey(name: 'alert_type') required this.alertType,
      @JsonKey(name: 'old_value') this.oldValue,
      @JsonKey(name: 'new_value') this.newValue,
      @JsonKey(name: 'detected_at') required this.detectedAt,
      final Map<String, dynamic>? metadata,
      @JsonKey(name: 'created_at') this.createdAt})
      : _metadata = metadata,
        super._();

  factory _$FundAlertModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FundAlertModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'amfi_code')
  final int amfiCode;
  @override
  @JsonKey(name: 'alert_type')
  final String alertType;
  @override
  @JsonKey(name: 'old_value')
  final String? oldValue;
  @override
  @JsonKey(name: 'new_value')
  final String? newValue;
  @override
  @JsonKey(name: 'detected_at')
  final String detectedAt;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @override
  String toString() {
    return 'FundAlertModel(id: $id, amfiCode: $amfiCode, alertType: $alertType, oldValue: $oldValue, newValue: $newValue, detectedAt: $detectedAt, metadata: $metadata, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FundAlertModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.amfiCode, amfiCode) ||
                other.amfiCode == amfiCode) &&
            (identical(other.alertType, alertType) ||
                other.alertType == alertType) &&
            (identical(other.oldValue, oldValue) ||
                other.oldValue == oldValue) &&
            (identical(other.newValue, newValue) ||
                other.newValue == newValue) &&
            (identical(other.detectedAt, detectedAt) ||
                other.detectedAt == detectedAt) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      amfiCode,
      alertType,
      oldValue,
      newValue,
      detectedAt,
      const DeepCollectionEquality().hash(_metadata),
      createdAt);

  /// Create a copy of FundAlertModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FundAlertModelImplCopyWith<_$FundAlertModelImpl> get copyWith =>
      __$$FundAlertModelImplCopyWithImpl<_$FundAlertModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FundAlertModelImplToJson(
      this,
    );
  }
}

abstract class _FundAlertModel extends FundAlertModel {
  const factory _FundAlertModel(
          {required final String id,
          @JsonKey(name: 'amfi_code') required final int amfiCode,
          @JsonKey(name: 'alert_type') required final String alertType,
          @JsonKey(name: 'old_value') final String? oldValue,
          @JsonKey(name: 'new_value') final String? newValue,
          @JsonKey(name: 'detected_at') required final String detectedAt,
          final Map<String, dynamic>? metadata,
          @JsonKey(name: 'created_at') final String? createdAt}) =
      _$FundAlertModelImpl;
  const _FundAlertModel._() : super._();

  factory _FundAlertModel.fromJson(Map<String, dynamic> json) =
      _$FundAlertModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'amfi_code')
  int get amfiCode;
  @override
  @JsonKey(name: 'alert_type')
  String get alertType;
  @override
  @JsonKey(name: 'old_value')
  String? get oldValue;
  @override
  @JsonKey(name: 'new_value')
  String? get newValue;
  @override
  @JsonKey(name: 'detected_at')
  String get detectedAt;
  @override
  Map<String, dynamic>? get metadata;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;

  /// Create a copy of FundAlertModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FundAlertModelImplCopyWith<_$FundAlertModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
