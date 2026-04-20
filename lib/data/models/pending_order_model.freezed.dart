// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_order_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PendingOrderModel _$PendingOrderModelFromJson(Map<String, dynamic> json) {
  return _PendingOrderModel.fromJson(json);
}

/// @nodoc
mixin _$PendingOrderModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'owner_id')
  String get ownerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'family_id')
  String? get familyId => throw _privateConstructorUsedError;
  @JsonKey(name: 'member_id')
  String? get memberId => throw _privateConstructorUsedError;
  @JsonKey(name: 'amfi_code')
  int? get amfiCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'fund_name')
  String get fundName => throw _privateConstructorUsedError;
  @JsonKey(name: 'asset_type')
  String get assetType => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_kind')
  String get orderKind => throw _privateConstructorUsedError;
  @JsonKey(name: 'switch_to_amfi')
  int? get switchToAmfi => throw _privateConstructorUsedError;
  double? get amount => throw _privateConstructorUsedError;
  double? get units => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  @JsonKey(name: 'source_ref')
  String? get sourceRef => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'executed_at')
  String? get executedAt => throw _privateConstructorUsedError;

  /// Serializes this PendingOrderModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PendingOrderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PendingOrderModelCopyWith<PendingOrderModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PendingOrderModelCopyWith<$Res> {
  factory $PendingOrderModelCopyWith(
          PendingOrderModel value, $Res Function(PendingOrderModel) then) =
      _$PendingOrderModelCopyWithImpl<$Res, PendingOrderModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'family_id') String? familyId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'amfi_code') int? amfiCode,
      @JsonKey(name: 'fund_name') String fundName,
      @JsonKey(name: 'asset_type') String assetType,
      @JsonKey(name: 'order_kind') String orderKind,
      @JsonKey(name: 'switch_to_amfi') int? switchToAmfi,
      double? amount,
      double? units,
      String status,
      String source,
      @JsonKey(name: 'source_ref') String? sourceRef,
      String? notes,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'executed_at') String? executedAt});
}

/// @nodoc
class _$PendingOrderModelCopyWithImpl<$Res, $Val extends PendingOrderModel>
    implements $PendingOrderModelCopyWith<$Res> {
  _$PendingOrderModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PendingOrderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? familyId = freezed,
    Object? memberId = freezed,
    Object? amfiCode = freezed,
    Object? fundName = null,
    Object? assetType = null,
    Object? orderKind = null,
    Object? switchToAmfi = freezed,
    Object? amount = freezed,
    Object? units = freezed,
    Object? status = null,
    Object? source = null,
    Object? sourceRef = freezed,
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
      amfiCode: freezed == amfiCode
          ? _value.amfiCode
          : amfiCode // ignore: cast_nullable_to_non_nullable
              as int?,
      fundName: null == fundName
          ? _value.fundName
          : fundName // ignore: cast_nullable_to_non_nullable
              as String,
      assetType: null == assetType
          ? _value.assetType
          : assetType // ignore: cast_nullable_to_non_nullable
              as String,
      orderKind: null == orderKind
          ? _value.orderKind
          : orderKind // ignore: cast_nullable_to_non_nullable
              as String,
      switchToAmfi: freezed == switchToAmfi
          ? _value.switchToAmfi
          : switchToAmfi // ignore: cast_nullable_to_non_nullable
              as int?,
      amount: freezed == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double?,
      units: freezed == units
          ? _value.units
          : units // ignore: cast_nullable_to_non_nullable
              as double?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      sourceRef: freezed == sourceRef
          ? _value.sourceRef
          : sourceRef // ignore: cast_nullable_to_non_nullable
              as String?,
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
abstract class _$$PendingOrderModelImplCopyWith<$Res>
    implements $PendingOrderModelCopyWith<$Res> {
  factory _$$PendingOrderModelImplCopyWith(_$PendingOrderModelImpl value,
          $Res Function(_$PendingOrderModelImpl) then) =
      __$$PendingOrderModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'family_id') String? familyId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'amfi_code') int? amfiCode,
      @JsonKey(name: 'fund_name') String fundName,
      @JsonKey(name: 'asset_type') String assetType,
      @JsonKey(name: 'order_kind') String orderKind,
      @JsonKey(name: 'switch_to_amfi') int? switchToAmfi,
      double? amount,
      double? units,
      String status,
      String source,
      @JsonKey(name: 'source_ref') String? sourceRef,
      String? notes,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'executed_at') String? executedAt});
}

