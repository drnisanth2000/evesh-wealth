// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) {
  return _TransactionModel.fromJson(json);
}

/// @nodoc
mixin _$TransactionModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'owner_id')
  String get ownerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'family_id')
  String? get familyId => throw _privateConstructorUsedError;
  @JsonKey(name: 'member_id')
  String? get memberId => throw _privateConstructorUsedError;
  @JsonKey(name: 'amfi_code')
  int? get amfiCode => throw _privateConstructorUsedError;
  String? get isin => throw _privateConstructorUsedError;
  String? get symbol => throw _privateConstructorUsedError;
  @JsonKey(name: 'asset_type')
  String get assetType => throw _privateConstructorUsedError;
  @JsonKey(name: 'asset_name')
  String? get assetName => throw _privateConstructorUsedError;
  @JsonKey(name: 'tx_date')
  String get txDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'tx_type')
  String get txType => throw _privateConstructorUsedError;
  double? get units => throw _privateConstructorUsedError;
  @JsonKey(name: 'nav_at_tx')
  double? get navAtTx => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  @JsonKey(name: 'folio_number')
  String? get folioNumber => throw _privateConstructorUsedError;
  String? get broker => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_amount')
  double? get targetAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'stoploss_amount')
  double? get stoplossAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_value')
  double? get currentValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'dedup_hash')
  String? get dedupHash => throw _privateConstructorUsedError;
  @JsonKey(name: 'stamp_duty')
  double get stampDuty => throw _privateConstructorUsedError;
  @JsonKey(name: 'stt_amount')
  double get sttAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'import_source')
  String get importSource => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt =>
      throw _privateConstructorUsedError; // Joined from fund_master (optional)
  @JsonKey(name: 'fund_master')
  FundJoin? get fundMaster => throw _privateConstructorUsedError;

  /// Serializes this TransactionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TransactionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionModelCopyWith<TransactionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionModelCopyWith<$Res> {
  factory $TransactionModelCopyWith(
          TransactionModel value, $Res Function(TransactionModel) then) =
      _$TransactionModelCopyWithImpl<$Res, TransactionModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'family_id') String? familyId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'amfi_code') int? amfiCode,
      String? isin,
      String? symbol,
      @JsonKey(name: 'asset_type') String assetType,
      @JsonKey(name: 'asset_name') String? assetName,
      @JsonKey(name: 'tx_date') String txDate,
      @JsonKey(name: 'tx_type') String txType,
      double? units,
      @JsonKey(name: 'nav_at_tx') double? navAtTx,
      double amount,
      @JsonKey(name: 'folio_number') String? folioNumber,
      String? broker,
      String? notes,
      @JsonKey(name: 'target_amount') double? targetAmount,
      @JsonKey(name: 'stoploss_amount') double? stoplossAmount,
      @JsonKey(name: 'current_value') double? currentValue,
      @JsonKey(name: 'dedup_hash') String? dedupHash,
      @JsonKey(name: 'stamp_duty') double stampDuty,
      @JsonKey(name: 'stt_amount') double sttAmount,
      @JsonKey(name: 'import_source') String importSource,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'fund_master') FundJoin? fundMaster});

  $FundJoinCopyWith<$Res>? get fundMaster;
}

