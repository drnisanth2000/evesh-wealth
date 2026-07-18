import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/fund_provider.dart';

class CompareTab extends ConsumerStatefulWidget {
  const CompareTab({super.key});

  @override
  ConsumerState<CompareTab> createState() => _CompareTabState();
}

class _CompareTabState extends ConsumerState<CompareTab> {
  final List<int> _selectedAmfiCodes = [];
  String _searchQuery = '';
  Timer? _debounce;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = value);
    });
  }

  void _addFund(int amfiCode) {
    if (_selectedAmfiCodes.contains(amfiCode)) return;
    if (_selectedAmfiCodes.length >= 4) return;
    setState(() {
      _selectedAmfiCodes.add(amfiCode);
      _searchCtrl.clear();
      _searchQuery = '';
    });
  }

  void _removeFund(int amfiCode) {
    setState(() => _selectedAmfiCodes.remove(amfiCode));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            style: TextStyle(
              fontSize: 14,
              color: context.palette.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search funds to compare...',
              hintStyle: TextStyle(color: context.palette.textTertiary),
              prefixIcon: Icon(
                Icons.search,
                color: context.palette.textTertiary,
                size: 20,
              ),
              filled: true,
              fillColor: context.palette.bgSurface,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Selected fund chips
        if (_selectedAmfiCodes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _selectedAmfiCodes.map((code) {
                final fundAsync = ref.watch(fundDetailProvider(code));
                final name = fundAsync.whenOrNull(data: (f) => f?.fundName) ??
                    'Loading...';
                return Chip(
                  backgroundColor: context.palette.bgSurface,
                  side: BorderSide(color: context.palette.bgDivider),
                  label: Text(
                    name,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.palette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  deleteIcon: Icon(
                    Icons.close,
                    size: 14,
                    color: context.palette.textTertiary,
                  ),
                  onDeleted: () => _removeFund(code),
                );
              }).toList(),
            ),
          ),

        if (_selectedAmfiCodes.isNotEmpty) const SizedBox(height: 8),

        // Search results
        if (_searchQuery.length >= 2)
          _SearchResults(
            query: _searchQuery,
            selectedCodes: _selectedAmfiCodes,
            onAdd: _addFund,
          ),

        // Comparison table or empty state
        if (_searchQuery.length < 2)
          _selectedAmfiCodes.length >= 2
              ? Expanded(
                  child: _ComparisonTable(amfiCodes: _selectedAmfiCodes),
                )
              : const Expanded(
                  child: _EmptyState(),
                ),
      ],
    );
  }
}

// ── Search results list ───────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    required this.query,
    required this.selectedCodes,
    required this.onAdd,
  });

  final String query;
  final List<int> selectedCodes;
  final ValueChanged<int> onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(fundSearchProvider(query));
    return resultsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Search failed',
          style: TextStyle(color: context.palette.textTertiary),
        ),
      ),
      data: (funds) {
        if (funds.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No funds found',
              style: TextStyle(color: context.palette.textTertiary, fontSize: 13),
            ),
          );
        }
        return Container(
          constraints: const BoxConstraints(maxHeight: 240),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.palette.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.palette.bgDivider),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: funds.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: context.palette.bgDivider),
            itemBuilder: (context, index) {
              final fund = funds[index];
              final isSelected = selectedCodes.contains(fund.amfiCode);
              final canAdd = !isSelected && selectedCodes.length < 4;
              return ListTile(
                dense: true,
                title: Text(
                  fund.fundName,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? context.palette.textTertiary
                        : context.palette.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [fund.category, fund.amc]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(' • '),
                  style: TextStyle(
                    fontSize: 11,
                    color: context.palette.textTertiary,
                  ),
                ),
                trailing: canAdd
                    ? const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.primary,
                        size: 20,
                      )
                    : isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: context.palette.gain,
                            size: 20,
                          )
                        : null,
                onTap: canAdd ? () => onAdd(fund.amfiCode) : null,
              );
            },
          ),
        );
      },
    );
  }
}

// ── Comparison data table ─────────────────────────────────────────────────────

class _ComparisonTable extends ConsumerWidget {
  const _ComparisonTable({required this.amfiCodes});

  final List<int> amfiCodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundsAsync = amfiCodes.map((c) => ref.watch(fundDetailProvider(c)));
    final isLoading = fundsAsync.any((a) => a.isLoading);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final funds = fundsAsync
        .map((a) => a.whenOrNull(data: (f) => f))
        .where((f) => f != null)
        .toList();

    if (funds.isEmpty) {
      return Center(
        child: Text(
          'Could not load fund details',
          style: TextStyle(color: context.palette.textSecondary),
        ),
      );
    }

    // Determine best values per metric row (for highlighting)
    double? bestOf(Iterable<double?> values, {bool lowest = false}) {
      final valid = values.whereType<double>().toList();
      if (valid.isEmpty) return null;
      return lowest ? valid.reduce((a, b) => a < b ? a : b) : valid.reduce((a, b) => a > b ? a : b);
    }

