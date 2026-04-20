// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allTransactionsHash() => r'd079b787d0091153e56f7b2c0ac65cccb5a3d491';

/// See also [allTransactions].
@ProviderFor(allTransactions)
final allTransactionsProvider =
    AutoDisposeFutureProvider<List<TransactionModel>>.internal(
  allTransactions,
  name: r'allTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllTransactionsRef
    = AutoDisposeFutureProviderRef<List<TransactionModel>>;
String _$latestNavMapHash() => r'64dfb17479c78ab310d5ae233708e9622fa9e600';

/// See also [latestNavMap].
@ProviderFor(latestNavMap)
final latestNavMapProvider =
    AutoDisposeFutureProvider<Map<int, double>>.internal(
  latestNavMap,
  name: r'latestNavMapProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$latestNavMapHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LatestNavMapRef = AutoDisposeFutureProviderRef<Map<int, double>>;
String _$portfolioSummaryHash() => r'0e805f38b1b3625bb4082225bc691cd6bd04c19d';

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

/// See also [portfolioSummary].
@ProviderFor(portfolioSummary)
const portfolioSummaryProvider = PortfolioSummaryFamily();

/// See also [portfolioSummary].
class PortfolioSummaryFamily extends Family<AsyncValue<PortfolioSummary>> {
  /// See also [portfolioSummary].
  const PortfolioSummaryFamily();

  /// See also [portfolioSummary].
  PortfolioSummaryProvider call(
    String? memberId,
  ) {
    return PortfolioSummaryProvider(
      memberId,
    );
  }

  @override
  PortfolioSummaryProvider getProviderOverride(
    covariant PortfolioSummaryProvider provider,
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
  String? get name => r'portfolioSummaryProvider';
}

/// See also [portfolioSummary].
class PortfolioSummaryProvider
    extends AutoDisposeFutureProvider<PortfolioSummary> {
  /// See also [portfolioSummary].
  PortfolioSummaryProvider(
    String? memberId,
  ) : this._internal(
          (ref) => portfolioSummary(
            ref as PortfolioSummaryRef,
            memberId,
          ),
          from: portfolioSummaryProvider,
          name: r'portfolioSummaryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$portfolioSummaryHash,
          dependencies: PortfolioSummaryFamily._dependencies,
          allTransitiveDependencies:
              PortfolioSummaryFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  PortfolioSummaryProvider._internal(
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
    FutureOr<PortfolioSummary> Function(PortfolioSummaryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PortfolioSummaryProvider._internal(
        (ref) => create(ref as PortfolioSummaryRef),
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
  AutoDisposeFutureProviderElement<PortfolioSummary> createElement() {
    return _PortfolioSummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PortfolioSummaryProvider && other.memberId == memberId;
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
mixin PortfolioSummaryRef on AutoDisposeFutureProviderRef<PortfolioSummary> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _PortfolioSummaryProviderElement
    extends AutoDisposeFutureProviderElement<PortfolioSummary>
    with PortfolioSummaryRef {
  _PortfolioSummaryProviderElement(super.provider);

  @override
  String? get memberId => (origin as PortfolioSummaryProvider).memberId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
