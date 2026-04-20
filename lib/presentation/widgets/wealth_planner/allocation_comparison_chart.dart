import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/allocation_models.dart';

/// Horizontal grouped bar chart: current vs ideal allocation per asset class.
class AllocationComparisonChart extends StatelessWidget {
  const AllocationComparisonChart({
    super.key,
    required this.healthResult,
  });

  final AllocationHealthResult healthResult;

  static const List<_AssetClassEntry> _assetClasses = [
    _AssetClassEntry(key: 'coreEquity', label: 'Core Eq.'),
    _AssetClassEntry(key: 'debt', label: 'Debt'),
    _AssetClassEntry(key: 'gold', label: 'Gold'),
    _AssetClassEntry(key: 'satelliteEquity', label: 'Sat. Eq.'),
    _AssetClassEntry(key: 'hybrid', label: 'Hybrid'),
    _AssetClassEntry(key: 'liquid', label: 'Liquid'),
    _AssetClassEntry(key: 'alternate', label: 'Alt.'),
  ];

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
              'Current vs Ideal Allocation',
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _buildLegend(context),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: BarChart(_buildChartData(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      children: [
        _LegendDot(color: AppColors.primary, label: 'Current'),
        SizedBox(width: 20),
        _LegendDot(
            color: context.palette.bgSurface,
            label: 'Ideal',
            borderColor: context.palette.textTertiary),
      ],
    );
  }

  BarChartData _buildChartData(BuildContext context) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 60,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final entry = _assetClasses[groupIndex];
            final label = rodIndex == 0 ? 'Current' : 'Ideal';
            return BarTooltipItem(
              '${entry.label}\n$label: ${rod.toY.toStringAsFixed(1)}%',
              const TextStyle(color: Colors.white, fontSize: 11),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: 20,
            getTitlesWidget: (value, meta) => Text(
              '${value.toInt()}%',
              style: TextStyle(
                color: context.palette.textTertiary,
                fontSize: 10,
              ),
            ),
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= _assetClasses.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _assetClasses[i].label,
                  style: TextStyle(
                    color: context.palette.textTertiary,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (_) => FlLine(
          color: context.palette.bgDivider,
          strokeWidth: 1,
        ),
      ),
      barGroups: _buildBarGroups(context),
    );
  }

  List<BarChartGroupData> _buildBarGroups(BuildContext context) {
    return _assetClasses.asMap().entries.map((entry) {
      final i = entry.key;
      final ac = entry.value;
      final currentPct =
          healthResult.currentAllocation[ac.key]?.toDouble() ?? 0.0;
      final idealPct =
          healthResult.idealAllocation.idealForAssetClass(ac.key);

      return BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: currentPct,
            color: AppColors.primary,
            width: 10,
            borderRadius: BorderRadius.circular(3),
          ),
          BarChartRodData(
            toY: idealPct,
            color: context.palette.textTertiary.withValues(alpha: 0.45),
            width: 10,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    }).toList();
  }
}

class _AssetClassEntry {
  const _AssetClassEntry({required this.key, required this.label});
  final String key;
  final String label;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.borderColor,
  });

  final Color color;
  final String label;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1.5)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: context.palette.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
