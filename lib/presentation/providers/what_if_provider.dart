import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/asset_classes.dart';
import '../../data/models/fund_model.dart';
import '../../domain/usecases/calculate_sharpe.dart';
import '../../domain/usecases/calculate_xirr.dart';
import '../../domain/usecases/run_what_if_analysis.dart';
import 'fund_provider.dart';
import 'portfolio_provider.dart';

part 'what_if_provider.g.dart';

class WhatIfInputState {
  const WhatIfInputState({
    this.fund,
    this.amount = 5000,
    this.isSip = true,
    this.years = 5,
  });

  final FundModel? fund;
  final double amount;
  final bool isSip;
  final int years;

  WhatIfInputState copyWith({
    FundModel? fund,
    double? amount,
    bool? isSip,
    int? years,
  }) {
    return WhatIfInputState(
      fund: fund ?? this.fund,
      amount: amount ?? this.amount,
      isSip: isSip ?? this.isSip,
      years: years ?? this.years,
    );
  }
}

@riverpod
class WhatIfInputNotifier extends _$WhatIfInputNotifier {
  @override
  WhatIfInputState build() => const WhatIfInputState();

  void setFund(FundModel fund) => state = state.copyWith(fund: fund);
  void setAmount(double v) => state = state.copyWith(amount: v);
  void setSip(bool v) => state = state.copyWith(isSip: v);
  void setYears(int v) => state = state.copyWith(years: v);
}

/// Screen-friendly result flattened from WhatIfResult
class WhatIfScreenResult {
  const WhatIfScreenResult({
    required this.projectedValue,
    required this.totalInvested,
    required this.projectedGain,
    required this.projectedXirr,
    required this.newPortfolioXirr,
    required this.growthCurve,
    required this.beforeAllocationPct,
    required this.newAllocationPct,
  });

  final double projectedValue;
  final double totalInvested;
  final double projectedGain;
  final double? projectedXirr;
  final double? newPortfolioXirr;
  final List<({DateTime date, double value, double invested})> growthCurve;
  final Map<String, double> beforeAllocationPct;
  final Map<String, double> newAllocationPct;
}

@riverpod
Future<WhatIfScreenResult?> whatIfResult(WhatIfResultRef ref) async {
  final input = ref.watch(whatIfInputNotifierProvider);
  if (input.fund == null) return null;

  final navHistoryRaw =
      await ref.watch(navHistoryProvider(input.fund!.amfiCode).future);
  final portfolio =
      await ref.watch(portfolioSummaryProvider(null).future);

  // Convert nav history rows → NavPoint list
  final navHistory = navHistoryRaw.map((r) {
    return NavPoint(
      date: DateTime.parse(r['nav_date'] as String),
      nav: (r['nav'] as num).toDouble(),
    );
  }).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  if (navHistory.isEmpty) return null;

  // Determine asset class for the fund
  final assetClass = _fundToAssetClass(input.fund!);

  // Build existing cash flows from portfolio
  final existingFlows = <CashFlow>[];
  final allTxs = await ref.watch(allTransactionsProvider.future);
  for (final tx in allTxs) {
    existingFlows.add(CashFlow(
      amount: tx.isPurchase ? -tx.amount : tx.amount,
      date: tx.parsedDate,
    ));
  }

  final startDate = DateTime.now().subtract(Duration(days: input.years * 365));

  final whatIfInput = WhatIfInput(
    amfiCode: input.fund!.amfiCode,
    fundName: input.fund!.fundName,
    assetClass: assetClass,
    simulationType:
        input.isSip ? SimulationType.sip : SimulationType.lumpsum,
    amount: input.amount,
    startDate: startDate,
  );

  // Build allocation values map (AssetClass → value)
  final allocationValues = <AssetClass, double>{};
  for (final e in portfolio.allocationValue.entries) {
    final ac = AssetClass.values.where((a) => a.displayName == e.key).firstOrNull;
    if (ac != null) allocationValues[ac] = e.value;
  }

  final result = WhatIfAnalyzer.analyze(
    input: whatIfInput,
    navHistory: navHistory,
    existingPortfolioValue: portfolio.currentValue,
    existingInvested: portfolio.totalInvested,
    existingCashFlows: existingFlows,
    existingAllocationValues: allocationValues,
  );

  // Build growth curve with cumulative invested
  double invested = 0;
  final growthCurve = <({DateTime date, double value, double invested})>[];

  if (input.isSip) {
    var sipDate = startDate;
    final totalMonths = input.years * 12;
    for (int m = 0; m < totalMonths; m++) {
      invested += input.amount;
      sipDate = DateTime(sipDate.year, sipDate.month + 1, sipDate.day);
    }
    // Pair with growth points
    final investedPerPoint = invested / (result.growthPoints.isEmpty ? 1 : result.growthPoints.length);
    double runningInvested = 0;
    for (final pt in result.growthPoints) {
      runningInvested += investedPerPoint;
      growthCurve.add((date: pt.date, value: pt.value, invested: runningInvested));
    }
  } else {
    for (final pt in result.growthPoints) {
      growthCurve.add((date: pt.date, value: pt.value, invested: input.amount));
    }
  }

  // Convert allocation maps to string keys
  final beforePct = {
    for (final e in portfolio.allocationPct.entries) e.key: e.value,
  };
  final afterPct = {
    for (final e in result.allocationShift.entries)
      e.key.displayName: e.value,
  };

  return WhatIfScreenResult(
    projectedValue: result.currentValue,
    totalInvested: result.totalInvested,
    projectedGain: result.gain,
    projectedXirr: result.xirr.isNaN ? null : result.xirr * 100,
    newPortfolioXirr:
        result.newPortfolioXirr.isNaN ? null : result.newPortfolioXirr * 100,
    growthCurve: growthCurve,
    beforeAllocationPct: beforePct,
    newAllocationPct: afterPct,
  );
}

AssetClass _fundToAssetClass(FundModel fund) {
  final tax = (fund.taxCategory ?? '').toLowerCase();
  final cat = (fund.category ?? '').toLowerCase();

  if (cat.contains('liquid') || cat.contains('overnight')) {
    return AssetClass.liquid;
  }
  switch (tax) {
    case 'equity':
      return AssetClass.coreEquity;
    case 'hybrid-e':
      return AssetClass.hybrid;
    case 'hybrid-d':
      return AssetClass.hybrid;
    case 'debt':
      return AssetClass.debt;
    case 'gold':
    case 'gold etf':
      return AssetClass.gold;
    default:
      return AssetClass.alternate;
  }
}
