import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/asset_classes.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/portfolio_summary_model.dart';
import 'move_to_asset_class_sheet.dart';

/// One fund row. Shows name, Rs value, 1d delta %, asset class, and a
/// trailing popup: "Move to another asset class" + conditional "Rebalance"
/// when the parent asset class has a warning/critical drift flag.
class HoldingRow extends ConsumerWidget {
  const HoldingRow({
    super.key,
    required this.holding,
    required this.showRebalanceCta,
    this.currentAssetClass,
    this.onMoveToAssetClass,
  });

  final FundHoldingSummary holding;
  final bool showRebalanceCta;

  /// The asset class the row is currently grouped under — used to highlight
  /// the current selection in the Move sheet.
  final AssetClass? currentAssetClass;
  final VoidCallback? onMoveToAssetClass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navChange = holding.nav1dChangePct ?? 0;
    final changeColor = navChange >= 0 ? AppColors.gain : AppColors.loss;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(holding.fundName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  '${holding.totalUnits.toStringAsFixed(3)} units \u00B7 ${holding.assetClassLabel ?? holding.category ?? '\u2014'}',
                  style: TextStyle(
                      fontSize: 11, color: context.palette.textTertiary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(holding.currentValue.toINRCompact(),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text(
                '${navChange >= 0 ? '+' : ''}${navChange.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 11, color: changeColor),
              ),
            ],
          ),
          const SizedBox(width: 4),
          PopupMenuButton<_HoldingAction>(
            icon: const Icon(Icons.more_vert, size: 18),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: _HoldingAction.move,
                child: Text('Move to another asset class'),
              ),
              if (showRebalanceCta)
                const PopupMenuItem(
                  value: _HoldingAction.rebalance,
                  child: Text('Rebalance'),
                ),
            ],
            onSelected: (action) {
              switch (action) {
                case _HoldingAction.move:
                  if (onMoveToAssetClass != null) {
                    onMoveToAssetClass!.call();
                  } else {
                    MoveToAssetClassSheet.show(
                      context: context,
                      amfiCode: holding.amfiCode,
                      title: holding.fundName,
                      currentAssetClass: currentAssetClass,
                    );
                  }
                case _HoldingAction.rebalance:
                  context.go(
                    '/wealth-planner/rebalance?focus=${holding.amfiCode}',
                  );
              }
            },
          ),
        ],
      ),
    );
  }
}

enum _HoldingAction { move, rebalance }
