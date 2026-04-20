// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'amfi_category_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$amfiCategoryCatalogHash() =>
    r'7b259f1c70a40e06f6d1f222272ff3c9a637df06';

/// Loads the entire amfi_category catalog once and caches as a
/// Map<id, AmfiCategoryModel>. Used by goal-term classification, asset-class
/// derivation, and the benchmark comparison chart.
///
/// Copied from [amfiCategoryCatalog].
@ProviderFor(amfiCategoryCatalog)
final amfiCategoryCatalogProvider =
    FutureProvider<Map<String, AmfiCategoryModel>>.internal(
  amfiCategoryCatalog,
  name: r'amfiCategoryCatalogProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$amfiCategoryCatalogHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AmfiCategoryCatalogRef
    = FutureProviderRef<Map<String, AmfiCategoryModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
