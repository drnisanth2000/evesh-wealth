import 'dart:math' as math;

import '../models/allocation_models.dart';

/// Computes the ideal Core-Satellite allocation for a given risk profile and age.
///
/// Applies a glide path that reduces equity exposure after age 45, capped at
/// age 65, with a minimum equity floor of 25%.
///
/// Usage:
/// ```dart
/// final allocation = IdealAllocationCalculator.compute(
///   riskProfile: 'Moderate',
///   age: 40,
/// );
/// ```
class IdealAllocationCalculator {
  IdealAllocationCalculator._();

  // ---------------------------------------------------------------------------
  // Risk profile base parameters
  // ---------------------------------------------------------------------------

  static const _profiles = {
    'Conservative':            _ProfileParams(core: 80, satellite: 20, equity: 40, debt: 45),
    'Moderately Conservative': _ProfileParams(core: 75, satellite: 25, equity: 50, debt: 35),
    'Moderate':                _ProfileParams(core: 70, satellite: 30, equity: 60, debt: 27),
    'Moderately Aggressive':   _ProfileParams(core: 65, satellite: 35, equity: 70, debt: 20),
    'Aggressive':              _ProfileParams(core: 55, satellite: 45, equity: 80, debt: 12),
  };

  // Fixed allocations
  static const double _goldFixed      = 7.0;
  static const double _liquidFixed    = 6.0;
  static const double _minEquityFloor = 25.0;
  static const double _glideReductionPerYear = 2.5;
  static const int    _glideStartAge  = 45;
  static const int    _glideMaxYears  = 20; // cap at age 65

  // Sub-bucket split ratios within their parent category
  static const double _coreEqNifty50   = 0.42;
  static const double _coreEqNext50    = 0.28;
  static const double _coreEqFlexi     = 0.30;

  static const double _debtShortDur    = 0.42;
  static const double _debtEPF         = 0.28;
  static const double _debtTargetMat   = 0.30;

  static const double _satEqMidcap     = 0.35;
  static const double _satEqSmallcap   = 0.30;
  static const double _satEqSector     = 0.35;

  static const double _hybridOfRemaining = 0.60;
  // Alternatives = 40% of remaining (1 - 0.60 = 0.40)

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Compute the ideal allocation for [riskProfile] at [age].
  /// Unknown profiles default to Moderate.
  static IdealAllocation compute({
    required String riskProfile,
    required int age,
  }) {
    final params = _profiles[riskProfile] ?? _profiles['Moderate']!;

    // --- Glide path: reduce equity after age 45, cap at 20 years ---
    final yearsOverBase = math.min(
      math.max(age - _glideStartAge, 0),
      _glideMaxYears,
    );
    final equityReduction = yearsOverBase * _glideReductionPerYear;
    final adjustedEquity = math.max(
      params.equity - equityReduction,
      _minEquityFloor,
    );
    // Debt absorbs the equity reduction
    final adjustedDebt = params.debt + (params.equity - adjustedEquity);

    // --- Split equity between core and satellite proportionally ---
    // Base split: corePct / (corePct + satellitePct) of total equity goes to core
    final totalBucketPct = params.core + params.satellite; // always 100
    final coreEquityPct = adjustedEquity * (params.core / totalBucketPct);
    final satelliteEquityPct = adjustedEquity * (params.satellite / totalBucketPct);

    // --- Fixed allocations ---
    // gold = 7%, liquid = 6% (both fixed regardless of profile)
    const goldPct   = _goldFixed;
    const liquidPct = _liquidFixed;

    // --- Remaining for hybrid/alternatives ---
    final usedSoFar = coreEquityPct + satelliteEquityPct + adjustedDebt + goldPct + liquidPct;
    final remaining = math.max(100.0 - usedSoFar, 0.0);
    final hybridPct       = remaining * _hybridOfRemaining;
    final alternativesPct = remaining * (1 - _hybridOfRemaining);

    // --- Build the 13 sub-buckets (raw, pre-normalisation) ---
    final rawBuckets = <_RawBucket>[
      // Core equity (3)
      _RawBucket('Nifty 50 / Sensex Index',         'coreEquity',      coreEquityPct * _coreEqNifty50),
      _RawBucket('Nifty Next 50 / Large & Midcap',  'coreEquity',      coreEquityPct * _coreEqNext50),
      _RawBucket('Flexi-cap / Multicap',            'coreEquity',      coreEquityPct * _coreEqFlexi),
      // Debt core (3)
      _RawBucket('Short Duration / Corporate Bond', 'debt',            adjustedDebt * _debtShortDur),
      _RawBucket('EPF / PPF / VPF',                 'debt',            adjustedDebt * _debtEPF),
      _RawBucket('Target Maturity Funds',           'debt',            adjustedDebt * _debtTargetMat),
      // Gold (1)
      const _RawBucket('Gold',                            'gold',            _goldFixed),
      // Satellite equity (3)
      _RawBucket('Midcap Funds',                    'satelliteEquity', satelliteEquityPct * _satEqMidcap),
      _RawBucket('Smallcap Funds',                  'satelliteEquity', satelliteEquityPct * _satEqSmallcap),
      _RawBucket('Sector / Thematic',               'satelliteEquity', satelliteEquityPct * _satEqSector),
      // Hybrid / Tactical (1)
      _RawBucket('Hybrid / Tactical',               'hybrid',          hybridPct),
      // Liquid / Emergency (1)
      const _RawBucket('Liquid / Emergency',              'liquid',          _liquidFixed),
      // Alternatives (1)
      _RawBucket('Alternatives',                    'alternatives',    alternativesPct),
    ];

    assert(rawBuckets.length == 13, 'Expected 13 sub-buckets, got ${rawBuckets.length}');

    // --- Normalise so sub-buckets sum to exactly 100% ---
    final rawTotal = rawBuckets.fold(0.0, (s, b) => s + b.pct);
    final scale = rawTotal > 0 ? 100.0 / rawTotal : 1.0;

    final subBuckets = rawBuckets.map((b) {
      final ideal = b.pct * scale;
      return SubBucketTarget(
        name: b.name,
        parentBucket: b.parentBucket,
        minPct: ideal * 0.8,
        maxPct: ideal * 1.2,
        idealPct: ideal,
      );
    }).toList();

    return IdealAllocation(
      riskProfile: riskProfile,
      age: age,
      corePct: params.core.toDouble(),
      satellitePct: params.satellite.toDouble(),
      subBuckets: subBuckets,
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _ProfileParams {
  const _ProfileParams({
    required this.core,
    required this.satellite,
    required this.equity,
    required this.debt,
  });

  final int core;
  final int satellite;
  final int equity;
  final int debt;
}

class _RawBucket {
  const _RawBucket(this.name, this.parentBucket, this.pct);

  final String name;
  final String parentBucket;
  final double pct;
}
