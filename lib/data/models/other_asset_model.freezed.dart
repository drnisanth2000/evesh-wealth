// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'other_asset_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OtherAssetModel _$OtherAssetModelFromJson(Map<String, dynamic> json) {
  return _OtherAssetModel.fromJson(json);
}

/// @nodoc
mixin _$OtherAssetModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'owner_id')
  String get ownerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'family_id')
  String? get familyId => throw _privateConstructorUsedError;
  @JsonKey(name: 'member_id')
  String? get memberId => throw _privateConstructorUsedError;
  @JsonKey(name: 'asset_type')
  String get assetType => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'isin_symbol')
  String? get isinSymbol => throw _privateConstructorUsedError;
  double? get quantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'cost_value')
  double? get costValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_value')
  double? get currentValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_price')
  double? get currentPrice => throw _privateConstructorUsedError;
  @JsonKey(name: 'interest_rate')
  double? get interestRate => throw _privateConstructorUsedError;
  @JsonKey(name: 'interest_frequency')
  String? get interestFrequency => throw _privateConstructorUsedError;
  @JsonKey(name: 'accrued_interest')
  double? get accruedInterest => throw _privateConstructorUsedError;
  @JsonKey(name: 'tax_category')
  String? get taxCategory => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_date')
  String? get startDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'maturity_date')
  String? get maturityDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'lock_in_end_date')
  String? get lockInEndDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_valuation_date')
  String? get lastValuationDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'broker_or_institution')
  String? get brokerOrInstitution => throw _privateConstructorUsedError;
  @JsonKey(name: 'account_number')
  String? get accountNumber => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'bucket_override')
  String? get bucketOverride => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_updated_at')
  String? get lastUpdatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this OtherAssetModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OtherAssetModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OtherAssetModelCopyWith<OtherAssetModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OtherAssetModelCopyWith<$Res> {
  factory $OtherAssetModelCopyWith(
          OtherAssetModel value, $Res Function(OtherAssetModel) then) =
      _$OtherAssetModelCopyWithImpl<$Res, OtherAssetModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'family_id') String? familyId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'asset_type') String assetType,
      String description,
      @JsonKey(name: 'isin_symbol') String? isinSymbol,
      double? quantity,
      @JsonKey(name: 'cost_value') double? costValue,
      @JsonKey(name: 'current_value') double? currentValue,
      @JsonKey(name: 'current_price') double? currentPrice,
      @JsonKey(name: 'interest_rate') double? interestRate,
      @JsonKey(name: 'interest_frequency') String? interestFrequency,
      @JsonKey(name: 'accrued_interest') double? accruedInterest,
      @JsonKey(name: 'tax_category') String? taxCategory,
      @JsonKey(name: 'start_date') String? startDate,
      @JsonKey(name: 'maturity_date') String? maturityDate,
      @JsonKey(name: 'lock_in_end_date') String? lockInEndDate,
      @JsonKey(name: 'last_valuation_date') String? lastValuationDate,
      @JsonKey(name: 'broker_or_institution') String? brokerOrInstitution,
      @JsonKey(name: 'account_number') String? accountNumber,
      String? notes,
      @JsonKey(name: 'bucket_override') String? bucketOverride,
      @JsonKey(name: 'last_updated_at') String? lastUpdatedAt,
      @JsonKey(name: 'created_at') String createdAt});
}

