// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PortfolioSummaryImpl _$$PortfolioSummaryImplFromJson(
        Map<String, dynamic> json) =>
    _$PortfolioSummaryImpl(
      memberId: json['memberId'] as String?,
      memberName: json['memberName'] as String?,
      totalInvested: (json['totalInvested'] as num?)?.toDouble() ?? 0,
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0,
      totalGain: (json['totalGain'] as num?)?.toDouble() ?? 0,
      gainPct: (json['gainPct'] as num?)?.toDouble() ?? 0,
      xirr: (json['xirr'] as num?)?.toDouble(),
      cagr: (json['cagr'] as num?)?.toDouble(),
      todayGain: (json['todayGain'] as num?)?.toDouble() ?? 0,
      todayGainPct: (json['todayGainPct'] as num?)?.toDouble() ?? 0,
      allocationPct: (json['allocationPct'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
      allocationValue: (json['allocationValue'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
      fundHoldings: (json['fundHoldings'] as List<dynamic>?)
              ?.map(
                  (e) => FundHoldingSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      memberBreakdown: (json['memberBreakdown'] as List<dynamic>?)
              ?.map((e) => MemberSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      asOfDate: json['asOfDate'] == null
          ? null
          : DateTime.parse(json['asOfDate'] as String),
    );

Map<String, dynamic> _$$PortfolioSummaryImplToJson(
        _$PortfolioSummaryImpl instance) =>
    <String, dynamic>{
      'memberId': instance.memberId,
      'memberName': instance.memberName,
      'totalInvested': instance.totalInvested,
      'currentValue': instance.currentValue,
      'totalGain': instance.totalGain,
      'gainPct': instance.gainPct,
      'xirr': instance.xirr,
      'cagr': instance.cagr,
      'todayGain': instance.todayGain,
      'todayGainPct': instance.todayGainPct,
      'allocationPct': instance.allocationPct,
      'allocationValue': instance.allocationValue,
      'fundHoldings': instance.fundHoldings,
      'memberBreakdown': instance.memberBreakdown,
      'asOfDate': instance.asOfDate?.toIso8601String(),
    };

_$FundHoldingSummaryImpl _$$FundHoldingSummaryImplFromJson(
        Map<String, dynamic> json) =>
    _$FundHoldingSummaryImpl(
      amfiCode: (json['amfiCode'] as num).toInt(),
      fundName: json['fundName'] as String,
      assetType: json['assetType'] as String? ?? 'MF',
      category: json['category'] as String?,
      taxCategory: json['taxCategory'] as String?,
      assetClassLabel: json['assetClassLabel'] as String?,
      totalUnits: (json['totalUnits'] as num?)?.toDouble() ?? 0,
      totalInvested: (json['totalInvested'] as num?)?.toDouble() ?? 0,
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0,
      gain: (json['gain'] as num?)?.toDouble() ?? 0,
      gainPct: (json['gainPct'] as num?)?.toDouble() ?? 0,
      cagr: (json['cagr'] as num?)?.toDouble(),
      xirr: (json['xirr'] as num?)?.toDouble(),
      latestNav: (json['latestNav'] as num?)?.toDouble(),
      nav1dChangePct: (json['nav1dChangePct'] as num?)?.toDouble(),
      todayGain: (json['todayGain'] as num?)?.toDouble() ?? 0,
      isCoreFund: json['isCoreFund'] as bool? ?? false,
      amfiCategoryId: json['amfiCategoryId'] as String?,
      benchmarkTier1: json['benchmarkTier1'] as String?,
      benchmarkTier2: json['benchmarkTier2'] as String?,
      holderBreakdown: (json['holderBreakdown'] as List<dynamic>?)
              ?.map(
                  (e) => HolderFundSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      investedSince: json['investedSince'] == null
          ? null
          : DateTime.parse(json['investedSince'] as String),
      planType: json['planType'] as String?,
      expenseRatio: (json['expenseRatio'] as num?)?.toDouble(),
      return1y: (json['return1y'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$FundHoldingSummaryImplToJson(
        _$FundHoldingSummaryImpl instance) =>
    <String, dynamic>{
      'amfiCode': instance.amfiCode,
      'fundName': instance.fundName,
      'assetType': instance.assetType,
      'category': instance.category,
      'taxCategory': instance.taxCategory,
      'assetClassLabel': instance.assetClassLabel,
      'totalUnits': instance.totalUnits,
      'totalInvested': instance.totalInvested,
      'currentValue': instance.currentValue,
      'gain': instance.gain,
      'gainPct': instance.gainPct,
      'cagr': instance.cagr,
      'xirr': instance.xirr,
      'latestNav': instance.latestNav,
      'nav1dChangePct': instance.nav1dChangePct,
      'todayGain': instance.todayGain,
      'isCoreFund': instance.isCoreFund,
      'amfiCategoryId': instance.amfiCategoryId,
      'benchmarkTier1': instance.benchmarkTier1,
      'benchmarkTier2': instance.benchmarkTier2,
      'holderBreakdown': instance.holderBreakdown,
      'investedSince': instance.investedSince?.toIso8601String(),
      'planType': instance.planType,
      'expenseRatio': instance.expenseRatio,
      'return1y': instance.return1y,
    };

_$HolderFundSummaryImpl _$$HolderFundSummaryImplFromJson(
        Map<String, dynamic> json) =>
    _$HolderFundSummaryImpl(
      memberId: json['memberId'] as String,
      memberName: json['memberName'] as String,
      units: (json['units'] as num?)?.toDouble() ?? 0,
      invested: (json['invested'] as num?)?.toDouble() ?? 0,
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0,
      gain: (json['gain'] as num?)?.toDouble() ?? 0,
      cagr: (json['cagr'] as num?)?.toDouble(),
      xirr: (json['xirr'] as num?)?.toDouble(),
      folioNumber: json['folioNumber'] as String?,
    );

Map<String, dynamic> _$$HolderFundSummaryImplToJson(
        _$HolderFundSummaryImpl instance) =>
    <String, dynamic>{
      'memberId': instance.memberId,
      'memberName': instance.memberName,
      'units': instance.units,
      'invested': instance.invested,
      'currentValue': instance.currentValue,
      'gain': instance.gain,
      'cagr': instance.cagr,
      'xirr': instance.xirr,
      'folioNumber': instance.folioNumber,
    };

_$MemberSummaryImpl _$$MemberSummaryImplFromJson(Map<String, dynamic> json) =>
    _$MemberSummaryImpl(
      memberId: json['memberId'] as String,
      memberName: json['memberName'] as String,
      colorHex: json['colorHex'] as String?,
      invested: (json['invested'] as num?)?.toDouble() ?? 0,
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0,
      gain: (json['gain'] as num?)?.toDouble() ?? 0,
      gainPct: (json['gainPct'] as num?)?.toDouble() ?? 0,
      xirr: (json['xirr'] as num?)?.toDouble(),
      cagr: (json['cagr'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$MemberSummaryImplToJson(_$MemberSummaryImpl instance) =>
    <String, dynamic>{
      'memberId': instance.memberId,
      'memberName': instance.memberName,
      'colorHex': instance.colorHex,
      'invested': instance.invested,
      'currentValue': instance.currentValue,
      'gain': instance.gain,
      'gainPct': instance.gainPct,
      'xirr': instance.xirr,
      'cagr': instance.cagr,
    };
