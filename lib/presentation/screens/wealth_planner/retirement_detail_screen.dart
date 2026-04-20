import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/retirement_models.dart';
import '../../providers/retirement_provider.dart';
import '../../widgets/common/member_selector.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class RetirementDetailScreen extends ConsumerStatefulWidget {
  const RetirementDetailScreen({super.key});

  @override
  ConsumerState<RetirementDetailScreen> createState() =>
      _RetirementDetailScreenState();
}

class _RetirementDetailScreenState
    extends ConsumerState<RetirementDetailScreen> {
  String? _selectedMemberId;

  @override
  Widget build(BuildContext context) {
    final readinessAsync =
        ref.watch(retirementReadinessProvider(_selectedMemberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retirement Planning'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(retirementReadinessProvider(_selectedMemberId));
        },
        child: CustomScrollView(
          slivers: [
            // ── Member selector ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: MemberSelector(
                  selectedMemberId: _selectedMemberId,
                  onSelected: (memberId) =>
                      setState(() => _selectedMemberId = memberId),
                ),
              ),
            ),

            // ── Main content ─────────────────────────────────────────────
            readinessAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.loss, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Error loading retirement data',
                        style: TextStyle(color: context.palette.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(
                            retirementReadinessProvider(_selectedMemberId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (readiness) => SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),

                  // 1. Corpus summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _CorpusSummaryCard(readiness: readiness),
                  ),

                  const SizedBox(height: 16),

                  // 2. Gap analysis
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _GapAnalysisCard(readiness: readiness),
                  ),

                  const SizedBox(height: 16),

                  // 3. Surplus / cash flow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SurplusCard(readiness: readiness),
                  ),

                  const SizedBox(height: 16),

                  // 4. Distribution phase
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child:
                        _DistributionPhaseCard(readiness: readiness),
                  ),

                  // 5. Corpus projection chart (only if data available)
                  if (readiness
                      .distributionPhase.yearlyProjections.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _CorpusProjectionChart(
                        projections:
                            readiness.distributionPhase.yearlyProjections,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared detail row ─────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? context.palette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card header helper ────────────────────────────────────────────────────────

Widget _cardHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      title,
      style: TextStyle(
        color: context.palette.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

ShapeBorder _cardShape(BuildContext context) {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: context.palette.bgDivider),
  );
}

// ── 1. Corpus Summary Card ────────────────────────────────────────────────────

class _CorpusSummaryCard extends StatelessWidget {
  const _CorpusSummaryCard({required this.readiness});

  final RetirementReadiness readiness;

  Color _statusColor(BuildContext context) {
    switch (readiness.statusLabel) {
      case 'On Track':
        return AppColors.gain;
      case 'Needs Attention':
        return AppColors.warning;
      case 'Behind':
        return AppColors.loss;
      case 'Critical':
        return AppColors.alertUrgent;
      default:
        return context.palette.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);
    final funded = readiness.fundedPct.clamp(0.0, 100.0);

    return Card(
      color: context.palette.bgCard,
      shape: _cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(context, 'Corpus Summary'),

            // Large funded % display
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${funded.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Funded',
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    readiness.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _DetailRow(
              label: 'Required Corpus',
              value: readiness.requiredCorpus.toINR(compact: true),
            ),
            _DetailRow(
              label: 'Current Trajectory',
              value: readiness.currentTrajectory.toINR(compact: true),
            ),
            _DetailRow(
              label: readiness.gap < 0 ? 'Over-funded by' : 'Gap',
              value: readiness.gap.abs().toINR(compact: true),
              valueColor:
                  readiness.gap <= 0 ? AppColors.gain : AppColors.loss,
            ),
            _DetailRow(
              label: 'Years to Retirement',
              value: '${readiness.yearsToRetirement} yrs',
            ),
          ],
        ),
      ),
    );
  }
}

// ── 2. Gap Analysis Card ──────────────────────────────────────────────────────

class _GapAnalysisCard extends StatelessWidget {
  const _GapAnalysisCard({required this.readiness});

  final RetirementReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final gap = readiness.gapAnalysis;
    final corpus = gap.corpus;

