// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reconciliation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$folioDetailsHash() => r'd2d18e95fe95bf28e945c322455e99844b5226fa';

/// See also [folioDetails].
@ProviderFor(folioDetails)
final folioDetailsProvider =
    AutoDisposeFutureProvider<List<FolioDetailModel>>.internal(
  folioDetails,
  name: r'folioDetailsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$folioDetailsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FolioDetailsRef = AutoDisposeFutureProviderRef<List<FolioDetailModel>>;
String _$reconciliationHash() => r'0a36ef56212851383d19bf2c29ece8d638b54fb4';

/// See also [reconciliation].
@ProviderFor(reconciliation)
final reconciliationProvider =
    AutoDisposeFutureProvider<ReconciliationSummary>.internal(
  reconciliation,
  name: r'reconciliationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reconciliationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReconciliationRef = AutoDisposeFutureProviderRef<ReconciliationSummary>;
String _$taxReconciliationHash() => r'92dd003b121582aa99f157cf69c56db4d8f55eaf';

/// See also [taxReconciliation].
@ProviderFor(taxReconciliation)
final taxReconciliationProvider =
    AutoDisposeFutureProvider<TaxReconciliationResult?>.internal(
  taxReconciliation,
  name: r'taxReconciliationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$taxReconciliationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TaxReconciliationRef
    = AutoDisposeFutureProviderRef<TaxReconciliationResult?>;
String _$exposurePortfolioCheckHash() =>
    r'184f4f1f752203ad411942895e34c9565ec460c3';

/// See also [exposurePortfolioCheck].
@ProviderFor(exposurePortfolioCheck)
final exposurePortfolioCheckProvider =
    AutoDisposeFutureProvider<ExposurePortfolioCheck?>.internal(
  exposurePortfolioCheck,
  name: r'exposurePortfolioCheckProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exposurePortfolioCheckHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExposurePortfolioCheckRef
    = AutoDisposeFutureProviderRef<ExposurePortfolioCheck?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
