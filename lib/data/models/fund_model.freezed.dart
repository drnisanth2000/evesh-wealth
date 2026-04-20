// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fund_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FundModel _$FundModelFromJson(Map<String, dynamic> json) {
  return _FundModel.fromJson(json);
}

/// @nodoc
mixin _$FundModel {
  @JsonKey(name: 'amfi_code')
  int get amfiCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'isin_growth')
  String? get isinGrowth => throw _privateConstructorUsedError;
  @JsonKey(name: 'isin_div_reinvest')
  String? get isinDivReinvest => throw _privateConstructorUsedError;
  @JsonKey(name: 'fund_name')
  String get fundName => throw _privateConstructorUsedError;
  String? get amc => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  @JsonKey(name: 'sub_category')
  String? get subCategory => throw _privateConstructorUsedError;
  @JsonKey(name: 'fund_type')
  String? get fundType => throw _privateConstructorUsedError;
  @JsonKey(name: 'tax_category')
  String? get taxCategory => throw _privateConstructorUsedError;
  @JsonKey(name: 'plan_type')
  String? get planType => throw _privateConstructorUsedError;
  @JsonKey(name: 'latest_nav')
  double? get latestNav => throw _privateConstructorUsedError;
  @JsonKey(name: 'prev_nav')
  double? get prevNav => throw _privateConstructorUsedError;
  @JsonKey(name: 'nav_date')
  String? get navDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'nav_30d_high')
  double? get nav30dHigh => throw _privateConstructorUsedError;
  @JsonKey(name: 'expense_ratio')
  double? get expenseRatio => throw _privateConstructorUsedError;
  @JsonKey(name: 'er_source')
  String? get erSource => throw _privateConstructorUsedError;
  @JsonKey(name: 'fund_managers')
  List<String>? get fundManagers => throw _privateConstructorUsedError;
  @JsonKey(name: 'crisil_rating')
  String? get crisilRating => throw _privateConstructorUsedError;
  @JsonKey(name: 'fund_rating')
  int? get fundRating => throw _privateConstructorUsedError;
  @JsonKey(name: 'aum_cr')
  double? get aumCr => throw _privateConstructorUsedError;
  @JsonKey(name: 'return_1y')
  double? get return1y => throw _privateConstructorUsedError;
  @JsonKey(name: 'return_3y')
  double? get return3y => throw _privateConstructorUsedError;
  @JsonKey(name: 'return_5y')
  double? get return5y => throw _privateConstructorUsedError;
  @JsonKey(name: 'return_1w')
  double? get return1w => throw _privateConstructorUsedError;
  @JsonKey(name: 'return_inception')
  double? get returnInception => throw _privateConstructorUsedError;
  @JsonKey(name: 'volatility_1y')
  double? get volatility1y => throw _privateConstructorUsedError;
  @JsonKey(name: 'portfolio_turnover')
  double? get portfolioTurnover => throw _privateConstructorUsedError;
  @JsonKey(name: 'benchmark_index')
  String? get benchmarkIndex => throw _privateConstructorUsedError;
  @JsonKey(name: 'amfi_category_id')
  String? get amfiCategoryId => throw _privateConstructorUsedError;
  @JsonKey(name: 'benchmark_tier1')
  String? get benchmarkTier1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'benchmark_tier2')
  String? get benchmarkTier2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'exit_load')
  String? get exitLoad => throw _privateConstructorUsedError;
  @JsonKey(name: 'min_investment')
  double? get minInvestment => throw _privateConstructorUsedError;
  @JsonKey(name: 'min_sip_amount')
  double? get minSipAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'launch_date')
  String? get launchDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'fund_category')
  String? get fundCategory => throw _privateConstructorUsedError;
  @JsonKey(name: 'fund_rating_date')
  String? get fundRatingDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'investment_objective')
  String? get investmentObjective => throw _privateConstructorUsedError;
  @JsonKey(name: 'jan_31_nav')
  double? get jan31Nav => throw _privateConstructorUsedError;
  @JsonKey(name: 'lock_in_period')
  int get lockInPeriod => throw _privateConstructorUsedError;
  @JsonKey(name: 'tax_period')
  int? get taxPeriod => throw _privateConstructorUsedError;
  @JsonKey(name: 'maturity_type')
  String? get maturityType => throw _privateConstructorUsedError;
  @JsonKey(name: 'detail_info')
  String? get detailInfo => throw _privateConstructorUsedError;
  List<String>? get tags => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;

  /// Serializes this FundModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FundModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FundModelCopyWith<FundModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FundModelCopyWith<$Res> {
  factory $FundModelCopyWith(FundModel value, $Res Function(FundModel) then) =
      _$FundModelCopyWithImpl<$Res, FundModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'amfi_code') int amfiCode,
      @JsonKey(name: 'isin_growth') String? isinGrowth,
      @JsonKey(name: 'isin_div_reinvest') String? isinDivReinvest,
      @JsonKey(name: 'fund_name') String fundName,
      String? amc,
      String? category,
      @JsonKey(name: 'sub_category') String? subCategory,
      @JsonKey(name: 'fund_type') String? fundType,
      @JsonKey(name: 'tax_category') String? taxCategory,
      @JsonKey(name: 'plan_type') String? planType,
      @JsonKey(name: 'latest_nav') double? latestNav,
      @JsonKey(name: 'prev_nav') double? prevNav,
      @JsonKey(name: 'nav_date') String? navDate,
      @JsonKey(name: 'nav_30d_high') double? nav30dHigh,
      @JsonKey(name: 'expense_ratio') double? expenseRatio,
      @JsonKey(name: 'er_source') String? erSource,
      @JsonKey(name: 'fund_managers') List<String>? fundManagers,
      @JsonKey(name: 'crisil_rating') String? crisilRating,
      @JsonKey(name: 'fund_rating') int? fundRating,
      @JsonKey(name: 'aum_cr') double? aumCr,
      @JsonKey(name: 'return_1y') double? return1y,
      @JsonKey(name: 'return_3y') double? return3y,
      @JsonKey(name: 'return_5y') double? return5y,
      @JsonKey(name: 'return_1w') double? return1w,
      @JsonKey(name: 'return_inception') double? returnInception,
      @JsonKey(name: 'volatility_1y') double? volatility1y,
      @JsonKey(name: 'portfolio_turnover') double? portfolioTurnover,
      @JsonKey(name: 'benchmark_index') String? benchmarkIndex,
      @JsonKey(name: 'amfi_category_id') String? amfiCategoryId,
      @JsonKey(name: 'benchmark_tier1') String? benchmarkTier1,
      @JsonKey(name: 'benchmark_tier2') String? benchmarkTier2,
      @JsonKey(name: 'exit_load') String? exitLoad,
      @JsonKey(name: 'min_investment') double? minInvestment,
      @JsonKey(name: 'min_sip_amount') double? minSipAmount,
      @JsonKey(name: 'launch_date') String? launchDate,
      @JsonKey(name: 'fund_category') String? fundCategory,
      @JsonKey(name: 'fund_rating_date') String? fundRatingDate,
      @JsonKey(name: 'investment_objective') String? investmentObjective,
      @JsonKey(name: 'jan_31_nav') double? jan31Nav,
      @JsonKey(name: 'lock_in_period') int lockInPeriod,
      @JsonKey(name: 'tax_period') int? taxPeriod,
      @JsonKey(name: 'maturity_type') String? maturityType,
      @JsonKey(name: 'detail_info') String? detailInfo,
      List<String>? tags,
      @JsonKey(name: 'is_active') bool isActive});
}

