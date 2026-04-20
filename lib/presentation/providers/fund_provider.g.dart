// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fundSearchHash() => r'612f1dfc91d17b9a57b3fc97dba1c9d7c972f7d1';

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

/// Trigram search over fund_master — returns up to 20 matches.
///
/// Copied from [fundSearch].
@ProviderFor(fundSearch)
const fundSearchProvider = FundSearchFamily();

/// Trigram search over fund_master — returns up to 20 matches.
///
/// Copied from [fundSearch].
class FundSearchFamily extends Family<AsyncValue<List<FundModel>>> {
  /// Trigram search over fund_master — returns up to 20 matches.
  ///
  /// Copied from [fundSearch].
  const FundSearchFamily();

  /// Trigram search over fund_master — returns up to 20 matches.
  ///
  /// Copied from [fundSearch].
  FundSearchProvider call(
    String query,
  ) {
    return FundSearchProvider(
      query,
    );
  }

  @override
  FundSearchProvider getProviderOverride(
    covariant FundSearchProvider provider,
  ) {
    return call(
      provider.query,
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
  String? get name => r'fundSearchProvider';
}

/// Trigram search over fund_master — returns up to 20 matches.
///
/// Copied from [fundSearch].
class FundSearchProvider extends AutoDisposeFutureProvider<List<FundModel>> {
  /// Trigram search over fund_master — returns up to 20 matches.
  ///
  /// Copied from [fundSearch].
  FundSearchProvider(
    String query,
  ) : this._internal(
          (ref) => fundSearch(
            ref as FundSearchRef,
            query,
          ),
          from: fundSearchProvider,
          name: r'fundSearchProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fundSearchHash,
          dependencies: FundSearchFamily._dependencies,
          allTransitiveDependencies:
              FundSearchFamily._allTransitiveDependencies,
          query: query,
        );

  FundSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<FundModel>> Function(FundSearchRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FundSearchProvider._internal(
        (ref) => create(ref as FundSearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<FundModel>> createElement() {
    return _FundSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FundSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FundSearchRef on AutoDisposeFutureProviderRef<List<FundModel>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _FundSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<FundModel>>
    with FundSearchRef {
  _FundSearchProviderElement(super.provider);

  @override
  String get query => (origin as FundSearchProvider).query;
}

String _$fundDetailHash() => r'029a937b8e7fc51211269bbd1664232bd29bf767';

/// Full details for a single fund by amfi_code.
///
/// If the fund is in the cold tier (i.e. not in our daily-refresh warm
/// universe), fire-and-forget a call to `fetch-fund-ondemand`. That
/// edge function pulls 400 days of NAV history from mfapi.in, upserts
/// into nav_history, recomputes short-window returns, and flips the
/// fund to warm with a 30-day sticky window — so the next visit (and
/// every visit for a month) will be instant.
///
/// We do NOT await the promotion: the UI renders the currently-known
/// fund_master row immediately and a RefreshIndicator pull will pick up
/// the freshly-populated values. This keeps cold-fund detail loads
/// snappy and prevents a slow mfapi.in call from blocking the page.
///
/// Copied from [fundDetail].
@ProviderFor(fundDetail)
const fundDetailProvider = FundDetailFamily();

/// Full details for a single fund by amfi_code.
///
/// If the fund is in the cold tier (i.e. not in our daily-refresh warm
/// universe), fire-and-forget a call to `fetch-fund-ondemand`. That
/// edge function pulls 400 days of NAV history from mfapi.in, upserts
/// into nav_history, recomputes short-window returns, and flips the
/// fund to warm with a 30-day sticky window — so the next visit (and
/// every visit for a month) will be instant.
///
/// We do NOT await the promotion: the UI renders the currently-known
/// fund_master row immediately and a RefreshIndicator pull will pick up
/// the freshly-populated values. This keeps cold-fund detail loads
/// snappy and prevents a slow mfapi.in call from blocking the page.
///
/// Copied from [fundDetail].
class FundDetailFamily extends Family<AsyncValue<FundModel?>> {
  /// Full details for a single fund by amfi_code.
  ///
  /// If the fund is in the cold tier (i.e. not in our daily-refresh warm
  /// universe), fire-and-forget a call to `fetch-fund-ondemand`. That
  /// edge function pulls 400 days of NAV history from mfapi.in, upserts
  /// into nav_history, recomputes short-window returns, and flips the
  /// fund to warm with a 30-day sticky window — so the next visit (and
  /// every visit for a month) will be instant.
  ///
  /// We do NOT await the promotion: the UI renders the currently-known
  /// fund_master row immediately and a RefreshIndicator pull will pick up
  /// the freshly-populated values. This keeps cold-fund detail loads
  /// snappy and prevents a slow mfapi.in call from blocking the page.
  ///
  /// Copied from [fundDetail].
  const FundDetailFamily();

  /// Full details for a single fund by amfi_code.
  ///
  /// If the fund is in the cold tier (i.e. not in our daily-refresh warm
  /// universe), fire-and-forget a call to `fetch-fund-ondemand`. That
  /// edge function pulls 400 days of NAV history from mfapi.in, upserts
  /// into nav_history, recomputes short-window returns, and flips the
  /// fund to warm with a 30-day sticky window — so the next visit (and
  /// every visit for a month) will be instant.
  ///
  /// We do NOT await the promotion: the UI renders the currently-known
  /// fund_master row immediately and a RefreshIndicator pull will pick up
  /// the freshly-populated values. This keeps cold-fund detail loads
  /// snappy and prevents a slow mfapi.in call from blocking the page.
  ///
  /// Copied from [fundDetail].
  FundDetailProvider call(
    int amfiCode,
  ) {
    return FundDetailProvider(
      amfiCode,
    );
  }

  @override
  FundDetailProvider getProviderOverride(
    covariant FundDetailProvider provider,
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
  String? get name => r'fundDetailProvider';
}

/// Full details for a single fund by amfi_code.
///
/// If the fund is in the cold tier (i.e. not in our daily-refresh warm
/// universe), fire-and-forget a call to `fetch-fund-ondemand`. That
/// edge function pulls 400 days of NAV history from mfapi.in, upserts
/// into nav_history, recomputes short-window returns, and flips the
/// fund to warm with a 30-day sticky window — so the next visit (and
/// every visit for a month) will be instant.
///
/// We do NOT await the promotion: the UI renders the currently-known
/// fund_master row immediately and a RefreshIndicator pull will pick up
/// the freshly-populated values. This keeps cold-fund detail loads
/// snappy and prevents a slow mfapi.in call from blocking the page.
///
/// Copied from [fundDetail].
class FundDetailProvider extends AutoDisposeFutureProvider<FundModel?> {
  /// Full details for a single fund by amfi_code.
  ///
  /// If the fund is in the cold tier (i.e. not in our daily-refresh warm
  /// universe), fire-and-forget a call to `fetch-fund-ondemand`. That
  /// edge function pulls 400 days of NAV history from mfapi.in, upserts
  /// into nav_history, recomputes short-window returns, and flips the
  /// fund to warm with a 30-day sticky window — so the next visit (and
  /// every visit for a month) will be instant.
  ///
  /// We do NOT await the promotion: the UI renders the currently-known
  /// fund_master row immediately and a RefreshIndicator pull will pick up
  /// the freshly-populated values. This keeps cold-fund detail loads
  /// snappy and prevents a slow mfapi.in call from blocking the page.
  ///
  /// Copied from [fundDetail].
  FundDetailProvider(
    int amfiCode,
  ) : this._internal(
          (ref) => fundDetail(
            ref as FundDetailRef,
            amfiCode,
          ),
          from: fundDetailProvider,
          name: r'fundDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fundDetailHash,
          dependencies: FundDetailFamily._dependencies,
          allTransitiveDependencies:
              FundDetailFamily._allTransitiveDependencies,
          amfiCode: amfiCode,
        );

  FundDetailProvider._internal(
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
    FutureOr<FundModel?> Function(FundDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FundDetailProvider._internal(
        (ref) => create(ref as FundDetailRef),
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
  AutoDisposeFutureProviderElement<FundModel?> createElement() {
    return _FundDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FundDetailProvider && other.amfiCode == amfiCode;
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
mixin FundDetailRef on AutoDisposeFutureProviderRef<FundModel?> {
  /// The parameter `amfiCode` of this provider.
  int get amfiCode;
}

class _FundDetailProviderElement
    extends AutoDisposeFutureProviderElement<FundModel?> with FundDetailRef {
  _FundDetailProviderElement(super.provider);

  @override
  int get amfiCode => (origin as FundDetailProvider).amfiCode;
}

String _$fundPrewarmBatchHash() => r'7ef34a8f583a91395e646b028897474d6126ffe7';

/// Background pre-warm trigger. Call this from a screener / research
/// screen after it finishes painting to idle-fetch a small batch of
/// cold funds grouped by AMC. Safe to call repeatedly — each call picks
/// a fresh batch and returns quickly (~25-40s in the background worker,
/// but the future resolves as soon as the edge function returns, which
/// is typically within 5 seconds since it pipelines mfapi fetches).
///
/// Returns the number of funds successfully fetched, or 0 on error.
///
/// Copied from [fundPrewarmBatch].
@ProviderFor(fundPrewarmBatch)
const fundPrewarmBatchProvider = FundPrewarmBatchFamily();

/// Background pre-warm trigger. Call this from a screener / research
/// screen after it finishes painting to idle-fetch a small batch of
/// cold funds grouped by AMC. Safe to call repeatedly — each call picks
/// a fresh batch and returns quickly (~25-40s in the background worker,
/// but the future resolves as soon as the edge function returns, which
/// is typically within 5 seconds since it pipelines mfapi fetches).
///
/// Returns the number of funds successfully fetched, or 0 on error.
///
/// Copied from [fundPrewarmBatch].
class FundPrewarmBatchFamily extends Family<AsyncValue<int>> {
  /// Background pre-warm trigger. Call this from a screener / research
  /// screen after it finishes painting to idle-fetch a small batch of
  /// cold funds grouped by AMC. Safe to call repeatedly — each call picks
  /// a fresh batch and returns quickly (~25-40s in the background worker,
  /// but the future resolves as soon as the edge function returns, which
  /// is typically within 5 seconds since it pipelines mfapi fetches).
  ///
  /// Returns the number of funds successfully fetched, or 0 on error.
  ///
  /// Copied from [fundPrewarmBatch].
  const FundPrewarmBatchFamily();

  /// Background pre-warm trigger. Call this from a screener / research
  /// screen after it finishes painting to idle-fetch a small batch of
  /// cold funds grouped by AMC. Safe to call repeatedly — each call picks
  /// a fresh batch and returns quickly (~25-40s in the background worker,
  /// but the future resolves as soon as the edge function returns, which
  /// is typically within 5 seconds since it pipelines mfapi fetches).
  ///
  /// Returns the number of funds successfully fetched, or 0 on error.
  ///
  /// Copied from [fundPrewarmBatch].
  FundPrewarmBatchProvider call({
    int limit = 30,
    int perAmc = 3,
  }) {
    return FundPrewarmBatchProvider(
      limit: limit,
      perAmc: perAmc,
    );
  }

  @override
  FundPrewarmBatchProvider getProviderOverride(
    covariant FundPrewarmBatchProvider provider,
  ) {
    return call(
      limit: provider.limit,
      perAmc: provider.perAmc,
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
  String? get name => r'fundPrewarmBatchProvider';
}

/// Background pre-warm trigger. Call this from a screener / research
/// screen after it finishes painting to idle-fetch a small batch of
/// cold funds grouped by AMC. Safe to call repeatedly — each call picks
/// a fresh batch and returns quickly (~25-40s in the background worker,
/// but the future resolves as soon as the edge function returns, which
/// is typically within 5 seconds since it pipelines mfapi fetches).
///
/// Returns the number of funds successfully fetched, or 0 on error.
///
/// Copied from [fundPrewarmBatch].
class FundPrewarmBatchProvider extends AutoDisposeFutureProvider<int> {
  /// Background pre-warm trigger. Call this from a screener / research
  /// screen after it finishes painting to idle-fetch a small batch of
  /// cold funds grouped by AMC. Safe to call repeatedly — each call picks
  /// a fresh batch and returns quickly (~25-40s in the background worker,
  /// but the future resolves as soon as the edge function returns, which
  /// is typically within 5 seconds since it pipelines mfapi fetches).
  ///
  /// Returns the number of funds successfully fetched, or 0 on error.
  ///
  /// Copied from [fundPrewarmBatch].
  FundPrewarmBatchProvider({
    int limit = 30,
    int perAmc = 3,
  }) : this._internal(
          (ref) => fundPrewarmBatch(
            ref as FundPrewarmBatchRef,
            limit: limit,
            perAmc: perAmc,
          ),
          from: fundPrewarmBatchProvider,
          name: r'fundPrewarmBatchProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fundPrewarmBatchHash,
          dependencies: FundPrewarmBatchFamily._dependencies,
          allTransitiveDependencies:
              FundPrewarmBatchFamily._allTransitiveDependencies,
          limit: limit,
          perAmc: perAmc,
        );

  FundPrewarmBatchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
    required this.perAmc,
  }) : super.internal();

  final int limit;
  final int perAmc;

  @override
  Override overrideWith(
    FutureOr<int> Function(FundPrewarmBatchRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FundPrewarmBatchProvider._internal(
        (ref) => create(ref as FundPrewarmBatchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
        perAmc: perAmc,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _FundPrewarmBatchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FundPrewarmBatchProvider &&
        other.limit == limit &&
        other.perAmc == perAmc;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, perAmc.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FundPrewarmBatchRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `perAmc` of this provider.
  int get perAmc;
}

class _FundPrewarmBatchProviderElement
    extends AutoDisposeFutureProviderElement<int> with FundPrewarmBatchRef {
  _FundPrewarmBatchProviderElement(super.provider);

  @override
  int get limit => (origin as FundPrewarmBatchProvider).limit;
  @override
  int get perAmc => (origin as FundPrewarmBatchProvider).perAmc;
}

String _$navHistoryHash() => r'a30e011bbc0e159cf3fcc26cb318d91ff97ac5ad';

/// Historical NAV for charts and analytics — from nav_history table.
///
/// IMPORTANT: this provider is the *single source of truth* for daily NAV
/// history. It owns the on-demand backfill so every consumer (analytics,
/// benchmark chart, rolling returns, what-if calculator, …) sees a
/// consistent loading → data → error lifecycle.
///
/// Behaviour:
///   1. Read whatever is currently stored in `nav_history`.
///   2. If the row count is below the "statistically meaningful" threshold
///      (60 trading days ≈ 3 months), invoke the `fetch-nav-batch` edge
///      function in `single` mode. This pulls the full history from
///      mfapi.in / Kuvera and writes it to `nav_history` (and back-fills
///      `fund_master.launch_date` when missing).
///   3. Re-query and return the populated rows.
///
/// We deliberately let backfill failures *propagate* as Riverpod errors so
/// the UI can show a real error state (and so we never see "—" silently
/// hiding a broken integration). The previous design swallowed errors with
/// a bare `catch (_)`, which made the page indistinguishable from "no data
/// available" and hid two real production bugs.
///
/// Copied from [navHistory].
@ProviderFor(navHistory)
const navHistoryProvider = NavHistoryFamily();

/// Historical NAV for charts and analytics — from nav_history table.
///
/// IMPORTANT: this provider is the *single source of truth* for daily NAV
/// history. It owns the on-demand backfill so every consumer (analytics,
/// benchmark chart, rolling returns, what-if calculator, …) sees a
/// consistent loading → data → error lifecycle.
///
/// Behaviour:
///   1. Read whatever is currently stored in `nav_history`.
///   2. If the row count is below the "statistically meaningful" threshold
///      (60 trading days ≈ 3 months), invoke the `fetch-nav-batch` edge
///      function in `single` mode. This pulls the full history from
///      mfapi.in / Kuvera and writes it to `nav_history` (and back-fills
///      `fund_master.launch_date` when missing).
///   3. Re-query and return the populated rows.
///
/// We deliberately let backfill failures *propagate* as Riverpod errors so
/// the UI can show a real error state (and so we never see "—" silently
/// hiding a broken integration). The previous design swallowed errors with
/// a bare `catch (_)`, which made the page indistinguishable from "no data
/// available" and hid two real production bugs.
///
/// Copied from [navHistory].
class NavHistoryFamily extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// Historical NAV for charts and analytics — from nav_history table.
  ///
  /// IMPORTANT: this provider is the *single source of truth* for daily NAV
  /// history. It owns the on-demand backfill so every consumer (analytics,
  /// benchmark chart, rolling returns, what-if calculator, …) sees a
  /// consistent loading → data → error lifecycle.
  ///
  /// Behaviour:
  ///   1. Read whatever is currently stored in `nav_history`.
  ///   2. If the row count is below the "statistically meaningful" threshold
  ///      (60 trading days ≈ 3 months), invoke the `fetch-nav-batch` edge
  ///      function in `single` mode. This pulls the full history from
  ///      mfapi.in / Kuvera and writes it to `nav_history` (and back-fills
  ///      `fund_master.launch_date` when missing).
  ///   3. Re-query and return the populated rows.
  ///
  /// We deliberately let backfill failures *propagate* as Riverpod errors so
  /// the UI can show a real error state (and so we never see "—" silently
  /// hiding a broken integration). The previous design swallowed errors with
  /// a bare `catch (_)`, which made the page indistinguishable from "no data
  /// available" and hid two real production bugs.
  ///
  /// Copied from [navHistory].
  const NavHistoryFamily();

  /// Historical NAV for charts and analytics — from nav_history table.
  ///
  /// IMPORTANT: this provider is the *single source of truth* for daily NAV
  /// history. It owns the on-demand backfill so every consumer (analytics,
  /// benchmark chart, rolling returns, what-if calculator, …) sees a
  /// consistent loading → data → error lifecycle.
  ///
  /// Behaviour:
  ///   1. Read whatever is currently stored in `nav_history`.
  ///   2. If the row count is below the "statistically meaningful" threshold
  ///      (60 trading days ≈ 3 months), invoke the `fetch-nav-batch` edge
  ///      function in `single` mode. This pulls the full history from
  ///      mfapi.in / Kuvera and writes it to `nav_history` (and back-fills
  ///      `fund_master.launch_date` when missing).
  ///   3. Re-query and return the populated rows.
  ///
  /// We deliberately let backfill failures *propagate* as Riverpod errors so
  /// the UI can show a real error state (and so we never see "—" silently
  /// hiding a broken integration). The previous design swallowed errors with
  /// a bare `catch (_)`, which made the page indistinguishable from "no data
  /// available" and hid two real production bugs.
  ///
  /// Copied from [navHistory].
  NavHistoryProvider call(
    int amfiCode,
  ) {
    return NavHistoryProvider(
      amfiCode,
    );
  }

  @override
  NavHistoryProvider getProviderOverride(
    covariant NavHistoryProvider provider,
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
  String? get name => r'navHistoryProvider';
}

/// Historical NAV for charts and analytics — from nav_history table.
///
/// IMPORTANT: this provider is the *single source of truth* for daily NAV
/// history. It owns the on-demand backfill so every consumer (analytics,
/// benchmark chart, rolling returns, what-if calculator, …) sees a
/// consistent loading → data → error lifecycle.
///
/// Behaviour:
///   1. Read whatever is currently stored in `nav_history`.
///   2. If the row count is below the "statistically meaningful" threshold
///      (60 trading days ≈ 3 months), invoke the `fetch-nav-batch` edge
///      function in `single` mode. This pulls the full history from
///      mfapi.in / Kuvera and writes it to `nav_history` (and back-fills
///      `fund_master.launch_date` when missing).
///   3. Re-query and return the populated rows.
///
/// We deliberately let backfill failures *propagate* as Riverpod errors so
/// the UI can show a real error state (and so we never see "—" silently
/// hiding a broken integration). The previous design swallowed errors with
/// a bare `catch (_)`, which made the page indistinguishable from "no data
/// available" and hid two real production bugs.
///
/// Copied from [navHistory].
class NavHistoryProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// Historical NAV for charts and analytics — from nav_history table.
  ///
  /// IMPORTANT: this provider is the *single source of truth* for daily NAV
  /// history. It owns the on-demand backfill so every consumer (analytics,
  /// benchmark chart, rolling returns, what-if calculator, …) sees a
  /// consistent loading → data → error lifecycle.
  ///
  /// Behaviour:
  ///   1. Read whatever is currently stored in `nav_history`.
  ///   2. If the row count is below the "statistically meaningful" threshold
  ///      (60 trading days ≈ 3 months), invoke the `fetch-nav-batch` edge
  ///      function in `single` mode. This pulls the full history from
  ///      mfapi.in / Kuvera and writes it to `nav_history` (and back-fills
  ///      `fund_master.launch_date` when missing).
  ///   3. Re-query and return the populated rows.
  ///
  /// We deliberately let backfill failures *propagate* as Riverpod errors so
  /// the UI can show a real error state (and so we never see "—" silently
  /// hiding a broken integration). The previous design swallowed errors with
  /// a bare `catch (_)`, which made the page indistinguishable from "no data
  /// available" and hid two real production bugs.
  ///
  /// Copied from [navHistory].
  NavHistoryProvider(
    int amfiCode,
  ) : this._internal(
          (ref) => navHistory(
            ref as NavHistoryRef,
            amfiCode,
          ),
          from: navHistoryProvider,
          name: r'navHistoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$navHistoryHash,
          dependencies: NavHistoryFamily._dependencies,
          allTransitiveDependencies:
              NavHistoryFamily._allTransitiveDependencies,
          amfiCode: amfiCode,
        );

  NavHistoryProvider._internal(
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
    FutureOr<List<Map<String, dynamic>>> Function(NavHistoryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NavHistoryProvider._internal(
        (ref) => create(ref as NavHistoryRef),
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
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _NavHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NavHistoryProvider && other.amfiCode == amfiCode;
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
mixin NavHistoryRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `amfiCode` of this provider.
  int get amfiCode;
}

class _NavHistoryProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with NavHistoryRef {
  _NavHistoryProviderElement(super.provider);

  @override
  int get amfiCode => (origin as NavHistoryProvider).amfiCode;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
