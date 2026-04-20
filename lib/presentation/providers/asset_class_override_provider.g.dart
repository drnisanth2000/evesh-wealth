// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_class_override_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fundAssetClassOverridesHash() =>
    r'7a2a2ade9d4f81ada39247e58b93da46f9c5dea5';

/// Pulls the current user's `transactions.asset_class_override` rows and folds
/// them into a per-AMFI map. Any non-null override on any row for the AMFI
/// code wins — the override is logically per-fund even though it lives on
/// transactions (mirrors the `bucket_override` pattern).
///
/// Copied from [fundAssetClassOverrides].
@ProviderFor(fundAssetClassOverrides)
final fundAssetClassOverridesProvider =
    AutoDisposeFutureProvider<Map<int, AssetClass>>.internal(
  fundAssetClassOverrides,
  name: r'fundAssetClassOverridesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fundAssetClassOverridesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FundAssetClassOverridesRef
    = AutoDisposeFutureProviderRef<Map<int, AssetClass>>;
String _$assetClassOverrideMutatorHash() =>
    r'402256c3ff419c8e4a39d00d17d8c12c7a90c085';

/// Mutator: writes/clears `asset_class_override` on transactions rows and
/// invalidates the providers that render holdings grouped by asset class.
///
/// Copied from [AssetClassOverrideMutator].
@ProviderFor(AssetClassOverrideMutator)
final assetClassOverrideMutatorProvider =
    AutoDisposeNotifierProvider<AssetClassOverrideMutator, void>.internal(
  AssetClassOverrideMutator.new,
  name: r'assetClassOverrideMutatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$assetClassOverrideMutatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AssetClassOverrideMutator = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
