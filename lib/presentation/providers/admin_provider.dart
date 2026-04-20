import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_provider.dart';

part 'admin_provider.g.dart';

class AdminMetrics {
  const AdminMetrics({
    required this.totalUsers,
    required this.dau,
    required this.wau,
    required this.mau,
    required this.tierBreakdown,
    required this.newUsersThisWeek,
    required this.totalTransactions,
    required this.mrr,
    required this.generatedAt,
  });

  final int totalUsers;
  final int dau;
  final int wau;
  final int mau;
  final Map<String, int> tierBreakdown;
  final int newUsersThisWeek;
  final int totalTransactions;
  final double mrr;
  final DateTime generatedAt;

  factory AdminMetrics.fromJson(Map<String, dynamic> j) {
    final users = j['users'] as Map<String, dynamic>? ?? {};
    final tier = (j['users']?['tierBreakdown'] as Map?)?.cast<String, dynamic>() ?? {};
    return AdminMetrics(
      totalUsers: (users['total'] as num?)?.toInt() ?? 0,
      dau: (users['dau'] as num?)?.toInt() ?? 0,
      wau: (users['wau'] as num?)?.toInt() ?? 0,
      mau: (users['mau'] as num?)?.toInt() ?? 0,
      tierBreakdown: tier.map((k, v) => MapEntry(k, (v as num).toInt())),
      newUsersThisWeek: (users['newThisWeek'] as num?)?.toInt() ?? 0,
      totalTransactions:
          ((j['transactions'] as Map?)?['total'] as num?)?.toInt() ?? 0,
      mrr: ((j['revenue'] as Map?)?['mrr'] as num?)?.toDouble() ?? 0,
      generatedAt: j['generatedAt'] != null
          ? DateTime.parse(j['generatedAt'] as String)
          : DateTime.now(),
    );
  }
}

@riverpod
Future<AdminMetrics> adminMetrics(AdminMetricsRef ref) async {
  final client = ref.watch(supabaseClientProvider);
  final session = ref.watch(currentSessionProvider);
  if (session == null) throw Exception('Not authenticated');

  final response = await client.functions.invoke(
    'admin-metrics',
    headers: {'Authorization': 'Bearer ${session.accessToken}'},
  );

  final data = response.data as Map<String, dynamic>;
  return AdminMetrics.fromJson(data);
}
