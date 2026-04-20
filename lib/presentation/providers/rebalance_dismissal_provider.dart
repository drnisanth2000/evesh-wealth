import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/rebalance_dismissal_model.dart';
import 'auth_provider.dart';

part 'rebalance_dismissal_provider.g.dart';

/// Rebalance suggestions the user has dismissed, scoped to a single member
/// (or all when [memberId] is null). Sorted newest-first by `dismissed_at`.
@riverpod
Future<List<RebalanceDismissalModel>> rebalanceDismissals(
  RebalanceDismissalsRef ref,
  String? memberId,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  final client = ref.watch(supabaseClientProvider);
  var query =
      client.from('rebalance_dismissals').select().eq('owner_id', userId);
  if (memberId != null) {
    query = query.eq('member_id', memberId);
  }
  final rows = await query.order('dismissed_at', ascending: false);
  return (rows as List)
      .cast<Map<String, dynamic>>()
      .map(RebalanceDismissalModel.fromJson)
      .toList();
}

@riverpod
class RebalanceDismissalsMutator extends _$RebalanceDismissalsMutator {
  @override
  void build() {}

  Future<void> dismiss({
    required String suggestionHash,
    String? memberId,
    String? familyId,
    int? fromAmfiCode,
    int? toAmfiCode,
    double? driftPct,
    String? reason,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw StateError('Not signed in');

    // Upsert on (owner_id, suggestion_hash) UNIQUE so re-dismissing
    // the same suggestion is idempotent.
    final payload = <String, dynamic>{
      'owner_id': userId,
      if (familyId != null) 'family_id': familyId,
      if (memberId != null) 'member_id': memberId,
      'suggestion_hash': suggestionHash,
      if (fromAmfiCode != null) 'from_amfi_code': fromAmfiCode,
      if (toAmfiCode != null) 'to_amfi_code': toAmfiCode,
      if (driftPct != null) 'drift_pct': driftPct,
      if (reason != null) 'reason': reason,
    };
    await client
        .from('rebalance_dismissals')
        .upsert(payload, onConflict: 'owner_id,suggestion_hash');
    ref.invalidate(rebalanceDismissalsProvider);
  }

  Future<void> restore(String id) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('rebalance_dismissals').delete().eq('id', id);
    ref.invalidate(rebalanceDismissalsProvider);
  }
}
