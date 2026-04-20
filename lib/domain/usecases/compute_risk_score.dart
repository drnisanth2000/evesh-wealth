import '../../core/constants/risk_questionnaire.dart';
import '../../core/constants/risk_tiers.dart';
import '../models/risk_score_result.dart';

export '../models/risk_score_result.dart';

/// Computes a [RiskScoreResult] from the user\'s Phase 1 answers and
/// Phase 2 demographic selections.
RiskScoreResult computeRiskScore({
  required List<int> answerIndices,
  required Map<String, String> demographics,
}) {
  if (answerIndices.length != riskQuestions.length) {
    throw ArgumentError(
      'Expected ${riskQuestions.length} answers, got ${answerIndices.length}',
    );
  }

  var phase1 = 0;
  for (var i = 0; i < riskQuestions.length; i++) {
    final q = riskQuestions[i];
    final idx = answerIndices[i];
    if (idx < 0 || idx >= q.options.length) {
      throw ArgumentError(
        'Answer $idx for question "${q.id}" is out of range '
        '(0..${q.options.length - 1})',
      );
    }
    phase1 += q.options[idx].score;
  }

  var phase2 = 0;
  for (final field in demographicFields) {
    final key = field.id.name;
    final value = demographics[key];
    if (value == null) {
      throw ArgumentError('Missing demographic field: $key');
    }
    final opt = field.options.firstWhere(
      (o) => o.value == value,
      orElse: () =>
          throw ArgumentError('Unknown value "$value" for demographic $key'),
    );
    phase2 += opt.adjustment;
  }

  final total = phase1 + phase2;
  final tier = RiskTier.fromScore(total);

  return RiskScoreResult(
    phase1Score: phase1,
    phase2Adjustment: phase2,
    totalScore: total,
    tier: tier,
  );
}
