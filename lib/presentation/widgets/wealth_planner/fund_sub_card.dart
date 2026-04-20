import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/asset_classes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import 'move_to_asset_class_sheet.dart';

/// Collapsible fund sub-card rendered inside the Fund tab's asset-class
/// allocator. Collapsed header surfaces fund name, current ₹, current %,
/// target % and a 3-dot menu (Move to another asset class, Rebalance).
///
/// Expanded body adds a per-fund slider + paired ₹ / % inputs so the user
/// can dial in per-fund targets — same UX vocabulary as the class-level
/// slider one level up. No Δpp pill anywhere (class-level pill banner owns
/// the gap communication in ₹).
///
/// When [pendingDeployment] is true the card wears a "Pending deployment"
/// badge and an "Execute deployment" CTA that calls [onExecuteDeployment].
class FundSubCard extends ConsumerStatefulWidget {
  const FundSubCard({
    super.key,
    required this.amfiCode,
    required this.fundName,
    required this.currentAssetClass,
    required this.currentValue,
    required this.targetValue,
    required this.classCurrentRupees,
    required this.classTargetRupees,
    required this.onTargetChanged,
    this.pendingDeployment = false,
    this.onExecuteDeployment,
    this.initiallyExpanded = false,
  });

  final int amfiCode;
  final String fundName;
  final AssetClass currentAssetClass;
  final double currentValue;

  /// User's committed target ₹ for this fund (from simState.fundAmounts).
  final double targetValue;

  /// Sum of every fund's `currentValue` inside this asset class — used so
  /// the "Current %" pill shows how much of the class pie this fund holds.
  final double classCurrentRupees;

  /// Class target ₹ = classTargetPct × portfolioTotal / 100 — the cap for
  /// per-fund editing when the user expands the slider.
  final double classTargetRupees;

  /// Fires every time the user commits a new target ₹ via slider or inputs.
  final ValueChanged<double> onTargetChanged;

  final bool pendingDeployment;
  final VoidCallback? onExecuteDeployment;

  final bool initiallyExpanded;

  @override
  ConsumerState<FundSubCard> createState() => _FundSubCardState();
}

class _FundSubCardState extends ConsumerState<FundSubCard> {
  late bool _expanded = widget.initiallyExpanded;
  late final TextEditingController _rupeesCtrl;
  late final TextEditingController _pctCtrl;
  final FocusNode _rupeesFocus = FocusNode();
  final FocusNode _pctFocus = FocusNode();
  final _fmt = NumberFormat('#,##,###', 'en_IN');