/// @nodoc
class _$TransactionModelCopyWithImpl<$Res, $Val extends TransactionModel>
    implements $TransactionModelCopyWith<$Res> {
  _$TransactionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransactionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? familyId = freezed,
    Object? memberId = freezed,
    Object? amfiCode = freezed,
    Object? isin = freezed,
    Object? symbol = freezed,
    Object? assetType = null,
    Object? assetName = freezed,
    Object? txDate = null,
    Object? txType = null,
    Object? units = freezed,
    Object? navAtTx = freezed,
    Object? amount = null,
    Object? folioNumber = freezed,
    Object? broker = freezed,
    Object? notes = freezed,
    Object? targetAmount = freezed,
    Object? stoplossAmount = freezed,
    Object? currentValue = freezed,
    Object? dedupHash = freezed,
    Object? stampDuty = null,
    Object? sttAmount = null,
    Object? importSource = null,
    Object? createdAt = freezed,
    Object? fundMaster = freezed,
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
      isin: freezed == isin
          ? _value.isin
          : isin // ignore: cast_nullable_to_non_nullable
              as String?,
      symbol: freezed == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String?,
      assetType: null == assetType
          ? _value.assetType
          : assetType // ignore: cast_nullable_to_non_nullable
              as String,
      assetName: freezed == assetName
          ? _value.assetName
          : assetName // ignore: cast_nullable_to_non_nullable
              as String?,
      txDate: null == txDate
          ? _value.txDate
          : txDate // ignore: cast_nullable_to_non_nullable
              as String,
      txType: null == txType
          ? _value.txType
          : txType // ignore: cast_nullable_to_non_nullable
              as String,
      units: freezed == units
          ? _value.units
          : units // ignore: cast_nullable_to_non_nullable
              as double?,
      navAtTx: freezed == navAtTx
          ? _value.navAtTx
          : navAtTx // ignore: cast_nullable_to_non_nullable
              as double?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      folioNumber: freezed == folioNumber
          ? _value.folioNumber
          : folioNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      broker: freezed == broker
          ? _value.broker
          : broker // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      targetAmount: freezed == targetAmount
          ? _value.targetAmount
          : targetAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      stoplossAmount: freezed == stoplossAmount
          ? _value.stoplossAmount
          : stoplossAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      currentValue: freezed == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double?,
      dedupHash: freezed == dedupHash
          ? _value.dedupHash
          : dedupHash // ignore: cast_nullable_to_non_nullable
              as String?,
      stampDuty: null == stampDuty
          ? _value.stampDuty
          : stampDuty // ignore: cast_nullable_to_non_nullable
              as double,
      sttAmount: null == sttAmount
          ? _value.sttAmount
          : sttAmount // ignore: cast_nullable_to_non_nullable
              as double,
      importSource: null == importSource
          ? _value.importSource
          : importSource // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      fundMaster: freezed == fundMaster
          ? _value.fundMaster
          : fundMaster // ignore: cast_nullable_to_non_nullable
              as FundJoin?,
    ) as $Val);
  }

  /// Create a copy of TransactionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FundJoinCopyWith<$Res>? get fundMaster {
    if (_value.fundMaster == null) {
      return null;
    }

    return $FundJoinCopyWith<$Res>(_value.fundMaster!, (value) {
      return _then(_value.copyWith(fundMaster: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TransactionModelImplCopyWith<$Res>
    implements $TransactionModelCopyWith<$Res> {
  factory _$$TransactionModelImplCopyWith(_$TransactionModelImpl value,
          $Res Function(_$TransactionModelImpl) then) =
      __$$TransactionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'family_id') String? familyId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'amfi_code') int? amfiCode,
      String? isin,
      String? symbol,
      @JsonKey(name: 'asset_type') String assetType,
      @JsonKey(name: 'asset_name') String? assetName,
      @JsonKey(name: 'tx_date') String txDate,
      @JsonKey(name: 'tx_type') String txType,
      double? units,
      @JsonKey(name: 'nav_at_tx') double? navAtTx,
      double amount,
      @JsonKey(name: 'folio_number') String? folioNumber,
      String? broker,
      String? notes,
      @JsonKey(name: 'target_amount') double? targetAmount,
      @JsonKey(name: 'stoploss_amount') double? stoplossAmount,
      @JsonKey(name: 'current_value') double? currentValue,
      @JsonKey(name: 'dedup_hash') String? dedupHash,
      @JsonKey(name: 'stamp_duty') double stampDuty,
      @JsonKey(name: 'stt_amount') double sttAmount,
      @JsonKey(name: 'import_source') String importSource,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'fund_master') FundJoin? fundMaster});

  @override
  $FundJoinCopyWith<$Res>? get fundMaster;
}

