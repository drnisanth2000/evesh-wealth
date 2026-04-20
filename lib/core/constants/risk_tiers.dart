// lib/core/constants/risk_tiers.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Canonical 6-tier risk enum used throughout the app.
/// `dbValue` strings are persisted in `families.risk_profile` and
/// `family_members.risk_profile`.
enum RiskTier {
  low(
    dbValue: 'Low',
    defaultEquity: 15,
    defaultDebt: 85,
    minFinalScore: 60,
    educationEn:
        'You play it safe. Capital protection comes first. A market dip shouldn\'t cost you sleep.',
    educationHi: 'आप सुरक्षा को पहले रखते हैं। मूलधन की रक्षा सबसे महत्वपूर्ण है।',
  ),
  lowToModerate(
    dbValue: 'Low To Moderate',
    defaultEquity: 30,
    defaultDebt: 70,
    minFinalScore: 181,
    educationEn:
        'You want steady growth with a safety net. Small dips are fine — crashes are not.',
    educationHi: 'आप सुरक्षा के साथ स्थिर विकास चाहते हैं।',
  ),
  moderate(
    dbValue: 'Moderate',
    defaultEquity: 55,
    defaultDebt: 45,
    minFinalScore: 241,
    educationEn:
        'Balanced. You accept short-term volatility for long-term growth. The classic middle path.',
    educationHi: 'संतुलित दृष्टिकोण। दीर्घकालिक विकास के लिए अल्पकालिक उतार-चढ़ाव स्वीकार्य।',
  ),
  moderatelyHigh(
    dbValue: 'Moderately High',
    defaultEquity: 70,
    defaultDebt: 30,
    minFinalScore: 311,
    educationEn:
        'Growth-first. You can stomach bigger dips because time is on your side.',
    educationHi: 'विकास पहले। समय के साथ आप बड़े उतार-चढ़ाव सह सकते हैं।',
  ),
  high(
    dbValue: 'High',
    defaultEquity: 85,
    defaultDebt: 15,
    minFinalScore: 371,
    educationEn:
        'Aggressive growth. Volatility is just noise on the road to long-term wealth.',
    educationHi: 'आक्रामक विकास। अस्थिरता केवल शोर है।',
  ),
  veryHigh(
    dbValue: 'Very High',
    defaultEquity: 95,
    defaultDebt: 5,
    minFinalScore: 441,
    educationEn:
        'Maximum growth. You understand risk deeply and are prepared to hold through any storm.',
    educationHi: 'अधिकतम विकास। आप जोखिम को गहराई से समझते हैं।',
  );

  const RiskTier({
    required this.dbValue,
    required this.defaultEquity,
    required this.defaultDebt,
    required this.minFinalScore,
    required this.educationEn,
    required this.educationHi,
  });

  final String dbValue;
  final int defaultEquity;
  final int defaultDebt;
  final int minFinalScore;
  final String educationEn;
  final String educationHi;

  /// 0.0 .. 1.0 position on the risk meter (for needle animation).
  double get meterPosition => index / (RiskTier.values.length - 1);

  Color get color {
    switch (this) {
      case RiskTier.low:
        return Colors.blue;
      case RiskTier.lowToModerate:
        return Colors.teal;
      case RiskTier.moderate:
        return AppColors.primary;
      case RiskTier.moderatelyHigh:
        return Colors.orange;
      case RiskTier.high:
        return AppColors.loss;
      case RiskTier.veryHigh:
        return Colors.purple;
    }
  }

  static RiskTier fromDb(String? value) {
    if (value == null) return RiskTier.moderate;
    return RiskTier.values.firstWhere(
      (t) => t.dbValue == value,
      orElse: () => RiskTier.moderate,
    );
  }

  /// Walks the tier list and returns the highest tier whose [minFinalScore]
  /// the [finalScore] meets or exceeds.
  static RiskTier fromScore(int finalScore) {
    var result = RiskTier.low;
    for (final t in RiskTier.values) {
      if (finalScore >= t.minFinalScore) result = t;
    }
    return result;
  }
}