  @override
  void initState() {
    super.initState();
    _rupeesCtrl =
        TextEditingController(text: _fmt.format(widget.targetValue.round()));
    _pctCtrl = TextEditingController(text: _pctWithinClass.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(FundSubCard old) {
    super.didUpdateWidget(old);
    if (old.targetValue != widget.targetValue && !_rupeesFocus.hasFocus) {
      _rupeesCtrl.text = _fmt.format(widget.targetValue.round());
    }
    if (old.targetValue != widget.targetValue && !_pctFocus.hasFocus) {
      _pctCtrl.text = _pctWithinClass.toStringAsFixed(1);
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

  /// Shared denominator for both the Cur% and Tgt% pills: the class TARGET
  /// rupees (falls back to class current when no class target is set). Using
  /// the same denominator makes `Cur 29% / Tgt 29%` read as "balanced" and
  /// `Cur 29% / Tgt 50%` read as "deficit — buy more", matching the slider
  /// grammar one level up.
  double get _sharedDenom {
    if (widget.classTargetRupees > 0) return widget.classTargetRupees;
    if (widget.classCurrentRupees > 0) return widget.classCurrentRupees;
    return 0;
  }

  double get _currentPctWithinClass => _sharedDenom <= 0
      ? 0
      : (widget.currentValue / _sharedDenom) * 100.0;

  double get _pctWithinClass => _sharedDenom <= 0
      ? 0
      : (widget.targetValue / _sharedDenom) * 100.0;

  double get _sliderMax {
    final cap = widget.classTargetRupees > 0
        ? widget.classTargetRupees
        : widget.classCurrentRupees;
    return cap > 0 ? cap : 100000;
  }

  void _commitRupees(double v) {
    final clamped = v.clamp(0.0, _sliderMax);
    // Only rewrite a field when it does NOT currently have focus —
    // otherwise the TextField's own onChanged would reset the controller
    // text mid-keystroke and eat digits (the "type 1, then 0, gets 1" bug).
    if (!_rupeesFocus.hasFocus) {
      _rupeesCtrl.text = _fmt.format(clamped.round());
    }
    if (_sharedDenom > 0 && !_pctFocus.hasFocus) {
      _pctCtrl.text = ((clamped / _sharedDenom) * 100).toStringAsFixed(1);
    }
    widget.onTargetChanged(clamped.toDouble());
  }

  void _onRupeesText(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      widget.onTargetChanged(0);
      return;
    }
    final v = double.tryParse(digits);
    if (v != null) _commitRupees(v);
  }

  void _onPctText(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (clean.isEmpty) {
      widget.onTargetChanged(0);
      return;
    }
    final pct = double.tryParse(clean);
    if (pct == null) return;
    if (_sharedDenom <= 0) return;
    _commitRupees((pct / 100.0) * _sharedDenom);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final pending = widget.pendingDeployment;
    final isSelling = widget.targetValue < widget.currentValue - 1.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      decoration: BoxDecoration(
        color: palette.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: pending
              ? AppColors.info.withValues(alpha: 0.5)
              : palette.bgDivider,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.fundName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            if (pending) ...[
                              const SizedBox(width: 6),
                              const _Badge(
                                text: 'Pending',
                                color: AppColors.info,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '₹${_fmt.format(widget.currentValue.round())}',
                              style: TextStyle(
                                fontSize: 11,
                                color: palette.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _MiniPill(
                              label:
                                  'Cur ${_currentPctWithinClass.toStringAsFixed(0)}%',
                              color: palette.textSecondary,
                              bg: palette.bgCard,
                            ),
                            const SizedBox(width: 4),
                            _MiniPill(
                              label: 'Tgt ${_pctWithinClass.toStringAsFixed(0)}%',
                              color: isSelling
                                  ? AppColors.loss
                                  : AppColors.primary,
                              bg: (isSelling
                                      ? AppColors.loss
                                      : AppColors.primary)
                                  .withValues(alpha: 0.12),
                              bold: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // At-a-glance mini bar: green baseline for current,
                        // red overlay for deficit (tgt > cur), amber
                        // overlay for excess (tgt < cur). Both quantities
                        // scale against the class target so this grammar
                        // matches the class-level slider.
                        _FundMiniBar(
                          currentPct: _currentPctWithinClass,
                          targetPct: _pctWithinClass,
                        ),
                      ],
                    ),
                  ),
                  _ThreeDotMenu(
                    amfiCode: widget.amfiCode,
                    fundName: widget.fundName,
                    currentAssetClass: widget.currentAssetClass,
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: palette.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: palette.bgDivider),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor:
                          isSelling ? AppColors.loss : AppColors.gain,
                      thumbColor:
                          isSelling ? AppColors.loss : AppColors.gain,
                      overlayColor:
                          (isSelling ? AppColors.loss : AppColors.gain)
                              .withValues(alpha: 0.18),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: widget.targetValue.clamp(0, _sliderMax),
                      min: 0,
                      max: _sliderMax,
                      onChanged: _commitRupees,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _rupeesCtrl,
                          focusNode: _rupeesFocus,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(
                              fontSize: 12, color: palette.textPrimary),
                          decoration: InputDecoration(
                            prefixText: '₹',
                            labelText: 'Target',
                            labelStyle: TextStyle(
                                fontSize: 10, color: palette.textSecondary),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            filled: true,
                            fillColor: palette.bgCard,
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6)),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: _onRupeesText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _pctCtrl,
                          focusNode: _pctFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          style: TextStyle(
                              fontSize: 12, color: palette.textPrimary),
                          decoration: InputDecoration(
                            suffixText: '%',
                            labelText: 'Of class',
                            labelStyle: TextStyle(
                                fontSize: 10, color: palette.textSecondary),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            filled: true,
                            fillColor: palette.bgCard,
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6)),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: _onPctText,
                        ),
                      ),
                    ],
                  ),
                  if (pending && widget.onExecuteDeployment != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.info,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: widget.onExecuteDeployment,
                        icon: const Icon(Icons.rocket_launch, size: 14),
                        label: const Text(
                          'Execute deployment',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThreeDotMenu extends StatelessWidget {
  const _ThreeDotMenu({
    required this.amfiCode,
    required this.fundName,
    required this.currentAssetClass,
  });

  final int amfiCode;
  final String fundName;
  final AssetClass currentAssetClass;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_FundAction>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_vert, size: 16),
      padding: EdgeInsets.zero,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _FundAction.move,
          child: Text('Move to another asset class'),
        ),
        PopupMenuItem(
          value: _FundAction.rebalance,
          child: Text('Rebalance'),
        ),
      ],
      onSelected: (action) {
        switch (action) {
          case _FundAction.move:
            MoveToAssetClassSheet.show(
              context: context,
              amfiCode: amfiCode,
              title: fundName,
              currentAssetClass: currentAssetClass,
            );
          case _FundAction.rebalance:
            context.go('/wealth-planner/rebalance?focus=$amfiCode');
        }
      },
    );
  }
}

