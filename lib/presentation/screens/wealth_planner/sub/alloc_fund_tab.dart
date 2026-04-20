import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/asset_class_resolver.dart';
import '../../../../core/constants/asset_classes.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../data/models/pending_order_model.dart';
import '../../../../data/models/portfolio_summary_model.dart';
import '../../../../domain/models/simulation_models.dart';
import '../../../providers/asset_class_override_provider.dart';
import '../../../providers/pending_orders_provider.dart';
import '../../../providers/portfolio_provider.dart';
import '../../../providers/selected_member_provider.dart';
import '../../../providers/simulation_provider.dart';
import '../../../providers/wealth_planner_provider.dart';
import '../../../widgets/wealth_planner/add_fund_to_asset_class_sheet.dart';
import '../../../widgets/wealth_planner/asset_class_allocation_slider.dart';
import '../../../widgets/wealth_planner/asset_class_card.dart';
import '../../../widgets/wealth_planner/asset_class_overview_banner.dart';
import '../../../widgets/wealth_planner/fund_sub_card.dart';

/// Fund sub-tab (v3): a scannable editor that surfaces allocation gaps at
/// three grains — the top bird's-eye banner, the per-class pill banner +
/// slider, and collapsible per-fund sub-cards. Writes to the member-scoped
/// [simulationStateProvider] so Rebalance immediately picks up every change.
class AllocFundTab extends ConsumerStatefulWidget {
  const AllocFundTab({super.key});

  @override
  ConsumerState<AllocFundTab> createState() => _AllocFundTabState();
}

class _AllocFundTabState extends ConsumerState<AllocFundTab> {
  bool _initialized = false;
  final ScrollController _scrollController = ScrollController();
  final Map<AssetClass, GlobalKey> _classKeys = {
    for (final c in AssetClass.values) c: GlobalKey(),
  };

  /// Last time the simulation state was persisted — fires after every
  /// slider / text commit (since `SimulationStateNotifier._persist()` runs
  /// on every state change). Drives the "Saved · HH:MM" chip so the user
  /// has explicit feedback that their edit landed in Hive.
  DateTime? _lastSavedAt;

