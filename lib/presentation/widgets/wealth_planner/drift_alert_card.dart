import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/allocation_models.dart';

class DriftAlertCard extends StatelessWidget {
  const DriftAlertCard({
    super.key,
    required this.driftAlerts,
  });

  final List<DriftAlert> driftAlerts;

  bool get _hasActionableAlerts =>
      driftAlerts.any((a) => a.severity != 'ok');

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
              'Rebalancing Alerts',
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            if (!_hasActionableAlerts)
              _buildAllOnTarget()
            else
              ...driftAlerts
                  .where((a) => a.severity != 'ok')
                  .map((a) => _buildAlertRow(context, a)),
          ],
        ),
      ),
    );
  }

  Widget _buildAllOnTarget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.alertLowBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              color: AppColors.gain, size: 22),
          SizedBox(width: 10),
          Text(
            'All allocations on target',
            style: TextStyle(
              color: AppColors.gain,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertRow(BuildContext context, DriftAlert alert) {
    final isCritical = alert.severity == 'critical';
    final iconColor =
        isCritical ? AppColors.alertUrgent : AppColors.alertMedium;
    final bgColor =
        isCritical ? AppColors.alertUrgentBg : AppColors.alertMediumBg;
    final icon =
        isCritical ? Icons.error_outline : Icons.info_outline;

    final driftPositive = alert.driftPct > 0;
    final driftColor = driftPositive ? context.palette.loss : context.palette.gain;
    final driftSign = driftPositive ? '+' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                alert.message,
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$driftSign${alert.driftPct.toStringAsFixed(1)}%',
              style: TextStyle(
                color: driftColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