    final best1y = bestOf(funds.map((f) => f!.return1y));
    final best3y = bestOf(funds.map((f) => f!.return3y));
    final best5y = bestOf(funds.map((f) => f!.return5y));
    final bestEr = bestOf(funds.map((f) => f!.expenseRatio), lowest: true);
    final bestAum = bestOf(funds.map((f) => f!.aumCr));
    final bestNav1d = bestOf(funds.map((f) => f!.nav1dChangePct));

    Color cellColor(double? value, double? bestValue) {
      if (value == null || bestValue == null) return context.palette.textPrimary;
      return value == bestValue ? context.palette.gain : context.palette.textPrimary;
    }

    // Build rows: label + values per fund
    List<DataRow> buildRows() {
      TextStyle styleFor(double? val, double? best) => TextStyle(
            fontSize: 12,
            color: cellColor(val, best),
            fontWeight:
                val != null && val == best ? FontWeight.bold : FontWeight.normal,
          );

      return [
        _row(context, 'NAV', funds.map((f) {
          final nav = f!.latestNav;
          return Text(
            nav != null ? nav.toNAV() : '—',
            style: TextStyle(fontSize: 12, color: context.palette.textPrimary),
          );
        }).toList()),
        _row(context, '1D Change', funds.map((f) {
          final v = f!.nav1dChangePct;
          return Text(
            v != null ? v.toPercent(decimals: 2, showSign: true) : '—',
            style: styleFor(v, bestNav1d),
          );
        }).toList()),
        _row(context, '1Y Return', funds.map((f) {
          final v = f!.return1y;
          return Text(
            v != null ? v.toPercent(decimals: 1, showSign: true) : '—',
            style: styleFor(v, best1y),
          );
        }).toList()),
        _row(context, '3Y Return', funds.map((f) {
          final v = f!.return3y;
          return Text(
            v != null ? v.toPercent(decimals: 1, showSign: true) : '—',
            style: styleFor(v, best3y),
          );
        }).toList()),
        _row(context, '5Y Return', funds.map((f) {
          final v = f!.return5y;
          return Text(
            v != null ? v.toPercent(decimals: 1, showSign: true) : '—',
            style: styleFor(v, best5y),
          );
        }).toList()),
        _row(context, 'Expense Ratio', funds.map((f) {
          final v = f!.expenseRatio;
          return Text(
            v != null ? v.toPercent(decimals: 2) : '—',
            style: v != null && v == bestEr
                ? TextStyle(
                    fontSize: 12,
                    color: context.palette.gain,
                    fontWeight: FontWeight.bold,
                  )
                : TextStyle(fontSize: 12, color: context.palette.textPrimary),
          );
        }).toList()),
        _row(context, 'AUM', funds.map((f) {
          final v = f!.aumCr;
          return Text(
            v != null ? (v * 1e7).toINRCompact() : '—',
            style: styleFor(v, bestAum),
          );
        }).toList()),
        _row(context, 'Rating', funds.map((f) {
          final r = f!.fundRating;
          return Text(
            r != null ? '$r ★' : '—',
            style: TextStyle(fontSize: 12, color: context.palette.textPrimary),
          );
        }).toList()),
        _row(context, 'Category', funds.map((f) {
          return Text(
            f!.category ?? '—',
            style: TextStyle(
              fontSize: 11,
              color: context.palette.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        }).toList()),
        _row(context, 'Tax Category', funds.map((f) {
          return Text(
            f!.taxCategory ?? '—',
            style: TextStyle(
              fontSize: 11,
              color: context.palette.textSecondary,
            ),
          );
        }).toList()),
        _row(context, 'Fund Manager(s)', funds.map((f) {
          return Text(
            f!.fundManagerDisplay,
            style: TextStyle(
              fontSize: 11,
              color: context.palette.textSecondary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          );
        }).toList()),
      ];
    }

    // Column widths
    const double labelColWidth = 110;
    const double fundColWidth = 130;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: DataTable(
          columnSpacing: 16,
          headingRowHeight: 48,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 72,
          headingRowColor: WidgetStateProperty.all(context.palette.bgCardElevated),
          border: TableBorder.all(
            color: context.palette.bgDivider,
            borderRadius: BorderRadius.circular(8),
          ),
          columns: [
            DataColumn(
              label: SizedBox(
                width: labelColWidth,
                child: Text(
                  'Metric',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
            ),
            ...funds.map((f) => DataColumn(
                  label: SizedBox(
                    width: fundColWidth,
                    child: Text(
                      f!.fundName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.palette.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )),
          ],
          rows: buildRows(),
        ),
      ),
    );
  }

  DataRow _row(BuildContext context, String label, List<Widget> cells) {
    return DataRow(cells: [
      DataCell(
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.palette.textTertiary,
          ),
        ),
      ),
      ...cells.map((c) => DataCell(c)),
    ]);
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.compare_arrows,
            size: 56,
            color: context.palette.textTertiary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Select 2–4 funds to compare',
            style: TextStyle(
              fontSize: 15,
              color: context.palette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for funds above and add them',
            style: TextStyle(
              fontSize: 12,
              color: context.palette.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
