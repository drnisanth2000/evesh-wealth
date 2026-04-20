import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/goal_model.dart';
import 'auth_provider.dart';
import 'family_provider.dart';

part 'goal_provider.g.dart';

@riverpod
Future<List<GoalModel>> goals(GoalsRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('goals')
      .select()
      .eq('owner_id', userId)
      .order('target_date');

  return (response as List)
      .map((row) => GoalModel.fromJson(row as Map<String, dynamic>))
      .toList();
}

@riverpod
Future<List<GoalFundLink>> goalFundLinks(GoalFundLinksRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('goal_funds')
      .select()
      .eq('owner_id', userId);

  return (response as List)
      .map((row) => GoalFundLink.fromJson(row as Map<String, dynamic>))
      .toList();
}

@riverpod
class GoalMutator extends _$GoalMutator {
  @override
  void build() {}

  Future<void> addGoal({
    String? memberId,
    required String goalName,
    required double targetAmount,
    required DateTime targetDate,
    String? notes,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw StateError('Not signed in');
    final family = await ref.read(familyProvider.future);
    if (family == null) throw StateError('No family exists');

    final payload = {
      'owner_id': userId,
      'family_id': family.id,
      if (memberId != null) 'member_id': memberId,
      'goal_name': goalName,
      'target_amount': targetAmount,
      'target_date': targetDate.toIso8601String().substring(0, 10),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    await client.from('goals').insert(payload);
    ref.invalidate(goalsProvider);
  }

  Future<void> updateGoal({
    required String goalId,
    String? goalName,
    double? targetAmount,
    DateTime? targetDate,
    String? notes,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw StateError('Not signed in');
    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (goalName != null) payload['goal_name'] = goalName;
    if (targetAmount != null) payload['target_amount'] = targetAmount;
    if (targetDate != null) {
      payload['target_date'] = targetDate.toIso8601String().substring(0, 10);
    }
    if (notes != null) payload['notes'] = notes;

    await client
        .from('goals')
        .update(payload)
        .eq('id', goalId)
        .eq('owner_id', userId);
    ref.invalidate(goalsProvider);
  }

  Future<void> deleteGoal(String goalId) async {
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw StateError('Not signed in');
    await client
        .from('goals')
        .delete()
        .eq('id', goalId)
        .eq('owner_id', userId);
    ref.invalidate(goalsProvider);
    ref.invalidate(goalFundLinksProvider);
  }

  Future<void> attachFund({
    required String goalId,
    required int amfiCode,
    double allocationPct = 100.0,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw StateError('Not signed in');
    await client.from('goal_funds').upsert({
      'owner_id': userId,
      'goal_id': goalId,
      'amfi_code': amfiCode,
      'allocation_pct': allocationPct,
    }, onConflict: 'goal_id,amfi_code');
    ref.invalidate(goalFundLinksProvider);
  }

  Future<void> detachFund({
    required String goalId,
    required int amfiCode,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client
        .from('goal_funds')
        .delete()
        .eq('goal_id', goalId)
        .eq('amfi_code', amfiCode);
    ref.invalidate(goalFundLinksProvider);
  }
}
