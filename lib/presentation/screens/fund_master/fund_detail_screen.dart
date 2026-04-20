import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/watchlist_rule_model.dart';
import '../../../domain/usecases/calculate_rolling_returns.dart';
import '../../../domain/usecases/calculate_sharpe.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/fund_provider.dart';
import '../../providers/index_nav_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/charts/benchmark_comparison_chart.dart';
import '../../widgets/common/kpi_card.dart';
import '../../widgets/common/member_selector.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/overlap/portfolio_fit_section.dart';

class FundDetailScreen extends ConsumerStatefulWidget {
  const FundDetailScreen({super.key, required this.amfiCode});
  final int amfiCode;

  @override
  ConsumerState<FundDetailScreen> createState() => _FundDetailScreenState();
}

class _FundDetailScreenState extends ConsumerState<FundDetailScreen> {
  String? _selectedMemberId;

  @override
  Widget build(BuildContext context) {
    final amfiCode = widget.amfiCode;
    final fundAsync = ref.watch(fundDetailProvider(amfiCode));
    final analyticsAsync = ref.watch(fundAnalyticsProvider(amfiCode));
    final portfolioAsync = ref.watch(portfolioSummaryProvider(_selectedMemberId));

    final holding = portfolioAsync.valueOrNull?.fundHoldings
        .where((f) => f.amfiCode == amfiCode)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: fundAsync.when(
          data: (f) => Text(
            f?.fundName ?? 'Fund Detail',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16),
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Fund Detail'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(fundDetailProvider(amfiCode));
          ref.invalidate(fundAnalyticsProvider(amfiCode));
        },
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            // ── Member selector ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: MemberSelector(
                selectedMemberId: _selectedMemberId,
                onSelected: (id) => setState(() => _selectedMemberId = id),
              ),
            ),
            // ── Fund header ───────────────────────────────────────────────
            fundAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (fund) {
                if (fund == null) {
                  return const Center(child: Text('Fund not found'));
                }
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fund.fundName,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        [fund.amc, fund.subCategory ?? fund.category, fund.planType]
                            .where((s) => s != null && s.toString().isNotEmpty)
                            .join(' • '),
                        style: TextStyle(
                            fontSize: 12, color: context.palette.textTertiary),
                      ),
                      // ── Inception date / fund age hint ─────────────
                      if (_inceptionLine(fund.launchDate) != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _inceptionLine(fund.launchDate)!,
                          style: TextStyle(
                              fontSize: 11, color: context.palette.textTertiary),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── NAV / Day Change / ER row ─────────────────
                      Row(
                        children: [
                          _NavBlock(
                            label: 'NAV',
                            value: fund.latestNav != null
                                ? '₹${fund.latestNav!.toStringAsFixed(4)}'
                                : '—',
                          ),
                          const SizedBox(width: 20),
                          if (fund.nav1dChangePct != null)
                            _NavBlock(
                              label: 'Day Change',
                              value:
                                  '${fund.nav1dChangePct! >= 0 ? '+' : ''}${fund.nav1dChangePct!.toStringAsFixed(2)}%',
                              color: fund.nav1dChangePct! >= 0
                                  ? AppColors.gain
                                  : AppColors.loss,
                            ),
                          const SizedBox(width: 20),
                          if (fund.expenseRatio != null)
                            _NavBlock(
                              label: 'Expense Ratio',
                              value: '${fund.expenseRatio!.toStringAsFixed(2)}%',
                            ),
                          if (fund.aumCr != null) ...[
                            const SizedBox(width: 20),
                            _NavBlock(
                              label: 'AUM',
                              value: '₹${fund.aumCr!.toStringAsFixed(0)} Cr',
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── vs Benchmark chart ──────────────────────────
                      if (fund.benchmarkTier1 != null) ...[
                        const SectionHeader(title: 'vs Benchmark'),
                        const SizedBox(height: 8),
                        _BenchmarkSection(
                          amfiCode: amfiCode,
                          benchmark: fund.benchmarkTier1!,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── CRISIL section ─────────────────────────────
                      if (fund.crisilRating != null || fund.fundRating != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: context.palette.bgSurface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.palette.bgDivider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Row 1: Star rating (if available) + Riskometer ──
                              Row(
                                children: [
                                  // Star rating (when fund_rating exists)
                                  if (fund.fundRating != null) ...[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('CRISIL Rank',
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  color: context.palette.textTertiary,
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: 0.5)),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(5, (i) {
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 2),
                                                child: Icon(
                                                  i < fund.fundRating!
                                                      ? Icons.star_rounded
                                                      : Icons.star_outline_rounded,
                                                  size: 18,
                                                  color: i < fund.fundRating!
                                                      ? _ratingColor(fund.fundRating!)
                                                      : context.palette.textTertiary.withOpacity(0.3),
                                                ),
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 32,
                                      color: context.palette.bgDivider,
                                      margin: const EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                  ],

                                  // Riskometer — ALWAYS shown when crisilRating exists
                                  if (fund.crisilRating != null)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('SEBI Riskometer',
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  color: context.palette.textTertiary,
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: 0.5)),
                                          const SizedBox(height: 4),
                                          _RiskometerBar(
                                            level: _riskLevel(fund.crisilRating!),
                                            label: _riskLabel(fund.crisilRating!),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // ── Fund Manager chips ────────────────────────
                      if (fund.fundManagers != null &&
                          fund.fundManagers!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.person_outline,
                                size: 14, color: context.palette.textTertiary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: fund.fundManagers!.map((name) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: context.palette.bgSurface,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(name,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: context.palette.textSecondary)),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            const Divider(height: 1),

            // ── Your holding (if held) ─────────────────────────────────────
            if (holding != null) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Your Holding',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    KpiCard(
                        label: 'Current Value',
                        value: holding.currentValue.toINRCompact()),
                    KpiCard(
                        label: 'Invested',
                        value: holding.totalInvested.toINRCompact()),
                    KpiCard(
                      label: 'Gain / Loss',
                      value:
                          '${holding.gain >= 0 ? '+' : ''}${holding.gain.toINRCompact()} (${holding.gainPct.toReturnLabel()})',
                      valueColor:
                          holding.gain >= 0 ? AppColors.gain : AppColors.loss,
                    ),
                    KpiCard(
                      label: 'XIRR',
                      value: holding.xirr != null
                          ? holding.xirr!.toReturnLabel()
                          : '—',
                      valueColor: holding.xirr != null
                          ? (holding.xirr! >= 0 ? AppColors.gain : AppColors.loss)
                          : null,
                    ),
                    KpiCard(
                      label: 'CAGR',
                      value: holding.cagr != null
                          ? holding.cagr!.toReturnLabel()
                          : '—',
                      valueColor: holding.cagr != null
                          ? (holding.cagr! >= 0 ? AppColors.gain : AppColors.loss)
                          : null,
                    ),
                    KpiCard(
                        label: 'Units',
                        value: holding.totalUnits.toUnits()),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
            ],

            // ── Alerts ────────────────────────────────────────────────────
            _FundAlertSection(
              amfiCode: amfiCode,
              fundName: fundAsync.valueOrNull?.fundName ?? '',
            ),

            // ── Portfolio Fit ─────────────────────────────────────────────
            if (fundAsync.valueOrNull?.fundName != null)
              PortfolioFitSection(
                amfiCode: amfiCode,
                fundName: fundAsync.valueOrNull!.fundName,
                memberId: _selectedMemberId,
              ),

            const Divider(height: 1),

            // ── Analytics ─────────────────────────────────────────────────
            analyticsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Analytics unavailable: $e',
                    style: TextStyle(color: context.palette.textTertiary)),
              ),
              data: (analytics) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── Risk & Return metrics ────────────────────────────
                    SectionHeader(title: 'Risk & Return Analytics'),
                    if (analytics.benchmarkName != null &&
                        analytics.benchmarkName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          'Benchmark: ${analytics.benchmarkName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.palette.textTertiary,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          KpiCard(
                            label: 'CAGR',
                            value: _fmtPct(analytics.cagr),
                            tooltip:
                                'Compound annual growth rate (annualised return).',
                            valueColor: _gainLossColor(analytics.cagr),
                          ),
                          KpiCard(
                            label: 'Mean',
                            value: _fmtPct(analytics.meanAnnualised),
                            tooltip:
                                'Arithmetic mean of daily returns × 252 trading days.',
                          ),
                          KpiCard(
                            label: 'Excess vs Benchmark',
                            value: _fmtPct(analytics.excessReturn),
                            tooltip: analytics.benchmarkPoints.isNotEmpty
                                ? 'Annualised fund return − benchmark return (daily series).'
                                : 'Fund − benchmark from AMFI 5y/3y/1y window (daily benchmark NAV not yet available).',
                            valueColor: _gainLossColor(analytics.excessReturn),
                          ),
                          KpiCard(
                            label: 'Sharpe Ratio',
                            value: _fmtNum(analytics.sharpe),
                            tooltip:
                                'Risk-adjusted return vs risk-free rate (6.5%). >1 is good, >2 great.',
                            valueColor: analytics.sharpe != null &&
                                    analytics.sharpe! > 1
                                ? AppColors.gain
                                : null,
                          ),
                          KpiCard(
                            label: 'Sortino Ratio',
                            value: _fmtNum(analytics.sortino),
                            tooltip:
                                'Like Sharpe but only penalises downside volatility.',
                            valueColor: analytics.sortino != null &&
                                    analytics.sortino! > 1
                                ? AppColors.gain
                                : null,
                          ),
                          KpiCard(
                            label: 'Std Deviation',
                            value: _fmtPct(analytics.stdDev),
                            tooltip:
                                'Annualised volatility — higher means more day-to-day swings.',
                          ),
                          KpiCard(
                            label: 'Max Drawdown',
                            value: _fmtPct(analytics.maxDrawdown),
                            tooltip:
                                'Largest peak-to-trough NAV decline since inception.',
                            valueColor: analytics.maxDrawdown != null
                                ? AppColors.loss
                                : null,
                          ),
                          KpiCard(
                            label: 'Alpha',
                            value: _fmtPct(analytics.alpha),
                            tooltip: analytics.alpha != null
                                ? 'Excess return over benchmark after adjusting for beta.'
                                : 'Needs daily benchmark NAV — will populate once index_nav_history is seeded.',
                            valueColor: _gainLossColor(analytics.alpha),
                          ),
                          KpiCard(
                            label: 'Beta',
                            value: _fmtNum(analytics.beta),
                            tooltip: analytics.beta != null
                                ? 'Sensitivity to benchmark moves. 1 = moves with index, <1 = less volatile, >1 = more.'
                                : 'Needs daily benchmark NAV — will populate once index_nav_history is seeded.',
                          ),
                          KpiCard(
                            label: 'Tracking Error',
                            value: _fmtPct(analytics.trackingError),
                            tooltip: analytics.trackingError != null
                                ? 'Annualised stdev of (fund − benchmark) daily returns.'
                                : 'Needs daily benchmark NAV — will populate once index_nav_history is seeded.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── NAV chart ─────────────────────────────────────────
                    if (analytics.navPoints.length > 2) ...[
                      SectionHeader(title: 'NAV History'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _NavChart(navPoints: analytics.navPoints),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Rolling returns chart ─────────────────────────────
                    if (analytics.rollingReturns.isNotEmpty) ...[
                      SectionHeader(title: 'Rolling Returns'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _RollingChart(points: analytics.rollingReturns),
                      ),
                      const SizedBox(height: 24),
                    ],
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

// ── Fund alert section ────────────────────────────────────────────────────

class _FundAlertSection extends ConsumerWidget {
  const _FundAlertSection({required this.amfiCode, required this.fundName});
  final int amfiCode;
  final String fundName;

  IconData _iconForRuleType(String ruleType) {
    switch (ruleType) {
      case 'stop_loss':
        return Icons.trending_down;
      case 'gain_harvest':
        return Icons.trending_up;
      case 'price_target':
        return Icons.flag_outlined;
      case 'allocation_drift':
        return Icons.pie_chart_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  void _navigateToAdd(BuildContext context, {WatchlistRuleModel? editRule}) {
    context.push(
      '/wealth-planner/watchlist/add',
      extra: {
        'amfiCode': amfiCode,
        'fundName': fundName,
        if (editRule != null) 'editRule': editRule,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(fundWatchlistRulesProvider(amfiCode));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Alerts',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.palette.textPrimary,
            ),
          ),
        ),
        rulesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Could not load alerts: $e',
              style: TextStyle(
                fontSize: 12,
                color: context.palette.textTertiary,
              ),
            ),
          ),
          data: (rules) {
            if (rules.isEmpty) {
              return Column(
                children: [
                  ListTile(
                    dense: true,
                    title: const Text('Stop-Loss'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Not set',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.palette.textTertiary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _navigateToAdd(context),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: const Text('Gain Target'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Not set',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.palette.textTertiary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _navigateToAdd(context),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                ...rules.map(
                  (rule) => ListTile(
                    leading: Icon(
                      _iconForRuleType(rule.ruleType),
                      color: context.palette.textSecondary,
                    ),
                    title: Text(rule.ruleTypeLabel),
                    subtitle: Text(
                      rule.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textTertiary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              _navigateToAdd(context, editRule: rule),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.loss,
                          ),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Alert'),
                                content: Text(
                                  'Delete "${rule.ruleTypeLabel}" alert for this fund?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text(
                                      'Delete',
                                      style:
                                          TextStyle(color: AppColors.loss),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              ref
                                  .read(watchlistNotifierProvider.notifier)
                                  .deleteRule(rule.id, amfiCode: amfiCode);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToAdd(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Alert'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.palette.textSecondary,
                      side: BorderSide(color: context.palette.bgDivider),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── CRISIL risk/rating helpers ────────────────────────────────────────────

/// Maps CRISIL risk description to a 1-5 level
int _riskLevel(String crisilRating) {
  final r = crisilRating.toLowerCase();
  if (r.contains('very high')) return 5;
  if (r.contains('moderately high')) return 4;
  if (r.contains('high') && !r.contains('moderate')) return 4;
  if (r.contains('low to moderate')) return 2;
  if (r.contains('moderate')) return 3;
  if (r.contains('low')) return 1;
  return 3; // fallback
}

/// Short label for risk display
String _riskLabel(String crisilRating) {
  final r = crisilRating.toLowerCase();
  if (r.contains('very high')) return 'Very High';
  if (r.contains('moderately high')) return 'Mod. High';
  if (r.contains('high') && !r.contains('moderate')) return 'High';
  if (r.contains('low to moderate')) return 'Low-Mod';
  if (r.contains('moderate')) return 'Moderate';
  if (r.contains('low')) return 'Low';
  return crisilRating;
}

/// Color for risk level badge
Color _riskColor(String crisilRating) {
  switch (_riskLevel(crisilRating)) {
    case 1: return const Color(0xFF22C55E); // green
    case 2: return const Color(0xFF84CC16); // lime
    case 3: return const Color(0xFFF59E0B); // amber
    case 4: return const Color(0xFFF97316); // orange
    case 5: return const Color(0xFFEF4444); // red
    default: return const Color(0xFFF59E0B);
  }
}

/// Color for fund star rating (1-5)
Color _ratingColor(int rating) {
  if (rating >= 4) return const Color(0xFF22C55E); // green — excellent
  if (rating >= 3) return const Color(0xFFF59E0B); // amber — average
  return const Color(0xFFEF4444); // red — below average
}

// ── SEBI Riskometer bar widget ────────────────────────────────────────────

class _RiskometerBar extends StatelessWidget {
  const _RiskometerBar({required this.level, required this.label});
  final int level;   // 1-5
  final String label;

  static const _segmentColors = [
    Color(0xFF22C55E), // 1 — Low (green)
    Color(0xFF84CC16), // 2 — Low-Moderate (lime)
    Color(0xFFF59E0B), // 3 — Moderate (amber)
    Color(0xFFF97316), // 4 — High (orange)
    Color(0xFFEF4444), // 5 — Very High (red)
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segmented bar
        Row(
          children: List.generate(5, (i) {
            final isActive = i < level;
            final color = _segmentColors[i];
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: i < 4 ? 2 : 0),
                decoration: BoxDecoration(
                  color: isActive ? color : color.withOpacity(0.15),
                  borderRadius: BorderRadius.horizontal(
                    left: i == 0 ? const Radius.circular(3) : Radius.zero,
                    right: i == 4 ? const Radius.circular(3) : Radius.zero,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        // Pointer + label
        Row(
          children: [
            Icon(Icons.arrow_drop_up_rounded,
                size: 14, color: _segmentColors[(level - 1).clamp(0, 4)]),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _segmentColors[(level - 1).clamp(0, 4)])),
          ],
        ),
      ],
    );
  }
}

class _NavBlock extends StatelessWidget {
  const _NavBlock({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

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
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color ?? context.palette.textPrimary)),
      ],
    );
  }
}

// ── NAV line chart ─────────────────────────────────────────────────────────
class _NavChart extends StatelessWidget {
  const _NavChart({required this.navPoints});
  final List<NavPoint> navPoints;

  @override
  Widget build(BuildContext context) {
    // Downsample to max 500 points for performance
    final pts = _downsample(navPoints, 500);
    final minNav = pts.map((p) => p.nav).reduce((a, b) => a < b ? a : b);
    final maxNav = pts.map((p) => p.nav).reduce((a, b) => a > b ? a : b);
    final latestNav = pts.last.nav;
    final firstNav = pts.first.nav;
    final isGain = latestNav >= firstNav;

    return Container(
      height: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.bgDivider),
      ),
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
                interval: pts.length / 4,
                getTitlesWidget: (x, _) {
                  final i = x.toInt().clamp(0, pts.length - 1);
                  return Text(
                    DateFormat('yy').format(pts[i].date),
                    style: TextStyle(
                        fontSize: 9, color: context.palette.textTertiary),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final i = spot.x.toInt().clamp(0, pts.length - 1);
                  return LineTooltipItem(
                    '${DateFormat('dd MMM yy').format(pts[i].date)}\n₹${pts[i].nav.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white, fontSize: 11),
                  );
                }).toList();
              },
            ),
          ),
          minY: minNav * 0.95,
          maxY: maxNav * 1.05,
          lineBarsData: [
            LineChartBarData(
              spots: pts.asMap().entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.nav))
                  .toList(),
              isCurved: true,
              curveSmoothness: 0.2,
              color: isGain ? AppColors.gain : AppColors.loss,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: (isGain ? AppColors.gain : AppColors.loss)
                    .withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<NavPoint> _downsample(List<NavPoint> pts, int max) {
    if (pts.length <= max) return pts;
    final step = pts.length / max;
    return [
      for (int i = 0; i < max; i++) pts[(i * step).floor()],
    ];
  }
}

// ── Rolling returns chart ──────────────────────────────────────────────────
class _RollingChart extends StatefulWidget {
  const _RollingChart({required this.points});
  final List<RollingReturnPoint> points;

  @override
  State<_RollingChart> createState() => _RollingChartState();
}

class _RollingChartState extends State<_RollingChart> {
  int _windowYears = 3;

  @override
  Widget build(BuildContext context) {
    final pts = widget.points
        .where((p) => _windowYears == 1
            ? p.rolling1y != null
            : _windowYears == 3
                ? p.rolling3y != null
                : p.rolling5y != null)
        .toList();

    final vals = pts.map((p) {
      final v = _windowYears == 1
          ? p.rolling1y!
          : _windowYears == 3
              ? p.rolling3y!
              : p.rolling5y!;
      return v;
    }).toList();

    if (vals.isEmpty) {
      return Text('Insufficient data for rolling returns',
          style: TextStyle(color: context.palette.textTertiary, fontSize: 12));
    }

    final minV = vals.reduce((a, b) => a < b ? a : b);
    final maxV = vals.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.bgDivider),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [1, 3, 5].map((y) {
                return GestureDetector(
                  onTap: () => setState(() => _windowYears = y),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _windowYears == y
                          ? AppColors.primary
                          : context.palette.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${y}Y',
                        style: TextStyle(
                            fontSize: 11,
                            color: _windowYears == y
                                ? Colors.white
                                : context.palette.textSecondary)),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData:
                      FlTitlesData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final i = s.x.toInt().clamp(0, pts.length - 1);
                        return LineTooltipItem(
                          '${DateFormat('MMM yy').format(pts[i].date)}\n${(s.y).toStringAsFixed(1)}%',
                          const TextStyle(
                              color: Colors.white, fontSize: 10),
                        );
                      }).toList(),
                    ),
                  ),
                  minY: (minV - 2).floorToDouble(),
                  maxY: (maxV + 2).ceilToDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: vals
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loads fund NAV history + benchmark NAV history and renders the comparison chart.
class _BenchmarkSection extends ConsumerWidget {
  const _BenchmarkSection({required this.amfiCode, required this.benchmark});
  final int amfiCode;
  final String benchmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundNavAsync = ref.watch(navHistoryProvider(amfiCode));
    // IMPORTANT: round to midnight UTC of (today − 365 days). If we pass a
    // raw `DateTime.now().subtract(...)` here, every rebuild produces a new
    // DateTime instant, which Riverpod treats as a brand-new family key →
    // the future is re-created every frame and the spinner never resolves.
    final today = DateTime.now().toUtc();
    final fromDate = DateTime.utc(today.year, today.month, today.day)
        .subtract(const Duration(days: 365));
    final indexAsync = ref.watch(indexNavHistoryProvider(
      indexName: benchmark,
      fromDate: fromDate,
    ));

    return fundNavAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Could not load fund NAV: $e',
                style: TextStyle(fontSize: 12, color: context.palette.textTertiary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.invalidate(navHistoryProvider(amfiCode));
                ref.invalidate(fundAnalyticsProvider(amfiCode));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (fundRows) {
        return indexAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Could not load benchmark: $e',
                style: TextStyle(fontSize: 12, color: context.palette.textTertiary)),
          ),
          data: (indexPoints) {
            final fundPoints = fundRows
                .where((r) => r['nav_date'] != null && r['nav'] != null)
                .map((r) => MapEntry(
                      DateTime.parse(r['nav_date'] as String),
                      (r['nav'] as num).toDouble(),
                    ))
                .where((e) => e.key.isAfter(fromDate))
                .toList();
            if (fundPoints.isEmpty) {
              // navHistoryProvider has fully resolved (loading guard above
              // is past), and we still have nothing in the trailing-1y
              // window. Either the fund is brand-new (< 1y old) or upstream
              // mfapi has no data for it.
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fundRows.isEmpty
                          ? 'No NAV history available for this fund yet.'
                          : 'Less than 1 year of NAV history — chart hidden.',
                      style: TextStyle(
                          fontSize: 12, color: context.palette.textTertiary),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(navHistoryProvider(amfiCode));
                        ref.invalidate(fundAnalyticsProvider(amfiCode));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (indexPoints.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'No daily benchmark series yet for "$benchmark".',
                  style: TextStyle(fontSize: 12, color: context.palette.textTertiary),
                ),
              );
            }
            return BenchmarkComparisonChart(
              fundNavPoints: fundPoints,
              indexNavPoints: indexPoints,
              benchmarkLabel: benchmark,
            );
          },
        );
      },
    );
  }
}

// ── Formatting helpers for KPI cards ────────────────────────────────────────

String _fmtPct(double? v) {
  if (v == null || v.isNaN || v.isInfinite) return '—';
  return '${(v * 100).toStringAsFixed(2)}%';
}

String _fmtNum(double? v) {
  if (v == null || v.isNaN || v.isInfinite) return '—';
  return v.toStringAsFixed(2);
}

Color? _gainLossColor(double? v) {
  if (v == null || v.isNaN) return null;
  if (v > 0) return AppColors.gain;
  if (v < 0) return AppColors.loss;
  return null;
}

/// Returns a human-friendly inception line for the fund header.
/// Examples:
///   "Launched Mar 2018 • 8 yrs old"
///   "Launched Sep 2023 • 2 yrs young — 3Y/5Y returns not yet available"
/// Returns null when launch_date is missing or unparsable.
String? _inceptionLine(String? launchDate) {
  if (launchDate == null || launchDate.isEmpty) return null;
  DateTime? d;
  try {
    d = DateTime.parse(launchDate);
  } catch (_) {
    return null;
  }
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  final mon = months[d.month - 1];
  final now = DateTime.now();
  final years = (now.difference(d).inDays / 365.25);
  final yrsInt = years.floor();
  final base = 'Launched $mon ${d.year}';
  if (yrsInt < 1) {
    return '$base • new fund — long-term returns not yet available';
  }
  if (yrsInt < 3) {
    return '$base • $yrsInt yrs young — 3Y/5Y returns not yet available';
  }
  if (yrsInt < 5) {
    return '$base • $yrsInt yrs old — 5Y returns not yet available';
  }
  return '$base • $yrsInt yrs old';
}