/// @nodoc
class _$OtherAssetModelCopyWithImpl<$Res, $Val extends OtherAssetModel>
    implements $OtherAssetModelCopyWith<$Res> {
  _$OtherAssetModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OtherAssetModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? familyId = freezed,
    Object? memberId = freezed,
    Object? assetType = null,
    Object? description = null,
    Object? isinSymbol = freezed,
    Object? quantity = freezed,
    Object? costValue = freezed,
    Object? currentValue = freezed,
    Object? currentPrice = freezed,
    Object? interestRate = freezed,
    Object? interestFrequency = freezed,
    Object? accruedInterest = freezed,
    Object? taxCategory = freezed,
    Object? startDate = freezed,
    Object? maturityDate = freezed,
    Object? lockInEndDate = freezed,
    Object? lastValuationDate = freezed,
    Object? brokerOrInstitution = freezed,
    Object? accountNumber = freezed,
    Object? notes = freezed,
    Object? bucketOverride = freezed,
    Object? lastUpdatedAt = freezed,
    Object? createdAt = null,
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
      assetType: null == assetType
          ? _value.assetType
          : assetType // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      isinSymbol: freezed == isinSymbol
          ? _value.isinSymbol
          : isinSymbol // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: freezed == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      costValue: freezed == costValue
          ? _value.costValue
          : costValue // ignore: cast_nullable_to_non_nullable
              as double?,
      currentValue: freezed == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double?,
      currentPrice: freezed == currentPrice
          ? _value.currentPrice
          : currentPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      interestRate: freezed == interestRate
          ? _value.interestRate
          : interestRate // ignore: cast_nullable_to_non_nullable
              as double?,
      interestFrequency: freezed == interestFrequency
          ? _value.interestFrequency
          : interestFrequency // ignore: cast_nullable_to_non_nullable
              as String?,
      accruedInterest: freezed == accruedInterest
          ? _value.accruedInterest
          : accruedInterest // ignore: cast_nullable_to_non_nullable
              as double?,
      taxCategory: freezed == taxCategory
          ? _value.taxCategory
          : taxCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as String?,
      maturityDate: freezed == maturityDate
          ? _value.maturityDate
          : maturityDate // ignore: cast_nullable_to_non_nullable
              as String?,
      lockInEndDate: freezed == lockInEndDate
          ? _value.lockInEndDate
          : lockInEndDate // ignore: cast_nullable_to_non_nullable
              as String?,
      lastValuationDate: freezed == lastValuationDate
          ? _value.lastValuationDate
          : lastValuationDate // ignore: cast_nullable_to_non_nullable
              as String?,
      brokerOrInstitution: freezed == brokerOrInstitution
          ? _value.brokerOrInstitution
          : brokerOrInstitution // ignore: cast_nullable_to_non_nullable
              as String?,
      accountNumber: freezed == accountNumber
          ? _value.accountNumber
          : accountNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      bucketOverride: freezed == bucketOverride
          ? _value.bucketOverride
          : bucketOverride // ignore: cast_nullable_to_non_nullable
              as String?,
      lastUpdatedAt: freezed == lastUpdatedAt
          ? _value.lastUpdatedAt
          : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OtherAssetModelImplCopyWith<$Res>
    implements $OtherAssetModelCopyWith<$Res> {
  factory _$$OtherAssetModelImplCopyWith(_$OtherAssetModelImpl value,
          $Res Function(_$OtherAssetModelImpl) then) =
      __$$OtherAssetModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'family_id') String? familyId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'asset_type') String assetType,
      String description,
      @JsonKey(name: 'isin_symbol') String? isinSymbol,
      double? quantity,
      @JsonKey(name: 'cost_value') double? costValue,
      @JsonKey(name: 'current_value') double? currentValue,
      @JsonKey(name: 'current_price') double? currentPrice,
      @JsonKey(name: 'interest_rate') double? interestRate,
      @JsonKey(name: 'interest_frequency') String? interestFrequency,
      @JsonKey(name: 'accrued_interest') double? accruedInterest,
      @JsonKey(name: 'tax_category') String? taxCategory,
      @JsonKey(name: 'start_date') String? startDate,
      @JsonKey(name: 'maturity_date') String? maturityDate,
      @JsonKey(name: 'lock_in_end_date') String? lockInEndDate,
      @JsonKey(name: 'last_valuation_date') String? lastValuationDate,
      @JsonKey(name: 'broker_or_institution') String? brokerOrInstitution,
      @JsonKey(name: 'account_number') String? accountNumber,
      String? notes,
      @JsonKey(name: 'bucket_override') String? bucketOverride,
      @JsonKey(name: 'last_updated_at') String? lastUpdatedAt,
      @JsonKey(name: 'created_at') String createdAt});
}

