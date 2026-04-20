// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_gap_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$goalGapHash() => r'c09fba3b347292224fb2a16e42522f040ad9bc12';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Per-goal deficit/excess, keyed by goalId. Individual goal pages or expanded
/// rail cards can watch this directly.
///
/// Copied from [goalGap].
@ProviderFor(goalGap)
const goalGapProvider = GoalGapFamily();

/// Per-goal deficit/excess, keyed by goalId. Individual goal pages or expanded
/// rail cards can watch this directly.
///
/// Copied from [goalGap].
class GoalGapFamily extends Family<AsyncValue<GoalGapResult?>> {
  /// Per-goal deficit/excess, keyed by goalId. Individual goal pages or expanded
  /// rail cards can watch this directly.
  ///
  /// Copied from [goalGap].
  const GoalGapFamily();

  /// Per-goal deficit/excess, keyed by goalId. Individual goal pages or expanded
  /// rail cards can watch this directly.
  ///
  /// Copied from [goalGap].
  GoalGapProvider call(
    String goalId,
  ) {
    return GoalGapProvider(
      goalId,
    );
  }

  @override
  GoalGapProvider getProviderOverride(
    covariant GoalGapProvider provider,
  ) {
    return call(
      provider.goalId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'goalGapProvider';
}

/// Per-goal deficit/excess, keyed by goalId. Individual goal pages or expanded
/// rail cards can watch this directly.
///
/// Copied from [goalGap].
class GoalGapProvider extends AutoDisposeFutureProvider<GoalGapResult?> {
  /// Per-goal deficit/excess, keyed by goalId. Individual goal pages or expanded
  /// rail cards can watch this directly.
  ///
  /// Copied from [goalGap].
  GoalGapProvider(
    String goalId,
  ) : this._internal(
          (ref) => goalGap(
            ref as GoalGapRef,
            goalId,
          ),
          from: goalGapProvider,
          name: r'goalGapProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$goalGapHash,
          dependencies: GoalGapFamily._dependencies,
          allTransitiveDependencies: GoalGapFamily._allTransitiveDependencies,
          goalId: goalId,
        );

  GoalGapProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.goalId,
  }) : super.internal();

  final String goalId;

  @override
  Override overrideWith(
    FutureOr<GoalGapResult?> Function(GoalGapRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GoalGapProvider._internal(
        (ref) => create(ref as GoalGapRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        goalId: goalId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<GoalGapResult?> createElement() {
    return _GoalGapProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GoalGapProvider && other.goalId == goalId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, goalId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GoalGapRef on AutoDisposeFutureProviderRef<GoalGapResult?> {
  /// The parameter `goalId` of this provider.
  String get goalId;
}

class _GoalGapProviderElement
    extends AutoDisposeFutureProviderElement<GoalGapResult?> with GoalGapRef {
  _GoalGapProviderElement(super.provider);

  @override
  String get goalId => (origin as GoalGapProvider).goalId;
}

String _$allGoalGapsHash() => r'4a0dd5d14c485d56e5f9e38b5fcc3a064c331ac5';

/// All-goal fan-out used by the Goal Rail + Plan tab. Single provider avoids
/// N individual subscriptions when the rail paints 20 goals.
///
/// Copied from [allGoalGaps].
@ProviderFor(allGoalGaps)
const allGoalGapsProvider = AllGoalGapsFamily();

/// All-goal fan-out used by the Goal Rail + Plan tab. Single provider avoids
/// N individual subscriptions when the rail paints 20 goals.
///
/// Copied from [allGoalGaps].
class AllGoalGapsFamily extends Family<AsyncValue<List<GoalGapResult>>> {
  /// All-goal fan-out used by the Goal Rail + Plan tab. Single provider avoids
  /// N individual subscriptions when the rail paints 20 goals.
  ///
  /// Copied from [allGoalGaps].
  const AllGoalGapsFamily();

  /// All-goal fan-out used by the Goal Rail + Plan tab. Single provider avoids
  /// N individual subscriptions when the rail paints 20 goals.
  ///
  /// Copied from [allGoalGaps].
  AllGoalGapsProvider call(
    String? memberId,
  ) {
    return AllGoalGapsProvider(
      memberId,
    );
  }

  @override
  AllGoalGapsProvider getProviderOverride(
    covariant AllGoalGapsProvider provider,
  ) {
    return call(
      provider.memberId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'allGoalGapsProvider';
}

/// All-goal fan-out used by the Goal Rail + Plan tab. Single provider avoids
/// N individual subscriptions when the rail paints 20 goals.
///
/// Copied from [allGoalGaps].
class AllGoalGapsProvider
    extends AutoDisposeFutureProvider<List<GoalGapResult>> {
  /// All-goal fan-out used by the Goal Rail + Plan tab. Single provider avoids
  /// N individual subscriptions when the rail paints 20 goals.
  ///
  /// Copied from [allGoalGaps].
  AllGoalGapsProvider(
    String? memberId,
  ) : this._internal(
          (ref) => allGoalGaps(
            ref as AllGoalGapsRef,
            memberId,
          ),
          from: allGoalGapsProvider,
          name: r'allGoalGapsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$allGoalGapsHash,
          dependencies: AllGoalGapsFamily._dependencies,
          allTransitiveDependencies:
              AllGoalGapsFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  AllGoalGapsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.memberId,
  }) : super.internal();

  final String? memberId;

  @override
  Override overrideWith(
    FutureOr<List<GoalGapResult>> Function(AllGoalGapsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AllGoalGapsProvider._internal(
        (ref) => create(ref as AllGoalGapsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        memberId: memberId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<GoalGapResult>> createElement() {
    return _AllGoalGapsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AllGoalGapsProvider && other.memberId == memberId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, memberId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AllGoalGapsRef on AutoDisposeFutureProviderRef<List<GoalGapResult>> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _AllGoalGapsProviderElement
    extends AutoDisposeFutureProviderElement<List<GoalGapResult>>
    with AllGoalGapsRef {
  _AllGoalGapsProviderElement(super.provider);

  @override
  String? get memberId => (origin as AllGoalGapsProvider).memberId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