  // Must match wealth_planner_provider.dart's _displayToAssetClassKey values.
  String _keyFor(AssetClass cls) {
    switch (cls) {
      case AssetClass.coreEquity:
        return 'coreEquity';
      case AssetClass.satelliteEquity:
        return 'satelliteEquity';
      case AssetClass.hybrid:
        return 'hybrid';
      case AssetClass.debt:
        return 'debt';
      case AssetClass.liquid:
        return 'liquid';
      case AssetClass.gold:
        return 'gold';
      case AssetClass.alternate:
        return 'alternatives';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToClass(AssetClass cls) {
    final ctx = _classKeys[cls]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final memberId = ref.watch(selectedMemberProvider);

    if (memberId == null) return const _DisabledOverlay();

    // Fire a "Saved just now" stamp every time the persisted sim state
    // mutates. The listen must live inside build so the ref is scoped to
    // this ConsumerState.
    ref.listen<SimulationState>(simulationStateProvider(memberId), (prev, next) {
      if (prev == null) return; // ignore initial hydration
      if (identical(prev, next)) return;
      if (!mounted) return;
      setState(() => _lastSavedAt = DateTime.now());
    });

    final simState = ref.watch(simulationStateProvider(memberId));
    final portfolioAsync = ref.watch(portfolioSummaryProvider(memberId));
    final healthAsync = ref.watch(allocationHealthProvider(memberId));
    final overridesAsync = ref.watch(fundAssetClassOverridesProvider);

    if (!_initialized) {
      portfolioAsync.whenData((portfolio) {
        if (_initialized) return;
        _initialized = true;
        final current = <int, double>{};
        for (final h in portfolio.fundHoldings) {
          current[h.amfiCode] = h.currentValue;
        }
        Future.microtask(() {
          ref
              .read(simulationStateProvider(memberId).notifier)
              .initFromHoldings(current);
        });
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: portfolioAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('$e',
              style: TextStyle(color: context.palette.textSecondary)),
        ),
        data: (portfolio) => healthAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('$e',
                style: TextStyle(color: context.palette.textSecondary)),
          ),
          data: (health) {
            final holdings = portfolio.fundHoldings;
            final totalValue = portfolio.currentValue;
            final overrides = overridesAsync.valueOrNull ?? const {};

            if (holdings.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No fund holdings to simulate.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.palette.textSecondary,
                    ),
                  ),
                ),
              );
            }

            // Group holdings by resolved (override-aware) asset class.
            final grouped = <AssetClass, List<FundHoldingSummary>>{};
            final clsByAmfi = <int, AssetClass>{};
            for (final h in holdings) {
              final cls = overrides[h.amfiCode] ??
                  resolveAssetClass(
                    amfiCategoryId: h.amfiCategoryId,
                    assetClassLabel: h.assetClassLabel,
                    category: h.category,
                  );
              (grouped[cls] ??= []).add(h);
              clsByAmfi[h.amfiCode] = cls;
            }

            // Include funds added via "Add Fund" that aren't yet in the
            // portfolio (no real holding row). They render as virtual
            // sub-cards in their chosen asset class with the "Pending"
            // badge and an Execute CTA. Chosen class is sourced from
            // simState.pendingFundAssetClass — a transaction-free fund has
            // no `asset_class_override` row, so the override provider
            // can't tell us where to put it.
            final existingAmfis = {for (final h in holdings) h.amfiCode};
            for (final amfi in simState.pendingDeployments) {
              if (existingAmfis.contains(amfi)) continue;
              final name = simState.pendingFundNames[amfi] ?? 'Added fund';
              final clsName = simState.pendingFundAssetClass[amfi];
              final cls = clsName == null
                  ? (overrides[amfi] ?? AssetClass.alternate)
                  : _assetClassFromName(clsName) ??
                      (overrides[amfi] ?? AssetClass.alternate);
              final virtual = FundHoldingSummary(
                amfiCode: amfi,
                fundName: name,
                currentValue: 0,
              );
              (grouped[cls] ??= []).add(virtual);
              clsByAmfi[amfi] = cls;
            }

            // Build overview-banner entries for ALL 7 classes, in enum order.
            final overview = <AssetClassOverview>[];
            for (final cls in AssetClass.values) {
              final classHoldings = grouped[cls] ?? const [];
              final classCurrent = classHoldings.fold<double>(
                  0, (s, h) => s + h.currentValue);
              final currentPct = totalValue > 0
                  ? (classCurrent / totalValue) * 100.0
                  : 0.0;
              final targetPct =
                  simState.targetAllocations[_keyFor(cls)] ??
                      health.idealAllocation.idealForAssetClass(_keyFor(cls));
              overview.add(AssetClassOverview(
                assetClass: cls,
                currentPct: currentPct,
                targetPct: targetPct,
              ));
            }

            // Bottom total = sum of CLASS targets across the 7 asset
            // classes. Reflects class-level slider edits (previously the
            // footer only reacted to fund-level edits). Target is 100%.
            final classTargetSum = AssetClass.values.fold<double>(0, (s, cls) {
              final pct = simState.targetAllocations[_keyFor(cls)] ??
                  health.idealAllocation.idealForAssetClass(_keyFor(cls));
              return s + pct;
            });

            // A fund is "modified" when the user has explicitly touched its
            // slider / input — the touchedFundAmounts set is authoritative.
            // Count only touched funds that are currently visible so stale
            // amfis from a prior session (deleted funds) don't inflate.
            final visibleAmfis = {
              for (final h in holdings) h.amfiCode,
              ...simState.pendingDeployments,
            };
            final modifiedCount = simState.touchedFundAmounts
                .where(visibleAmfis.contains)
                .length;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 140, top: 4),
                    children: [
                      AssetClassOverviewBanner(
                        entries: overview,
                        onTapClass: _scrollToClass,
                      ),
                      for (final cls in AssetClass.values)
                        if ((grouped[cls] ?? const []).isNotEmpty)
                          _AssetClassAllocator(
                            key: _classKeys[cls],
                            cls: cls,
                            memberId: memberId,
                            holdings: grouped[cls]!,
                            simAmounts: simState.fundAmounts,
                            touchedFunds: simState.touchedFundAmounts,
                            targetPct: simState
                                    .targetAllocations[_keyFor(cls)] ??
                                health.idealAllocation
                                    .idealForAssetClass(_keyFor(cls)),
                            totalValue: totalValue,
                            clsByAmfi: clsByAmfi,
                            pendingDeployments: simState.pendingDeployments,
                            onClassTargetChanged: (pct) => ref
                                .read(simulationStateProvider(memberId)
                                    .notifier)
                                .setTargetAllocation(_keyFor(cls), pct),
                          ),
                    ],
                  ),
                ),
                if (modifiedCount > 0)
                  _CustomTargetsBanner(
                    count: modifiedCount,
                    onReset: () => ref
                        .read(simulationStateProvider(memberId).notifier)
                        .reset({
                      for (final h in holdings) h.amfiCode: h.currentValue,
                    }),
                  ),
                _BottomActionBar(
                  classTargetSumPct: classTargetSum,
                  lastSavedAt: _lastSavedAt,
                  onAddFund: () => AddFundToAssetClassSheet.show(
                    context: context,
                    memberId: memberId,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One asset-class allocator card. Header reuses [AssetClassCard] with its
/// default pill row suppressed; we inject the Current / Target / Buy|Sell
/// pill banner + class-level slider into the `headerSlot`.
class _AssetClassAllocator extends ConsumerWidget {
  const _AssetClassAllocator({
    super.key,
    required this.cls,
    required this.memberId,
    required this.holdings,
    required this.simAmounts,
    required this.touchedFunds,
    required this.targetPct,
    required this.totalValue,
    required this.clsByAmfi,
    required this.pendingDeployments,
    required this.onClassTargetChanged,
  });

  final AssetClass cls;
  final String memberId;
  final List<FundHoldingSummary> holdings;
  final Map<int, double> simAmounts;
  final Set<int> touchedFunds;
  final double targetPct;
  final double totalValue;
  final Map<int, AssetClass> clsByAmfi;
  final Set<int> pendingDeployments;
  final ValueChanged<double> onClassTargetChanged;

  /// Effective target rupees for a single fund:
  ///   * user has touched this fund → serve their stored value
  ///   * otherwise → pro-rata share of the class target weighted by the
  ///     fund's current value (falls back to equal split when the class
  ///     has zero current value overall).
  ///
  /// This makes the fund breakdown sum to 100% of the class target by
  /// default; dragging any fund's slider flips it into the user-edit lane
  /// and leaves peers on the suggestion.
  double _effectiveTarget({
    required FundHoldingSummary fund,
    required double classCurrent,
    required double classTargetRupees,
    required int holdingsCount,
  }) {
    if (touchedFunds.contains(fund.amfiCode)) {
      return simAmounts[fund.amfiCode] ?? fund.currentValue;
    }
    if (classTargetRupees <= 0) return fund.currentValue;
    if (classCurrent > 0) {
      return (fund.currentValue / classCurrent) * classTargetRupees;
    }
    // Class has zero current but non-zero target → equal split across
    // holdings so user sees a reasonable starting point.
    return holdingsCount == 0
        ? classTargetRupees
        : classTargetRupees / holdingsCount;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classCurrent =
        holdings.fold<double>(0, (s, h) => s + h.currentValue);
    final currentPct =
        totalValue > 0 ? (classCurrent / totalValue) * 100.0 : 0.0;
    final classTargetRupees = totalValue * targetPct / 100.0;

    // Sum of per-fund effective targets — used by the status bar. With no
    // user touches, this equals `classTargetRupees` (balanced by design).
    final fundTargetSum = holdings.fold<double>(
      0,
      (s, h) => s +
          _effectiveTarget(
            fund: h,
            classCurrent: classCurrent,
            classTargetRupees: classTargetRupees,
            holdingsCount: holdings.length,
          ),
    );

    return AssetClassCard(
      displayName: cls.displayName,
      currentPct: currentPct,
      idealPct: targetPct,
      currentValue: classCurrent,
      totalPortfolioValue: totalValue,
      showHeaderPills: false,
      fundCount: holdings.length,
      // Header = pill banner + class-level slider + paired ₹/% inputs.
      // Rendered even when the card is collapsed so the user can adjust
      // the class target without expanding to see fund sub-cards.
      headerSlot: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderBanner(
            currentPct: currentPct,
            targetPct: targetPct,
            gapRupees: classCurrent - classTargetRupees,
          ),
          AssetClassAllocationSlider(
            currentPct: currentPct,
            targetPct: targetPct,
            totalPortfolioValue: totalValue,
            onChangedPct: onClassTargetChanged,
          ),
        ],
      ),
      children: [
        for (final h in holdings)
          FundSubCard(
            amfiCode: h.amfiCode,
            fundName: h.fundName,
            currentAssetClass: clsByAmfi[h.amfiCode] ?? cls,
            currentValue: h.currentValue,
            targetValue: _effectiveTarget(
              fund: h,
              classCurrent: classCurrent,
              classTargetRupees: classTargetRupees,
              holdingsCount: holdings.length,
            ),
            classCurrentRupees: classCurrent,
            classTargetRupees: classTargetRupees,
            pendingDeployment: pendingDeployments.contains(h.amfiCode),
            onExecuteDeployment: () =>
                _executeDeployment(ref, context, h, simAmounts),
            // Plain commit — no pro-rata. The ClassSumStatusBar below the
            // list flags any drift so the user can balance manually.
            onTargetChanged: (v) => ref
                .read(simulationStateProvider(memberId).notifier)
                .setFundAmount(h.amfiCode, v),
          ),
        _ClassSumStatusBar(
          fundTargetSum: fundTargetSum,
          classTargetRupees: classTargetRupees,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _executeDeployment(
    WidgetRef ref,
    BuildContext context,
    FundHoldingSummary h,
    Map<int, double> simAmounts,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final amount = simAmounts[h.amfiCode] ?? 0;
    if (amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Nothing to deploy — set a target first')),
      );
      return;
    }
    try {
      await ref.read(pendingOrdersMutatorProvider.notifier).add(
            fundName: h.fundName,
            kind: OrderKind.lumpsum,
            amfiCode: h.amfiCode,
            amount: amount,
            status: OrderStatus.placed,
            source: OrderSource.deployment,
            memberId: memberId,
            notes: 'Add Fund via Asset Allocation → Fund',
          );
      ref
          .read(simulationStateProvider(memberId).notifier)
          .clearPendingDeployment(h.amfiCode);
      messenger.showSnackBar(SnackBar(
        content: Text(
          'Deployment recorded — ${amount.toINRCompact()} in ${h.fundName}',
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Execute failed: $e')),
      );
    }
  }
}

/// Current / Target / Buy-or-Sell pill banner — action coloring.
class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({
    required this.currentPct,
    required this.targetPct,
    required this.gapRupees,
  });

  final double currentPct;
  final double targetPct;

  /// Positive = currentRs > targetRs → user needs to SELL (red).
  /// Negative = currentRs < targetRs → user needs to BUY (amber).
  final double gapRupees;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final deltaPct = currentPct - targetPct;
    final balanced = deltaPct.abs() < 0.5;
    final buy = deltaPct < 0 && !balanced; // target > current

    final actionColor = balanced
        ? AppColors.gain
        : buy
            ? AppColors.warning
            : AppColors.loss;
    final currentBg = balanced
        ? AppColors.gain.withValues(alpha: 0.16)
        : palette.bgSurface;
    final currentFg = balanced ? AppColors.gain : palette.textPrimary;

    String actionLabel;
    if (balanced) {
      actionLabel = 'Balanced';
    } else if (buy) {
      actionLabel = 'Buy ${gapRupees.abs().toINRCompact()}';
    } else {
      actionLabel = 'Sell ${gapRupees.abs().toINRCompact()}';
    }

    return Row(
      children: [
        Expanded(
          child: _Pill(
            label: 'Current ${currentPct.toStringAsFixed(1)}%',
            fg: currentFg,
            bg: currentBg,
            bold: balanced,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _Pill(
            label: 'Target ${targetPct.toStringAsFixed(1)}%',
            fg: balanced ? AppColors.textOnPrimary : actionColor,
            bg: balanced
                ? AppColors.gain.withValues(alpha: 0.16)
                : actionColor.withValues(alpha: 0.18),
            bold: true,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _Pill(
            label: actionLabel,
            fg: AppColors.textOnPrimary,
            bg: actionColor,
            bold: true,
          ),
        ),
      ],
    );
  }
}

/// Shows the sum of per-fund targets inside an asset class vs the class
/// target. Red when the sum over- or under-shoots by more than ₹100; green
/// "Balanced" when it matches. Replaces the pro-rata auto-rescaling that
/// turned out to fight the user's intent.
class _ClassSumStatusBar extends StatelessWidget {
  const _ClassSumStatusBar({
    required this.fundTargetSum,
    required this.classTargetRupees,
  });

  final double fundTargetSum;
  final double classTargetRupees;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final delta = fundTargetSum - classTargetRupees;
    // Tolerance: ₹500 or 0.1% of the class target, whichever is larger. Keeps
    // tiny rounding residues from showing as "Short" when the user sees 100%.
    final tolerance = classTargetRupees <= 0
        ? 0.0
        : (classTargetRupees * 0.001).clamp(500.0, double.infinity);
    final balanced = delta.abs() <= tolerance || classTargetRupees <= 0;
    final classPct = classTargetRupees <= 0
        ? 0.0
        : (fundTargetSum / classTargetRupees) * 100;

    final Color color;
    final IconData icon;
    final String label;
    if (balanced) {
      color = AppColors.gain;
      icon = Icons.check_circle;
      label = classTargetRupees <= 0
          ? 'Set a class target to see balance'
          : 'Balanced 100% (${fundTargetSum.toINRCompact()})';
    } else if (delta > 0) {
      color = AppColors.loss;
      icon = Icons.error_outline;
      label =
          'Over ${classPct.toStringAsFixed(1)}% — excess ${delta.abs().toINRCompact()}';
    } else {
      color = AppColors.loss;
      icon = Icons.error_outline;
      label =
          'Short ${classPct.toStringAsFixed(1)}% — deficit ${delta.abs().toINRCompact()}';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          Text(
            'Target ${classTargetRupees.toINRCompact()}',
            style: TextStyle(
              fontSize: 10,
              color: palette.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.fg,
    required this.bg,
    this.bold = false,
  });
  final String label;
  final Color fg;
  final Color bg;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _CustomTargetsBanner extends StatelessWidget {
  const _CustomTargetsBanner({required this.count, required this.onReset});

  final int count;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count custom target${count == 1 ? '' : 's'} active — '
              'steering Rebalance reallocation.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: onReset,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

AssetClass? _assetClassFromName(String name) {
  for (final c in AssetClass.values) {
    if (c.name == name) return c;
  }
  return null;
}

/// Bottom action bar: sum-of-class-targets pill + "Saved · HH:MM" chip +
/// inline Add Fund button. Replaces the old Scaffold FAB that overlapped
/// the TotalAllocationIndicator.
class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.classTargetSumPct,
    required this.lastSavedAt,
    required this.onAddFund,
  });

  final double classTargetSumPct;
  final DateTime? lastSavedAt;
  final VoidCallback onAddFund;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final balanced = (classTargetSumPct - 100).abs() < 0.1;
    final color = balanced ? AppColors.gain : AppColors.loss;
    final delta = classTargetSumPct - 100;
    final label = balanced
        ? 'Balanced 100%'
        : (delta > 0
            ? 'Over ${classTargetSumPct.toStringAsFixed(1)}%'
            : 'Short ${classTargetSumPct.toStringAsFixed(1)}%');

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  balanced ? Icons.check_circle : Icons.error_outline,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (lastSavedAt != null)
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done_outlined,
                      size: 13, color: palette.textTertiary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Saved \u00B7 ${_fmtTime(lastSavedAt!)}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11, color: palette.textTertiary),
                    ),
                  ),
                ],
              ),
            )
          else
            const Spacer(),
          FilledButton.icon(
            onPressed: onAddFund,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Fund'),
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _DisabledOverlay extends StatelessWidget {
  const _DisabledOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline,
                size: 40,
                color:
                    context.palette.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            Text(
              'Select a member to simulate individual allocations',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
