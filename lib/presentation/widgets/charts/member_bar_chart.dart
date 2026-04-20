import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/portfolio_summary_model.dart';

class MemberBarChart extends StatelessWidget {
  const MemberBarChart({super.key, required this.members});
  final List<MemberSummary> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    final maxVal = members
        .map((m) => m.currentValue > m.invested ? m.currentValue : m.invested)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.bgDivider),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.15,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final m = members[groupIndex];
                final label = rodIndex == 0 ? 'Invested' : 'Current';
                final val = rodIndex == 0 ? m.invested : m.currentValue;
                return BarTooltipItem(
                  '$label\n${val.toINRCompact()}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= members.length) return const SizedBox();
                  final name = members[i].memberName;
                  final short = name.length > 8 ? name.substring(0, 8) : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(short,
                        style: TextStyle(
                            fontSize: 10, color: context.palette.textTertiary)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            horizontalInterval: maxVal / 4,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: context.palette.bgDivider,
              strokeWidth: 1,
            ),
          ),
          barGroups: members.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            final isGain = m.currentValue >= m.invested;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: m.invested,
                  color: context.palette.textTertiary.withOpacity(0.4),
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: m.currentValue,
                  color: isGain ? AppColors.gain : AppColors.loss,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              barsSpace: 4,
            );
          }).toList(),
        ),
      ),
    );
  }
}
