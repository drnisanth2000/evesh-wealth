// lib/domain/usecases/compute_portfolio_projection.dart

import 'dart:math' as math;

import '../../core/constants/app_constants.dart';
import '../models/projection_models.dart';

/// Computes multi-scenario portfolio projections, waterfall breakdown, and benchmarks.
class PortfolioProjectionCalculator {
  /// Scenario return rates: conservative uses expected-4%, aggressive uses expected+4%.
  static const _conservativeSpread = -4.0;
  static const _aggressiveSpread = 4.0;

  /// Benchmark return assumptions (annual %).
  static const _niftyReturn = 12.0;
  static const _fdPreTaxReturn = 7.0;
  static const _ppfReturn = 7.1;

  static ProjectionResult compute(ProjectionInput input) {
    final scenarios = _buildScenarios(input);
    final waterfall = _buildWaterfall(input, scenarios[1]); // use moderate
    final benchmarks = _buildBenchmarks(input);

    return ProjectionResult(
      input: input,
      scenarios: scenarios,
      waterfall: waterfall,
      benchmarks: benchmarks,
      stressTests: const [],  // populated by separate calculator
      behaviorScenarios: const [], // populated by separate calculator
    );
  }

  // ── Scenarios ──────────────────────────────────────────────────────────────

  static List<GrowthScenario> _buildScenarios(ProjectionInput input) {
    final conservativeReturn = math.max(input.expectedReturn + _conservativeSpread, 1.0);
    final moderateReturn = input.expectedReturn;
    final aggressiveReturn = input.expectedReturn + _aggressiveSpread;

    return [
      _projectScenario('Conservative', conservativeReturn, input),
      _projectScenario('Moderate', moderateReturn, input),
      _projectScenario('Aggressive', aggressiveReturn, input),
    ];
  }

  static GrowthScenario _projectScenario(
    String name,
    double annualReturn,
    ProjectionInput input,
  ) {
    final monthlyReturn = annualReturn / 100 / 12;
    final points = <ProjectionPoint>[];
    double value = input.currentPortfolioValue;
    final annualSip = input.monthlySip * 12;

    for (int year = 1; year <= input.horizonYears; year++) {
      final startValue = value;

      // Monthly compounding with SIP
      for (int month = 0; month < 12; month++) {
        value += input.monthlySip; // SIP at start of month
        value *= (1 + monthlyReturn); // compound
      }

      final growth = value - startValue - annualSip;
      points.add(ProjectionPoint(
        year: year,
        startValue: startValue,
        sipAdded: annualSip,
        growth: growth,
        endValue: value,
      ));
    }

    final totalInvested = input.currentPortfolioValue + (input.monthlySip * 12 * input.horizonYears);
    final totalGain = value - totalInvested;
    final wealthMultiple = totalInvested > 0 ? value / totalInvested : 0.0;

    return GrowthScenario(
      name: name,
      annualReturn: annualReturn,
      points: points,
      finalValue: value,
      totalInvested: totalInvested,
      totalGain: totalGain,
      wealthMultiple: wealthMultiple,
    );
  }

  // ── Waterfall ──────────────────────────────────────────────────────────────

  static List<WaterfallStep> _buildWaterfall(
    ProjectionInput input,
    GrowthScenario moderateScenario,
  ) {
    final steps = <WaterfallStep>[];
    final currentValue = input.currentPortfolioValue;
    double running = currentValue;

    // Step 1: Current portfolio
    steps.add(WaterfallStep(
      label: 'Current Portfolio',
      value: currentValue,
      runningTotal: running,
      isPositive: true,
    ));

    // Step 2: SIP contributions
    final totalSip = input.monthlySip * 12 * input.horizonYears;
    running += totalSip;
    steps.add(WaterfallStep(
      label: 'SIP Contributions',
      value: totalSip,
      runningTotal: running,
      isPositive: true,
    ));

    // Step 3: Investment returns (growth portion)
    final nominalFinal = moderateScenario.finalValue;
    final totalInvested = moderateScenario.totalInvested;
    final returnsEarned = nominalFinal - totalInvested;
    running += returnsEarned;
    steps.add(WaterfallStep(
      label: 'Expected Returns',
      value: returnsEarned,
      runningTotal: running,
      isPositive: true,
    ));

    // Step 4: Estimated tax
    final equityPct = (input.allocationPct['coreEquity'] ?? 0) +
        (input.allocationPct['satelliteEquity'] ?? 0) +
        (input.allocationPct['hybrid'] ?? 0) * 0.65;
    final debtPct = 100 - equityPct;
    final equityGain = returnsEarned * (equityPct / 100);
    final debtGain = returnsEarned * (debtPct / 100);

    // Equity LTCG on gains above the per-FY exemption (rates from AppConstants)
    final annualEquityGain = equityGain / input.horizonYears;
    final taxableEquityGainPerYear = math.max(
        annualEquityGain - AppConstants.ltcgExemptionPerPersonPerFy, 0.0);
    final equityTax =
        taxableEquityGainPerYear * AppConstants.equityLtcgRate * input.horizonYears;

    // Debt: slab rate on all gains
    final debtTax = debtGain * (input.taxSlabPct / 100);

    final totalTax =
        (equityTax + debtTax) * (1 + AppConstants.healthEducationCess);
    running -= totalTax;
    steps.add(WaterfallStep(
      label: 'Estimated Tax',
      value: totalTax,
      runningTotal: running,
      isPositive: false,
    ));

    // Step 5: Inflation erosion (nominal → real)
    final realValue = nominalFinal / math.pow(1 + input.inflationRate / 100, input.horizonYears);
    final inflationErosion = nominalFinal - realValue;
    steps.add(WaterfallStep(
      label: 'Inflation Erosion',
      value: inflationErosion,
      runningTotal: running - inflationErosion,
      isPositive: false,
    ));

    // Step 6: Real value (today's money)
    steps.add(WaterfallStep(
      label: 'Real Value',
      value: running - inflationErosion,
      runningTotal: running - inflationErosion,
      isPositive: true,
    ));

    return steps;
  }

  // ── Benchmarks ─────────────────────────────────────────────────────────────

  static List<BenchmarkLine> _buildBenchmarks(ProjectionInput input) {
    final fdPostTax = _fdPreTaxReturn * (1 - input.taxSlabPct / 100);

    return [
      _buildBenchmarkLine('Your Portfolio', input.expectedReturn, input),
      _buildBenchmarkLine('Nifty 50', _niftyReturn, input),
      _buildBenchmarkLine('FD (Post-Tax)', fdPostTax, input),
      _buildBenchmarkLine('PPF', _ppfReturn, input),
    ];
  }

  static BenchmarkLine _buildBenchmarkLine(
    String name,
    double annualReturn,
    ProjectionInput input,
  ) {
    final monthlyReturn = annualReturn / 100 / 12;
    final yearlyValues = <double>[];
    double value = input.currentPortfolioValue;

    for (int year = 0; year < input.horizonYears; year++) {
      for (int month = 0; month < 12; month++) {
        value += input.monthlySip;
        value *= (1 + monthlyReturn);
      }
      yearlyValues.add(value);
    }

    return BenchmarkLine(
      name: name,
      annualReturn: annualReturn,
      finalValue: value,
      yearlyValues: yearlyValues,
    );
  }
}
