import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/screener_models.dart';
import '../../providers/fund_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/screener_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/member_selector.dart';
import '../../widgets/screener/filter_bar.dart';
import '../../widgets/screener/fund_screener_card.dart';

class ScreenerTab extends ConsumerStatefulWidget {
  const ScreenerTab({super.key});

  @override
  ConsumerState<ScreenerTab> createState() => _ScreenerTabState();
}

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class _ScreenerTabState extends ConsumerState<ScreenerTab> {
  ScreenerFilters _filters = const ScreenerFilters();
  String? _selectedMemberId;

  // ── Idle prewarm scheduler ────────────────────────────────────────────
  // Fires a single `fetch-fund-ondemand` prewarm call ~5 seconds after
  // the screener settles on this tab. The edge function picks up to 30
  // cold funds balanced across AMCs, pulls their NAV history from
  // mfapi.in in parallel, and writes the results back to nav_history
  // so the screener's warm universe grows organically over time
  // without ever blocking the user.
  //
  // We debounce with a timer rather than Future.delayed so navigating
  // away from the tab cancels the prewarm instead of firing it after
  // the user has left. Repeated tab re-entry restarts the timer.
  Timer? _prewarmTimer;
  static const _prewarmDelay = Duration(seconds: 5);
  static const _prewarmBatchSize = 30;
  static const _prewarmPerAmc = 3;

  @override
  void initState() {
    super.initState();
    _schedulePrewarm();
  }

  @override
  void dispose() {
    _prewarmTimer?.cancel();
    super.dispose();
  }

  void _schedulePrewarm() {
    _prewarmTimer?.cancel();
    _prewarmTimer = Timer(_prewarmDelay, () {
      if (!mounted) return;
      // Fire-and-forget — ignore the returned count.
      // ignore: unawaited_futures
      ref
          .read(fundPrewarmBatchProvider(
                  limit: _prewarmBatchSize, perAmc: _prewarmPerAmc).future)
          .then((_) {
        // Chain another prewarm if the user is still on this tab.
        // Spacing them ~60s apart keeps IO usage low while filling in
        // coverage opportunistically.
        if (!mounted) return;
        _prewarmTimer = Timer(const Duration(seconds: 60), _schedulePrewarm);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final amcsAsync = ref.watch(amcListProvider);
    final resultsAsync = ref.watch(screenerResultsProvider(_filters));
    final portfolioAsync = ref.watch(portfolioSummaryProvider(_selectedMemberId));

    final heldAmfiCodes = portfolioAsync.whenOrNull(
          data: (summary) =>
              summary.fundHoldings.map((h) => h.amfiCode).toSet(),
        ) ??
        <int>{};

    final categories = categoriesAsync.whenOrNull(data: (d) => d) ?? [];
    final amcs = amcsAsync.whenOrNull(data: (d) => d) ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: MemberSelector(
            selectedMemberId: _selectedMemberId,
            onSelected: (id) => setState(() => _selectedMemberId = id),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: FilterBar(
            filters: _filters,
            onChanged: (f) => setState(() => _filters = f),
            categories: categories,
            amcs: amcs,
          ),
        ),
        Expanded(
          child: resultsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: context.palette.loss,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load funds',
                    style: TextStyle(
                      color: context.palette.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    err.toString(),
                    style: TextStyle(
                      color: context.palette.textTertiary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                    onPressed: () =>
                        ref.invalidate(screenerResultsProvider(_filters)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return Center(
                  child: Text(
                    'No funds match your filters',
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                );
              }
              // Footer: most recent AMFI refresh across visible rows.
              final latestUpdate = rows
                  .map((r) => r.perf.returnsUpdatedAt)
                  .whereType<DateTime>()
                  .fold<DateTime?>(null, (acc, d) {
                if (acc == null) return d;
                return d.isAfter(acc) ? d : acc;
              });
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '${rows.length} fund${rows.length == 1 ? '' : 's'} found',
                          style: TextStyle(
                            color: context.palette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        if (latestUpdate != null)
                          Text(
                            'Updated ${_formatDate(latestUpdate)}',
                            style: TextStyle(
                              color: context.palette.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FundScreenerCard(
                            fund: row.fund,
                            perf: row.perf,
                            isHeld: heldAmfiCodes.contains(row.fund.amfiCode),
                            onTap: () => context.push(
                              '${Routes.fundMaster}/${row.fund.amfiCode}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
