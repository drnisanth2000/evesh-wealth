import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/asset_type_selector.dart';
import '../../widgets/common/member_selector.dart';

// ─── Sort options ────────────────────────────────────────────────────────────
enum _SortOption {
  dateDesc('Latest Date First'),
  dateAsc('Oldest Date First'),
  amountDesc('Amount: High to Low'),
  amountAsc('Amount: Low to High'),
  nameAsc('Scheme: A → Z'),
  nameDesc('Scheme: Z → A');

  const _SortOption(this.label);
  final String label;
}

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key, this.initialSearch});

  final String? initialSearch;

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState
    extends ConsumerState<TransactionListScreen> {
  String? _selectedMemberId;
  String? _selectedAssetType;
  late String _search;
  bool _selectMode = false;
  final Set<String> _selectedIds = {};
  _SortOption _sort = _SortOption.dateDesc;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _search = widget.initialSearch ?? '';
    _searchController = TextEditingController(text: _search);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) _selectedIds.clear();
    });
  }

  void _toggleItem(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<TransactionModel> filtered) {
    setState(() {
      if (_selectedIds.length == filtered.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(filtered.map((t) => t.id));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transactions?'),
        content: Text(
            'Delete $count selected transaction${count == 1 ? '' : 's'}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.loss)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final client = ref.read(supabaseClientProvider);
    await client
        .from('transactions')
        .delete()
        .inFilter('id', _selectedIds.toList());

    ref.invalidate(allTransactionsProvider);
    ref.invalidate(portfolioSummaryProvider);
    ref.invalidate(latestNavMapProvider);
    setState(() {
      _selectMode = false;
      _selectedIds.clear();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count transaction${count == 1 ? '' : 's'} deleted'),
        backgroundColor: AppColors.gain,
      ),
    );
  }

  Future<void> _clearAll(List<TransactionModel> filtered) async {
    final count = filtered.length;
    final label = _selectedMemberId != null ? 'this member' : 'all members';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all transactions?'),
        content: Text(
            'Delete all $count transaction${count == 1 ? '' : 's'} for $label? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All',
                style: TextStyle(color: AppColors.loss)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final ids = filtered.map((t) => t.id).toList();

    for (var i = 0; i < ids.length; i += 100) {
      final batch =
          ids.sublist(i, i + 100 > ids.length ? ids.length : i + 100);
      await client
          .from('transactions')
          .delete()
          .inFilter('id', batch)
          .eq('owner_id', userId);
    }

    ref.invalidate(allTransactionsProvider);
    ref.invalidate(portfolioSummaryProvider);
    ref.invalidate(latestNavMapProvider);
    setState(() {
      _selectMode = false;
      _selectedIds.clear();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count transaction${count == 1 ? '' : 's'} deleted'),
        backgroundColor: AppColors.gain,
      ),
    );
  }

  /// Collect distinct asset types from the (member-filtered) list.
  Set<String> _availableAssetTypes(List<TransactionModel> txList) {
    return txList
        .where((t) =>
            _selectedMemberId == null || t.memberId == _selectedMemberId)
        .map((t) => t.assetType)
        .toSet();
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> txList) {
    var result = txList.where((t) {
      if (_selectedMemberId != null && t.memberId != _selectedMemberId) {
        return false;
      }
      if (_selectedAssetType != null && t.assetType != _selectedAssetType) {
        return false;
      }
      if (_search.isNotEmpty) {
        final name =
            (t.fundMaster?.fundName ?? t.assetName ?? '').toLowerCase();
        return name.contains(_search);
      }
      return true;
    }).toList();

    // Apply sort
    switch (_sort) {
      case _SortOption.dateDesc:
        result.sort((a, b) => b.txDate.compareTo(a.txDate));
      case _SortOption.dateAsc:
        result.sort((a, b) => a.txDate.compareTo(b.txDate));
      case _SortOption.amountDesc:
        result.sort((a, b) => b.amount.compareTo(a.amount));
      case _SortOption.amountAsc:
        result.sort((a, b) => a.amount.compareTo(b.amount));
      case _SortOption.nameAsc:
        result.sort((a, b) {
          final an = a.fundMaster?.fundName ?? a.assetName ?? '';
          final bn = b.fundMaster?.fundName ?? b.assetName ?? '';
          return an.toLowerCase().compareTo(bn.toLowerCase());
        });
      case _SortOption.nameDesc:
        result.sort((a, b) {
          final an = a.fundMaster?.fundName ?? a.assetName ?? '';
          final bn = b.fundMaster?.fundName ?? b.assetName ?? '';
          return bn.toLowerCase().compareTo(an.toLowerCase());
        });
    }

    return result;
  }

  void _confirmDelete(TransactionModel tx) {
    final name =
        tx.fundMaster?.fundName ?? tx.assetName ?? 'this transaction';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text('Remove "$name" on ${tx.txDate}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref
                  .read(transactionNotifierProvider.notifier)
                  .deleteTransaction(tx.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.loss)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _selectMode ? '${_selectedIds.length} selected' : 'Transactions'),
        leading: _selectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectMode,
              )
            : null,
        actions: [
          if (!_selectMode) ...[
            IconButton(
              icon: const Icon(Icons.checklist_outlined),
              tooltip: 'Select',
              onPressed: _toggleSelectMode,
            ),
            IconButton(
              icon: const Icon(Icons.upload_outlined),
              tooltip: 'Upload MF Central',
              onPressed: () => context.push(Routes.uploadMfCentral),
            ),
          ],
          if (_selectMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select all',
              onPressed: () {
                final txList = txAsync.valueOrNull ?? [];
                final filtered = _applyFilters(txList);
                _selectAll(filtered);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete selected',
              color: AppColors.loss,
              onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search fund or asset...',
                prefixIcon: Icon(Icons.search, size: 18),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: MemberSelector(
              selectedMemberId: _selectedMemberId,
              onSelected: (id) => setState(() {
                _selectedMemberId = id;
                _selectedAssetType = null;
                _selectedIds.clear();
              }),
            ),
          ),
          // Asset type filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AssetTypeSelector(
              selectedType: _selectedAssetType,
              availableTypes:
                  _availableAssetTypes(txAsync.valueOrNull ?? []),
              onSelected: (type) => setState(() {
                _selectedAssetType = type;
                _selectedIds.clear();
              }),
            ),
          ),
          Expanded(
            child: txAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (txList) {
                final filtered = _applyFilters(txList);

                if (filtered.isEmpty) {
                  return _EmptyState(
                    onAdd: () => context.push(Routes.addTransaction),
                  );
                }

                return Column(
                  children: [
                    // ── Sort bar + count + clear ───────────────────────
                    if (!_selectMode)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            Text(
                              '${filtered.length} transaction${filtered.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.palette.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Sort dropdown
                            Expanded(
                              child: Container(
                                height: 30,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: context.palette.bgDivider, width: 1),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<_SortOption>(
                                    value: _sort,
                                    isDense: true,
                                    isExpanded: true,
                                    icon: const Icon(Icons.sort, size: 14),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.palette.textSecondary),
                                    items: _SortOption.values
                                        .map((s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(s.label),
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => _sort = v);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton.icon(
                              onPressed: () => _clearAll(filtered),
                              icon: const Icon(Icons.delete_sweep_outlined,
                                  size: 14, color: AppColors.loss),
                              label: const Text('Clear',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.loss)),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // ── Transaction list ───────────────────────────────
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 4),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _TxTile(
                          tx: filtered[i],
                          selectMode: _selectMode,
                          isSelected:
                              _selectedIds.contains(filtered[i].id),
                          onTap: _selectMode
                              ? () => _toggleItem(filtered[i].id)
                              : () => context.push(
                                    Routes.addTransaction,
                                    extra: filtered[i],
                                  ),
                          onDelete: () => _confirmDelete(filtered[i]),
                        ),
                      ),
                    ),
                    // ── NAV last updated footer ────────────────────────
                    Consumer(builder: (context, ref, _) {
                      final navTs = ref.watch(navLastUpdatedProvider);
                      return navTs.when(
                        data: (dt) {
                          if (dt == null) return const SizedBox.shrink();
                          final local = dt.toLocal();
                          final formatted = DateFormat('dd MMM yyyy, hh:mm a').format(local);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'NAV as of $formatted',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.palette.textSecondary.withOpacity(0.6),
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push(Routes.addTransaction),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}

// ─── Transaction type → color mapping ────────────────────────────────────────
Color txTypeColor(String txType) {
  switch (txType) {
    // Green — money going IN (purchases / accumulation)
    case 'BUY':
    case 'SIP':
    case 'Switch-In':
    case 'STP-In':
    case 'Bonus':
    case 'IDCW':
    case 'IDCW-Reinvest':
    case 'Transfer-In':
    case 'Opening Balance':
      return AppColors.gain;
    // Red — money going OUT (sells / redemptions)
    case 'SELL':
    case 'SWP':
    case 'Switch-Out':
    case 'STP-Out':
    case 'Transfer-Out':
      return AppColors.loss;
    // Orange — cash only (no unit movement)
    case 'IDCW-Payout':
      return Colors.orange;
    // Other / neutral
    default:
      return AppColors.info;
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({
    required this.tx,
    required this.onDelete,
    this.selectMode = false,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
  });
  final TransactionModel tx;
  final VoidCallback onDelete;
  final bool selectMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final name =
        tx.fundMaster?.fundName ?? tx.assetName ?? tx.assetType ?? '—';
    final typeColor = txTypeColor(tx.txType);
    final isPurchase = tx.isPurchase;

    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: selectMode
          ? Checkbox(
              value: isSelected,
              onChanged: (_) => onTap?.call(),
              activeColor: AppColors.primary,
            )
          : Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          _buildTypeBadge(tx.txType, typeColor),
          const SizedBox(width: 6),
          Text(
            tx.txDate,
            style: TextStyle(
                fontSize: 11, color: context.palette.textTertiary),
          ),
          if (tx.units != null) ...[
            const SizedBox(width: 6),
            Text(
              '${tx.units!.toStringAsFixed(3)} units',
              style: TextStyle(
                  fontSize: 11, color: context.palette.textTertiary),
            ),
          ],
        ],
      ),
      trailing: selectMode
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isPurchase ? '' : '+'}₹${_fmt(tx.amount)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isPurchase ? context.palette.textPrimary : AppColors.gain,
                      ),
                    ),
                    if (tx.navAtTx != null)
                      Text(
                        'NAV ₹${tx.navAtTx!.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 10, color: context.palette.textTertiary),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: context.palette.textTertiary,
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
    );
  }

  Widget _buildTypeBadge(String txType, Color typeColor) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: txType == 'Opening Balance'
            ? Border.all(color: typeColor.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (txType == 'Opening Balance') ...[
            Icon(Icons.account_balance_wallet, size: 10, color: typeColor),
            const SizedBox(width: 3),
          ],
          Text(
            txType,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: typeColor),
          ),
        ],
      ),
    );

    if (txType == 'Opening Balance') {
      return Tooltip(
        message: 'Estimated cost basis for holdings purchased before CAS date range',
        child: badge,
      );
    }
    return badge;
  }

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 56, color: context.palette.textTertiary),
          const SizedBox(height: 16),
          Text('No transactions yet',
              style:
                  TextStyle(color: context.palette.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add first transaction'),
          ),
        ],
      ),
    );
  }
}
