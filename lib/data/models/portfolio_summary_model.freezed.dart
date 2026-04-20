// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portfolio_summary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PortfolioSummary _$PortfolioSummaryFromJson(Map<String, dynamic> json) {
  return _PortfolioSummary.fromJson(json);
}

/// @nodoc
mixin _$PortfolioSummary {
  /// null = family view; non-null = individual member
  String? get memberId => throw _privateConstructorUsedError;
  String? get memberName => throw _privateConstructorUsedError;
  double get totalInvested => throw _privateConstructorUsedError;
  double get currentValue => throw _privateConstructorUsedError;
  double get totalGain => throw _privateConstructorUsedError;
  double get gainPct => throw _privateConstructorUsedError;
  double? get xirr => throw _privateConstructorUsedError;
  double? get cagr => throw _privateConstructorUsedError;
  double get todayGain => throw _privateConstructorUsedError;
  double get todayGainPct => throw _privateConstructorUsedError;
  Map<String, double> get allocationPct =>
      throw _privateConstructorUsedError; // asset class → %
  Map<String, double> get allocationValue =>
      throw _privateConstructorUsedError; // asset class → Rs
  List<FundHoldingSummary> get fundHoldings =>
      throw _privateConstructorUsedError;
  List<MemberSummary> get memberBreakdown =>
      throw _privateConstructorUsedError; // for family view
  DateTime? get asOfDate => throw _privateConstructorUsedError;

  /// Serializes this PortfolioSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PortfolioSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PortfolioSummaryCopyWith<PortfolioSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PortfolioSummaryCopyWith<$Res> {
  factory $PortfolioSummaryCopyWith(
          PortfolioSummary value, $Res Function(PortfolioSummary) then) =
      _$PortfolioSummaryCopyWithImpl<$Res, PortfolioSummary>;
  @useResult
  $Res call(
      {String? memberId,
      String? memberName,
      double totalInvested,
      double currentValue,
      double totalGain,
      double gainPct,
      double? xirr,
      double? cagr,
      double todayGain,
      double todayGainPct,
      Map<String, double> allocationPct,
      Map<String, double> allocationValue,
      List<FundHoldingSummary> fundHoldings,
      List<MemberSummary> memberBreakdown,
      DateTime? asOfDate});
}

