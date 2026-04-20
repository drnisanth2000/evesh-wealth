// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_goal_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectedGoalFilterHash() =>
    r'3f5a9aa4b1efe6afa31b71ae72758baa26aabf82';

/// Which goal (if any) is currently filtering the Buckets sub-tab view. Null
/// means "whole portfolio" — bucket targets come from the risk-profile ideal.
/// Non-null means the buckets are re-scoped to that goal's linked funds +
/// that goal's term-based target mix.
///
/// Copied from [SelectedGoalFilter].
@ProviderFor(SelectedGoalFilter)
final selectedGoalFilterProvider =
    AutoDisposeNotifierProvider<SelectedGoalFilter, String?>.internal(
  SelectedGoalFilter.new,
  name: r'selectedGoalFilterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedGoalFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedGoalFilter = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
