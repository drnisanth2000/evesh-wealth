import 'dart:math' as math;
import '../../core/constants/asset_classes.dart';
import '../models/action_models.dart';
import '../models/allocation_models.dart';
import 'run_rebalance_analysis.dart';

/// Input holding data for the rebalance actions calculator.
/// Lighter than FundHoldingSummary — only what we need.
class FundHoldingInput {
  final int amfiCode;
  final String fundName;
  final String assetClassKey; // 'coreEquity', 'debt', etc.
  final double currentValue;
  final double? return3y;
  final double? expenseRatio;

  const FundHoldingInput({
    required this.amfiCode,
    required this.fundName,
    required this.assetClassKey,
    required this.currentValue,
    this.return3y,
    this.expenseRatio,
  });

  /// Score for ranking: higher = better fund (keep), lower = sell first.
  double get qualityScore {
    double score = 50; // baseline
    if (return3y != null) score += return3y! * 2; // reward returns
    if (expenseRatio != null) score -= expenseRatio! * 10; // penalise cost
    return score;
  }
}

/// Generates fund-to-fund money movements from existing rebalance analysis.
class RebalanceActionsCalculator {
  RebalanceActionsCalculator._();

  /// Emergency fund = 6 months of expenses. Cash above this can be deployed.
  static const _emergencyFundMonths = 6;

  /// Minimum excess above emergency fund to trigger a deploy move (₹).
  static const _minDeployAmount = 10000.0;

