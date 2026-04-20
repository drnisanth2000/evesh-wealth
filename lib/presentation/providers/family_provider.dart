import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/family_model.dart';
import 'auth_provider.dart';

part 'family_provider.g.dart';

@riverpod
Future<List<FamilyMemberModel>> familyMembers(FamilyMembersRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('family_members')
      .select()
      .eq('owner_id', userId)
      .order('display_name');

  return (response as List)
      .map((row) => FamilyMemberModel.fromJson(row as Map<String, dynamic>))
      .toList();
}

/// The family member with relationship 'Self' — the primary user / CEO.
@riverpod
Future<FamilyMemberModel?> selfMember(SelfMemberRef ref) async {
  final members = await ref.watch(familyMembersProvider.future);
  return members.cast<FamilyMemberModel?>().firstWhere(
      (m) => m?.relationship == 'Self',
      orElse: () => null);
}

@riverpod
Future<FamilyModel?> family(FamilyRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('families')
      .select()
      .eq('owner_id', userId)
      .order('created_at')
      .limit(1);

  final rows = response as List;
  if (rows.isEmpty) return null;
  return FamilyModel.fromJson(rows.first as Map<String, dynamic>);
}

@riverpod
Future<ProfileModel?> currentProfile(CurrentProfileRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('profiles')
      .select()
      .eq('id', userId)
      .maybeSingle();

  if (response == null) return null;
  return ProfileModel.fromJson(response as Map<String, dynamic>);
}
