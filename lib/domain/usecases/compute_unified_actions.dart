import '../../core/constants/platform_links.dart';
import '../models/action_models.dart';
import '../models/allocation_models.dart';
import '../models/retirement_models.dart';
import '../models/simulation_models.dart';

/// Aggregates actions from all engines into a unified RebalancePlan.
class UnifiedActionsCalculator {
  UnifiedActionsCalculator._();

  /// Bucket mapping: asset class key → bucket number.
  static const _assetClassToBucket = <String, int>{
    'liquid': 1,
    'debt': 1,
    'gold': 2,
    'hybrid': 2,
    'alternate': 2,
    'coreEquity': 3,
    'satelliteEquity': 3,
  };

  static RebalancePlan compute({
    required List<FundMove> fundMoves,
    required AllocationHealthResult healthResult,
    required RetirementGap? retirementGap,
    required Map<String, double> currentAllocation,
    required double totalPortfolioValue,
    required BucketStrategy bucketStrategy,
  }) {
    final actionItems = <ActionItem>[];
    final rationale = <String>[];

    // ── 1. Build bucket summary ──────────────────────────────────────────
    final bucketCurrentPct = <int, double>{1: 0, 2: 0, 3: 0};
    for (final entry in currentAllocation.entries) {
      final bucket = _assetClassToBucket[entry.key] ?? 2;
      bucketCurrentPct[bucket] = (bucketCurrentPct[bucket] ?? 0) + entry.value;
    }

    final bucketSummary = [1, 2, 3].map((b) {
      final current = bucketCurrentPct[b] ?? 0;
      final ideal = bucketStrategy.bucketTargets[b] ?? 33.3;
      final diff = current - ideal;
      final status = diff > 5
          ? 'overweight'
          : diff < -5
              ? 'underweight'
              : 'balanced';
      return BucketStatus(
        bucketNumber: b,
        bucketName: bucketStrategy.bucketNames[b] ?? 'Bucket $b',
        currentPct: current,
        idealPct: ideal,
        currentValue: totalPortfolioValue * (current / 100),
        status: status,
      );
    }).toList();

    // ── 2. Convert FundMoves → ActionItems ───────────────────────────────
    for (final move in fundMoves) {
      if (move.moveType == MoveType.hold) continue;

      final isShift = move.moveType == MoveType.shift;
      final isDeploy = move.moveType == MoveType.deployCash;

      final id = 'rebalance_${move.sourceAmfiCode ?? 0}_${move.destAmfiCode ?? 0}_${move.amount.round()}';

      actionItems.add(ActionItem(
        id: id,
        source: isDeploy ? ActionSource.cashOptimization : ActionSource.rebalance,
        priority: isDeploy ? ActionPriority.info : ActionPriority.warning,
        title: _moveTitle(move),
        subtitle: move.rationale,
        actionType: isShift || isDeploy ? ActionType.sell : ActionType.buy,
        amfiCode: move.destAmfiCode ?? move.sourceAmfiCode,
        amount: move.amount,
        rationale: move.rationale,
        impactDescription: _moveImpact(move),
        platformLinks: PlatformLinks.linksForAction(amfiCode: move.destAmfiCode),
      ));

      rationale.add(move.rationale);
    }

    // ── 3. Add retirement gap action ─────────────────────────────────────
    if (retirementGap != null && retirementGap.gap > 0 && retirementGap.requiredMonthlySip > 0) {
      final sipAmount = retirementGap.requiredMonthlySip;
      actionItems.add(ActionItem(
        id: 'retirement_sip_${sipAmount.round()}',
        source: ActionSource.retirement,
        priority: ActionPriority.warning,
        title: 'Increase monthly SIP by ₹${_compact(sipAmount)}',
        subtitle: 'Retirement corpus shortfall of ₹${_compact(retirementGap.gap)}',
        actionType: ActionType.increaseSip,
        amount: sipAmount,
        rationale: 'Current trajectory covers ${retirementGap.fundedPct.toStringAsFixed(0)}% of retirement corpus — additional SIP needed',
        impactDescription: 'Funded: ${retirementGap.fundedPct.toStringAsFixed(0)}% → 100%',
        platformLinks: PlatformLinks.linksForAction(),
      ));
      rationale.add('Retirement gap of ₹${_compact(retirementGap.gap)} — increase SIP by ₹${_compact(sipAmount)}/month');
    }

    // ── 4. Add drift alert actions ───────────────────────────────────────
    for (final drift in healthResult.driftAlerts) {
      if (drift.severity == 'ok') continue;

      final priority = drift.severity == 'critical'
          ? ActionPriority.critical
          : ActionPriority.warning;

      actionItems.add(ActionItem(
        id: 'drift_${drift.assetClassKey}_${drift.driftPct.round()}',
        source: ActionSource.drift,
        priority: priority,
        title: drift.message,
        subtitle: '${drift.assetClass}: ${drift.currentPct.toStringAsFixed(1)}% vs ideal ${drift.idealPct.toStringAsFixed(1)}%',
        actionType: drift.driftPct > 0 ? ActionType.sell : ActionType.buy,
        rationale: drift.message,
        impactDescription: 'Drift: ${drift.driftPct > 0 ? "+" : ""}${drift.driftPct.toStringAsFixed(1)}%',
        platformLinks: const [],
      ));
    }

    // ── 5. Sort by priority ──────────────────────────────────────────────
    actionItems.sort((a, b) {
      final priorityOrder = {ActionPriority.critical: 0, ActionPriority.warning: 1, ActionPriority.info: 2};
      final cmp = (priorityOrder[a.priority] ?? 2).compareTo(priorityOrder[b.priority] ?? 2);
      if (cmp != 0) return cmp;
      return (b.amount ?? 0).compareTo(a.amount ?? 0);
    });

    // ── 6. Compute totals ────────────────────────────────────────────────
    double totalSell = 0;
    double totalBuy = 0;
    for (final move in fundMoves) {
      if (move.moveType == MoveType.shift || move.moveType == MoveType.deployCash) {
        totalSell += move.amount;
        totalBuy += move.amount;
      } else if (move.moveType == MoveType.sell) {
        totalSell += move.amount;
      } else if (move.moveType == MoveType.buy) {
        totalBuy += move.amount;
      }
    }

    // Top drift alert
    final topDrift = healthResult.driftAlerts
        .where((d) => d.severity != 'ok')
        .toList();
    topDrift.sort((a, b) => b.driftPct.abs().compareTo(a.driftPct.abs()));

    return RebalancePlan(
      healthScore: healthResult.healthScore,
      healthLabel: healthResult.healthLabel,
      topDriftAlert: topDrift.isNotEmpty ? topDrift.first.message : null,
      retirementGapMonthly: retirementGap != null && retirementGap.gap > 0
          ? retirementGap.requiredMonthlySip
          : null,
      bucketSummary: bucketSummary,
      fundMoves: fundMoves,
      actionItems: actionItems,
      rationale: rationale,
      totalSellAmount: totalSell,
      totalBuyAmount: totalBuy,
      netCashFlow: totalBuy - totalSell,
    );
  }

