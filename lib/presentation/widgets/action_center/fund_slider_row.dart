import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/simulation_models.dart';

// ─── FundSliderRow ────────────────────────────────────────────────────────────

class FundSliderRow extends StatefulWidget {
  const FundSliderRow({
    super.key,
    required this.amfiCode,
    required this.fundName,
    required this.assetClassLabel,
    required this.currentValue,
    required this.adjustedValue,
    required this.totalPortfolioValue,
    required this.onChanged,
    this.taxImpact,
  });

  final int amfiCode;
  final String fundName;
  final String assetClassLabel;
  final double currentValue;
  final double adjustedValue;
  final double totalPortfolioValue;
  final Function(double) onChanged;
  final FundTaxImpact? taxImpact;

  @override
  State<FundSliderRow> createState() => _FundSliderRowState();
}

class _FundSliderRowState extends State<FundSliderRow> {
  late final TextEditingController _amountController;
  late final TextEditingController _pctController;
  // Track which field has focus so we don't reformat while the user is
  // mid-typing (otherwise typing "3" then "0" becomes "3.00" — 3% not 30%).
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _pctFocus = FocusNode();
  final _fmt = NumberFormat('#,##,###', 'en_IN');

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _fmt.format(widget.adjustedValue.round()),
    );
    _pctController = TextEditingController(
      text: _targetPct.toStringAsFixed(1),
    );
  }

  @override
  void didUpdateWidget(FundSliderRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adjustedValue != widget.adjustedValue) {
      final formatted = _fmt.format(widget.adjustedValue.round());
      if (!_amountFocus.hasFocus && _amountController.text != formatted) {
        _amountController.text = formatted;
      }
      final pctFormatted = _targetPct.toStringAsFixed(1);
      if (!_pctFocus.hasFocus && _pctController.text != pctFormatted) {
        _pctController.text = pctFormatted;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _pctController.dispose();
    _amountFocus.dispose();
    _pctFocus.dispose();
    super.dispose();
  }

  /// Slider upper bound = total portfolio value (i.e. user can dial any
  /// single fund up to 100% of the portfolio). The concentration warning on
  /// the Rebalance Actions card flags over-exposure; the slider itself
  /// shouldn't impose an arbitrary ceiling. Falls back to ₹1L for the
  /// degenerate `totalPortfolioValue == 0` case.
  double get _sliderMax {
    final cap = widget.totalPortfolioValue;
    return cap > 0 ? cap : 100000;
  }

  bool get _isSelling => widget.adjustedValue < widget.currentValue;

  double get _currentPct => widget.totalPortfolioValue > 0
      ? (widget.currentValue / widget.totalPortfolioValue) * 100
      : 0;

  double get _targetPct => widget.totalPortfolioValue > 0
      ? (widget.adjustedValue / widget.totalPortfolioValue) * 100
      : 0;

  double get _driftPp => _targetPct - _currentPct;

  bool get _isModified =>
      (widget.adjustedValue - widget.currentValue).abs() > 1.0;

  void _onSliderChanged(double value) {
    _amountController.text = _fmt.format(value.round());
    if (widget.totalPortfolioValue > 0) {
      final pct = (value / widget.totalPortfolioValue) * 100;
      _pctController.text = pct.toStringAsFixed(1);
    }
    widget.onChanged(value);
  }

  void _onTextChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      widget.onChanged(0);
      return;
    }
    final value = double.tryParse(digits);
    if (value != null) {
      final clamped = value.clamp(0.0, _sliderMax);
      if (widget.totalPortfolioValue > 0) {
        final pct = (clamped / widget.totalPortfolioValue) * 100;
        _pctController.text = pct.toStringAsFixed(1);
      }
      widget.onChanged(clamped);
    }
  }

  void _onPctChanged(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (clean.isEmpty) {
      widget.onChanged(0);
      return;
    }
    final pct = double.tryParse(clean);
    if (pct == null) return;
    final value = widget.totalPortfolioValue > 0
        ? (pct / 100) * widget.totalPortfolioValue
        : 0;
    final clamped = value.clamp(0.0, _sliderMax);
    _amountController.text = _fmt.format(clamped.round());
    widget.onChanged(clamped.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final sliderColor = _isSelling ? context.palette.loss : context.palette.gain;
    final taxImpact = widget.taxImpact;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fund name + Modified tag
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.fundName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
              if (_isModified)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 10, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Modified',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          // Asset class + current value
          Text(
            '${widget.assetClassLabel} · Current ₹${_fmt.format(widget.currentValue.round())}',
            style: TextStyle(
              fontSize: 10,
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          // Slider + ₹ field + % field row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: sliderColor,
                    thumbColor: sliderColor,
                    overlayColor: sliderColor.withValues(alpha: 0.2),
                    inactiveTrackColor: context.palette.bgSurface,
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: widget.adjustedValue.clamp(0, _sliderMax),
                    min: 0,
                    max: _sliderMax > 0 ? _sliderMax : 1,
                    onChanged: _onSliderChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextFormField(
                  controller: _amountController,
                  focusNode: _amountFocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textPrimary,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹',
                    prefixStyle: TextStyle(
                      fontSize: 12,
                      color: context.palette.textSecondary,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: context.palette.bgSurface,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onTextChanged,
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 62,
                child: TextFormField(
                  controller: _pctController,
                  focusNode: _pctFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textPrimary,
                  ),
                  decoration: InputDecoration(
                    suffixText: '%',
                    suffixStyle: TextStyle(
                      fontSize: 11,
                      color: context.palette.textSecondary,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: context.palette.bgSurface,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onPctChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _PillsRow(
            currentPct: _currentPct,
            targetPct: _targetPct,
            driftPp: _driftPp,
          ),
          // Tax impact row (conditional)
          if (taxImpact != null) ...[
            const SizedBox(height: 3),
            Text(
              'Tax if sold: ₹${_fmt.format(taxImpact.ltcgTax.round())} LTCG'
              ' · ₹${_fmt.format(taxImpact.stcgTax.round())} STCG'
              ' · ₹${_fmt.format(taxImpact.exitLoadAmount.round())} exit load',
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PillsRow extends StatelessWidget {
  const _PillsRow({
    required this.currentPct,
    required this.targetPct,
    required this.driftPp,
  });

  final double currentPct;
  final double targetPct;
  final double driftPp;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final driftColor = driftPp.abs() < 0.1
        ? palette.textTertiary
        : (driftPp > 0 ? context.palette.gain : context.palette.loss);
    final sign = driftPp > 0 ? '+' : '';
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _Pill(
          label: 'Cur ${currentPct.toStringAsFixed(1)}%',
          color: palette.textSecondary,
          bg: palette.bgSurface,
        ),
        _Pill(
          label: 'Tgt ${targetPct.toStringAsFixed(1)}%',
          color: palette.textPrimary,
          bg: palette.bgSurface,
          bold: true,
        ),
        _Pill(
          label:
              'Δ $sign${driftPp.toStringAsFixed(1)}pp',
          color: driftColor,
          bg: driftColor.withValues(alpha: 0.10),
          bold: true,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
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

// ─── NewMoneyInput ────────────────────────────────────────────────────────────

class NewMoneyInput extends StatefulWidget {
  const NewMoneyInput({
    super.key,
    required this.lumpsum,
    required this.sip,
    required this.onLumpsumChanged,
    required this.onSipChanged,
  });

  final double lumpsum;
  final double sip;
  final Function(double) onLumpsumChanged;
  final Function(double) onSipChanged;

  @override
  State<NewMoneyInput> createState() => _NewMoneyInputState();
}

class _NewMoneyInputState extends State<NewMoneyInput> {
  late final TextEditingController _lumpsumController;
  late final TextEditingController _sipController;
  final _fmt = NumberFormat('#,##,###', 'en_IN');

  @override
  void initState() {
    super.initState();
    _lumpsumController = TextEditingController(
      text: widget.lumpsum > 0 ? _fmt.format(widget.lumpsum.round()) : '',
    );
    _sipController = TextEditingController(
      text: widget.sip > 0 ? _fmt.format(widget.sip.round()) : '',
    );
  }

  @override
  void dispose() {
    _lumpsumController.dispose();
    _sipController.dispose();
    super.dispose();
  }

  void _onLumpsumChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    widget.onLumpsumChanged(digits.isEmpty ? 0 : double.tryParse(digits) ?? 0);
  }

  void _onSipChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    widget.onSipChanged(digits.isEmpty ? 0 : double.tryParse(digits) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Money',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MoneyField(
                    controller: _lumpsumController,
                    label: 'Lumpsum',
                    onChanged: _onLumpsumChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MoneyField(
                    controller: _sipController,
                    label: 'Monthly SIP',
                    onChanged: _onSipChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(fontSize: 13, color: context.palette.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 11,
          color: context.palette.textSecondary,
        ),
        prefixText: '₹',
        prefixStyle: TextStyle(
          fontSize: 13,
          color: context.palette.textSecondary,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        filled: true,
        fillColor: context.palette.bgSurface,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
    );
  }
}
