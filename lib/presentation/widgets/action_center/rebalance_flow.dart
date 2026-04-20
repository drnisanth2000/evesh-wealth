import 'package:flutter/material.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/action_models.dart';

/// 3-column money movement visualization.
/// Source Fund | →Amount→ | Destination Fund + Action
class RebalanceFlow extends StatelessWidget {
  const RebalanceFlow({
    super.key,
    required this.moves,
    required this.rationale,
  });

  final List<FundMove> moves;
  final List<String> rationale;

  @override
  Widget build(BuildContext context) {
    // Filter to actionable moves only (skip holds)
    final actionMoves = moves.where((m) => m.moveType != MoveType.hold).toList();
    final holdMoves = moves.where((m) => m.moveType == MoveType.hold).toList();

    if (actionMoves.isEmpty && holdMoves.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.bgDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Money Movement',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Action moves
            if (actionMoves.isNotEmpty) ...[
              // Header row
              Row(
                children: [
                  Expanded(flex: 3, child: Text('From', style: TextStyle(fontSize: 10, color: context.palette.textTertiary, fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Center(child: Text('Amount', style: TextStyle(fontSize: 10, color: context.palette.textTertiary, fontWeight: FontWeight.w600)))),
                  Expanded(flex: 3, child: Text('To', style: TextStyle(fontSize: 10, color: context.palette.textTertiary, fontWeight: FontWeight.w600))),
                ],
              ),
              const Divider(height: 16),
              ...actionMoves.map((move) => _MoveRow(move: move)),
            ],

            // Hold moves
            if (holdMoves.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              ...holdMoves.map((move) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const _Tag('HOLD', AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            move.sourceFundName ?? '?',
                            style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          move.amount.toINR(compact: true),
                          style: TextStyle(fontSize: 11, color: context.palette.textTertiary),
                        ),
                      ],
                    ),
                  )),
            ],

            // Rationale
            if (rationale.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Why these changes?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.palette.textSecondary),
              ),
              const SizedBox(height: 6),
              ...rationale.map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(fontSize: 12, color: context.palette.textTertiary)),
                        Expanded(
                          child: Text(
                            r,
                            style: TextStyle(fontSize: 11, color: context.palette.textTertiary),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({required this.move});
  final FundMove move;

  Color get _moveColor {
    switch (move.moveType) {
      case MoveType.shift:
        return AppColors.primary;
      case MoveType.deployCash:
        return AppColors.info;
      case MoveType.sell:
        return AppColors.loss;
      case MoveType.buy:
        return AppColors.gain;
      case MoveType.hold:
        return AppColors.warning;
    }
  }

  String get _tagLabel {
    switch (move.moveType) {
      case MoveType.shift:
        return 'SHIFT';
      case MoveType.deployCash:
        return 'DEPLOY';
      case MoveType.sell:
        return 'SELL';
      case MoveType.buy:
        return 'BUY';
      case MoveType.hold:
        return 'HOLD';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Source
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  move.sourceFundName ?? 'Cash',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.palette.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (move.sourceAssetClass != null)
                  Text(
                    move.sourceAssetClass!,
                    style: TextStyle(fontSize: 9, color: context.palette.textTertiary),
                  ),
              ],
            ),
          ),

          // Arrow + amount
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _Tag(_tagLabel, _moveColor),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 16, height: 1, color: _moveColor),
                    Icon(Icons.arrow_forward, size: 12, color: _moveColor),
                  ],
                ),
                Text(
                  move.amount.toINR(compact: true),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _moveColor),
                ),
              ],
            ),
          ),

          // Destination
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  move.destFundName ?? 'Cash',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.palette.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (move.destAssetClass != null)
                  Text(
                    move.destAssetClass!,
                    style: TextStyle(fontSize: 9, color: context.palette.textTertiary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
