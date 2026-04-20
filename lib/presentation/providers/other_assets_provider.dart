import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/other_asset_model.dart';
import 'auth_provider.dart';

part 'other_assets_provider.g.dart';

/// Other assets (FD / PPF / NPS / SGB / Real Estate / PMS / ...) scoped to a
/// single member, or the entire owner scope when [memberId] is null.
///
/// The bucket-composition provider (Wealth Planner v2 task 0.7) reads this
/// same family provider — keying by memberId lets screens switch between
/// "All members" and an individual view without refetching.
@riverpod
Future<List<OtherAssetModel>> otherAssets(
  OtherAssetsRef ref,
  String? memberId,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  final client = ref.watch(supabaseClientProvider);
  var query = client.from('other_assets').select().eq('owner_id', userId);
  if (memberId != null) {
    query = query.eq('member_id', memberId);
  }
  final rows = await query.order('asset_type');
  return (rows as List)
      .cast<Map<String, dynamic>>()
      .map(OtherAssetModel.fromJson)
      .toList();
}

@riverpod
class OtherAssetsMutator extends _$OtherAssetsMutator {
  @override
  void build() {}

  Future<void> add({
    required String assetType,
    required String description,
    String? memberId,
    String? familyId,
    double? costValue,
    double? currentValue,
    double? quantity,
    double? interestRate,
    String? interestFrequency,
    String? startDate,
    String? maturityDate,
    String? brokerOrInstitution,
    String? notes,
    String? bucketOverride,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw StateError('Not signed in');

    final payload = <String, dynamic>{
      'owner_id': userId,
      'asset_type': assetType,
      'description': description,
      if (memberId != null) 'member_id': memberId,
      if (familyId != null) 'family_id': familyId,
      if (costValue != null) 'cost_value': costValue,
      if (currentValue != null) 'current_value': currentValue,
      if (quantity != null) 'quantity': quantity,
      if (interestRate != null) 'interest_rate': interestRate,
      if (interestFrequency != null) 'interest_frequency': interestFrequency,
      if (startDate != null) 'start_date': startDate,
      if (maturityDate != null) 'maturity_date': maturityDate,
      if (brokerOrInstitution != null)
        'broker_or_institution': brokerOrInstitution,
      if (notes != null) 'notes': notes,
      if (bucketOverride != null) 'bucket_override': bucketOverride,
    };
    await client.from('other_assets').insert(payload);
    ref.invalidate(otherAssetsProvider);
  }

  Future<void> update(
    String id, {
    String? description,
    double? costValue,
    double? currentValue,
    double? quantity,
    String? maturityDate,
    String? bucketOverride,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final payload = <String, dynamic>{
      'last_updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (description != null) payload['description'] = description;
    if (costValue != null) payload['cost_value'] = costValue;
    if (currentValue != null) payload['current_value'] = currentValue;
    if (quantity != null) payload['quantity'] = quantity;
    if (maturityDate != null) payload['maturity_date'] = maturityDate;
    if (bucketOverride != null) payload['bucket_override'] = bucketOverride;

    await client.from('other_assets').update(payload).eq('id', id);
    ref.invalidate(otherAssetsProvider);
  }

  Future<void> delete(String id) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('other_assets').delete().eq('id', id);
    ref.invalidate(otherAssetsProvider);
  }
}
