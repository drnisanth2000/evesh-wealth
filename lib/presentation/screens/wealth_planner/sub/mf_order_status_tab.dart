import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../data/models/pending_order_model.dart';
import '../../../providers/pending_orders_provider.dart';
import '../../../providers/selected_member_provider.dart';

enum _KindFilter {
  all,
  sip,
  buy,
  switchOrder,
  swp,
  sell,
  gift;

  String get label => switch (this) {
        _KindFilter.all => 'All',
        _KindFilter.sip => 'SIP',
        _KindFilter.buy => 'Buy/Lumpsum',
        _KindFilter.switchOrder => 'Switch',
        _KindFilter.swp => 'SWP',
        _KindFilter.sell => 'Sell',
        _KindFilter.gift => 'Gift',
      };

  bool matches(OrderKind k) => switch (this) {
        _KindFilter.all => true,
        _KindFilter.sip => k == OrderKind.sip,
        _KindFilter.buy => k == OrderKind.buy || k == OrderKind.lumpsum,
        _KindFilter.switchOrder => k == OrderKind.switchOrder,
        _KindFilter.swp => k == OrderKind.swp,
        _KindFilter.sell => k == OrderKind.sell,
        _KindFilter.gift => k == OrderKind.gift,
      };
}

class MfOrderStatusTab extends ConsumerStatefulWidget {
  const MfOrderStatusTab({super.key});

  @override
  ConsumerState<MfOrderStatusTab> createState() => _MfOrderStatusTabState();
}

class _MfOrderStatusTabState extends ConsumerState<MfOrderStatusTab> {
  _KindFilter _filter = _KindFilter.all;

  @override
  Widget build(BuildContext context) {
    final memberId = ref.watch(selectedMemberProvider);
    final ordersAsync = ref.watch(pendingOrdersProvider(memberId));

    return Column(
      children: [
        _FilterPills(
          selected: _filter,
          onChanged: (f) => setState(() => _filter = f),
        ),
        const Divider(height: 1),
        Expanded(
          child: ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _errorView(context, '$e'),
            data: (orders) {
              final filtered =
                  orders.where((o) => _filter.matches(o.kind)).toList();
              if (filtered.isEmpty) return _emptyView(context);
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _OrderCard(order: filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _emptyView(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 56, color: context.palette.textTertiary),
              const SizedBox(height: 12),
              Text(
                'No orders yet — record your next buy in the Buy tab',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.palette.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );

  Widget _errorView(BuildContext context, String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.loss, size: 48),
              const SizedBox(height: 12),
              Text('Error loading orders',
                  style: TextStyle(color: context.palette.textSecondary)),
              const SizedBox(height: 4),
              Text(msg,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11, color: context.palette.textTertiary)),
            ],
          ),
        ),
      );
}

class _FilterPills extends StatelessWidget {
  const _FilterPills({required this.selected, required this.onChanged});

  final _KindFilter selected;
  final ValueChanged<_KindFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (final f in _KindFilter.values)
            _PillChip(
              label: f.label,
              selected: f == selected,
              onTap: () => onChanged(f),
            ),
        ],
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : context.palette.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : context.palette.bgDivider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : context.palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final PendingOrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final kind = order.kind;
    final status = order.statusEnum;
    final created = DateTime.tryParse(order.createdAt);
    final createdLabel =
        created == null ? '' : DateFormat('dd MMM yyyy').format(created);

    final amountLabel = order.amount != null
        ? '₹${NumberFormat('#,##,###').format(order.amount)}'
        : order.units != null
            ? '${order.units!.toStringAsFixed(3)} units'
            : '—';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.bgDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  order.fundName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _Chip(label: kind.displayName, color: AppColors.primary),
              _OrderMenu(order: order),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                amountLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const Spacer(),
              _Chip(label: status.displayName, color: _statusColor(status)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            createdLabel,
            style: TextStyle(fontSize: 11, color: palette.textTertiary),
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.draft => AppColors.warning,
        OrderStatus.placed => AppColors.primary,
        OrderStatus.executed => AppColors.gain,
        OrderStatus.cancelled => AppColors.loss,
      };
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _OrderMenu extends ConsumerWidget {
  const _OrderMenu({required this.order});
  final PendingOrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = order.statusEnum.isOpen;
    return PopupMenuButton<String>(
      iconSize: 18,
      padding: EdgeInsets.zero,
      onSelected: (v) async {
        final mutator = ref.read(pendingOrdersMutatorProvider.notifier);
        try {
          switch (v) {
            case 'executed':
              await mutator.markExecuted(order.id);
              break;
            case 'cancel':
              await mutator.cancel(order.id);
              break;
            case 'delete':
              await mutator.cancel(order.id);
              break;
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: $e')),
            );
          }
        }
      },
      itemBuilder: (_) => [
        if (isOpen)
          const PopupMenuItem(
              value: 'executed', child: Text('Mark executed')),
        if (isOpen) const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}
