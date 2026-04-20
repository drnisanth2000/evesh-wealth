import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/goal_model.dart';
import '../../data/models/portfolio_summary_model.dart';
import '../../domain/models/allocation_models.dart';
import '../../domain/usecases/compute_goal_gap.dart';
import 'goal_provider.dart';
import 'other_assets_provider.dart';
import 'portfolio_provider.dart';
import 'wealth_planner_provider.dart';

part 'goal_gap_provider.g.dart';

/// Per-goal deficit/excess, keyed by goalId. Individual goal pages or expanded
/// rail cards can watch this directly.
@riverpod
Future<GoalGapResult?> goalGap(GoalGapRef ref, String goalId) async {
  final goals = await ref.watch(goalsProvider.future);
  final goal = goals.firstWhereOrNull((g) => g.id == goalId);
  if (goal == null) return null;

  final links = await ref.watch(goalFundLinksProvider.future);
  final portfolio =
      await ref.watch(portfolioSummaryProvider(goal.memberId).future);
  final health =
      await ref.watch(allocationHealthProvider(goal.memberId).future);

  final scopedGoals = _scopedGoalsFor(goals, goal.memberId);

  return _gapFor(
    goal: goal,
    goalsInScope: scopedGoals,
    links: links,
    holdings: portfolio.fundHoldings,
    ideal: health.idealAllocation,
    // Per-member view auto-attaches by term; family-scope (memberId==null)
    // only honours explicit links (mirrors goal_landing_screen behaviour).
    autoAttach: goal.memberId != null,
  );
}

/// All-goal fan-out used by the Goal Rail + Plan tab. Single provider avoids
/// N individual subscriptions when the rail paints 20 goals.
@riverpod
Future<List<GoalGapResult>> allGoalGaps(
  AllGoalGapsRef ref,
  String? memberId,
) async {
  final goals = await ref.watch(goalsProvider.future);
  final links = await ref.watch(goalFundLinksProvider.future);
  final portfolio = await ref.watch(portfolioSummaryProvider(memberId).future);
  // otherAssets currently unused here — goal_other_asset_links table is TBD.
  await ref.watch(otherAssetsProvider(memberId).future);
  final health = await ref.watch(allocationHealthProvider(memberId).future);

  final scopedGoals = _scopedGoalsFor(goals, memberId);
  final autoAttach = memberId != null;

  return [
    for (final goal in scopedGoals)
      _gapFor(
        goal: goal,
        goalsInScope: scopedGoals,
        links: links,
        holdings: portfolio.fundHoldings,
        ideal: health.idealAllocation,
        autoAttach: autoAttach,
      ),
  ];
}

/// Scope rule mirrors `goal_landing_screen._MemberGoalsView`:
/// - ALL view (`memberId == null`) → only family-level goals (memberId == null)
/// - Member view (`memberId != null`) → strictly that member's goals. Family
///   goals don't bleed into a member view — they live on the ALL tab.
List<GoalModel> _scopedGoalsFor(List<GoalModel> goals, String? memberId) {
  if (memberId == null) {
    return goals.where((g) => g.memberId == null).toList();
  }
  return goals.where((g) => g.memberId == memberId).toList();
}

/// Builds the "funds attached to this goal" list using the same two-step
/// strategy the Goals page uses:
/// 1. Explicit `goal_funds` rows win outright.
/// 2. If [autoAttach] is true, auto-attach untouched holdings by fund term to
///    the earliest goal in that term.
///
/// Funds whose term has no matching goal fall through unassigned — they do
/// NOT contribute to any goal's progress.
GoalGapResult _gapFor({
  required GoalModel goal,
  required List<GoalModel> goalsInScope,
  required List<GoalFundLink> links,
  required List<FundHoldingSummary> holdings,
  required IdealAllocation ideal,
  required bool autoAttach,
}) {
  // Earliest goal per term becomes the auto-attach default for that term.
  final sortedGoals = [...goalsInScope]
    ..sort((a, b) => a.targetDateTime.compareTo(b.targetDateTime));
  final defaultByTerm = <GoalTerm, String>{};
  for (final g in sortedGoals) {
    defaultByTerm.putIfAbsent(g.term, () => g.id);
  }

  // Pre-index explicit links by amfiCode → goalId.
  final explicit = <int, String>{};
  for (final l in links) {
    if (goalsInScope.any((g) => g.id == l.goalId)) {
      explicit[l.amfiCode] = l.goalId;
    }
  }

  final linkedFunds = <FundHoldingSummary>[];
  for (final h in holdings) {
    final pinned = explicit[h.amfiCode];
    if (pinned != null) {
      if (pinned == goal.id) linkedFunds.add(h);
      // else fund is explicitly pinned to a different goal; skip.
      continue;
    }
    if (!autoAttach) continue;
    final term = classifyFundTerm(h);
    final defaultGoalId = defaultByTerm[term];
    if (defaultGoalId == goal.id) {
      linkedFunds.add(h);
    }
  }

  return computeGoalGap(
    goal: goal,
    linkedFunds: linkedFunds,
    linkedOtherAssets: const [],
    riskIdeal: ideal,
    now: DateTime.now(),
  );
}

extension _FirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