/// @nodoc
class __$$TransactionModelImplCopyWithImpl<$Res>
    extends _$TransactionModelCopyWithImpl<$Res, _$TransactionModelImpl>
    implements _$$TransactionModelImplCopyWith<$Res> {
  __$$TransactionModelImplCopyWithImpl(_$TransactionModelImpl _value,
      $Res Function(_$TransactionModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransactionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? familyId = freezed,
    Object? memberId = freezed,
    Object? amfiCode = freezed,
    Object? isin = freezed,
    Object? symbol = freezed,
    Object? assetType = null,
    Object? assetName = freezed,
    Object? txDate = null,
    Object? txType = null,
    Object? units = freezed,
    Object? navAtTx = freezed,
    Object? amount = null,
    Object? folioNumber = freezed,
    Object? broker = freezed,
    Object? notes = freezed,
    Object? targetAmount = freezed,
    Object? stoplossAmount = freezed,
    Object? currentValue = freezed,
    Object? dedupHash = freezed,
    Object? stampDuty = null,
    Object? sttAmount = null,
    Object? importSource = null,
    Object? createdAt = freezed,
    Object? fundMaster = freezed,
  }) {
    return _then(_$TransactionModelImpl(
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
      isin: freezed == isin
          ? _value.isin
          : isin // ignore: cast_nullable_to_non_nullable
              as String?,
      symbol: freezed == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String?,
      assetType: null == assetType
          ? _value.assetType
          : assetType // ignore: cast_nullable_to_non_nullable
              as String,
      assetName: freezed == assetName
          ? _value.assetName
          : assetName // ignore: cast_nullable_to_non_nullable
              as String?,
      txDate: null == txDate
          ? _value.txDate
          : txDate // ignore: cast_nullable_to_non_nullable
              as String,
      txType: null == txType
          ? _value.txType
          : txType // ignore: cast_nullable_to_non_nullable
              as String,
      units: freezed == units
          ? _value.units
          : units // ignore: cast_nullable_to_non_nullable
              as double?,
      navAtTx: freezed == navAtTx
          ? _value.navAtTx
          : navAtTx // ignore: cast_nullable_to_non_nullable
              as double?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      folioNumber: freezed == folioNumber
          ? _value.folioNumber
          : folioNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      broker: freezed == broker
          ? _value.broker
          : broker // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      targetAmount: freezed == targetAmount
          ? _value.targetAmount
          : targetAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      stoplossAmount: freezed == stoplossAmount
          ? _value.stoplossAmount
          : stoplossAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      currentValue: freezed == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double?,
      dedupHash: freezed == dedupHash
          ? _value.dedupHash
          : dedupHash // ignore: cast_nullable_to_non_nullable
              as String?,
      stampDuty: null == stampDuty
          ? _value.stampDuty
          : stampDuty // ignore: cast_nullable_to_non_nullable
              as double,
      sttAmount: null == sttAmount
          ? _value.sttAmount
          : sttAmount // ignore: cast_nullable_to_non_nullable
              as double,
      importSource: null == importSource
          ? _value.importSource
          : importSource // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      fundMaster: freezed == fundMaster
          ? _value.fundMaster
          : fundMaster // ignore: cast_nullable_to_non_nullable
              as FundJoin?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TransactionModelImpl extends _TransactionModel {
  const _$TransactionModelImpl(
      {required this.id,
      @JsonKey(name: 'owner_id') required this.ownerId,
      @JsonKey(name: 'family_id') this.familyId,
      @JsonKey(name: 'member_id') this.memberId,
      @JsonKey(name: 'amfi_code') this.amfiCode,
      this.isin,
      this.symbol,
      @JsonKey(name: 'asset_type') required this.assetType,
      @JsonKey(name: 'asset_name') this.assetName,
      @JsonKey(name: 'tx_date') required this.txDate,
      @JsonKey(name: 'tx_type') required this.txType,
      this.units,
      @JsonKey(name: 'nav_at_tx') this.navAtTx,
      required this.amount,
      @JsonKey(name: 'folio_number') this.folioNumber,
      this.broker,
      this.notes,
      @JsonKey(name: 'target_amount') this.targetAmount,
      @JsonKey(name: 'stoploss_amount') this.stoplossAmount,
      @JsonKey(name: 'current_value') this.currentValue,
      @JsonKey(name: 'dedup_hash') this.dedupHash,
      @JsonKey(name: 'stamp_duty') this.stampDuty = 0,
      @JsonKey(name: 'stt_amount') this.sttAmount = 0,
      @JsonKey(name: 'import_source') this.importSource = 'manual',
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'fund_master') this.fundMaster})
      : super._();

  factory _$TransactionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionModelImplFromJson(json);

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
  final String? isin;
  @override
  final String? symbol;
  @override
  @JsonKey(name: 'asset_type')
  final String assetType;
  @override
  @JsonKey(name: 'asset_name')
  final String? assetName;
  @override
  @JsonKey(name: 'tx_date')
  final String txDate;
  @override
  @JsonKey(name: 'tx_type')
  final String txType;
  @override
  final double? units;
  @override
  @JsonKey(name: 'nav_at_tx')
  final double? navAtTx;
  @override
  final double amount;
  @override
  @JsonKey(name: 'folio_number')
  final String? folioNumber;
  @override
  final String? broker;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'target_amount')
  final double? targetAmount;
  @override
  @JsonKey(name: 'stoploss_amount')
  final double? stoplossAmount;
  @override
  @JsonKey(name: 'current_value')
  final double? currentValue;
  @override
  @JsonKey(name: 'dedup_hash')
  final String? dedupHash;
  @override
  @JsonKey(name: 'stamp_duty')
  final double stampDuty;
  @override
  @JsonKey(name: 'stt_amount')
  final double sttAmount;
  @override
  @JsonKey(name: 'import_source')
  final String importSource;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
// Joined from fund_master (optional)
  @override
  @JsonKey(name: 'fund_master')
  final FundJoin? fundMaster;

  @override
  String toString() {
    return 'TransactionModel(id: $id, ownerId: $ownerId, familyId: $familyId, memberId: $memberId, amfiCode: $amfiCode, isin: $isin, symbol: $symbol, assetType: $assetType, assetName: $assetName, txDate: $txDate, txType: $txType, units: $units, navAtTx: $navAtTx, amount: $amount, folioNumber: $folioNumber, broker: $broker, notes: $notes, targetAmount: $targetAmount, stoplossAmount: $stoplossAmount, currentValue: $currentValue, dedupHash: $dedupHash, stampDuty: $stampDuty, sttAmount: $sttAmount, importSource: $importSource, createdAt: $createdAt, fundMaster: $fundMaster)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.amfiCode, amfiCode) ||
                other.amfiCode == amfiCode) &&
            (identical(other.isin, isin) || other.isin == isin) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.assetType, assetType) ||
                other.assetType == assetType) &&
            (identical(other.assetName, assetName) ||
                other.assetName == assetName) &&
            (identical(other.txDate, txDate) || other.txDate == txDate) &&
            (identical(other.txType, txType) || other.txType == txType) &&
            (identical(other.units, units) || other.units == units) &&
            (identical(other.navAtTx, navAtTx) || other.navAtTx == navAtTx) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.folioNumber, folioNumber) ||
                other.folioNumber == folioNumber) &&
            (identical(other.broker, broker) || other.broker == broker) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.targetAmount, targetAmount) ||
                other.targetAmount == targetAmount) &&
            (identical(other.stoplossAmount, stoplossAmount) ||
                other.stoplossAmount == stoplossAmount) &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue) &&
            (identical(other.dedupHash, dedupHash) ||
                other.dedupHash == dedupHash) &&
            (identical(other.stampDuty, stampDuty) ||
                other.stampDuty == stampDuty) &&
            (identical(other.sttAmount, sttAmount) ||
                other.sttAmount == sttAmount) &&
            (identical(other.importSource, importSource) ||
                other.importSource == importSource) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.fundMaster, fundMaster) ||
                other.fundMaster == fundMaster));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        ownerId,
        familyId,
        memberId,
        amfiCode,
        isin,
        symbol,
        assetType,
        assetName,
        txDate,
        txType,
        units,
        navAtTx,
        amount,
        folioNumber,
        broker,
        notes,
        targetAmount,
        stoplossAmount,
        currentValue,
        dedupHash,
        stampDuty,
        sttAmount,
        importSource,
        createdAt,
        fundMaster
      ]);

  /// Create a copy of TransactionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionModelImplCopyWith<_$TransactionModelImpl> get copyWith =>
      __$$TransactionModelImplCopyWithImpl<_$TransactionModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionModelImplToJson(
      this,
    );
  }
}

