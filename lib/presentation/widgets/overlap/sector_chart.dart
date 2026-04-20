import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/overlap_models.dart';

/// Collapsible horizontal bar chart showing sector allocation with risk-coloured bars.
/// Collapsed by default; shows top 3 sectors as preview.
class SectorChart extends StatefulWidget {
  final List<SectorExposure> sectors;

  const SectorChart({super.key, required this.sectors});

  @override
  State<SectorChart> createState() => _SectorChartState();
}

class _SectorChartState extends State<SectorChart> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.sectors.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'No sector data available.',
          style: TextStyle(color: context.palette.textSecondary, fontSize: 13),
        ),
      );
    }

    final preview = widget.sectors.take(3).toList();
    final all = widget.sectors;

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
            // Header
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sector Allocation (${all.length} sectors)',
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
            // Preview or full list
            ...(_expanded ? all : preview)
                .map((s) => _SectorRow(sector: s)),
            // "Show more" hint when collapsed
            if (!_expanded && all.length > 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '+${all.length - 3} more sectors',
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

class _SectorRow extends StatelessWidget {
  final SectorExposure sector;

  const _SectorRow({required this.sector});

  Color _barColor(RiskLevel risk) => switch (risk) {
        RiskLevel.low => AppColors.gain,
        RiskLevel.moderate => AppColors.warning,
        RiskLevel.high => AppColors.loss,
      };

  @override
  Widget build(BuildContext context) {
    final barFraction = (sector.weightPct / 100.0).clamp(0.0, 1.0);
    final color = _barColor(sector.risk);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          // Sector name
          SizedBox(
            width: 120,
            child: Text(
              sector.sectorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: context.palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bar track
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.palette.bgDivider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: barFraction,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Percentage
          SizedBox(
            width: 55,
            child: Text(
              '${sector.weightPct.toStringAsFixed(1)}%',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
