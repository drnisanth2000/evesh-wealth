import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

/// Asset-class-level slider with paired ₹ and % input boxes.
///
/// Visual track semantics:
///   * `0 → min(current, target)` — GREEN baseline (what you already have).
///   * `current → target` (thumb right of current, i.e. deficit to fill)
///       — RED overlay.
///   * `target → current` (thumb left of current, i.e. excess to trim)
///       — AMBER overlay.
///
/// The slider's thumb represents the **target %** (0–100). Values persist
/// immediately via [onChangedPct] so Hive save-on-change semantics hold.
class AssetClassAllocationSlider extends StatefulWidget {
  const AssetClassAllocationSlider({
    super.key,
    required this.currentPct,
    required this.targetPct,
    required this.totalPortfolioValue,
    required this.onChangedPct,
  });

  final double currentPct;
  final double targetPct;
  final double totalPortfolioValue;

  /// Fires every time the user commits a new target %. Parent should call
  /// `simState.setTargetAllocation(classKey, pct)`.
  final ValueChanged<double> onChangedPct;

  @override
  State<AssetClassAllocationSlider> createState() =>
      _AssetClassAllocationSliderState();
}

class _AssetClassAllocationSliderState
    extends State<AssetClassAllocationSlider> {
  late final TextEditingController _rupeesCtrl;
  late final TextEditingController _pctCtrl;
  final FocusNode _rupeesFocus = FocusNode();
  final FocusNode _pctFocus = FocusNode();
  final _rupeesFmt = NumberFormat('#,##,###', 'en_IN');

  late double _pct;

  @override
  void initState() {
    super.initState();
    _pct = widget.targetPct.clamp(0.0, 100.0);
    _rupeesCtrl = TextEditingController(text: _rupeesFmt.format(_rupees.round()));
    _pctCtrl = TextEditingController(text: _pct.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(AssetClassAllocationSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetPct != widget.targetPct && !_pctFocus.hasFocus) {
      _pct = widget.targetPct.clamp(0.0, 100.0);
      _pctCtrl.text = _pct.toStringAsFixed(1);
      if (!_rupeesFocus.hasFocus) {
        _rupeesCtrl.text = _rupeesFmt.format(_rupees.round());
      }
    }
  }

  @override
  void dispose() {
    _rupeesCtrl.dispose();
    _pctCtrl.dispose();
    _rupeesFocus.dispose();
    _pctFocus.dispose();
    super.dispose();
  }

  double get _rupees => widget.totalPortfolioValue * _pct / 100.0;

  void _commit(double pct) {
    setState(() => _pct = pct.clamp(0.0, 100.0));
    if (!_rupeesFocus.hasFocus) {
      _rupeesCtrl.text = _rupeesFmt.format(_rupees.round());
    }
    if (!_pctFocus.hasFocus) {
      _pctCtrl.text = _pct.toStringAsFixed(1);
    }
    widget.onChangedPct(_pct);
  }

  void _onRupeesChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _commit(0);
      return;
    }
    final rupees = double.tryParse(digits) ?? 0;
    if (widget.totalPortfolioValue > 0) {
      _commit((rupees / widget.totalPortfolioValue) * 100.0);
    }
  }

  void _onPctChanged(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (clean.isEmpty) {
      _commit(0);
      return;
    }
    final pct = double.tryParse(clean) ?? 0;
    _commit(pct);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SegmentedTrack(
            currentPct: widget.currentPct,
            targetPct: _pct,
            onChanged: _commit,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _rupeesCtrl,
                  focusNode: _rupeesFocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                      fontSize: 12, color: palette.textPrimary),
                  decoration: InputDecoration(
                    prefixText: '₹',
                    prefixStyle: TextStyle(
                        fontSize: 12, color: palette.textSecondary),
                    labelText: 'Target value',
                    labelStyle: TextStyle(
                        fontSize: 10, color: palette.textSecondary),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    filled: true,
                    fillColor: palette.bgSurface,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onRupeesChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _pctCtrl,
                  focusNode: _pctFocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: TextStyle(
                      fontSize: 12, color: palette.textPrimary),
                  decoration: InputDecoration(
                    suffixText: '%',
                    suffixStyle: TextStyle(
                        fontSize: 11, color: palette.textSecondary),
                    labelText: 'Target %',
                    labelStyle: TextStyle(
                        fontSize: 10, color: palette.textSecondary),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    filled: true,
                    fillColor: palette.bgSurface,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onPctChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Multi-segment slider track — green baseline with RED deficit overlay or
/// AMBER excess overlay depending on the relationship between current and
/// target.
class _SegmentedTrack extends StatelessWidget {
  const _SegmentedTrack({
    required this.currentPct,
    required this.targetPct,
    required this.onChanged,
  });

  final double currentPct;
  final double targetPct;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final deficit = targetPct > currentPct + 0.1;
    final excess = targetPct < currentPct - 0.1;

    final overlayColor = deficit
        ? context.palette.loss
        : excess
            ? AppColors.warning
            : context.palette.gain;

    final cur = currentPct.clamp(0.0, 100.0);
    final tgt = targetPct.clamp(0.0, 100.0);
    final lo = cur < tgt ? cur : tgt;
    final hi = cur > tgt ? cur : tgt;

    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return Stack(
                  children: [
                    // Inactive track.
                    Positioned.fill(
                      top: 19,
                      bottom: 19,
                      child: Container(
                        decoration: BoxDecoration(
                          color: palette.bgSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Green baseline — 0 → min(current, target).
                    Positioned(
                      top: 19,
                      left: 0,
                      height: 6,
                      width: w * (lo / 100),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.palette.gain,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Overlay segment — min(cur,tgt) → max(cur,tgt).
                    if (deficit || excess)
                      Positioned(
                        top: 19,
                        left: w * (lo / 100),
                        height: 6,
                        width: w * ((hi - lo) / 100),
                        child: Container(
                          decoration: BoxDecoration(
                            color: overlayColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbColor: overlayColor,
              overlayColor: overlayColor.withValues(alpha: 0.18),
              trackHeight: 6,
            ),
            child: Slider(
              value: tgt,
              min: 0,
              max: 100,
              divisions: 200,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
