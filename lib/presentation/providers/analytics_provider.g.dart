// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fundAnalyticsHash() => r'e46c01044f755d0384e556bf5336567d630621e5';

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

/// See also [fundAnalytics].
@ProviderFor(fundAnalytics)
const fundAnalyticsProvider = FundAnalyticsFamily();

/// See also [fundAnalytics].
class FundAnalyticsFamily extends Family<AsyncValue<FundAnalytics>> {
  /// See also [fundAnalytics].
  const FundAnalyticsFamily();

  /// See also [fundAnalytics].
  FundAnalyticsProvider call(
    int amfiCode,
  ) {
    return FundAnalyticsProvider(
      amfiCode,
    );
  }

  @override
  FundAnalyticsProvider getProviderOverride(
    covariant FundAnalyticsProvider provider,
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
  String? get name => r'fundAnalyticsProvider';
}

/// See also [fundAnalytics].
class FundAnalyticsProvider extends AutoDisposeFutureProvider<FundAnalytics> {
  /// See also [fundAnalytics].
  FundAnalyticsProvider(
    int amfiCode,
  ) : this._internal(
          (ref) => fundAnalytics(
            ref as FundAnalyticsRef,
            amfiCode,
          ),
          from: fundAnalyticsProvider,
          name: r'fundAnalyticsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fundAnalyticsHash,
          dependencies: FundAnalyticsFamily._dependencies,
          allTransitiveDependencies:
              FundAnalyticsFamily._allTransitiveDependencies,
          amfiCode: amfiCode,
        );

  FundAnalyticsProvider._internal(
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
    FutureOr<FundAnalytics> Function(FundAnalyticsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FundAnalyticsProvider._internal(
        (ref) => create(ref as FundAnalyticsRef),
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
  AutoDisposeFutureProviderElement<FundAnalytics> createElement() {
    return _FundAnalyticsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FundAnalyticsProvider && other.amfiCode == amfiCode;
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
mixin FundAnalyticsRef on AutoDisposeFutureProviderRef<FundAnalytics> {
  /// The parameter `amfiCode` of this provider.
  int get amfiCode;
}

class _FundAnalyticsProviderElement
    extends AutoDisposeFutureProviderElement<FundAnalytics>
    with FundAnalyticsRef {
  _FundAnalyticsProviderElement(super.provider);

  @override
  int get amfiCode => (origin as FundAnalyticsProvider).amfiCode;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