/// @nodoc
class _$PortfolioSummaryCopyWithImpl<$Res, $Val extends PortfolioSummary>
    implements $PortfolioSummaryCopyWith<$Res> {
  _$PortfolioSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PortfolioSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = freezed,
    Object? memberName = freezed,
    Object? totalInvested = null,
    Object? currentValue = null,
    Object? totalGain = null,
    Object? gainPct = null,
    Object? xirr = freezed,
    Object? cagr = freezed,
    Object? todayGain = null,
    Object? todayGainPct = null,
    Object? allocationPct = null,
    Object? allocationValue = null,
    Object? fundHoldings = null,
    Object? memberBreakdown = null,
    Object? asOfDate = freezed,
  }) {
    return _then(_value.copyWith(
      memberId: freezed == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String?,
      memberName: freezed == memberName
          ? _value.memberName
          : memberName // ignore: cast_nullable_to_non_nullable
              as String?,
      totalInvested: null == totalInvested
          ? _value.totalInvested
          : totalInvested // ignore: cast_nullable_to_non_nullable
              as double,
      currentValue: null == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double,
      totalGain: null == totalGain
          ? _value.totalGain
          : totalGain // ignore: cast_nullable_to_non_nullable
              as double,
      gainPct: null == gainPct
          ? _value.gainPct
          : gainPct // ignore: cast_nullable_to_non_nullable
              as double,
      xirr: freezed == xirr
          ? _value.xirr
          : xirr // ignore: cast_nullable_to_non_nullable
              as double?,
      cagr: freezed == cagr
          ? _value.cagr
          : cagr // ignore: cast_nullable_to_non_nullable
              as double?,
      todayGain: null == todayGain
          ? _value.todayGain
          : todayGain // ignore: cast_nullable_to_non_nullable
              as double,
      todayGainPct: null == todayGainPct
          ? _value.todayGainPct
          : todayGainPct // ignore: cast_nullable_to_non_nullable
              as double,
      allocationPct: null == allocationPct
          ? _value.allocationPct
          : allocationPct // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      allocationValue: null == allocationValue
          ? _value.allocationValue
          : allocationValue // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      fundHoldings: null == fundHoldings
          ? _value.fundHoldings
          : fundHoldings // ignore: cast_nullable_to_non_nullable
              as List<FundHoldingSummary>,
      memberBreakdown: null == memberBreakdown
          ? _value.memberBreakdown
          : memberBreakdown // ignore: cast_nullable_to_non_nullable
              as List<MemberSummary>,
      asOfDate: freezed == asOfDate
          ? _value.asOfDate
          : asOfDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PortfolioSummaryImplCopyWith<$Res>
    implements $PortfolioSummaryCopyWith<$Res> {
  factory _$$PortfolioSummaryImplCopyWith(_$PortfolioSummaryImpl value,
          $Res Function(_$PortfolioSummaryImpl) then) =
      __$$PortfolioSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? memberId,
      String? memberName,
      double totalInvested,
      double currentValue,
      double totalGain,
      double gainPct,
      double? xirr,
      double? cagr,
      double todayGain,
      double todayGainPct,
      Map<String, double> allocationPct,
      Map<String, double> allocationValue,
      List<FundHoldingSummary> fundHoldings,
      List<MemberSummary> memberBreakdown,
      DateTime? asOfDate});
}

/// @nodoc
class __$$PortfolioSummaryImplCopyWithImpl<$Res>
    extends _$PortfolioSummaryCopyWithImpl<$Res, _$PortfolioSummaryImpl>
    implements _$$PortfolioSummaryImplCopyWith<$Res> {
  __$$PortfolioSummaryImplCopyWithImpl(_$PortfolioSummaryImpl _value,
      $Res Function(_$PortfolioSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of PortfolioSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = freezed,
    Object? memberName = freezed,
    Object? totalInvested = null,
    Object? currentValue = null,
    Object? totalGain = null,
    Object? gainPct = null,
    Object? xirr = freezed,
    Object? cagr = freezed,
    Object? todayGain = null,
    Object? todayGainPct = null,
    Object? allocationPct = null,
    Object? allocationValue = null,
    Object? fundHoldings = null,
    Object? memberBreakdown = null,
    Object? asOfDate = freezed,
  }) {
    return _then(_$PortfolioSummaryImpl(
      memberId: freezed == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String?,
      memberName: freezed == memberName
          ? _value.memberName
          : memberName // ignore: cast_nullable_to_non_nullable
              as String?,
      totalInvested: null == totalInvested
          ? _value.totalInvested
          : totalInvested // ignore: cast_nullable_to_non_nullable
              as double,
      currentValue: null == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double,
      totalGain: null == totalGain
          ? _value.totalGain
          : totalGain // ignore: cast_nullable_to_non_nullable
              as double,
      gainPct: null == gainPct
          ? _value.gainPct
          : gainPct // ignore: cast_nullable_to_non_nullable
              as double,
      xirr: freezed == xirr
          ? _value.xirr
          : xirr // ignore: cast_nullable_to_non_nullable
              as double?,
      cagr: freezed == cagr
          ? _value.cagr
          : cagr // ignore: cast_nullable_to_non_nullable
              as double?,
      todayGain: null == todayGain
          ? _value.todayGain
          : todayGain // ignore: cast_nullable_to_non_nullable
              as double,
      todayGainPct: null == todayGainPct
          ? _value.todayGainPct
          : todayGainPct // ignore: cast_nullable_to_non_nullable
              as double,
      allocationPct: null == allocationPct
          ? _value._allocationPct
          : allocationPct // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      allocationValue: null == allocationValue
          ? _value._allocationValue
          : allocationValue // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      fundHoldings: null == fundHoldings
          ? _value._fundHoldings
          : fundHoldings // ignore: cast_nullable_to_non_nullable
              as List<FundHoldingSummary>,
      memberBreakdown: null == memberBreakdown
          ? _value._memberBreakdown
          : memberBreakdown // ignore: cast_nullable_to_non_nullable
              as List<MemberSummary>,
      asOfDate: freezed == asOfDate
          ? _value.asOfDate
          : asOfDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PortfolioSummaryImpl extends _PortfolioSummary {
  const _$PortfolioSummaryImpl(
      {this.memberId,
      this.memberName,
      this.totalInvested = 0,
      this.currentValue = 0,
      this.totalGain = 0,
      this.gainPct = 0,
      this.xirr,
      this.cagr,
      this.todayGain = 0,
      this.todayGainPct = 0,
      final Map<String, double> allocationPct = const {},
      final Map<String, double> allocationValue = const {},
      final List<FundHoldingSummary> fundHoldings = const [],
      final List<MemberSummary> memberBreakdown = const [],
      this.asOfDate})
      : _allocationPct = allocationPct,
        _allocationValue = allocationValue,
        _fundHoldings = fundHoldings,
        _memberBreakdown = memberBreakdown,
        super._();

  factory _$PortfolioSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$PortfolioSummaryImplFromJson(json);

  /// null = family view; non-null = individual member
  @override
  final String? memberId;
  @override
  final String? memberName;
  @override
  @JsonKey()
  final double totalInvested;
  @override
  @JsonKey()
  final double currentValue;
  @override
  @JsonKey()
  final double totalGain;
  @override
  @JsonKey()
  final double gainPct;
  @override
  final double? xirr;
  @override
  final double? cagr;
  @override
  @JsonKey()
  final double todayGain;
  @override
  @JsonKey()
  final double todayGainPct;
  final Map<String, double> _allocationPct;
  @override
  @JsonKey()
  Map<String, double> get allocationPct {
    if (_allocationPct is EqualUnmodifiableMapView) return _allocationPct;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_allocationPct);
  }

// asset class → %
  final Map<String, double> _allocationValue;
// asset class → %
  @override
  @JsonKey()
  Map<String, double> get allocationValue {
    if (_allocationValue is EqualUnmodifiableMapView) return _allocationValue;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_allocationValue);
  }

// asset class → Rs
  final List<FundHoldingSummary> _fundHoldings;
// asset class → Rs
  @override
  @JsonKey()
  List<FundHoldingSummary> get fundHoldings {
    if (_fundHoldings is EqualUnmodifiableListView) return _fundHoldings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_fundHoldings);
  }

  final List<MemberSummary> _memberBreakdown;
  @override
  @JsonKey()
  List<MemberSummary> get memberBreakdown {
    if (_memberBreakdown is EqualUnmodifiableListView) return _memberBreakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_memberBreakdown);
  }

// for family view
  @override
  final DateTime? asOfDate;

  @override
  String toString() {
    return 'PortfolioSummary(memberId: $memberId, memberName: $memberName, totalInvested: $totalInvested, currentValue: $currentValue, totalGain: $totalGain, gainPct: $gainPct, xirr: $xirr, cagr: $cagr, todayGain: $todayGain, todayGainPct: $todayGainPct, allocationPct: $allocationPct, allocationValue: $allocationValue, fundHoldings: $fundHoldings, memberBreakdown: $memberBreakdown, asOfDate: $asOfDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PortfolioSummaryImpl &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.memberName, memberName) ||
                other.memberName == memberName) &&
            (identical(other.totalInvested, totalInvested) ||
                other.totalInvested == totalInvested) &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue) &&
            (identical(other.totalGain, totalGain) ||
                other.totalGain == totalGain) &&
            (identical(other.gainPct, gainPct) || other.gainPct == gainPct) &&
            (identical(other.xirr, xirr) || other.xirr == xirr) &&
            (identical(other.cagr, cagr) || other.cagr == cagr) &&
            (identical(other.todayGain, todayGain) ||
                other.todayGain == todayGain) &&
            (identical(other.todayGainPct, todayGainPct) ||
                other.todayGainPct == todayGainPct) &&
            const DeepCollectionEquality()
                .equals(other._allocationPct, _allocationPct) &&
            const DeepCollectionEquality()
                .equals(other._allocationValue, _allocationValue) &&
            const DeepCollectionEquality()
                .equals(other._fundHoldings, _fundHoldings) &&
            const DeepCollectionEquality()
                .equals(other._memberBreakdown, _memberBreakdown) &&
            (identical(other.asOfDate, asOfDate) ||
                other.asOfDate == asOfDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      memberId,
      memberName,
      totalInvested,
      currentValue,
      totalGain,
      gainPct,
      xirr,
      cagr,
      todayGain,
      todayGainPct,
      const DeepCollectionEquality().hash(_allocationPct),
      const DeepCollectionEquality().hash(_allocationValue),
      const DeepCollectionEquality().hash(_fundHoldings),
      const DeepCollectionEquality().hash(_memberBreakdown),
      asOfDate);

  /// Create a copy of PortfolioSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PortfolioSummaryImplCopyWith<_$PortfolioSummaryImpl> get copyWith =>
      __$$PortfolioSummaryImplCopyWithImpl<_$PortfolioSummaryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PortfolioSummaryImplToJson(
      this,
    );
  }
}