enum _FundAction { move, rebalance }

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.label,
    required this.color,
    required this.bg,
    this.bold = false,
  });

  final String label;
  final Color color;
  final Color bg;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Compact two-segment bar for the collapsed fund header. Mirrors the
/// class-level slider grammar (green → red/amber overlay) without a thumb
/// or percentage scale labels.
///
/// Both percentages come from the same denominator (class target) so the
/// bar width maps 1:1 to ₹ share of the class target up to 100%; values
/// past 100% are clipped visually but the pill numbers still tell the
/// full story.
class _FundMiniBar extends StatelessWidget {
  const _FundMiniBar({
    required this.currentPct,
    required this.targetPct,
  });

  final double currentPct;
  final double targetPct;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cur = currentPct.clamp(0.0, 100.0);
    final tgt = targetPct.clamp(0.0, 100.0);
    final deficit = tgt > cur + 0.5;
    final excess = tgt < cur - 0.5;
    final overlayColor = deficit
        ? AppColors.loss
        : excess
            ? AppColors.warning
            : AppColors.gain;
    final lo = cur < tgt ? cur : tgt;
    final hi = cur > tgt ? cur : tgt;

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Stack(
        children: [
          // Inactive rail.
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: palette.bgCard,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Green baseline: 0 → min(cur, tgt).
          Container(
            height: 5,
            width: w * (lo / 100),
            decoration: BoxDecoration(
              color: AppColors.gain,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Delta overlay: min(cur, tgt) → max(cur, tgt).
          if (deficit || excess)
            Positioned(
              left: w * (lo / 100),
              top: 0,
              height: 5,
              width: w * ((hi - lo) / 100),
              child: Container(
                decoration: BoxDecoration(
                  color: overlayColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          // Target tick — thin vertical line so the planned position is
          // legible even when the fund is well under target.
          Positioned(
            left: (w * (tgt / 100)).clamp(0.0, w - 1),
            top: -1,
            height: 7,
            width: 1.5,
            child: Container(color: palette.textSecondary),
          ),
        ],
      );
    });
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}
