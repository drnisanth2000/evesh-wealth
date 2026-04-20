import 'package:flutter/material.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/fund_model.dart';
import '../../../data/models/fund_performance_row.dart';

/// Compact card showing a single fund from screener results.
class FundScreenerCard extends StatelessWidget {
  const FundScreenerCard({
    super.key,
    required this.fund,
    required this.isHeld,
    this.perf,
    this.onTap,
  });

  final FundModel fund;
  final FundPerformanceRow? perf;
  final bool isHeld;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.palette.bgDivider),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Fund name + Held chip
              _buildNameRow(context),
              const SizedBox(height: 6),
              // Row 2: Plan type badge + category + AMC
              _buildMetaRow(context),
              const SizedBox(height: 8),
              // Row 3: Metrics grid (1Y, 3Y, ER, Rating)
              _buildMetricsRow(context),
              const SizedBox(height: 4),
              // Row 3b: Short-window + info ratio
              _buildShortMetricsRow(context),
              const SizedBox(height: 6),
              // Row 4: AUM + riskometer + benchmark
              _buildAumRow(context),
              if (fund.benchmarkIndex != null &&
                  fund.benchmarkIndex!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Benchmark: ${fund.benchmarkIndex}',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.palette.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (perf?.returnsUpdatedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Updated ${_formatUpdatedAt(perf!.returnsUpdatedAt!)}',
                    style: TextStyle(
                      fontSize: 9,
                      color: context.palette.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            fund.fundName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: context.palette.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isHeld) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Held',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetaRow(BuildContext context) {
    final isDirect = fund.planType?.toLowerCase().contains('direct') ?? false;
    final isRegular = fund.planType?.toLowerCase().contains('regular') ?? true;

    final chipColor = isDirect
        ? AppColors.gain
        : isRegular
            ? AppColors.warning
            : context.palette.textTertiary;

    final chipBg = isDirect
        ? AppColors.gain.withValues(alpha: 0.15)
        : isRegular
            ? AppColors.warning.withValues(alpha: 0.15)
            : context.palette.bgSurface;

    final planLabel = isDirect ? 'Direct' : isRegular ? 'Regular' : (fund.planType ?? '—');

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: chipBg, // chipBg computed above from withValues
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            planLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            [
              fund.category ?? '',
              fund.amc ?? '',
            ].where((s) => s.isNotEmpty).join(' • '),
            style: TextStyle(
              fontSize: 11,
              color: context.palette.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildMetricItem(context, '1Y', fund.return1y, isReturn: true)),
        Expanded(child: _buildMetricItem(context, '3Y', fund.return3y, isReturn: true)),
        Expanded(child: _buildMetricItem(context, 'ER', fund.expenseRatio, isReturn: false)),
        Expanded(child: _buildRatingItem(context)),
      ],
    );
  }

  Widget _buildShortMetricsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildMetricItem(context, '3M', perf?.return3m, isReturn: true)),
        Expanded(child: _buildMetricItem(context, '6M', perf?.return6m, isReturn: true)),
        Expanded(child: _buildInfoRatioItem(context)),
        Expanded(child: _buildRiskometerItem(context)),
      ],
    );
  }

  Widget _buildInfoRatioItem(BuildContext context) {
    final v = perf?.infoRatio5y;
    final text = v != null ? v.toStringAsFixed(2) : '—';
    Color valueColor = context.palette.textSecondary;
    if (v != null) {
      valueColor = v >= 0 ? AppColors.gain : AppColors.loss;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IR5Y',
          style: TextStyle(fontSize: 10, color: context.palette.textTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskometerItem(BuildContext context) {
    final risk = perf?.riskometerScheme;
    Color color = context.palette.textSecondary;
    if (risk != null) {
      final lower = risk.toLowerCase();
      if (lower.contains('very high')) {
        color = AppColors.loss;
      } else if (lower.contains('high')) {
        color = AppColors.warning;
      } else if (lower.contains('moderate')) {
        color = AppColors.info;
      } else if (lower.contains('low')) {
        color = AppColors.gain;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk',
          style: TextStyle(fontSize: 10, color: context.palette.textTertiary),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            risk ?? '—',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static String _formatUpdatedAt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _buildMetricItem(BuildContext context, String label, double? value, {required bool isReturn}) {
    final displayText = value != null ? value.toPercent(decimals: 1) : '—';
    Color valueColor = context.palette.textSecondary;

    if (isReturn && value != null) {
      valueColor = value >= 0 ? AppColors.gain : AppColors.loss;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: context.palette.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          displayText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingItem(BuildContext context) {
    final rating = fund.fundRating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '★',
          style: TextStyle(
            fontSize: 10,
            color: context.palette.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          rating != null ? rating.toString() : '—',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.palette.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAumRow(BuildContext context) {
    final aumText = fund.aumCr != null
        ? 'AUM: ${(fund.aumCr! * 1e7).toINRCompact()}'
        : 'AUM: —';

    return Text(
      aumText,
      style: TextStyle(
        fontSize: 11,
        color: context.palette.textTertiary,
      ),
    );
  }
}