abstract class _PortfolioSummary extends PortfolioSummary {
  const factory _PortfolioSummary(
      {final String? memberId,
      final String? memberName,
      final double totalInvested,
      final double currentValue,
      final double totalGain,
      final double gainPct,
      final double? xirr,
      final double? cagr,
      final double todayGain,
      final double todayGainPct,
      final Map<String, double> allocationPct,
      final Map<String, double> allocationValue,
      final List<FundHoldingSummary> fundHoldings,
      final List<MemberSummary> memberBreakdown,
      final DateTime? asOfDate}) = _$PortfolioSummaryImpl;
  const _PortfolioSummary._() : super._();

  factory _PortfolioSummary.fromJson(Map<String, dynamic> json) =
      _$PortfolioSummaryImpl.fromJson;

  /// null = family view; non-null = individual member
  @override
  String? get memberId;
  @override
  String? get memberName;
  @override
  double get totalInvested;
  @override
  double get currentValue;
  @override
  double get totalGain;
  @override
  double get gainPct;
  @override
  double? get xirr;
  @override
  double? get cagr;
  @override
  double get todayGain;
  @override
  double get todayGainPct;
  @override
  Map<String, double> get allocationPct; // asset class → %
  @override
  Map<String, double> get allocationValue; // asset class → Rs
  @override
  List<FundHoldingSummary> get fundHoldings;
  @override
  List<MemberSummary> get memberBreakdown; // for family view
  @override
  DateTime? get asOfDate;

  /// Create a copy of PortfolioSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PortfolioSummaryImplCopyWith<_$PortfolioSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FundHoldingSummary _$FundHoldingSummaryFromJson(Map<String, dynamic> json) {
  return _FundHoldingSummary.fromJson(json);
}

/// @nodoc
mixin _$FundHoldingSummary {
  int get amfiCode => throw _privateConstructorUsedError;
  String get fundName => throw _privateConstructorUsedError;
  String get assetType =>
      throw _privateConstructorUsedError; // DB value: MF, Stock, Gold, etc.
  String? get category => throw _privateConstructorUsedError;
  String? get taxCategory => throw _privateConstructorUsedError;
  String? get assetClassLabel => throw _privateConstructorUsedError;
  double get totalUnits => throw _privateConstructorUsedError;
  double get totalInvested => throw _privateConstructorUsedError;
  double get currentValue => throw _privateConstructorUsedError;
  double get gain => throw _privateConstructorUsedError;
  double get gainPct => throw _privateConstructorUsedError;
  double? get cagr => throw _privateConstructorUsedError;
  double? get xirr => throw _privateConstructorUsedError;
  double? get latestNav => throw _privateConstructorUsedError;
  double? get nav1dChangePct => throw _privateConstructorUsedError;
  double get todayGain =>
      throw _privateConstructorUsedError; // units × (nav - prevNav)
  bool get isCoreFund =>
      throw _privateConstructorUsedError; // CORE vs SATELLITE
// ── AMFI / SEBI 2018 categorisation ──
  String? get amfiCategoryId => throw _privateConstructorUsedError;
  String? get benchmarkTier1 => throw _privateConstructorUsedError;
  String? get benchmarkTier2 => throw _privateConstructorUsedError;
  List<HolderFundSummary> get holderBreakdown =>
      throw _privateConstructorUsedError; // ── Investor details ──
  DateTime? get investedSince => throw _privateConstructorUsedError;
  String? get planType => throw _privateConstructorUsedError;
  double? get expenseRatio => throw _privateConstructorUsedError;
  double? get return1y => throw _privateConstructorUsedError;

  /// Serializes this FundHoldingSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FundHoldingSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FundHoldingSummaryCopyWith<FundHoldingSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FundHoldingSummaryCopyWith<$Res> {
  factory $FundHoldingSummaryCopyWith(
          FundHoldingSummary value, $Res Function(FundHoldingSummary) then) =
      _$FundHoldingSummaryCopyWithImpl<$Res, FundHoldingSummary>;
  @useResult
  $Res call(
      {int amfiCode,
      String fundName,
      String assetType,
      String? category,
      String? taxCategory,
      String? assetClassLabel,
      double totalUnits,
      double totalInvested,
      double currentValue,
      double gain,
      double gainPct,
      double? cagr,
      double? xirr,
      double? latestNav,
      double? nav1dChangePct,
      double todayGain,
      bool isCoreFund,
      String? amfiCategoryId,
      String? benchmarkTier1,
      String? benchmarkTier2,
      List<HolderFundSummary> holderBreakdown,
      DateTime? investedSince,
      String? planType,
      double? expenseRatio,
      double? return1y});
}

