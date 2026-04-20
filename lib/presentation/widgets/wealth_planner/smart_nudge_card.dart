import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class SmartNudgeCard extends StatelessWidget {
  const SmartNudgeCard({
    super.key,
    required this.nudges,
    this.onPlanNow,
    this.onFixPortfolio,
    this.onRetirementCheck,
  });

  final List<String> nudges;
  final VoidCallback? onPlanNow;
  final VoidCallback? onFixPortfolio;
  final VoidCallback? onRetirementCheck;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.bgDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Nudges',
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            if (nudges.isEmpty)
              Text(
                'No nudges at this time. Your portfolio looks good!',
                style: TextStyle(
                  color: context.palette.textTertiary,
                  fontSize: 13,
                ),
              )
            else
              ...nudges.map((n) => _buildNudgeRow(context, n)),
            const SizedBox(height: 20),
            _buildCTAButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildNudgeRow(BuildContext context, String nudge) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.lightbulb_outline,
              color: AppColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nudge,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton(
          onPressed: onPlanNow,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Plan Now'),
        ),
        OutlinedButton(
          onPressed: onFixPortfolio,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            side: const BorderSide(color: AppColors.primaryLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Fix Portfolio'),
        ),
        OutlinedButton(
          onPressed: onRetirementCheck,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            side: const BorderSide(color: AppColors.primaryLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Retirement Check'),
        ),
      ],
    );
  }
}