    return Card(
      color: context.palette.bgCard,
      shape: _cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(context, 'Gap Analysis'),

            _DetailRow(
              label: 'Current Portfolio',
              value: gap.currentPortfolioValue.toINR(compact: true),
            ),
            _DetailRow(
              label: 'Projected Portfolio (at retirement)',
              value: gap.projectedPortfolioValue.toINR(compact: true),
            ),
            if (gap.projectedLumpsumValue > 0)
              _DetailRow(
                label: 'Projected Lumpsums',
                value: gap.projectedLumpsumValue.toINR(compact: true),
              ),
            _DetailRow(
              label: 'Total Trajectory',
              value: gap.totalProjectedValue.toINR(compact: true),
            ),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: context.palette.bgDivider, height: 1),
            ),

            _DetailRow(
              label: 'Monthly Expense at Retirement',
              value: corpus.monthlyExpenseAtRetirement.toINR(compact: true),
            ),
            _DetailRow(
              label: 'Expected Return',
              value: gap.expectedReturn.toPercent(),
            ),
            _DetailRow(
              label: 'Inflation Rate',
              value: corpus.inflationRate.toPercent(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 3. Surplus Card ───────────────────────────────────────────────────────────

class _SurplusCard extends StatelessWidget {
  const _SurplusCard({required this.readiness});

  final RetirementReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final gap = readiness.gapAnalysis;

    return Card(
      color: context.palette.bgCard,
      shape: _cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(context, 'Monthly Cash Flow'),

            _DetailRow(
              label: 'Investable Surplus',
              value: gap.investableSurplus.toINR(compact: true),
              valueColor: gap.investableSurplus > 0
                  ? AppColors.gain
                  : AppColors.loss,
            ),
            _DetailRow(
              label: 'Required Monthly SIP',
              value: gap.requiredMonthlySip.toINR(compact: true),
            ),
            _DetailRow(
              label: 'SIP Affordable?',
              value: gap.isSipAffordable ? 'Yes ✓' : 'No — exceeds surplus',
              valueColor: gap.isSipAffordable
                  ? AppColors.gain
                  : AppColors.loss,
            ),

            if (gap.incomeType != 'steady') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Income type: ${gap.incomeType}. Surplus may vary.',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 4. Distribution Phase Card ────────────────────────────────────────────────

class _DistributionPhaseCard extends StatelessWidget {
  const _DistributionPhaseCard({required this.readiness});

  final RetirementReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final dist = readiness.distributionPhase;

    // Bar segment data: [Debt, Equity, Income, Cash]
    final segments = [
      _BarSegment(
          pct: dist.debtPct,
          color: AppColors.chartColors[3],
          label: 'Debt'),
      _BarSegment(
          pct: dist.equityPct,
          color: AppColors.chartColors[0],
          label: 'Equity'),
      _BarSegment(
          pct: dist.incomePct,
          color: AppColors.chartColors[1],
          label: 'Income'),
      _BarSegment(
          pct: dist.cashPct,
          color: AppColors.chartColors[4],
          label: 'Cash'),
    ].where((s) => s.pct > 0).toList();

    return Card(
      color: context.palette.bgCard,
      shape: _cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(context, 'Post-Retirement Income'),

            // Sustainability label
            Text(
              dist.sustainabilityLabel,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 12),

            _DetailRow(
              label: 'Monthly Income (initial)',
              value: dist.monthlyIncome.toINR(compact: true),
              valueColor: AppColors.gain,
            ),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: context.palette.bgDivider, height: 1),
            ),

            Text(
              'Distribution Allocation',
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 10),

            // Stacked horizontal bar
            if (segments.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 20,
                  child: Row(
                    children: segments
                        .map((s) => Flexible(
                              flex: (s.pct * 100).round(),
                              child: Container(color: s.color),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Legend with % labels
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: segments
                    .map((s) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: s.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${s.label} ${(s.pct * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: context.palette.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarSegment {
  const _BarSegment({
    required this.pct,
    required this.color,
    required this.label,
  });

  final double pct;
  final Color color;
  final String label;
}

// ── 5. Corpus Projection Chart ────────────────────────────────────────────────

class _CorpusProjectionChart extends StatelessWidget {
  const _CorpusProjectionChart({required this.projections});

  final List<YearlyProjection> projections;

  @override
  Widget build(BuildContext context) {
    // Pick every 5th year for readability, always include last
    final displayIndices = <int>{};
    for (int i = 0; i < projections.length; i++) {
      if (i == 0 || (projections[i].year % 5 == 0)) {
        displayIndices.add(i);
      }
    }
    displayIndices.add(projections.length - 1);
    final displayList = displayIndices.toList()..sort();

    final maxVal = projections
        .map((p) => p.corpusEnd.abs())
        .fold(0.0, (a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.2 : 1.0;

    final barGroups = displayList.map((idx) {
      final proj = projections[idx];
      final ratio =
          maxVal > 0 ? proj.corpusEnd / maxVal : 0.0;
      final barColor = ratio > 0.5
          ? AppColors.gain
          : ratio > 0.2
              ? AppColors.warning
              : AppColors.loss;

      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: proj.corpusEnd.clamp(0, double.infinity),
            color: barColor,
            width: 14,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return Card(
      color: context.palette.bgCard,
      shape: _cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(context, 'Corpus Depletion Over Retirement'),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  barGroups: barGroups,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (!displayList.contains(idx)) {
                            return const SizedBox.shrink();
                          }
                          final year = projections[idx].year;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Y$year',
                              style: TextStyle(
                                color: context.palette.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        reservedSize: 24,
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => context.palette.bgCardElevated,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final idx = group.x;
                        final proj = projections[idx];
                        return BarTooltipItem(
                          'Year ${proj.year}\n${proj.corpusEnd.toINR(compact: true)}',
                          TextStyle(
                            color: context.palette.textPrimary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
