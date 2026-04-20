// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retirement_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$retirementReadinessHash() =>
    r'c099a17db3b18da0232e5ece321644a98a10c062';

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

/// Computes [RetirementReadiness] for a given member (or family primary).
///
/// - [memberId] null → uses primary member.
/// - [memberId] non-null → uses that member's data.
///
/// Copied from [retirementReadiness].
@ProviderFor(retirementReadiness)
const retirementReadinessProvider = RetirementReadinessFamily();

/// Computes [RetirementReadiness] for a given member (or family primary).
///
/// - [memberId] null → uses primary member.
/// - [memberId] non-null → uses that member's data.
///
/// Copied from [retirementReadiness].
class RetirementReadinessFamily
    extends Family<AsyncValue<RetirementReadiness>> {
  /// Computes [RetirementReadiness] for a given member (or family primary).
  ///
  /// - [memberId] null → uses primary member.
  /// - [memberId] non-null → uses that member's data.
  ///
  /// Copied from [retirementReadiness].
  const RetirementReadinessFamily();

  /// Computes [RetirementReadiness] for a given member (or family primary).
  ///
  /// - [memberId] null → uses primary member.
  /// - [memberId] non-null → uses that member's data.
  ///
  /// Copied from [retirementReadiness].
  RetirementReadinessProvider call(
    String? memberId,
  ) {
    return RetirementReadinessProvider(
      memberId,
    );
  }

  @override
  RetirementReadinessProvider getProviderOverride(
    covariant RetirementReadinessProvider provider,
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
  String? get name => r'retirementReadinessProvider';
}

/// Computes [RetirementReadiness] for a given member (or family primary).
///
/// - [memberId] null → uses primary member.
/// - [memberId] non-null → uses that member's data.
///
/// Copied from [retirementReadiness].
class RetirementReadinessProvider
    extends AutoDisposeFutureProvider<RetirementReadiness> {
  /// Computes [RetirementReadiness] for a given member (or family primary).
  ///
  /// - [memberId] null → uses primary member.
  /// - [memberId] non-null → uses that member's data.
  ///
  /// Copied from [retirementReadiness].
  RetirementReadinessProvider(
    String? memberId,
  ) : this._internal(
          (ref) => retirementReadiness(
            ref as RetirementReadinessRef,
            memberId,
          ),
          from: retirementReadinessProvider,
          name: r'retirementReadinessProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$retirementReadinessHash,
          dependencies: RetirementReadinessFamily._dependencies,
          allTransitiveDependencies:
              RetirementReadinessFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  RetirementReadinessProvider._internal(
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
    FutureOr<RetirementReadiness> Function(RetirementReadinessRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RetirementReadinessProvider._internal(
        (ref) => create(ref as RetirementReadinessRef),
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
  AutoDisposeFutureProviderElement<RetirementReadiness> createElement() {
    return _RetirementReadinessProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RetirementReadinessProvider && other.memberId == memberId;
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
mixin RetirementReadinessRef
    on AutoDisposeFutureProviderRef<RetirementReadiness> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _RetirementReadinessProviderElement
    extends AutoDisposeFutureProviderElement<RetirementReadiness>
    with RetirementReadinessRef {
  _RetirementReadinessProviderElement(super.provider);

  @override
  String? get memberId => (origin as RetirementReadinessProvider).memberId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