/// @nodoc
class __$$OtherAssetModelImplCopyWithImpl<$Res>
    extends _$OtherAssetModelCopyWithImpl<$Res, _$OtherAssetModelImpl>
    implements _$$OtherAssetModelImplCopyWith<$Res> {
  __$$OtherAssetModelImplCopyWithImpl(
      _$OtherAssetModelImpl _value, $Res Function(_$OtherAssetModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of OtherAssetModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? familyId = freezed,
    Object? memberId = freezed,
    Object? assetType = null,
    Object? description = null,
    Object? isinSymbol = freezed,
    Object? quantity = freezed,
    Object? costValue = freezed,
    Object? currentValue = freezed,
    Object? currentPrice = freezed,
    Object? interestRate = freezed,
    Object? interestFrequency = freezed,
    Object? accruedInterest = freezed,
    Object? taxCategory = freezed,
    Object? startDate = freezed,
    Object? maturityDate = freezed,
    Object? lockInEndDate = freezed,
    Object? lastValuationDate = freezed,
    Object? brokerOrInstitution = freezed,
    Object? accountNumber = freezed,
    Object? notes = freezed,
    Object? bucketOverride = freezed,
    Object? lastUpdatedAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$OtherAssetModelImpl(
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
      assetType: null == assetType
          ? _value.assetType
          : assetType // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      isinSymbol: freezed == isinSymbol
          ? _value.isinSymbol
          : isinSymbol // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: freezed == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      costValue: freezed == costValue
          ? _value.costValue
          : costValue // ignore: cast_nullable_to_non_nullable
              as double?,
      currentValue: freezed == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double?,
      currentPrice: freezed == currentPrice
          ? _value.currentPrice
          : currentPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      interestRate: freezed == interestRate
          ? _value.interestRate
          : interestRate // ignore: cast_nullable_to_non_nullable
              as double?,
      interestFrequency: freezed == interestFrequency
          ? _value.interestFrequency
          : interestFrequency // ignore: cast_nullable_to_non_nullable
              as String?,
      accruedInterest: freezed == accruedInterest
          ? _value.accruedInterest
          : accruedInterest // ignore: cast_nullable_to_non_nullable
              as double?,
      taxCategory: freezed == taxCategory
          ? _value.taxCategory
          : taxCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as String?,
      maturityDate: freezed == maturityDate
          ? _value.maturityDate
          : maturityDate // ignore: cast_nullable_to_non_nullable
              as String?,
      lockInEndDate: freezed == lockInEndDate
          ? _value.lockInEndDate
          : lockInEndDate // ignore: cast_nullable_to_non_nullable
              as String?,
      lastValuationDate: freezed == lastValuationDate
          ? _value.lastValuationDate
          : lastValuationDate // ignore: cast_nullable_to_non_nullable
              as String?,
      brokerOrInstitution: freezed == brokerOrInstitution
          ? _value.brokerOrInstitution
          : brokerOrInstitution // ignore: cast_nullable_to_non_nullable
              as String?,
      accountNumber: freezed == accountNumber
          ? _value.accountNumber
          : accountNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      bucketOverride: freezed == bucketOverride
          ? _value.bucketOverride
          : bucketOverride // ignore: cast_nullable_to_non_nullable
              as String?,
      lastUpdatedAt: freezed == lastUpdatedAt
          ? _value.lastUpdatedAt
          : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OtherAssetModelImpl implements _OtherAssetModel {
  const _$OtherAssetModelImpl(
      {required this.id,
      @JsonKey(name: 'owner_id') required this.ownerId,
      @JsonKey(name: 'family_id') this.familyId,
      @JsonKey(name: 'member_id') this.memberId,
      @JsonKey(name: 'asset_type') required this.assetType,
      required this.description,
      @JsonKey(name: 'isin_symbol') this.isinSymbol,
      this.quantity,
      @JsonKey(name: 'cost_value') this.costValue,
      @JsonKey(name: 'current_value') this.currentValue,
      @JsonKey(name: 'current_price') this.currentPrice,
      @JsonKey(name: 'interest_rate') this.interestRate,
      @JsonKey(name: 'interest_frequency') this.interestFrequency,
      @JsonKey(name: 'accrued_interest') this.accruedInterest,
      @JsonKey(name: 'tax_category') this.taxCategory,
      @JsonKey(name: 'start_date') this.startDate,
      @JsonKey(name: 'maturity_date') this.maturityDate,
      @JsonKey(name: 'lock_in_end_date') this.lockInEndDate,
      @JsonKey(name: 'last_valuation_date') this.lastValuationDate,
      @JsonKey(name: 'broker_or_institution') this.brokerOrInstitution,
      @JsonKey(name: 'account_number') this.accountNumber,
      this.notes,
      @JsonKey(name: 'bucket_override') this.bucketOverride,
      @JsonKey(name: 'last_updated_at') this.lastUpdatedAt,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$OtherAssetModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OtherAssetModelImplFromJson(json);

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
  @JsonKey(name: 'asset_type')
  final String assetType;
  @override
  final String description;
  @override
  @JsonKey(name: 'isin_symbol')
  final String? isinSymbol;
  @override
  final double? quantity;
  @override
  @JsonKey(name: 'cost_value')
  final double? costValue;
  @override
  @JsonKey(name: 'current_value')
  final double? currentValue;
  @override
  @JsonKey(name: 'current_price')
  final double? currentPrice;
  @override
  @JsonKey(name: 'interest_rate')
  final double? interestRate;
  @override
  @JsonKey(name: 'interest_frequency')
  final String? interestFrequency;
  @override
  @JsonKey(name: 'accrued_interest')
  final double? accruedInterest;
  @override
  @JsonKey(name: 'tax_category')
  final String? taxCategory;
  @override
  @JsonKey(name: 'start_date')
  final String? startDate;
  @override
  @JsonKey(name: 'maturity_date')
  final String? maturityDate;
  @override
  @JsonKey(name: 'lock_in_end_date')
  final String? lockInEndDate;
  @override
  @JsonKey(name: 'last_valuation_date')
  final String? lastValuationDate;
  @override
  @JsonKey(name: 'broker_or_institution')
  final String? brokerOrInstitution;
  @override
  @JsonKey(name: 'account_number')
  final String? accountNumber;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'bucket_override')
  final String? bucketOverride;
  @override
  @JsonKey(name: 'last_updated_at')
  final String? lastUpdatedAt;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;

  @override
  String toString() {
    return 'OtherAssetModel(id: $id, ownerId: $ownerId, familyId: $familyId, memberId: $memberId, assetType: $assetType, description: $description, isinSymbol: $isinSymbol, quantity: $quantity, costValue: $costValue, currentValue: $currentValue, currentPrice: $currentPrice, interestRate: $interestRate, interestFrequency: $interestFrequency, accruedInterest: $accruedInterest, taxCategory: $taxCategory, startDate: $startDate, maturityDate: $maturityDate, lockInEndDate: $lockInEndDate, lastValuationDate: $lastValuationDate, brokerOrInstitution: $brokerOrInstitution, accountNumber: $accountNumber, notes: $notes, bucketOverride: $bucketOverride, lastUpdatedAt: $lastUpdatedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OtherAssetModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.assetType, assetType) ||
                other.assetType == assetType) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isinSymbol, isinSymbol) ||
                other.isinSymbol == isinSymbol) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.costValue, costValue) ||
                other.costValue == costValue) &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue) &&
            (identical(other.currentPrice, currentPrice) ||
                other.currentPrice == currentPrice) &&
            (identical(other.interestRate, interestRate) ||
                other.interestRate == interestRate) &&
            (identical(other.interestFrequency, interestFrequency) ||
                other.interestFrequency == interestFrequency) &&
            (identical(other.accruedInterest, accruedInterest) ||
                other.accruedInterest == accruedInterest) &&
            (identical(other.taxCategory, taxCategory) ||
                other.taxCategory == taxCategory) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.maturityDate, maturityDate) ||
                other.maturityDate == maturityDate) &&
            (identical(other.lockInEndDate, lockInEndDate) ||
                other.lockInEndDate == lockInEndDate) &&
            (identical(other.lastValuationDate, lastValuationDate) ||
                other.lastValuationDate == lastValuationDate) &&
            (identical(other.brokerOrInstitution, brokerOrInstitution) ||
                other.brokerOrInstitution == brokerOrInstitution) &&
            (identical(other.accountNumber, accountNumber) ||
                other.accountNumber == accountNumber) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.bucketOverride, bucketOverride) ||
                other.bucketOverride == bucketOverride) &&
            (identical(other.lastUpdatedAt, lastUpdatedAt) ||
                other.lastUpdatedAt == lastUpdatedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        ownerId,
        familyId,
        memberId,
        assetType,
        description,
        isinSymbol,
        quantity,
        costValue,
        currentValue,
        currentPrice,
        interestRate,
        interestFrequency,
        accruedInterest,
        taxCategory,
        startDate,
        maturityDate,
        lockInEndDate,
        lastValuationDate,
        brokerOrInstitution,
        accountNumber,
        notes,
        bucketOverride,
        lastUpdatedAt,
        createdAt
      ]);

  /// Create a copy of OtherAssetModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OtherAssetModelImplCopyWith<_$OtherAssetModelImpl> get copyWith =>
      __$$OtherAssetModelImplCopyWithImpl<_$OtherAssetModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OtherAssetModelImplToJson(
      this,
    );
  }
}

