// lib/domain/usecases/compute_behavior_impact.dart

import 'dart:math' as math;
import '../models/projection_models.dart';

/// Quantifies the financial cost of common behavioral investor mistakes.
class BehaviorImpactCalculator {
  /// Compute behavior scenarios.
  ///
  /// Three scenarios:
  /// 1. **Stay Invested** — baseline (no mistake)
  /// 2. **Panic Sell** — sell at a 30% crash, stay in cash 6 months, re-enter
  /// 3. **Stop SIP 1 Year** — pause SIP for 12 months during downturn
  static List<BehaviorScenario> compute({
    required double currentValue,
    required double monthlySip,
    required int horizonYears,
    required double expectedReturn,
  }) {
    final baseline = _projectValue(
      currentValue: currentValue,
      monthlySip: monthlySip,
      months: horizonYears * 12,
      annualReturn: expectedReturn,
    );

    return [
      // 1. Stay Invested (baseline)
      BehaviorScenario(
        name: 'Stay Invested',
        description: 'Continue SIP and stay fully invested throughout',
        projectedValue: baseline,
        baselineValue: baseline,
        costOfMistake: 0,
        costPct: 0,
        insight: 'Discipline is the best strategy. Stay the course.',
      ),

      // 2. Panic Sell — crash happens in month 12
      _panicSellScenario(currentValue, monthlySip, horizonYears, expectedReturn, baseline),

      // 3. Stop SIP for 1 year — no SIP from month 12-24
      _stopSipScenario(currentValue, monthlySip, horizonYears, expectedReturn, baseline),
    ];
  }

  /// Panic sell: market drops 30% in month 12, investor sells everything,
  /// sits in cash for 6 months, then re-enters at recovered price.
  static BehaviorScenario _panicSellScenario(
    double currentValue,
    double monthlySip,
    int horizonYears,
    double expectedReturn,
    double baseline,
  ) {
    final totalMonths = horizonYears * 12;
    if (totalMonths <= 18) {
      // Too short for panic scenario to play out meaningfully
      return BehaviorScenario(
        name: 'Panic Sell',
        description: 'Sell at a 30% crash, stay in cash 6 months, re-enter',
        projectedValue: baseline * 0.85, // rough estimate
        baselineValue: baseline,
        costOfMistake: baseline * 0.15,
        costPct: 15.0,
        insight: 'Panic selling locks in losses and misses the recovery.',
      );
    }

    // Phase 1: Invest normally for 12 months
    double value = currentValue;
    final monthlyReturn = expectedReturn / 100 / 12;
    for (int m = 0; m < 12; m++) {
      value += monthlySip;
      value *= (1 + monthlyReturn);
    }

    // Month 12: Market crashes 30% — panic sell everything
    value *= 0.70; // 30% crash
    final cashOut = value; // sell at bottom

    // Months 13-18: Sit in cash, no growth, no SIP
    final missedSip = monthlySip * 6;

    // Month 19: Re-enter market (market has recovered ~15% from bottom)
    final reEntryValue = cashOut; // re-enter at same price (missed recovery)

    // Phase 3: Continue investing for remaining months
    final remainingMonths = totalMonths - 18;
    final finalValue = _projectValue(
      currentValue: reEntryValue,
      monthlySip: monthlySip,
      months: remainingMonths,
      annualReturn: expectedReturn,
    );

    // Add back the SIP money that was saved during cash period (uninvested)
    final finalWithMissedSip = finalValue + missedSip *
        math.pow(1 + monthlyReturn, remainingMonths);

    final cost = baseline - finalWithMissedSip;
    final costPct = baseline > 0 ? (cost / baseline * 100).clamp(0, 100) : 0.0;

    return BehaviorScenario(
      name: 'Panic Sell',
      description: 'Sell at a 30% crash, stay in cash 6 months, re-enter',
      projectedValue: finalWithMissedSip,
      baselineValue: baseline,
      costOfMistake: math.max(cost, 0),
      costPct: costPct.toDouble(),
      insight: 'Panic selling locks in losses and misses the recovery.',
    );
  }

  /// Stop SIP: pause SIP for 12 months (months 12-24), then resume.
  static BehaviorScenario _stopSipScenario(
    double currentValue,
    double monthlySip,
    int horizonYears,
    double expectedReturn,
    double baseline,
  ) {
    final totalMonths = horizonYears * 12;
    final monthlyReturn = expectedReturn / 100 / 12;

    // Phase 1: Normal investing for 12 months
    double value = currentValue;
    for (int m = 0; m < math.min(12, totalMonths); m++) {
      value += monthlySip;
      value *= (1 + monthlyReturn);
    }

    // Phase 2: No SIP for 12 months (portfolio still grows)
    final sipPauseMonths = math.min(12, totalMonths - 12);
    for (int m = 0; m < sipPauseMonths; m++) {
      // No SIP, but existing investments compound
      value *= (1 + monthlyReturn);
    }

    // Phase 3: Resume SIP for remaining months
    final remainingMonths = totalMonths - 12 - sipPauseMonths;
    for (int m = 0; m < remainingMonths; m++) {
      value += monthlySip;
      value *= (1 + monthlyReturn);
    }

    final cost = baseline - value;
    final costPct = baseline > 0 ? (cost / baseline * 100).clamp(0, 100) : 0.0;

    return BehaviorScenario(
      name: 'Stop SIP 1 Year',
      description: 'Pause monthly SIP for 12 months, then resume',
      projectedValue: value,
      baselineValue: baseline,
      costOfMistake: math.max(cost, 0),
      costPct: costPct.toDouble(),
      insight: 'Missing 12 months of SIP costs more than you think due to lost compounding.',
    );
  }

  /// Simple future value projection with monthly SIP and compounding.
  static double _projectValue({
    required double currentValue,
    required double monthlySip,
    required int months,
    required double annualReturn,
  }) {
    final monthlyReturn = annualReturn / 100 / 12;
    double value = currentValue;
    for (int m = 0; m < months; m++) {
      value += monthlySip;
      value *= (1 + monthlyReturn);
    }
    return value;
  }
}
