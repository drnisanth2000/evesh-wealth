import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/simulation_models.dart';

// ─── SimulationSummaryCard ────────────────────────────────────────────────────

class SimulationSummaryCard extends StatelessWidget {
  const SimulationSummaryCard({super.key, required this.result});

  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###', 'en_IN');

    final ltcgTax = result.taxImpacts.fold<double>(
      0,
      (sum, t) => sum + t.ltcgTax,
    );
    final stcgTax = result.taxImpacts.fold<double>(
      0,
      (sum, t) => sum + t.stcgTax,
    );
    final exitLoad = result.totalExitLoad;
    final netCost = result.netRebalanceCost;

    final delta = result.healthDelta;
    final deltaPositive = delta > 0;
    final deltaSign = deltaPositive ? '+' : '';
    final healthColor = delta > 0
        ? AppColors.gain
        : delta < 0
            ? AppColors.loss
            : context.palette.textSecondary;

    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulation Summary',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // KPI row with dividers
            IntrinsicHeight(
              child: Row(
                children: [
                  _KpiCell(
                    label: 'LTCG Tax',
                    value: '₹${fmt.format(ltcgTax.round())}',
                  ),
                  VerticalDivider(
                    color: context.palette.bgDivider,
                    thickness: 1,
                    width: 1,
                  ),
                  _KpiCell(
                    label: 'STCG Tax',
                    value: '₹${fmt.format(stcgTax.round())}',
                  ),
                  VerticalDivider(
                    color: context.palette.bgDivider,
                    thickness: 1,
                    width: 1,
                  ),
                  _KpiCell(
                    label: 'Exit Load',
                    value: '₹${fmt.format(exitLoad.round())}',
                  ),
                  VerticalDivider(
                    color: context.palette.bgDivider,
                    thickness: 1,
                    width: 1,
                  ),
                  _KpiCell(
                    label: 'Net Cost',
                    value: '₹${fmt.format(netCost.round())}',
                    valueColor: netCost > 0 ? AppColors.warning : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: context.palette.bgDivider, height: 1),
            const SizedBox(height: 10),
            // Health delta bar
            Row(
              children: [
                Text(
                  'Health: ${result.projectedHealthScore} ($deltaSign$delta)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: healthColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (result.projectedHealthScore / 100).clamp(0.0, 1.0),
                      backgroundColor: context.palette.bgSurface,
                      valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCell extends StatelessWidget {
  const _KpiCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: context.palette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: valueColor ?? context.palette.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SimulationBottomBar ──────────────────────────────────────────────────────

class SimulationBottomBar extends StatelessWidget {
  const SimulationBottomBar({
    super.key,
    required this.isDirty,
    required this.isLoading,
    required this.onReset,
    required this.onFreeze,
    this.frozenPlanDate,
  });

  final bool isDirty;
  final bool isLoading;
  final VoidCallback onReset;
  final VoidCallback onFreeze;
  final DateTime? frozenPlanDate;

  String _formatFrozenDate(DateTime dt) {
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        border: Border(
          top: BorderSide(color: context.palette.bgDivider, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Frozen plan badge
          if (frozenPlanDate != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 13,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Frozen plan active · Created ${_formatFrozenDate(frozenPlanDate!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Button row
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: isDirty ? onReset : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDirty
                          ? context.palette.textSecondary
                          : context.palette.bgDivider,
                    ),
                    foregroundColor: context.palette.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: (isDirty && !isLoading) ? onFreeze : null,
                  icon: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnPrimary,
                          ),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: const Text(
                    'Freeze Plan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
