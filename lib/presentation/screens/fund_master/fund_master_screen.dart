import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../providers/portfolio_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/asset_type_selector.dart';
import '../../widgets/common/member_selector.dart';
import '../../../data/models/portfolio_summary_model.dart';

// ─── Portfolio sort options ───────────────────────────────────────────────────
enum _PortfolioSort {
  valueDesc('Value: High \u2192 Low'),
  gainDesc('Gain: High \u2192 Low'),
  gainAsc('Gain: Low \u2192 High'),
  gainPctDesc('Gain %: High \u2192 Low'),
  xirrDesc('XIRR: High \u2192 Low'),
  todayDesc("Today's \u0394: High \u2192 Low"),
  return1yDesc('1Y Return: High \u2192 Low'),
  investedAsc('Invested: Oldest First'),
  nameAsc('Fund: A \u2192 Z');

  const _PortfolioSort(this.label);
  final String label;
}

class FundMasterScreen extends ConsumerStatefulWidget {
  const FundMasterScreen({super.key});

  @override
  ConsumerState<FundMasterScreen> createState() => _FundMasterScreenState();
}

class _FundMasterScreenState extends ConsumerState<FundMasterScreen> {
  String? _selectedMemberId;
  String? _selectedAssetType;
  String _searchQuery = '';
  String? _filterCategory;
  _PortfolioSort _sort = _PortfolioSort.valueDesc;

