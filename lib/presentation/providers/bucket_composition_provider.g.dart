// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bucket_composition_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bucketCompositionHash() => r'3dd8d4a64215be732799d3dc96b93c9f33be45b6';

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

/// See also [bucketComposition].
@ProviderFor(bucketComposition)
const bucketCompositionProvider = BucketCompositionFamily();

/// See also [bucketComposition].
class BucketCompositionFamily
    extends Family<AsyncValue<BucketCompositionResult>> {
  /// See also [bucketComposition].
  const BucketCompositionFamily();

  /// See also [bucketComposition].
  BucketCompositionProvider call(
    String? memberId,
  ) {
    return BucketCompositionProvider(
      memberId,
    );
  }

  @override
  BucketCompositionProvider getProviderOverride(
    covariant BucketCompositionProvider provider,
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
  String? get name => r'bucketCompositionProvider';
}

/// See also [bucketComposition].
class BucketCompositionProvider
    extends AutoDisposeFutureProvider<BucketCompositionResult> {
  /// See also [bucketComposition].
  BucketCompositionProvider(
    String? memberId,
  ) : this._internal(
          (ref) => bucketComposition(
            ref as BucketCompositionRef,
            memberId,
          ),
          from: bucketCompositionProvider,
          name: r'bucketCompositionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bucketCompositionHash,
          dependencies: BucketCompositionFamily._dependencies,
          allTransitiveDependencies:
              BucketCompositionFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  BucketCompositionProvider._internal(
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
    FutureOr<BucketCompositionResult> Function(BucketCompositionRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BucketCompositionProvider._internal(
        (ref) => create(ref as BucketCompositionRef),
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
  AutoDisposeFutureProviderElement<BucketCompositionResult> createElement() {
    return _BucketCompositionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BucketCompositionProvider && other.memberId == memberId;
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
mixin BucketCompositionRef
    on AutoDisposeFutureProviderRef<BucketCompositionResult> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _BucketCompositionProviderElement
    extends AutoDisposeFutureProviderElement<BucketCompositionResult>
    with BucketCompositionRef {
  _BucketCompositionProviderElement(super.provider);

  @override
  String? get memberId => (origin as BucketCompositionProvider).memberId;
}

String _$fundBucketOverridesHash() =>
    r'3f01684a2f1f260f68ceff7375508fc5d25ad39d';

/// Pulls the current user's `transactions.bucket_override` rows and folds them
/// into a per-AMFI map. The latest non-null override wins (we just take any).
///
/// Copied from [fundBucketOverrides].
@ProviderFor(fundBucketOverrides)
final fundBucketOverridesProvider =
    AutoDisposeFutureProvider<Map<int, Bucket>>.internal(
  fundBucketOverrides,
  name: r'fundBucketOverridesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fundBucketOverridesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FundBucketOverridesRef = AutoDisposeFutureProviderRef<Map<int, Bucket>>;
String _$bucketOverrideMutatorHash() =>
    r'49514e28ce22fd2846211a522eb8cadff3f150bb';

/// Mutator: writes/clears `bucket_override` on transactions or other_assets
/// rows and invalidates dependent providers.
///
/// Copied from [BucketOverrideMutator].
@ProviderFor(BucketOverrideMutator)
final bucketOverrideMutatorProvider =
    AutoDisposeNotifierProvider<BucketOverrideMutator, void>.internal(
  BucketOverrideMutator.new,
  name: r'bucketOverrideMutatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bucketOverrideMutatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BucketOverrideMutator = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
