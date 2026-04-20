import 'calculate_xirr.dart';
import 'calculate_sharpe.dart';
import '../../core/constants/asset_classes.dart';

enum SimulationType { sip, lumpsum }

class WhatIfInput {
  const WhatIfInput({
    required this.amfiCode,
    required this.fundName,
    required this.assetClass,
    required this.simulationType,
    required this.amount,       // monthly SIP or lumpsum amount
    required this.startDate,
    this.endDate,               // null = till today
    this.taxCategory,
  });

  final int amfiCode;
  final String fundName;
  final AssetClass assetClass;
  final SimulationType simulationType;
  final double amount;
  final DateTime startDate;
  final DateTime? endDate;
  final TaxCategory? taxCategory;
}

class WhatIfResult {
  const WhatIfResult({
    required this.input,
    required this.totalInvested,
    required this.currentValue,
    required this.gain,
    required this.gainPct,
    required this.xirr,
    required this.newPortfolioXirr,
    required this.newPortfolioValue,
    required this.newPortfolioInvested,
    required this.allocationShift,
    required this.growthPoints,
  });

  final WhatIfInput input;
  final double totalInvested;
  final double currentValue;
  final double gain;
  final double gainPct;
  final double xirr;               // XIRR just for this simulation
  final double newPortfolioXirr;   // XIRR of current portfolio + simulation
  final double newPortfolioValue;
  final double newPortfolioInvested;
  final Map<AssetClass, double> allocationShift; // new allocation % after adding fund
  final List<({DateTime date, double value})> growthPoints; // portfolio growth curve
}

class WhatIfAnalyzer {
  WhatIfAnalyzer._();

