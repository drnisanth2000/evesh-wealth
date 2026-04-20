import 'package:flutter/material.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/action_models.dart';

/// Horizontal stacked bars showing 3-bucket current vs ideal allocation.
class BucketBars extends StatelessWidget {
  const BucketBars({super.key, required this.buckets});

  final List<BucketStatus> buckets;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.bgDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3-Bucket Allocation',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ...buckets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _BucketBar(bucket: b),
                )),
          ],
        ),
      ),
    );
  }
}

class _BucketBar extends StatelessWidget {
  const _BucketBar({required this.bucket});

  final BucketStatus bucket;

  Color get _statusColor {
    switch (bucket.status) {
      case 'overweight':
        return AppColors.loss;
      case 'underweight':
        return AppColors.warning;
      default:
        return AppColors.gain;
    }
  }

  IconData get _statusIcon {
    switch (bucket.status) {
      case 'overweight':
        return Icons.arrow_upward;
      case 'underweight':
        return Icons.arrow_downward;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    const maxPct = 100.0;
    final currentFill = (bucket.currentPct / maxPct).clamp(0.0, 1.0);
    final idealMark = (bucket.idealPct / maxPct).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Icon(_statusIcon, color: _statusColor, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                bucket.bucketName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textPrimary,
                ),
              ),
            ),
            Text(
              '${bucket.currentPct.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _statusColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${bucket.currentValue.toINR(compact: true)})',
              style: TextStyle(fontSize: 10, color: context.palette.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Bar
        SizedBox(
          height: 16,
          child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    color: context.palette.bgDivider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Current fill
                Container(
                  width: width * currentFill,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Ideal marker line
                Positioned(
                  left: (width * idealMark) - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: context.palette.textPrimary,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                // Ideal label
                Positioned(
                  left: width * idealMark + 4,
                  top: 1,
                  child: Text(
                    '${bucket.idealPct.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 8, color: context.palette.textTertiary),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
