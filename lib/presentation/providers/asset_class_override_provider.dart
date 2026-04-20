import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/asset_classes.dart';
import 'auth_provider.dart';
import 'bucket_composition_provider.dart';
import 'portfolio_provider.dart';

part 'asset_class_override_provider.g.dart';

/// Pulls the current user's `transactions.asset_class_override` rows and folds
/// them into a per-AMFI map. Any non-null override on any row for the AMFI
/// code wins — the override is logically per-fund even though it lives on
/// transactions (mirrors the `bucket_override` pattern).
@riverpod
Future<Map<int, AssetClass>> fundAssetClassOverrides(
  FundAssetClassOverridesRef ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const {};
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('transactions')
      .select('amfi_code, asset_class_override')
      .eq('owner_id', userId)
      .not('asset_class_override', 'is', null);
  final map = <int, AssetClass>{};
  for (final row in (response as List)) {
    final code = (row as Map)['amfi_code'];
    final override = row['asset_class_override'] as String?;
    if (code is! int || override == null) continue;
    final cls = _assetClassFromName(override);
    if (cls != null) map[code] = cls;
  }
  return map;
}

AssetClass? _assetClassFromName(String name) {
  for (final c in AssetClass.values) {
    if (c.name == name) return c;
  }
  return null;
}

/// Mutator: writes/clears `asset_class_override` on transactions rows and
/// invalidates the providers that render holdings grouped by asset class.
@riverpod
class AssetClassOverrideMutator extends _$AssetClassOverrideMutator {
  @override
  void build() {}

  Future<void> setForFund({
    required int amfiCode,
    required AssetClass? assetClass,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not signed in');
    }
    await client
        .from('transactions')
        .update({'asset_class_override': assetClass?.name})
        .eq('owner_id', userId)
        .eq('amfi_code', amfiCode);
    ref.invalidate(fundAssetClassOverridesProvider);
    ref.invalidate(portfolioSummaryProvider);
    // Rebalance/bucket view also keys off asset class via the resolver → keep
    // it consistent even though asset class and bucket overrides are separate.
    ref.invalidate(bucketCompositionProvider);
  }
}