/// @nodoc
class _$FundHoldingSummaryCopyWithImpl<$Res, $Val extends FundHoldingSummary>
    implements $FundHoldingSummaryCopyWith<$Res> {
  _$FundHoldingSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FundHoldingSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? amfiCode = null,
    Object? fundName = null,
    Object? assetType = null,
    Object? category = freezed,
    Object? taxCategory = freezed,
    Object? assetClassLabel = freezed,
    Object? totalUnits = null,
    Object? totalInvested = null,
    Object? currentValue = null,
    Object? gain = null,
    Object? gainPct = null,
    Object? cagr = freezed,
    Object? xirr = freezed,
    Object? latestNav = freezed,
    Object? nav1dChangePct = freezed,
    Object? todayGain = null,
    Object? isCoreFund = null,
    Object? amfiCategoryId = freezed,
    Object? benchmarkTier1 = freezed,
    Object? benchmarkTier2 = freezed,
    Object? holderBreakdown = null,
    Object? investedSince = freezed,
    Object? planType = freezed,
    Object? expenseRatio = freezed,
    Object? return1y = freezed,
  }) {
    return _then(_value.copyWith(
      amfiCode: null == amfiCode
          ? _value.amfiCode
          : amfiCode // ignore: cast_nullable_to_non_nullable
              as int,
      fundName: null == fundName
          ? _value.fundName
          : fundName // ignore: cast_nullable_to_non_nullable
              as String,
      assetType: null == assetType
          ? _value.assetType
          : assetType // ignore: cast_nullable_to_non_nullable
              as String,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      taxCategory: freezed == taxCategory
          ? _value.taxCategory
          : taxCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      assetClassLabel: freezed == assetClassLabel
          ? _value.assetClassLabel
          : assetClassLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      totalUnits: null == totalUnits
          ? _value.totalUnits
          : totalUnits // ignore: cast_nullable_to_non_nullable
              as double,
      totalInvested: null == totalInvested
          ? _value.totalInvested
          : totalInvested // ignore: cast_nullable_to_non_nullable
              as double,
      currentValue: null == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double,
      gain: null == gain
          ? _value.gain
          : gain // ignore: cast_nullable_to_non_nullable
              as double,
      gainPct: null == gainPct
          ? _value.gainPct
          : gainPct // ignore: cast_nullable_to_non_nullable
              as double,
      cagr: freezed == cagr
          ? _value.cagr
          : cagr // ignore: cast_nullable_to_non_nullable
              as double?,
      xirr: freezed == xirr
          ? _value.xirr
          : xirr // ignore: cast_nullable_to_non_nullable
              as double?,
      latestNav: freezed == latestNav
          ? _value.latestNav
          : latestNav // ignore: cast_nullable_to_non_nullable
              as double?,
      nav1dChangePct: freezed == nav1dChangePct
          ? _value.nav1dChangePct
          : nav1dChangePct // ignore: cast_nullable_to_non_nullable
              as double?,
      todayGain: null == todayGain
          ? _value.todayGain
          : todayGain // ignore: cast_nullable_to_non_nullable
              as double,
      isCoreFund: null == isCoreFund
          ? _value.isCoreFund
          : isCoreFund // ignore: cast_nullable_to_non_nullable
              as bool,
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
      holderBreakdown: null == holderBreakdown
          ? _value.holderBreakdown
          : holderBreakdown // ignore: cast_nullable_to_non_nullable
              as List<HolderFundSummary>,
      investedSince: freezed == investedSince
          ? _value.investedSince
          : investedSince // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FundHoldingSummaryImplCopyWith<$Res>
    implements $FundHoldingSummaryCopyWith<$Res> {
  factory _$$FundHoldingSummaryImplCopyWith(_$FundHoldingSummaryImpl value,
          $Res Function(_$FundHoldingSummaryImpl) then) =
      __$$FundHoldingSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int amfiCode,
      String fundName,
      String assetType,
      String? category,
      String? taxCategory,
      String? assetClassLabel,
      double totalUnits,
      double totalInvested,
      double currentValue,
      double gain,
      double gainPct,
      double? cagr,
      double? xirr,
      double? latestNav,
      double? nav1dChangePct,
      double todayGain,
      bool isCoreFund,
      String? amfiCategoryId,
      String? benchmarkTier1,
      String? benchmarkTier2,
      List<HolderFundSummary> holderBreakdown,
      DateTime? investedSince,
      String? planType,
      double? expenseRatio,
      double? return1y});
}

/// @nodoc
class __$$FundHoldingSummaryImplCopyWithImpl<$Res>
    extends _$FundHoldingSummaryCopyWithImpl<$Res, _$FundHoldingSummaryImpl>
    implements _$$FundHoldingSummaryImplCopyWith<$Res> {
  __$$FundHoldingSummaryImplCopyWithImpl(_$FundHoldingSummaryImpl _value,
      $Res Function(_$FundHoldingSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of FundHoldingSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? amfiCode = null,
    Object? fundName = null,
    Object? assetType = null,
    Object? category = freezed,
    Object? taxCategory = freezed,
    Object? assetClassLabel = freezed,
    Object? totalUnits = null,
    Object? totalInvested = null,
    Object? currentValue = null,
    Object? gain = null,
    Object? gainPct = null,
    Object? cagr = freezed,
    Object? xirr = freezed,
    Object? latestNav = freezed,
    Object? nav1dChangePct = freezed,
    Object? todayGain = null,
    Object? isCoreFund = null,
    Object? amfiCategoryId = freezed,
    Object? benchmarkTier1 = freezed,
    Object? benchmarkTier2 = freezed,
    Object? holderBreakdown = null,
    Object? investedSince = freezed,
    Object? planType = freezed,
    Object? expenseRatio = freezed,
    Object? return1y = freezed,
  }) {
    return _then(_$FundHoldingSummaryImpl(
      amfiCode: null == amfiCode
          ? _value.amfiCode
          : amfiCode // ignore: cast_nullable_to_non_nullable
              as int,
      fundName: null == fundName
          ? _value.fundName
          : fundName // ignore: cast_nullable_to_non_nullable
              as String,
      assetType: null == assetType
          ? _value.assetType
          : assetType // ignore: cast_nullable_to_non_nullable
              as String,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      taxCategory: freezed == taxCategory
          ? _value.taxCategory
          : taxCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      assetClassLabel: freezed == assetClassLabel
          ? _value.assetClassLabel
          : assetClassLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      totalUnits: null == totalUnits
          ? _value.totalUnits
          : totalUnits // ignore: cast_nullable_to_non_nullable
              as double,
      totalInvested: null == totalInvested
          ? _value.totalInvested
          : totalInvested // ignore: cast_nullable_to_non_nullable
              as double,
      currentValue: null == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double,
      gain: null == gain
          ? _value.gain
          : gain // ignore: cast_nullable_to_non_nullable
              as double,
      gainPct: null == gainPct
          ? _value.gainPct
          : gainPct // ignore: cast_nullable_to_non_nullable
              as double,
      cagr: freezed == cagr
          ? _value.cagr
          : cagr // ignore: cast_nullable_to_non_nullable
              as double?,
      xirr: freezed == xirr
          ? _value.xirr
          : xirr // ignore: cast_nullable_to_non_nullable
              as double?,
      latestNav: freezed == latestNav
          ? _value.latestNav
          : latestNav // ignore: cast_nullable_to_non_nullable
              as double?,
      nav1dChangePct: freezed == nav1dChangePct
          ? _value.nav1dChangePct
          : nav1dChangePct // ignore: cast_nullable_to_non_nullable
              as double?,
      todayGain: null == todayGain
          ? _value.todayGain
          : todayGain // ignore: cast_nullable_to_non_nullable
              as double,
      isCoreFund: null == isCoreFund
          ? _value.isCoreFund
          : isCoreFund // ignore: cast_nullable_to_non_nullable
              as bool,
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
      holderBreakdown: null == holderBreakdown
          ? _value._holderBreakdown
          : holderBreakdown // ignore: cast_nullable_to_non_nullable
              as List<HolderFundSummary>,
      investedSince: freezed == investedSince
          ? _value.investedSince
          : investedSince // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FundHoldingSummaryImpl extends _FundHoldingSummary {
  const _$FundHoldingSummaryImpl(
      {required this.amfiCode,
      required this.fundName,
      this.assetType = 'MF',
      this.category,
      this.taxCategory,
      this.assetClassLabel,
      this.totalUnits = 0,
      this.totalInvested = 0,
      this.currentValue = 0,
      this.gain = 0,
      this.gainPct = 0,
      this.cagr,
      this.xirr,
      this.latestNav,
      this.nav1dChangePct,
      this.todayGain = 0,
      this.isCoreFund = false,
      this.amfiCategoryId,
      this.benchmarkTier1,
      this.benchmarkTier2,
      final List<HolderFundSummary> holderBreakdown = const [],
      this.investedSince,
      this.planType,
      this.expenseRatio,
      this.return1y})
      : _holderBreakdown = holderBreakdown,
        super._();

  factory _$FundHoldingSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$FundHoldingSummaryImplFromJson(json);

  @override
  final int amfiCode;
  @override
  final String fundName;
  @override
  @JsonKey()
  final String assetType;
// DB value: MF, Stock, Gold, etc.
  @override
  final String? category;
  @override
  final String? taxCategory;
  @override
  final String? assetClassLabel;
  @override
  @JsonKey()
  final double totalUnits;
  @override
  @JsonKey()
  final double totalInvested;
  @override
  @JsonKey()
  final double currentValue;
  @override
  @JsonKey()
  final double gain;
  @override
  @JsonKey()
  final double gainPct;
  @override
  final double? cagr;
  @override
  final double? xirr;
  @override
  final double? latestNav;
  @override
  final double? nav1dChangePct;
  @override
  @JsonKey()
  final double todayGain;
// units × (nav - prevNav)
  @override
  @JsonKey()
  final bool isCoreFund;
// CORE vs SATELLITE
// ── AMFI / SEBI 2018 categorisation ──
  @override
  final String? amfiCategoryId;
  @override
  final String? benchmarkTier1;
  @override
  final String? benchmarkTier2;
  final List<HolderFundSummary> _holderBreakdown;
  @override
  @JsonKey()
  List<HolderFundSummary> get holderBreakdown {
    if (_holderBreakdown is EqualUnmodifiableListView) return _holderBreakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_holderBreakdown);
  }

// ── Investor details ──
  @override
  final DateTime? investedSince;
  @override
  final String? planType;
  @override
  final double? expenseRatio;
  @override
  final double? return1y;

  @override
  String toString() {
    return 'FundHoldingSummary(amfiCode: $amfiCode, fundName: $fundName, assetType: $assetType, category: $category, taxCategory: $taxCategory, assetClassLabel: $assetClassLabel, totalUnits: $totalUnits, totalInvested: $totalInvested, currentValue: $currentValue, gain: $gain, gainPct: $gainPct, cagr: $cagr, xirr: $xirr, latestNav: $latestNav, nav1dChangePct: $nav1dChangePct, todayGain: $todayGain, isCoreFund: $isCoreFund, amfiCategoryId: $amfiCategoryId, benchmarkTier1: $benchmarkTier1, benchmarkTier2: $benchmarkTier2, holderBreakdown: $holderBreakdown, investedSince: $investedSince, planType: $planType, expenseRatio: $expenseRatio, return1y: $return1y)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FundHoldingSummaryImpl &&
            (identical(other.amfiCode, amfiCode) ||
                other.amfiCode == amfiCode) &&
            (identical(other.fundName, fundName) ||
                other.fundName == fundName) &&
            (identical(other.assetType, assetType) ||
                other.assetType == assetType) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.taxCategory, taxCategory) ||
                other.taxCategory == taxCategory) &&
            (identical(other.assetClassLabel, assetClassLabel) ||
                other.assetClassLabel == assetClassLabel) &&
            (identical(other.totalUnits, totalUnits) ||
                other.totalUnits == totalUnits) &&
            (identical(other.totalInvested, totalInvested) ||
                other.totalInvested == totalInvested) &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue) &&
            (identical(other.gain, gain) || other.gain == gain) &&
            (identical(other.gainPct, gainPct) || other.gainPct == gainPct) &&
            (identical(other.cagr, cagr) || other.cagr == cagr) &&
            (identical(other.xirr, xirr) || other.xirr == xirr) &&
            (identical(other.latestNav, latestNav) ||
                other.latestNav == latestNav) &&
            (identical(other.nav1dChangePct, nav1dChangePct) ||
                other.nav1dChangePct == nav1dChangePct) &&
            (identical(other.todayGain, todayGain) ||
                other.todayGain == todayGain) &&
            (identical(other.isCoreFund, isCoreFund) ||
                other.isCoreFund == isCoreFund) &&
            (identical(other.amfiCategoryId, amfiCategoryId) ||
                other.amfiCategoryId == amfiCategoryId) &&
            (identical(other.benchmarkTier1, benchmarkTier1) ||
                other.benchmarkTier1 == benchmarkTier1) &&
            (identical(other.benchmarkTier2, benchmarkTier2) ||
                other.benchmarkTier2 == benchmarkTier2) &&
            const DeepCollectionEquality()
                .equals(other._holderBreakdown, _holderBreakdown) &&
            (identical(other.investedSince, investedSince) ||
                other.investedSince == investedSince) &&
            (identical(other.planType, planType) ||
                other.planType == planType) &&
            (identical(other.expenseRatio, expenseRatio) ||
                other.expenseRatio == expenseRatio) &&
            (identical(other.return1y, return1y) ||
                other.return1y == return1y));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        amfiCode,
        fundName,
        assetType,
        category,
        taxCategory,
        assetClassLabel,
        totalUnits,
        totalInvested,
        currentValue,
        gain,
        gainPct,
        cagr,
        xirr,
        latestNav,
        nav1dChangePct,
        todayGain,
        isCoreFund,
        amfiCategoryId,
        benchmarkTier1,
        benchmarkTier2,
        const DeepCollectionEquality().hash(_holderBreakdown),
        investedSince,
        planType,
        expenseRatio,
        return1y
      ]);

  /// Create a copy of FundHoldingSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FundHoldingSummaryImplCopyWith<_$FundHoldingSummaryImpl> get copyWith =>
      __$$FundHoldingSummaryImplCopyWithImpl<_$FundHoldingSummaryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FundHoldingSummaryImplToJson(
      this,
    );
  }
}

