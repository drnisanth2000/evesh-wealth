// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index_nav_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$indexNavHistoryHash() => r'50567d1454694463039297f951cc5444e7805a63';

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

/// Returns the historical NAV series for a given benchmark index from
/// `index_nav_history`, ordered by date ascending.
///
/// Copied from [indexNavHistory].
@ProviderFor(indexNavHistory)
const indexNavHistoryProvider = IndexNavHistoryFamily();

/// Returns the historical NAV series for a given benchmark index from
/// `index_nav_history`, ordered by date ascending.
///
/// Copied from [indexNavHistory].
class IndexNavHistoryFamily extends Family<AsyncValue<List<IndexNavPoint>>> {
  /// Returns the historical NAV series for a given benchmark index from
  /// `index_nav_history`, ordered by date ascending.
  ///
  /// Copied from [indexNavHistory].
  const IndexNavHistoryFamily();

  /// Returns the historical NAV series for a given benchmark index from
  /// `index_nav_history`, ordered by date ascending.
  ///
  /// Copied from [indexNavHistory].
  IndexNavHistoryProvider call({
    required String indexName,
    required DateTime fromDate,
  }) {
    return IndexNavHistoryProvider(
      indexName: indexName,
      fromDate: fromDate,
    );
  }

  @override
  IndexNavHistoryProvider getProviderOverride(
    covariant IndexNavHistoryProvider provider,
  ) {
    return call(
      indexName: provider.indexName,
      fromDate: provider.fromDate,
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
  String? get name => r'indexNavHistoryProvider';
}

/// Returns the historical NAV series for a given benchmark index from
/// `index_nav_history`, ordered by date ascending.
///
/// Copied from [indexNavHistory].
class IndexNavHistoryProvider
    extends AutoDisposeFutureProvider<List<IndexNavPoint>> {
  /// Returns the historical NAV series for a given benchmark index from
  /// `index_nav_history`, ordered by date ascending.
  ///
  /// Copied from [indexNavHistory].
  IndexNavHistoryProvider({
    required String indexName,
    required DateTime fromDate,
  }) : this._internal(
          (ref) => indexNavHistory(
            ref as IndexNavHistoryRef,
            indexName: indexName,
            fromDate: fromDate,
          ),
          from: indexNavHistoryProvider,
          name: r'indexNavHistoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$indexNavHistoryHash,
          dependencies: IndexNavHistoryFamily._dependencies,
          allTransitiveDependencies:
              IndexNavHistoryFamily._allTransitiveDependencies,
          indexName: indexName,
          fromDate: fromDate,
        );

  IndexNavHistoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.indexName,
    required this.fromDate,
  }) : super.internal();

  final String indexName;
  final DateTime fromDate;

  @override
  Override overrideWith(
    FutureOr<List<IndexNavPoint>> Function(IndexNavHistoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IndexNavHistoryProvider._internal(
        (ref) => create(ref as IndexNavHistoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        indexName: indexName,
        fromDate: fromDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<IndexNavPoint>> createElement() {
    return _IndexNavHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IndexNavHistoryProvider &&
        other.indexName == indexName &&
        other.fromDate == fromDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, indexName.hashCode);
    hash = _SystemHash.combine(hash, fromDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IndexNavHistoryRef on AutoDisposeFutureProviderRef<List<IndexNavPoint>> {
  /// The parameter `indexName` of this provider.
  String get indexName;

  /// The parameter `fromDate` of this provider.
  DateTime get fromDate;
}

class _IndexNavHistoryProviderElement
    extends AutoDisposeFutureProviderElement<List<IndexNavPoint>>
    with IndexNavHistoryRef {
  _IndexNavHistoryProviderElement(super.provider);

  @override
  String get indexName => (origin as IndexNavHistoryProvider).indexName;
  @override
  DateTime get fromDate => (origin as IndexNavHistoryProvider).fromDate;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
