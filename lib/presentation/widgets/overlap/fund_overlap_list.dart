import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/overlap_models.dart';
import 'traffic_light.dart';

/// List of fund pair overlaps, sorted by overlap percentage descending.
/// Each card is expandable to show the top common holdings.
class FundOverlapList extends StatelessWidget {
  final List<FundPairOverlap> pairs;

  const FundOverlapList({super.key, required this.pairs});

  @override
  Widget build(BuildContext context) {
    if (pairs.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Add at least 2 mutual funds to see fund overlap analysis.',
          style: TextStyle(color: context.palette.textSecondary, fontSize: 13),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: pairs
            .map((pair) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FundOverlapItem(pair: pair),
                ))
            .toList(),
      ),
    );
  }
}

class _FundOverlapItem extends StatefulWidget {
  final FundPairOverlap pair;

  const _FundOverlapItem({required this.pair});

  @override
  State<_FundOverlapItem> createState() => _FundOverlapItemState();
}

class _FundOverlapItemState extends State<_FundOverlapItem> {
  bool _expanded = false;

  String _subtitle(RiskLevel risk) => switch (risk) {
        RiskLevel.high => 'Exceeds SEBI 50% limit',
        RiskLevel.moderate => 'Significant overlap',
        RiskLevel.low => 'Distinct portfolios',
      };

  Color _subtitleColor(RiskLevel risk) => switch (risk) {
        RiskLevel.high => context.palette.loss,
        RiskLevel.moderate => AppColors.warning,
        RiskLevel.low => context.palette.gain,
      };

  @override
  Widget build(BuildContext context) {
    final pair = widget.pair;
    final hasCommon = pair.commonHoldings.isNotEmpty;
    final topCommon = pair.commonHoldings.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.palette.bgDivider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Main card (tappable) ──
          InkWell(
            onTap: hasCommon ? () => setState(() => _expanded = !_expanded) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Left: fund names + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pair.fundNameA} ↔ ${pair.fundNameB}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _subtitle(pair.risk),
                              style: TextStyle(
                                fontSize: 11,
                                color: _subtitleColor(pair.risk),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (hasCommon) ...[
                              const SizedBox(width: 6),
                              Text(
                                '· ${pair.commonHoldings.length} common stocks',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.palette.textTertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right: traffic light + expand icon
                  TrafficLight(
                    risk: pair.risk,
                    percentage: pair.overlapPct,
                    compact: true,
                  ),
                  if (hasCommon)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: context.palette.textTertiary,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Expanded: top common holdings ──
          if (_expanded && topCommon.isNotEmpty) ...[
            Divider(height: 1, color: context.palette.bgDivider),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Common Holdings',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      _shortName(pair.fundNameA),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      _shortName(pair.fundNameB),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...topCommon.map((h) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          h.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.palette.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 52,
                        child: Text(
                          '${h.weightA.toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 52,
                        child: Text(
                          '${h.weightB.toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            if (pair.commonHoldings.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 8),
                child: Text(
                  '+${pair.commonHoldings.length - 5} more common holdings',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.palette.textTertiary,
                  ),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  /// Extract a short fund name (first word or AMC abbreviation).
  String _shortName(String fundName) {
    // "ICICI Prudential ..." → "ICICI"
    // "Parag Parikh ..." → "PP"
    // "Franklin India ..." → "Franklin"
    // "UTI Quant ..." → "UTI"
    // "Bandhan Small ..." → "Bandhan"
    final parts = fundName.split(' ');
    if (parts.isEmpty) return '?';
    final first = parts.first;
    // If first word is short enough, use it
    if (first.length <= 8) return first;
    // Otherwise abbreviate
    return '${first.substring(0, 6)}..';
  }
}
