import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/overlap_models.dart';
import '../../../domain/usecases/compute_portfolio_overlap.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/overlap_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../widgets/common/kpi_card.dart';
import '../../widgets/common/member_selector.dart';
import '../../widgets/overlap/educational_cards.dart';
import '../../widgets/overlap/fund_overlap_list.dart';
import '../../widgets/overlap/sector_chart.dart';
import '../../widgets/overlap/stock_exposure_list.dart';
import '../../widgets/overlap/traffic_light.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String? _selectedMemberId;
  _SortField _sortField = _SortField.cagr;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Performance'),
            Tab(text: 'Risk Metrics'),
            Tab(text: 'Overlap'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Member selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: MemberSelector(
              selectedMemberId: _selectedMemberId,
              onSelected: (id) => setState(() => _selectedMemberId = id),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _PerformanceTab(
                  memberId: _selectedMemberId,
                  sortField: _sortField,
                  onSortChanged: (f) => setState(() => _sortField = f),
                ),
                _RiskTab(memberId: _selectedMemberId),
                _OverlapTab(memberId: _selectedMemberId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Performance Tab ───────────────────────────────────────────────────────────
class _PerformanceTab extends ConsumerWidget {
  const _PerformanceTab({
    required this.memberId,
    required this.sortField,
    required this.onSortChanged,
  });

  final String? memberId;
  final _SortField sortField;
  final void Function(_SortField) onSortChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioSummaryProvider(memberId));

    return portfolioAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: context.palette.loss, size: 48),
            const SizedBox(height: 12),
            Text('$e', style: TextStyle(color: context.palette.textSecondary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(portfolioSummaryProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (portfolio) {
        if (portfolio.fundHoldings.isEmpty) {
          return Center(
            child: Text(
              'No holdings found.\nAdd transactions to see analytics.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.textSecondary),
            ),
          );
        }

        // Sort holdings
        final holdings = [...portfolio.fundHoldings];
        switch (sortField) {
          case _SortField.cagr:
            holdings.sort((a, b) => (b.cagr ?? -99).compareTo(a.cagr ?? -99));
          case _SortField.gain:
            holdings.sort((a, b) => b.gainPct.compareTo(a.gainPct));
          case _SortField.value:
            holdings.sort((a, b) => b.currentValue.compareTo(a.currentValue));
          case _SortField.xirr:
            holdings.sort((a, b) => (b.xirr ?? -99).compareTo(a.xirr ?? -99));
        }

        final best = holdings.first;
        final worst = holdings.last;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Portfolio XIRR / CAGR hero ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.palette.bgCard, context.palette.bgCardElevated],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.palette.bgDivider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portfolio Returns',
                    style: TextStyle(
                        color: context.palette.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: KpiCard(
                          label: 'XIRR',
                          value: portfolio.xirr != null && !portfolio.xirr!.isNaN
                              ? portfolio.xirr!.toPercent()
                              : '—',
                          valueColor: portfolio.xirr != null && portfolio.xirr! > 0
                              ? context.palette.gain
                              : context.palette.textSecondary,
                          tooltip: 'Annualised return accounting for investment timing',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: KpiCard(
                          label: 'Total Gain',
                          value: portfolio.gainPct.toReturnLabel(),
                          valueColor: portfolio.totalGain >= 0
                              ? context.palette.gain
                              : context.palette.loss,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: KpiCard(
                          label: 'Invested',
                          value: portfolio.totalInvested.toINRCompact(),
                          valueColor: context.palette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Best / Worst ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _PerformerCard(
                    label: 'Best Performer',
                    fundName: best.fundName,
                    metric: best.cagr != null
                        ? 'CAGR ${best.cagr!.toPercent()}'
                        : best.gainPct.toReturnLabel(),
                    color: context.palette.gain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PerformerCard(
                    label: 'Needs Review',
                    fundName: worst.fundName,
                    metric: worst.cagr != null
                        ? 'CAGR ${worst.cagr!.toPercent()}'
                        : worst.gainPct.toReturnLabel(),
                    color: worst.gainPct < 0 ? context.palette.loss : AppColors.warning,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Sort bar ──────────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Sort by:',
                  style: TextStyle(
                      color: context.palette.textTertiary, fontSize: 12),
                ),
                const SizedBox(width: 8),
                ..._SortField.values.map((f) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _SortChip(
                        label: f.label,
                        selected: f == sortField,
                        onTap: () => onSortChanged(f),
                      ),
                    )),
              ],
            ),

            const SizedBox(height: 12),

            // ── Fund table ────────────────────────────────────────────────
            ...holdings.map((h) => _FundPerformanceRow(
                  fundName: h.fundName,
                  category: h.assetClassLabel ?? h.category ?? '—',
                  currentValue: h.currentValue,
                  gainPct: h.gainPct,
                  cagr: h.cagr,
                  xirr: h.xirr,
                )),

            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

// ── Risk Tab ──────────────────────────────────────────────────────────────────
class _RiskTab extends ConsumerWidget {
  const _RiskTab({required this.memberId});
  final String? memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioSummaryProvider(memberId));

    return portfolioAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (portfolio) {
        final mfHoldings = portfolio.fundHoldings
            .where((h) => h.amfiCode != null)
            .toList();

        if (mfHoldings.isEmpty) {
          return Center(
            child: Text(
              'No mutual fund holdings found.',
              style: TextStyle(color: context.palette.textSecondary),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Risk metrics require NAV history. Sharpe, Sortino and max drawdown '
                'are computed once NAV history is available for each fund.',
                style: TextStyle(
                    fontSize: 12, color: context.palette.textSecondary),
              ),
            ),
            ...mfHoldings.map((h) => _FundRiskCard(
                  amfiCode: h.amfiCode!,
                  fundName: h.fundName,
                )),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _FundRiskCard extends ConsumerWidget {
  const _FundRiskCard({
    required this.amfiCode,
    required this.fundName,
  });

  final int amfiCode;
  final String fundName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(fundAnalyticsProvider(amfiCode));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fundName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            analyticsAsync.when(
              loading: () => const SizedBox(
                height: 20,
                child: LinearProgressIndicator(minHeight: 2),
              ),
              error: (e, _) => Text(
                'Could not load risk data',
                style: TextStyle(
                    color: context.palette.textTertiary, fontSize: 12),
              ),
              data: (a) {
                if (a.navPoints.isEmpty) {
                  return Text(
                    'No NAV history available yet',
                    style: TextStyle(
                        color: context.palette.textTertiary, fontSize: 12),
                  );
                }
                return Row(
                  children: [
                    _RiskStat(
                      'Sharpe',
                      a.sharpe != null
                          ? a.sharpe!.toStringAsFixed(2)
                          : '—',
                      a.sharpe != null && a.sharpe! > 1
                          ? context.palette.gain
                          : context.palette.textSecondary,
                    ),
                    const SizedBox(width: 20),
                    _RiskStat(
                      'Sortino',
                      a.sortino != null
                          ? a.sortino!.toStringAsFixed(2)
                          : '—',
                      a.sortino != null && a.sortino! > 1
                          ? context.palette.gain
                          : context.palette.textSecondary,
                    ),
                    const SizedBox(width: 20),
                    _RiskStat(
                      'Max Drawdown',
                      a.maxDrawdown != null
                          ? (a.maxDrawdown! * 100).toPercent()
                          : '—',
                      context.palette.loss,
                    ),
                    const SizedBox(width: 20),
                    _RiskStat(
                      'NAV Points',
                      '${a.navPoints.length}d',
                      context.palette.textSecondary,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _PerformerCard extends StatelessWidget {
  const _PerformerCard({
    required this.label,
    required this.fundName,
    required this.metric,
    required this.color,
  });

  final String label;
  final String fundName;
  final String metric;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            fundName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: context.palette.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(metric,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FundPerformanceRow extends StatelessWidget {
  const _FundPerformanceRow({
    required this.fundName,
    required this.category,
    required this.currentValue,
    required this.gainPct,
    this.cagr,
    this.xirr,
  });

  final String fundName;
  final String category;
  final double currentValue;
  final double gainPct;
  final double? cagr;
  final double? xirr;

  @override
  Widget build(BuildContext context) {
    final isGain = gainPct >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.bgDivider),
      ),
      child: Row(
        children: [
          // Fund name + category
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fundName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  category,
                  style: TextStyle(
                      fontSize: 11, color: context.palette.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Metrics
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currentValue.toINRCompact(),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    gainPct.toReturnLabel(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isGain ? context.palette.gain : context.palette.loss,
                    ),
                  ),
                  if (cagr != null) ...[
                    Text('  ·  ',
                        style: TextStyle(
                            color: context.palette.textTertiary, fontSize: 11)),
                    Text(
                      'CAGR ${cagr!.toPercent()}',
                      style: TextStyle(
                          fontSize: 11, color: context.palette.textSecondary),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : context.palette.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppColors.primary : context.palette.bgDivider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.primary : context.palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RiskStat extends StatelessWidget {
  const _RiskStat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10, color: context.palette.textTertiary)),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

// ── Overlap Tab ───────────────────────────────────────────────────────────────
class _OverlapTab extends ConsumerWidget {
  const _OverlapTab({required this.memberId});
  final String? memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdingsAsync = ref.watch(portfolioHoldingsProvider(memberId));

    return holdingsAsync.when(
      loading: () => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Analyzing portfolio overlap...',
              style: TextStyle(color: context.palette.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
      error: (e, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: context.palette.loss, size: 48),
            const SizedBox(height: 12),
            Text(
              '$e',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.invalidate(portfolioHoldingsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (funds) {
        if (funds.isEmpty) {
          return Center(
            child: Text(
              'Add mutual fund holdings to see overlap analysis',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.textSecondary, fontSize: 13),
            ),
          );
        }

        // Separate funds with and without holdings data
        final fundsWithData = funds.where((f) => f.holdings.isNotEmpty).toList();
        final pendingCount = funds.where((f) => f.holdings.isEmpty).length;

        final result = PortfolioOverlapCalculator.compute(funds);

        return ListView(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
          children: [
            // ── Portfolio health badge ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PortfolioHealthBadge(
                risk: result.overallRisk,
                issueCount: result.issueCount,
              ),
            ),

            // ── Pending data notice ──────────────────────────────────────
            if (pendingCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top_rounded,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Holdings data is being fetched for $pendingCount fund${pendingCount > 1 ? 's' : ''}. '
                          'Overlap results will improve once data is available.',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Sector Allocation (collapsed by default) ─────────────────
            const SizedBox(height: 16),
            SectorChart(sectors: result.sectorExposures),

            // ── Top Stock Exposures (collapsed by default) ─────────────
            const SizedBox(height: 12),
            StockExposureList(stocks: result.stockExposures),

            // ── Fund Overlap ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Fund Overlap',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.palette.textPrimary,
                ),
              ),
            ),
            FundOverlapList(pairs: result.fundPairOverlaps),

            // ── Educational cards ─────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: OverlapEducation(),
            ),
          ],
        );
      },
    );
  }
}

enum _SortField {
  cagr('CAGR'),
  gain('Gain %'),
  xirr('XIRR'),
  value('Value');

  const _SortField(this.label);
  final String label;
}
