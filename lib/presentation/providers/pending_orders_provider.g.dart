// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_orders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingOrdersHash() => r'093a5d600f8c9640da4a9244e9ade40a6928eae2';

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

/// Pending orders for a single member (or all when [memberId] is null).
/// Sorted newest-first by `created_at`.
///
/// Copied from [pendingOrders].
@ProviderFor(pendingOrders)
const pendingOrdersProvider = PendingOrdersFamily();

/// Pending orders for a single member (or all when [memberId] is null).
/// Sorted newest-first by `created_at`.
///
/// Copied from [pendingOrders].
class PendingOrdersFamily extends Family<AsyncValue<List<PendingOrderModel>>> {
  /// Pending orders for a single member (or all when [memberId] is null).
  /// Sorted newest-first by `created_at`.
  ///
  /// Copied from [pendingOrders].
  const PendingOrdersFamily();

  /// Pending orders for a single member (or all when [memberId] is null).
  /// Sorted newest-first by `created_at`.
  ///
  /// Copied from [pendingOrders].
  PendingOrdersProvider call(
    String? memberId,
  ) {
    return PendingOrdersProvider(
      memberId,
    );
  }

  @override
  PendingOrdersProvider getProviderOverride(
    covariant PendingOrdersProvider provider,
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
  String? get name => r'pendingOrdersProvider';
}

/// Pending orders for a single member (or all when [memberId] is null).
/// Sorted newest-first by `created_at`.
///
/// Copied from [pendingOrders].
class PendingOrdersProvider
    extends AutoDisposeFutureProvider<List<PendingOrderModel>> {
  /// Pending orders for a single member (or all when [memberId] is null).
  /// Sorted newest-first by `created_at`.
  ///
  /// Copied from [pendingOrders].
  PendingOrdersProvider(
    String? memberId,
  ) : this._internal(
          (ref) => pendingOrders(
            ref as PendingOrdersRef,
            memberId,
          ),
          from: pendingOrdersProvider,
          name: r'pendingOrdersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pendingOrdersHash,
          dependencies: PendingOrdersFamily._dependencies,
          allTransitiveDependencies:
              PendingOrdersFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  PendingOrdersProvider._internal(
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
    FutureOr<List<PendingOrderModel>> Function(PendingOrdersRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingOrdersProvider._internal(
        (ref) => create(ref as PendingOrdersRef),
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
  AutoDisposeFutureProviderElement<List<PendingOrderModel>> createElement() {
    return _PendingOrdersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingOrdersProvider && other.memberId == memberId;
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
mixin PendingOrdersRef
    on AutoDisposeFutureProviderRef<List<PendingOrderModel>> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _PendingOrdersProviderElement
    extends AutoDisposeFutureProviderElement<List<PendingOrderModel>>
    with PendingOrdersRef {
  _PendingOrdersProviderElement(super.provider);

  @override
  String? get memberId => (origin as PendingOrdersProvider).memberId;
}

String _$pendingOrdersMutatorHash() =>
    r'4a1be4b1cf8e378b721b8764e94e66f1ded3a0b5';

/// See also [PendingOrdersMutator].
@ProviderFor(PendingOrdersMutator)
final pendingOrdersMutatorProvider =
    AutoDisposeNotifierProvider<PendingOrdersMutator, void>.internal(
  PendingOrdersMutator.new,
  name: r'pendingOrdersMutatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingOrdersMutatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PendingOrdersMutator = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