/// @nodoc
class _$FundModelCopyWithImpl<$Res, $Val extends FundModel>
    implements $FundModelCopyWith<$Res> {
  _$FundModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FundModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? amfiCode = null,
    Object? isinGrowth = freezed,
    Object? isinDivReinvest = freezed,
    Object? fundName = null,
    Object? amc = freezed,
    Object? category = freezed,
    Object? subCategory = freezed,
    Object? fundType = freezed,
    Object? taxCategory = freezed,
    Object? planType = freezed,
    Object? latestNav = freezed,
    Object? prevNav = freezed,
    Object? navDate = freezed,
    Object? nav30dHigh = freezed,
    Object? expenseRatio = freezed,
    Object? erSource = freezed,
    Object? fundManagers = freezed,
    Object? crisilRating = freezed,
    Object? fundRating = freezed,
    Object? aumCr = freezed,
    Object? return1y = freezed,
    Object? return3y = freezed,
    Object? return5y = freezed,
    Object? return1w = freezed,
    Object? returnInception = freezed,
    Object? volatility1y = freezed,
    Object? portfolioTurnover = freezed,
    Object? benchmarkIndex = freezed,
    Object? amfiCategoryId = freezed,
    Object? benchmarkTier1 = freezed,
    Object? benchmarkTier2 = freezed,
    Object? exitLoad = freezed,
    Object? minInvestment = freezed,
    Object? minSipAmount = freezed,
    Object? launchDate = freezed,
    Object? fundCategory = freezed,
    Object? fundRatingDate = freezed,
    Object? investmentObjective = freezed,
    Object? jan31Nav = freezed,
    Object? lockInPeriod = null,
    Object? taxPeriod = freezed,
    Object? maturityType = freezed,
    Object? detailInfo = freezed,
    Object? tags = freezed,
    Object? isActive = null,
  }) {
    return _then(_value.copyWith(
      amfiCode: null == amfiCode
          ? _value.amfiCode
          : amfiCode // ignore: cast_nullable_to_non_nullable
              as int,
      isinGrowth: freezed == isinGrowth
          ? _value.isinGrowth
          : isinGrowth // ignore: cast_nullable_to_non_nullable
              as String?,
      isinDivReinvest: freezed == isinDivReinvest
          ? _value.isinDivReinvest
          : isinDivReinvest // ignore: cast_nullable_to_non_nullable
              as String?,
      fundName: null == fundName
          ? _value.fundName
          : fundName // ignore: cast_nullable_to_non_nullable
              as String,
      amc: freezed == amc
          ? _value.amc
          : amc // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      subCategory: freezed == subCategory
          ? _value.subCategory
          : subCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      fundType: freezed == fundType
          ? _value.fundType
          : fundType // ignore: cast_nullable_to_non_nullable
              as String?,
      taxCategory: freezed == taxCategory
          ? _value.taxCategory
          : taxCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      planType: freezed == planType
          ? _value.planType
          : planType // ignore: cast_nullable_to_non_nullable
              as String?,
      latestNav: freezed == latestNav
          ? _value.latestNav
          : latestNav // ignore: cast_nullable_to_non_nullable
              as double?,
      prevNav: freezed == prevNav
          ? _value.prevNav
          : prevNav // ignore: cast_nullable_to_non_nullable
              as double?,
      navDate: freezed == navDate
          ? _value.navDate
          : navDate // ignore: cast_nullable_to_non_nullable
              as String?,
      nav30dHigh: freezed == nav30dHigh
          ? _value.nav30dHigh
          : nav30dHigh // ignore: cast_nullable_to_non_nullable
              as double?,
      expenseRatio: freezed == expenseRatio
          ? _value.expenseRatio
          : expenseRatio // ignore: cast_nullable_to_non_nullable
              as double?,
      erSource: freezed == erSource
          ? _value.erSource
          : erSource // ignore: cast_nullable_to_non_nullable
              as String?,
      fundManagers: freezed == fundManagers
          ? _value.fundManagers
          : fundManagers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      crisilRating: freezed == crisilRating
          ? _value.crisilRating
          : crisilRating // ignore: cast_nullable_to_non_nullable
              as String?,
      fundRating: freezed == fundRating
          ? _value.fundRating
          : fundRating // ignore: cast_nullable_to_non_nullable
              as int?,
      aumCr: freezed == aumCr
          ? _value.aumCr
          : aumCr // ignore: cast_nullable_to_non_nullable
              as double?,
      return1y: freezed == return1y
          ? _value.return1y
          : return1y // ignore: cast_nullable_to_non_nullable
              as double?,
      return3y: freezed == return3y
          ? _value.return3y
          : return3y // ignore: cast_nullable_to_non_nullable
              as double?,
      return5y: freezed == return5y
          ? _value.return5y
          : return5y // ignore: cast_nullable_to_non_nullable
              as double?,
      return1w: freezed == return1w
          ? _value.return1w
          : return1w // ignore: cast_nullable_to_non_nullable
              as double?,
      returnInception: freezed == returnInception
          ? _value.returnInception
          : returnInception // ignore: cast_nullable_to_non_nullable
              as double?,
      volatility1y: freezed == volatility1y
          ? _value.volatility1y
          : volatility1y // ignore: cast_nullable_to_non_nullable
              as double?,
      portfolioTurnover: freezed == portfolioTurnover
          ? _value.portfolioTurnover
          : portfolioTurnover // ignore: cast_nullable_to_non_nullable
              as double?,
      benchmarkIndex: freezed == benchmarkIndex
          ? _value.benchmarkIndex
          : benchmarkIndex // ignore: cast_nullable_to_non_nullable
              as String?,
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
      exitLoad: freezed == exitLoad
          ? _value.exitLoad
          : exitLoad // ignore: cast_nullable_to_non_nullable
              as String?,
      minInvestment: freezed == minInvestment
          ? _value.minInvestment
          : minInvestment // ignore: cast_nullable_to_non_nullable
              as double?,
      minSipAmount: freezed == minSipAmount
          ? _value.minSipAmount
          : minSipAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      launchDate: freezed == launchDate
          ? _value.launchDate
          : launchDate // ignore: cast_nullable_to_non_nullable
              as String?,
      fundCategory: freezed == fundCategory
          ? _value.fundCategory
          : fundCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      fundRatingDate: freezed == fundRatingDate
          ? _value.fundRatingDate
          : fundRatingDate // ignore: cast_nullable_to_non_nullable
              as String?,
      investmentObjective: freezed == investmentObjective
          ? _value.investmentObjective
          : investmentObjective // ignore: cast_nullable_to_non_nullable
              as String?,
      jan31Nav: freezed == jan31Nav
          ? _value.jan31Nav
          : jan31Nav // ignore: cast_nullable_to_non_nullable
              as double?,
      lockInPeriod: null == lockInPeriod
          ? _value.lockInPeriod
          : lockInPeriod // ignore: cast_nullable_to_non_nullable
              as int,
      taxPeriod: freezed == taxPeriod
          ? _value.taxPeriod
          : taxPeriod // ignore: cast_nullable_to_non_nullable
              as int?,
      maturityType: freezed == maturityType
          ? _value.maturityType
          : maturityType // ignore: cast_nullable_to_non_nullable
              as String?,
      detailInfo: freezed == detailInfo
          ? _value.detailInfo
          : detailInfo // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: freezed == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FundModelImplCopyWith<$Res>
    implements $FundModelCopyWith<$Res> {
  factory _$$FundModelImplCopyWith(
          _$FundModelImpl value, $Res Function(_$FundModelImpl) then) =
      __$$FundModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'amfi_code') int amfiCode,
      @JsonKey(name: 'isin_growth') String? isinGrowth,
      @JsonKey(name: 'isin_div_reinvest') String? isinDivReinvest,
      @JsonKey(name: 'fund_name') String fundName,
      String? amc,
      String? category,
      @JsonKey(name: 'sub_category') String? subCategory,
      @JsonKey(name: 'fund_type') String? fundType,
      @JsonKey(name: 'tax_category') String? taxCategory,
      @JsonKey(name: 'plan_type') String? planType,
      @JsonKey(name: 'latest_nav') double? latestNav,
      @JsonKey(name: 'prev_nav') double? prevNav,
      @JsonKey(name: 'nav_date') String? navDate,
      @JsonKey(name: 'nav_30d_high') double? nav30dHigh,
      @JsonKey(name: 'expense_ratio') double? expenseRatio,
      @JsonKey(name: 'er_source') String? erSource,
      @JsonKey(name: 'fund_managers') List<String>? fundManagers,
      @JsonKey(name: 'crisil_rating') String? crisilRating,
      @JsonKey(name: 'fund_rating') int? fundRating,
      @JsonKey(name: 'aum_cr') double? aumCr,
      @JsonKey(name: 'return_1y') double? return1y,
      @JsonKey(name: 'return_3y') double? return3y,
      @JsonKey(name: 'return_5y') double? return5y,
      @JsonKey(name: 'return_1w') double? return1w,
      @JsonKey(name: 'return_inception') double? returnInception,
      @JsonKey(name: 'volatility_1y') double? volatility1y,
      @JsonKey(name: 'portfolio_turnover') double? portfolioTurnover,
      @JsonKey(name: 'benchmark_index') String? benchmarkIndex,
      @JsonKey(name: 'amfi_category_id') String? amfiCategoryId,
      @JsonKey(name: 'benchmark_tier1') String? benchmarkTier1,
      @JsonKey(name: 'benchmark_tier2') String? benchmarkTier2,
      @JsonKey(name: 'exit_load') String? exitLoad,
      @JsonKey(name: 'min_investment') double? minInvestment,
      @JsonKey(name: 'min_sip_amount') double? minSipAmount,
      @JsonKey(name: 'launch_date') String? launchDate,
      @JsonKey(name: 'fund_category') String? fundCategory,
      @JsonKey(name: 'fund_rating_date') String? fundRatingDate,
      @JsonKey(name: 'investment_objective') String? investmentObjective,
      @JsonKey(name: 'jan_31_nav') double? jan31Nav,
      @JsonKey(name: 'lock_in_period') int lockInPeriod,
      @JsonKey(name: 'tax_period') int? taxPeriod,
      @JsonKey(name: 'maturity_type') String? maturityType,
      @JsonKey(name: 'detail_info') String? detailInfo,
      List<String>? tags,
      @JsonKey(name: 'is_active') bool isActive});
}

