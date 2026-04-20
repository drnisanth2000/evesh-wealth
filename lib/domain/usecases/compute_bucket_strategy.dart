import '../models/simulation_models.dart';
import '../../core/constants/bucket_education.dart';

/// Computes a 3-bucket strategy allocation based on age, risk profile, and
/// retirement age. Uses age-band midpoints with risk-factor adjustments and
/// normalises the result so buckets always sum to 100%.
class BucketStrategyCalculator {
  BucketStrategyCalculator._();

  // Risk factor: Conservative = -1.0, Moderate = 0.0, Aggressive = +1.0
  static double _riskFactor(String riskProfile) {
    switch (riskProfile) {
      case 'Conservative':
        return -1.0;
      case 'Moderately Conservative':
        return -0.5;
      case 'Moderate':
        return 0.0;
      case 'Moderately Aggressive':
        return 0.5;
      case 'Aggressive':
        return 1.0;
      default:
        return 0.0;
    }
  }

  static BucketStrategy compute({
    required int age,
    required String riskProfile,
    required int retirementAge,
  }) {
    final isDistribution = age >= retirementAge;
    final scenario = isDistribution ? 'distribution' : 'accumulation';
    final rf = _riskFactor(riskProfile);

    double b1, b2, b3;
    double corePct, satellitePct;

    if (isDistribution) {
      // Distribution base: B1=25, B2=45, B3=30
      // Risk shifts: B1 ±5, B2 ±5, B3 ±10
      // Conservative (rf=-1): more B1/B2, less B3
      // Aggressive (rf=+1): less B1/B2, more B3
      b1 = 25.0 - rf * 5.0;
      b2 = 45.0 - rf * 5.0;
      b3 = 30.0 + rf * 10.0;
      corePct = 80.0;
      satellitePct = 20.0;
    } else {
      // Accumulation — age-band base targets
      double b1Mid, b2Mid, b3Mid;
      double b1Range, b2Range, b3Range;

      if (age < 35) {
        b1Mid = 6.5; b2Mid = 16.0; b3Mid = 77.5;
        b1Range = 1.5; b2Range = 4.0; b3Range = 5.0;
      } else if (age < 45) {
        b1Mid = 9.0; b2Mid = 25.0; b3Mid = 66.0;
        b1Range = 1.0; b2Range = 5.0; b3Range = 5.0;
      } else if (age < 55) {
        b1Mid = 12.5; b2Mid = 35.0; b3Mid = 52.5;
        b1Range = 2.5; b2Range = 5.0; b3Range = 7.5;
      } else {
        // 55+
        b1Mid = 17.5; b2Mid = 40.0; b3Mid = 42.5;
        b1Range = 2.5; b2Range = 5.0; b3Range = 5.0;
      }

      // Conservative (rf=-1): subtract rf from B1/B2 base (increases them),
      //   lower B3.
      // Aggressive (rf=+1): add rf * range to B3, reduce B1/B2.
      b1 = b1Mid - rf * b1Range;
      b2 = b2Mid - rf * b2Range;
      b3 = b3Mid + rf * b3Range;

      corePct = age < 45 ? 75.0 : 80.0;
      satellitePct = 100.0 - corePct;
    }

    // Normalise so that b1 + b2 + b3 = 100.0
    final sum = b1 + b2 + b3;
    b1 = b1 / sum * 100.0;
    b2 = b2 / sum * 100.0;
    b3 = b3 / sum * 100.0;

    // Round to 1 decimal, keep b3 as remainder to guarantee exact 100
    b1 = _round1(b1);
    b2 = _round1(b2);
    b3 = _round1(100.0 - b1 - b2);

    final bucketTargets = <int, double>{1: b1, 2: b2, 3: b3};

    // Build refill rules
    final rawRules = isDistribution
        ? BucketEducation.distributionRefillRules
        : BucketEducation.accumulationRefillRules;

    final refillRules = rawRules
        .map(
          (r) => RefillRule(
            fromBucket: r['fromBucket'] as int,
            toBucket: r['toBucket'] as int,
            trigger: r['trigger'] as String,
            frequency: r['frequency'] as String,
            description: r['description'] as String,
          ),
        )
        .toList();

    return BucketStrategy(
      scenario: scenario,
      bucketTargets: bucketTargets,
      bucketNames: BucketEducation.bucketNames,
      bucketInstruments: BucketEducation.bucketInstruments,
      corePct: corePct,
      satellitePct: satellitePct,
      educationNotes: BucketEducation.notesForScenario(scenario),
      refillRules: refillRules,
    );
  }

  static double _round1(double v) => (v * 10).round() / 10.0;
}
