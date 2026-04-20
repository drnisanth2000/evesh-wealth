import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/deployment_plan_model.dart';
import 'auth_provider.dart';

part 'deployment_plan_provider.g.dart';

/// Saved STP / lumpsum-vs-SIP deployment plans, scoped to a single member
/// (or all when [memberId] is null). Sorted newest-first by `created_at`.
@riverpod
Future<List<DeploymentPlanModel>> deploymentPlans(
  DeploymentPlansRef ref,
  String? memberId,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  final client = ref.watch(supabaseClientProvider);
  var query = client.from('deployment_plans').select().eq('owner_id', userId);
  if (memberId != null) {
    query = query.eq('member_id', memberId);
  }
  final rows = await query.order('created_at', ascending: false);
  return (rows as List)
      .cast<Map<String, dynamic>>()
      .map(DeploymentPlanModel.fromJson)
      .toList();
}

@riverpod
class DeploymentPlansMutator extends _$DeploymentPlansMutator {
  @override
  void build() {}

  Future<String> save({
    required double lumpsumRupees,
    required double sipRupees,
    required double splitPct,
    required Map<String, dynamic> planJson,
    String? memberId,
    String? familyId,
    String? notes,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw StateError('Not signed in');

    final payload = <String, dynamic>{
      'owner_id': userId,
      if (familyId != null) 'family_id': familyId,
      if (memberId != null) 'member_id': memberId,
      'lumpsum_rupees': lumpsumRupees,
      'sip_rupees': sipRupees,
      'split_pct': splitPct,
      'plan_jsonb': planJson,
      if (notes != null) 'notes': notes,
    };
    final inserted = await client
        .from('deployment_plans')
        .insert(payload)
        .select('id')
        .single();
    ref.invalidate(deploymentPlansProvider);
    return inserted['id'] as String;
  }

  Future<void> markExecuted(String id) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('deployment_plans').update({
      'executed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
    ref.invalidate(deploymentPlansProvider);
  }

  Future<void> delete(String id) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('deployment_plans').delete().eq('id', id);
    ref.invalidate(deploymentPlansProvider);
  }
}