/// @nodoc
class __$$FundModelImplCopyWithImpl<$Res>
    extends _$FundModelCopyWithImpl<$Res, _$FundModelImpl>
    implements _$$FundModelImplCopyWith<$Res> {
  __$$FundModelImplCopyWithImpl(
      _$FundModelImpl _value, $Res Function(_$FundModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of FundModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? amfiCode = null,
    Object? isinGrowth = freezed,
    Object? isinDivReinvest = freezed,
    Object? fundName = null,
    Object? amc = freezed,
    Object? category = freezed,
    Object? subCategory = freezed,
    Object? fundType = freezed,
    Object? taxCategory = freezed,
    Object? planType = freezed,
    Object? latestNav = freezed,
    Object? prevNav = freezed,
    Object? navDate = freezed,
    Object? nav30dHigh = freezed,
    Object? expenseRatio = freezed,
    Object? erSource = freezed,
    Object? fundManagers = freezed,
    Object? crisilRating = freezed,
    Object? fundRating = freezed,
    Object? aumCr = freezed,
    Object? return1y = freezed,
    Object? return3y = freezed,
    Object? return5y = freezed,
    Object? return1w = freezed,
    Object? returnInception = freezed,
    Object? volatility1y = freezed,
    Object? portfolioTurnover = freezed,
    Object? benchmarkIndex = freezed,
    Object? amfiCategoryId = freezed,
    Object? benchmarkTier1 = freezed,
    Object? benchmarkTier2 = freezed,
    Object? exitLoad = freezed,
    Object? minInvestment = freezed,
    Object? minSipAmount = freezed,
    Object? launchDate = freezed,
    Object? fundCategory = freezed,
    Object? fundRatingDate = freezed,
    Object? investmentObjective = freezed,
    Object? jan31Nav = freezed,
    Object? lockInPeriod = null,
    Object? taxPeriod = freezed,
    Object? maturityType = freezed,
    Object? detailInfo = freezed,
    Object? tags = freezed,
    Object? isActive = null,
  }) {
    return _then(_$FundModelImpl(
      amfiCode: null == amfiCode
          ? _value.amfiCode
          : amfiCode // ignore: cast_nullable_to_non_nullable
              as int,
      isinGrowth: freezed == isinGrowth
          ? _value.isinGrowth
          : isinGrowth // ignore: cast_nullable_to_non_nullable
              as String?,
      isinDivReinvest: freezed == isinDivReinvest
          ? _value.isinDivReinvest
          : isinDivReinvest // ignore: cast_nullable_to_non_nullable
              as String?,
      fundName: null == fundName
          ? _value.fundName
          : fundName // ignore: cast_nullable_to_non_nullable
              as String,
      amc: freezed == amc
          ? _value.amc
          : amc // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      subCategory: freezed == subCategory
          ? _value.subCategory
          : subCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      fundType: freezed == fundType
          ? _value.fundType
          : fundType // ignore: cast_nullable_to_non_nullable
              as String?,
      taxCategory: freezed == taxCategory
          ? _value.taxCategory
          : taxCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      planType: freezed == planType
          ? _value.planType
          : planType // ignore: cast_nullable_to_non_nullable
              as String?,
      latestNav: freezed == latestNav
          ? _value.latestNav
          : latestNav // ignore: cast_nullable_to_non_nullable
              as double?,
      prevNav: freezed == prevNav
          ? _value.prevNav
          : prevNav // ignore: cast_nullable_to_non_nullable
              as double?,
      navDate: freezed == navDate
          ? _value.navDate
          : navDate // ignore: cast_nullable_to_non_nullable
              as String?,
      nav30dHigh: freezed == nav30dHigh
          ? _value.nav30dHigh
          : nav30dHigh // ignore: cast_nullable_to_non_nullable
              as double?,
      expenseRatio: freezed == expenseRatio
          ? _value.expenseRatio
          : expenseRatio // ignore: cast_nullable_to_non_nullable
              as double?,
      erSource: freezed == erSource
          ? _value.erSource
          : erSource // ignore: cast_nullable_to_non_nullable
              as String?,
      fundManagers: freezed == fundManagers
          ? _value._fundManagers
          : fundManagers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      crisilRating: freezed == crisilRating
          ? _value.crisilRating
          : crisilRating // ignore: cast_nullable_to_non_nullable
              as String?,
      fundRating: freezed == fundRating
          ? _value.fundRating
          : fundRating // ignore: cast_nullable_to_non_nullable
              as int?,
      aumCr: freezed == aumCr
          ? _value.aumCr
          : aumCr // ignore: cast_nullable_to_non_nullable
              as double?,
      return1y: freezed == return1y
          ? _value.return1y
          : return1y // ignore: cast_nullable_to_non_nullable
              as double?,
      return3y: freezed == return3y
          ? _value.return3y
          : return3y // ignore: cast_nullable_to_non_nullable
              as double?,
      return5y: freezed == return5y
          ? _value.return5y
          : return5y // ignore: cast_nullable_to_non_nullable
              as double?,
      return1w: freezed == return1w
          ? _value.return1w
          : return1w // ignore: cast_nullable_to_non_nullable
              as double?,
      returnInception: freezed == returnInception
          ? _value.returnInception
          : returnInception // ignore: cast_nullable_to_non_nullable
              as double?,
      volatility1y: freezed == volatility1y
          ? _value.volatility1y
          : volatility1y // ignore: cast_nullable_to_non_nullable
              as double?,
      portfolioTurnover: freezed == portfolioTurnover
          ? _value.portfolioTurnover
          : portfolioTurnover // ignore: cast_nullable_to_non_nullable
              as double?,
      benchmarkIndex: freezed == benchmarkIndex
          ? _value.benchmarkIndex
          : benchmarkIndex // ignore: cast_nullable_to_non_nullable
              as String?,
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
      exitLoad: freezed == exitLoad
          ? _value.exitLoad
          : exitLoad // ignore: cast_nullable_to_non_nullable
              as String?,
      minInvestment: freezed == minInvestment
          ? _value.minInvestment
          : minInvestment // ignore: cast_nullable_to_non_nullable
              as double?,
      minSipAmount: freezed == minSipAmount
          ? _value.minSipAmount
          : minSipAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      launchDate: freezed == launchDate
          ? _value.launchDate
          : launchDate // ignore: cast_nullable_to_non_nullable
              as String?,
      fundCategory: freezed == fundCategory
          ? _value.fundCategory
          : fundCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      fundRatingDate: freezed == fundRatingDate
          ? _value.fundRatingDate
          : fundRatingDate // ignore: cast_nullable_to_non_nullable
              as String?,
      investmentObjective: freezed == investmentObjective
          ? _value.investmentObjective
          : investmentObjective // ignore: cast_nullable_to_non_nullable
              as String?,
      jan31Nav: freezed == jan31Nav
          ? _value.jan31Nav
          : jan31Nav // ignore: cast_nullable_to_non_nullable
              as double?,
      lockInPeriod: null == lockInPeriod
          ? _value.lockInPeriod
          : lockInPeriod // ignore: cast_nullable_to_non_nullable
              as int,
      taxPeriod: freezed == taxPeriod
          ? _value.taxPeriod
          : taxPeriod // ignore: cast_nullable_to_non_nullable
              as int?,
      maturityType: freezed == maturityType
          ? _value.maturityType
          : maturityType // ignore: cast_nullable_to_non_nullable
              as String?,
      detailInfo: freezed == detailInfo
          ? _value.detailInfo
          : detailInfo // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: freezed == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FundModelImpl extends _FundModel {
  const _$FundModelImpl(
      {@JsonKey(name: 'amfi_code') required this.amfiCode,
      @JsonKey(name: 'isin_growth') this.isinGrowth,
      @JsonKey(name: 'isin_div_reinvest') this.isinDivReinvest,
      @JsonKey(name: 'fund_name') required this.fundName,
      this.amc,
      this.category,
      @JsonKey(name: 'sub_category') this.subCategory,
      @JsonKey(name: 'fund_type') this.fundType,
      @JsonKey(name: 'tax_category') this.taxCategory,
      @JsonKey(name: 'plan_type') this.planType,
      @JsonKey(name: 'latest_nav') this.latestNav,
      @JsonKey(name: 'prev_nav') this.prevNav,
      @JsonKey(name: 'nav_date') this.navDate,
      @JsonKey(name: 'nav_30d_high') this.nav30dHigh,
      @JsonKey(name: 'expense_ratio') this.expenseRatio,
      @JsonKey(name: 'er_source') this.erSource,
      @JsonKey(name: 'fund_managers') final List<String>? fundManagers,
      @JsonKey(name: 'crisil_rating') this.crisilRating,
      @JsonKey(name: 'fund_rating') this.fundRating,
      @JsonKey(name: 'aum_cr') this.aumCr,
      @JsonKey(name: 'return_1y') this.return1y,
      @JsonKey(name: 'return_3y') this.return3y,
      @JsonKey(name: 'return_5y') this.return5y,
      @JsonKey(name: 'return_1w') this.return1w,
      @JsonKey(name: 'return_inception') this.returnInception,
      @JsonKey(name: 'volatility_1y') this.volatility1y,
      @JsonKey(name: 'portfolio_turnover') this.portfolioTurnover,
      @JsonKey(name: 'benchmark_index') this.benchmarkIndex,
      @JsonKey(name: 'amfi_category_id') this.amfiCategoryId,
      @JsonKey(name: 'benchmark_tier1') this.benchmarkTier1,
      @JsonKey(name: 'benchmark_tier2') this.benchmarkTier2,
      @JsonKey(name: 'exit_load') this.exitLoad,
      @JsonKey(name: 'min_investment') this.minInvestment,
      @JsonKey(name: 'min_sip_amount') this.minSipAmount,
      @JsonKey(name: 'launch_date') this.launchDate,
      @JsonKey(name: 'fund_category') this.fundCategory,
      @JsonKey(name: 'fund_rating_date') this.fundRatingDate,
      @JsonKey(name: 'investment_objective') this.investmentObjective,
      @JsonKey(name: 'jan_31_nav') this.jan31Nav,
      @JsonKey(name: 'lock_in_period') this.lockInPeriod = 0,
      @JsonKey(name: 'tax_period') this.taxPeriod,
      @JsonKey(name: 'maturity_type') this.maturityType,
      @JsonKey(name: 'detail_info') this.detailInfo,
      final List<String>? tags,
      @JsonKey(name: 'is_active') this.isActive = true})
      : _fundManagers = fundManagers,
        _tags = tags,
        super._();

  factory _$FundModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FundModelImplFromJson(json);

  @override
  @JsonKey(name: 'amfi_code')
  final int amfiCode;
  @override
  @JsonKey(name: 'isin_growth')
  final String? isinGrowth;
  @override
  @JsonKey(name: 'isin_div_reinvest')
  final String? isinDivReinvest;
  @override
  @JsonKey(name: 'fund_name')
  final String fundName;
  @override
  final String? amc;
  @override
  final String? category;
  @override
  @JsonKey(name: 'sub_category')
  final String? subCategory;
  @override
  @JsonKey(name: 'fund_type')
  final String? fundType;
  @override
  @JsonKey(name: 'tax_category')
  final String? taxCategory;
  @override
  @JsonKey(name: 'plan_type')
  final String? planType;
  @override
  @JsonKey(name: 'latest_nav')
  final double? latestNav;
  @override
  @JsonKey(name: 'prev_nav')
  final double? prevNav;
  @override
  @JsonKey(name: 'nav_date')
  final String? navDate;
  @override
  @JsonKey(name: 'nav_30d_high')
  final double? nav30dHigh;
  @override
  @JsonKey(name: 'expense_ratio')
  final double? expenseRatio;
  @override
  @JsonKey(name: 'er_source')
  final String? erSource;
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
  @JsonKey(name: 'fund_rating')
  final int? fundRating;
  @override
  @JsonKey(name: 'aum_cr')
  final double? aumCr;
  @override
  @JsonKey(name: 'return_1y')
  final double? return1y;
  @override
  @JsonKey(name: 'return_3y')
  final double? return3y;
  @override
  @JsonKey(name: 'return_5y')
  final double? return5y;
  @override
  @JsonKey(name: 'return_1w')
  final double? return1w;
  @override
  @JsonKey(name: 'return_inception')
  final double? returnInception;
  @override
  @JsonKey(name: 'volatility_1y')
  final double? volatility1y;
  @override
  @JsonKey(name: 'portfolio_turnover')
  final double? portfolioTurnover;
  @override
  @JsonKey(name: 'benchmark_index')
  final String? benchmarkIndex;
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
  @JsonKey(name: 'exit_load')
  final String? exitLoad;
  @override
  @JsonKey(name: 'min_investment')
  final double? minInvestment;
  @override
  @JsonKey(name: 'min_sip_amount')
  final double? minSipAmount;
  @override
  @JsonKey(name: 'launch_date')
  final String? launchDate;
  @override
  @JsonKey(name: 'fund_category')
  final String? fundCategory;
  @override
  @JsonKey(name: 'fund_rating_date')
  final String? fundRatingDate;
  @override
  @JsonKey(name: 'investment_objective')
  final String? investmentObjective;
  @override
  @JsonKey(name: 'jan_31_nav')
  final double? jan31Nav;
  @override
  @JsonKey(name: 'lock_in_period')
  final int lockInPeriod;
  @override
  @JsonKey(name: 'tax_period')
  final int? taxPeriod;
  @override
  @JsonKey(name: 'maturity_type')
  final String? maturityType;
  @override
  @JsonKey(name: 'detail_info')
  final String? detailInfo;
  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'is_active')
  final bool isActive;

  @override
  String toString() {
    return 'FundModel(amfiCode: $amfiCode, isinGrowth: $isinGrowth, isinDivReinvest: $isinDivReinvest, fundName: $fundName, amc: $amc, category: $category, subCategory: $subCategory, fundType: $fundType, taxCategory: $taxCategory, planType: $planType, latestNav: $latestNav, prevNav: $prevNav, navDate: $navDate, nav30dHigh: $nav30dHigh, expenseRatio: $expenseRatio, erSource: $erSource, fundManagers: $fundManagers, crisilRating: $crisilRating, fundRating: $fundRating, aumCr: $aumCr, return1y: $return1y, return3y: $return3y, return5y: $return5y, return1w: $return1w, returnInception: $returnInception, volatility1y: $volatility1y, portfolioTurnover: $portfolioTurnover, benchmarkIndex: $benchmarkIndex, amfiCategoryId: $amfiCategoryId, benchmarkTier1: $benchmarkTier1, benchmarkTier2: $benchmarkTier2, exitLoad: $exitLoad, minInvestment: $minInvestment, minSipAmount: $minSipAmount, launchDate: $launchDate, fundCategory: $fundCategory, fundRatingDate: $fundRatingDate, investmentObjective: $investmentObjective, jan31Nav: $jan31Nav, lockInPeriod: $lockInPeriod, taxPeriod: $taxPeriod, maturityType: $maturityType, detailInfo: $detailInfo, tags: $tags, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FundModelImpl &&
            (identical(other.amfiCode, amfiCode) ||
                other.amfiCode == amfiCode) &&
            (identical(other.isinGrowth, isinGrowth) ||
                other.isinGrowth == isinGrowth) &&
            (identical(other.isinDivReinvest, isinDivReinvest) ||
                other.isinDivReinvest == isinDivReinvest) &&
            (identical(other.fundName, fundName) ||
                other.fundName == fundName) &&
            (identical(other.amc, amc) || other.amc == amc) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.subCategory, subCategory) ||
                other.subCategory == subCategory) &&
            (identical(other.fundType, fundType) ||
                other.fundType == fundType) &&
            (identical(other.taxCategory, taxCategory) ||
                other.taxCategory == taxCategory) &&
            (identical(other.planType, planType) ||
                other.planType == planType) &&
            (identical(other.latestNav, latestNav) ||
                other.latestNav == latestNav) &&
            (identical(other.prevNav, prevNav) || other.prevNav == prevNav) &&
            (identical(other.navDate, navDate) || other.navDate == navDate) &&
            (identical(other.nav30dHigh, nav30dHigh) ||
                other.nav30dHigh == nav30dHigh) &&
            (identical(other.expenseRatio, expenseRatio) ||
                other.expenseRatio == expenseRatio) &&
            (identical(other.erSource, erSource) ||
                other.erSource == erSource) &&
            const DeepCollectionEquality()
                .equals(other._fundManagers, _fundManagers) &&
            (identical(other.crisilRating, crisilRating) ||
                other.crisilRating == crisilRating) &&
            (identical(other.fundRating, fundRating) ||
                other.fundRating == fundRating) &&
            (identical(other.aumCr, aumCr) || other.aumCr == aumCr) &&
            (identical(other.return1y, return1y) ||
                other.return1y == return1y) &&
            (identical(other.return3y, return3y) ||
                other.return3y == return3y) &&
            (identical(other.return5y, return5y) ||
                other.return5y == return5y) &&
            (identical(other.return1w, return1w) ||
                other.return1w == return1w) &&
            (identical(other.returnInception, returnInception) ||
                other.returnInception == returnInception) &&
            (identical(other.volatility1y, volatility1y) ||
                other.volatility1y == volatility1y) &&
            (identical(other.portfolioTurnover, portfolioTurnover) ||
                other.portfolioTurnover == portfolioTurnover) &&
            (identical(other.benchmarkIndex, benchmarkIndex) ||
                other.benchmarkIndex == benchmarkIndex) &&
            (identical(other.amfiCategoryId, amfiCategoryId) ||
                other.amfiCategoryId == amfiCategoryId) &&
            (identical(other.benchmarkTier1, benchmarkTier1) ||
                other.benchmarkTier1 == benchmarkTier1) &&
            (identical(other.benchmarkTier2, benchmarkTier2) ||
                other.benchmarkTier2 == benchmarkTier2) &&
            (identical(other.exitLoad, exitLoad) ||
                other.exitLoad == exitLoad) &&
            (identical(other.minInvestment, minInvestment) ||
                other.minInvestment == minInvestment) &&
            (identical(other.minSipAmount, minSipAmount) ||
                other.minSipAmount == minSipAmount) &&
            (identical(other.launchDate, launchDate) ||
                other.launchDate == launchDate) &&
            (identical(other.fundCategory, fundCategory) ||
                other.fundCategory == fundCategory) &&
            (identical(other.fundRatingDate, fundRatingDate) ||
                other.fundRatingDate == fundRatingDate) &&
            (identical(other.investmentObjective, investmentObjective) ||
                other.investmentObjective == investmentObjective) &&
            (identical(other.jan31Nav, jan31Nav) ||
                other.jan31Nav == jan31Nav) &&
            (identical(other.lockInPeriod, lockInPeriod) ||
                other.lockInPeriod == lockInPeriod) &&
            (identical(other.taxPeriod, taxPeriod) ||
                other.taxPeriod == taxPeriod) &&
            (identical(other.maturityType, maturityType) ||
                other.maturityType == maturityType) &&
            (identical(other.detailInfo, detailInfo) ||
                other.detailInfo == detailInfo) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        amfiCode,
        isinGrowth,
        isinDivReinvest,
        fundName,
        amc,
        category,
        subCategory,
        fundType,
        taxCategory,
        planType,
        latestNav,
        prevNav,
        navDate,
        nav30dHigh,
        expenseRatio,
        erSource,
        const DeepCollectionEquality().hash(_fundManagers),
        crisilRating,
        fundRating,
        aumCr,
        return1y,
        return3y,
        return5y,
        return1w,
        returnInception,
        volatility1y,
        portfolioTurnover,
        benchmarkIndex,
        amfiCategoryId,
        benchmarkTier1,
        benchmarkTier2,
        exitLoad,
        minInvestment,
        minSipAmount,
        launchDate,
        fundCategory,
        fundRatingDate,
        investmentObjective,
        jan31Nav,
        lockInPeriod,
        taxPeriod,
        maturityType,
        detailInfo,
        const DeepCollectionEquality().hash(_tags),
        isActive
      ]);

  /// Create a copy of FundModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FundModelImplCopyWith<_$FundModelImpl> get copyWith =>
      __$$FundModelImplCopyWithImpl<_$FundModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FundModelImplToJson(
      this,
    );
  }
}

