// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'other_assets_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$otherAssetsHash() => r'96ddc98d6ac0e5775d53b5b8b6d3162ccd3d74b8';

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

/// Other assets (FD / PPF / NPS / SGB / Real Estate / PMS / ...) scoped to a
/// single member, or the entire owner scope when [memberId] is null.
///
/// The bucket-composition provider (Wealth Planner v2 task 0.7) reads this
/// same family provider — keying by memberId lets screens switch between
/// "All members" and an individual view without refetching.
///
/// Copied from [otherAssets].
@ProviderFor(otherAssets)
const otherAssetsProvider = OtherAssetsFamily();

/// Other assets (FD / PPF / NPS / SGB / Real Estate / PMS / ...) scoped to a
/// single member, or the entire owner scope when [memberId] is null.
///
/// The bucket-composition provider (Wealth Planner v2 task 0.7) reads this
/// same family provider — keying by memberId lets screens switch between
/// "All members" and an individual view without refetching.
///
/// Copied from [otherAssets].
class OtherAssetsFamily extends Family<AsyncValue<List<OtherAssetModel>>> {
  /// Other assets (FD / PPF / NPS / SGB / Real Estate / PMS / ...) scoped to a
  /// single member, or the entire owner scope when [memberId] is null.
  ///
  /// The bucket-composition provider (Wealth Planner v2 task 0.7) reads this
  /// same family provider — keying by memberId lets screens switch between
  /// "All members" and an individual view without refetching.
  ///
  /// Copied from [otherAssets].
  const OtherAssetsFamily();

  /// Other assets (FD / PPF / NPS / SGB / Real Estate / PMS / ...) scoped to a
  /// single member, or the entire owner scope when [memberId] is null.
  ///
  /// The bucket-composition provider (Wealth Planner v2 task 0.7) reads this
  /// same family provider — keying by memberId lets screens switch between
  /// "All members" and an individual view without refetching.
  ///
  /// Copied from [otherAssets].
  OtherAssetsProvider call(
    String? memberId,
  ) {
    return OtherAssetsProvider(
      memberId,
    );
  }

  @override
  OtherAssetsProvider getProviderOverride(
    covariant OtherAssetsProvider provider,
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
  String? get name => r'otherAssetsProvider';
}

/// Other assets (FD / PPF / NPS / SGB / Real Estate / PMS / ...) scoped to a
/// single member, or the entire owner scope when [memberId] is null.
///
/// The bucket-composition provider (Wealth Planner v2 task 0.7) reads this
/// same family provider — keying by memberId lets screens switch between
/// "All members" and an individual view without refetching.
///
/// Copied from [otherAssets].
class OtherAssetsProvider
    extends AutoDisposeFutureProvider<List<OtherAssetModel>> {
  /// Other assets (FD / PPF / NPS / SGB / Real Estate / PMS / ...) scoped to a
  /// single member, or the entire owner scope when [memberId] is null.
  ///
  /// The bucket-composition provider (Wealth Planner v2 task 0.7) reads this
  /// same family provider — keying by memberId lets screens switch between
  /// "All members" and an individual view without refetching.
  ///
  /// Copied from [otherAssets].
  OtherAssetsProvider(
    String? memberId,
  ) : this._internal(
          (ref) => otherAssets(
            ref as OtherAssetsRef,
            memberId,
          ),
          from: otherAssetsProvider,
          name: r'otherAssetsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$otherAssetsHash,
          dependencies: OtherAssetsFamily._dependencies,
          allTransitiveDependencies:
              OtherAssetsFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  OtherAssetsProvider._internal(
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
    FutureOr<List<OtherAssetModel>> Function(OtherAssetsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OtherAssetsProvider._internal(
        (ref) => create(ref as OtherAssetsRef),
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
  AutoDisposeFutureProviderElement<List<OtherAssetModel>> createElement() {
    return _OtherAssetsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OtherAssetsProvider && other.memberId == memberId;
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
mixin OtherAssetsRef on AutoDisposeFutureProviderRef<List<OtherAssetModel>> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _OtherAssetsProviderElement
    extends AutoDisposeFutureProviderElement<List<OtherAssetModel>>
    with OtherAssetsRef {
  _OtherAssetsProviderElement(super.provider);

  @override
  String? get memberId => (origin as OtherAssetsProvider).memberId;
}

String _$otherAssetsMutatorHash() =>
    r'33c3db2d5e4dc9e8134f9ce7b34b5dd4847df014';

/// See also [OtherAssetsMutator].
@ProviderFor(OtherAssetsMutator)
final otherAssetsMutatorProvider =
    AutoDisposeNotifierProvider<OtherAssetsMutator, void>.internal(
  OtherAssetsMutator.new,
  name: r'otherAssetsMutatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$otherAssetsMutatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OtherAssetsMutator = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
