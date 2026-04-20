import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/index_nav_point.dart';
import 'auth_provider.dart';

part 'index_nav_provider.g.dart';

/// Returns the historical NAV series for a given benchmark index from
/// `index_nav_history`, ordered by date ascending.
@riverpod
Future<List<IndexNavPoint>> indexNavHistory(
  IndexNavHistoryRef ref, {
  required String indexName,
  required DateTime fromDate,
}) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final response = await client
        .from('index_nav_history')
        .select('index_name, nav_date, nav')
        .eq('index_name', indexName)
        .gte('nav_date', fromDate.toIso8601String().substring(0, 10))
        .order('nav_date', ascending: true);
    return (response as List).map((row) {
      final r = row as Map<String, dynamic>;
      return IndexNavPoint(
        indexName: r['index_name'] as String,
        navDate: DateTime.parse(r['nav_date'] as String),
        nav: (r['nav'] as num).toDouble(),
      );
    }).toList();
  } catch (_) {
    return const <IndexNavPoint>[];
  }
}