/// @nodoc
class __$$PendingOrderModelImplCopyWithImpl<$Res>
    extends _$PendingOrderModelCopyWithImpl<$Res, _$PendingOrderModelImpl>
    implements _$$PendingOrderModelImplCopyWith<$Res> {
  __$$PendingOrderModelImplCopyWithImpl(_$PendingOrderModelImpl _value,
      $Res Function(_$PendingOrderModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PendingOrderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? familyId = freezed,
    Object? memberId = freezed,
    Object? amfiCode = freezed,
    Object? fundName = null,
    Object? assetType = null,
    Object? orderKind = null,
    Object? switchToAmfi = freezed,
    Object? amount = freezed,
    Object? units = freezed,
    Object? status = null,
    Object? source = null,
    Object? sourceRef = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? executedAt = freezed,
  }) {
    return _then(_$PendingOrderModelImpl(
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
      amfiCode: freezed == amfiCode
          ? _value.amfiCode
          : amfiCode // ignore: cast_nullable_to_non_nullable
              as int?,
      fundName: null == fundName
          ? _value.fundName
          : fundName // ignore: cast_nullable_to_non_nullable
              as String,
      assetType: null == assetType
          ? _value.assetType
          : assetType // ignore: cast_nullable_to_non_nullable
              as String,
      orderKind: null == orderKind
          ? _value.orderKind
          : orderKind // ignore: cast_nullable_to_non_nullable
              as String,
      switchToAmfi: freezed == switchToAmfi
          ? _value.switchToAmfi
          : switchToAmfi // ignore: cast_nullable_to_non_nullable
              as int?,
      amount: freezed == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double?,
      units: freezed == units
          ? _value.units
          : units // ignore: cast_nullable_to_non_nullable
              as double?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      sourceRef: freezed == sourceRef
          ? _value.sourceRef
          : sourceRef // ignore: cast_nullable_to_non_nullable
              as String?,
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
class _$PendingOrderModelImpl implements _PendingOrderModel {
  const _$PendingOrderModelImpl(
      {required this.id,
      @JsonKey(name: 'owner_id') required this.ownerId,
      @JsonKey(name: 'family_id') this.familyId,
      @JsonKey(name: 'member_id') this.memberId,
      @JsonKey(name: 'amfi_code') this.amfiCode,
      @JsonKey(name: 'fund_name') required this.fundName,
      @JsonKey(name: 'asset_type') this.assetType = 'MF',
      @JsonKey(name: 'order_kind') required this.orderKind,
      @JsonKey(name: 'switch_to_amfi') this.switchToAmfi,
      this.amount,
      this.units,
      this.status = 'placed',
      this.source = 'manual',
      @JsonKey(name: 'source_ref') this.sourceRef,
      this.notes,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'executed_at') this.executedAt});

  factory _$PendingOrderModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PendingOrderModelImplFromJson(json);

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
  @JsonKey(name: 'amfi_code')
  final int? amfiCode;
  @override
  @JsonKey(name: 'fund_name')
  final String fundName;
  @override
  @JsonKey(name: 'asset_type')
  final String assetType;
  @override
  @JsonKey(name: 'order_kind')
  final String orderKind;
  @override
  @JsonKey(name: 'switch_to_amfi')
  final int? switchToAmfi;
  @override
  final double? amount;
  @override
  final double? units;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final String source;
  @override
  @JsonKey(name: 'source_ref')
  final String? sourceRef;
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
    return 'PendingOrderModel(id: $id, ownerId: $ownerId, familyId: $familyId, memberId: $memberId, amfiCode: $amfiCode, fundName: $fundName, assetType: $assetType, orderKind: $orderKind, switchToAmfi: $switchToAmfi, amount: $amount, units: $units, status: $status, source: $source, sourceRef: $sourceRef, notes: $notes, createdAt: $createdAt, executedAt: $executedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PendingOrderModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.amfiCode, amfiCode) ||
                other.amfiCode == amfiCode) &&
            (identical(other.fundName, fundName) ||
                other.fundName == fundName) &&
            (identical(other.assetType, assetType) ||
                other.assetType == assetType) &&
            (identical(other.orderKind, orderKind) ||
                other.orderKind == orderKind) &&
            (identical(other.switchToAmfi, switchToAmfi) ||
                other.switchToAmfi == switchToAmfi) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.units, units) || other.units == units) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.sourceRef, sourceRef) ||
                other.sourceRef == sourceRef) &&
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
      amfiCode,
      fundName,
      assetType,
      orderKind,
      switchToAmfi,
      amount,
      units,
      status,
      source,
      sourceRef,
      notes,
      createdAt,
      executedAt);

  /// Create a copy of PendingOrderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PendingOrderModelImplCopyWith<_$PendingOrderModelImpl> get copyWith =>
      __$$PendingOrderModelImplCopyWithImpl<_$PendingOrderModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PendingOrderModelImplToJson(
      this,
    );
  }
}

abstract class _PendingOrderModel implements PendingOrderModel {
  const factory _PendingOrderModel(
          {required final String id,
          @JsonKey(name: 'owner_id') required final String ownerId,
          @JsonKey(name: 'family_id') final String? familyId,
          @JsonKey(name: 'member_id') final String? memberId,
          @JsonKey(name: 'amfi_code') final int? amfiCode,
          @JsonKey(name: 'fund_name') required final String fundName,
          @JsonKey(name: 'asset_type') final String assetType,
          @JsonKey(name: 'order_kind') required final String orderKind,
          @JsonKey(name: 'switch_to_amfi') final int? switchToAmfi,
          final double? amount,
          final double? units,
          final String status,
          final String source,
          @JsonKey(name: 'source_ref') final String? sourceRef,
          final String? notes,
          @JsonKey(name: 'created_at') required final String createdAt,
          @JsonKey(name: 'executed_at') final String? executedAt}) =
      _$PendingOrderModelImpl;

  factory _PendingOrderModel.fromJson(Map<String, dynamic> json) =
      _$PendingOrderModelImpl.fromJson;

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
  @JsonKey(name: 'amfi_code')
  int? get amfiCode;
  @override
  @JsonKey(name: 'fund_name')
  String get fundName;
  @override
  @JsonKey(name: 'asset_type')
  String get assetType;
  @override
  @JsonKey(name: 'order_kind')
  String get orderKind;
  @override
  @JsonKey(name: 'switch_to_amfi')
  int? get switchToAmfi;
  @override
  double? get amount;
  @override
  double? get units;
  @override
  String get status;
  @override
  String get source;
  @override
  @JsonKey(name: 'source_ref')
  String? get sourceRef;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  @JsonKey(name: 'executed_at')
  String? get executedAt;

  /// Create a copy of PendingOrderModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PendingOrderModelImplCopyWith<_$PendingOrderModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
