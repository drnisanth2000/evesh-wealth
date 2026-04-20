// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folio_detail_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FolioDetailModel _$FolioDetailModelFromJson(Map<String, dynamic> json) {
  return _FolioDetailModel.fromJson(json);
}

/// @nodoc
mixin _$FolioDetailModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'owner_id')
  String get ownerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'member_id')
  String? get memberId => throw _privateConstructorUsedError;
  @JsonKey(name: 'folio_number')
  String get folioNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'amc_name')
  String? get amcName => throw _privateConstructorUsedError;
  @JsonKey(name: 'scheme_name')
  String? get schemeName => throw _privateConstructorUsedError;
  String? get isin => throw _privateConstructorUsedError;
  String? get pan => throw _privateConstructorUsedError;
  @JsonKey(name: 'kyc_status')
  String? get kycStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'pan_status')
  String? get panStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'investor_name')
  String? get investorName => throw _privateConstructorUsedError;
  String? get registrar => throw _privateConstructorUsedError;
  @JsonKey(name: 'advisor_code')
  String? get advisorCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'demat_status')
  String? get dematStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'nominee_1')
  String? get nominee1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'nominee_2')
  String? get nominee2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'nominee_3')
  String? get nominee3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'closing_units')
  double? get closingUnits => throw _privateConstructorUsedError;
  @JsonKey(name: 'closing_nav')
  double? get closingNav => throw _privateConstructorUsedError;
  @JsonKey(name: 'closing_nav_date')
  String? get closingNavDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_cost_value')
  double? get totalCostValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'market_value')
  double? get marketValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'exit_load_text')
  String? get exitLoadText => throw _privateConstructorUsedError;
  @JsonKey(name: 'exit_load_days')
  int? get exitLoadDays => throw _privateConstructorUsedError;
  @JsonKey(name: 'exit_load_pct')
  double? get exitLoadPct => throw _privateConstructorUsedError;
  @JsonKey(name: 'exit_load_free_pct')
  double get exitLoadFreePct => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this FolioDetailModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FolioDetailModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FolioDetailModelCopyWith<FolioDetailModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FolioDetailModelCopyWith<$Res> {
  factory $FolioDetailModelCopyWith(
          FolioDetailModel value, $Res Function(FolioDetailModel) then) =
      _$FolioDetailModelCopyWithImpl<$Res, FolioDetailModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'folio_number') String folioNumber,
      @JsonKey(name: 'amc_name') String? amcName,
      @JsonKey(name: 'scheme_name') String? schemeName,
      String? isin,
      String? pan,
      @JsonKey(name: 'kyc_status') String? kycStatus,
      @JsonKey(name: 'pan_status') String? panStatus,
      @JsonKey(name: 'investor_name') String? investorName,
      String? registrar,
      @JsonKey(name: 'advisor_code') String? advisorCode,
      @JsonKey(name: 'demat_status') String? dematStatus,
      @JsonKey(name: 'nominee_1') String? nominee1,
      @JsonKey(name: 'nominee_2') String? nominee2,
      @JsonKey(name: 'nominee_3') String? nominee3,
      @JsonKey(name: 'closing_units') double? closingUnits,
      @JsonKey(name: 'closing_nav') double? closingNav,
      @JsonKey(name: 'closing_nav_date') String? closingNavDate,
      @JsonKey(name: 'total_cost_value') double? totalCostValue,
      @JsonKey(name: 'market_value') double? marketValue,
      @JsonKey(name: 'exit_load_text') String? exitLoadText,
      @JsonKey(name: 'exit_load_days') int? exitLoadDays,
      @JsonKey(name: 'exit_load_pct') double? exitLoadPct,
      @JsonKey(name: 'exit_load_free_pct') double exitLoadFreePct,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt});
}

