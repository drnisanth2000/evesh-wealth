import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/models/family_model.dart';
import '../../providers/family_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/reconciliation_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/charts/allocation_pie_chart.dart';
import '../../widgets/charts/member_bar_chart.dart';
import '../../widgets/common/kpi_card.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/member_selector.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _selectedMemberId; // null = family view

  @override
  Widget build(BuildContext context) {
    final portfolioAsync = ref.watch(portfolioSummaryProvider(_selectedMemberId));

    return Scaffold(
      appBar: AppBar(
        title: Consumer(builder: (context, ref, _) {
          final selfAsync = ref.watch(selfMemberProvider);
          return selfAsync.maybeWhen(
            data: (self) => Text(self?.displayName ?? 'eVesh'),
            orElse: () => const Text('eVesh'),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(Routes.alerts),
          ),
          Consumer(builder: (context, ref, _) {
            final selfAsync = ref.watch(selfMemberProvider);
            return IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                final self = selfAsync.valueOrNull;
                if (self != null) {
                  _showProfileCard(context, self);
                } else {
                  context.push(Routes.profile);
                }
              },
            );
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(portfolioSummaryProvider),
        child: CustomScrollView(
          slivers: [
            // ── Member selector ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: MemberSelector(
                  selectedMemberId: _selectedMemberId,
                  onSelected: (memberId) => setState(() => _selectedMemberId = memberId),
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────────
            portfolioAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: context.palette.loss, size: 48),
                      const SizedBox(height: 12),
                      Text('Error loading portfolio', style: TextStyle(color: context.palette.textSecondary)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(portfolioSummaryProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (portfolio) => SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),

                  // ── Hero KPI row ────────────────────────────────────────────
                  _HeroKPISection(
                    currentValue: portfolio.currentValue,
                    invested: portfolio.totalInvested,
                    gain: portfolio.totalGain,
                    gainPct: portfolio.gainPct,
                    todayGain: portfolio.todayGain,
                    todayGainPct: portfolio.todayGainPct,
                  ),

                  // ── Reconciliation warning ─────────────────────────────────
                  Consumer(builder: (context, ref, _) {
                    final reconAsync = ref.watch(reconciliationProvider);
                    return reconAsync.maybeWhen(
                      data: (recon) {
                        if (recon.allMatch || recon.totalChecked == 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.compare_arrows, size: 18, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${recon.mismatchCount} fund(s) differ from CAMS registrar data. Re-upload CAS to reconcile.',
                                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    );
                  }),

                  const SizedBox(height: 16),

                  // ── XIRR / CAGR row ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
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
                            tooltip: 'Extended Internal Rate of Return — true annualised return accounting for timing',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KpiCard(
                            label: 'CAGR',
                            value: portfolio.cagr != null && !portfolio.cagr!.isNaN
                                ? portfolio.cagr!.toPercent()
                                : '—',
                            valueColor: portfolio.cagr != null && portfolio.cagr! > 0
                                ? context.palette.gain
                                : context.palette.textSecondary,
                            tooltip: 'Compound Annual Growth Rate',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Wealth Planner Quick Access ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.go(Routes.wealthPlanner),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.auto_fix_high,
                                    color: Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Wealth Planner',
                                        style: Theme.of(context).textTheme.titleMedium),
                                    Text('Check portfolio health & plan investments',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: context.palette.textSecondary)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Allocation pie chart ──────────────────────────────────────
                  if (portfolio.allocationPct.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Asset Allocation',
                      action: 'Rebalance',
                      onAction: () => context.push(Routes.wealthPlannerRebalance),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AllocationPieChart(
                        allocationPct: portfolio.allocationPct,
                        totalValue: portfolio.currentValue,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Member breakdown (family view only) ──────────────────────
                  if (_selectedMemberId == null && portfolio.memberBreakdown.length > 1) ...[
                    SectionHeader(
                      title: 'Member Breakdown',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: MemberBarChart(members: portfolio.memberBreakdown),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Quick actions ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _QuickActions(),
                  ),

                  const SizedBox(height: 24),

                  // ── Top holdings preview ──────────────────────────────────────
                  if (portfolio.fundHoldings.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Top Holdings',
                      action: 'View all',
                      onAction: () => context.push(Routes.fundMaster),
                    ),
                    ...portfolio.fundHoldings.take(5).map((fund) => _FundHoldingTile(
                      fundName: fund.fundName,
                      currentValue: fund.currentValue,
                      gain: fund.gain,
                      gainPct: fund.gainPct,
                      cagr: fund.cagr,
                      assetClass: fund.assetClassLabel ?? fund.category ?? '—',
                      onTap: () => context.push('/portfolio/${fund.amfiCode}'),
                    )),
                    const SizedBox(height: 8),
                  ],

                  // ── As of date ────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'As of ${(portfolio.asOfDate ?? DateTime.now()).displayDate}',
                      style: TextStyle(color: context.palette.textTertiary, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.addTransaction),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Transaction', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showProfileCard(BuildContext context, FamilyMemberModel self) {
    final initial = self.displayName.isNotEmpty ? self.displayName[0].toUpperCase() : '?';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary,
                child: Text(initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
              Text(self.displayName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('CEO',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                  if (self.pan != null) ...[
                    const SizedBox(width: 8),
                    Text(self.pan!,
                        style: TextStyle(
                            fontSize: 12, color: context.palette.textSecondary)),
                  ],
                ],
              ),
              if (self.email != null) ...[
                const SizedBox(height: 8),
                Text(self.email!,
                    style: TextStyle(
                        fontSize: 12, color: context.palette.textSecondary)),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(Routes.familySetup);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Profile'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(Routes.settings);
                    },
                    icon: const Icon(Icons.settings_outlined, size: 16),
                    label: const Text('Settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero KPI Section ──────────────────────────────────────────────────────────
class _HeroKPISection extends StatelessWidget {
  const _HeroKPISection({
    required this.currentValue,
    required this.invested,
    required this.gain,
    required this.gainPct,
    required this.todayGain,
    required this.todayGainPct,
  });

  final double currentValue;
  final double invested;
  final double gain;
  final double gainPct;
  final double todayGain;
  final double todayGainPct;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.palette.bgCard, context.palette.bgCardElevated],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.bgDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Portfolio Value',
              style: TextStyle(color: context.palette.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            currentValue.toINR(compact: true),
            style: TextStyle(
              color: context.palette.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _KpiChip(
                label: 'Invested',
                value: invested.toINRCompact(),
                color: context.palette.textSecondary,
              ),
              const SizedBox(width: 12),
              _KpiChip(
                label: 'Total Gain',
                value: '${gain >= 0 ? '+' : ''}${gain.toINRCompact()}  (${gainPct.toReturnLabel()})',
                color: gain >= 0 ? context.palette.gain : context.palette.loss,
                emphasized: true,
              ),
            ],
          ),
          if (todayGain != 0) ...[
            const SizedBox(height: 8),
            _KpiChip(
              label: "Today's change",
              value: '${todayGain >= 0 ? '+' : ''}${todayGain.toINRCompact()} (${todayGainPct.toReturnLabel()})',
              color: todayGain >= 0 ? context.palette.gain : context.palette.loss,
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.label,
    required this.value,
    required this.color,
    this.emphasized = false,
  });
  final String label;
  final String value;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: context.palette.textTertiary,
                fontSize: emphasized ? 12 : 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: emphasized ? 18 : 13,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600)),
      ],
    );
  }
}

// ── Quick Action buttons ──────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _QuickActionButton(icon: Icons.calculate_outlined, label: 'Tax', route: Routes.tax),
        _QuickActionButton(icon: Icons.balance_outlined, label: 'Rebalance', route: Routes.wealthPlannerRebalance),
        _QuickActionButton(icon: Icons.flag_outlined, label: 'Goals', route: Routes.wealthPlannerGoals),
        _QuickActionButton(icon: Icons.search_outlined, label: 'Screener', route: Routes.marketIntel),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.route,
  });
  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: context.palette.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.palette.bgDivider),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, color: context.palette.textSecondary)),
        ],
      ),
    );
  }
}

// ── Fund Holding Tile ────────────────────────────────────────────────────────
class _FundHoldingTile extends StatelessWidget {
  const _FundHoldingTile({
    required this.fundName,
    required this.currentValue,
    required this.gain,
    required this.gainPct,
    this.cagr,
    required this.assetClass,
    required this.onTap,
  });

  final String fundName;
  final double currentValue;
  final double gain;
  final double gainPct;
  final double? cagr;
  final String assetClass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        fundName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        assetClass,
        style: TextStyle(fontSize: 11, color: context.palette.textSecondary),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            currentValue.toINRCompact(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Text(
            gainPct.toReturnLabel(),
            style: TextStyle(
              fontSize: 12,
              color: gain >= 0 ? context.palette.gain : context.palette.loss,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
