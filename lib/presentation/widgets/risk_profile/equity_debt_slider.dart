import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

class EquityDebtSlider extends StatefulWidget {
  const EquityDebtSlider({
    super.key,
    required this.equityPct,
    required this.onChanged,
  });

  final double equityPct;
  final ValueChanged<double> onChanged;

  @override
  State<EquityDebtSlider> createState() => _EquityDebtSliderState();
}

class _EquityDebtSliderState extends State<EquityDebtSlider> {
  late final TextEditingController _eqCtrl;
  late final TextEditingController _debtCtrl;

  @override
  void initState() {
    super.initState();
    _eqCtrl = TextEditingController(text: widget.equityPct.toStringAsFixed(0));
    _debtCtrl =
        TextEditingController(text: (100 - widget.equityPct).toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant EquityDebtSlider old) {
    super.didUpdateWidget(old);
    if (old.equityPct != widget.equityPct) {
      _eqCtrl.text = widget.equityPct.toStringAsFixed(0);
      _debtCtrl.text = (100 - widget.equityPct).toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _eqCtrl.dispose();
    _debtCtrl.dispose();
    super.dispose();
  }

  void _updateFromSlider(double v) {
    final eq = v.roundToDouble();
    _eqCtrl.text = eq.toStringAsFixed(0);
    _debtCtrl.text = (100 - eq).toStringAsFixed(0);
    widget.onChanged(eq);
  }

  void _updateFromEquityText(String txt) {
    final v = double.tryParse(txt);
    if (v == null || v < 0 || v > 100) return;
    _debtCtrl.text = (100 - v).toStringAsFixed(0);
    widget.onChanged(v);
  }

  void _updateFromDebtText(String txt) {
    final v = double.tryParse(txt);
    if (v == null || v < 0 || v > 100) return;
    final eq = 100 - v;
    _eqCtrl.text = eq.toStringAsFixed(0);
    widget.onChanged(eq);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _pctBox('Equity', _eqCtrl, AppColors.primary, _updateFromEquityText),
            const SizedBox(width: 12),
            const Text(':', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            _pctBox('Debt', _debtCtrl, Colors.blueGrey, _updateFromDebtText),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: widget.equityPct.clamp(0, 100),
          min: 0,
          max: 100,
          divisions: 100,
          label:
              '${widget.equityPct.toStringAsFixed(0)} : ${(100 - widget.equityPct).toStringAsFixed(0)}',
          activeColor: AppColors.primary,
          onChanged: _updateFromSlider,
        ),
      ],
    );
  }

  Widget _pctBox(String label, TextEditingController ctrl, Color color,
      ValueChanged<String> onChanged) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: InputDecoration(
              suffixText: '%',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
