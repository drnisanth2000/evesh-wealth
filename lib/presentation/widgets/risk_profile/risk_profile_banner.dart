import 'package:flutter/material.dart';

import '../../../core/constants/risk_tiers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class RiskProfileBanner extends StatelessWidget {
  const RiskProfileBanner({
    super.key,
    required this.tier,
    required this.source, // 'manual' or 'questionnaire'
    required this.finalScore,
  });

  final RiskTier tier;
  final String source;
  final int? finalScore;

  @override
  Widget build(BuildContext context) {
    final header = source == 'questionnaire'
        ? 'Your quiz score (${finalScore ?? '-'}) says you are a'
        : 'You have chosen';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tier.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tier.color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(header,
              style: TextStyle(fontSize: 11, color: context.palette.textSecondary)),
          const SizedBox(height: 6),
          Text(tier.dbValue,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: tier.color)),
          const SizedBox(height: 8),
          Text(tier.educationEn,
              style: TextStyle(
                  fontSize: 12, color: context.palette.textPrimary, height: 1.4)),
        ],
      ),
    );
  }
}
