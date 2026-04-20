import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/family_model.dart';
import '../../../data/models/goal_model.dart';
import '../../../domain/usecases/compute_goal_gap.dart';
import '../../providers/family_provider.dart';
import '../../providers/goal_gap_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/selected_goal_filter_provider.dart';

/// Horizontally-scrolling strip of goal status chips. Tapping a goal sets
/// [selectedGoalFilterProvider]; tapping the currently-selected goal clears
/// it. Never collapses to 0 height — empty state renders an "Add goal" chip
/// deep-linking to the Goals screen.
class GoalRail extends ConsumerWidget {
  const GoalRail({super.key, required this.memberId});

  final String? memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gapsAsync = ref.watch(allGoalGapsProvider(memberId));
    final goalsAsync = ref.watch(goalsProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final selected = ref.watch(selectedGoalFilterProvider);

    return SizedBox(
      height: 96,
      child: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Err loading goals', style: TextStyle(fontSize: 11, color: context.palette.textTertiary)),
        ),
        data: (goals) {
          // Strict scoping: member view shows only that member's goals;
          // ALL view shows only family-level goals (matches Goals page).
          final scoped = goals.where((g) {
            if (memberId == null) return g.memberId == null;
            return g.memberId == memberId;
          }).toList()
            ..sort((a, b) => a.targetDateTime.compareTo(b.targetDateTime));

          if (scoped.isEmpty) return _emptyState(context);

          final gaps = gapsAsync.valueOrNull ?? const <GoalGapResult>[];
          final gapById = {for (final g in gaps) g.goalId: g};
          final members = membersAsync.valueOrNull ?? const <FamilyMemberModel>[];
          final memberById = {for (final m in members) m.id: m};

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: scoped.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final goal = scoped[i];
              return _GoalChip(
                goal: goal,
                gap: gapById[goal.id],
                member: goal.memberId == null
                    ? null
                    : memberById[goal.memberId!],
                isSelected: selected == goal.id,
                onTap: () {
                  final notifier =
                      ref.read(selectedGoalFilterProvider.notifier);
                  notifier.set(selected == goal.id ? null : goal.id);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          avatar: const Icon(Icons.flag_outlined, size: 16),
          label: const Text('Add a goal to scope rebalancing'),
          onPressed: () => context.go('/goals'),
        ),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.goal,
    required this.gap,
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  final GoalModel goal;
  final GoalGapResult? gap;
  final FamilyMemberModel? member;
  final bool isSelected;
  final VoidCallback onTap;

  String get _ownerLabel {
    if (goal.memberId == null) return 'Family';
    final name = member?.displayName;
    if (name == null || name.isEmpty) return 'Member';
    // First token only so the badge stays compact ("Hiya" not "Hiya Nambison").
    return name.trim().split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final status = gap?.status ?? GoalStatus.watch;
    final color = _statusColor(status);
    final progress = gap == null
        ? 0.0
        : (gap!.overallProgressPct / 100).clamp(0.0, 1.0);
    final ownerColor = goal.memberId == null
        ? AppColors.info
        : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : palette.bgDivider,
            width: isSelected ? 1.4 : 0.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    goal.goalName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: ownerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _ownerLabel,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: ownerColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('MMM yyyy').format(goal.targetDateTime),
              style: TextStyle(fontSize: 10, color: palette.textTertiary),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: palette.bgDivider,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  gap == null
                      ? '—'
                      : '${gap!.overallProgressPct.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
                const Spacer(),
                Text(
                  _statusLabel(status),
                  style: TextStyle(fontSize: 10, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(GoalStatus s) {
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

  String _statusLabel(GoalStatus s) {
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
}
