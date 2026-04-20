// lib/presentation/screens/wealth_planner/projection_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/projection_models.dart';
import '../../providers/projection_provider.dart';
import '../../widgets/common/member_selector.dart';

class ProjectionScreen extends ConsumerStatefulWidget {
  const ProjectionScreen({super.key});

  @override
  ConsumerState<ProjectionScreen> createState() => _ProjectionScreenState();
}

class _ProjectionScreenState extends ConsumerState<ProjectionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _sipCtrl = TextEditingController();
  String? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _sipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizon = ref.watch(projectionHorizonNotifierProvider);
    final resultAsync = ref.watch(projectionResultProvider(_selectedMemberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projections'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Scenarios'),
            Tab(text: 'Waterfall'),
            Tab(text: 'Stress Test'),
            Tab(text: 'Behavior'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Member selector ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: MemberSelector(
              selectedMemberId: _selectedMemberId,
              onSelected: (id) => setState(() => _selectedMemberId = id),
            ),
          ),
          // ── Controls ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                // Horizon selector
                Text('Horizon: ', style: TextStyle(fontSize: 12, color: context.palette.textTertiary)),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 5, label: Text('5Y')),
                    ButtonSegment(value: 10, label: Text('10Y')),
                    ButtonSegment(value: 15, label: Text('15Y')),
                    ButtonSegment(value: 20, label: Text('20Y')),
                  ],
                  selected: {horizon},
                  onSelectionChanged: (v) =>
                      ref.read(projectionHorizonNotifierProvider.notifier).set(v.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                // SIP input
                Expanded(
                  child: TextField(
                    controller: _sipCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      hintText: 'Monthly SIP',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (v) {
                      final sip = double.tryParse(v);
                      if (sip != null && sip >= 0) {
                        ref.read(projectionSipNotifierProvider.notifier).set(sip);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Tab content ──
          Expanded(
            child: resultAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.loss))),
              data: (result) => TabBarView(
                controller: _tabCtrl,
                children: [
                  _ScenariosTab(result: result),
                  _WaterfallTab(result: result),
                  _StressTestTab(result: result),
                  _BehaviorTab(result: result),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Scenarios ─────────────────────────────────────────────────────────

class _ScenariosTab extends StatelessWidget {
  const _ScenariosTab({required this.result});
  final ProjectionResult result;

  static const _colors = [AppColors.warning, AppColors.primary, AppColors.gain];

  @override
  Widget build(BuildContext context) {
    final scenarios = result.scenarios;
    if (scenarios.isEmpty) return const Center(child: Text('No data'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Line chart
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: context.palette.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.palette.bgDivider),
          ),
          padding: const EdgeInsets.all(12),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (result.input.horizonYears / 4).ceilToDouble(),
                    getTitlesWidget: (x, _) {
                      return Text('Y${x.toInt()}',
                          style: TextStyle(fontSize: 9, color: context.palette.textTertiary));
                    },
                  ),
                ),
              ),
              lineBarsData: scenarios.asMap().entries.map((entry) {
                final s = entry.value;
                final color = _colors[entry.key];
                return LineChartBarData(
                  spots: s.points
                      .map((p) => FlSpot(p.year.toDouble(), p.endValue))
                      .toList(),
                  isCurved: true,
                  color: color,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: entry.key == 1, // fill only moderate
                    color: color.withValues(alpha: 0.06),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: scenarios.asMap().entries.map((entry) {
            final s = entry.value;
            final color = _colors[entry.key];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2),
                )),
                const SizedBox(width: 4),
                Text('${s.name} (${s.annualReturn.toStringAsFixed(0)}%)',
                    style: TextStyle(fontSize: 11, color: context.palette.textSecondary)),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // KPI cards per scenario
        ...scenarios.asMap().entries.map((entry) {
          final s = entry.value;
          final color = _colors[entry.key];
          return Card(
            color: context.palette.bgCard,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: TextStyle(
                            fontWeight: FontWeight.w600, color: color, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('${s.annualReturn.toStringAsFixed(0)}% p.a.',
                            style: TextStyle(fontSize: 11, color: context.palette.textTertiary)),
                      ],
                    ),
                  ),
                  _KpiCol('Final', s.finalValue.toINR(compact: true)),
                  const SizedBox(width: 16),
                  _KpiCol('Gain', s.totalGain.toINR(compact: true)),
                  const SizedBox(width: 16),
                  _KpiCol('Multiple', '${s.wealthMultiple.toStringAsFixed(1)}x'),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Tab 2: Waterfall ─────────────────────────────────────────────────────────

class _WaterfallTab extends StatelessWidget {
  const _WaterfallTab({required this.result});
  final ProjectionResult result;

  @override
  Widget build(BuildContext context) {
    final steps = result.waterfall;
    if (steps.isEmpty) return const Center(child: Text('No data'));

    final maxVal = steps.map((s) => s.runningTotal).fold(0.0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Waterfall bars
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: context.palette.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.palette.bgDivider),
          ),
          padding: const EdgeInsets.all(12),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.15,
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (x, _) {
                      final idx = x.toInt();
                      if (idx < 0 || idx >= steps.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          steps[idx].label.split(' ').first,
                          style: TextStyle(fontSize: 8, color: context.palette.textTertiary),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: steps.asMap().entries.map((entry) {
                final step = entry.value;
                final color = step.isPositive ? AppColors.gain : AppColors.loss;
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: step.runningTotal.clamp(0, double.infinity),
                      color: color,
                      width: 22,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Step details
        ...steps.map((step) {
          final color = step.isPositive ? AppColors.gain : AppColors.loss;
          final sign = step.isPositive ? '+' : '-';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  step.isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  size: 16, color: color,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(step.label,
                    style: TextStyle(fontSize: 13, color: context.palette.textPrimary))),
                Text(
                  '$sign${step.value.toINR(compact: true)}',
                  style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Tab 3: Stress Test ───────────────────────────────────────────────────────

class _StressTestTab extends StatelessWidget {
  const _StressTestTab({required this.result});
  final ProjectionResult result;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'How would your current portfolio perform in a historical crash?',
          style: TextStyle(fontSize: 13, color: context.palette.textSecondary),
        ),
        const SizedBox(height: 16),
        ...result.stressTests.map((s) => _StressCard(scenario: s)),
      ],
    );
  }
}

class _StressCard extends StatelessWidget {
  const _StressCard({required this.scenario});
  final StressScenario scenario;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.bgCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.palette.bgDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, color: AppColors.loss, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scenario.name, style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14, color: context.palette.textPrimary)),
                      Text(scenario.description, style: TextStyle(
                          fontSize: 11, color: context.palette.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _KpiCol('Drawdown', '${scenario.portfolioDrawdownPct.toStringAsFixed(1)}%',
                    color: AppColors.loss),
                _KpiCol('Loss', scenario.portfolioLoss.toINR(compact: true),
                    color: AppColors.loss),
                _KpiCol('Nadir', scenario.nadir.toINR(compact: true)),
                _KpiCol('Recovery', '${scenario.recoveryMonths}mo',
                    color: AppColors.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 4: Behavior ──────────────────────────────────────────────────────────

class _BehaviorTab extends StatelessWidget {
  const _BehaviorTab({required this.result});
  final ProjectionResult result;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'The real cost of common investor mistakes over your horizon',
          style: TextStyle(fontSize: 13, color: context.palette.textSecondary),
        ),
        const SizedBox(height: 16),
        ...result.behaviorScenarios.map((s) => _BehaviorCard(scenario: s)),
      ],
    );
  }
}

class _BehaviorCard extends StatelessWidget {
  const _BehaviorCard({required this.scenario});
  final BehaviorScenario scenario;

  @override
  Widget build(BuildContext context) {
    final isBaseline = scenario.costOfMistake <= 0;
    final borderColor = isBaseline ? AppColors.gain : AppColors.loss;

    return Card(
      color: context.palette.bgCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isBaseline ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: borderColor, size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(scenario.name, style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14, color: context.palette.textPrimary)),
                ),
                if (!isBaseline)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.loss.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${scenario.costPct.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12, color: AppColors.loss, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(scenario.description, style: TextStyle(
                fontSize: 11, color: context.palette.textTertiary)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _KpiCol('Projected', scenario.projectedValue.toINR(compact: true)),
                if (!isBaseline) ...[
                  _KpiCol('Baseline', scenario.baselineValue.toINR(compact: true)),
                  _KpiCol('Cost', scenario.costOfMistake.toINR(compact: true),
                      color: AppColors.loss),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.info),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(scenario.insight, style: const TextStyle(
                        fontSize: 11, color: AppColors.info)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────────

class _KpiCol extends StatelessWidget {
  const _KpiCol(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: context.palette.textTertiary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: color ?? context.palette.textPrimary)),
      ],
    );
  }
}
