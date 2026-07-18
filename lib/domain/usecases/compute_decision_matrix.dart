import 'dart:math' as math;

import '../../core/constants/app_constants.dart';

import '../models/screener_models.dart';

// ---------------------------------------------------------------------------
// Private types
// ---------------------------------------------------------------------------

enum _TaxType {
  equity,
  debtSlab,
  fdSlab,
  exempt,
  sgb,
  nps,
}

class _InstrumentParams {
  final String instrument;
  final String category;
  final double grossRatePct; // e.g. 12.5 for 12.5%
  final _TaxType taxType;
  final bool isEditable;
  final String? note;

  const _InstrumentParams({
    required this.instrument,
    required this.category,
    required this.grossRatePct,
    required this.taxType,
    this.isEditable = false,
    this.note,
  });
}

// ---------------------------------------------------------------------------
// Calculator
// ---------------------------------------------------------------------------

/// Static calculator that produces a [DecisionMatrixResult] from
/// [DecisionMatrixInput].
///
/// Tax rules applied (post-April 2023 Finance Act):
/// - Equity       : ≤1Y → STCG 20% + 4% cess; >1Y → LTCG 12.5% on gains > ₹1.25L/yr + 4% cess
/// - Debt MFs     : Always taxed at slab rate + 4% cess (indexation removed Apr 2023)
/// - Bank FD      : Slab rate + 4% cess on interest
/// - PPF / EPF    : Fully exempt
/// - SGB          : ≥8Y → exempt; >1Y → LTCG 12.5% + 4% cess; ≤1Y → slab + 4% cess
/// - NPS          : 60% tax-free; 40% → slab rate on gains portion
class DecisionMatrixCalculator {
  DecisionMatrixCalculator._();

  // Single source of truth for rates is AppConstants — do not hardcode here.
  static const double _cessRate = AppConstants.healthEducationCess;
  static const double _ltcgRate = AppConstants.equityLtcgRate;
  static const double _stcgRate = AppConstants.equityStcgRate;
  static const double _ltcgExemptAnnual =
      AppConstants.ltcgExemptionPerPersonPerFy;

