import 'package:freezed_annotation/freezed_annotation.dart';

part 'fund_model.freezed.dart';
part 'fund_model.g.dart';

@freezed
class FundModel with _$FundModel {
  const factory FundModel({
    @JsonKey(name: 'amfi_code') required int amfiCode,
    @JsonKey(name: 'isin_growth') String? isinGrowth,
    @JsonKey(name: 'isin_div_reinvest') String? isinDivReinvest,
    @JsonKey(name: 'fund_name') required String fundName,
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
    @JsonKey(name: 'lock_in_period') @Default(0) int lockInPeriod,
    @JsonKey(name: 'tax_period') int? taxPeriod,
    @JsonKey(name: 'maturity_type') String? maturityType,
    @JsonKey(name: 'detail_info') String? detailInfo,
    List<String>? tags,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _FundModel;

  factory FundModel.fromJson(Map<String, dynamic> json) =>
      _$FundModelFromJson(json);

  const FundModel._();

  /// 1-day NAV change percentage
  double? get nav1dChangePct {
    if (latestNav == null || prevNav == null || prevNav == 0) return null;
    return ((latestNav! - prevNav!) / prevNav!) * 100;
  }

  /// Formatted fund manager string
  String get fundManagerDisplay {
    if (fundManagers == null || fundManagers!.isEmpty) return '—';
    return fundManagers!.join(', ');
  }
}
