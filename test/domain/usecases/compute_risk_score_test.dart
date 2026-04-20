import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/core/constants/risk_tiers.dart';
import 'package:evesh_wealth/domain/usecases/compute_risk_score.dart';

void main() {
  // A neutral demographic selection: all zero-adjustment or balanced choices.
  const neutralDemo = {
    'gender': 'other',                 // 0
    'ageGroup': 'under60',             // +20
    'income': 'income_under_1cr',      // -10
    'workType': 'salaried',            // 0
    'education': 'graduatePlus',       // +10
    'investingExperience': 'exp_under_3', // -10
    'investmentDuration': 'dur_under_3',  // -15
  }; // net = -5

  const maxDemo = {
    'gender': 'male',
    'ageGroup': 'under60',              // +20
    'income': 'income_1cr_plus',        // +15
    'workType': 'selfEmployed',         // +15
    'education': 'graduatePlus',        // +10
    'investingExperience': 'exp_3_plus',// +15
    'investmentDuration': 'dur_3_plus', // +25
  }; // +100

  const minDemo = {
    'gender': 'female',
    'ageGroup': '60plus',               // -20
    'income': 'income_under_10l',       // -10
    'workType': 'salaried',             // 0
    'education': 'nonGraduate',         // -5
    'investingExperience': 'exp_under_3', // -10
    'investmentDuration': 'dur_under_3',  // -15
  }; // -60

  group('computeRiskScore — Phase 1', () {
    test('all lowest answers → phase1 = 120', () {
      final r = computeRiskScore(
        answerIndices: List.filled(6, 0),
        demographics: maxDemo,
      );
      expect(r.phase1Score, 120);
      expect(r.totalScore, 220);
      expect(r.tier, RiskTier.lowToModerate);
    });

    test('all highest answers → phase1 = 480', () {
      final r = computeRiskScore(
        answerIndices: List.filled(6, 3),
        demographics: minDemo,
      );
      expect(r.phase1Score, 480);
      expect(r.totalScore, 420);
      expect(r.tier, RiskTier.high);
    });

    test('throws if answers length != 6', () {
      expect(
        () => computeRiskScore(answerIndices: [0, 1, 2], demographics: neutralDemo),
        throwsArgumentError,
      );
    });

    test('throws if any answer index is out of range', () {
      expect(
        () => computeRiskScore(answerIndices: [0, 1, 2, 3, 4, 0], demographics: neutralDemo),
        throwsArgumentError,
      );
    });
  });

  group('computeRiskScore — Phase 2 + bands', () {
    test('minimum possible score (60) → Low', () {
      final r = computeRiskScore(
        answerIndices: List.filled(6, 0),
        demographics: minDemo,
      );
      expect(r.phase1Score, 120);
      expect(r.phase2Adjustment, -60);
      expect(r.totalScore, 60);
      expect(r.tier, RiskTier.low);
    });

    test('maximum possible score (580) → Very High', () {
      final r = computeRiskScore(
        answerIndices: List.filled(6, 3),
        demographics: maxDemo,
      );
      expect(r.totalScore, 580);
      expect(r.tier, RiskTier.veryHigh);
    });

    test('moderate band check', () {
      final r = computeRiskScore(
        answerIndices: [1, 1, 1, 1, 2, 2],
        demographics: neutralDemo,
      );
      expect(r.phase1Score, 280);
      expect(r.phase2Adjustment, -5);
      expect(r.totalScore, 275);
      expect(r.tier, RiskTier.moderate);
    });

    test('moderately high band check', () {
      final r = computeRiskScore(
        answerIndices: [1, 1, 2, 2, 2, 3],
        demographics: neutralDemo,
      );
      expect(r.phase1Score, 340);
      expect(r.totalScore, 335);
      expect(r.tier, RiskTier.moderatelyHigh);
    });

    test('demographics missing a key → throws', () {
      const incomplete = {'gender': 'male', 'ageGroup': 'under60'};
      expect(
        () => computeRiskScore(
          answerIndices: List.filled(6, 0),
          demographics: incomplete,
        ),
        throwsArgumentError,
      );
    });

    test('unknown demographic value → throws', () {
      final bad = Map<String, String>.from(neutralDemo)..['ageGroup'] = 'mars';
      expect(
        () => computeRiskScore(
          answerIndices: List.filled(6, 0),
          demographics: bad,
        ),
        throwsArgumentError,
      );
    });
  });
}