abstract class _OtherAssetModel implements OtherAssetModel {
  const factory _OtherAssetModel(
      {required final String id,
      @JsonKey(name: 'owner_id') required final String ownerId,
      @JsonKey(name: 'family_id') final String? familyId,
      @JsonKey(name: 'member_id') final String? memberId,
      @JsonKey(name: 'asset_type') required final String assetType,
      required final String description,
      @JsonKey(name: 'isin_symbol') final String? isinSymbol,
      final double? quantity,
      @JsonKey(name: 'cost_value') final double? costValue,
      @JsonKey(name: 'current_value') final double? currentValue,
      @JsonKey(name: 'current_price') final double? currentPrice,
      @JsonKey(name: 'interest_rate') final double? interestRate,
      @JsonKey(name: 'interest_frequency') final String? interestFrequency,
      @JsonKey(name: 'accrued_interest') final double? accruedInterest,
      @JsonKey(name: 'tax_category') final String? taxCategory,
      @JsonKey(name: 'start_date') final String? startDate,
      @JsonKey(name: 'maturity_date') final String? maturityDate,
      @JsonKey(name: 'lock_in_end_date') final String? lockInEndDate,
      @JsonKey(name: 'last_valuation_date') final String? lastValuationDate,
      @JsonKey(name: 'broker_or_institution') final String? brokerOrInstitution,
      @JsonKey(name: 'account_number') final String? accountNumber,
      final String? notes,
      @JsonKey(name: 'bucket_override') final String? bucketOverride,
      @JsonKey(name: 'last_updated_at') final String? lastUpdatedAt,
      @JsonKey(name: 'created_at')
      required final String createdAt}) = _$OtherAssetModelImpl;

