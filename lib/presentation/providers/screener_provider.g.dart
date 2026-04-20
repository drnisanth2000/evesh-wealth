// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screener_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$screenerResultsHash() => r'879aa28493a286e5b12669a7f823eea50985ab37';

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

/// Queries the tracked warm-fund universe (via fund_screener_mv) with
/// dynamic filters and sort. Returns up to 100 [ScreenerFundRow]s.
///
/// The materialized view is refreshed nightly and holds only funds with
/// tracked_tier='warm' (~2,000 out of ~14,000 active funds). It is
/// pre-joined, pre-sorted, and column-trimmed so the screener payload
/// is ~1.5 MB instead of the ~25 MB we were shipping from fund_master.
///
/// Cold funds are excluded by default. Users who want to screen across
/// the full universe can opt in by calling [screenerResultsAll] instead
/// (slower, touches fund_master directly). A cold fund that a user
/// actually opens gets promoted to warm automatically by the
/// fetch-fund-ondemand edge function — so power users never miss out
/// on funds they care about.
///
/// Copied from [screenerResults].
@ProviderFor(screenerResults)
const screenerResultsProvider = ScreenerResultsFamily();

/// Queries the tracked warm-fund universe (via fund_screener_mv) with
/// dynamic filters and sort. Returns up to 100 [ScreenerFundRow]s.
///
/// The materialized view is refreshed nightly and holds only funds with
/// tracked_tier='warm' (~2,000 out of ~14,000 active funds). It is
/// pre-joined, pre-sorted, and column-trimmed so the screener payload
/// is ~1.5 MB instead of the ~25 MB we were shipping from fund_master.
///
/// Cold funds are excluded by default. Users who want to screen across
/// the full universe can opt in by calling [screenerResultsAll] instead
/// (slower, touches fund_master directly). A cold fund that a user
/// actually opens gets promoted to warm automatically by the
/// fetch-fund-ondemand edge function — so power users never miss out
/// on funds they care about.
///
/// Copied from [screenerResults].
class ScreenerResultsFamily extends Family<AsyncValue<List<ScreenerFundRow>>> {
  /// Queries the tracked warm-fund universe (via fund_screener_mv) with
  /// dynamic filters and sort. Returns up to 100 [ScreenerFundRow]s.
  ///
  /// The materialized view is refreshed nightly and holds only funds with
  /// tracked_tier='warm' (~2,000 out of ~14,000 active funds). It is
  /// pre-joined, pre-sorted, and column-trimmed so the screener payload
  /// is ~1.5 MB instead of the ~25 MB we were shipping from fund_master.
  ///
  /// Cold funds are excluded by default. Users who want to screen across
  /// the full universe can opt in by calling [screenerResultsAll] instead
  /// (slower, touches fund_master directly). A cold fund that a user
  /// actually opens gets promoted to warm automatically by the
  /// fetch-fund-ondemand edge function — so power users never miss out
  /// on funds they care about.
  ///
  /// Copied from [screenerResults].
  const ScreenerResultsFamily();

  /// Queries the tracked warm-fund universe (via fund_screener_mv) with
  /// dynamic filters and sort. Returns up to 100 [ScreenerFundRow]s.
  ///
  /// The materialized view is refreshed nightly and holds only funds with
  /// tracked_tier='warm' (~2,000 out of ~14,000 active funds). It is
  /// pre-joined, pre-sorted, and column-trimmed so the screener payload
  /// is ~1.5 MB instead of the ~25 MB we were shipping from fund_master.
  ///
  /// Cold funds are excluded by default. Users who want to screen across
  /// the full universe can opt in by calling [screenerResultsAll] instead
  /// (slower, touches fund_master directly). A cold fund that a user
  /// actually opens gets promoted to warm automatically by the
  /// fetch-fund-ondemand edge function — so power users never miss out
  /// on funds they care about.
  ///
  /// Copied from [screenerResults].
  ScreenerResultsProvider call(
    ScreenerFilters filters,
  ) {
    return ScreenerResultsProvider(
      filters,
    );
  }

