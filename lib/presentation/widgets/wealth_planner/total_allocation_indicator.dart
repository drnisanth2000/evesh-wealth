import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

/// Sticky footer pill showing the running allocation total.
///
/// Green when within 0.5% of 100; red otherwise with a signed delta and an
/// optional "Distribute remainder" quick-action button.
class TotalAllocationIndicator extends StatelessWidget {
  const TotalAllocationIndicator({
    super.key,
    required this.total,
    this.onDistribute,
  });

  final double total;
  final VoidCallback? onDistribute;

  @override
  Widget build(BuildContext context) {
    final delta = total - 100.0;
    final isBalanced = delta.abs() < 0.5;
    final color = isBalanced ? context.palette.gain : context.palette.loss;
    final label = isBalanced
        ? 'Balanced 100%'
        : 'Total ${total.toStringAsFixed(1)}% '
            '(${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        border: Border(
          top: BorderSide(color: context.palette.bgDivider),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBalanced ? Icons.check_circle : Icons.error_outline,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (!isBalanced && onDistribute != null)
            TextButton.icon(
              onPressed: onDistribute,
              icon: const Icon(Icons.auto_fix_high, size: 14),
              label: const Text('Distribute remainder'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
