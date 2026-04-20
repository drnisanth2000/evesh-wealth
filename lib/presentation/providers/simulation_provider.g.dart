// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simulation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$memberBucketStrategyHash() =>
    r'4d0ad3e192085aec6411406bc0343e928bb0ddde';

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

/// Computes [BucketStrategy] for a specific family member (or Self if null).
///
/// Copied from [memberBucketStrategy].
@ProviderFor(memberBucketStrategy)
const memberBucketStrategyProvider = MemberBucketStrategyFamily();

/// Computes [BucketStrategy] for a specific family member (or Self if null).
///
/// Copied from [memberBucketStrategy].
class MemberBucketStrategyFamily extends Family<AsyncValue<BucketStrategy>> {
  /// Computes [BucketStrategy] for a specific family member (or Self if null).
  ///
  /// Copied from [memberBucketStrategy].
  const MemberBucketStrategyFamily();

  /// Computes [BucketStrategy] for a specific family member (or Self if null).
  ///
  /// Copied from [memberBucketStrategy].
  MemberBucketStrategyProvider call(
    String? memberId,
  ) {
    return MemberBucketStrategyProvider(
      memberId,
    );
  }

  @override
  MemberBucketStrategyProvider getProviderOverride(
    covariant MemberBucketStrategyProvider provider,
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
  String? get name => r'memberBucketStrategyProvider';
}

/// Computes [BucketStrategy] for a specific family member (or Self if null).
///
/// Copied from [memberBucketStrategy].
class MemberBucketStrategyProvider
    extends AutoDisposeFutureProvider<BucketStrategy> {
  /// Computes [BucketStrategy] for a specific family member (or Self if null).
  ///
  /// Copied from [memberBucketStrategy].
  MemberBucketStrategyProvider(
    String? memberId,
  ) : this._internal(
          (ref) => memberBucketStrategy(
            ref as MemberBucketStrategyRef,
            memberId,
          ),
          from: memberBucketStrategyProvider,
          name: r'memberBucketStrategyProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$memberBucketStrategyHash,
          dependencies: MemberBucketStrategyFamily._dependencies,
          allTransitiveDependencies:
              MemberBucketStrategyFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  MemberBucketStrategyProvider._internal(
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
    FutureOr<BucketStrategy> Function(MemberBucketStrategyRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MemberBucketStrategyProvider._internal(
        (ref) => create(ref as MemberBucketStrategyRef),
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
  AutoDisposeFutureProviderElement<BucketStrategy> createElement() {
    return _MemberBucketStrategyProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MemberBucketStrategyProvider && other.memberId == memberId;
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
mixin MemberBucketStrategyRef on AutoDisposeFutureProviderRef<BucketStrategy> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _MemberBucketStrategyProviderElement
    extends AutoDisposeFutureProviderElement<BucketStrategy>
    with MemberBucketStrategyRef {
  _MemberBucketStrategyProviderElement(super.provider);

  @override
  String? get memberId => (origin as MemberBucketStrategyProvider).memberId;
}

String _$simulationResultHash() => r'ca9794fd70f05d27d116e7d88a10b1f917d6da9b';

/// Computes [SimulationResult] from the current [SimulationState].
/// Returns null when the user hasn't changed anything (not dirty, empty).
///
/// Copied from [simulationResult].
@ProviderFor(simulationResult)
const simulationResultProvider = SimulationResultFamily();

/// Computes [SimulationResult] from the current [SimulationState].
/// Returns null when the user hasn't changed anything (not dirty, empty).
///
/// Copied from [simulationResult].
class SimulationResultFamily extends Family<AsyncValue<SimulationResult?>> {
  /// Computes [SimulationResult] from the current [SimulationState].
  /// Returns null when the user hasn't changed anything (not dirty, empty).
  ///
  /// Copied from [simulationResult].
  const SimulationResultFamily();

  /// Computes [SimulationResult] from the current [SimulationState].
  /// Returns null when the user hasn't changed anything (not dirty, empty).
  ///
  /// Copied from [simulationResult].
  SimulationResultProvider call(
    String? memberId,
  ) {
    return SimulationResultProvider(
      memberId,
    );
  }

  @override
  SimulationResultProvider getProviderOverride(
    covariant SimulationResultProvider provider,
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
  String? get name => r'simulationResultProvider';
}

/// Computes [SimulationResult] from the current [SimulationState].
/// Returns null when the user hasn't changed anything (not dirty, empty).
///
/// Copied from [simulationResult].
class SimulationResultProvider
    extends AutoDisposeFutureProvider<SimulationResult?> {
  /// Computes [SimulationResult] from the current [SimulationState].
  /// Returns null when the user hasn't changed anything (not dirty, empty).
  ///
  /// Copied from [simulationResult].
  SimulationResultProvider(
    String? memberId,
  ) : this._internal(
          (ref) => simulationResult(
            ref as SimulationResultRef,
            memberId,
          ),
          from: simulationResultProvider,
          name: r'simulationResultProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$simulationResultHash,
          dependencies: SimulationResultFamily._dependencies,
          allTransitiveDependencies:
              SimulationResultFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  SimulationResultProvider._internal(
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
    FutureOr<SimulationResult?> Function(SimulationResultRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SimulationResultProvider._internal(
        (ref) => create(ref as SimulationResultRef),
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
  AutoDisposeFutureProviderElement<SimulationResult?> createElement() {
    return _SimulationResultProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SimulationResultProvider && other.memberId == memberId;
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
mixin SimulationResultRef on AutoDisposeFutureProviderRef<SimulationResult?> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _SimulationResultProviderElement
    extends AutoDisposeFutureProviderElement<SimulationResult?>
    with SimulationResultRef {
  _SimulationResultProviderElement(super.provider);

  @override
  String? get memberId => (origin as SimulationResultProvider).memberId;
}

String _$activeFrozenPlanHash() => r'fcfc57f61654e6276b3ff03c9afc5a48278a4f50';

/// Fetches the active frozen plan for a member (or self if null).
///
/// Swallows transient/optional errors (missing table, parse failure) and
/// returns null. The frozen-plan signal is non-essential for downstream
/// providers like `rebalanceAnalysisProvider`; an exception here would cascade
/// and blank out the whole Suggested tab.
///
/// Copied from [activeFrozenPlan].
@ProviderFor(activeFrozenPlan)
const activeFrozenPlanProvider = ActiveFrozenPlanFamily();

/// Fetches the active frozen plan for a member (or self if null).
///
/// Swallows transient/optional errors (missing table, parse failure) and
/// returns null. The frozen-plan signal is non-essential for downstream
/// providers like `rebalanceAnalysisProvider`; an exception here would cascade
/// and blank out the whole Suggested tab.
///
/// Copied from [activeFrozenPlan].
class ActiveFrozenPlanFamily extends Family<AsyncValue<FrozenPlan?>> {
  /// Fetches the active frozen plan for a member (or self if null).
  ///
  /// Swallows transient/optional errors (missing table, parse failure) and
  /// returns null. The frozen-plan signal is non-essential for downstream
  /// providers like `rebalanceAnalysisProvider`; an exception here would cascade
  /// and blank out the whole Suggested tab.
  ///
  /// Copied from [activeFrozenPlan].
  const ActiveFrozenPlanFamily();

  /// Fetches the active frozen plan for a member (or self if null).
  ///
  /// Swallows transient/optional errors (missing table, parse failure) and
  /// returns null. The frozen-plan signal is non-essential for downstream
  /// providers like `rebalanceAnalysisProvider`; an exception here would cascade
  /// and blank out the whole Suggested tab.
  ///
  /// Copied from [activeFrozenPlan].
  ActiveFrozenPlanProvider call(
    String? memberId,
  ) {
    return ActiveFrozenPlanProvider(
      memberId,
    );
  }

  @override
  ActiveFrozenPlanProvider getProviderOverride(
    covariant ActiveFrozenPlanProvider provider,
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
  String? get name => r'activeFrozenPlanProvider';
}

/// Fetches the active frozen plan for a member (or self if null).
///
/// Swallows transient/optional errors (missing table, parse failure) and
/// returns null. The frozen-plan signal is non-essential for downstream
/// providers like `rebalanceAnalysisProvider`; an exception here would cascade
/// and blank out the whole Suggested tab.
///
/// Copied from [activeFrozenPlan].
class ActiveFrozenPlanProvider extends AutoDisposeFutureProvider<FrozenPlan?> {
  /// Fetches the active frozen plan for a member (or self if null).
  ///
  /// Swallows transient/optional errors (missing table, parse failure) and
  /// returns null. The frozen-plan signal is non-essential for downstream
  /// providers like `rebalanceAnalysisProvider`; an exception here would cascade
  /// and blank out the whole Suggested tab.
  ///
  /// Copied from [activeFrozenPlan].
  ActiveFrozenPlanProvider(
    String? memberId,
  ) : this._internal(
          (ref) => activeFrozenPlan(
            ref as ActiveFrozenPlanRef,
            memberId,
          ),
          from: activeFrozenPlanProvider,
          name: r'activeFrozenPlanProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activeFrozenPlanHash,
          dependencies: ActiveFrozenPlanFamily._dependencies,
          allTransitiveDependencies:
              ActiveFrozenPlanFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  ActiveFrozenPlanProvider._internal(
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
    FutureOr<FrozenPlan?> Function(ActiveFrozenPlanRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveFrozenPlanProvider._internal(
        (ref) => create(ref as ActiveFrozenPlanRef),
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
  AutoDisposeFutureProviderElement<FrozenPlan?> createElement() {
    return _ActiveFrozenPlanProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveFrozenPlanProvider && other.memberId == memberId;
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
mixin ActiveFrozenPlanRef on AutoDisposeFutureProviderRef<FrozenPlan?> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _ActiveFrozenPlanProviderElement
    extends AutoDisposeFutureProviderElement<FrozenPlan?>
    with ActiveFrozenPlanRef {
  _ActiveFrozenPlanProviderElement(super.provider);

  @override
  String? get memberId => (origin as ActiveFrozenPlanProvider).memberId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
