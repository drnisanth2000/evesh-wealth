// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watchlist_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$watchlistRulesHash() => r'9b722ee6d85f6eedef7c38202b6f7b5180bb1e76';

/// Fetches all watchlist rules for the current user.
///
/// Copied from [watchlistRules].
@ProviderFor(watchlistRules)
final watchlistRulesProvider =
    AutoDisposeFutureProvider<List<WatchlistRuleModel>>.internal(
  watchlistRules,
  name: r'watchlistRulesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$watchlistRulesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WatchlistRulesRef
    = AutoDisposeFutureProviderRef<List<WatchlistRuleModel>>;
String _$fundWatchlistRulesHash() =>
    r'b705be8f6e42701858044c596a1259be1d372ed7';

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

/// Fetches watchlist rules for a specific fund.
///
/// Copied from [fundWatchlistRules].
@ProviderFor(fundWatchlistRules)
const fundWatchlistRulesProvider = FundWatchlistRulesFamily();

/// Fetches watchlist rules for a specific fund.
///
/// Copied from [fundWatchlistRules].
class FundWatchlistRulesFamily
    extends Family<AsyncValue<List<WatchlistRuleModel>>> {
  /// Fetches watchlist rules for a specific fund.
  ///
  /// Copied from [fundWatchlistRules].
  const FundWatchlistRulesFamily();

  /// Fetches watchlist rules for a specific fund.
  ///
  /// Copied from [fundWatchlistRules].
  FundWatchlistRulesProvider call(
    int amfiCode,
  ) {
    return FundWatchlistRulesProvider(
      amfiCode,
    );
  }

  @override
  FundWatchlistRulesProvider getProviderOverride(
    covariant FundWatchlistRulesProvider provider,
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
  String? get name => r'fundWatchlistRulesProvider';
}

/// Fetches watchlist rules for a specific fund.
///
/// Copied from [fundWatchlistRules].
class FundWatchlistRulesProvider
    extends AutoDisposeFutureProvider<List<WatchlistRuleModel>> {
  /// Fetches watchlist rules for a specific fund.
  ///
  /// Copied from [fundWatchlistRules].
  FundWatchlistRulesProvider(
    int amfiCode,
  ) : this._internal(
          (ref) => fundWatchlistRules(
            ref as FundWatchlistRulesRef,
            amfiCode,
          ),
          from: fundWatchlistRulesProvider,
          name: r'fundWatchlistRulesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fundWatchlistRulesHash,
          dependencies: FundWatchlistRulesFamily._dependencies,
          allTransitiveDependencies:
              FundWatchlistRulesFamily._allTransitiveDependencies,
          amfiCode: amfiCode,
        );

  FundWatchlistRulesProvider._internal(
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
    FutureOr<List<WatchlistRuleModel>> Function(FundWatchlistRulesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FundWatchlistRulesProvider._internal(
        (ref) => create(ref as FundWatchlistRulesRef),
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
  AutoDisposeFutureProviderElement<List<WatchlistRuleModel>> createElement() {
    return _FundWatchlistRulesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FundWatchlistRulesProvider && other.amfiCode == amfiCode;
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
mixin FundWatchlistRulesRef
    on AutoDisposeFutureProviderRef<List<WatchlistRuleModel>> {
  /// The parameter `amfiCode` of this provider.
  int get amfiCode;
}

class _FundWatchlistRulesProviderElement
    extends AutoDisposeFutureProviderElement<List<WatchlistRuleModel>>
    with FundWatchlistRulesRef {
  _FundWatchlistRulesProviderElement(super.provider);

  @override
  int get amfiCode => (origin as FundWatchlistRulesProvider).amfiCode;
}

String _$watchlistNavMapHash() => r'6c0911e534d08949debf78cf233bf341e1793fb0';

/// Fetches current NAV for a list of amfi codes (for status display).
///
/// Copied from [watchlistNavMap].
@ProviderFor(watchlistNavMap)
final watchlistNavMapProvider =
    AutoDisposeFutureProvider<Map<int, double>>.internal(
  watchlistNavMap,
  name: r'watchlistNavMapProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$watchlistNavMapHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WatchlistNavMapRef = AutoDisposeFutureProviderRef<Map<int, double>>;
String _$watchlistNotifierHash() => r'875630128d2fa595e4ec0a794f18dc4d535d6721';

/// Notifier for CRUD operations on watchlist rules.
///
/// Copied from [WatchlistNotifier].
@ProviderFor(WatchlistNotifier)
final watchlistNotifierProvider =
    AutoDisposeAsyncNotifierProvider<WatchlistNotifier, void>.internal(
  WatchlistNotifier.new,
  name: r'watchlistNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$watchlistNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WatchlistNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
