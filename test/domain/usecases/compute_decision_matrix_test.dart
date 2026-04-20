import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/domain/models/screener_models.dart';
import 'package:evesh_wealth/domain/usecases/compute_decision_matrix.dart';

void main() {
  group('DecisionMatrixCalculator', () {
    // Shared baseline input: ₹1,00,000 — 5-year horizon — 30% slab
    const baseInput = DecisionMatrixInput(
      amount: 100000,
      horizonYears: 5,
      taxSlabPct: 30,
      isNewRegime: false,
    );

    DecisionMatrixResult compute(DecisionMatrixInput input) =>
        DecisionMatrixCalculator.compute(input);

    // ------------------------------------------------------------------
    // 1. At least 8 instrument types, all with positive gross return
    // ------------------------------------------------------------------
    test('produces at least 8 rows, all with positive gross return', () {
      final result = compute(baseInput);
      expect(result.rows.length, greaterThanOrEqualTo(8));
      for (final row in result.rows) {
        expect(row.grossReturn, greaterThan(0),
            reason: '${row.instrument} should have positive gross return');
      }
    });

    // ------------------------------------------------------------------
    // 2. Net return <= gross return for all rows
    // ------------------------------------------------------------------
    test('net return is always <= gross return', () {
      final result = compute(baseInput);
      for (final row in result.rows) {
        expect(row.netReturn, lessThanOrEqualTo(row.grossReturn + 1e-9),
            reason:
                '${row.instrument}: netReturn (${row.netReturn}) > grossReturn (${row.grossReturn})');
      }
    });

    // ------------------------------------------------------------------
    // 3. PPF has zero tax impact (tax-free), net == gross
    // ------------------------------------------------------------------
    test('PPF has zero tax impact and net return equals gross return', () {
      final result = compute(baseInput);
      final ppf = result.rows.firstWhere(
        (r) => r.instrument.toLowerCase().contains('ppf'),
        orElse: () => throw TestFailure('PPF row not found'),
      );
      expect(ppf.taxImpact, closeTo(0, 1e-9),
          reason: 'PPF should have zero tax impact');
      expect(ppf.netReturn, closeTo(ppf.grossReturn, 1e-9),
          reason: 'PPF net return should equal gross return');
    });

    // ------------------------------------------------------------------
    // 4. Debt funds use slab rate (taxTreatment contains 'slab')
    //    for both 1-year and 5-year horizons (post April 2023 rule)
    // ------------------------------------------------------------------
    test('debt funds use slab-rate tax treatment for 1Y horizon', () {
      final input1y = DecisionMatrixInput(
        amount: 100000,
        horizonYears: 1,
        taxSlabPct: 30,
        isNewRegime: false,
      );
      final result = compute(input1y);
      final debtFunds = result.rows
          .where((r) => r.category == 'Debt')
          .toList();
      expect(debtFunds, isNotEmpty, reason: 'Expected at least one Debt row');
      for (final row in debtFunds) {
        expect(row.taxTreatment.toLowerCase(), contains('slab'),
            reason: '${row.instrument} should use slab rate at 1Y');
      }
    });

    test('debt funds use slab-rate tax treatment for 5Y horizon', () {
      final result = compute(baseInput); // baseInput has horizonYears = 5
      final debtFunds = result.rows
          .where((r) => r.category == 'Debt')
          .toList();
      expect(debtFunds, isNotEmpty, reason: 'Expected at least one Debt row');
      for (final row in debtFunds) {
        expect(row.taxTreatment.toLowerCase(), contains('slab'),
            reason: '${row.instrument} should use slab rate at 5Y');
      }
    });

    // ------------------------------------------------------------------
    // 5. Equity funds → STCG for 1-year horizon
    // ------------------------------------------------------------------
    test('equity funds show STCG tax treatment for 1-year horizon', () {
      final input1y = DecisionMatrixInput(
        amount: 100000,
        horizonYears: 1,
        taxSlabPct: 30,
        isNewRegime: false,
      );
      final result = compute(input1y);
      final equityRows = result.rows
          .where((r) => r.category == 'Equity')
          .toList();
      expect(equityRows, isNotEmpty, reason: 'Expected at least one Equity row');
      for (final row in equityRows) {
        expect(row.taxTreatment, contains('STCG'),
            reason: '${row.instrument} should use STCG at 1Y');
      }
    });

    // ------------------------------------------------------------------
    // 6. Maturity value increases with longer horizon
    // ------------------------------------------------------------------
    test('maturity value is higher for 10Y horizon than 5Y', () {
      final result5y = compute(baseInput);
      final result10y = compute(const DecisionMatrixInput(
        amount: 100000,
        horizonYears: 10,
        taxSlabPct: 30,
        isNewRegime: false,
      ));

      // Pick a stable instrument: PPF
      final ppf5y = result5y.rows
          .firstWhere((r) => r.instrument.toLowerCase().contains('ppf'));
      final ppf10y = result10y.rows
          .firstWhere((r) => r.instrument.toLowerCase().contains('ppf'));

      expect(ppf10y.maturityValue, greaterThan(ppf5y.maturityValue),
          reason: 'PPF maturity should be larger over longer horizon');
    });

    // ------------------------------------------------------------------
    // 7. Higher tax slab → higher tax impact on debt vs lower slab
    // ------------------------------------------------------------------
    test('30% slab yields higher tax impact on debt than 10% slab', () {
      final result30 = compute(baseInput); // 30% slab
      final result10 = compute(const DecisionMatrixInput(
        amount: 100000,
        horizonYears: 5,
        taxSlabPct: 10,
        isNewRegime: false,
      ));

      final debtAt30 = result30.rows
          .where((r) => r.category == 'Debt')
          .fold(0.0, (sum, r) => sum + r.taxImpact);
      final debtAt10 = result10.rows
          .where((r) => r.category == 'Debt')
          .fold(0.0, (sum, r) => sum + r.taxImpact);

      expect(debtAt30, greaterThan(debtAt10),
          reason: 'Higher slab should produce higher aggregate tax impact on debt');
    });

    // ------------------------------------------------------------------
    // 8. Rows sorted by net return descending
    // ------------------------------------------------------------------
    test('rows are sorted by net return descending', () {
      final result = compute(baseInput);
      final rows = result.rows;
      for (int i = 0; i < rows.length - 1; i++) {
        expect(
          rows[i].netReturn,
          greaterThanOrEqualTo(rows[i + 1].netReturn - 1e-9),
          reason:
              'Row $i (${rows[i].instrument}: ${rows[i].netReturn}) should be '
              '>= row ${i + 1} (${rows[i + 1].instrument}: ${rows[i + 1].netReturn})',
        );
      }
    });

    // ------------------------------------------------------------------
    // 9. Maturity value >= investment amount for all instruments
    // ------------------------------------------------------------------
    test('maturity value is >= investment amount for all instruments', () {
      final result = compute(baseInput);
      for (final row in result.rows) {
        expect(row.maturityValue, greaterThanOrEqualTo(baseInput.amount - 1e-9),
            reason:
                '${row.instrument} maturity (${row.maturityValue}) is less than '
                'investment amount (${baseInput.amount})');
      }
    });
  });
}
