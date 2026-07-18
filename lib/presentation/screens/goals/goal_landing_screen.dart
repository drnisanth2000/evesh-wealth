import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/family_model.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/models/portfolio_summary_model.dart';
import '../../../domain/usecases/compute_goal_gap.dart';
import '../../providers/amfi_category_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/selected_member_provider.dart';
import '../../widgets/common/member_selector.dart';
import 'add_goal_dialog.dart';

class GoalLandingScreen extends StatelessWidget {
  const GoalLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: const GoalsView(),
    );
  }
}

/// Body of the Goals page — per-term goal cards + floating "Add Goal" button.
///
/// Used standalone at `/goals` (wrapped in a Scaffold with AppBar and its own
/// [MemberSelector]) and embedded inside the Wealth Planner shell's Goals tab,
/// which provides a global member chip header. Set [showMemberSelector] to
/// `false` in the embedded case; the view then reads the currently selected
/// member from [selectedMemberProvider] instead of rendering a duplicate strip.
/// No Scaffold here so the widget can safely nest inside a parent Scaffold.
class GoalsView extends ConsumerStatefulWidget {
  const GoalsView({super.key, this.showMemberSelector = true});

  /// Whether to render the in-body member selector strip. Leave `true` for
  /// standalone use; set `false` when a parent surface already owns member
  /// selection (e.g. the Wealth Planner shell's `GlobalMemberHeader`).
  final bool showMemberSelector;

