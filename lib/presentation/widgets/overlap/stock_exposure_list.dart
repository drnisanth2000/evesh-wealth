import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/overlap_models.dart';
import 'traffic_light.dart';

/// Collapsible list of top stock exposures, sorted by effective weight descending.
/// Collapsed by default to save screen space.
class StockExposureList extends StatefulWidget {
  final List<StockExposure> stocks;

  const StockExposureList({super.key, required this.stocks});

  @override
  State<StockExposureList> createState() => _StockExposureListState();
}

class _StockExposureListState extends State<StockExposureList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.stocks.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'No stock exposure data available.',
          style: TextStyle(color: context.palette.textSecondary, fontSize: 13),
        ),
      );
    }

    final display = widget.stocks.take(20).toList();
    // Show top 3 as preview when collapsed
    final preview = display.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: context.palette.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.palette.bgDivider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header — always visible, tappable
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Top ${display.length} Stock Exposures',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.palette.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: context.palette.textSecondary,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            // Preview (always shown) — top 3 stocks
            if (!_expanded)
              ...preview.map((stock) => _StockExposureItem(stock: stock)),
            // Full list (shown when expanded)
            if (_expanded)
              ...display.map((stock) => Column(
                    children: [
                      Divider(
                        height: 1,
                        color: context.palette.bgDivider,
                      ),
                      _StockExposureItem(stock: stock),
                    ],
                  )),
            // "Show more" hint when collapsed
            if (!_expanded && display.length > 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '+${display.length - 3} more',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.palette.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StockExposureItem extends StatelessWidget {
  final StockExposure stock;

  const _StockExposureItem({required this.stock});

  @override
  Widget build(BuildContext context) {
    final isHighRisk = stock.risk == RiskLevel.high;

    return Container(
      color: isHighRisk
          ? context.palette.loss.withValues(alpha: 0.06)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: company name + sector + held-in
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.companyName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textPrimary,
                  ),
                ),
                if (stock.sectorName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    stock.sectorName!,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.palette.textSecondary,
                    ),
                  ),
                ],
                if (stock.heldInFunds.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Held in: ${stock.heldInFunds.join(', ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.palette.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: compact traffic light
          TrafficLight(
            risk: stock.risk,
            percentage: stock.effectiveWeightPct,
            compact: true,
          ),
        ],
      ),
    );
  }
}