abstract class _FundModel extends FundModel {
  const factory _FundModel(
      {@JsonKey(name: 'amfi_code') required final int amfiCode,
      @JsonKey(name: 'isin_growth') final String? isinGrowth,
      @JsonKey(name: 'isin_div_reinvest') final String? isinDivReinvest,
      @JsonKey(name: 'fund_name') required final String fundName,
      final String? amc,
      final String? category,
      @JsonKey(name: 'sub_category') final String? subCategory,
      @JsonKey(name: 'fund_type') final String? fundType,
      @JsonKey(name: 'tax_category') final String? taxCategory,
      @JsonKey(name: 'plan_type') final String? planType,
      @JsonKey(name: 'latest_nav') final double? latestNav,
      @JsonKey(name: 'prev_nav') final double? prevNav,
      @JsonKey(name: 'nav_date') final String? navDate,
      @JsonKey(name: 'nav_30d_high') final double? nav30dHigh,
      @JsonKey(name: 'expense_ratio') final double? expenseRatio,
      @JsonKey(name: 'er_source') final String? erSource,
      @JsonKey(name: 'fund_managers') final List<String>? fundManagers,
      @JsonKey(name: 'crisil_rating') final String? crisilRating,
      @JsonKey(name: 'fund_rating') final int? fundRating,
      @JsonKey(name: 'aum_cr') final double? aumCr,
      @JsonKey(name: 'return_1y') final double? return1y,
      @JsonKey(name: 'return_3y') final double? return3y,
      @JsonKey(name: 'return_5y') final double? return5y,
      @JsonKey(name: 'return_1w') final double? return1w,
      @JsonKey(name: 'return_inception') final double? returnInception,
      @JsonKey(name: 'volatility_1y') final double? volatility1y,
      @JsonKey(name: 'portfolio_turnover') final double? portfolioTurnover,
      @JsonKey(name: 'benchmark_index') final String? benchmarkIndex,
      @JsonKey(name: 'amfi_category_id') final String? amfiCategoryId,
      @JsonKey(name: 'benchmark_tier1') final String? benchmarkTier1,
      @JsonKey(name: 'benchmark_tier2') final String? benchmarkTier2,
      @JsonKey(name: 'exit_load') final String? exitLoad,
      @JsonKey(name: 'min_investment') final double? minInvestment,
      @JsonKey(name: 'min_sip_amount') final double? minSipAmount,
      @JsonKey(name: 'launch_date') final String? launchDate,
      @JsonKey(name: 'fund_category') final String? fundCategory,
      @JsonKey(name: 'fund_rating_date') final String? fundRatingDate,
      @JsonKey(name: 'investment_objective') final String? investmentObjective,
      @JsonKey(name: 'jan_31_nav') final double? jan31Nav,
      @JsonKey(name: 'lock_in_period') final int lockInPeriod,
      @JsonKey(name: 'tax_period') final int? taxPeriod,
      @JsonKey(name: 'maturity_type') final String? maturityType,
      @JsonKey(name: 'detail_info') final String? detailInfo,
      final List<String>? tags,
      @JsonKey(name: 'is_active') final bool isActive}) = _$FundModelImpl;
  const _FundModel._() : super._();

