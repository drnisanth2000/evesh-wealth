// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wealth_planner_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allocationHealthHash() => r'661129a6a1642e510449a914caaa63d40a76ae62';

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

/// Computes [AllocationHealthResult] for a given member (or the family view).
///
/// - [memberId] null → family view: uses primary member's risk profile & age.
/// - [memberId] non-null → individual view: uses that member's data.
///
/// Copied from [allocationHealth].
@ProviderFor(allocationHealth)
const allocationHealthProvider = AllocationHealthFamily();

/// Computes [AllocationHealthResult] for a given member (or the family view).
///
/// - [memberId] null → family view: uses primary member's risk profile & age.
/// - [memberId] non-null → individual view: uses that member's data.
///
/// Copied from [allocationHealth].
class AllocationHealthFamily
    extends Family<AsyncValue<AllocationHealthResult>> {
  /// Computes [AllocationHealthResult] for a given member (or the family view).
  ///
  /// - [memberId] null → family view: uses primary member's risk profile & age.
  /// - [memberId] non-null → individual view: uses that member's data.
  ///
  /// Copied from [allocationHealth].
  const AllocationHealthFamily();

  /// Computes [AllocationHealthResult] for a given member (or the family view).
  ///
  /// - [memberId] null → family view: uses primary member's risk profile & age.
  /// - [memberId] non-null → individual view: uses that member's data.
  ///
  /// Copied from [allocationHealth].
  AllocationHealthProvider call(
    String? memberId,
  ) {
    return AllocationHealthProvider(
      memberId,
    );
  }

  @override
  AllocationHealthProvider getProviderOverride(
    covariant AllocationHealthProvider provider,
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
  String? get name => r'allocationHealthProvider';
}

/// Computes [AllocationHealthResult] for a given member (or the family view).
///
/// - [memberId] null → family view: uses primary member's risk profile & age.
/// - [memberId] non-null → individual view: uses that member's data.
///
/// Copied from [allocationHealth].
class AllocationHealthProvider
    extends AutoDisposeFutureProvider<AllocationHealthResult> {
  /// Computes [AllocationHealthResult] for a given member (or the family view).
  ///
  /// - [memberId] null → family view: uses primary member's risk profile & age.
  /// - [memberId] non-null → individual view: uses that member's data.
  ///
  /// Copied from [allocationHealth].
  AllocationHealthProvider(
    String? memberId,
  ) : this._internal(
          (ref) => allocationHealth(
            ref as AllocationHealthRef,
            memberId,
          ),
          from: allocationHealthProvider,
          name: r'allocationHealthProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$allocationHealthHash,
          dependencies: AllocationHealthFamily._dependencies,
          allTransitiveDependencies:
              AllocationHealthFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  AllocationHealthProvider._internal(
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
    FutureOr<AllocationHealthResult> Function(AllocationHealthRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AllocationHealthProvider._internal(
        (ref) => create(ref as AllocationHealthRef),
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
  AutoDisposeFutureProviderElement<AllocationHealthResult> createElement() {
    return _AllocationHealthProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AllocationHealthProvider && other.memberId == memberId;
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
mixin AllocationHealthRef
    on AutoDisposeFutureProviderRef<AllocationHealthResult> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _AllocationHealthProviderElement
    extends AutoDisposeFutureProviderElement<AllocationHealthResult>
    with AllocationHealthRef {
  _AllocationHealthProviderElement(super.provider);

  @override
  String? get memberId => (origin as AllocationHealthProvider).memberId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
