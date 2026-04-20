import '../models/allocation_models.dart';

/// Display name mapping for each asset class key.
const _displayNames = <String, String>{
  'coreEquity': 'Core Equity',
  'debt': 'Debt',
  'gold': 'Gold',
  'satelliteEquity': 'Satellite Equity',
  'hybrid': 'Hybrid',
  'liquid': 'Liquid',
  'alternatives': 'Alternatives',
};

/// Ordered list of all tracked asset class keys.
const _assetClassKeys = <String>[
  'coreEquity',
  'debt',
  'gold',
  'satelliteEquity',
  'hybrid',
  'liquid',
  'alternatives',
];

/// Computes allocation health by comparing current portfolio allocation against
/// an ideal target allocation.
///
/// Usage:
/// ```dart
/// final result = AllocationHealthCalculator.compute(
///   currentAllocation: {'coreEquity': 42.0, 'debt': 28.0, ...},
///   portfolioValue: 500000,
///   ideal: idealAllocation,
/// );
/// ```
class AllocationHealthCalculator {
  AllocationHealthCalculator._();

  // Drift severity thresholds (absolute %)
  static const double _warnThreshold = 5.0;
  static const double _criticalThreshold = 15.0;

  // Emergency fund threshold
  static const double _liquidMinPct = 3.0;
  static const double _emergencyFundMinPortfolio = 100000.0; // ₹1L

  // Max theoretical total drift (100% in wrong bucket = 200 total abs drift)
  static const double _maxTotalDrift = 200.0;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Compute [AllocationHealthResult] for the given inputs.
  ///
  /// [currentAllocation] – map of assetClassKey → current allocation %.
  /// [portfolioValue]    – total portfolio value in INR.
  /// [ideal]             – pre-computed [IdealAllocation].
  static AllocationHealthResult compute({
    required Map<String, double> currentAllocation,
    required double portfolioValue,
    required IdealAllocation ideal,
  }) {
    // Edge case: empty / zero portfolio
    if (portfolioValue <= 0 || currentAllocation.isEmpty) {
      return AllocationHealthResult(
        healthScore: 0,
        healthLabel: 'No Portfolio',
        idealAllocation: ideal,
        currentAllocation: const {},
        driftAlerts: const [],
        nudges: const ['Start investing to see your allocation health.'],
      );
    }

    // Build drift alerts
    final alerts = _buildAlerts(currentAllocation, ideal);

    // Health score
    final totalAbsDrift = alerts.fold(
      0.0,
      (sum, a) => sum + a.driftPct.abs(),
    );
    final rawScore = 100.0 * (1.0 - totalAbsDrift / _maxTotalDrift);
    final healthScore = rawScore.clamp(0.0, 100.0).round();

    // Health label
    final healthLabel = _healthLabel(healthScore);

    // Smart nudges
    final nudges = _buildNudges(
      alerts: alerts,
      currentAllocation: currentAllocation,
      portfolioValue: portfolioValue,
    );

    return AllocationHealthResult(
      healthScore: healthScore,
      healthLabel: healthLabel,
      idealAllocation: ideal,
      currentAllocation: currentAllocation,
      driftAlerts: alerts,
      nudges: nudges,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static List<DriftAlert> _buildAlerts(
    Map<String, double> current,
    IdealAllocation ideal,
  ) {
    return _assetClassKeys.map((key) {
      final currentPct = current[key] ?? 0.0;
      final idealPct = ideal.idealForAssetClass(key);
      final driftPct = currentPct - idealPct;
      final absDrift = driftPct.abs();

      final String severity;
      if (absDrift >= _criticalThreshold) {
        severity = 'critical';
      } else if (absDrift >= _warnThreshold) {
        severity = 'warning';
      } else {
        severity = 'ok';
      }

      final displayName = _displayNames[key] ?? key;
      final direction = driftPct >= 0 ? 'Overexposed' : 'Underweight';
      final driftStr = absDrift.toStringAsFixed(1);
      final message = '$direction in $displayName by $driftStr%';

      return DriftAlert(
        assetClass: displayName,
        assetClassKey: key,
        currentPct: currentPct,
        idealPct: idealPct,
        driftPct: driftPct,
        severity: severity,
        message: message,
      );
    }).toList();
  }

  static String _healthLabel(int score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Needs Attention';
    return 'Critical';
  }

  static List<String> _buildNudges({
    required List<DriftAlert> alerts,
    required Map<String, double> currentAllocation,
    required double portfolioValue,
  }) {
    final nudges = <String>[];

    // 1. If any critical: highlight worst + rebalancing recommended
    final criticals = alerts
        .where((a) => a.severity == 'critical')
        .toList()
      ..sort((a, b) => b.driftPct.abs().compareTo(a.driftPct.abs()));

    if (criticals.isNotEmpty) {
      nudges.add('${criticals.first.message} — rebalancing recommended');
    }

    // 2. If 2+ warnings: portfolio review
    final warnings = alerts.where((a) => a.severity == 'warning').toList();
    if (warnings.length >= 2) {
      nudges.add(
        'Multiple asset classes drifted — consider a portfolio review',
      );
    }

    // 3. Low liquid + large portfolio
    final liquidPct = currentAllocation['liquid'] ?? 0.0;
    if (liquidPct < _liquidMinPct &&
        portfolioValue > _emergencyFundMinPortfolio) {
      nudges.add('Your emergency fund allocation is low');
    }

    return nudges;
  }
}
