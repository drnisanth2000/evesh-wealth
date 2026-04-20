import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/selected_member_provider.dart';
import '../../providers/wealth_planner_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/wealth_planner/allocation_comparison_chart.dart';
import '../../widgets/wealth_planner/drift_alert_card.dart';
import '../../widgets/wealth_planner/global_member_header.dart';
import '../../widgets/wealth_planner/health_score_card.dart';
import '../../widgets/wealth_planner/smart_nudge_card.dart';
import '../../providers/retirement_provider.dart';
import '../../widgets/wealth_planner/retirement_readiness_card.dart';

class WealthPlannerDashboardScreen extends ConsumerWidget {
  const WealthPlannerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMemberId = ref.watch(selectedMemberProvider);
    final healthAsync = ref.watch(allocationHealthProvider(selectedMemberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wealth Planner (Legacy)'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allocationHealthProvider(selectedMemberId));
          ref.invalidate(portfolioSummaryProvider(selectedMemberId));
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Material(
                color: Colors.amber.withValues(alpha: 0.15),
                child: InkWell(
                  onTap: () => context.go(Routes.wealthPlanner),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.history, size: 18, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Legacy view — moved to the new Wealth Planner. Tap to switch.',
                            style: TextStyle(
                                fontSize: 12,
                                color: context.palette.textSecondary),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ── Member selector ──────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: GlobalMemberHeader(),
            ),

            // ── Main content ─────────────────────────────────────────────────
            healthAsync.when(
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
                        'Error loading wealth planner data',
                        style: TextStyle(color: context.palette.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(
                            allocationHealthProvider(selectedMemberId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (health) => SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),

                  // ── Health score ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: HealthScoreCard(
                      healthScore: health.healthScore,
                      healthLabel: health.healthLabel,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Portfolio value summary ───────────────────────────────
                  Consumer(builder: (context, ref, _) {
                    final portfolioAsync = ref.watch(
                        portfolioSummaryProvider(selectedMemberId));
                    return portfolioAsync.maybeWhen(
                      data: (portfolio) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _PortfolioSummaryCard(
                          netWorth: portfolio.currentValue,
                          xirr: portfolio.xirr,
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    );
                  }),

                  const SizedBox(height: 16),

                  // ── Allocation comparison chart ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AllocationComparisonChart(healthResult: health),
                  ),

                  const SizedBox(height: 16),

                  // ── Retirement readiness ─────────────────────────────────
                  Consumer(builder: (context, ref, _) {
                    final retirementAsync = ref.watch(
                        retirementReadinessProvider(selectedMemberId));
                    return retirementAsync.maybeWhen(
                      data: (readiness) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: RetirementReadinessCard(
                          readiness: readiness,
                          onRetirementCheck: () =>
                              context.go(Routes.wealthPlannerRetirement),
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    );
                  }),

                  const SizedBox(height: 16),

                  // ── Action Center ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ActionCenterLinkCard(
                      onTap: () => context.go(Routes.wealthPlannerActions),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Portfolio projections ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ProjectionsLinkCard(
                      onTap: () => context.go(Routes.wealthPlannerProjections),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Drift alerts ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DriftAlertCard(driftAlerts: health.driftAlerts),
                  ),

                  const SizedBox(height: 16),

                  // ── Smart nudges ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SmartNudgeCard(
                      nudges: health.nudges,
                      onPlanNow: () => context.go(Routes.suggestions),
                      onFixPortfolio: () => context.push(Routes.rebalance),
                      onRetirementCheck: () =>
                          context.go(Routes.wealthPlannerRetirement),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Smart Screener link ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ScreenerLinkCard(
                      onTap: () => context.go(Routes.marketIntel),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Watchlist ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _WatchlistLinkCard(
                      onTap: () => context.go(Routes.wealthPlannerWatchlist),
                    ),
                  ),

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

// ── Portfolio summary card ────────────────────────────────────────────────────

class _PortfolioSummaryCard extends StatelessWidget {
  const _PortfolioSummaryCard({
    required this.netWorth,
    required this.xirr,
  });

  final double netWorth;
  final double? xirr;

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
        child: Row(
          children: [
            Expanded(
              child: _SummaryKpi(
                label: 'Net Worth',
                value: netWorth.toINR(compact: true),
                valueColor: context.palette.textPrimary,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: context.palette.bgDivider,
            ),
            Expanded(
              child: _SummaryKpi(
                label: 'XIRR',
                value: xirr != null && !xirr!.isNaN
                    ? xirr!.toPercent()
                    : '—',
                valueColor: xirr != null && xirr! > 0
                    ? AppColors.gain
                    : context.palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryKpi extends StatelessWidget {
  const _SummaryKpi({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.palette.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Screener link card ───────────────────────────────────────────────────────

class _ProjectionsLinkCard extends StatelessWidget {
  const _ProjectionsLinkCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.bgDivider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Portfolio Projections',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.palette.textPrimary)),
                    SizedBox(height: 2),
                    Text('Scenarios, stress tests & behavior impact analysis',
                      style: TextStyle(fontSize: 11, color: context.palette.textTertiary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.palette.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCenterLinkCard extends StatelessWidget {
  const _ActionCenterLinkCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.bgDivider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.loss.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.playlist_add_check, color: AppColors.loss, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Action Center',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.palette.textPrimary)),
                    SizedBox(height: 2),
                    Text('Rebalance moves, action items & execution links',
                      style: TextStyle(fontSize: 11, color: context.palette.textTertiary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.palette.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchlistLinkCard extends StatelessWidget {
  const _WatchlistLinkCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.bgDivider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.visibility_outlined,
                    color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Watchlist',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: context.palette.textPrimary)),
                    SizedBox(height: 2),
                    Text(
                        'Stop-loss, gain harvest & allocation drift alerts',
                        style: TextStyle(
                            fontSize: 11, color: context.palette.textTertiary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: context.palette.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenerLinkCard extends StatelessWidget {
  const _ScreenerLinkCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.bgDivider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.search, color: AppColors.info, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Screener',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: context.palette.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Screen funds, compare side-by-side, and view post-tax returns',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.palette.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