abstract class _FundHoldingSummary extends FundHoldingSummary {
  const factory _FundHoldingSummary(
      {required final int amfiCode,
      required final String fundName,
      final String assetType,
      final String? category,
      final String? taxCategory,
      final String? assetClassLabel,
      final double totalUnits,
      final double totalInvested,
      final double currentValue,
      final double gain,
      final double gainPct,
      final double? cagr,
      final double? xirr,
      final double? latestNav,
      final double? nav1dChangePct,
      final double todayGain,
      final bool isCoreFund,
      final String? amfiCategoryId,
      final String? benchmarkTier1,
      final String? benchmarkTier2,
      final List<HolderFundSummary> holderBreakdown,
      final DateTime? investedSince,
      final String? planType,
      final double? expenseRatio,
      final double? return1y}) = _$FundHoldingSummaryImpl;
  const _FundHoldingSummary._() : super._();

  factory _FundHoldingSummary.fromJson(Map<String, dynamic> json) =
      _$FundHoldingSummaryImpl.fromJson;

  @override
  int get amfiCode;
  @override
  String get fundName;
  @override
  String get assetType; // DB value: MF, Stock, Gold, etc.
  @override
  String? get category;
  @override
  String? get taxCategory;
  @override
  String? get assetClassLabel;
  @override
  double get totalUnits;
  @override
  double get totalInvested;
  @override
  double get currentValue;
  @override
  double get gain;
  @override
  double get gainPct;
  @override
  double? get cagr;
  @override
  double? get xirr;
  @override
  double? get latestNav;
  @override
  double? get nav1dChangePct;
  @override
  double get todayGain; // units × (nav - prevNav)
  @override
  bool get isCoreFund; // CORE vs SATELLITE
// ── AMFI / SEBI 2018 categorisation ──
  @override
  String? get amfiCategoryId;
  @override
  String? get benchmarkTier1;
  @override
  String? get benchmarkTier2;
  @override
  List<HolderFundSummary> get holderBreakdown; // ── Investor details ──
  @override
  DateTime? get investedSince;
  @override
  String? get planType;
  @override
  double? get expenseRatio;
  @override
  double? get return1y;