  static List<FundMove> compute({
    required RebalanceResult rebalanceResult,
    required List<FundHoldingInput> holdings,
    required AllocationHealthResult healthResult,
    required double driftThreshold,
    required double monthlyExpense,
  }) {
    if (holdings.isEmpty || rebalanceResult.totalPortfolioValue <= 0) {
      return [];
    }

    final totalValue = rebalanceResult.totalPortfolioValue;
    final moves = <FundMove>[];

    // Group holdings by asset class key
    final holdingsByClass = <String, List<FundHoldingInput>>{};
    for (final h in holdings) {
      holdingsByClass.putIfAbsent(h.assetClassKey, () => []).add(h);
    }

    // Identify overweight and underweight classes from drifts
    final overweightClasses = <String, double>{}; // key → excess ₹
    final underweightClasses = <String, double>{}; // key → deficit ₹

    for (final drift in rebalanceResult.allocationDrifts) {
      final key = drift.assetClass.name; // e.g. 'coreEquity'
      if (drift.driftPct > driftThreshold) {
        overweightClasses[key] = drift.actionAmount;
      } else if (drift.driftPct < -driftThreshold) {
        underweightClasses[key] = drift.actionAmount;
      }
    }

    // ── Step 1: Check for idle cash (liquid exceeding emergency fund) ──
    final emergencyFund = monthlyExpense * _emergencyFundMonths;
    final liquidHoldings = holdingsByClass['liquid'] ?? [];
    final totalLiquid = liquidHoldings.fold(0.0, (s, h) => s + h.currentValue);
    final excessLiquid = totalLiquid - emergencyFund;

    if (excessLiquid > _minDeployAmount && underweightClasses.isNotEmpty) {
      // Find largest underweight class to deploy into
      final bestTarget = underweightClasses.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final targetClass = bestTarget.first.key;
      final targetFunds = holdingsByClass[targetClass] ?? [];

      // Deploy into best existing fund in target class, or name the class
      final deployAmount = math.min(excessLiquid, bestTarget.first.value);
      final destFund = targetFunds.isNotEmpty
          ? (targetFunds..sort((a, b) => b.qualityScore.compareTo(a.qualityScore))).first
          : null;

      moves.add(FundMove(
        sourceAmfiCode: liquidHoldings.first.amfiCode,
        sourceFundName: liquidHoldings.first.fundName,
        sourceAssetClass: 'liquid',
        destAmfiCode: destFund?.amfiCode,
        destFundName: destFund?.fundName ?? '${AssetClass.fromString(targetClass).displayName} fund',
        destAssetClass: targetClass,
        amount: deployAmount,
        moveType: MoveType.deployCash,
        rationale: 'Idle cash above emergency fund (₹${emergencyFund.round()}) — deploy for better returns',
      ));

      // Reduce the underweight deficit by the deployed amount
      underweightClasses[targetClass] = (underweightClasses[targetClass]! - deployAmount).clamp(0, double.infinity);
    }

    // ── Step 2: Generate shift moves from overweight → underweight ──
    if (overweightClasses.isNotEmpty && underweightClasses.isNotEmpty) {
      // Build sell queue: within each overweight class, rank funds worst-first
      final sellQueue = <FundHoldingInput>[];
      for (final entry in overweightClasses.entries) {
        final classHoldings = List<FundHoldingInput>.from(holdingsByClass[entry.key] ?? []);
        classHoldings.sort((a, b) => a.qualityScore.compareTo(b.qualityScore)); // worst first
        sellQueue.addAll(classHoldings);
      }

      // Build buy queue: within each underweight class, rank funds best-first
      final buyTargets = <String, FundHoldingInput?>{};
      for (final entry in underweightClasses.entries) {
        final classHoldings = List<FundHoldingInput>.from(holdingsByClass[entry.key] ?? []);
        if (classHoldings.isNotEmpty) {
          classHoldings.sort((a, b) => b.qualityScore.compareTo(a.qualityScore)); // best first
          buyTargets[entry.key] = classHoldings.first;
        }
      }

      // Total amount to move = min(total overweight, total underweight)
      double totalToMove = math.min(
        overweightClasses.values.fold(0.0, (s, v) => s + v),
        underweightClasses.values.fold(0.0, (s, v) => s + v),
      );

      // Distribute proportionally to underweight gaps
      final totalDeficit = underweightClasses.values.fold(0.0, (s, v) => s + v);

      if (totalDeficit > 0 && totalToMove > 0) {
        // For each underweight class, calculate its share of the moves
        final underweightEntries = underweightClasses.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value)); // largest gap first

        double remainingToMove = totalToMove;
        int sellIdx = 0;
        double sellRemaining = sellQueue.isNotEmpty
            ? math.min(sellQueue[sellIdx].currentValue,
                overweightClasses[sellQueue[sellIdx].assetClassKey] ?? 0)
            : 0;

        for (final uwEntry in underweightEntries) {
          if (remainingToMove <= 0 || sellIdx >= sellQueue.length) break;

          final share = (uwEntry.value / totalDeficit) * totalToMove;
          double allocated = 0;

          while (allocated < share && sellIdx < sellQueue.length) {
            final chunk = math.min(share - allocated, sellRemaining);
            if (chunk <= 0) {
              sellIdx++;
              if (sellIdx < sellQueue.length) {
                sellRemaining = math.min(sellQueue[sellIdx].currentValue,
                    overweightClasses[sellQueue[sellIdx].assetClassKey] ?? double.infinity);
              }
              continue;
            }

            final source = sellQueue[sellIdx];
            final dest = buyTargets[uwEntry.key];

            moves.add(FundMove(
              sourceAmfiCode: source.amfiCode,
              sourceFundName: source.fundName,
              sourceAssetClass: source.assetClassKey,
              destAmfiCode: dest?.amfiCode,
              destFundName: dest?.fundName ?? '${AssetClass.fromString(uwEntry.key).displayName} fund',
              destAssetClass: uwEntry.key,
              amount: chunk,
              moveType: MoveType.shift,
              rationale: '${AssetClass.fromString(source.assetClassKey).displayName} overweight → rebalance into ${AssetClass.fromString(uwEntry.key).displayName}',
            ));

            allocated += chunk;
            sellRemaining -= chunk;
            remainingToMove -= chunk;

            if (sellRemaining <= 0) {
              sellIdx++;
              if (sellIdx < sellQueue.length) {
                sellRemaining = math.min(sellQueue[sellIdx].currentValue,
                    overweightClasses[sellQueue[sellIdx].assetClassKey] ?? double.infinity);
              }
            }
          }
        }
      }
    }

    // ── Step 3: Mark remaining funds as hold ──
    final movedAmfis = <int>{};
    for (final m in moves) {
      if (m.sourceAmfiCode != null) movedAmfis.add(m.sourceAmfiCode!);
    }

    for (final h in holdings) {
      // Only add hold if this fund wasn't part of any move
      if (!movedAmfis.contains(h.amfiCode)) {
        final classKey = h.assetClassKey;
        final isOverweight = overweightClasses.containsKey(classKey);
        final isUnderweight = underweightClasses.containsKey(classKey);

        if (!isOverweight && !isUnderweight) {
          moves.add(FundMove(
            sourceAmfiCode: h.amfiCode,
            sourceFundName: h.fundName,
            sourceAssetClass: classKey,
            amount: h.currentValue,
            moveType: MoveType.hold,
            rationale: '${AssetClass.fromString(classKey).displayName} within target range — no action needed',
          ));
        }
      }
    }

    return moves;
  }
}