/// @nodoc
class _$FolioDetailModelCopyWithImpl<$Res, $Val extends FolioDetailModel>
    implements $FolioDetailModelCopyWith<$Res> {
  _$FolioDetailModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FolioDetailModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? memberId = freezed,
    Object? folioNumber = null,
    Object? amcName = freezed,
    Object? schemeName = freezed,
    Object? isin = freezed,
    Object? pan = freezed,
    Object? kycStatus = freezed,
    Object? panStatus = freezed,
    Object? investorName = freezed,
    Object? registrar = freezed,
    Object? advisorCode = freezed,
    Object? dematStatus = freezed,
    Object? nominee1 = freezed,
    Object? nominee2 = freezed,
    Object? nominee3 = freezed,
    Object? closingUnits = freezed,
    Object? closingNav = freezed,
    Object? closingNavDate = freezed,
    Object? totalCostValue = freezed,
    Object? marketValue = freezed,
    Object? exitLoadText = freezed,
    Object? exitLoadDays = freezed,
    Object? exitLoadPct = freezed,
    Object? exitLoadFreePct = null,
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
      memberId: freezed == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String?,
      folioNumber: null == folioNumber
          ? _value.folioNumber
          : folioNumber // ignore: cast_nullable_to_non_nullable
              as String,
      amcName: freezed == amcName
          ? _value.amcName
          : amcName // ignore: cast_nullable_to_non_nullable
              as String?,
      schemeName: freezed == schemeName
          ? _value.schemeName
          : schemeName // ignore: cast_nullable_to_non_nullable
              as String?,
      isin: freezed == isin
          ? _value.isin
          : isin // ignore: cast_nullable_to_non_nullable
              as String?,
      pan: freezed == pan
          ? _value.pan
          : pan // ignore: cast_nullable_to_non_nullable
              as String?,
      kycStatus: freezed == kycStatus
          ? _value.kycStatus
          : kycStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      panStatus: freezed == panStatus
          ? _value.panStatus
          : panStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      investorName: freezed == investorName
          ? _value.investorName
          : investorName // ignore: cast_nullable_to_non_nullable
              as String?,
      registrar: freezed == registrar
          ? _value.registrar
          : registrar // ignore: cast_nullable_to_non_nullable
              as String?,
      advisorCode: freezed == advisorCode
          ? _value.advisorCode
          : advisorCode // ignore: cast_nullable_to_non_nullable
              as String?,
      dematStatus: freezed == dematStatus
          ? _value.dematStatus
          : dematStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      nominee1: freezed == nominee1
          ? _value.nominee1
          : nominee1 // ignore: cast_nullable_to_non_nullable
              as String?,
      nominee2: freezed == nominee2
          ? _value.nominee2
          : nominee2 // ignore: cast_nullable_to_non_nullable
              as String?,
      nominee3: freezed == nominee3
          ? _value.nominee3
          : nominee3 // ignore: cast_nullable_to_non_nullable
              as String?,
      closingUnits: freezed == closingUnits
          ? _value.closingUnits
          : closingUnits // ignore: cast_nullable_to_non_nullable
              as double?,
      closingNav: freezed == closingNav
          ? _value.closingNav
          : closingNav // ignore: cast_nullable_to_non_nullable
              as double?,
      closingNavDate: freezed == closingNavDate
          ? _value.closingNavDate
          : closingNavDate // ignore: cast_nullable_to_non_nullable
              as String?,
      totalCostValue: freezed == totalCostValue
          ? _value.totalCostValue
          : totalCostValue // ignore: cast_nullable_to_non_nullable
              as double?,
      marketValue: freezed == marketValue
          ? _value.marketValue
          : marketValue // ignore: cast_nullable_to_non_nullable
              as double?,
      exitLoadText: freezed == exitLoadText
          ? _value.exitLoadText
          : exitLoadText // ignore: cast_nullable_to_non_nullable
              as String?,
      exitLoadDays: freezed == exitLoadDays
          ? _value.exitLoadDays
          : exitLoadDays // ignore: cast_nullable_to_non_nullable
              as int?,
      exitLoadPct: freezed == exitLoadPct
          ? _value.exitLoadPct
          : exitLoadPct // ignore: cast_nullable_to_non_nullable
              as double?,
      exitLoadFreePct: null == exitLoadFreePct
          ? _value.exitLoadFreePct
          : exitLoadFreePct // ignore: cast_nullable_to_non_nullable
              as double,
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
abstract class _$$FolioDetailModelImplCopyWith<$Res>
    implements $FolioDetailModelCopyWith<$Res> {
  factory _$$FolioDetailModelImplCopyWith(_$FolioDetailModelImpl value,
          $Res Function(_$FolioDetailModelImpl) then) =
      __$$FolioDetailModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'owner_id') String ownerId,
      @JsonKey(name: 'member_id') String? memberId,
      @JsonKey(name: 'folio_number') String folioNumber,
      @JsonKey(name: 'amc_name') String? amcName,
      @JsonKey(name: 'scheme_name') String? schemeName,
      String? isin,
      String? pan,
      @JsonKey(name: 'kyc_status') String? kycStatus,
      @JsonKey(name: 'pan_status') String? panStatus,
      @JsonKey(name: 'investor_name') String? investorName,
      String? registrar,
      @JsonKey(name: 'advisor_code') String? advisorCode,
      @JsonKey(name: 'demat_status') String? dematStatus,
      @JsonKey(name: 'nominee_1') String? nominee1,
      @JsonKey(name: 'nominee_2') String? nominee2,
      @JsonKey(name: 'nominee_3') String? nominee3,
      @JsonKey(name: 'closing_units') double? closingUnits,
      @JsonKey(name: 'closing_nav') double? closingNav,
      @JsonKey(name: 'closing_nav_date') String? closingNavDate,
      @JsonKey(name: 'total_cost_value') double? totalCostValue,
      @JsonKey(name: 'market_value') double? marketValue,
      @JsonKey(name: 'exit_load_text') String? exitLoadText,
      @JsonKey(name: 'exit_load_days') int? exitLoadDays,
      @JsonKey(name: 'exit_load_pct') double? exitLoadPct,
      @JsonKey(name: 'exit_load_free_pct') double exitLoadFreePct,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt});
}