  /// Create a copy of FundHoldingSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FundHoldingSummaryImplCopyWith<_$FundHoldingSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HolderFundSummary _$HolderFundSummaryFromJson(Map<String, dynamic> json) {
  return _HolderFundSummary.fromJson(json);
}

/// @nodoc
mixin _$HolderFundSummary {
  String get memberId => throw _privateConstructorUsedError;
  String get memberName => throw _privateConstructorUsedError;
  double get units => throw _privateConstructorUsedError;
  double get invested => throw _privateConstructorUsedError;
  double get currentValue => throw _privateConstructorUsedError;
  double get gain => throw _privateConstructorUsedError;
  double? get cagr => throw _privateConstructorUsedError;
  double? get xirr => throw _privateConstructorUsedError;
  String? get folioNumber => throw _privateConstructorUsedError;

  /// Serializes this HolderFundSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HolderFundSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HolderFundSummaryCopyWith<HolderFundSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HolderFundSummaryCopyWith<$Res> {
  factory $HolderFundSummaryCopyWith(
          HolderFundSummary value, $Res Function(HolderFundSummary) then) =
      _$HolderFundSummaryCopyWithImpl<$Res, HolderFundSummary>;
  @useResult
  $Res call(
      {String memberId,
      String memberName,
      double units,
      double invested,
      double currentValue,
      double gain,
      double? cagr,
      double? xirr,
      String? folioNumber});
}