  @override
  Widget build(BuildContext context) {
    final portfolioAsync = ref.watch(portfolioSummaryProvider(_selectedMemberId));

    // Collect available asset types from transactions
    final txAsync = ref.watch(allTransactionsProvider);
    final availableTypes = <String>{};
    final txList = txAsync.valueOrNull ?? [];
    for (final t in txList) {
      if (_selectedMemberId == null || t.memberId == _selectedMemberId) {
        availableTypes.add(t.assetType);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search portfolio...',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Member selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: MemberSelector(
              selectedMemberId: _selectedMemberId,
              onSelected: (id) => setState(() {
                _selectedMemberId = id;
                _selectedAssetType = null;
              }),
            ),
          ),

          // Asset type selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AssetTypeSelector(
              selectedType: _selectedAssetType,
              availableTypes: availableTypes,
              onSelected: (type) =>
                  setState(() => _selectedAssetType = type),
            ),
          ),

          // Fund list
          Expanded(
            child: portfolioAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (portfolio) {
                final funds = portfolio.fundHoldings.where((f) {
                  // Asset type filter
                  if (_selectedAssetType != null && f.assetType != _selectedAssetType) {
                    return false;
                  }
                  if (_searchQuery.isNotEmpty) {
                    return f.fundName.toLowerCase().contains(_searchQuery);
                  }
                  if (_filterCategory != null) {
                    return f.category == _filterCategory;
                  }
                  return true;
                }).toList();

                // Apply sort
                switch (_sort) {
                  case _PortfolioSort.valueDesc:
                    funds.sort((a, b) => b.currentValue.compareTo(a.currentValue));
                  case _PortfolioSort.gainDesc:
                    funds.sort((a, b) => b.gain.compareTo(a.gain));
                  case _PortfolioSort.gainAsc:
                    funds.sort((a, b) => a.gain.compareTo(b.gain));
                  case _PortfolioSort.gainPctDesc:
                    funds.sort((a, b) => b.gainPct.compareTo(a.gainPct));
                  case _PortfolioSort.xirrDesc:
                    funds.sort((a, b) => (b.xirr ?? -99).compareTo(a.xirr ?? -99));
                  case _PortfolioSort.todayDesc:
                    funds.sort((a, b) => b.todayGain.compareTo(a.todayGain));
                  case _PortfolioSort.return1yDesc:
                    funds.sort((a, b) => (b.return1y ?? -99).compareTo(a.return1y ?? -99));
                  case _PortfolioSort.investedAsc:
                    funds.sort((a, b) {
                      final aDate = a.investedSince ?? DateTime(2099);
                      final bDate = b.investedSince ?? DateTime(2099);
                      return aDate.compareTo(bDate);
                    });
                  case _PortfolioSort.nameAsc:
                    funds.sort((a, b) =>
                        a.fundName.toLowerCase().compareTo(b.fundName.toLowerCase()));
                }

                if (funds.isEmpty) {
                  return _buildEmptyState(context);
                }

                return Column(
                  children: [
                    // ── Sort bar ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          Text(
                            '${funds.length} fund${funds.length == 1 ? '' : 's'}',
                            style: TextStyle(
                                fontSize: 12, color: context.palette.textTertiary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 30,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: context.palette.bgDivider, width: 1),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<_PortfolioSort>(
                                  value: _sort,
                                  isDense: true,
                                  isExpanded: true,
                                  icon: const Icon(Icons.sort, size: 14),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: context.palette.textSecondary),
                                  items: _PortfolioSort.values
                                      .map((s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s.label),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _sort = v);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Fund list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: funds.length,
                        itemBuilder: (ctx, i) => _FundCard(
                          fund: funds[i],
                          onTap: () =>
                              context.push('/portfolio/${funds[i].amfiCode}'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_outlined, size: 56, color: context.palette.textTertiary),
          const SizedBox(height: 16),
          Text('No holdings in portfolio',
              style: TextStyle(color: context.palette.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.push(Routes.addTransaction),
            child: const Text('Add your first transaction'),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => _FilterSheet(
        selected: _filterCategory,
        onSelected: (cat) {
          setState(() => _filterCategory = cat);
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Expandable fund card showing per-holder breakdown
class _FundCard extends StatefulWidget {
  const _FundCard({required this.fund, required this.onTap});
  final FundHoldingSummary fund;
  final VoidCallback onTap;

  @override
  State<_FundCard> createState() => _FundCardState();
}

class _FundCardState extends State<_FundCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.fund;
    final isGain = f.gain >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // ── Fund header row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.fundName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (f.category != null)
                                  _Chip(f.category!),
                                const SizedBox(width: 4),
                                if (f.assetClassLabel != null)
                                  _Chip(f.assetClassLabel!, color: AppColors.primary),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            f.currentValue.toINRCompact(),
                            style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700,
                            ),
                          ),
                          // 1D change (like other apps)
                          if (f.todayGain != 0 || f.nav1dChangePct != null) ...[
                            Text(
                              '1D: ${f.todayGain >= 0 ? '+' : ''}${f.todayGain.toINRCompact()} (${f.nav1dChangePct != null ? f.nav1dChangePct!.toReturnLabel() : '—'})',
                              style: TextStyle(
                                fontSize: 11,
                                color: f.todayGain >= 0 ? AppColors.gain : AppColors.loss,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ] else
                            Text(
                              '${isGain ? '+' : ''}${f.gain.toINRCompact()} (${f.gainPct.toReturnLabel()})',
                              style: TextStyle(
                                fontSize: 12,
                                color: isGain ? AppColors.gain : AppColors.loss,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // ── Investor details row ──────────────────────────────────
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (f.investedSince != null)
                        _DetailChip(Icons.calendar_today_outlined,
                            'Since ${f.investedSince!.displayDate}'),
                      if (f.holdingPeriodFormatted != null)
                        _DetailChip(Icons.schedule_outlined,
                            f.holdingPeriodFormatted!),
                      if (f.planType != null)
                        _DetailChip(
                            f.planType == 'Direct'
                                ? Icons.bolt_outlined
                                : Icons.storefront_outlined,
                            f.planType!,
                            color: _planTypeColor(f.planType)),
                      if (f.taxCategory != null)
                        _DetailChip(Icons.category_outlined,
                            f.taxCategory!,
                            color: _taxCategoryColor(context, f.taxCategory)),
                      if (f.expenseRatio != null)
                        _DetailChip(Icons.percent_outlined,
                            'ER ${f.expenseRatio!.toStringAsFixed(2)}%'),
                      if (f.return1y != null)
                        _DetailChip(
                            f.return1y! >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            '1Y ${f.return1y! >= 0 ? '+' : ''}${f.return1y!.toStringAsFixed(1)}%'),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // ── Metrics row ───────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MetricCol(
                        label: 'Invested',
                        value: f.totalInvested.toINRCompact(),
                      ),
                      _MetricCol(
                        label: 'Gain/Loss',
                        value: '${f.gain >= 0 ? '+' : ''}${f.gain.toINRCompact()}',
                        valueColor: f.gain >= 0 ? AppColors.gain : AppColors.loss,
                      ),
                      _MetricCol(
                        label: 'Units',
                        value: f.totalUnits.toUnits(),
                      ),
                      _MetricCol(
                        label: 'NAV',
                        value: f.latestNav?.toNAV() ?? '—',
                      ),
                      _MetricCol(
                        label: 'XIRR',
                        value: f.xirr != null ? f.xirr!.toReturnLabel() : '—',
                        valueColor: f.xirr != null
                            ? (f.xirr! >= 0 ? AppColors.gain : AppColors.loss)
                            : null,
                      ),
                      _MetricCol(
                        label: 'CAGR',
                        value: f.cagr != null ? f.cagr!.toReturnLabel() : '—',
                        valueColor: f.cagr != null
                            ? (f.cagr! >= 0 ? AppColors.gain : AppColors.loss)
                            : null,
                      ),
                    ],
                  ),

                  // ── Expand button (show holders) ──────────────────────────
                  if (f.holderBreakdown.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _expanded
                                ? 'Hide details  ▲'
                                : f.holderBreakdown.length == 1
                                    ? '${f.holderBreakdown.first.memberName}  ▼'
                                    : '${f.holderBreakdown.length} holders  ▼',
                            style: const TextStyle(
                              fontSize: 12, color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Expanded holder breakdown ─────────────────────────────────────
            if (_expanded && f.holderBreakdown.isNotEmpty) ...[
              const Divider(height: 1),
              ...f.holderBreakdown.map((h) {
                final hIsGain = h.gain >= 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(h.memberName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          Text(h.currentValue.toINRCompact(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MetricCol(label: 'Invested', value: h.invested.toINRCompact()),
                          _MetricCol(
                            label: 'Gain',
                            value: '${hIsGain ? '+' : ''}${h.gain.toINRCompact()}',
                            valueColor: hIsGain ? AppColors.gain : AppColors.loss,
                          ),
                          _MetricCol(
                            label: 'XIRR',
                            value: h.xirr != null ? h.xirr!.toReturnLabel() : '—',
                            valueColor: h.xirr != null
                                ? (h.xirr! >= 0 ? AppColors.gain : AppColors.loss)
                                : null,
                          ),
                          _MetricCol(
                            label: 'CAGR',
                            value: h.cagr != null ? h.cagr!.toReturnLabel() : '—',
                            valueColor: h.cagr != null
                                ? (h.cagr! >= 0 ? AppColors.gain : AppColors.loss)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? context.palette.textSecondary).withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color ?? context.palette.textSecondary),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip(this.icon, this.text, {this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: c),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: 10, color: c)),
        ],
      ),
    );
  }
}

Color _taxCategoryColor(BuildContext context, String? taxCategory) {
  switch (taxCategory?.toLowerCase()) {
    case 'equity':
      return const Color(0xFF1B8A5A); // green
    case 'hybrid-e':
    case 'hybrid-equity':
      return const Color(0xFF3B82F6); // blue
    case 'hybrid-d':
    case 'hybrid-debt':
      return const Color(0xFF8B5CF6); // violet
    case 'debt':
      return const Color(0xFF8B5CF6); // violet
    case 'gold':
    case 'gold etf':
      return const Color(0xFFF59E0B); // amber
    case 'liquid':
      return const Color(0xFF06B6D4); // cyan
    default:
      return context.palette.textTertiary;
  }
}

Color _planTypeColor(String? planType) {
  if (planType == 'Direct') return const Color(0xFF1B8A5A); // green
  return const Color(0xFFF59E0B); // amber for Regular
}

class _MetricCol extends StatelessWidget {
  const _MetricCol({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: context.palette.textTertiary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: valueColor ?? context.palette.textPrimary,
        )),
      ],
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({this.selected, required this.onSelected});
  final String? selected;
  final void Function(String?) onSelected;

  static const _categories = [
    'Flexi Cap Fund', 'Large Cap Fund', 'Mid Cap Fund', 'Small Cap Fund',
    'Multi Cap Fund', 'ELSS', 'Liquid Fund', 'Short Duration Fund',
    'Corporate Bond Fund', 'Dynamic Bond Fund', 'Hybrid Fund',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Filter by Category', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        ListTile(
          title: const Text('All'),
          leading: selected == null
              ? const Icon(Icons.radio_button_checked, color: AppColors.primary)
              : const Icon(Icons.radio_button_unchecked),
          onTap: () => onSelected(null),
        ),
        ..._categories.map((cat) => ListTile(
          title: Text(cat),
          leading: selected == cat
              ? const Icon(Icons.radio_button_checked, color: AppColors.primary)
              : const Icon(Icons.radio_button_unchecked),
          onTap: () => onSelected(cat),
        )),
        const SizedBox(height: 16),
      ],
    );
  }
}
