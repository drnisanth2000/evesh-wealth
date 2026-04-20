import 'package:flutter/material.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

/// Collapsible asset-class card with a banner (ideal %, current %, gap % + Rs)
/// and a body of fund rows. Collapses by default when [currentValue] is 0.
class AssetClassCard extends StatefulWidget {
  const AssetClassCard({
    super.key,
    required this.displayName,
    required this.currentPct,
    required this.idealPct,
    required this.currentValue,
    required this.totalPortfolioValue,
    required this.children,
    this.showHeaderPills = true,
    this.headerSlot,
    this.fundCount,
  });

  final String displayName;
  final double currentPct;
  final double idealPct;
  final double currentValue;
  final double totalPortfolioValue;
  final List<Widget> children;

  /// When false, suppress the default Current/Ideal/Gap pill row and let the
  /// caller render its own header UI (e.g. the Fund tab's pill banner).
  final bool showHeaderPills;

  /// Optional widget the caller can inject below the title row and above
  /// (or in place of) the default pill row. Use for the Fund tab's
  /// allocator controls.
  final Widget? headerSlot;

  /// Actual number of fund rows the caller is rendering. Preferred over
  /// `children.length` because callers (e.g. the Fund allocator tab) mix
  /// fund sub-cards with ambient widgets like a class-level slider + status
  /// bar in the same children list.
  final int? fundCount;

  double get gapPct => currentPct - idealPct;
  double get gapRupees => currentValue - (totalPortfolioValue * idealPct / 100);

  bool get startCollapsed => currentValue < 1.0;

  int get _effectiveFundCount => fundCount ?? children.length;

  @override
  State<AssetClassCard> createState() => _AssetClassCardState();
}

class _AssetClassCardState extends State<AssetClassCard> {
  late bool _expanded = !widget.startCollapsed;

  @override
  Widget build(BuildContext context) {
    final gapColor = widget.gapPct.abs() < 2
        ? context.palette.textSecondary
        : (widget.gapPct > 0 ? AppColors.gain : AppColors.loss);

    // Asset-class colour anchor (left bar + count badge background).
    final accent =
        AppColors.assetClassColors[widget.displayName] ?? AppColors.primary;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Left color bar keyed to the asset class.
                      Container(
                        width: 8,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.displayName,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            if (widget._effectiveFundCount > 0)
                              Text(
                                '${widget._effectiveFundCount} fund${widget._effectiveFundCount == 1 ? '' : 's'}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: context.palette.textTertiary),
                              ),
                          ],
                        ),
                      ),
                      Text(widget.currentValue.toINRCompact(),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  if (widget.headerSlot != null) ...[
                    const SizedBox(height: 8),
                    widget.headerSlot!,
                  ],
                  if (widget.showHeaderPills) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _pill(
                            'Current ${widget.currentPct.toStringAsFixed(1)}%',
                            context.palette.bgSurface),
                        _pill('Ideal ${widget.idealPct.toStringAsFixed(1)}%',
                            context.palette.bgSurface),
                        _pill(
                          widget.gapRupees.abs() < 100
                              ? 'On target'
                              : (widget.gapRupees > 0
                                  ? 'Over ${widget.gapRupees.abs().toINRCompact()}'
                                  : 'Under ${widget.gapRupees.abs().toINRCompact()}'),
                          gapColor.withValues(alpha: 0.12),
                          textColor: gapColor,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_expanded && widget.children.isNotEmpty) ...[
            Divider(height: 1, color: context.palette.bgDivider),
            ...widget.children,
          ],
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg, {Color? textColor}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textColor ?? context.palette.textSecondary)),
      );
}