/// @nodoc
class __$$FolioDetailModelImplCopyWithImpl<$Res>
    extends _$FolioDetailModelCopyWithImpl<$Res, _$FolioDetailModelImpl>
    implements _$$FolioDetailModelImplCopyWith<$Res> {
  __$$FolioDetailModelImplCopyWithImpl(_$FolioDetailModelImpl _value,
      $Res Function(_$FolioDetailModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of FolioDetailModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? memberId = freezed,
    Object? folioNumber = null,
    Object? amcName = freezed,
    Object? schemeName = freezed,
    Object? isin = freezed,
    Object? pan = freezed,
    Object? kycStatus = freezed,
    Object? panStatus = freezed,
    Object? investorName = freezed,
    Object? registrar = freezed,
    Object? advisorCode = freezed,
    Object? dematStatus = freezed,
    Object? nominee1 = freezed,
    Object? nominee2 = freezed,
    Object? nominee3 = freezed,
    Object? closingUnits = freezed,
    Object? closingNav = freezed,
    Object? closingNavDate = freezed,
    Object? totalCostValue = freezed,
    Object? marketValue = freezed,
    Object? exitLoadText = freezed,
    Object? exitLoadDays = freezed,
    Object? exitLoadPct = freezed,
    Object? exitLoadFreePct = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$FolioDetailModelImpl(
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
      folioNumber: null == folioNumber
          ? _value.folioNumber
          : folioNumber // ignore: cast_nullable_to_non_nullable
              as String,
      amcName: freezed == amcName
          ? _value.amcName
          : amcName // ignore: cast_nullable_to_non_nullable
              as String?,
      schemeName: freezed == schemeName
          ? _value.schemeName
          : schemeName // ignore: cast_nullable_to_non_nullable
              as String?,
      isin: freezed == isin
          ? _value.isin
          : isin // ignore: cast_nullable_to_non_nullable
              as String?,
      pan: freezed == pan
          ? _value.pan
          : pan // ignore: cast_nullable_to_non_nullable
              as String?,
      kycStatus: freezed == kycStatus
          ? _value.kycStatus
          : kycStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      panStatus: freezed == panStatus
          ? _value.panStatus
          : panStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      investorName: freezed == investorName
          ? _value.investorName
          : investorName // ignore: cast_nullable_to_non_nullable
              as String?,
      registrar: freezed == registrar
          ? _value.registrar
          : registrar // ignore: cast_nullable_to_non_nullable
              as String?,
      advisorCode: freezed == advisorCode
          ? _value.advisorCode
          : advisorCode // ignore: cast_nullable_to_non_nullable
              as String?,
      dematStatus: freezed == dematStatus
          ? _value.dematStatus
          : dematStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      nominee1: freezed == nominee1
          ? _value.nominee1
          : nominee1 // ignore: cast_nullable_to_non_nullable
              as String?,
      nominee2: freezed == nominee2
          ? _value.nominee2
          : nominee2 // ignore: cast_nullable_to_non_nullable
              as String?,
      nominee3: freezed == nominee3
          ? _value.nominee3
          : nominee3 // ignore: cast_nullable_to_non_nullable
              as String?,
      closingUnits: freezed == closingUnits
          ? _value.closingUnits
          : closingUnits // ignore: cast_nullable_to_non_nullable
              as double?,
      closingNav: freezed == closingNav
          ? _value.closingNav
          : closingNav // ignore: cast_nullable_to_non_nullable
              as double?,
      closingNavDate: freezed == closingNavDate
          ? _value.closingNavDate
          : closingNavDate // ignore: cast_nullable_to_non_nullable
              as String?,
      totalCostValue: freezed == totalCostValue
          ? _value.totalCostValue
          : totalCostValue // ignore: cast_nullable_to_non_nullable
              as double?,
      marketValue: freezed == marketValue
          ? _value.marketValue
          : marketValue // ignore: cast_nullable_to_non_nullable
              as double?,
      exitLoadText: freezed == exitLoadText
          ? _value.exitLoadText
          : exitLoadText // ignore: cast_nullable_to_non_nullable
              as String?,
      exitLoadDays: freezed == exitLoadDays
          ? _value.exitLoadDays
          : exitLoadDays // ignore: cast_nullable_to_non_nullable
              as int?,
      exitLoadPct: freezed == exitLoadPct
          ? _value.exitLoadPct
          : exitLoadPct // ignore: cast_nullable_to_non_nullable
              as double?,
      exitLoadFreePct: null == exitLoadFreePct
          ? _value.exitLoadFreePct
          : exitLoadFreePct // ignore: cast_nullable_to_non_nullable
              as double,
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
class _$FolioDetailModelImpl implements _FolioDetailModel {
  const _$FolioDetailModelImpl(
      {required this.id,
      @JsonKey(name: 'owner_id') required this.ownerId,
      @JsonKey(name: 'member_id') this.memberId,
      @JsonKey(name: 'folio_number') required this.folioNumber,
      @JsonKey(name: 'amc_name') this.amcName,
      @JsonKey(name: 'scheme_name') this.schemeName,
      this.isin,
      this.pan,
      @JsonKey(name: 'kyc_status') this.kycStatus,
      @JsonKey(name: 'pan_status') this.panStatus,
      @JsonKey(name: 'investor_name') this.investorName,
      this.registrar,
      @JsonKey(name: 'advisor_code') this.advisorCode,
      @JsonKey(name: 'demat_status') this.dematStatus,
      @JsonKey(name: 'nominee_1') this.nominee1,
      @JsonKey(name: 'nominee_2') this.nominee2,
      @JsonKey(name: 'nominee_3') this.nominee3,
      @JsonKey(name: 'closing_units') this.closingUnits,
      @JsonKey(name: 'closing_nav') this.closingNav,
      @JsonKey(name: 'closing_nav_date') this.closingNavDate,
      @JsonKey(name: 'total_cost_value') this.totalCostValue,
      @JsonKey(name: 'market_value') this.marketValue,
      @JsonKey(name: 'exit_load_text') this.exitLoadText,
      @JsonKey(name: 'exit_load_days') this.exitLoadDays,
      @JsonKey(name: 'exit_load_pct') this.exitLoadPct,
      @JsonKey(name: 'exit_load_free_pct') this.exitLoadFreePct = 0,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt});

  factory _$FolioDetailModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FolioDetailModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @override
  @JsonKey(name: 'member_id')
  final String? memberId;
  @override
  @JsonKey(name: 'folio_number')
  final String folioNumber;
  @override
  @JsonKey(name: 'amc_name')
  final String? amcName;
  @override
  @JsonKey(name: 'scheme_name')
  final String? schemeName;
  @override
  final String? isin;
  @override
  final String? pan;
  @override
  @JsonKey(name: 'kyc_status')
  final String? kycStatus;
  @override
  @JsonKey(name: 'pan_status')
  final String? panStatus;
  @override
  @JsonKey(name: 'investor_name')
  final String? investorName;
  @override
  final String? registrar;
  @override
  @JsonKey(name: 'advisor_code')
  final String? advisorCode;
  @override
  @JsonKey(name: 'demat_status')
  final String? dematStatus;
  @override
  @JsonKey(name: 'nominee_1')
  final String? nominee1;
  @override
  @JsonKey(name: 'nominee_2')
  final String? nominee2;
  @override
  @JsonKey(name: 'nominee_3')
  final String? nominee3;
  @override
  @JsonKey(name: 'closing_units')
  final double? closingUnits;
  @override
  @JsonKey(name: 'closing_nav')
  final double? closingNav;
  @override
  @JsonKey(name: 'closing_nav_date')
  final String? closingNavDate;
  @override
  @JsonKey(name: 'total_cost_value')
  final double? totalCostValue;
  @override
  @JsonKey(name: 'market_value')
  final double? marketValue;
  @override
  @JsonKey(name: 'exit_load_text')
  final String? exitLoadText;
  @override
  @JsonKey(name: 'exit_load_days')
  final int? exitLoadDays;
  @override
  @JsonKey(name: 'exit_load_pct')
  final double? exitLoadPct;
  @override
  @JsonKey(name: 'exit_load_free_pct')
  final double exitLoadFreePct;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  @override
  String toString() {
    return 'FolioDetailModel(id: $id, ownerId: $ownerId, memberId: $memberId, folioNumber: $folioNumber, amcName: $amcName, schemeName: $schemeName, isin: $isin, pan: $pan, kycStatus: $kycStatus, panStatus: $panStatus, investorName: $investorName, registrar: $registrar, advisorCode: $advisorCode, dematStatus: $dematStatus, nominee1: $nominee1, nominee2: $nominee2, nominee3: $nominee3, closingUnits: $closingUnits, closingNav: $closingNav, closingNavDate: $closingNavDate, totalCostValue: $totalCostValue, marketValue: $marketValue, exitLoadText: $exitLoadText, exitLoadDays: $exitLoadDays, exitLoadPct: $exitLoadPct, exitLoadFreePct: $exitLoadFreePct, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FolioDetailModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.folioNumber, folioNumber) ||
                other.folioNumber == folioNumber) &&
            (identical(other.amcName, amcName) || other.amcName == amcName) &&
            (identical(other.schemeName, schemeName) ||
                other.schemeName == schemeName) &&
            (identical(other.isin, isin) || other.isin == isin) &&
            (identical(other.pan, pan) || other.pan == pan) &&
            (identical(other.kycStatus, kycStatus) ||
                other.kycStatus == kycStatus) &&
            (identical(other.panStatus, panStatus) ||
                other.panStatus == panStatus) &&
            (identical(other.investorName, investorName) ||
                other.investorName == investorName) &&
            (identical(other.registrar, registrar) ||
                other.registrar == registrar) &&
            (identical(other.advisorCode, advisorCode) ||
                other.advisorCode == advisorCode) &&
            (identical(other.dematStatus, dematStatus) ||
                other.dematStatus == dematStatus) &&
            (identical(other.nominee1, nominee1) ||
                other.nominee1 == nominee1) &&
            (identical(other.nominee2, nominee2) ||
                other.nominee2 == nominee2) &&
            (identical(other.nominee3, nominee3) ||
                other.nominee3 == nominee3) &&
            (identical(other.closingUnits, closingUnits) ||
                other.closingUnits == closingUnits) &&
            (identical(other.closingNav, closingNav) ||
                other.closingNav == closingNav) &&
            (identical(other.closingNavDate, closingNavDate) ||
                other.closingNavDate == closingNavDate) &&
            (identical(other.totalCostValue, totalCostValue) ||
                other.totalCostValue == totalCostValue) &&
            (identical(other.marketValue, marketValue) ||
                other.marketValue == marketValue) &&
            (identical(other.exitLoadText, exitLoadText) ||
                other.exitLoadText == exitLoadText) &&
            (identical(other.exitLoadDays, exitLoadDays) ||
                other.exitLoadDays == exitLoadDays) &&
            (identical(other.exitLoadPct, exitLoadPct) ||
                other.exitLoadPct == exitLoadPct) &&
            (identical(other.exitLoadFreePct, exitLoadFreePct) ||
                other.exitLoadFreePct == exitLoadFreePct) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        ownerId,
        memberId,
        folioNumber,
        amcName,
        schemeName,
        isin,
        pan,
        kycStatus,
        panStatus,
        investorName,
        registrar,
        advisorCode,
        dematStatus,
        nominee1,
        nominee2,
        nominee3,
        closingUnits,
        closingNav,
        closingNavDate,
        totalCostValue,
        marketValue,
        exitLoadText,
        exitLoadDays,
        exitLoadPct,
        exitLoadFreePct,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of FolioDetailModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FolioDetailModelImplCopyWith<_$FolioDetailModelImpl> get copyWith =>
      __$$FolioDetailModelImplCopyWithImpl<_$FolioDetailModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FolioDetailModelImplToJson(
      this,
    );
  }
}

abstract class _FolioDetailModel implements FolioDetailModel {
  const factory _FolioDetailModel(
          {required final String id,
          @JsonKey(name: 'owner_id') required final String ownerId,
          @JsonKey(name: 'member_id') final String? memberId,
          @JsonKey(name: 'folio_number') required final String folioNumber,
          @JsonKey(name: 'amc_name') final String? amcName,
          @JsonKey(name: 'scheme_name') final String? schemeName,
          final String? isin,
          final String? pan,
          @JsonKey(name: 'kyc_status') final String? kycStatus,
          @JsonKey(name: 'pan_status') final String? panStatus,
          @JsonKey(name: 'investor_name') final String? investorName,
          final String? registrar,
          @JsonKey(name: 'advisor_code') final String? advisorCode,
          @JsonKey(name: 'demat_status') final String? dematStatus,
          @JsonKey(name: 'nominee_1') final String? nominee1,
          @JsonKey(name: 'nominee_2') final String? nominee2,
          @JsonKey(name: 'nominee_3') final String? nominee3,
          @JsonKey(name: 'closing_units') final double? closingUnits,
          @JsonKey(name: 'closing_nav') final double? closingNav,
          @JsonKey(name: 'closing_nav_date') final String? closingNavDate,
          @JsonKey(name: 'total_cost_value') final double? totalCostValue,
          @JsonKey(name: 'market_value') final double? marketValue,
          @JsonKey(name: 'exit_load_text') final String? exitLoadText,
          @JsonKey(name: 'exit_load_days') final int? exitLoadDays,
          @JsonKey(name: 'exit_load_pct') final double? exitLoadPct,
          @JsonKey(name: 'exit_load_free_pct') final double exitLoadFreePct,
          @JsonKey(name: 'created_at') final String? createdAt,
          @JsonKey(name: 'updated_at') final String? updatedAt}) =
      _$FolioDetailModelImpl;

  factory _FolioDetailModel.fromJson(Map<String, dynamic> json) =
      _$FolioDetailModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'owner_id')
  String get ownerId;
  @override
  @JsonKey(name: 'member_id')
  String? get memberId;
  @override
  @JsonKey(name: 'folio_number')
  String get folioNumber;
  @override
  @JsonKey(name: 'amc_name')
  String? get amcName;
  @override
  @JsonKey(name: 'scheme_name')
  String? get schemeName;
  @override
  String? get isin;
  @override
  String? get pan;
  @override
  @JsonKey(name: 'kyc_status')
  String? get kycStatus;
  @override
  @JsonKey(name: 'pan_status')
  String? get panStatus;
  @override
  @JsonKey(name: 'investor_name')
  String? get investorName;
  @override
  String? get registrar;
  @override
  @JsonKey(name: 'advisor_code')
  String? get advisorCode;
  @override
  @JsonKey(name: 'demat_status')
  String? get dematStatus;
  @override
  @JsonKey(name: 'nominee_1')
  String? get nominee1;
  @override
  @JsonKey(name: 'nominee_2')
  String? get nominee2;
  @override
  @JsonKey(name: 'nominee_3')
  String? get nominee3;
  @override
  @JsonKey(name: 'closing_units')
  double? get closingUnits;
  @override
  @JsonKey(name: 'closing_nav')
  double? get closingNav;
  @override
  @JsonKey(name: 'closing_nav_date')
  String? get closingNavDate;
  @override
  @JsonKey(name: 'total_cost_value')
  double? get totalCostValue;
  @override
  @JsonKey(name: 'market_value')
  double? get marketValue;
  @override
  @JsonKey(name: 'exit_load_text')
  String? get exitLoadText;
  @override
  @JsonKey(name: 'exit_load_days')
  int? get exitLoadDays;
  @override
  @JsonKey(name: 'exit_load_pct')
  double? get exitLoadPct;
  @override
  @JsonKey(name: 'exit_load_free_pct')
  double get exitLoadFreePct;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String? get updatedAt;

  /// Create a copy of FolioDetailModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FolioDetailModelImplCopyWith<_$FolioDetailModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