abstract class _TransactionModel extends TransactionModel {
  const factory _TransactionModel(
          {required final String id,
          @JsonKey(name: 'owner_id') required final String ownerId,
          @JsonKey(name: 'family_id') final String? familyId,
          @JsonKey(name: 'member_id') final String? memberId,
          @JsonKey(name: 'amfi_code') final int? amfiCode,
          final String? isin,
          final String? symbol,
          @JsonKey(name: 'asset_type') required final String assetType,
          @JsonKey(name: 'asset_name') final String? assetName,
          @JsonKey(name: 'tx_date') required final String txDate,
          @JsonKey(name: 'tx_type') required final String txType,
          final double? units,
          @JsonKey(name: 'nav_at_tx') final double? navAtTx,
          required final double amount,
          @JsonKey(name: 'folio_number') final String? folioNumber,
          final String? broker,
          final String? notes,
          @JsonKey(name: 'target_amount') final double? targetAmount,
          @JsonKey(name: 'stoploss_amount') final double? stoplossAmount,
          @JsonKey(name: 'current_value') final double? currentValue,
          @JsonKey(name: 'dedup_hash') final String? dedupHash,
          @JsonKey(name: 'stamp_duty') final double stampDuty,
          @JsonKey(name: 'stt_amount') final double sttAmount,
          @JsonKey(name: 'import_source') final String importSource,
          @JsonKey(name: 'created_at') final String? createdAt,
          @JsonKey(name: 'fund_master') final FundJoin? fundMaster}) =
      _$TransactionModelImpl;
  const _TransactionModel._() : super._();

