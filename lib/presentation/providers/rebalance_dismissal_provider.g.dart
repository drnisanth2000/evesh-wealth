// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rebalance_dismissal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$rebalanceDismissalsHash() =>
    r'96e8d5a9ea33df81e836414294798a46063a8022';

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

/// Rebalance suggestions the user has dismissed, scoped to a single member
/// (or all when [memberId] is null). Sorted newest-first by `dismissed_at`.
///
/// Copied from [rebalanceDismissals].
@ProviderFor(rebalanceDismissals)
const rebalanceDismissalsProvider = RebalanceDismissalsFamily();

/// Rebalance suggestions the user has dismissed, scoped to a single member
/// (or all when [memberId] is null). Sorted newest-first by `dismissed_at`.
///
/// Copied from [rebalanceDismissals].
class RebalanceDismissalsFamily
    extends Family<AsyncValue<List<RebalanceDismissalModel>>> {
  /// Rebalance suggestions the user has dismissed, scoped to a single member
  /// (or all when [memberId] is null). Sorted newest-first by `dismissed_at`.
  ///
  /// Copied from [rebalanceDismissals].
  const RebalanceDismissalsFamily();

  /// Rebalance suggestions the user has dismissed, scoped to a single member
  /// (or all when [memberId] is null). Sorted newest-first by `dismissed_at`.
  ///
  /// Copied from [rebalanceDismissals].
  RebalanceDismissalsProvider call(
    String? memberId,
  ) {
    return RebalanceDismissalsProvider(
      memberId,
    );
  }

  @override
  RebalanceDismissalsProvider getProviderOverride(
    covariant RebalanceDismissalsProvider provider,
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
  String? get name => r'rebalanceDismissalsProvider';
}

/// Rebalance suggestions the user has dismissed, scoped to a single member
/// (or all when [memberId] is null). Sorted newest-first by `dismissed_at`.
///
/// Copied from [rebalanceDismissals].
class RebalanceDismissalsProvider
    extends AutoDisposeFutureProvider<List<RebalanceDismissalModel>> {
  /// Rebalance suggestions the user has dismissed, scoped to a single member
  /// (or all when [memberId] is null). Sorted newest-first by `dismissed_at`.
  ///
  /// Copied from [rebalanceDismissals].
  RebalanceDismissalsProvider(
    String? memberId,
  ) : this._internal(
          (ref) => rebalanceDismissals(
            ref as RebalanceDismissalsRef,
            memberId,
          ),
          from: rebalanceDismissalsProvider,
          name: r'rebalanceDismissalsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$rebalanceDismissalsHash,
          dependencies: RebalanceDismissalsFamily._dependencies,
          allTransitiveDependencies:
              RebalanceDismissalsFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  RebalanceDismissalsProvider._internal(
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
    FutureOr<List<RebalanceDismissalModel>> Function(
            RebalanceDismissalsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RebalanceDismissalsProvider._internal(
        (ref) => create(ref as RebalanceDismissalsRef),
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
  AutoDisposeFutureProviderElement<List<RebalanceDismissalModel>>
      createElement() {
    return _RebalanceDismissalsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RebalanceDismissalsProvider && other.memberId == memberId;
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
mixin RebalanceDismissalsRef
    on AutoDisposeFutureProviderRef<List<RebalanceDismissalModel>> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _RebalanceDismissalsProviderElement
    extends AutoDisposeFutureProviderElement<List<RebalanceDismissalModel>>
    with RebalanceDismissalsRef {
  _RebalanceDismissalsProviderElement(super.provider);

  @override
  String? get memberId => (origin as RebalanceDismissalsProvider).memberId;
}

String _$rebalanceDismissalsMutatorHash() =>
    r'243211744e11562feb692b7d41bbb139118b96fe';

/// See also [RebalanceDismissalsMutator].
@ProviderFor(RebalanceDismissalsMutator)
final rebalanceDismissalsMutatorProvider =
    AutoDisposeNotifierProvider<RebalanceDismissalsMutator, void>.internal(
  RebalanceDismissalsMutator.new,
  name: r'rebalanceDismissalsMutatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$rebalanceDismissalsMutatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RebalanceDismissalsMutator = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