  // ---------------------------------------------------------------------------
  // Instrument catalogue
  // ---------------------------------------------------------------------------
  static const List<_InstrumentParams> _instruments = [
    _InstrumentParams(
      instrument: 'Equity Large Cap',
      category: 'Equity',
      grossRatePct: 12.5,
      taxType: _TaxType.equity,
    ),
    _InstrumentParams(
      instrument: 'Equity Flexi Cap',
      category: 'Equity',
      grossRatePct: 13.5,
      taxType: _TaxType.equity,
    ),
    _InstrumentParams(
      instrument: 'Equity Mid Cap',
      category: 'Equity',
      grossRatePct: 15.0,
      taxType: _TaxType.equity,
    ),
    _InstrumentParams(
      instrument: 'ELSS',
      category: 'Equity',
      grossRatePct: 13.0,
      taxType: _TaxType.equity,
      note: '3-year lock-in',
    ),
    _InstrumentParams(
      instrument: 'Arbitrage Fund',
      category: 'Hybrid',
      grossRatePct: 7.2,
      taxType: _TaxType.equity,
    ),
    _InstrumentParams(
      instrument: 'Balanced Advantage',
      category: 'Hybrid',
      grossRatePct: 10.5,
      taxType: _TaxType.equity,
    ),
    _InstrumentParams(
      instrument: 'Short Duration MF',
      category: 'Debt',
      grossRatePct: 7.8,
      taxType: _TaxType.debtSlab,
    ),
    _InstrumentParams(
      instrument: 'Liquid Fund',
      category: 'Debt',
      grossRatePct: 6.5,
      taxType: _TaxType.debtSlab,
    ),
    _InstrumentParams(
      instrument: 'Bank FD',
      category: 'Fixed Income',
      grossRatePct: 7.5,
      taxType: _TaxType.fdSlab,
      isEditable: true,
    ),
    _InstrumentParams(
      instrument: 'PPF',
      category: 'Tax-Free',
      grossRatePct: 7.1,
      taxType: _TaxType.exempt,
      note: '15-year lock-in',
    ),
    _InstrumentParams(
      instrument: 'EPF (8.15%)',
      category: 'Tax-Free',
      grossRatePct: 8.15,
      taxType: _TaxType.exempt,
    ),
    _InstrumentParams(
      instrument: 'NPS (Equity)',
      category: 'Tax-Free',
      grossRatePct: 12.0,
      taxType: _TaxType.nps,
      note: '60% tax-free at 60',
    ),
    _InstrumentParams(
      instrument: 'SGB',
      category: 'Tax-Free',
      grossRatePct: 10.0,
      taxType: _TaxType.sgb,
      note: '8-year maturity',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Compute the decision matrix for the given [input].
  ///
  /// Returns a [DecisionMatrixResult] with rows sorted by [netReturn] descending.
  static DecisionMatrixResult compute(DecisionMatrixInput input) {
    final rows = _instruments
        .map((p) => _computeRow(p, input))
        .toList()
      ..sort((a, b) => b.netReturn.compareTo(a.netReturn));

    return DecisionMatrixResult(input: input, rows: rows);
  }

  // ---------------------------------------------------------------------------
  // Row computation
  // ---------------------------------------------------------------------------

  static DecisionMatrixRow _computeRow(
    _InstrumentParams params,
    DecisionMatrixInput input,
  ) {
    final double grossRate = params.grossRatePct / 100.0;
    final int n = input.horizonYears;
    final double amount = input.amount;
    final double slabRate = input.taxSlabPct / 100.0;

    // Gross compounded maturity
    final double grossMaturity = amount * math.pow(1 + grossRate, n);
    final double totalGain = grossMaturity - amount;

    // Annualised gross return % (already params.grossRatePct, but compute
    // consistently from grossMaturity for symmetry).
    final double grossReturn = params.grossRatePct;

    // Compute tax
    final _TaxResult tax = _computeTax(
      params: params,
      amount: amount,
      grossMaturity: grossMaturity,
      totalGain: totalGain,
      horizonYears: n,
      slabRate: slabRate,
    );

    final double netMaturity = grossMaturity - tax.taxAmount;

    // Annualised net return %
    final double netReturnFrac = math.pow(netMaturity / amount, 1.0 / n) - 1;
    final double netReturn = netReturnFrac * 100.0;

    // Tax impact in return % points (clamped ≥ 0)
    final double taxImpact = (grossReturn - netReturn).clamp(0.0, double.infinity);

    return DecisionMatrixRow(
      instrument: params.instrument,
      category: params.category,
      grossReturn: grossReturn,
      taxImpact: taxImpact,
      netReturn: netReturn,
      maturityValue: netMaturity,
      totalTaxPaid: tax.taxAmount,
      taxTreatment: tax.description,
      isEditable: params.isEditable,
      note: params.note,
    );
  }

  // ---------------------------------------------------------------------------
  // Tax computation
  // ---------------------------------------------------------------------------

  static _TaxResult _computeTax({
    required _InstrumentParams params,
    required double amount,
    required double grossMaturity,
    required double totalGain,
    required int horizonYears,
    required double slabRate,
  }) {
    switch (params.taxType) {
      case _TaxType.exempt:
        return _TaxResult(taxAmount: 0, description: 'Tax-free (exempt)');

      case _TaxType.debtSlab:
        // Always slab rate regardless of holding period (post Apr 2023)
        final effective = slabRate * (1 + _cessRate);
        final tax = totalGain * effective;
        return _TaxResult(
          taxAmount: tax,
          description:
              'slab rate ${(slabRate * 100).toStringAsFixed(0)}% + cess',
        );

      case _TaxType.fdSlab:
        // Interest taxed at slab + cess each year (simple compound model)
        // For modelling simplicity: tax on total interest at slab + cess
        final effective = slabRate * (1 + _cessRate);
        final tax = totalGain * effective;
        return _TaxResult(
          taxAmount: tax,
          description:
              'FD slab rate ${(slabRate * 100).toStringAsFixed(0)}% + cess',
        );

      case _TaxType.equity:
        return _computeEquityTax(
          totalGain: totalGain,
          horizonYears: horizonYears,
          amount: amount,
          grossMaturity: grossMaturity,
          slabRate: slabRate,
        );

      case _TaxType.sgb:
        return _computeSgbTax(
          totalGain: totalGain,
          horizonYears: horizonYears,
          slabRate: slabRate,
        );

      case _TaxType.nps:
        return _computeNpsTax(
          totalGain: totalGain,
          slabRate: slabRate,
        );
    }
  }

  // Equity tax: STCG ≤1Y, LTCG >1Y (with ₹1.25L/year exemption)
  static _TaxResult _computeEquityTax({
    required double totalGain,
    required int horizonYears,
    required double amount,
    required double grossMaturity,
    required double slabRate,
  }) {
    if (horizonYears <= 1) {
      // STCG 20% + 4% cess
      final effective = _stcgRate * (1 + _cessRate);
      final tax = totalGain * effective;
      return _TaxResult(
        taxAmount: tax,
        description: 'STCG 20% + cess',
      );
    } else {
      // LTCG 12.5% on gains exceeding ₹1.25L/year exemption
      final annualExempt = _ltcgExemptAnnual * horizonYears;
      final taxableGain = (totalGain - annualExempt).clamp(0.0, double.infinity);
      final effective = _ltcgRate * (1 + _cessRate);
      final tax = taxableGain * effective;
      return _TaxResult(
        taxAmount: tax,
        description: 'LTCG 12.5% + cess (₹1.25L/yr exempt)',
      );
    }
  }

  // SGB: ≥8Y → exempt; >1Y → LTCG 12.5% + cess; ≤1Y → slab + cess
  static _TaxResult _computeSgbTax({
    required double totalGain,
    required int horizonYears,
    required double slabRate,
  }) {
    if (horizonYears >= 8) {
      return _TaxResult(taxAmount: 0, description: 'SGB exempt (≥8Y maturity)');
    } else if (horizonYears > 1) {
      final effective = _ltcgRate * (1 + _cessRate);
      final tax = totalGain * effective;
      return _TaxResult(
        taxAmount: tax,
        description: 'SGB LTCG 12.5% + cess',
      );
    } else {
      final effective = slabRate * (1 + _cessRate);
      final tax = totalGain * effective;
      return _TaxResult(
        taxAmount: tax,
        description:
            'SGB slab rate ${(slabRate * 100).toStringAsFixed(0)}% + cess (≤1Y)',
      );
    }
  }

  // NPS: 60% tax-free; 40% taxed at slab on gains portion
  static _TaxResult _computeNpsTax({
    required double totalGain,
    required double slabRate,
  }) {
    final taxableGain = totalGain * 0.40;
    final effective = slabRate * (1 + _cessRate);
    final tax = taxableGain * effective;
    return _TaxResult(
      taxAmount: tax,
      description:
          'NPS: 60% tax-free, 40% at slab ${(slabRate * 100).toStringAsFixed(0)}%',
    );
  }
}

// ---------------------------------------------------------------------------
// Private result helper
// ---------------------------------------------------------------------------

class _TaxResult {
  final double taxAmount;
  final String description;
  const _TaxResult({required this.taxAmount, required this.description});
}
