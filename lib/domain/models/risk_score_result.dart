import '../../core/constants/risk_tiers.dart';

class RiskScoreResult {
  const RiskScoreResult({
    required this.phase1Score,
    required this.phase2Adjustment,
    required this.totalScore,
    required this.tier,
  });
  final int phase1Score;
  final int phase2Adjustment;
  final int totalScore;
  final RiskTier tier;

  @override
  String toString() =>
      'RiskScoreResult(phase1: $phase1Score, phase2: $phase2Adjustment, '
      'total: $totalScore, tier: ${tier.dbValue})';
}
