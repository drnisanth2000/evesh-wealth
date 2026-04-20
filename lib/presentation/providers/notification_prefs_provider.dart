import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'auth_provider.dart';

part 'notification_prefs_provider.g.dart';

/// Default notification preferences.
const defaultNotificationPrefs = <String, dynamic>{
  'email': true,
  'push': true,
  'frequency': 'daily',
  'stop_loss': true,
  'gain_harvest': true,
  'rebalance_drift': true,
  'sip_reminder': true,
  'nav_drop': true,
  'ltcg_harvest': true,
  'maturity_alert': true,
  'price_target': true,
  'report_weekly': true,
  'report_monthly': true,
  'report_yearly': true,
  'stock_concentration': true,
  'sector_concentration': true,
  'fund_overlap': true,
};

@riverpod
Future<Map<String, dynamic>> notificationPrefs(NotificationPrefsRef ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Map.of(defaultNotificationPrefs);

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('profiles')
      .select('notification_prefs')
      .eq('id', uid)
      .single();

  final prefs = response['notification_prefs'] as Map<String, dynamic>?;
  if (prefs == null) return Map.of(defaultNotificationPrefs);

  // Merge with defaults so new keys are always present
  return {...defaultNotificationPrefs, ...prefs};
}

@riverpod
class NotificationPrefsNotifier extends _$NotificationPrefsNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> updatePref(String key, dynamic value) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final current = await ref.read(notificationPrefsProvider.future);
    final updated = {...current, key: value};

    final client = ref.read(supabaseClientProvider);
    await client
        .from('profiles')
        .update({'notification_prefs': updated})
        .eq('id', uid);

    ref.invalidate(notificationPrefsProvider);
  }
}