  @override
  ConsumerState<GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends ConsumerState<GoalsView> {
  String? _localSelectedMemberId; // null = ALL (family-level)
  List<FamilyMemberModel> _members = const [];

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(familyMembersProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final activeMemberId = widget.showMemberSelector
        ? _localSelectedMemberId
        : ref.watch(selectedMemberProvider);

    return Stack(
      children: [
        Positioned.fill(
          child: membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (members) {
              _members = members;
              return goalsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (allGoals) {
                  return Column(
                    children: [
                      if (widget.showMemberSelector)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: MemberSelector(
                            selectedMemberId: _localSelectedMemberId,
                            onSelected: (id) => setState(
                                () => _localSelectedMemberId = id),
                          ),
                        ),
                      Expanded(
                        child: _MemberGoalsView(
                          key: ValueKey(activeMemberId ?? '__ALL__'),
                          allGoals: allGoals,
                          memberId: activeMemberId,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'goals_view_add_fab',
            onPressed: _members.isEmpty ? null : () => _openAddGoal(activeMemberId),
            icon: const Icon(Icons.add),
            label: const Text('Add Goal'),
          ),
        ),
      ],
    );
  }

  void _openAddGoal(String? activeMemberId) {
    showDialog<void>(
      context: context,
      builder: (_) => AddGoalDialog(
        members: _members,
        preselectedMemberId: activeMemberId,
        preselectAll: activeMemberId == null,
      ),
    );
  }
}

// ─── Per-member view (resolves auto-attach + renders term cards) ─────────────

class _MemberGoalsView extends ConsumerWidget {
  const _MemberGoalsView({
    super.key,
    required this.allGoals,
    required this.memberId,
  });

  final List<GoalModel> allGoals;
  final String? memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(goalFundLinksProvider);

    final goals = allGoals
        .where((g) => g.memberId == memberId)
        .toList()
      ..sort((a, b) => a.targetDateTime.compareTo(b.targetDateTime));

    final byTerm = <GoalTerm, List<GoalModel>>{
      GoalTerm.shortTerm: [],
      GoalTerm.mediumTerm: [],
      GoalTerm.longTerm: [],
    };
    for (final g in goals) {
      byTerm[g.term]!.add(g);
    }

    // ── ALL view: family-level goals only. NO auto-attach. Funds belong to
    //    individual members; ALL is purely a place for collective goals.
    if (memberId == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          for (final term in [
            GoalTerm.shortTerm,
            GoalTerm.mediumTerm,
            GoalTerm.longTerm,
          ]) ...[
            _TermCard(
              term: term,
              goals: byTerm[term]!,
              fundsByGoal: const {},
              unassignedByTerm: const {},
              allMemberGoals: goals,
              memberId: null,
            ),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    // ── Per-member view: pull holdings + auto-attach by category, but
    //    only against goals in the SAME term. Funds whose term has no
    //    matching goal are surfaced as "Unassigned" rows in that term card.
    final summaryAsync = ref.watch(portfolioSummaryProvider(memberId));
    final amfiCatalog = ref.watch(amfiCategoryCatalogProvider).valueOrNull ?? const {};
    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Err: $e')),
      data: (summary) {
        final links = linksAsync.value ?? const <GoalFundLink>[];

        // Default goal per term = earliest target_date in that term.
        final defaultByTerm = <GoalTerm, String>{};
        for (final g in goals) {
          defaultByTerm.putIfAbsent(g.term, () => g.id);
        }
        // Explicit links lookup
        final explicit = <int, String>{};
        for (final l in links) {
          if (goals.any((g) => g.id == l.goalId)) {
            explicit[l.amfiCode] = l.goalId;
          }
        }

        final fundsByGoal = <String, List<FundHoldingSummary>>{
          for (final g in goals) g.id: [],
        };
        final unassignedByTerm = <GoalTerm, List<FundHoldingSummary>>{
          GoalTerm.shortTerm: [],
          GoalTerm.mediumTerm: [],
          GoalTerm.longTerm: [],
        };

        for (final f in summary.fundHoldings) {
          final pinned = explicit[f.amfiCode];
          if (pinned != null) {
            fundsByGoal[pinned]!.add(f);
            continue;
          }
          final term = classifyFundTerm(f, amfiCatalog);
          final defaultGoalId = defaultByTerm[term];
          if (defaultGoalId != null) {
            fundsByGoal[defaultGoalId]!.add(f);
          } else {
            unassignedByTerm[term]!.add(f);
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            for (final term in [
              GoalTerm.shortTerm,
              GoalTerm.mediumTerm,
              GoalTerm.longTerm,
            ]) ...[
              _TermCard(
                term: term,
                goals: byTerm[term]!,
                fundsByGoal: fundsByGoal,
                unassignedByTerm: unassignedByTerm,
                allMemberGoals: goals,
                memberId: memberId,
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

// ─── Term Card ───────────────────────────────────────────────────────────────

class _TermCard extends ConsumerWidget {
  const _TermCard({
    required this.term,
    required this.goals,
    required this.fundsByGoal,
    required this.unassignedByTerm,
    required this.allMemberGoals,
    required this.memberId,
  });

  final GoalTerm term;
  final List<GoalModel> goals;
  final Map<String, List<FundHoldingSummary>> fundsByGoal;
  final Map<GoalTerm, List<FundHoldingSummary>> unassignedByTerm;
  final List<GoalModel> allMemberGoals;
  final String? memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _termColor(term);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        term.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        term.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.palette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${goals.length}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (goals.isEmpty && (unassignedByTerm[term]?.isEmpty ?? true))
              Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'No goals yet — tap Add Goal below.',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textTertiary,
                  ),
                ),
              )
            else ...[
              ...goals.map((g) => _GoalRow(
                    goal: g,
                    funds: fundsByGoal[g.id] ?? const [],
                    allMemberGoals: allMemberGoals,
                    memberId: memberId,
                  )),
              if ((unassignedByTerm[term] ?? const []).isNotEmpty)
                _UnassignedRow(
                  term: term,
                  funds: unassignedByTerm[term]!,
                  memberGoals: allMemberGoals,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Color _termColor(GoalTerm t) {
    switch (t) {
      case GoalTerm.shortTerm:
        return const Color(0xFFE57373);
      case GoalTerm.mediumTerm:
        return const Color(0xFFFFB74D);
      case GoalTerm.longTerm:
        return const Color(0xFF66BB6A);
    }
  }
}

// ─── Goal Row ────────────────────────────────────────────────────────────────

class _GoalRow extends ConsumerWidget {
  const _GoalRow({
    required this.goal,
    required this.funds,
    required this.allMemberGoals,
    required this.memberId,
  });

  final GoalModel goal;
  final List<FundHoldingSummary> funds;
  final List<GoalModel> allMemberGoals;
  final String? memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double invested = 0;
    double current = 0;
    for (final f in funds) {
      invested += f.totalInvested;
      current += f.currentValue;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.palette.bgDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.goalName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.palette.textPrimary,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMM yyyy').format(goal.targetDateTime),
                  style: TextStyle(
                    fontSize: 11,
                    color: context.palette.textTertiary,
                  ),
                ),
                IconButton(
                  iconSize: 18,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openEdit(context, ref),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 18,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ProgressBlock(
              goal: goal,
              invested: invested,
              current: current,
              fundsAttached: funds.length,
            ),
            if (funds.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: funds
                    .map((f) => _FundChip(
                          fund: f,
                          currentGoal: goal,
                          otherGoals: allMemberGoals
                              .where((g) => g.id != goal.id)
                              .toList(),
                          memberId: memberId,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AddGoalDialog(
        members: const [],
        preselectedMemberId: goal.memberId,
        preselectAll: goal.memberId == null,
        existing: goal,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text('Delete "${goal.goalName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(goalMutatorProvider.notifier).deleteGoal(goal.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }
}

// ─── Unassigned Row (no matching-term goal exists) ───────────────────────────

class _UnassignedRow extends ConsumerWidget {
  const _UnassignedRow({
    required this.term,
    required this.funds,
    required this.memberGoals,
  });

  final GoalTerm term;
  final List<FundHoldingSummary> funds;
  final List<GoalModel> memberGoals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    double total = 0;
    for (final f in funds) {
      total += f.currentValue;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Unassigned funds (${funds.length}) — ${fmt.format(total)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'These funds match this term but no ${term.label.toLowerCase()} exists. Add a goal here to track them — or use the move icon to attach to another goal.',
              style: TextStyle(
                fontSize: 10,
                color: context.palette.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: funds
                  .map((f) => _FundChip(
                        fund: f,
                        currentGoal: null,
                        otherGoals: memberGoals,
                        memberId: null,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Fund Chip with Move popup ───────────────────────────────────────────────

class _FundChip extends ConsumerWidget {
  const _FundChip({
    required this.fund,
    required this.currentGoal,
    required this.otherGoals,
    required this.memberId,
  });

  final FundHoldingSummary fund;
  final GoalModel? currentGoal;
  final List<GoalModel> otherGoals;
  final String? memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat.compactCurrency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 1);
    return PopupMenuButton<String>(
      tooltip: 'Move to another goal',
      itemBuilder: (ctx) {
        if (otherGoals.isEmpty) {
          return const [
            PopupMenuItem<String>(
              enabled: false,
              child: Text('No other goals to move to'),
            ),
          ];
        }
        return otherGoals
            .map((g) => PopupMenuItem<String>(
                  value: g.id,
                  child: Text(g.goalName),
                ))
            .toList();
      },
      onSelected: (newGoalId) async {
        try {
          await ref.read(goalMutatorProvider.notifier).attachFund(
                goalId: newGoalId,
                amfiCode: fund.amfiCode,
              );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Move failed: $e')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                fund.fundName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              fmt.format(fund.currentValue),
              style: TextStyle(
                fontSize: 10,
                color: context.palette.textTertiary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.swap_horiz, size: 12, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ─── Progress Block ──────────────────────────────────────────────────────────

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({
    required this.goal,
    required this.invested,
    required this.current,
    required this.fundsAttached,
  });

  final GoalModel goal;
  final double invested;
  final double current;
  final int fundsAttached;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final pct = goal.targetAmount > 0
        ? (current / goal.targetAmount * 100).clamp(0, 999).toDouble()
        : 0.0;

    // Share the same 4-state status algorithm Plan tab + Goal Rail use so
    // the label/colour never disagree between surfaces.
    final status = goalStatusFor(goal, current, DateTime.now());
    final statusColor = _goalStatusColor(status);
    final statusLabel = _goalStatusLabel(status);
    final statusIcon = status == GoalStatus.behind || status == GoalStatus.watch
        ? Icons.warning_amber
        : Icons.check_circle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: context.palette.bgDivider,
            valueColor: AlwaysStoppedAnimation(statusColor),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                '${fmt.format(current)} of ${fmt.format(goal.targetAmount)}',
                style: TextStyle(
                  fontSize: 11,
                  color: context.palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              statusIcon,
              size: 12,
              color: statusColor,
            ),
            const SizedBox(width: 4),
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Invested: ${fmt.format(invested)}',
              style: TextStyle(
                fontSize: 10,
                color: context.palette.textTertiary,
              ),
            ),
            const Spacer(),
            Text(
              fundsAttached == 0
                  ? 'No funds linked'
                  : '$fundsAttached fund${fundsAttached == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 10,
                color: context.palette.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shared status → colour mapping. Mirrors the palette used in
/// `goal_rail.dart` and `plan_tab.dart` so the same goal renders the same
/// status colour across every surface.
Color _goalStatusColor(GoalStatus s) {
  switch (s) {
    case GoalStatus.achieved:
      return AppColors.goalAchieved;
    case GoalStatus.onTrack:
      return AppColors.goalOnTrack;
    case GoalStatus.watch:
      return AppColors.goalWatch;
    case GoalStatus.behind:
      return AppColors.goalBehind;
  }
}

String _goalStatusLabel(GoalStatus s) {
  switch (s) {
    case GoalStatus.achieved:
      return 'Achieved';
    case GoalStatus.onTrack:
      return 'On track';
    case GoalStatus.watch:
      return 'Watch';
    case GoalStatus.behind:
      return 'Behind';
  }
}