  factory _TransactionModel.fromJson(Map<String, dynamic> json) =
      _$TransactionModelImpl.fromJson;

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
  String? get isin;
  @override
  String? get symbol;
  @override
  @JsonKey(name: 'asset_type')
  String get assetType;
  @override
  @JsonKey(name: 'asset_name')
  String? get assetName;
  @override
  @JsonKey(name: 'tx_date')
  String get txDate;
  @override
  @JsonKey(name: 'tx_type')
  String get txType;
  @override
  double? get units;
  @override
  @JsonKey(name: 'nav_at_tx')
  double? get navAtTx;
  @override
  double get amount;
  @override
  @JsonKey(name: 'folio_number')
  String? get folioNumber;
  @override
  String? get broker;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'target_amount')
  double? get targetAmount;
  @override
  @JsonKey(name: 'stoploss_amount')
  double? get stoplossAmount;
  @override
  @JsonKey(name: 'current_value')
  double? get currentValue;
  @override
  @JsonKey(name: 'dedup_hash')
  String? get dedupHash;
  @override
  @JsonKey(name: 'stamp_duty')
  double get stampDuty;
  @override
  @JsonKey(name: 'stt_amount')
  double get sttAmount;
  @override
  @JsonKey(name: 'import_source')
  String get importSource;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt; // Joined from fund_master (optional)
  @override
  @JsonKey(name: 'fund_master')
  FundJoin? get fundMaster;

  /// Create a copy of TransactionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionModelImplCopyWith<_$TransactionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FundJoin _$FundJoinFromJson(Map<String, dynamic> json) {
  return _FundJoin.fromJson(json);
}

/// @nodoc
mixin _$FundJoin {
  @JsonKey(name: 'fund_name')
  String get fundName => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  @JsonKey(name: 'tax_category')
  String? get taxCategory => throw _privateConstructorUsedError;
  @JsonKey(name: 'latest_nav')
  double? get latestNav => throw _privateConstructorUsedError;
  @JsonKey(name: 'fund_managers')
  List<String>? get fundManagers => throw _privateConstructorUsedError;
  @JsonKey(name: 'crisil_rating')
  String? get crisilRating => throw _privateConstructorUsedError;
  @JsonKey(name: 'jan_31_nav')
  double? get jan31Nav => throw _privateConstructorUsedError;
  @JsonKey(name: 'tax_period')
  int? get taxPeriod => throw _privateConstructorUsedError;
  @JsonKey(name: 'exit_load')
  String? get exitLoad => throw _privateConstructorUsedError;
  @JsonKey(name: 'plan_type')
  String? get planType => throw _privateConstructorUsedError;
  @JsonKey(name: 'expense_ratio')
  double? get expenseRatio => throw _privateConstructorUsedError;
  @JsonKey(name: 'return_1y')
  double? get return1y => throw _privateConstructorUsedError;
  @JsonKey(name: 'amfi_category_id')
  String? get amfiCategoryId => throw _privateConstructorUsedError;
  @JsonKey(name: 'benchmark_tier1')
  String? get benchmarkTier1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'benchmark_tier2')
  String? get benchmarkTier2 => throw _privateConstructorUsedError;

  /// Serializes this FundJoin to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FundJoin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FundJoinCopyWith<FundJoin> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FundJoinCopyWith<$Res> {
  factory $FundJoinCopyWith(FundJoin value, $Res Function(FundJoin) then) =
      _$FundJoinCopyWithImpl<$Res, FundJoin>;
  @useResult
  $Res call(
      {@JsonKey(name: 'fund_name') String fundName,
      String? category,
      @JsonKey(name: 'tax_category') String? taxCategory,
      @JsonKey(name: 'latest_nav') double? latestNav,
      @JsonKey(name: 'fund_managers') List<String>? fundManagers,
      @JsonKey(name: 'crisil_rating') String? crisilRating,
      @JsonKey(name: 'jan_31_nav') double? jan31Nav,
      @JsonKey(name: 'tax_period') int? taxPeriod,
      @JsonKey(name: 'exit_load') String? exitLoad,
      @JsonKey(name: 'plan_type') String? planType,
      @JsonKey(name: 'expense_ratio') double? expenseRatio,
      @JsonKey(name: 'return_1y') double? return1y,
      @JsonKey(name: 'amfi_category_id') String? amfiCategoryId,
      @JsonKey(name: 'benchmark_tier1') String? benchmarkTier1,
      @JsonKey(name: 'benchmark_tier2') String? benchmarkTier2});
}

