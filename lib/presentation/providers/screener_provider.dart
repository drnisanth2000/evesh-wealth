import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/fund_model.dart';
import '../../data/models/fund_performance_row.dart';
import '../../domain/models/screener_models.dart';
import 'auth_provider.dart';

part 'screener_provider.g.dart';

/// Queries the tracked warm-fund universe (via fund_screener_mv) with
/// dynamic filters and sort. Returns up to 100 [ScreenerFundRow]s.
///
/// The materialized view is refreshed nightly and holds only funds with
/// tracked_tier='warm' (~2,000 out of ~14,000 active funds). It is
/// pre-joined, pre-sorted, and column-trimmed so the screener payload
/// is ~1.5 MB instead of the ~25 MB we were shipping from fund_master.
///
/// Cold funds are excluded by default. Users who want to screen across
/// the full universe can opt in by calling [screenerResultsAll] instead
/// (slower, touches fund_master directly). A cold fund that a user
/// actually opens gets promoted to warm automatically by the
/// fetch-fund-ondemand edge function — so power users never miss out
/// on funds they care about.
@riverpod
Future<List<ScreenerFundRow>> screenerResults(
  ScreenerResultsRef ref,
  ScreenerFilters filters,
) async {
  // When the user types a name-search query, we deliberately bypass the
  // warm materialized view and query fund_master directly. Otherwise the
  // screener can never surface cold funds (e.g. HDFC Technology Fund) by
  // name, which is confusing UX — the user knows the fund exists, types
  // its name, and gets "No funds match your filters". Tapping a cold
  // result triggers fetch-fund-ondemand from FundDetailScreen, which
  // promotes it to warm for the next 30 days.
  final hasSearch =
      filters.searchQuery != null && filters.searchQuery!.trim().length >= 2;
  if (hasSearch) {
    return ref.watch(screenerResultsAllProvider(filters).future);
  }

  final client = ref.watch(supabaseClientProvider);

  // fund_screener_mv pre-filters on `is_active = true AND tracked_tier = 'warm'`
  // so we skip those predicates here.
  var filterQuery = client.from('fund_screener_mv').select();

  // Apply filters
  if (filters.searchQuery != null && filters.searchQuery!.trim().length >= 2) {
    filterQuery = filterQuery.ilike('fund_name', '%${filters.searchQuery!.trim()}%');
  }
  if (filters.category != null) {
    // Heterogeneous legacy column — we still allow contains-match for the
    // dropdown UI, but presets should use `subCategory` (exact, canonical).
    filterQuery = filterQuery.ilike('category', '%${filters.category}%');
  }
  if (filters.subCategory != null) {
    filterQuery = filterQuery.eq('sub_category', filters.subCategory!);
  }
  if (filters.amc != null) {
    filterQuery = filterQuery.ilike('amc', '%${filters.amc}%');
  }
  if (filters.planType != null) {
    filterQuery = filterQuery.eq('plan_type', filters.planType!);
  }
  if (filters.aumMin != null) {
    filterQuery = filterQuery.gte('aum_cr', filters.aumMin!);
  }
  if (filters.aumMax != null) {
    filterQuery = filterQuery.lte('aum_cr', filters.aumMax!);
  }
  if (filters.erMax != null) {
    filterQuery = filterQuery.lte('expense_ratio', filters.erMax!);
  }
  if (filters.return1yMin != null) {
    filterQuery = filterQuery.gte('return_1y', filters.return1yMin!);
  }
  if (filters.return3yMin != null) {
    filterQuery = filterQuery.gte('return_3y', filters.return3yMin!);
  }
  if (filters.return5yMin != null) {
    filterQuery = filterQuery.gte('return_5y', filters.return5yMin!);
  }
  if (filters.return3mMin != null) {
    filterQuery = filterQuery.gte('return_3m', filters.return3mMin!);
  }
  if (filters.return6mMin != null) {
    filterQuery = filterQuery.gte('return_6m', filters.return6mMin!);
  }
  if (filters.infoRatio3yMin != null) {
    filterQuery = filterQuery.gte('info_ratio_3y', filters.infoRatio3yMin!);
  }
  if (filters.riskometer != null && filters.riskometer!.isNotEmpty) {
    filterQuery = filterQuery.inFilter('riskometer_scheme', filters.riskometer!);
  }
  if (filters.benchmarkContains != null &&
      filters.benchmarkContains!.trim().isNotEmpty) {
    filterQuery = filterQuery.ilike(
      'benchmark_index',
      '%${filters.benchmarkContains!.trim()}%',
    );
  }
  if (filters.ratingMin != null) {
    filterQuery = filterQuery.gte('fund_rating', filters.ratingMin!);
  }

  // Apply sort + limit (returns PostgrestTransformBuilder — no re-assignment needed)
  // nullsFirst: false ensures funds with NULL values in the sort column
  // appear at the end, so the top-100 results have meaningful data.
  final response = await filterQuery
      .order(filters.sortBy, ascending: filters.sortAsc, nullsFirst: false)
      .limit(100);
  return (response as List).map((raw) {
    final row = raw as Map<String, dynamic>;
    return ScreenerFundRow(
      fund: FundModel.fromJson(row),
      perf: FundPerformanceRow.fromJson(row),
    );
  }).toList();
}

