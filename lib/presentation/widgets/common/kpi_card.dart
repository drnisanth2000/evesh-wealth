import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.tooltip,
    this.subLabel,
    this.subValue,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final String? tooltip;
  final String? subLabel;
  final String? subValue;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.bgDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: context.palette.textTertiary,
                ),
              ),
              if (tooltip != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: tooltip!,
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: context.palette.textTertiary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor ?? context.palette.textPrimary,
            ),
          ),
          if (subLabel != null && subValue != null) ...[
            const SizedBox(height: 4),
            Text(
              '$subLabel: $subValue',
              style: TextStyle(
                fontSize: 11,
                color: context.palette.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );

    return card;
  }
}
