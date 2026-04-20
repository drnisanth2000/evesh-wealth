// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$goalsHash() => r'ad4d5d19e9ceba78840025babe6d3c32cb6b9acb';

/// See also [goals].
@ProviderFor(goals)
final goalsProvider = AutoDisposeFutureProvider<List<GoalModel>>.internal(
  goals,
  name: r'goalsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$goalsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GoalsRef = AutoDisposeFutureProviderRef<List<GoalModel>>;
String _$goalFundLinksHash() => r'6d5aa3d59f1d6264bfb1ba22aa5edbbdb1f83579';

/// See also [goalFundLinks].
@ProviderFor(goalFundLinks)
final goalFundLinksProvider =
    AutoDisposeFutureProvider<List<GoalFundLink>>.internal(
  goalFundLinks,
  name: r'goalFundLinksProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$goalFundLinksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GoalFundLinksRef = AutoDisposeFutureProviderRef<List<GoalFundLink>>;
String _$goalMutatorHash() => r'9980a03d7461a8cdb47873ac51d7d5db65c333b2';

/// See also [GoalMutator].
@ProviderFor(GoalMutator)
final goalMutatorProvider =
    AutoDisposeNotifierProvider<GoalMutator, void>.internal(
  GoalMutator.new,
  name: r'goalMutatorProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$goalMutatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GoalMutator = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
