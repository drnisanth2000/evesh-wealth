// lib/domain/usecases/compute_stress_test.dart

import '../models/projection_models.dart';

/// Applies historical crash scenarios to the current portfolio allocation.
class StressTestCalculator {
  /// Historical crash data: asset class → drawdown % (negative).
  /// Recovery months are historical actuals.
  static const _scenarios = <Map<String, dynamic>>[
    {
      'name': '2008 GFC',
      'description': 'Global Financial Crisis — Lehman collapse, credit freeze',
      'year': 2008,
      'drawdowns': {
        'coreEquity': -52.0,
        'satelliteEquity': -60.0,
        'hybrid': -35.0,
        'debt': -8.0,
        'liquid': 0.0,
        'gold': 15.0,   // gold rallied
        'alternatives': -40.0,
      },
      'recoveryMonths': 22,
    },
    {
      'name': '2020 COVID',
      'description': 'COVID-19 pandemic — fastest crash and recovery in history',
      'year': 2020,
      'drawdowns': {
        'coreEquity': -38.0,
        'satelliteEquity': -45.0,
        'hybrid': -22.0,
        'debt': -5.0,
        'liquid': 0.0,
        'gold': 25.0,   // gold as safe haven
        'alternatives': -30.0,
      },
      'recoveryMonths': 8,
    },
    {
      'name': '2015 Correction',
      'description': 'China slowdown fears, FII outflows, mid/small cap rout',
      'year': 2015,
      'drawdowns': {
        'coreEquity': -18.0,
        'satelliteEquity': -32.0,
        'hybrid': -12.0,
        'debt': -2.0,
        'liquid': 0.0,
        'gold': 8.0,
        'alternatives': -20.0,
      },
      'recoveryMonths': 14,
    },
  ];

  /// Compute stress test impact for the current portfolio.
  static List<StressScenario> compute({
    required double portfolioValue,
    required Map<String, double> allocationPct,
  }) {
    return _scenarios.map((s) {
      final drawdowns = s['drawdowns'] as Map<String, double>;

      // Weighted portfolio drawdown based on allocation
      double weightedDrawdown = 0;
      for (final entry in allocationPct.entries) {
        final assetDrawdown = drawdowns[entry.key] ?? 0.0;
        weightedDrawdown += assetDrawdown * (entry.value / 100);
      }

      final loss = portfolioValue * (weightedDrawdown.abs() / 100);
      // If weighted drawdown is positive (unlikely), loss = 0
      final actualLoss = weightedDrawdown < 0 ? loss : 0.0;
      final nadir = portfolioValue - actualLoss;

      return StressScenario(
        name: s['name'] as String,
        description: s['description'] as String,
        year: s['year'] as int,
        assetClassDrawdown: drawdowns,
        portfolioDrawdownPct: weightedDrawdown,
        portfolioLoss: actualLoss,
        nadir: nadir,
        recoveryMonths: s['recoveryMonths'] as int,
      );
    }).toList();
  }
}
