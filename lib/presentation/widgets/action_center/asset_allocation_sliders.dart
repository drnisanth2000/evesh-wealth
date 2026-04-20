import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/asset_classes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

/// Interactive asset class target allocation sliders.
///
/// Shows 7 sliders (one per asset class) with current vs ideal % and a
/// running total bar. Users adjust their desired allocation mix; the total
/// must sum to 100%.
class AssetAllocationSliders extends StatelessWidget {
  const AssetAllocationSliders({
    super.key,
    required this.targets,
    required this.currentAllocation,
    required this.onChanged,
    required this.onReset,
  });

  /// Current target allocation % per asset class key.
  final Map<String, double> targets;

  /// Current actual allocation % per asset class display name.
  final Map<String, double> currentAllocation;

  /// Called when a single asset class target changes.
  final void Function(String assetClassKey, double pct) onChanged;

  /// Resets targets to computed ideal.
  final VoidCallback onReset;

  static const _assetClasses = [
    ('coreEquity', 'Core Equity'),
    ('satelliteEquity', 'Satellite Equity'),
    ('hybrid', 'Hybrid'),
    ('debt', 'Debt'),
    ('liquid', 'Liquid'),
    ('gold', 'Gold'),
    ('alternate', 'Alternate'),
  ];

  double get _total =>
      targets.values.fold(0.0, (sum, v) => sum + v);

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final isBalanced = (total - 100).abs() < 0.5;

    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.tune, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Target Allocation',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.palette.textPrimary,
                    ),
                  ),
                ),
                // Reset button
                GestureDetector(
                  onTap: onReset,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restart_alt, size: 14, color: AppColors.info),
                      SizedBox(width: 3),
                      Text(
                        'Reset to Ideal',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Total bar
            _TotalBar(total: total, isBalanced: isBalanced),
            const SizedBox(height: 12),

            // Asset class sliders
            ..._assetClasses.map((entry) {
              final key = entry.$1;
              final label = entry.$2;
              final targetPct = targets[key] ?? 0.0;
              final currentPct = currentAllocation[label] ?? 0.0;
              final color =
                  AppColors.assetClassColors[label] ?? AppColors.primary;

              return _AssetClassSliderRow(
                assetClassKey: key,
                label: label,
                targetPct: targetPct,
                currentPct: currentPct,
                color: color,
                onChanged: (v) => onChanged(key, v),
              );
            }),

            if (!isBalanced)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Total is ${total.toStringAsFixed(1)}% — adjust to reach 100%',
                  style: TextStyle(
                    fontSize: 10,
                    color: total > 100 ? AppColors.loss : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Total Progress Bar ──────────────────────────────────────────────────────

class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.total, required this.isBalanced});

  final double total;
  final bool isBalanced;

  @override
  Widget build(BuildContext context) {
    final barColor = isBalanced
        ? AppColors.gain
        : total > 100
            ? AppColors.loss
            : AppColors.warning;
    final fillFraction = (total / 100).clamp(0.0, 1.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total: ${total.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: barColor,
              ),
            ),
            if (isBalanced)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 12, color: AppColors.gain),
                  SizedBox(width: 3),
                  Text('Balanced',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.gain,
                          fontWeight: FontWeight.w500)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                // Background
                Container(color: context.palette.bgSurface),
                // Fill
                FractionallySizedBox(
                  widthFactor: fillFraction.clamp(0.0, 1.0),
                  child: Container(color: barColor),
                ),
                // 100% marker
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.83 *
                      (100 / (total > 100 ? total : 100)) *
                      0.01 *
                      100,
                  child: Container(
                    width: 1,
                    height: 6,
                    color: context.palette.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Per-Asset-Class Slider Row ──────────────────────────────────────────────

class _AssetClassSliderRow extends StatefulWidget {
  const _AssetClassSliderRow({
    required this.assetClassKey,
    required this.label,
    required this.targetPct,
    required this.currentPct,
    required this.color,
    required this.onChanged,
  });

  final String assetClassKey;
  final String label;
  final double targetPct;
  final double currentPct;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  State<_AssetClassSliderRow> createState() => _AssetClassSliderRowState();
}

class _AssetClassSliderRowState extends State<_AssetClassSliderRow> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.targetPct.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(_AssetClassSliderRow old) {
    super.didUpdateWidget(old);
    if (old.targetPct != widget.targetPct) {
      final newText = widget.targetPct.toStringAsFixed(0);
      if (_ctrl.text != newText) {
        _ctrl.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onSliderChanged(double v) {
    _ctrl.text = v.round().toStringAsFixed(0);
    widget.onChanged(v.roundToDouble());
  }

  void _onTextChanged(String raw) {
    final val = double.tryParse(raw);
    if (val != null) {
      widget.onChanged(val.clamp(0, 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.targetPct - widget.currentPct;
    final diffStr = diff.abs() < 0.5
        ? ''
        : '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
              // Current %
              Text(
                'Now ${widget.currentPct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 9,
                  color: context.palette.textTertiary,
                ),
              ),
              if (diffStr.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  diffStr,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: diff.abs() > 5
                        ? (diff > 0 ? AppColors.gain : AppColors.loss)
                        : context.palette.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          // Slider + text field
          Row(
            children: [
              Expanded(
                flex: 4,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: widget.color,
                    thumbColor: widget.color,
                    overlayColor: widget.color.withValues(alpha: 0.15),
                    inactiveTrackColor: context.palette.bgSurface,
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: widget.targetPct.clamp(0, 100),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: _onSliderChanged,
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                child: TextFormField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textPrimary,
                  ),
                  decoration: InputDecoration(
                    suffixText: '%',
                    suffixStyle: TextStyle(
                      fontSize: 10,
                      color: context.palette.textTertiary,
                    ),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    filled: true,
                    fillColor: context.palette.bgSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onTextChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