/// @nodoc
class _$FundJoinCopyWithImpl<$Res, $Val extends FundJoin>
    implements $FundJoinCopyWith<$Res> {
  _$FundJoinCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FundJoin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fundName = null,
    Object? category = freezed,
    Object? taxCategory = freezed,
    Object? latestNav = freezed,
    Object? fundManagers = freezed,
    Object? crisilRating = freezed,
    Object? jan31Nav = freezed,
    Object? taxPeriod = freezed,
    Object? exitLoad = freezed,
    Object? planType = freezed,
    Object? expenseRatio = freezed,
    Object? return1y = freezed,
    Object? amfiCategoryId = freezed,
    Object? benchmarkTier1 = freezed,
    Object? benchmarkTier2 = freezed,
  }) {
    return _then(_value.copyWith(
      fundName: null == fundName
          ? _value.fundName
          : fundName // ignore: cast_nullable_to_non_nullable
              as String,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      taxCategory: freezed == taxCategory
          ? _value.taxCategory
          : taxCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      latestNav: freezed == latestNav
          ? _value.latestNav
          : latestNav // ignore: cast_nullable_to_non_nullable
              as double?,
      fundManagers: freezed == fundManagers
          ? _value.fundManagers
          : fundManagers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      crisilRating: freezed == crisilRating
          ? _value.crisilRating
          : crisilRating // ignore: cast_nullable_to_non_nullable
              as String?,
      jan31Nav: freezed == jan31Nav
          ? _value.jan31Nav
          : jan31Nav // ignore: cast_nullable_to_non_nullable
              as double?,
      taxPeriod: freezed == taxPeriod
          ? _value.taxPeriod
          : taxPeriod // ignore: cast_nullable_to_non_nullable
              as int?,
      exitLoad: freezed == exitLoad
          ? _value.exitLoad
          : exitLoad // ignore: cast_nullable_to_non_nullable
              as String?,
      planType: freezed == planType
          ? _value.planType
          : planType // ignore: cast_nullable_to_non_nullable
              as String?,
      expenseRatio: freezed == expenseRatio
          ? _value.expenseRatio
          : expenseRatio // ignore: cast_nullable_to_non_nullable
              as double?,
      return1y: freezed == return1y
          ? _value.return1y
          : return1y // ignore: cast_nullable_to_non_nullable
              as double?,
      amfiCategoryId: freezed == amfiCategoryId
          ? _value.amfiCategoryId
          : amfiCategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      benchmarkTier1: freezed == benchmarkTier1
          ? _value.benchmarkTier1
          : benchmarkTier1 // ignore: cast_nullable_to_non_nullable
              as String?,
      benchmarkTier2: freezed == benchmarkTier2
          ? _value.benchmarkTier2
          : benchmarkTier2 // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FundJoinImplCopyWith<$Res>
    implements $FundJoinCopyWith<$Res> {
  factory _$$FundJoinImplCopyWith(
          _$FundJoinImpl value, $Res Function(_$FundJoinImpl) then) =
      __$$FundJoinImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'fund_name') String fundName,
      String? category,
      @JsonKey(name: 'tax_category') String? taxCategory,
      @JsonKey(name: 'latest_nav') double? latestNav,
      @JsonKey(name: 'fund_managers') List<String>? fundManagers,
      @JsonKey(name: 'crisil_rating') String? crisilRating,
      @JsonKey(name: 'jan_31_nav') double? jan31Nav,
      @JsonKey(name: 'tax_period') int? taxPeriod,
      @JsonKey(name: 'exit_load') String? exitLoad,
      @JsonKey(name: 'plan_type') String? planType,
      @JsonKey(name: 'expense_ratio') double? expenseRatio,
      @JsonKey(name: 'return_1y') double? return1y,
      @JsonKey(name: 'amfi_category_id') String? amfiCategoryId,
      @JsonKey(name: 'benchmark_tier1') String? benchmarkTier1,
      @JsonKey(name: 'benchmark_tier2') String? benchmarkTier2});
}

