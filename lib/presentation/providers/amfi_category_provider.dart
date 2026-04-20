import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/amfi_category_model.dart';
import 'auth_provider.dart';

part 'amfi_category_provider.g.dart';

/// Loads the entire amfi_category catalog once and caches as a
/// Map<id, AmfiCategoryModel>. Used by goal-term classification, asset-class
/// derivation, and the benchmark comparison chart.
@Riverpod(keepAlive: true)
Future<Map<String, AmfiCategoryModel>> amfiCategoryCatalog(
    AmfiCategoryCatalogRef ref) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final response = await client.from('amfi_category').select();
    final list = (response as List)
        .map((row) => AmfiCategoryModel.fromJson(row as Map<String, dynamic>))
        .toList();
    return {for (final c in list) c.id: c};
  } catch (e) {
    // Table may not exist yet (pre-migration). Return empty so callers can
    // fall back to legacy keyword heuristics.
    return <String, AmfiCategoryModel>{};
  }
}