/// Escape-hatch: query the full fund_master universe (not just warm set).
/// Slower — used only when the user explicitly toggles "Show all funds"
/// in the screener. Same filter chain as [screenerResults] but hits the
/// raw table and keeps the is_active predicate.
@riverpod
Future<List<ScreenerFundRow>> screenerResultsAll(
  ScreenerResultsAllRef ref,
  ScreenerFilters filters,
) async {
  final client = ref.watch(supabaseClientProvider);
  var filterQuery = client
      .from('fund_master')
      .select()
      .eq('is_active', true);

  if (filters.searchQuery != null && filters.searchQuery!.trim().length >= 2) {
    filterQuery = filterQuery.ilike('fund_name', '%${filters.searchQuery!.trim()}%');
  }
  if (filters.category != null) {
    filterQuery = filterQuery.ilike('category', '%${filters.category}%');
  }
  if (filters.subCategory != null) {
    filterQuery = filterQuery.eq('sub_category', filters.subCategory!);
  }
  if (filters.amc != null) {
    filterQuery = filterQuery.ilike('amc', '%${filters.amc}%');
  }
  if (filters.planType != null) {
    filterQuery = filterQuery.eq('plan_type', filters.planType!);
  }
  if (filters.aumMin != null) filterQuery = filterQuery.gte('aum_cr', filters.aumMin!);
  if (filters.aumMax != null) filterQuery = filterQuery.lte('aum_cr', filters.aumMax!);
  if (filters.erMax != null) filterQuery = filterQuery.lte('expense_ratio', filters.erMax!);
  if (filters.return1yMin != null) filterQuery = filterQuery.gte('return_1y', filters.return1yMin!);
  if (filters.return3yMin != null) filterQuery = filterQuery.gte('return_3y', filters.return3yMin!);
  if (filters.return5yMin != null) filterQuery = filterQuery.gte('return_5y', filters.return5yMin!);
  if (filters.return3mMin != null) filterQuery = filterQuery.gte('return_3m', filters.return3mMin!);
  if (filters.return6mMin != null) filterQuery = filterQuery.gte('return_6m', filters.return6mMin!);
  if (filters.infoRatio3yMin != null) filterQuery = filterQuery.gte('info_ratio_3y', filters.infoRatio3yMin!);
  if (filters.riskometer != null && filters.riskometer!.isNotEmpty) {
    filterQuery = filterQuery.inFilter('riskometer_scheme', filters.riskometer!);
  }
  if (filters.benchmarkContains != null && filters.benchmarkContains!.trim().isNotEmpty) {
    filterQuery = filterQuery.ilike('benchmark_index', '%${filters.benchmarkContains!.trim()}%');
  }
  if (filters.ratingMin != null) filterQuery = filterQuery.gte('fund_rating', filters.ratingMin!);

  final response = await filterQuery
      .order(filters.sortBy, ascending: filters.sortAsc, nullsFirst: false)
      .limit(100);
  return (response as List).map((raw) {
    final row = raw as Map<String, dynamic>;
    return ScreenerFundRow(
      fund: FundModel.fromJson(row),
      perf: FundPerformanceRow.fromJson(row),
    );
  }).toList();
}

/// Distinct AMC names for filter dropdown — scoped to the warm universe
/// (so the dropdown matches what the screener actually returns).
@riverpod
Future<List<String>> amcList(AmcListRef ref) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('fund_screener_mv')
      .select('amc')
      .not('amc', 'is', null)
      .order('amc')
      .limit(200);

  final amcs = <String>{};
  for (final row in (response as List)) {
    final amc = (row as Map<String, dynamic>)['amc'] as String?;
    if (amc != null && amc.isNotEmpty) amcs.add(amc);
  }
  return amcs.toList()..sort();
}

/// Distinct categories for filter dropdown — scoped to warm universe.
@riverpod
Future<List<String>> categoryList(CategoryListRef ref) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('fund_screener_mv')
      .select('category')
      .not('category', 'is', null)
      .order('category')
      .limit(100);

  final cats = <String>{};
  for (final row in (response as List)) {
    final cat = (row as Map<String, dynamic>)['category'] as String?;
    if (cat != null && cat.isNotEmpty) cats.add(cat);
  }
  return cats.toList()..sort();
}