/// @nodoc
class __$$FundJoinImplCopyWithImpl<$Res>
    extends _$FundJoinCopyWithImpl<$Res, _$FundJoinImpl>
    implements _$$FundJoinImplCopyWith<$Res> {
  __$$FundJoinImplCopyWithImpl(
      _$FundJoinImpl _value, $Res Function(_$FundJoinImpl) _then)
      : super(_value, _then);

  /// Create a copy of FundJoin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fundName = null,
    Object? category = freezed,
    Object? taxCategory = freezed,
    Object? latestNav = freezed,
    Object? fundManagers = freezed,
    Object? crisilRating = freezed,
    Object? jan31Nav = freezed,
    Object? taxPeriod = freezed,
    Object? exitLoad = freezed,
    Object? planType = freezed,
    Object? expenseRatio = freezed,
    Object? return1y = freezed,
    Object? amfiCategoryId = freezed,
    Object? benchmarkTier1 = freezed,
    Object? benchmarkTier2 = freezed,
  }) {
    return _then(_$FundJoinImpl(
      fundName: null == fundName
          ? _value.fundName
          : fundName // ignore: cast_nullable_to_non_nullable
              as String,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      taxCategory: freezed == taxCategory
          ? _value.taxCategory
          : taxCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      latestNav: freezed == latestNav
          ? _value.latestNav
          : latestNav // ignore: cast_nullable_to_non_nullable
              as double?,
      fundManagers: freezed == fundManagers
          ? _value._fundManagers
          : fundManagers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      crisilRating: freezed == crisilRating
          ? _value.crisilRating
          : crisilRating // ignore: cast_nullable_to_non_nullable
              as String?,
      jan31Nav: freezed == jan31Nav
          ? _value.jan31Nav
          : jan31Nav // ignore: cast_nullable_to_non_nullable
              as double?,
      taxPeriod: freezed == taxPeriod
          ? _value.taxPeriod
          : taxPeriod // ignore: cast_nullable_to_non_nullable
              as int?,
      exitLoad: freezed == exitLoad
          ? _value.exitLoad
          : exitLoad // ignore: cast_nullable_to_non_nullable
              as String?,
      planType: freezed == planType
          ? _value.planType
          : planType // ignore: cast_nullable_to_non_nullable
              as String?,
      expenseRatio: freezed == expenseRatio
          ? _value.expenseRatio
          : expenseRatio // ignore: cast_nullable_to_non_nullable
              as double?,
      return1y: freezed == return1y
          ? _value.return1y
          : return1y // ignore: cast_nullable_to_non_nullable
              as double?,
      amfiCategoryId: freezed == amfiCategoryId
          ? _value.amfiCategoryId
          : amfiCategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      benchmarkTier1: freezed == benchmarkTier1
          ? _value.benchmarkTier1
          : benchmarkTier1 // ignore: cast_nullable_to_non_nullable
              as String?,
      benchmarkTier2: freezed == benchmarkTier2
          ? _value.benchmarkTier2
          : benchmarkTier2 // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FundJoinImpl implements _FundJoin {
  const _$FundJoinImpl(
      {@JsonKey(name: 'fund_name') required this.fundName,
      this.category,
      @JsonKey(name: 'tax_category') this.taxCategory,
      @JsonKey(name: 'latest_nav') this.latestNav,
      @JsonKey(name: 'fund_managers') final List<String>? fundManagers,
      @JsonKey(name: 'crisil_rating') this.crisilRating,
      @JsonKey(name: 'jan_31_nav') this.jan31Nav,
      @JsonKey(name: 'tax_period') this.taxPeriod,
      @JsonKey(name: 'exit_load') this.exitLoad,
      @JsonKey(name: 'plan_type') this.planType,
      @JsonKey(name: 'expense_ratio') this.expenseRatio,
      @JsonKey(name: 'return_1y') this.return1y,
      @JsonKey(name: 'amfi_category_id') this.amfiCategoryId,
      @JsonKey(name: 'benchmark_tier1') this.benchmarkTier1,
      @JsonKey(name: 'benchmark_tier2') this.benchmarkTier2})
      : _fundManagers = fundManagers;

  factory _$FundJoinImpl.fromJson(Map<String, dynamic> json) =>
      _$$FundJoinImplFromJson(json);

  @override
  @JsonKey(name: 'fund_name')
  final String fundName;
  @override
  final String? category;
  @override
  @JsonKey(name: 'tax_category')
  final String? taxCategory;
  @override
  @JsonKey(name: 'latest_nav')
  final double? latestNav;
  final List<String>? _fundManagers;
  @override
  @JsonKey(name: 'fund_managers')
  List<String>? get fundManagers {
    final value = _fundManagers;
    if (value == null) return null;
    if (_fundManagers is EqualUnmodifiableListView) return _fundManagers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'crisil_rating')
  final String? crisilRating;
  @override
  @JsonKey(name: 'jan_31_nav')
  final double? jan31Nav;
  @override
  @JsonKey(name: 'tax_period')
  final int? taxPeriod;
  @override
  @JsonKey(name: 'exit_load')
  final String? exitLoad;
  @override
  @JsonKey(name: 'plan_type')
  final String? planType;
  @override
  @JsonKey(name: 'expense_ratio')
  final double? expenseRatio;
  @override
  @JsonKey(name: 'return_1y')
  final double? return1y;
  @override
  @JsonKey(name: 'amfi_category_id')
  final String? amfiCategoryId;
  @override
  @JsonKey(name: 'benchmark_tier1')
  final String? benchmarkTier1;
  @override
  @JsonKey(name: 'benchmark_tier2')
  final String? benchmarkTier2;

  @override
  String toString() {
    return 'FundJoin(fundName: $fundName, category: $category, taxCategory: $taxCategory, latestNav: $latestNav, fundManagers: $fundManagers, crisilRating: $crisilRating, jan31Nav: $jan31Nav, taxPeriod: $taxPeriod, exitLoad: $exitLoad, planType: $planType, expenseRatio: $expenseRatio, return1y: $return1y, amfiCategoryId: $amfiCategoryId, benchmarkTier1: $benchmarkTier1, benchmarkTier2: $benchmarkTier2)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FundJoinImpl &&
            (identical(other.fundName, fundName) ||
                other.fundName == fundName) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.taxCategory, taxCategory) ||
                other.taxCategory == taxCategory) &&
            (identical(other.latestNav, latestNav) ||
                other.latestNav == latestNav) &&
            const DeepCollectionEquality()
                .equals(other._fundManagers, _fundManagers) &&
            (identical(other.crisilRating, crisilRating) ||
                other.crisilRating == crisilRating) &&
            (identical(other.jan31Nav, jan31Nav) ||
                other.jan31Nav == jan31Nav) &&
            (identical(other.taxPeriod, taxPeriod) ||
                other.taxPeriod == taxPeriod) &&
            (identical(other.exitLoad, exitLoad) ||
                other.exitLoad == exitLoad) &&
            (identical(other.planType, planType) ||
                other.planType == planType) &&
            (identical(other.expenseRatio, expenseRatio) ||
                other.expenseRatio == expenseRatio) &&
            (identical(other.return1y, return1y) ||
                other.return1y == return1y) &&
            (identical(other.amfiCategoryId, amfiCategoryId) ||
                other.amfiCategoryId == amfiCategoryId) &&
            (identical(other.benchmarkTier1, benchmarkTier1) ||
                other.benchmarkTier1 == benchmarkTier1) &&
            (identical(other.benchmarkTier2, benchmarkTier2) ||
                other.benchmarkTier2 == benchmarkTier2));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      fundName,
      category,
      taxCategory,
      latestNav,
      const DeepCollectionEquality().hash(_fundManagers),
      crisilRating,
      jan31Nav,
      taxPeriod,
      exitLoad,
      planType,
      expenseRatio,
      return1y,
      amfiCategoryId,
      benchmarkTier1,
      benchmarkTier2);

  /// Create a copy of FundJoin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FundJoinImplCopyWith<_$FundJoinImpl> get copyWith =>
      __$$FundJoinImplCopyWithImpl<_$FundJoinImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FundJoinImplToJson(
      this,
    );
  }
}

