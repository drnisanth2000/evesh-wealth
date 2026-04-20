import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_provider.dart';

part 'alert_provider.g.dart';

class AlertModel {
  const AlertModel({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.amfiCode,
    this.memberId,
  });

  final String id;
  final String alertType;
  final String severity; // URGENT | MEDIUM | LOW
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final int? amfiCode;
  final String? memberId;

  factory AlertModel.fromJson(Map<String, dynamic> j) {
    return AlertModel(
      id: j['id'] as String,
      alertType: j['alert_type'] as String,
      severity: j['severity'] as String? ?? 'LOW',
      title: j['title'] as String? ?? '',
      body: j['body'] as String? ?? '',
      isRead: j['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(j['created_at'] as String),
      amfiCode: j['amfi_code'] as int?,
      memberId: j['member_id'] as String?,
    );
  }
}

@riverpod
Future<List<AlertModel>> alerts(AlertsRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('alert_log')
      .select()
      .eq('owner_id', userId)
      .order('created_at', ascending: false)
      .limit(100);

  return (response as List)
      .map((r) => AlertModel.fromJson(r as Map<String, dynamic>))
      .toList();
}

@riverpod
class AlertNotifier extends _$AlertNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> markRead(String alertId) async {
    final client = ref.read(supabaseClientProvider);
    await client
        .from('alert_log')
        .update({'is_read': true})
        .eq('id', alertId);
    ref.invalidate(alertsProvider);
  }

  Future<void> markAllRead() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final client = ref.read(supabaseClientProvider);
    await client
        .from('alert_log')
        .update({'is_read': true})
        .eq('owner_id', userId)
        .eq('is_read', false);
    ref.invalidate(alertsProvider);
  }
}