  @override
  ScreenerResultsProvider getProviderOverride(
    covariant ScreenerResultsProvider provider,
  ) {
    return call(
      provider.filters,
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
  String? get name => r'screenerResultsProvider';
}

/// Queries the tracked warm-fund universe (via fund_screener_mv) with
/// dynamic filters and sort. Returns up to 100 [ScreenerFundRow]s.
///
/// The materialized view is refreshed nightly and holds only funds with
/// tracked_tier='warm' (~2,000 out of ~14,000 active funds). It is
/// pre-joined, pre-sorted, and column-trimmed so the screener payload
/// is ~1.5 MB instead of the ~25 MB we were shipping from fund_master.
///
/// Cold funds are excluded by default. Users who want to screen across
/// the full universe can opt in by calling [screenerResultsAll] instead
/// (slower, touches fund_master directly). A cold fund that a user
/// actually opens gets promoted to warm automatically by the
/// fetch-fund-ondemand edge function — so power users never miss out
/// on funds they care about.
///
/// Copied from [screenerResults].
class ScreenerResultsProvider
    extends AutoDisposeFutureProvider<List<ScreenerFundRow>> {
  /// Queries the tracked warm-fund universe (via fund_screener_mv) with
  /// dynamic filters and sort. Returns up to 100 [ScreenerFundRow]s.
  ///
  /// The materialized view is refreshed nightly and holds only funds with
  /// tracked_tier='warm' (~2,000 out of ~14,000 active funds). It is
  /// pre-joined, pre-sorted, and column-trimmed so the screener payload
  /// is ~1.5 MB instead of the ~25 MB we were shipping from fund_master.
  ///
  /// Cold funds are excluded by default. Users who want to screen across
  /// the full universe can opt in by calling [screenerResultsAll] instead
  /// (slower, touches fund_master directly). A cold fund that a user
  /// actually opens gets promoted to warm automatically by the
  /// fetch-fund-ondemand edge function — so power users never miss out
  /// on funds they care about.
  ///
  /// Copied from [screenerResults].
  ScreenerResultsProvider(
    ScreenerFilters filters,
  ) : this._internal(
          (ref) => screenerResults(
            ref as ScreenerResultsRef,
            filters,
          ),
          from: screenerResultsProvider,
          name: r'screenerResultsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$screenerResultsHash,
          dependencies: ScreenerResultsFamily._dependencies,
          allTransitiveDependencies:
              ScreenerResultsFamily._allTransitiveDependencies,
          filters: filters,
        );

  ScreenerResultsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.filters,
  }) : super.internal();

  final ScreenerFilters filters;