abstract class _FundJoin implements FundJoin {
  const factory _FundJoin(
          {@JsonKey(name: 'fund_name') required final String fundName,
          final String? category,
          @JsonKey(name: 'tax_category') final String? taxCategory,
          @JsonKey(name: 'latest_nav') final double? latestNav,
          @JsonKey(name: 'fund_managers') final List<String>? fundManagers,
          @JsonKey(name: 'crisil_rating') final String? crisilRating,
          @JsonKey(name: 'jan_31_nav') final double? jan31Nav,
          @JsonKey(name: 'tax_period') final int? taxPeriod,
          @JsonKey(name: 'exit_load') final String? exitLoad,
          @JsonKey(name: 'plan_type') final String? planType,
          @JsonKey(name: 'expense_ratio') final double? expenseRatio,
          @JsonKey(name: 'return_1y') final double? return1y,
          @JsonKey(name: 'amfi_category_id') final String? amfiCategoryId,
          @JsonKey(name: 'benchmark_tier1') final String? benchmarkTier1,
          @JsonKey(name: 'benchmark_tier2') final String? benchmarkTier2}) =
      _$FundJoinImpl;

  factory _FundJoin.fromJson(Map<String, dynamic> json) =
      _$FundJoinImpl.fromJson;

  @override
  @JsonKey(name: 'fund_name')
  String get fundName;
  @override
  String? get category;
  @override
  @JsonKey(name: 'tax_category')
  String? get taxCategory;
  @override
  @JsonKey(name: 'latest_nav')
  double? get latestNav;
  @override
  @JsonKey(name: 'fund_managers')
  List<String>? get fundManagers;
  @override
  @JsonKey(name: 'crisil_rating')
  String? get crisilRating;
  @override
  @JsonKey(name: 'jan_31_nav')
  double? get jan31Nav;
  @override
  @JsonKey(name: 'tax_period')
  int? get taxPeriod;
  @override
  @JsonKey(name: 'exit_load')
  String? get exitLoad;
  @override
  @JsonKey(name: 'plan_type')
  String? get planType;
  @override
  @JsonKey(name: 'expense_ratio')
  double? get expenseRatio;
  @override
  @JsonKey(name: 'return_1y')
  double? get return1y;
  @override
  @JsonKey(name: 'amfi_category_id')
  String? get amfiCategoryId;
  @override
  @JsonKey(name: 'benchmark_tier1')
  String? get benchmarkTier1;
  @override
  @JsonKey(name: 'benchmark_tier2')
  String? get benchmarkTier2;

  /// Create a copy of FundJoin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FundJoinImplCopyWith<_$FundJoinImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
