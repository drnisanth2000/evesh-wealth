import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../router/route_names.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/action_models.dart';
import '../../../domain/models/simulation_models.dart';
import '../../providers/action_center_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/selected_member_provider.dart';
import '../../providers/simulation_provider.dart';
import '../../providers/wealth_planner_provider.dart';
import '../../widgets/action_center/action_item_card.dart';
import '../../widgets/action_center/asset_allocation_sliders.dart';
import '../../widgets/action_center/education_card.dart';
import '../../widgets/action_center/fund_slider_row.dart';
import '../../widgets/action_center/rebalance_flow.dart';
import '../../widgets/action_center/simulation_summary.dart';
import '../../widgets/action_center/vertical_buckets.dart';
import '../../widgets/wealth_planner/global_member_header.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Action Center Screen — Plan / Simulate tabs with member selector
// ═══════════════════════════════════════════════════════════════════════════════

class ActionCenterScreen extends ConsumerStatefulWidget {
  const ActionCenterScreen({super.key});

  @override
  ConsumerState<ActionCenterScreen> createState() => _ActionCenterScreenState();
}

class _ActionCenterScreenState extends ConsumerState<ActionCenterScreen>
    with SingleTickerProviderStateMixin {
  final _completedIds = <String>{};
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleItem(String id) {
    setState(() {
      if (_completedIds.contains(id)) {
        _completedIds.remove(id);
      } else {
        _completedIds.add(id);
      }
    });
  }

  void _invalidateAll(String? memberId) {
    ref.invalidate(actionCenterPlanProvider(memberId));
    ref.invalidate(memberBucketStrategyProvider(memberId));
    ref.invalidate(simulationResultProvider(memberId));
    ref.invalidate(activeFrozenPlanProvider(memberId));
  }

  @override
  Widget build(BuildContext context) {
    final selectedMemberId = ref.watch(selectedMemberProvider);
    final isAllSelected = selectedMemberId == null;
    final membersAsync = ref.watch(familyMembersProvider);

    ref.listen<String?>(selectedMemberProvider, (prev, next) {
      if (next == null && _tabController.index == 1) {
        _tabController.animateTo(0);
      }
      _invalidateAll(next);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Action Center (Legacy)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _invalidateAll(selectedMemberId),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: Colors.amber.withValues(alpha: 0.15),
        child: InkWell(
          onTap: () => context.go(Routes.wealthPlanner),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.history, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Legacy view — Plan + Simulate moved to the new Wealth Planner tabs. Tap to switch.',
                    style: TextStyle(
                        fontSize: 12, color: context.palette.textSecondary),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: context.palette.loss, size: 48),
              const SizedBox(height: 12),
              Text('Error: $e',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: context.palette.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(familyMembersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (_) => Column(
          children: [
            // ── Layer 1: Member selector ──────────────────────────────
            const GlobalMemberHeader(),

            // ── Layer 2: Plan / Simulate tabs ────────────────────────
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: context.palette.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Plan'),
                Tab(text: 'Simulate'),
              ],
            ),

            // ── Layer 3: Tab content ─────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PlanTab(
                    memberId: selectedMemberId,
                    completedIds: _completedIds,
                    onToggle: _toggleItem,
                  ),
                  isAllSelected
                      ? const _DisabledSimulateMessage()
                      : _SimulateTab(memberId: selectedMemberId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Disabled Simulate Message (shown when ALL is selected)
// ═══════════════════════════════════════════════════════════════════════════════

class _DisabledSimulateMessage extends StatelessWidget {
  const _DisabledSimulateMessage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline,
                size: 48,
                color: context.palette.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'Select a member to simulate',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Simulation works on individual portfolios.\nChoose a member from the chips above.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: context.palette.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Plan Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _PlanTab extends ConsumerWidget {
  const _PlanTab({
    required this.memberId,
    required this.completedIds,
    required this.onToggle,
  });

  final String? memberId;
  final Set<String> completedIds;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(actionCenterPlanProvider(memberId));
    final strategyAsync = ref.watch(memberBucketStrategyProvider(memberId));

    return planAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: context.palette.loss, size: 48),
            const SizedBox(height: 12),
            Text('Error: $e',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.palette.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.invalidate(actionCenterPlanProvider(memberId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (plan) => RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(actionCenterPlanProvider(memberId)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Health Snapshot
            _HealthSnapshotBanner(plan: plan),
            const SizedBox(height: 16),

            // 2. Vertical Buckets (convert BucketStatus → BucketComposition)
            VerticalBuckets(
              buckets: plan.bucketSummary
                  .map((bs) => BucketComposition(
                        bucketNumber: bs.bucketNumber,
                        bucketName: bs.bucketName,
                        currentPct: bs.currentPct,
                        idealPct: bs.idealPct,
                        currentValue: bs.currentValue,
                        status: bs.status,
                        bands: const [],
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // 3. Rebalance Flow
            if (plan.fundMoves.isNotEmpty) ...[
              RebalanceFlow(
                moves: plan.fundMoves,
                rationale: plan.rationale,
              ),
              const SizedBox(height: 16),
            ],

            // 4. Action Items
            if (plan.actionItems.isNotEmpty) ...[
              _ActionItemsSection(
                items: plan.actionItems,
                completedIds: completedIds,
                onToggle: onToggle,
              ),
              const SizedBox(height: 16),
            ],

            // 5. Education Card
            strategyAsync.whenData((strategy) {
              return EducationCard(strategy: strategy);
            }).valueOrNull ??
                const SizedBox.shrink(),
            const SizedBox(height: 16),

            // 6. Summary Footer
            if (plan.totalSellAmount > 0 || plan.totalBuyAmount > 0)
              _SummaryFooter(plan: plan),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Simulate Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _SimulateTab extends ConsumerStatefulWidget {
  const _SimulateTab({required this.memberId});

  final String? memberId;

  @override
  ConsumerState<_SimulateTab> createState() => _SimulateTabState();
}

class _SimulateTabState extends ConsumerState<_SimulateTab> {
  bool _initialized = false;
  bool _freezing = false;

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(simulationStateProvider(widget.memberId));
    final resultAsync = ref.watch(simulationResultProvider(widget.memberId));
    final strategyAsync =
        ref.watch(memberBucketStrategyProvider(widget.memberId));
    final portfolioAsync =
        ref.watch(portfolioSummaryProvider(widget.memberId));
    final frozenAsync =
        ref.watch(activeFrozenPlanProvider(widget.memberId));
    final healthAsync =
        ref.watch(allocationHealthProvider(widget.memberId));

    // Init simulation from portfolio on first build
    if (!_initialized) {
      portfolioAsync.whenData((portfolio) {
        if (!_initialized) {
          _initialized = true;
          final currentAmounts = <int, double>{};
          for (final h in portfolio.fundHoldings) {
            currentAmounts[h.amfiCode] = h.currentValue;
          }
          // Use Future.microtask to avoid modifying providers during build
          Future.microtask(() {
            ref
                .read(simulationStateProvider(widget.memberId).notifier)
                .initFromHoldings(currentAmounts);
          });
        }
      });
    }

    // Init target allocations from ideal (runs independently of _initialized)
    if (simState.targetAllocations.isEmpty) {
      healthAsync.whenData((health) {
        if (ref
            .read(simulationStateProvider(widget.memberId))
            .targetAllocations
            .isEmpty) {
          final ideal = health.idealAllocation;
          final targets = <String, double>{
            'coreEquity': ideal.idealForAssetClass('coreEquity'),
            'satelliteEquity': ideal.idealForAssetClass('satelliteEquity'),
            'hybrid': ideal.idealForAssetClass('hybrid'),
            'debt': ideal.idealForAssetClass('debt'),
            'liquid': ideal.idealForAssetClass('liquid'),
            'gold': ideal.idealForAssetClass('gold'),
            'alternate': ideal.idealForAssetClass('alternatives'),
          };
          Future.microtask(() {
            ref
                .read(simulationStateProvider(widget.memberId).notifier)
                .initTargetsFromStrategy(targets);
          });
        }
      });
    }

    return portfolioAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: TextStyle(color: context.palette.textSecondary)),
      ),
      data: (portfolio) {
        final holdings = portfolio.fundHoldings;
        final totalValue = portfolio.currentValue;

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Target Allocation Sliders
                  if (simState.targetAllocations.isNotEmpty)
                    AssetAllocationSliders(
                      targets: simState.targetAllocations,
                      currentAllocation: portfolio.allocationPct,
                      onChanged: (key, pct) => ref
                          .read(simulationStateProvider(widget.memberId).notifier)
                          .setTargetAllocation(key, pct),
                      onReset: () {
                        healthAsync.whenData((health) {
                          final ideal = health.idealAllocation;
                          final targets = <String, double>{
                            'coreEquity':
                                ideal.idealForAssetClass('coreEquity'),
                            'satelliteEquity':
                                ideal.idealForAssetClass('satelliteEquity'),
                            'hybrid': ideal.idealForAssetClass('hybrid'),
                            'debt': ideal.idealForAssetClass('debt'),
                            'liquid': ideal.idealForAssetClass('liquid'),
                            'gold': ideal.idealForAssetClass('gold'),
                            'alternate':
                                ideal.idealForAssetClass('alternatives'),
                          };
                          ref
                              .read(simulationStateProvider(widget.memberId).notifier)
                              .initTargetsFromStrategy(targets);
                        });
                      },
                    ),
                  if (simState.targetAllocations.isNotEmpty)
                    const SizedBox(height: 16),

                  // New Money Input
                  NewMoneyInput(
                    lumpsum: simState.additionalLumpsum,
                    sip: simState.additionalSip,
                    onLumpsumChanged: (v) => ref
                        .read(simulationStateProvider(widget.memberId).notifier)
                        .setLumpsum(v),
                    onSipChanged: (v) => ref
                        .read(simulationStateProvider(widget.memberId).notifier)
                        .setSip(v),
                  ),
                  const SizedBox(height: 16),

                  // Fund Allocations header
                  Text(
                    'Fund Allocations',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Fund slider rows
                  ...holdings.map((h) {
                    final adjustedValue =
                        simState.fundAmounts[h.amfiCode] ?? h.currentValue;
                    // Find matching tax impact from simulation result
                    FundTaxImpact? taxImpact;
                    resultAsync.whenData((result) {
                      if (result != null) {
                        taxImpact = result.taxImpacts
                            .cast<FundTaxImpact?>()
                            .firstWhere(
                              (t) => t?.amfiCode == h.amfiCode,
                              orElse: () => null,
                            );
                      }
                    });

                    return FundSliderRow(
                      amfiCode: h.amfiCode,
                      fundName: h.fundName,
                      assetClassLabel:
                          h.assetClassLabel ?? h.taxCategory ?? 'Alternate',
                      currentValue: h.currentValue,
                      adjustedValue: adjustedValue,
                      totalPortfolioValue: totalValue,
                      onChanged: (v) => ref
                          .read(simulationStateProvider(widget.memberId).notifier)
                          .setFundAmount(h.amfiCode, v),
                      taxImpact: taxImpact,
                    );
                  }),
                  const SizedBox(height: 16),

                  // Vertical Buckets from simulation result
                  resultAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (result) {
                      if (result == null) return const SizedBox.shrink();
                      return VerticalBuckets(buckets: result.bucketFills);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Education Card
                  strategyAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (strategy) => EducationCard(strategy: strategy),
                  ),
                  const SizedBox(height: 16),

                  // Simulation Summary Card
                  resultAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (result) {
                      if (result == null) return const SizedBox.shrink();
                      return SimulationSummaryCard(result: result);
                    },
                  ),

                  // Bottom bar space
                  const SizedBox(height: 80),
                ],
              ),
            ),

            // Sticky bottom bar
            SimulationBottomBar(
              isDirty: simState.isDirty,
              isLoading: _freezing || resultAsync.isLoading,
              onReset: _reset,
              onFreeze: _freeze,
              frozenPlanDate: frozenAsync.whenData((fp) => fp?.createdAt).valueOrNull,
            ),
          ],
        );
      },
    );
  }

  void _reset() {
    final portfolio =
        ref.read(portfolioSummaryProvider(widget.memberId)).valueOrNull;
    if (portfolio == null) return;
    final currentAmounts = <int, double>{};
    for (final h in portfolio.fundHoldings) {
      currentAmounts[h.amfiCode] = h.currentValue;
    }
    ref.read(simulationStateProvider(widget.memberId).notifier).reset(currentAmounts);
  }

  Future<void> _freeze() async {
    final simState = ref.read(simulationStateProvider(widget.memberId));
    final result =
        ref.read(simulationResultProvider(widget.memberId)).valueOrNull;
    final strategy =
        ref.read(memberBucketStrategyProvider(widget.memberId)).valueOrNull;

    if (result == null) return;

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.bgCard,
        title: Text('Freeze Plan?',
            style: TextStyle(color: context.palette.textPrimary)),
        content: Text(
          'This will save your current simulation as an active plan.\n'
          'Projected health: ${result.projectedHealthScore} '
          '(${result.healthDelta >= 0 ? '+' : ''}${result.healthDelta})\n'
          'Net cost: ${result.netRebalanceCost.toINR(compact: true)}',
          style: TextStyle(color: context.palette.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Freeze'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _freezing = true);

    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) throw Exception('Not authenticated');

      // Supersede old active plans
      await client
          .from('frozen_plans')
          .update({'status': 'superseded'})
          .eq('owner_id', uid)
          .eq('status', 'active')
          .maybeEq('member_id', widget.memberId);

      // Build frozen plan
      final plan = FrozenPlan(
        ownerId: uid,
        memberId: widget.memberId,
        fundAllocations: Map.of(simState.fundAmounts),
        additionalLumpsum: simState.additionalLumpsum,
        additionalSip: simState.additionalSip,
        healthScore: result.projectedHealthScore,
        healthDelta: result.healthDelta,
        totalTaxImpact: result.totalTaxCost,
        totalExitLoad: result.totalExitLoad,
        bucketTargets: strategy?.bucketTargets,
        status: 'active',
      );

      await client.from('frozen_plans').insert(plan.toJson());

      // Invalidate frozen plan provider
      ref.invalidate(activeFrozenPlanProvider(widget.memberId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan frozen successfully'),
            backgroundColor: context.palette.gain,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to freeze plan: $e'),
            backgroundColor: context.palette.loss,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _freezing = false);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Health Snapshot Banner
// ═══════════════════════════════════════════════════════════════════════════════

class _HealthSnapshotBanner extends StatelessWidget {
  const _HealthSnapshotBanner({required this.plan});
  final RebalancePlan plan;

  Color get _scoreColor {
    if (plan.healthScore >= 80) return AppColors.gain;
    if (plan.healthScore >= 60) return AppColors.primary;
    if (plan.healthScore >= 40) return AppColors.warning;
    return AppColors.loss;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _scoreColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Score row
            Row(
              children: [
                // Score circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _scoreColor, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      '${plan.healthScore}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _scoreColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.healthLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _scoreColor,
                        ),
                      ),
                      if (plan.topDriftAlert != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber,
                                  size: 12, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  plan.topDriftAlert!,
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.warning),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (plan.retirementGapMonthly != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.elderly,
                                  size: 12, color: AppColors.info),
                              const SizedBox(width: 4),
                              Text(
                                '${plan.retirementGapMonthly!.toINR(compact: true)}/month short for retirement',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.info),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action count chips
            Row(
              children: [
                _ActionCountChip(
                  count: plan.actionItems
                      .where((a) => a.priority == ActionPriority.critical)
                      .length,
                  label: 'Critical',
                  color: context.palette.loss,
                ),
                const SizedBox(width: 8),
                _ActionCountChip(
                  count: plan.actionItems
                      .where((a) => a.priority == ActionPriority.warning)
                      .length,
                  label: 'Attention',
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                _ActionCountChip(
                  count: plan.actionItems
                      .where((a) => a.priority == ActionPriority.info)
                      .length,
                  label: 'Info',
                  color: AppColors.info,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Action Count Chip
// ═══════════════════════════════════════════════════════════════════════════════

class _ActionCountChip extends StatelessWidget {
  const _ActionCountChip(
      {required this.count, required this.label, required this.color});
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count $label',
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Action Items Section — grouped by source
// ═══════════════════════════════════════════════════════════════════════════════

class _ActionItemsSection extends StatelessWidget {
  const _ActionItemsSection({
    required this.items,
    required this.completedIds,
    required this.onToggle,
  });

  final List<ActionItem> items;
  final Set<String> completedIds;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    // Group by source
    final grouped = <ActionSource, List<ActionItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.source, () => []).add(item);
    }

    // Display order
    const sourceOrder = [
      ActionSource.rebalance,
      ActionSource.drift,
      ActionSource.retirement,
      ActionSource.cashOptimization,
      ActionSource.fundReplace,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Action Items',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: context.palette.textPrimary,
          ),
        ),
        ...sourceOrder
            .where((s) => grouped.containsKey(s))
            .expand((source) {
          final sourceItems = grouped[source]!;
          return [
            ActionSourceHeader(source: source, count: sourceItems.length),
            ...sourceItems.map((item) {
              final resolved = item.copyWith(
                isCompleted: completedIds.contains(item.id),
              );
              return ActionItemCard(
                item: resolved,
                onToggle: () => onToggle(item.id),
              );
            }),
          ];
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Summary Footer — Sell / Buy / Net Flow KPIs
// ═══════════════════════════════════════════════════════════════════════════════

class _SummaryFooter extends StatelessWidget {
  const _SummaryFooter({required this.plan});
  final RebalancePlan plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.palette.bgDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryKpi(
              label: 'Total Sell',
              value: plan.totalSellAmount.toINR(compact: true),
              color: context.palette.loss,
            ),
            Container(width: 1, height: 30, color: context.palette.bgDivider),
            _SummaryKpi(
              label: 'Total Buy',
              value: plan.totalBuyAmount.toINR(compact: true),
              color: context.palette.gain,
            ),
            Container(width: 1, height: 30, color: context.palette.bgDivider),
            _SummaryKpi(
              label: 'Net Flow',
              value: plan.netCashFlow.toINR(compact: true),
              color: context.palette.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryKpi extends StatelessWidget {
  const _SummaryKpi(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10, color: context.palette.textTertiary)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Extension — conditional Supabase filter
// ═══════════════════════════════════════════════════════════════════════════════

extension _PostgrestFilterBuilderExt on PostgrestFilterBuilder {
  /// Applies `.eq(column, value)` when value is non-null,
  /// otherwise applies `.isFilter(column, null)`.
  PostgrestFilterBuilder maybeEq(String column, String? value) {
    if (value != null) {
      return eq(column, value);
    }
    return isFilter(column, null);
  }
}