/// @nodoc
class _$HolderFundSummaryCopyWithImpl<$Res, $Val extends HolderFundSummary>
    implements $HolderFundSummaryCopyWith<$Res> {
  _$HolderFundSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HolderFundSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? memberName = null,
    Object? units = null,
    Object? invested = null,
    Object? currentValue = null,
    Object? gain = null,
    Object? cagr = freezed,
    Object? xirr = freezed,
    Object? folioNumber = freezed,
  }) {
    return _then(_value.copyWith(
      memberId: null == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String,
      memberName: null == memberName
          ? _value.memberName
          : memberName // ignore: cast_nullable_to_non_nullable
              as String,
      units: null == units
          ? _value.units
          : units // ignore: cast_nullable_to_non_nullable
              as double,
      invested: null == invested
          ? _value.invested
          : invested // ignore: cast_nullable_to_non_nullable
              as double,
      currentValue: null == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double,
      gain: null == gain
          ? _value.gain
          : gain // ignore: cast_nullable_to_non_nullable
              as double,
      cagr: freezed == cagr
          ? _value.cagr
          : cagr // ignore: cast_nullable_to_non_nullable
              as double?,
      xirr: freezed == xirr
          ? _value.xirr
          : xirr // ignore: cast_nullable_to_non_nullable
              as double?,
      folioNumber: freezed == folioNumber
          ? _value.folioNumber
          : folioNumber // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HolderFundSummaryImplCopyWith<$Res>
    implements $HolderFundSummaryCopyWith<$Res> {
  factory _$$HolderFundSummaryImplCopyWith(_$HolderFundSummaryImpl value,
          $Res Function(_$HolderFundSummaryImpl) then) =
      __$$HolderFundSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String memberId,
      String memberName,
      double units,
      double invested,
      double currentValue,
      double gain,
      double? cagr,
      double? xirr,
      String? folioNumber});
}

/// @nodoc
class __$$HolderFundSummaryImplCopyWithImpl<$Res>
    extends _$HolderFundSummaryCopyWithImpl<$Res, _$HolderFundSummaryImpl>
    implements _$$HolderFundSummaryImplCopyWith<$Res> {
  __$$HolderFundSummaryImplCopyWithImpl(_$HolderFundSummaryImpl _value,
      $Res Function(_$HolderFundSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of HolderFundSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? memberName = null,
    Object? units = null,
    Object? invested = null,
    Object? currentValue = null,
    Object? gain = null,
    Object? cagr = freezed,
    Object? xirr = freezed,
    Object? folioNumber = freezed,
  }) {
    return _then(_$HolderFundSummaryImpl(
      memberId: null == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String,
      memberName: null == memberName
          ? _value.memberName
          : memberName // ignore: cast_nullable_to_non_nullable
              as String,
      units: null == units
          ? _value.units
          : units // ignore: cast_nullable_to_non_nullable
              as double,
      invested: null == invested
          ? _value.invested
          : invested // ignore: cast_nullable_to_non_nullable
              as double,
      currentValue: null == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double,
      gain: null == gain
          ? _value.gain
          : gain // ignore: cast_nullable_to_non_nullable
              as double,
      cagr: freezed == cagr
          ? _value.cagr
          : cagr // ignore: cast_nullable_to_non_nullable
              as double?,
      xirr: freezed == xirr
          ? _value.xirr
          : xirr // ignore: cast_nullable_to_non_nullable
              as double?,
      folioNumber: freezed == folioNumber
          ? _value.folioNumber
          : folioNumber // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HolderFundSummaryImpl implements _HolderFundSummary {
  const _$HolderFundSummaryImpl(
      {required this.memberId,
      required this.memberName,
      this.units = 0,
      this.invested = 0,
      this.currentValue = 0,
      this.gain = 0,
      this.cagr,
      this.xirr,
      this.folioNumber});

  factory _$HolderFundSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$HolderFundSummaryImplFromJson(json);

  @override
  final String memberId;
  @override
  final String memberName;
  @override
  @JsonKey()
  final double units;
  @override
  @JsonKey()
  final double invested;
  @override
  @JsonKey()
  final double currentValue;
  @override
  @JsonKey()
  final double gain;
  @override
  final double? cagr;
  @override
  final double? xirr;
  @override
  final String? folioNumber;

  @override
  String toString() {
    return 'HolderFundSummary(memberId: $memberId, memberName: $memberName, units: $units, invested: $invested, currentValue: $currentValue, gain: $gain, cagr: $cagr, xirr: $xirr, folioNumber: $folioNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HolderFundSummaryImpl &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.memberName, memberName) ||
                other.memberName == memberName) &&
            (identical(other.units, units) || other.units == units) &&
            (identical(other.invested, invested) ||
                other.invested == invested) &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue) &&
            (identical(other.gain, gain) || other.gain == gain) &&
            (identical(other.cagr, cagr) || other.cagr == cagr) &&
            (identical(other.xirr, xirr) || other.xirr == xirr) &&
            (identical(other.folioNumber, folioNumber) ||
                other.folioNumber == folioNumber));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, memberId, memberName, units,
      invested, currentValue, gain, cagr, xirr, folioNumber);

  /// Create a copy of HolderFundSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HolderFundSummaryImplCopyWith<_$HolderFundSummaryImpl> get copyWith =>
      __$$HolderFundSummaryImplCopyWithImpl<_$HolderFundSummaryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HolderFundSummaryImplToJson(
      this,
    );
  }
}

abstract class _HolderFundSummary implements HolderFundSummary {
  const factory _HolderFundSummary(
      {required final String memberId,
      required final String memberName,
      final double units,
      final double invested,
      final double currentValue,
      final double gain,
      final double? cagr,
      final double? xirr,
      final String? folioNumber}) = _$HolderFundSummaryImpl;

  factory _HolderFundSummary.fromJson(Map<String, dynamic> json) =
      _$HolderFundSummaryImpl.fromJson;

  @override
  String get memberId;
  @override
  String get memberName;
  @override
  double get units;
  @override
  double get invested;
  @override
  double get currentValue;
  @override
  double get gain;
  @override
  double? get cagr;
  @override
  double? get xirr;
  @override
  String? get folioNumber;

  /// Create a copy of HolderFundSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HolderFundSummaryImplCopyWith<_$HolderFundSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MemberSummary _$MemberSummaryFromJson(Map<String, dynamic> json) {
  return _MemberSummary.fromJson(json);
}

/// @nodoc
mixin _$MemberSummary {
  String get memberId => throw _privateConstructorUsedError;
  String get memberName => throw _privateConstructorUsedError;
  String? get colorHex => throw _privateConstructorUsedError;
  double get invested => throw _privateConstructorUsedError;
  double get currentValue => throw _privateConstructorUsedError;
  double get gain => throw _privateConstructorUsedError;
  double get gainPct => throw _privateConstructorUsedError;
  double? get xirr => throw _privateConstructorUsedError;
  double? get cagr => throw _privateConstructorUsedError;

  /// Serializes this MemberSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MemberSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MemberSummaryCopyWith<MemberSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemberSummaryCopyWith<$Res> {
  factory $MemberSummaryCopyWith(
          MemberSummary value, $Res Function(MemberSummary) then) =
      _$MemberSummaryCopyWithImpl<$Res, MemberSummary>;
  @useResult
  $Res call(
      {String memberId,
      String memberName,
      String? colorHex,
      double invested,
      double currentValue,
      double gain,
      double gainPct,
      double? xirr,
      double? cagr});
}