  static String _moveTitle(FundMove move) {
    switch (move.moveType) {
      case MoveType.shift:
        return 'Move ₹${_compact(move.amount)} from ${move.sourceFundName ?? "?"} → ${move.destFundName ?? "?"}';
      case MoveType.deployCash:
        return 'Deploy ₹${_compact(move.amount)} from ${move.sourceFundName ?? "cash"} → ${move.destFundName ?? "?"}';
      case MoveType.sell:
        return 'Sell ₹${_compact(move.amount)} of ${move.sourceFundName ?? "?"}';
      case MoveType.buy:
        return 'Buy ₹${_compact(move.amount)} of ${move.destFundName ?? "?"}';
      case MoveType.hold:
        return 'Hold ${move.sourceFundName ?? "?"}';
    }
  }

  static String _moveImpact(FundMove move) {
    switch (move.moveType) {
      case MoveType.shift:
      case MoveType.deployCash:
        return 'Reduces ${move.sourceAssetClass ?? "?"} drift, improves ${move.destAssetClass ?? "?"} allocation';
      case MoveType.sell:
        return 'Reduces overweight position';
      case MoveType.buy:
        return 'Fills underweight allocation';
      case MoveType.hold:
        return 'No change needed';
    }
  }

  static String _compact(double value) {
    final abs = value.abs();
    if (abs >= 1e7) return '${(abs / 1e7).toStringAsFixed(1)}Cr';
    if (abs >= 1e5) return '${(abs / 1e5).toStringAsFixed(1)}L';
    if (abs >= 1e3) return '${(abs / 1e3).toStringAsFixed(0)}K';
    return abs.toStringAsFixed(0);
  }
}
