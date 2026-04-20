import 'package:flutter/material.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/retirement_models.dart';

class RetirementReadinessCard extends StatelessWidget {
  const RetirementReadinessCard({
    super.key,
    required this.readiness,
    required this.onRetirementCheck,
  });

  final RetirementReadiness readiness;
  final VoidCallback onRetirementCheck;

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'On Track':
        return AppColors.gain;
      case 'Needs Attention':
        return AppColors.warning;
      case 'Behind':
        return AppColors.loss;
      case 'Critical':
        return AppColors.alertUrgent;
      default:
        return context.palette.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = readiness.requiredCorpus == 0;
    final statusColor = _statusColor(context, readiness.statusLabel);
    final fundedClamped = readiness.fundedPct.clamp(0.0, 100.0) / 100.0;

    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.bgDivider),
      ),
      child: InkWell(
        onTap: onRetirementCheck,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ────────────────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.beach_access,
                      color: context.palette.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Retirement',
                      style: TextStyle(
                        color: context.palette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        readiness.statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(Icons.chevron_right,
                      color: context.palette.textSecondary, size: 20),
                ],
              ),

              const SizedBox(height: 16),

              if (isEmpty) ...[
                // ── Empty state ───────────────────────────────────────────
                Text(
                  'Set up your monthly expenses and income to see your retirement readiness.',
                  style: TextStyle(
                    color: context.palette.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ] else ...[
                // ── Progress bar ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fundedClamped,
                          backgroundColor: context.palette.bgSurface,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(statusColor),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${readiness.fundedPct.clamp(0, 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Key metrics row ───────────────────────────────────────
                Row(
                  children: [
                    _MetricItem(
                      label: 'Gap',
                      value: readiness.gap > 0
                          ? readiness.gap.toINR(compact: true)
                          : '—',
                      valueColor: readiness.gap > 0
                          ? AppColors.loss
                          : AppColors.gain,
                    ),
                    _MetricItem(
                      label: 'SIP Needed',
                      value: readiness.requiredMonthlySip > 0
                          ? readiness.requiredMonthlySip.toINR(compact: true)
                          : '—',
                      valueColor: context.palette.textPrimary,
                    ),
                    _MetricItem(
                      label: 'Retire at',
                      value: 'Age ${readiness.retirementAge}',
                      valueColor: context.palette.textPrimary,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
