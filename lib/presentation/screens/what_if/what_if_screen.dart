import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/what_if_provider.dart';
import '../../widgets/common/fund_search_dropdown.dart';
import '../../widgets/common/kpi_card.dart';

class WhatIfScreen extends ConsumerStatefulWidget {
  const WhatIfScreen({super.key});

  @override
  ConsumerState<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends ConsumerState<WhatIfScreen> {
  final _amountCtrl = TextEditingController(text: '5000');

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = ref.watch(whatIfInputNotifierProvider);
    final notifier = ref.read(whatIfInputNotifierProvider.notifier);
    final resultAsync = ref.watch(whatIfResultProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('What-If Analysis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Fund picker ───────────────────────────────────────────────
          Text('Select Fund',
              style: TextStyle(
                  fontSize: 12,
                  color: context.palette.textTertiary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          FundSearchDropdown(
            initialFund: input.fund,
            onSelected: notifier.setFund,
          ),
          const SizedBox(height: 16),

          // ── SIP / Lumpsum toggle ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ToggleOption(
                  label: 'Monthly SIP',
                  icon: Icons.repeat,
                  selected: input.isSip,
                  onTap: () => notifier.setSip(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ToggleOption(
                  label: 'Lumpsum',
                  icon: Icons.bolt,
                  selected: !input.isSip,
                  onTap: () => notifier.setSip(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Amount ────────────────────────────────────────────────────
          Text(input.isSip ? 'Monthly SIP Amount (₹)' : 'Lumpsum Amount (₹)',
              style: TextStyle(
                  fontSize: 12,
                  color: context.palette.textTertiary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: '₹ '),
            onChanged: (v) {
              final amount = double.tryParse(v);
              if (amount != null && amount > 0) notifier.setAmount(amount);
            },
          ),
          const SizedBox(height: 16),

          // ── Duration ─────────────────────────────────────────────────
          Row(
            children: [
              Text('Duration: ',
                  style: TextStyle(
                      fontSize: 12, color: context.palette.textTertiary)),
              Text('${input.years} year${input.years > 1 ? 's' : ''}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.palette.textPrimary)),
            ],
          ),
          Slider(
            value: input.years.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            activeColor: AppColors.primary,
            label: '${input.years}Y',
            onChanged: (v) => notifier.setYears(v.round()),
          ),
          const SizedBox(height: 8),

          // ── Results ───────────────────────────────────────────────────
          if (input.fund == null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Select a fund to see projection',
                    style: TextStyle(color: context.palette.textTertiary)),
              ),
            )
          else
            resultAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: AppColors.loss)),
              data: (result) {
                if (result == null) {
                  return Text('No data available for this fund.',
                      style: TextStyle(color: context.palette.textTertiary));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 12),

                    // KPI summary
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        KpiCard(
                          label: 'Projected Value',
                          value: result.projectedValue.toINRCompact(),
                          valueColor: AppColors.primary,
                        ),
                        KpiCard(
                          label: 'Total Invested',
                          value: result.totalInvested.toINRCompact(),
                        ),
                        KpiCard(
                          label: 'Projected Gain',
                          value:
                              '+${result.projectedGain.toINRCompact()}',
                          valueColor: AppColors.gain,
                        ),
                        KpiCard(
                          label: 'Projected XIRR',
                          value: result.projectedXirr != null
                              ? result.projectedXirr!.toReturnLabel()
                              : '—',
                          valueColor: AppColors.gain,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Growth chart
                    if (result.growthCurve.isNotEmpty) ...[
                      const Text('Projected Growth',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _GrowthChart(curve: result.growthCurve),
                    ],

                    // Portfolio impact
                    if (result.newAllocationPct.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Portfolio Impact',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _AllocationDelta(
                        before: result.beforeAllocationPct,
                        after: result.newAllocationPct,
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.15)
              : context.palette.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : context.palette.bgDivider,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? AppColors.primary : context.palette.textTertiary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? AppColors.primary
                        : context.palette.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _GrowthChart extends StatelessWidget {
  const _GrowthChart({required this.curve});
  final List<({DateTime date, double value, double invested})> curve;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.bgDivider),
      ),
      padding: const EdgeInsets.all(8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: curve.length / 4,
                getTitlesWidget: (x, _) {
                  final i = x.toInt().clamp(0, curve.length - 1);
                  return Text(
                    DateFormat('yy').format(curve[i].date),
                    style: TextStyle(
                        fontSize: 9, color: context.palette.textTertiary),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            // Projected value line
            LineChartBarData(
              spots: curve.asMap().entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                  .toList(),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.06),
              ),
            ),
            // Invested line
            LineChartBarData(
              spots: curve.asMap().entries
                  .map((e) =>
                      FlSpot(e.key.toDouble(), e.value.invested))
                  .toList(),
              isCurved: false,
              color: context.palette.textTertiary,
              barWidth: 1.5,
              dashArray: [4, 4],
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllocationDelta extends StatelessWidget {
  const _AllocationDelta({required this.before, required this.after});
  final Map<String, double> before;
  final Map<String, double> after;

  @override
  Widget build(BuildContext context) {
    final keys = {...before.keys, ...after.keys}.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.bgDivider),
      ),
      child: Column(
        children: keys.map((key) {
          final b = before[key] ?? 0;
          final a = after[key] ?? 0;
          final delta = a - b;
          final color = delta > 0
              ? AppColors.gain
              : delta < 0
                  ? AppColors.loss
                  : context.palette.textTertiary;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                    child: Text(key,
                        style: const TextStyle(fontSize: 13))),
                Text('${b.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 12, color: context.palette.textTertiary)),
                Text(' → ',
                    style: TextStyle(color: context.palette.textTertiary)),
                Text('${a.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text(
                  '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
