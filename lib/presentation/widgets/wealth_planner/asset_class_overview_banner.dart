import 'package:flutter/material.dart';

import '../../../core/constants/asset_classes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

/// One entry in the overview banner.
class AssetClassOverview {
  const AssetClassOverview({
    required this.assetClass,
    required this.currentPct,
    required this.targetPct,
  });

  final AssetClass assetClass;
  final double currentPct;
  final double targetPct;

  double get deltaPct => currentPct - targetPct;
}

/// Horizontal "bird's-eye" banner sitting above the asset-class cards in the
/// Fund sub-tab.
///
/// Color semantics (alert coloring — intentionally inverse of card pills):
///   * |Δ| < 0.5pp → muted neutral chip.
///   * current < target (deficit; user needs to BUY) → **RED** chip.
///   * current > target (excess; user needs to SELL) → **AMBER** chip.
///
/// Tapping a chip fires [onTapClass] with the tapped class so the parent can
/// scroll its ListView to the matching card.
class AssetClassOverviewBanner extends StatelessWidget {
  const AssetClassOverviewBanner({
    super.key,
    required this.entries,
    required this.onTapClass,
  });

  final List<AssetClassOverview> entries;
  final void Function(AssetClass cls) onTapClass;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: palette.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.bgDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: Row(
              children: [
                Icon(Icons.radar, size: 13, color: palette.textTertiary),
                const SizedBox(width: 6),
                Text(
                  'Allocation at a glance',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _OverviewChip(
                entry: entries[i],
                onTap: () => onTapClass(entries[i].assetClass),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewChip extends StatelessWidget {
  const _OverviewChip({required this.entry, required this.onTap});

  final AssetClassOverview entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final deltaAbs = entry.deltaPct.abs();
    final (Color border, Color fill, Color text, IconData? icon) = _tone(
      palette: palette,
      delta: entry.deltaPct,
      deltaAbs: deltaAbs,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 128,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: border,
            width: deltaAbs >= 0.5 ? 1.4 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.assetClassColors[
                            entry.assetClass.displayName] ??
                        AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.assetClass.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                if (icon != null) Icon(icon, size: 12, color: text),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${entry.currentPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ ${entry.targetPct.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color, Color, IconData?) _tone({
    required AppPalette palette,
    required double delta,
    required double deltaAbs,
  }) {
    if (deltaAbs < 0.5) {
      return (
        palette.bgDivider,
        palette.bgSurface,
        palette.textSecondary,
        null,
      );
    }
    if (delta < 0) {
      // deficit — need to buy — RED per banner coloring.
      return (
        AppColors.loss,
        AppColors.loss.withValues(alpha: 0.12),
        AppColors.loss,
        Icons.arrow_downward,
      );
    }
    // excess — need to sell — AMBER per banner coloring.
    return (
      AppColors.warning,
      AppColors.warning.withValues(alpha: 0.12),
      AppColors.warning,
      Icons.arrow_upward,
    );
  }
}
