import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/asset_classes.dart';

part 'portfolio_summary_model.freezed.dart';
part 'portfolio_summary_model.g.dart';

/// Aggregated portfolio metrics for a member or family
@freezed
class PortfolioSummary with _$PortfolioSummary {
  const factory PortfolioSummary({
    /// null = family view; non-null = individual member
    String? memberId,
    String? memberName,
    @Default(0) double totalInvested,
    @Default(0) double currentValue,
    @Default(0) double totalGain,
    @Default(0) double gainPct,
    double? xirr,
    double? cagr,
    @Default(0) double todayGain,
    @Default(0) double todayGainPct,
    @Default({}) Map<String, double> allocationPct,    // asset class → %
    @Default({}) Map<String, double> allocationValue,  // asset class → Rs
    @Default([]) List<FundHoldingSummary> fundHoldings,
    @Default([]) List<MemberSummary> memberBreakdown,  // for family view
    DateTime? asOfDate,
  }) = _PortfolioSummary;

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) =>
      _$PortfolioSummaryFromJson(json);

  const PortfolioSummary._();

  bool get hasData => totalInvested > 0 || currentValue > 0;
}

/// Per-fund holding summary
@freezed
class FundHoldingSummary with _$FundHoldingSummary {
  const factory FundHoldingSummary({
    required int amfiCode,
    required String fundName,
    @Default('MF') String assetType,   // DB value: MF, Stock, Gold, etc.
    String? category,
    String? taxCategory,
    String? assetClassLabel,
    @Default(0) double totalUnits,
    @Default(0) double totalInvested,
    @Default(0) double currentValue,
    @Default(0) double gain,
    @Default(0) double gainPct,
    double? cagr,
    double? xirr,
    double? latestNav,
    double? nav1dChangePct,
    @Default(0) double todayGain,     // units × (nav - prevNav)
    @Default(false) bool isCoreFund,  // CORE vs SATELLITE
    // ── AMFI / SEBI 2018 categorisation ──
    String? amfiCategoryId,
    String? benchmarkTier1,
    String? benchmarkTier2,
    @Default([]) List<HolderFundSummary> holderBreakdown,
    // ── Investor details ──
    DateTime? investedSince,
    String? planType,
    double? expenseRatio,
    double? return1y,
  }) = _FundHoldingSummary;

  const FundHoldingSummary._();

  factory FundHoldingSummary.fromJson(Map<String, dynamic> json) =>
      _$FundHoldingSummaryFromJson(json);

  /// Holding period formatted as "2y 3m" or "45d"
  String? get holdingPeriodFormatted {
    if (investedSince == null) return null;
    final days = DateTime.now().difference(investedSince!).inDays;
    if (days >= 365) {
      final years = days ~/ 365;
      final months = (days % 365) ~/ 30;
      return months > 0 ? '${years}y ${months}m' : '${years}y';
    } else if (days >= 30) {
      return '${days ~/ 30}m ${days % 30}d';
    }
    return '${days}d';
  }
}

/// Per-holder breakdown within a fund
@freezed
class HolderFundSummary with _$HolderFundSummary {
  const factory HolderFundSummary({
    required String memberId,
    required String memberName,
    @Default(0) double units,
    @Default(0) double invested,
    @Default(0) double currentValue,
    @Default(0) double gain,
    double? cagr,
    double? xirr,
    String? folioNumber,
  }) = _HolderFundSummary;

  factory HolderFundSummary.fromJson(Map<String, dynamic> json) =>
      _$HolderFundSummaryFromJson(json);
}

/// Per-member summary for family dashboard view
@freezed
class MemberSummary with _$MemberSummary {
  const factory MemberSummary({
    required String memberId,
    required String memberName,
    String? colorHex,
    @Default(0) double invested,
    @Default(0) double currentValue,
    @Default(0) double gain,
    @Default(0) double gainPct,
    double? xirr,
    double? cagr,
  }) = _MemberSummary;

  factory MemberSummary.fromJson(Map<String, dynamic> json) =>
      _$MemberSummaryFromJson(json);
}