  @override
  Override overrideWith(
    FutureOr<List<ScreenerFundRow>> Function(ScreenerResultsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScreenerResultsProvider._internal(
        (ref) => create(ref as ScreenerResultsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        filters: filters,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ScreenerFundRow>> createElement() {
    return _ScreenerResultsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScreenerResultsProvider && other.filters == filters;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, filters.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ScreenerResultsRef
    on AutoDisposeFutureProviderRef<List<ScreenerFundRow>> {
  /// The parameter `filters` of this provider.
  ScreenerFilters get filters;
}

class _ScreenerResultsProviderElement
    extends AutoDisposeFutureProviderElement<List<ScreenerFundRow>>
    with ScreenerResultsRef {
  _ScreenerResultsProviderElement(super.provider);

  @override
  ScreenerFilters get filters => (origin as ScreenerResultsProvider).filters;
}

String _$screenerResultsAllHash() =>
    r'2eb870e858142d2f141dde09be65295aa268e915';

/// Escape-hatch: query the full fund_master universe (not just warm set).
/// Slower — used only when the user explicitly toggles "Show all funds"
/// in the screener. Same filter chain as [screenerResults] but hits the
/// raw table and keeps the is_active predicate.
///
/// Copied from [screenerResultsAll].
@ProviderFor(screenerResultsAll)
const screenerResultsAllProvider = ScreenerResultsAllFamily();

/// Escape-hatch: query the full fund_master universe (not just warm set).
/// Slower — used only when the user explicitly toggles "Show all funds"
/// in the screener. Same filter chain as [screenerResults] but hits the
/// raw table and keeps the is_active predicate.
///
/// Copied from [screenerResultsAll].
class ScreenerResultsAllFamily
    extends Family<AsyncValue<List<ScreenerFundRow>>> {
  /// Escape-hatch: query the full fund_master universe (not just warm set).
  /// Slower — used only when the user explicitly toggles "Show all funds"
  /// in the screener. Same filter chain as [screenerResults] but hits the
  /// raw table and keeps the is_active predicate.
  ///
  /// Copied from [screenerResultsAll].
  const ScreenerResultsAllFamily();

  /// Escape-hatch: query the full fund_master universe (not just warm set).
  /// Slower — used only when the user explicitly toggles "Show all funds"
  /// in the screener. Same filter chain as [screenerResults] but hits the
  /// raw table and keeps the is_active predicate.
  ///
  /// Copied from [screenerResultsAll].
  ScreenerResultsAllProvider call(
    ScreenerFilters filters,
  ) {
    return ScreenerResultsAllProvider(
      filters,
    );
  }

  @override
  ScreenerResultsAllProvider getProviderOverride(
    covariant ScreenerResultsAllProvider provider,
  ) {
    return call(
      provider.filters,
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
  String? get name => r'screenerResultsAllProvider';
}

/// Escape-hatch: query the full fund_master universe (not just warm set).
/// Slower — used only when the user explicitly toggles "Show all funds"
/// in the screener. Same filter chain as [screenerResults] but hits the
/// raw table and keeps the is_active predicate.
///
/// Copied from [screenerResultsAll].
class ScreenerResultsAllProvider
    extends AutoDisposeFutureProvider<List<ScreenerFundRow>> {
  /// Escape-hatch: query the full fund_master universe (not just warm set).
  /// Slower — used only when the user explicitly toggles "Show all funds"
  /// in the screener. Same filter chain as [screenerResults] but hits the
  /// raw table and keeps the is_active predicate.
  ///
  /// Copied from [screenerResultsAll].
  ScreenerResultsAllProvider(
    ScreenerFilters filters,
  ) : this._internal(
          (ref) => screenerResultsAll(
            ref as ScreenerResultsAllRef,
            filters,
          ),
          from: screenerResultsAllProvider,
          name: r'screenerResultsAllProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$screenerResultsAllHash,
          dependencies: ScreenerResultsAllFamily._dependencies,
          allTransitiveDependencies:
              ScreenerResultsAllFamily._allTransitiveDependencies,
          filters: filters,
        );

  ScreenerResultsAllProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.filters,
  }) : super.internal();

  final ScreenerFilters filters;

  @override
  Override overrideWith(
    FutureOr<List<ScreenerFundRow>> Function(ScreenerResultsAllRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScreenerResultsAllProvider._internal(
        (ref) => create(ref as ScreenerResultsAllRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        filters: filters,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ScreenerFundRow>> createElement() {
    return _ScreenerResultsAllProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScreenerResultsAllProvider && other.filters == filters;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, filters.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ScreenerResultsAllRef
    on AutoDisposeFutureProviderRef<List<ScreenerFundRow>> {
  /// The parameter `filters` of this provider.
  ScreenerFilters get filters;
}

class _ScreenerResultsAllProviderElement
    extends AutoDisposeFutureProviderElement<List<ScreenerFundRow>>
    with ScreenerResultsAllRef {
  _ScreenerResultsAllProviderElement(super.provider);

  @override
  ScreenerFilters get filters => (origin as ScreenerResultsAllProvider).filters;
}

String _$amcListHash() => r'2417eb56d96ce3eef28c2d15c8e9f5492bcb78f8';

/// Distinct AMC names for filter dropdown — scoped to the warm universe
/// (so the dropdown matches what the screener actually returns).
///
/// Copied from [amcList].
@ProviderFor(amcList)
final amcListProvider = AutoDisposeFutureProvider<List<String>>.internal(
  amcList,
  name: r'amcListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$amcListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AmcListRef = AutoDisposeFutureProviderRef<List<String>>;
String _$categoryListHash() => r'd378676bf5afc925286d31cd7be18c8079e7bd8b';

/// Distinct categories for filter dropdown — scoped to warm universe.
///
/// Copied from [categoryList].
@ProviderFor(categoryList)
final categoryListProvider = AutoDisposeFutureProvider<List<String>>.internal(
  categoryList,
  name: r'categoryListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$categoryListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CategoryListRef = AutoDisposeFutureProviderRef<List<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
