// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overlap_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fundHoldingsCacheHash() => r'7de910e589fb7193ff33f4498279f89a481424b3';

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

/// See also [fundHoldingsCache].
@ProviderFor(fundHoldingsCache)
const fundHoldingsCacheProvider = FundHoldingsCacheFamily();

/// See also [fundHoldingsCache].
class FundHoldingsCacheFamily
    extends Family<AsyncValue<List<CachedFundHolding>>> {
  /// See also [fundHoldingsCache].
  const FundHoldingsCacheFamily();

  /// See also [fundHoldingsCache].
  FundHoldingsCacheProvider call(
    int amfiCode,
  ) {
    return FundHoldingsCacheProvider(
      amfiCode,
    );
  }

  @override
  FundHoldingsCacheProvider getProviderOverride(
    covariant FundHoldingsCacheProvider provider,
  ) {
    return call(
      provider.amfiCode,
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
  String? get name => r'fundHoldingsCacheProvider';
}

/// See also [fundHoldingsCache].
class FundHoldingsCacheProvider
    extends AutoDisposeFutureProvider<List<CachedFundHolding>> {
  /// See also [fundHoldingsCache].
  FundHoldingsCacheProvider(
    int amfiCode,
  ) : this._internal(
          (ref) => fundHoldingsCache(
            ref as FundHoldingsCacheRef,
            amfiCode,
          ),
          from: fundHoldingsCacheProvider,
          name: r'fundHoldingsCacheProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fundHoldingsCacheHash,
          dependencies: FundHoldingsCacheFamily._dependencies,
          allTransitiveDependencies:
              FundHoldingsCacheFamily._allTransitiveDependencies,
          amfiCode: amfiCode,
        );

  FundHoldingsCacheProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.amfiCode,
  }) : super.internal();

  final int amfiCode;

  @override
  Override overrideWith(
    FutureOr<List<CachedFundHolding>> Function(FundHoldingsCacheRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FundHoldingsCacheProvider._internal(
        (ref) => create(ref as FundHoldingsCacheRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        amfiCode: amfiCode,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<CachedFundHolding>> createElement() {
    return _FundHoldingsCacheProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FundHoldingsCacheProvider && other.amfiCode == amfiCode;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, amfiCode.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FundHoldingsCacheRef
    on AutoDisposeFutureProviderRef<List<CachedFundHolding>> {
  /// The parameter `amfiCode` of this provider.
  int get amfiCode;
}

class _FundHoldingsCacheProviderElement
    extends AutoDisposeFutureProviderElement<List<CachedFundHolding>>
    with FundHoldingsCacheRef {
  _FundHoldingsCacheProviderElement(super.provider);

  @override
  int get amfiCode => (origin as FundHoldingsCacheProvider).amfiCode;
}

String _$isHoldingsCacheStaleHash() =>
    r'74854c66082e57fe6733ba78f811d5db3fbd78d6';

/// See also [isHoldingsCacheStale].
@ProviderFor(isHoldingsCacheStale)
const isHoldingsCacheStaleProvider = IsHoldingsCacheStaleFamily();

/// See also [isHoldingsCacheStale].
class IsHoldingsCacheStaleFamily extends Family<AsyncValue<bool>> {
  /// See also [isHoldingsCacheStale].
  const IsHoldingsCacheStaleFamily();

  /// See also [isHoldingsCacheStale].
  IsHoldingsCacheStaleProvider call(
    int amfiCode,
  ) {
    return IsHoldingsCacheStaleProvider(
      amfiCode,
    );
  }

  @override
  IsHoldingsCacheStaleProvider getProviderOverride(
    covariant IsHoldingsCacheStaleProvider provider,
  ) {
    return call(
      provider.amfiCode,
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
  String? get name => r'isHoldingsCacheStaleProvider';
}

/// See also [isHoldingsCacheStale].
class IsHoldingsCacheStaleProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [isHoldingsCacheStale].
  IsHoldingsCacheStaleProvider(
    int amfiCode,
  ) : this._internal(
          (ref) => isHoldingsCacheStale(
            ref as IsHoldingsCacheStaleRef,
            amfiCode,
          ),
          from: isHoldingsCacheStaleProvider,
          name: r'isHoldingsCacheStaleProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isHoldingsCacheStaleHash,
          dependencies: IsHoldingsCacheStaleFamily._dependencies,
          allTransitiveDependencies:
              IsHoldingsCacheStaleFamily._allTransitiveDependencies,
          amfiCode: amfiCode,
        );

  IsHoldingsCacheStaleProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.amfiCode,
  }) : super.internal();

  final int amfiCode;

  @override
  Override overrideWith(
    FutureOr<bool> Function(IsHoldingsCacheStaleRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsHoldingsCacheStaleProvider._internal(
        (ref) => create(ref as IsHoldingsCacheStaleRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        amfiCode: amfiCode,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsHoldingsCacheStaleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsHoldingsCacheStaleProvider && other.amfiCode == amfiCode;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, amfiCode.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsHoldingsCacheStaleRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `amfiCode` of this provider.
  int get amfiCode;
}

class _IsHoldingsCacheStaleProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with IsHoldingsCacheStaleRef {
  _IsHoldingsCacheStaleProviderElement(super.provider);

  @override
  int get amfiCode => (origin as IsHoldingsCacheStaleProvider).amfiCode;
}

String _$portfolioHoldingsHash() => r'bf529ef15ef8e679b092e6193d337583e2318fc3';

/// See also [portfolioHoldings].
@ProviderFor(portfolioHoldings)
const portfolioHoldingsProvider = PortfolioHoldingsFamily();

/// See also [portfolioHoldings].
class PortfolioHoldingsFamily
    extends Family<AsyncValue<List<FundWithHoldings>>> {
  /// See also [portfolioHoldings].
  const PortfolioHoldingsFamily();

  /// See also [portfolioHoldings].
  PortfolioHoldingsProvider call(
    String? memberId,
  ) {
    return PortfolioHoldingsProvider(
      memberId,
    );
  }

  @override
  PortfolioHoldingsProvider getProviderOverride(
    covariant PortfolioHoldingsProvider provider,
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
  String? get name => r'portfolioHoldingsProvider';
}

/// See also [portfolioHoldings].
class PortfolioHoldingsProvider
    extends AutoDisposeFutureProvider<List<FundWithHoldings>> {
  /// See also [portfolioHoldings].
  PortfolioHoldingsProvider(
    String? memberId,
  ) : this._internal(
          (ref) => portfolioHoldings(
            ref as PortfolioHoldingsRef,
            memberId,
          ),
          from: portfolioHoldingsProvider,
          name: r'portfolioHoldingsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$portfolioHoldingsHash,
          dependencies: PortfolioHoldingsFamily._dependencies,
          allTransitiveDependencies:
              PortfolioHoldingsFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  PortfolioHoldingsProvider._internal(
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
    FutureOr<List<FundWithHoldings>> Function(PortfolioHoldingsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PortfolioHoldingsProvider._internal(
        (ref) => create(ref as PortfolioHoldingsRef),
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
  AutoDisposeFutureProviderElement<List<FundWithHoldings>> createElement() {
    return _PortfolioHoldingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PortfolioHoldingsProvider && other.memberId == memberId;
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
mixin PortfolioHoldingsRef
    on AutoDisposeFutureProviderRef<List<FundWithHoldings>> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _PortfolioHoldingsProviderElement
    extends AutoDisposeFutureProviderElement<List<FundWithHoldings>>
    with PortfolioHoldingsRef {
  _PortfolioHoldingsProviderElement(super.provider);

  @override
  String? get memberId => (origin as PortfolioHoldingsProvider).memberId;
}

String _$candidateFundHoldingsHash() =>
    r'238dc2a055bd1d9c48c431b256a419c8c9db78c2';

/// See also [candidateFundHoldings].
@ProviderFor(candidateFundHoldings)
const candidateFundHoldingsProvider = CandidateFundHoldingsFamily();

/// See also [candidateFundHoldings].
class CandidateFundHoldingsFamily
    extends Family<AsyncValue<FundWithHoldings?>> {
  /// See also [candidateFundHoldings].
  const CandidateFundHoldingsFamily();

  /// See also [candidateFundHoldings].
  CandidateFundHoldingsProvider call(
    int amfiCode,
    String fundName,
  ) {
    return CandidateFundHoldingsProvider(
      amfiCode,
      fundName,
    );
  }

  @override
  CandidateFundHoldingsProvider getProviderOverride(
    covariant CandidateFundHoldingsProvider provider,
  ) {
    return call(
      provider.amfiCode,
      provider.fundName,
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
  String? get name => r'candidateFundHoldingsProvider';
}

/// See also [candidateFundHoldings].
class CandidateFundHoldingsProvider
    extends AutoDisposeFutureProvider<FundWithHoldings?> {
  /// See also [candidateFundHoldings].
  CandidateFundHoldingsProvider(
    int amfiCode,
    String fundName,
  ) : this._internal(
          (ref) => candidateFundHoldings(
            ref as CandidateFundHoldingsRef,
            amfiCode,
            fundName,
          ),
          from: candidateFundHoldingsProvider,
          name: r'candidateFundHoldingsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$candidateFundHoldingsHash,
          dependencies: CandidateFundHoldingsFamily._dependencies,
          allTransitiveDependencies:
              CandidateFundHoldingsFamily._allTransitiveDependencies,
          amfiCode: amfiCode,
          fundName: fundName,
        );

  CandidateFundHoldingsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.amfiCode,
    required this.fundName,
  }) : super.internal();

  final int amfiCode;
  final String fundName;

  @override
  Override overrideWith(
    FutureOr<FundWithHoldings?> Function(CandidateFundHoldingsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CandidateFundHoldingsProvider._internal(
        (ref) => create(ref as CandidateFundHoldingsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        amfiCode: amfiCode,
        fundName: fundName,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<FundWithHoldings?> createElement() {
    return _CandidateFundHoldingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CandidateFundHoldingsProvider &&
        other.amfiCode == amfiCode &&
        other.fundName == fundName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, amfiCode.hashCode);
    hash = _SystemHash.combine(hash, fundName.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CandidateFundHoldingsRef
    on AutoDisposeFutureProviderRef<FundWithHoldings?> {
  /// The parameter `amfiCode` of this provider.
  int get amfiCode;

  /// The parameter `fundName` of this provider.
  String get fundName;
}

class _CandidateFundHoldingsProviderElement
    extends AutoDisposeFutureProviderElement<FundWithHoldings?>
    with CandidateFundHoldingsRef {
  _CandidateFundHoldingsProviderElement(super.provider);

  @override
  int get amfiCode => (origin as CandidateFundHoldingsProvider).amfiCode;
  @override
  String get fundName => (origin as CandidateFundHoldingsProvider).fundName;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
