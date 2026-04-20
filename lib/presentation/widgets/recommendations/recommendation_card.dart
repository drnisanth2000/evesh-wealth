// lib/presentation/widgets/recommendations/recommendation_card.dart

import 'package:flutter/material.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/recommendation_models.dart';
import 'score_gauge.dart';

/// Displays a single fund recommendation with score, allocation, and explanations.
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
  });

  final FundRecommendation recommendation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fs = recommendation.fundScore;

    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.palette.bgDivider),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Score gauge + fund name + amount ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScoreGauge(score: fs.score, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fs.fundName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: context.palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${fs.amc ?? ''} · ${fs.category}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.palette.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        recommendation.suggestedAmount.toINR(compact: true),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _Badge(
                        label: recommendation.isSip ? 'SIP' : 'Lumpsum',
                        color: recommendation.isSip
                            ? AppColors.primary
                            : AppColors.gain,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Row 2: Asset class badge + metrics ──
              Row(
                children: [
                  _Badge(
                    label: recommendation.targetAssetClassLabel,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 6),
                  _Badge(
                    label: 'Gap ${recommendation.allocationGapPct.toStringAsFixed(1)}%',
                    color: AppColors.warning,
                  ),
                  const Spacer(),
                  if (fs.return1y != null)
                    _MetricChip('1Y', fs.return1y!),
                  if (fs.return3y != null) ...[
                    const SizedBox(width: 6),
                    _MetricChip('3Y', fs.return3y!),
                  ],
                  if (fs.expenseRatio != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      'ER ${fs.expenseRatio!.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 10),
              Divider(height: 1, color: context.palette.bgDivider),
              const SizedBox(height: 10),

              // ── Row 3: Reasons ──
              ...recommendation.reasons.map((reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 14, color: AppColors.gain),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),

              // ── Row 4: Warnings (if any) ──
              ...recommendation.warnings.map((warning) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            warning,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip(this.label, this.value);
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final color = value >= 0 ? AppColors.gain : AppColors.loss;
    return Text(
      '$label ${value.toStringAsFixed(1)}%',
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
    );
  }
}
