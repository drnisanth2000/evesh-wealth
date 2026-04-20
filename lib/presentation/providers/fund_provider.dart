import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/fund_model.dart';
import 'auth_provider.dart';

part 'fund_provider.g.dart';

/// Trigram search over fund_master — returns up to 20 matches.
@riverpod
Future<List<FundModel>> fundSearch(FundSearchRef ref, String query) async {
  if (query.trim().length < 2) return [];

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('fund_master')
      .select('amfi_code, fund_name, category, amc, plan_type, latest_nav, fund_type, tax_category')
      .ilike('fund_name', '%${query.trim()}%')
      .eq('is_active', true)
      .order('fund_name')
      .limit(20);

  return (response as List)
      .map((row) => FundModel.fromJson(row as Map<String, dynamic>))
      .toList();
}

/// Full details for a single fund by amfi_code.
///
/// If the fund is in the cold tier (i.e. not in our daily-refresh warm
/// universe), fire-and-forget a call to `fetch-fund-ondemand`. That
/// edge function pulls 400 days of NAV history from mfapi.in, upserts
/// into nav_history, recomputes short-window returns, and flips the
/// fund to warm with a 30-day sticky window — so the next visit (and
/// every visit for a month) will be instant.
///
/// We do NOT await the promotion: the UI renders the currently-known
/// fund_master row immediately and a RefreshIndicator pull will pick up
/// the freshly-populated values. This keeps cold-fund detail loads
/// snappy and prevents a slow mfapi.in call from blocking the page.
@riverpod
Future<FundModel?> fundDetail(FundDetailRef ref, int amfiCode) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('fund_master')
      .select()
      .eq('amfi_code', amfiCode)
      .maybeSingle();

  if (response == null) return null;
  final row = Map<String, dynamic>.from(response);

  // Opportunistic cold → warm promotion. The column is nullable because
  // it only exists after migration 033 has been applied; treat missing
  // as "unknown, assume warm" so the app keeps working on older DBs.
  final tier = row['tracked_tier'] as String?;
  if (tier == 'cold') {
    // Fire-and-forget; do not await. Wrapped in an IIFE so the try/catch
    // handles errors without tripping catchError's return-type signature.
    // ignore: unawaited_futures
    () async {
      try {
        await client.functions.invoke(
          'fetch-fund-ondemand',
          body: {'mode': 'single', 'amfi_code': amfiCode},
        );
      } catch (e) {
        // ignore: avoid_print
        print('fetch-fund-ondemand cold promotion failed for $amfiCode: $e');
      }
    }();
  }

  return FundModel.fromJson(row);
}

/// Background pre-warm trigger. Call this from a screener / research
/// screen after it finishes painting to idle-fetch a small batch of
/// cold funds grouped by AMC. Safe to call repeatedly — each call picks
/// a fresh batch and returns quickly (~25-40s in the background worker,
/// but the future resolves as soon as the edge function returns, which
/// is typically within 5 seconds since it pipelines mfapi fetches).
///
/// Returns the number of funds successfully fetched, or 0 on error.
@riverpod
Future<int> fundPrewarmBatch(
  FundPrewarmBatchRef ref, {
  int limit = 30,
  int perAmc = 3,
}) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final resp = await client.functions.invoke(
      'fetch-fund-ondemand',
      body: {'mode': 'prewarm', 'limit': limit, 'per_amc': perAmc},
    ).timeout(const Duration(seconds: 90));
    if (resp.status >= 400) return 0;
    final data = resp.data;
    if (data is Map && data['fetched'] is int) return data['fetched'] as int;
    return 0;
  } catch (_) {
    return 0;
  }
}

/// Historical NAV for charts and analytics — from nav_history table.
///
/// IMPORTANT: this provider is the *single source of truth* for daily NAV
/// history. It owns the on-demand backfill so every consumer (analytics,
/// benchmark chart, rolling returns, what-if calculator, …) sees a
/// consistent loading → data → error lifecycle.
///
/// Behaviour:
///   1. Read whatever is currently stored in `nav_history`.
///   2. If the row count is below the "statistically meaningful" threshold
///      (60 trading days ≈ 3 months), invoke the `fetch-nav-batch` edge
///      function in `single` mode. This pulls the full history from
///      mfapi.in / Kuvera and writes it to `nav_history` (and back-fills
///      `fund_master.launch_date` when missing).
///   3. Re-query and return the populated rows.
///
/// We deliberately let backfill failures *propagate* as Riverpod errors so
/// the UI can show a real error state (and so we never see "—" silently
/// hiding a broken integration). The previous design swallowed errors with
/// a bare `catch (_)`, which made the page indistinguishable from "no data
/// available" and hid two real production bugs.
@riverpod
Future<List<Map<String, dynamic>>> navHistory(
  NavHistoryRef ref,
  int amfiCode,
) async {
  final client = ref.watch(supabaseClientProvider);

  Future<List<Map<String, dynamic>>> readRows() async {
    // CRITICAL: order DESCENDING then limit. With ascending+limit, funds
    // older than 14-ish years (e.g. Nippon Large Cap launched 2007 has
    // ~4,589 trading-day rows) silently lose their most recent ~1,000
    // rows — the chart, vs-benchmark window and rolling-1y returns all
    // collapse because they need *recent* data, not ancient data.
    // We re-sort ascending in memory so downstream code (which expects
    // oldest-first) is unaffected.
    final response = await client
        .from('nav_history')
        .select('nav_date, nav')
        .eq('amfi_code', amfiCode)
        .order('nav_date', ascending: false)
        .limit(3650); // ~14.5 years of trading days, latest first
    final rows = (response as List).cast<Map<String, dynamic>>();
    rows.sort((a, b) =>
        (a['nav_date'] as String).compareTo(b['nav_date'] as String));
    return rows;
  }

  var rows = await readRows();

  // 60 trading days ≈ 3 months — anything below that and risk metrics are
  // statistically meaningless. The daily "latest" cron will append a single
  // stub row even for funds that have never been backfilled, so an
  // `isEmpty` check would miss the most common broken state.
  const kMinHistoryRows = 60;
  if (rows.length < kMinHistoryRows) {
    try {
      final resp = await client.functions.invoke(
        'fetch-nav-batch',
        body: {'mode': 'single', 'amfi_code': amfiCode},
      ).timeout(const Duration(seconds: 60));

      // supabase_flutter does NOT throw on non-2xx; check the status
      // explicitly so silent failures become loud failures.
      if (resp.status >= 400) {
        throw Exception(
          'fetch-nav-batch returned HTTP ${resp.status} for amfi $amfiCode: ${resp.data}',
        );
      }

      rows = await readRows();
    } catch (e, st) {
      // Surface the failure: better a visible error than empty "—" cards.
      // ignore: avoid_print
      print('navHistoryProvider backfill failed for $amfiCode: $e\n$st');
      // If we already had *some* rows, return what we have rather than
      // hiding the existing data behind an error state.
      if (rows.isNotEmpty) return rows;
      rethrow;
    }
  }

  return rows;
}