  factory _OtherAssetModel.fromJson(Map<String, dynamic> json) =
      _$OtherAssetModelImpl.fromJson;

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
  @JsonKey(name: 'asset_type')
  String get assetType;
  @override
  String get description;
  @override
  @JsonKey(name: 'isin_symbol')
  String? get isinSymbol;
  @override
  double? get quantity;
  @override
  @JsonKey(name: 'cost_value')
  double? get costValue;
  @override
  @JsonKey(name: 'current_value')
  double? get currentValue;
  @override
  @JsonKey(name: 'current_price')
  double? get currentPrice;
  @override
  @JsonKey(name: 'interest_rate')
  double? get interestRate;
  @override
  @JsonKey(name: 'interest_frequency')
  String? get interestFrequency;
  @override
  @JsonKey(name: 'accrued_interest')
  double? get accruedInterest;
  @override
  @JsonKey(name: 'tax_category')
  String? get taxCategory;
  @override
  @JsonKey(name: 'start_date')
  String? get startDate;
  @override
  @JsonKey(name: 'maturity_date')
  String? get maturityDate;
  @override
  @JsonKey(name: 'lock_in_end_date')
  String? get lockInEndDate;
  @override
  @JsonKey(name: 'last_valuation_date')
  String? get lastValuationDate;
  @override
  @JsonKey(name: 'broker_or_institution')
  String? get brokerOrInstitution;
  @override
  @JsonKey(name: 'account_number')
  String? get accountNumber;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'bucket_override')
  String? get bucketOverride;
  @override
  @JsonKey(name: 'last_updated_at')
  String? get lastUpdatedAt;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;

  /// Create a copy of OtherAssetModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OtherAssetModelImplCopyWith<_$OtherAssetModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
