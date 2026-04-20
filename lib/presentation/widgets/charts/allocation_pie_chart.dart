import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class AllocationPieChart extends StatefulWidget {
  const AllocationPieChart({
    super.key,
    required this.allocationPct,
    required this.totalValue,
  });

  final Map<String, double> allocationPct;
  final double totalValue;

  @override
  State<AllocationPieChart> createState() => _AllocationPieChartState();
}

class _AllocationPieChartState extends State<AllocationPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final entries = widget.allocationPct.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = AppColors.chartColors;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: entries.asMap().entries.map((entry) {
                      final i = entry.key;
                      final e = entry.value;
                      final isTouched = i == _touchedIndex;
                      final color = colors[i % colors.length];
                      return PieChartSectionData(
                        color: color,
                        value: e.value,
                        title: isTouched ? '${e.value.toStringAsFixed(1)}%' : '',
                        radius: isTouched ? 65 : 55,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entries.asMap().entries.map((entry) {
                      final i = entry.key;
                      final e = entry.value;
                      final color = colors[i % colors.length];
                      final assetValue =
                          widget.totalValue * e.value / 100;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.key,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.palette.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${e.value.toStringAsFixed(1)}%  ${assetValue.toINRCompact()}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: context.palette.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
