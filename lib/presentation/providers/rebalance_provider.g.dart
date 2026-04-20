// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rebalance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$rebalanceAnalysisHash() => r'd8d27215ef20009a65a124586a88792a7d54ef40';

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

/// Rebalance analysis keyed by [memberId] (null = family/all view).
///
/// Target priority (highest → lowest):
///   1. Live `simulationStateProvider(memberId).targetAllocations` — slider
///      currently held by the user wins.
///   2. `activeFrozenPlanProvider(memberId).assetClassTargets` — last frozen
///      per-asset-class target snapshot.
///   3. `allocationHealthProvider(memberId).idealAllocation` — risk-derived
///      defaults (same source the Asset slider tab seeds from on first open).
///      This is what the user sees on the Asset tab when they haven't touched
///      anything; rebalance must agree.
///   4. `family.target*` static defaults — last-resort fallback only.
///
/// Copied from [rebalanceAnalysis].
@ProviderFor(rebalanceAnalysis)
const rebalanceAnalysisProvider = RebalanceAnalysisFamily();

/// Rebalance analysis keyed by [memberId] (null = family/all view).
///
/// Target priority (highest → lowest):
///   1. Live `simulationStateProvider(memberId).targetAllocations` — slider
///      currently held by the user wins.
///   2. `activeFrozenPlanProvider(memberId).assetClassTargets` — last frozen
///      per-asset-class target snapshot.
///   3. `allocationHealthProvider(memberId).idealAllocation` — risk-derived
///      defaults (same source the Asset slider tab seeds from on first open).
///      This is what the user sees on the Asset tab when they haven't touched
///      anything; rebalance must agree.
///   4. `family.target*` static defaults — last-resort fallback only.
///
/// Copied from [rebalanceAnalysis].
class RebalanceAnalysisFamily extends Family<AsyncValue<RebalanceResult>> {
  /// Rebalance analysis keyed by [memberId] (null = family/all view).
  ///
  /// Target priority (highest → lowest):
  ///   1. Live `simulationStateProvider(memberId).targetAllocations` — slider
  ///      currently held by the user wins.
  ///   2. `activeFrozenPlanProvider(memberId).assetClassTargets` — last frozen
  ///      per-asset-class target snapshot.
  ///   3. `allocationHealthProvider(memberId).idealAllocation` — risk-derived
  ///      defaults (same source the Asset slider tab seeds from on first open).
  ///      This is what the user sees on the Asset tab when they haven't touched
  ///      anything; rebalance must agree.
  ///   4. `family.target*` static defaults — last-resort fallback only.
  ///
  /// Copied from [rebalanceAnalysis].
  const RebalanceAnalysisFamily();

  /// Rebalance analysis keyed by [memberId] (null = family/all view).
  ///
  /// Target priority (highest → lowest):
  ///   1. Live `simulationStateProvider(memberId).targetAllocations` — slider
  ///      currently held by the user wins.
  ///   2. `activeFrozenPlanProvider(memberId).assetClassTargets` — last frozen
  ///      per-asset-class target snapshot.
  ///   3. `allocationHealthProvider(memberId).idealAllocation` — risk-derived
  ///      defaults (same source the Asset slider tab seeds from on first open).
  ///      This is what the user sees on the Asset tab when they haven't touched
  ///      anything; rebalance must agree.
  ///   4. `family.target*` static defaults — last-resort fallback only.
  ///
  /// Copied from [rebalanceAnalysis].
  RebalanceAnalysisProvider call(
    String? memberId,
  ) {
    return RebalanceAnalysisProvider(
      memberId,
    );
  }

  @override
  RebalanceAnalysisProvider getProviderOverride(
    covariant RebalanceAnalysisProvider provider,
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
  String? get name => r'rebalanceAnalysisProvider';
}

/// Rebalance analysis keyed by [memberId] (null = family/all view).
///
/// Target priority (highest → lowest):
///   1. Live `simulationStateProvider(memberId).targetAllocations` — slider
///      currently held by the user wins.
///   2. `activeFrozenPlanProvider(memberId).assetClassTargets` — last frozen
///      per-asset-class target snapshot.
///   3. `allocationHealthProvider(memberId).idealAllocation` — risk-derived
///      defaults (same source the Asset slider tab seeds from on first open).
///      This is what the user sees on the Asset tab when they haven't touched
///      anything; rebalance must agree.
///   4. `family.target*` static defaults — last-resort fallback only.
///
/// Copied from [rebalanceAnalysis].
class RebalanceAnalysisProvider
    extends AutoDisposeFutureProvider<RebalanceResult> {
  /// Rebalance analysis keyed by [memberId] (null = family/all view).
  ///
  /// Target priority (highest → lowest):
  ///   1. Live `simulationStateProvider(memberId).targetAllocations` — slider
  ///      currently held by the user wins.
  ///   2. `activeFrozenPlanProvider(memberId).assetClassTargets` — last frozen
  ///      per-asset-class target snapshot.
  ///   3. `allocationHealthProvider(memberId).idealAllocation` — risk-derived
  ///      defaults (same source the Asset slider tab seeds from on first open).
  ///      This is what the user sees on the Asset tab when they haven't touched
  ///      anything; rebalance must agree.
  ///   4. `family.target*` static defaults — last-resort fallback only.
  ///
  /// Copied from [rebalanceAnalysis].
  RebalanceAnalysisProvider(
    String? memberId,
  ) : this._internal(
          (ref) => rebalanceAnalysis(
            ref as RebalanceAnalysisRef,
            memberId,
          ),
          from: rebalanceAnalysisProvider,
          name: r'rebalanceAnalysisProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$rebalanceAnalysisHash,
          dependencies: RebalanceAnalysisFamily._dependencies,
          allTransitiveDependencies:
              RebalanceAnalysisFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  RebalanceAnalysisProvider._internal(
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
    FutureOr<RebalanceResult> Function(RebalanceAnalysisRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RebalanceAnalysisProvider._internal(
        (ref) => create(ref as RebalanceAnalysisRef),
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
  AutoDisposeFutureProviderElement<RebalanceResult> createElement() {
    return _RebalanceAnalysisProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RebalanceAnalysisProvider && other.memberId == memberId;
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
mixin RebalanceAnalysisRef on AutoDisposeFutureProviderRef<RebalanceResult> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _RebalanceAnalysisProviderElement
    extends AutoDisposeFutureProviderElement<RebalanceResult>
    with RebalanceAnalysisRef {
  _RebalanceAnalysisProviderElement(super.provider);

  @override
  String? get memberId => (origin as RebalanceAnalysisProvider).memberId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