/// @nodoc
class _$MemberSummaryCopyWithImpl<$Res, $Val extends MemberSummary>
    implements $MemberSummaryCopyWith<$Res> {
  _$MemberSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MemberSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? memberName = null,
    Object? colorHex = freezed,
    Object? invested = null,
    Object? currentValue = null,
    Object? gain = null,
    Object? gainPct = null,
    Object? xirr = freezed,
    Object? cagr = freezed,
  }) {
    return _then(_value.copyWith(
      memberId: null == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String,
      memberName: null == memberName
          ? _value.memberName
          : memberName // ignore: cast_nullable_to_non_nullable
              as String,
      colorHex: freezed == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String?,
      invested: null == invested
          ? _value.invested
          : invested // ignore: cast_nullable_to_non_nullable
              as double,
      currentValue: null == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double,
      gain: null == gain
          ? _value.gain
          : gain // ignore: cast_nullable_to_non_nullable
              as double,
      gainPct: null == gainPct
          ? _value.gainPct
          : gainPct // ignore: cast_nullable_to_non_nullable
              as double,
      xirr: freezed == xirr
          ? _value.xirr
          : xirr // ignore: cast_nullable_to_non_nullable
              as double?,
      cagr: freezed == cagr
          ? _value.cagr
          : cagr // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemberSummaryImplCopyWith<$Res>
    implements $MemberSummaryCopyWith<$Res> {
  factory _$$MemberSummaryImplCopyWith(
          _$MemberSummaryImpl value, $Res Function(_$MemberSummaryImpl) then) =
      __$$MemberSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String memberId,
      String memberName,
      String? colorHex,
      double invested,
      double currentValue,
      double gain,
      double gainPct,
      double? xirr,
      double? cagr});
}

/// @nodoc
class __$$MemberSummaryImplCopyWithImpl<$Res>
    extends _$MemberSummaryCopyWithImpl<$Res, _$MemberSummaryImpl>
    implements _$$MemberSummaryImplCopyWith<$Res> {
  __$$MemberSummaryImplCopyWithImpl(
      _$MemberSummaryImpl _value, $Res Function(_$MemberSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of MemberSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? memberName = null,
    Object? colorHex = freezed,
    Object? invested = null,
    Object? currentValue = null,
    Object? gain = null,
    Object? gainPct = null,
    Object? xirr = freezed,
    Object? cagr = freezed,
  }) {
    return _then(_$MemberSummaryImpl(
      memberId: null == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String,
      memberName: null == memberName
          ? _value.memberName
          : memberName // ignore: cast_nullable_to_non_nullable
              as String,
      colorHex: freezed == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String?,
      invested: null == invested
          ? _value.invested
          : invested // ignore: cast_nullable_to_non_nullable
              as double,
      currentValue: null == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double,
      gain: null == gain
          ? _value.gain
          : gain // ignore: cast_nullable_to_non_nullable
              as double,
      gainPct: null == gainPct
          ? _value.gainPct
          : gainPct // ignore: cast_nullable_to_non_nullable
              as double,
      xirr: freezed == xirr
          ? _value.xirr
          : xirr // ignore: cast_nullable_to_non_nullable
              as double?,
      cagr: freezed == cagr
          ? _value.cagr
          : cagr // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MemberSummaryImpl implements _MemberSummary {
  const _$MemberSummaryImpl(
      {required this.memberId,
      required this.memberName,
      this.colorHex,
      this.invested = 0,
      this.currentValue = 0,
      this.gain = 0,
      this.gainPct = 0,
      this.xirr,
      this.cagr});

  factory _$MemberSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemberSummaryImplFromJson(json);

  @override
  final String memberId;
  @override
  final String memberName;
  @override
  final String? colorHex;
  @override
  @JsonKey()
  final double invested;
  @override
  @JsonKey()
  final double currentValue;
  @override
  @JsonKey()
  final double gain;
  @override
  @JsonKey()
  final double gainPct;
  @override
  final double? xirr;
  @override
  final double? cagr;

  @override
  String toString() {
    return 'MemberSummary(memberId: $memberId, memberName: $memberName, colorHex: $colorHex, invested: $invested, currentValue: $currentValue, gain: $gain, gainPct: $gainPct, xirr: $xirr, cagr: $cagr)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemberSummaryImpl &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.memberName, memberName) ||
                other.memberName == memberName) &&
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            (identical(other.invested, invested) ||
                other.invested == invested) &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue) &&
            (identical(other.gain, gain) || other.gain == gain) &&
            (identical(other.gainPct, gainPct) || other.gainPct == gainPct) &&
            (identical(other.xirr, xirr) || other.xirr == xirr) &&
            (identical(other.cagr, cagr) || other.cagr == cagr));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, memberId, memberName, colorHex,
      invested, currentValue, gain, gainPct, xirr, cagr);

  /// Create a copy of MemberSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemberSummaryImplCopyWith<_$MemberSummaryImpl> get copyWith =>
      __$$MemberSummaryImplCopyWithImpl<_$MemberSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemberSummaryImplToJson(
      this,
    );
  }
}

abstract class _MemberSummary implements MemberSummary {
  const factory _MemberSummary(
      {required final String memberId,
      required final String memberName,
      final String? colorHex,
      final double invested,
      final double currentValue,
      final double gain,
      final double gainPct,
      final double? xirr,
      final double? cagr}) = _$MemberSummaryImpl;

  factory _MemberSummary.fromJson(Map<String, dynamic> json) =
      _$MemberSummaryImpl.fromJson;

  @override
  String get memberId;
  @override
  String get memberName;
  @override
  String? get colorHex;
  @override
  double get invested;
  @override
  double get currentValue;
  @override
  double get gain;
  @override
  double get gainPct;
  @override
  double? get xirr;
  @override
  double? get cagr;

  /// Create a copy of MemberSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemberSummaryImplCopyWith<_$MemberSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
