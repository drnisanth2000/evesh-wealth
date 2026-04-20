import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/watchlist_rule_model.dart';
import 'auth_provider.dart';

part 'watchlist_provider.g.dart';

/// Fetches all watchlist rules for the current user.
@riverpod
Future<List<WatchlistRuleModel>> watchlistRules(WatchlistRulesRef ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('watchlist_rules')
      .select()
      .eq('owner_id', uid)
      .order('created_at', ascending: false);

  return (response as List)
      .map((row) => WatchlistRuleModel.fromJson(row as Map<String, dynamic>))
      .toList();
}

/// Fetches watchlist rules for a specific fund.
@riverpod
Future<List<WatchlistRuleModel>> fundWatchlistRules(
  FundWatchlistRulesRef ref,
  int amfiCode,
) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('watchlist_rules')
      .select()
      .eq('owner_id', uid)
      .eq('amfi_code', amfiCode)
      .order('created_at', ascending: false);

  return (response as List)
      .map((row) => WatchlistRuleModel.fromJson(row as Map<String, dynamic>))
      .toList();
}

/// Notifier for CRUD operations on watchlist rules.
@riverpod
class WatchlistNotifier extends _$WatchlistNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> addRule({
    String? memberId,
    int? amfiCode,
    String? fundName,
    required String ruleType,
    required String thresholdType,
    required double thresholdValue,
    required String direction,
    String? assetClassKey,
    String? note,
  }) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) throw Exception('Not authenticated');

    final client = ref.read(supabaseClientProvider);
    await client.from('watchlist_rules').insert({
      'owner_id': uid,
      if (memberId != null) 'member_id': memberId,
      if (amfiCode != null) 'amfi_code': amfiCode,
      if (fundName != null) 'fund_name': fundName,
      'rule_type': ruleType,
      'threshold_type': thresholdType,
      'threshold_value': thresholdValue,
      'direction': direction,
      if (assetClassKey != null) 'asset_class_key': assetClassKey,
      if (note != null) 'note': note,
    });

    ref.invalidate(watchlistRulesProvider);
    if (amfiCode != null) {
      ref.invalidate(fundWatchlistRulesProvider(amfiCode));
    }
  }

  Future<void> updateRule(String ruleId, Map<String, dynamic> updates) async {
    final client = ref.read(supabaseClientProvider);
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) throw Exception('Not authenticated');
    await client
        .from('watchlist_rules')
        .update(updates)
        .eq('id', ruleId)
        .eq('owner_id', uid);
    ref.invalidate(watchlistRulesProvider);
  }

  Future<void> toggleActive(String ruleId, bool isActive) async {
    await updateRule(ruleId, {'is_active': isActive});
  }

  Future<void> deleteRule(String ruleId, {int? amfiCode}) async {
    final client = ref.read(supabaseClientProvider);
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) throw Exception('Not authenticated');
    await client
        .from('watchlist_rules')
        .delete()
        .eq('id', ruleId)
        .eq('owner_id', uid);
    ref.invalidate(watchlistRulesProvider);
    if (amfiCode != null) {
      ref.invalidate(fundWatchlistRulesProvider(amfiCode));
    }
  }
}

/// Fetches current NAV for a list of amfi codes (for status display).
@riverpod
Future<Map<int, double>> watchlistNavMap(WatchlistNavMapRef ref) async {
  final rules = await ref.watch(watchlistRulesProvider.future);
  final amfiCodes = rules
      .where((r) => r.amfiCode != null)
      .map((r) => r.amfiCode!)
      .toSet()
      .toList();

  if (amfiCodes.isEmpty) return {};

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('fund_master')
      .select('amfi_code, latest_nav')
      .inFilter('amfi_code', amfiCodes);

  return {
    for (final row in (response as List))
      (row['amfi_code'] as int): (row['latest_nav'] as num?)?.toDouble() ?? 0.0,
  };
}
