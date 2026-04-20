// lib/domain/models/projection_models.dart

/// Input parameters for all projection calculations.
class ProjectionInput {
  final double currentPortfolioValue;
  final double monthlySip;             // ongoing monthly SIP (₹)
  final int horizonYears;              // projection horizon
  final double expectedReturn;         // annual % (from risk profile)
  final double inflationRate;          // annual % (default 6%)
  final Map<String, double> allocationPct; // assetClassKey → current %
  final double taxSlabPct;             // member's income tax slab

  const ProjectionInput({
    required this.currentPortfolioValue,
    required this.monthlySip,
    required this.horizonYears,
    required this.expectedReturn,
    this.inflationRate = 6.0,
    required this.allocationPct,
    this.taxSlabPct = 30.0,
  });
}

// ── Scenario Models ──────────────────────────────────────────────────────────

/// A single year's projection data point.
class ProjectionPoint {
  final int year;
  final double startValue;
  final double sipAdded;        // total SIP for this year
  final double growth;          // returns earned this year
  final double endValue;

  const ProjectionPoint({
    required this.year,
    required this.startValue,
    required this.sipAdded,
    required this.growth,
    required this.endValue,
  });
}

/// A named growth scenario (e.g. Conservative, Moderate, Aggressive).
class GrowthScenario {
  final String name;
  final double annualReturn;    // % per year
  final List<ProjectionPoint> points;
  final double finalValue;
  final double totalInvested;
  final double totalGain;
  final double wealthMultiple;  // finalValue / totalInvested

  const GrowthScenario({
    required this.name,
    required this.annualReturn,
    required this.points,
    required this.finalValue,
    required this.totalInvested,
    required this.totalGain,
    required this.wealthMultiple,
  });
}

// ── Waterfall Models ─────────────────────────────────────────────────────────

/// A single step in the waterfall chart.
class WaterfallStep {
  final String label;
  final double value;           // absolute value for this step
  final double runningTotal;    // cumulative after this step
  final bool isPositive;        // green or red

  const WaterfallStep({
    required this.label,
    required this.value,
    required this.runningTotal,
    required this.isPositive,
  });
}

// ── Benchmark Models ─────────────────────────────────────────────────────────

/// A benchmark comparison line (e.g. Nifty 50, FD, PPF).
class BenchmarkLine {
  final String name;
  final double annualReturn;
  final double finalValue;
  final List<double> yearlyValues; // value at end of each year

  const BenchmarkLine({
    required this.name,
    required this.annualReturn,
    required this.finalValue,
    required this.yearlyValues,
  });
}

// ── Stress Test Models ───────────────────────────────────────────────────────

/// A historical crash scenario applied to the current portfolio.
class StressScenario {
  final String name;            // e.g. '2008 GFC'
  final String description;     // e.g. 'Global Financial Crisis'
  final int year;               // 2008, 2020, etc.
  final Map<String, double> assetClassDrawdown; // assetClassKey → drawdown %
  final double portfolioDrawdownPct;  // weighted drawdown for this portfolio
  final double portfolioLoss;         // ₹ loss
  final double nadir;                // portfolio value at bottom
  final int recoveryMonths;           // months to recover to pre-crash level

  const StressScenario({
    required this.name,
    required this.description,
    required this.year,
    required this.assetClassDrawdown,
    required this.portfolioDrawdownPct,
    required this.portfolioLoss,
    required this.nadir,
    required this.recoveryMonths,
  });
}

// ── Behavior Models ──────────────────────────────────────────────────────────

/// A behavioral scenario showing cost of a common investor mistake.
class BehaviorScenario {
  final String name;            // e.g. 'Panic Sell'
  final String description;     // what happens
  final double projectedValue;  // final value with this behavior
  final double baselineValue;   // final value staying invested
  final double costOfMistake;   // baselineValue - projectedValue (₹)
  final double costPct;         // cost as % of baseline
  final String insight;         // one-liner takeaway

  const BehaviorScenario({
    required this.name,
    required this.description,
    required this.projectedValue,
    required this.baselineValue,
    required this.costOfMistake,
    required this.costPct,
    required this.insight,
  });
}

// ── Aggregate Results ────────────────────────────────────────────────────────

/// Complete projection result combining all engines.
class ProjectionResult {
  final ProjectionInput input;
  final List<GrowthScenario> scenarios;     // [conservative, moderate, aggressive]
  final List<WaterfallStep> waterfall;
  final List<BenchmarkLine> benchmarks;
  final List<StressScenario> stressTests;
  final List<BehaviorScenario> behaviorScenarios;

  const ProjectionResult({
    required this.input,
    required this.scenarios,
    required this.waterfall,
    required this.benchmarks,
    required this.stressTests,
    required this.behaviorScenarios,
  });
}