  /// Simulate adding a new fund/SIP to the portfolio
  /// [navHistory] is the full historical NAV of the simulated fund
  /// [existingPortfolioValue] is current portfolio value excluding this simulation
  /// [existingInvested] is current portfolio total invested excluding this simulation
  /// [existingCashFlows] for computing new overall XIRR
  static WhatIfResult analyze({
    required WhatIfInput input,
    required List<NavPoint> navHistory,
    required double existingPortfolioValue,
    required double existingInvested,
    required List<CashFlow> existingCashFlows,
    required Map<AssetClass, double> existingAllocationValues,
  }) {
    if (navHistory.isEmpty) {
      return _emptyResult(input, existingPortfolioValue, existingInvested, existingAllocationValues, existingCashFlows);
    }

    final sorted = List<NavPoint>.from(navHistory)
      ..sort((a, b) => a.date.compareTo(b.date));

    final endDate = input.endDate ?? DateTime.now();
    final simFlows = <CashFlow>[];
    final growthPoints = <({DateTime date, double value})>[];
    double totalInvested = 0;

    if (input.simulationType == SimulationType.lumpsum) {
      // Find NAV on start date
      final navOnStart = _navOnDate(sorted, input.startDate);
      if (navOnStart != null && navOnStart.nav > 0) {
        final units = input.amount / navOnStart.nav;
        simFlows.add(CashFlow(amount: -input.amount, date: input.startDate));
        totalInvested = input.amount;

        // Build growth curve
        for (final p in sorted.where((p) => !p.date.isBefore(input.startDate))) {
          if (p.date.isAfter(endDate)) break;
          growthPoints.add((date: p.date, value: units * p.nav));
        }
      }
    } else {
      // SIP: monthly purchase
      var sipDate = DateTime(input.startDate.year, input.startDate.month, input.startDate.day);
      while (!sipDate.isAfter(endDate)) {
        final nav = _navOnDate(sorted, sipDate);
        if (nav != null && nav.nav > 0) {
          simFlows.add(CashFlow(amount: -input.amount, date: sipDate));
          totalInvested += input.amount;
        }
        // Advance by 1 month
        sipDate = DateTime(sipDate.year, sipDate.month + 1, sipDate.day);
      }

      // Build approximate growth curve (cumulative units × current NAV)
      if (simFlows.isNotEmpty) {
        double units = 0;
        var purchaseIdx = 0;
        for (final p in sorted.where((p) => !p.date.isBefore(input.startDate))) {
          if (p.date.isAfter(endDate)) break;
          // Add units from SIP purchases up to this date
          while (purchaseIdx < simFlows.length &&
              !simFlows[purchaseIdx].date.isAfter(p.date)) {
            final sipNav = _navOnDate(sorted, simFlows[purchaseIdx].date);
            if (sipNav != null && sipNav.nav > 0) {
              units += input.amount / sipNav.nav;
            }
            purchaseIdx++;
          }
          growthPoints.add((date: p.date, value: units * p.nav));
        }
      }
    }

    // Current value of simulation
    final latestNav = sorted.last.nav;
    double currentValue = 0;
    if (growthPoints.isNotEmpty) {
      currentValue = growthPoints.last.value;
    }

    final gain = currentValue - totalInvested;
    final gainPct = totalInvested > 0 ? (gain / totalInvested) * 100 : 0.0;

    // XIRR for just this simulation
    final allSimFlows = [...simFlows, CashFlow(amount: currentValue, date: endDate)];
    final xirr = XirrCalculator.compute(allSimFlows);

    // New portfolio XIRR
    final newXirrFlows = [
      ...existingCashFlows,
      ...simFlows,
      CashFlow(
        amount: existingPortfolioValue + currentValue,
        date: endDate,
      ),
    ];
    // Remove old current value from existingCashFlows if present (it's replaced above)
    final filteredFlows = newXirrFlows.where((f) => f.amount > 0 || f.date != endDate).toList();
    final newPortfolioXirr = XirrCalculator.compute(filteredFlows);

    // New allocation
    final newAllocationValues = Map<AssetClass, double>.from(existingAllocationValues);
    newAllocationValues[input.assetClass] =
        (newAllocationValues[input.assetClass] ?? 0) + currentValue;
    final newPortfolioValue = existingPortfolioValue + currentValue;
    final newAllocationPct = <AssetClass, double>{};
    if (newPortfolioValue > 0) {
      for (final e in newAllocationValues.entries) {
        newAllocationPct[e.key] = (e.value / newPortfolioValue) * 100;
      }
    }

    return WhatIfResult(
      input: input,
      totalInvested: totalInvested,
      currentValue: currentValue,
      gain: gain,
      gainPct: gainPct,
      xirr: xirr,
      newPortfolioXirr: newPortfolioXirr,
      newPortfolioValue: newPortfolioValue,
      newPortfolioInvested: existingInvested + totalInvested,
      allocationShift: newAllocationPct,
      growthPoints: growthPoints,
    );
  }

  static NavPoint? _navOnDate(List<NavPoint> sorted, DateTime date) {
    // Find exact or nearest NAV within 7 days
    final target = DateTime(date.year, date.month, date.day);
    NavPoint? best;
    int minDiff = 8;

    for (final p in sorted) {
      final pDate = DateTime(p.date.year, p.date.month, p.date.day);
      final diff = (pDate.difference(target).inDays).abs();
      if (diff < minDiff) {
        minDiff = diff;
        best = p;
      }
      if (pDate.isAfter(target.add(const Duration(days: 7)))) break;
    }
    return best;
  }

  static WhatIfResult _emptyResult(
    WhatIfInput input,
    double existingValue,
    double existingInvested,
    Map<AssetClass, double> existingAllocation,
    List<CashFlow> existingFlows,
  ) {
    return WhatIfResult(
      input: input,
      totalInvested: 0,
      currentValue: 0,
      gain: 0,
      gainPct: 0,
      xirr: double.nan,
      newPortfolioXirr: XirrCalculator.compute(existingFlows),
      newPortfolioValue: existingValue,
      newPortfolioInvested: existingInvested,
      allocationShift: {
        for (final e in existingAllocation.entries)
          e.key: existingValue > 0 ? (e.value / existingValue) * 100 : 0,
      },
      growthPoints: [],
    );
  }
}
