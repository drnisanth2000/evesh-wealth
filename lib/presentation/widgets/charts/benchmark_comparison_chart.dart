import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/index_nav_point.dart';

/// Plots a fund's NAV history vs its benchmark index, both rebased to 100 at
/// the earliest common date. CAGR for each series is shown in the legend.
class BenchmarkComparisonChart extends StatelessWidget {
  const BenchmarkComparisonChart({
    super.key,
    required this.fundNavPoints,
    required this.indexNavPoints,
    required this.benchmarkLabel,
  });

  /// Fund NAV history as (date, nav) tuples, ordered ascending.
  final List<MapEntry<DateTime, double>> fundNavPoints;
  final List<IndexNavPoint> indexNavPoints;
  final String benchmarkLabel;

  @override
  Widget build(BuildContext context) {
    if (fundNavPoints.isEmpty || indexNavPoints.isEmpty) {
      return const _EmptyState();
    }
    // Align by date — keep dates that exist in both series.
    final fundMap = <DateTime, double>{
      for (final e in fundNavPoints) _dateOnly(e.key): e.value,
    };
    final indexMap = <DateTime, double>{
      for (final p in indexNavPoints) _dateOnly(p.navDate): p.nav,
    };
    final commonDates = fundMap.keys.where(indexMap.containsKey).toList()
      ..sort();
    if (commonDates.length < 2) return const _EmptyState();

    final baseDate = commonDates.first;
    final baseFund = fundMap[baseDate]!;
    final baseIndex = indexMap[baseDate]!;
    if (baseFund <= 0 || baseIndex <= 0) return const _EmptyState();

    final fundSpots = <FlSpot>[];
    final indexSpots = <FlSpot>[];
    for (var i = 0; i < commonDates.length; i++) {
      final d = commonDates[i];
      fundSpots.add(FlSpot(i.toDouble(), (fundMap[d]! / baseFund) * 100));
      indexSpots.add(FlSpot(i.toDouble(), (indexMap[d]! / baseIndex) * 100));
    }

    // CAGR delta in legend
    final years = commonDates.last.difference(baseDate).inDays / 365.25;
    final fundFinal = fundSpots.last.y;
    final indexFinal = indexSpots.last.y;
    String fmtCagr(double finalVal) {
      if (years <= 0) return '—';
      final cagr = (math.pow(finalVal / 100, 1 / years) - 1) * 100;
      return '${cagr >= 0 ? '+' : ''}${cagr.toStringAsFixed(1)}%';
    }
    final fundCagrLabel = fmtCagr(fundFinal);
    final indexCagrLabel = fmtCagr(indexFinal);

    final allY = [...fundSpots.map((s) => s.y), ...indexSpots.map((s) => s.y)];
    final minY = (allY.reduce(math.min) * 0.98).floorToDouble();
    final maxY = (allY.reduce(math.max) * 1.02).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _LegendDot(color: context.palette.gain, label: 'Fund $fundCagrLabel'),
            _LegendDot(color: Colors.blueAccent, label: '$benchmarkLabel $indexCagrLabel'),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 38),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: fundSpots,
                  color: context.palette.gain,
                  barWidth: 2,
                  isCurved: false,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: indexSpots,
                  color: Colors.blueAccent,
                  barWidth: 2,
                  isCurved: false,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          'Benchmark data not available yet.',
          style: TextStyle(fontSize: 12, color: context.palette.textTertiary),
        ),
      ),
    );
  }
}
