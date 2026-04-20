// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deployment_plan_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deploymentPlansHash() => r'413175b06371e45cc235e0aea982c89c042b745e';

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

/// Saved STP / lumpsum-vs-SIP deployment plans, scoped to a single member
/// (or all when [memberId] is null). Sorted newest-first by `created_at`.
///
/// Copied from [deploymentPlans].
@ProviderFor(deploymentPlans)
const deploymentPlansProvider = DeploymentPlansFamily();

/// Saved STP / lumpsum-vs-SIP deployment plans, scoped to a single member
/// (or all when [memberId] is null). Sorted newest-first by `created_at`.
///
/// Copied from [deploymentPlans].
class DeploymentPlansFamily
    extends Family<AsyncValue<List<DeploymentPlanModel>>> {
  /// Saved STP / lumpsum-vs-SIP deployment plans, scoped to a single member
  /// (or all when [memberId] is null). Sorted newest-first by `created_at`.
  ///
  /// Copied from [deploymentPlans].
  const DeploymentPlansFamily();

  /// Saved STP / lumpsum-vs-SIP deployment plans, scoped to a single member
  /// (or all when [memberId] is null). Sorted newest-first by `created_at`.
  ///
  /// Copied from [deploymentPlans].
  DeploymentPlansProvider call(
    String? memberId,
  ) {
    return DeploymentPlansProvider(
      memberId,
    );
  }

  @override
  DeploymentPlansProvider getProviderOverride(
    covariant DeploymentPlansProvider provider,
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
  String? get name => r'deploymentPlansProvider';
}

/// Saved STP / lumpsum-vs-SIP deployment plans, scoped to a single member
/// (or all when [memberId] is null). Sorted newest-first by `created_at`.
///
/// Copied from [deploymentPlans].
class DeploymentPlansProvider
    extends AutoDisposeFutureProvider<List<DeploymentPlanModel>> {
  /// Saved STP / lumpsum-vs-SIP deployment plans, scoped to a single member
  /// (or all when [memberId] is null). Sorted newest-first by `created_at`.
  ///
  /// Copied from [deploymentPlans].
  DeploymentPlansProvider(
    String? memberId,
  ) : this._internal(
          (ref) => deploymentPlans(
            ref as DeploymentPlansRef,
            memberId,
          ),
          from: deploymentPlansProvider,
          name: r'deploymentPlansProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$deploymentPlansHash,
          dependencies: DeploymentPlansFamily._dependencies,
          allTransitiveDependencies:
              DeploymentPlansFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  DeploymentPlansProvider._internal(
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
    FutureOr<List<DeploymentPlanModel>> Function(DeploymentPlansRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DeploymentPlansProvider._internal(
        (ref) => create(ref as DeploymentPlansRef),
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
  AutoDisposeFutureProviderElement<List<DeploymentPlanModel>> createElement() {
    return _DeploymentPlansProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DeploymentPlansProvider && other.memberId == memberId;
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
mixin DeploymentPlansRef
    on AutoDisposeFutureProviderRef<List<DeploymentPlanModel>> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _DeploymentPlansProviderElement
    extends AutoDisposeFutureProviderElement<List<DeploymentPlanModel>>
    with DeploymentPlansRef {
  _DeploymentPlansProviderElement(super.provider);

  @override
  String? get memberId => (origin as DeploymentPlansProvider).memberId;
}

String _$deploymentPlansMutatorHash() =>
    r'3942576ce9c0c7281f9cc0ce8507b3bc6b019ab3';

/// See also [DeploymentPlansMutator].
@ProviderFor(DeploymentPlansMutator)
final deploymentPlansMutatorProvider =
    AutoDisposeNotifierProvider<DeploymentPlansMutator, void>.internal(
  DeploymentPlansMutator.new,
  name: r'deploymentPlansMutatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deploymentPlansMutatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DeploymentPlansMutator = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
