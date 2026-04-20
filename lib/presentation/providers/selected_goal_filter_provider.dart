import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_goal_filter_provider.g.dart';

/// Which goal (if any) is currently filtering the Buckets sub-tab view. Null
/// means "whole portfolio" — bucket targets come from the risk-profile ideal.
/// Non-null means the buckets are re-scoped to that goal's linked funds +
/// that goal's term-based target mix.
@riverpod
class SelectedGoalFilter extends _$SelectedGoalFilter {
  @override
  String? build() => null;

  void set(String? goalId) => state = goalId;

  void clear() => state = null;
}
