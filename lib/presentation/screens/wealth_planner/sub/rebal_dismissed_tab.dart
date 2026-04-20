import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../data/models/pending_order_model.dart';
import '../../../../data/models/rebalance_dismissal_model.dart';
import '../../../providers/pending_orders_provider.dart';
import '../../../providers/portfolio_provider.dart';
import '../../../providers/rebalance_dismissal_provider.dart';
import '../../../providers/selected_member_provider.dart';

class RebalDismissedTab extends ConsumerWidget {
  const RebalDismissedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberId = ref.watch(selectedMemberProvider);
    final dismissalsAsync = ref.watch(rebalanceDismissalsProvider(memberId));
    final portfolioAsync = ref.watch(portfolioSummaryProvider(memberId));

    return dismissalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (dismissals) {
        if (dismissals.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 48, color: context.palette.textTertiary),
                const SizedBox(height: 8),
                Text(
                  'No dismissed suggestions',
                  style: TextStyle(
                      fontSize: 13, color: context.palette.textSecondary),
                ),
              ],
            ),
          );
        }
        final amfiToName = <int, String>{};
        portfolioAsync.whenData((p) {
          for (final h in p.fundHoldings) {
            amfiToName[h.amfiCode] = h.fundName;
          }
        });
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dismissals.length,
          itemBuilder: (_, i) => _DismissalCard(
            dismissal: dismissals[i],
            fundLabel: amfiToName[dismissals[i].fromAmfiCode ?? -1],
            memberId: memberId,
          ),
        );
      },
    );
  }
}

class _DismissalCard extends ConsumerStatefulWidget {
  const _DismissalCard({
    required this.dismissal,
    required this.fundLabel,
    required this.memberId,
  });
  final RebalanceDismissalModel dismissal;
  final String? fundLabel;
  final String? memberId;

  @override
  ConsumerState<_DismissalCard> createState() => _DismissalCardState();
}

class _DismissalCardState extends ConsumerState<_DismissalCard> {
  bool _busy = false;

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(rebalanceDismissalsMutatorProvider.notifier)
          .restore(widget.dismissal.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restored to Actions')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _execute() async {
    setState(() => _busy = true);
    try {
      final amfi = widget.dismissal.fromAmfiCode;
      await ref.read(pendingOrdersMutatorProvider.notifier).add(
            fundName: widget.fundLabel ??
                (amfi != null ? 'AMFI #$amfi' : 'Unknown fund'),
            kind: OrderKind.buy,
            amfiCode: amfi,
            status: OrderStatus.placed,
            source: OrderSource.rebalance,
            memberId: widget.memberId,
            notes: 'From dismissed rebalance',
          );
      await ref
          .read(rebalanceDismissalsMutatorProvider.notifier)
          .restore(widget.dismissal.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order recorded')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Execute failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final d = widget.dismissal;
    final amfi = d.fromAmfiCode;
    final label = widget.fundLabel ??
        (amfi != null ? 'AMFI #$amfi' : 'Unknown fund');
    final dismissedAt = DateTime.tryParse(d.dismissedAt)
            ?.toLocal()
            .toString()
            .substring(0, 10) ??
        d.dismissedAt;
    final drift = d.driftPct;
    final barColor =
        drift != null && drift > 0 ? AppColors.loss : AppColors.info;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.bgDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Dismissed $dismissedAt',
                        style: TextStyle(
                            fontSize: 11, color: palette.textTertiary)),
                  ],
                ),
              ),
              if (drift != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Drift ${drift >= 0 ? '+' : ''}${drift.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: barColor),
                  ),
                ),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: _busy ? null : _restore,
                  child: const Text('Restore')),
              const SizedBox(width: 4),
              FilledButton(
                  onPressed: _busy ? null : _execute,
                  child: const Text('Execute')),
            ]),
          ],
        ),
      ),
    );
  }
}