  factory _FundModel.fromJson(Map<String, dynamic> json) =
      _$FundModelImpl.fromJson;

  @override
  @JsonKey(name: 'amfi_code')
  int get amfiCode;
  @override
  @JsonKey(name: 'isin_growth')
  String? get isinGrowth;
  @override
  @JsonKey(name: 'isin_div_reinvest')
  String? get isinDivReinvest;
  @override
  @JsonKey(name: 'fund_name')
  String get fundName;
  @override
  String? get amc;
  @override
  String? get category;
  @override
  @JsonKey(name: 'sub_category')
  String? get subCategory;
  @override
  @JsonKey(name: 'fund_type')
  String? get fundType;
  @override
  @JsonKey(name: 'tax_category')
  String? get taxCategory;
  @override
  @JsonKey(name: 'plan_type')
  String? get planType;
  @override
  @JsonKey(name: 'latest_nav')
  double? get latestNav;
  @override
  @JsonKey(name: 'prev_nav')
  double? get prevNav;
  @override
  @JsonKey(name: 'nav_date')
  String? get navDate;
  @override
  @JsonKey(name: 'nav_30d_high')
  double? get nav30dHigh;
  @override
  @JsonKey(name: 'expense_ratio')
  double? get expenseRatio;
  @override
  @JsonKey(name: 'er_source')
  String? get erSource;
  @override
  @JsonKey(name: 'fund_managers')
  List<String>? get fundManagers;
  @override
  @JsonKey(name: 'crisil_rating')
  String? get crisilRating;
  @override
  @JsonKey(name: 'fund_rating')
  int? get fundRating;
  @override
  @JsonKey(name: 'aum_cr')
  double? get aumCr;
  @override
  @JsonKey(name: 'return_1y')
  double? get return1y;
  @override
  @JsonKey(name: 'return_3y')
  double? get return3y;
  @override
  @JsonKey(name: 'return_5y')
  double? get return5y;
  @override
  @JsonKey(name: 'return_1w')
  double? get return1w;
  @override
  @JsonKey(name: 'return_inception')
  double? get returnInception;
  @override
  @JsonKey(name: 'volatility_1y')
  double? get volatility1y;
  @override
  @JsonKey(name: 'portfolio_turnover')
  double? get portfolioTurnover;
  @override
  @JsonKey(name: 'benchmark_index')
  String? get benchmarkIndex;
  @override
  @JsonKey(name: 'amfi_category_id')
  String? get amfiCategoryId;
  @override
  @JsonKey(name: 'benchmark_tier1')
  String? get benchmarkTier1;
  @override
  @JsonKey(name: 'benchmark_tier2')
  String? get benchmarkTier2;
  @override
  @JsonKey(name: 'exit_load')
  String? get exitLoad;
  @override
  @JsonKey(name: 'min_investment')
  double? get minInvestment;
  @override
  @JsonKey(name: 'min_sip_amount')
  double? get minSipAmount;
  @override
  @JsonKey(name: 'launch_date')
  String? get launchDate;
  @override
  @JsonKey(name: 'fund_category')
  String? get fundCategory;
  @override
  @JsonKey(name: 'fund_rating_date')
  String? get fundRatingDate;
  @override
  @JsonKey(name: 'investment_objective')
  String? get investmentObjective;
  @override
  @JsonKey(name: 'jan_31_nav')
  double? get jan31Nav;
  @override
  @JsonKey(name: 'lock_in_period')
  int get lockInPeriod;
  @override
  @JsonKey(name: 'tax_period')
  int? get taxPeriod;
  @override
  @JsonKey(name: 'maturity_type')
  String? get maturityType;
  @override
  @JsonKey(name: 'detail_info')
  String? get detailInfo;
  @override
  List<String>? get tags;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;

  /// Create a copy of FundModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FundModelImplCopyWith<_$FundModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
