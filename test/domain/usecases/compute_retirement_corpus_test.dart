import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/domain/models/retirement_models.dart';
import 'package:evesh_wealth/domain/usecases/compute_retirement_corpus.dart';

void main() {
  group('RetirementCorpusCalculator', () {
    // -------------------------------------------------------------------------
    // Test 1: Basic corpus calculation
    // -------------------------------------------------------------------------
    group('basic corpus calculation', () {
      test(
        'age 30, retire 60, life 85, 50k/month, 6% inflation → corpus > 5Cr',
        () {
          final result = RetirementCorpusCalculator.compute(
            currentAge: 30,
            retirementAge: 60,
            lifeExpectancy: 85,
            monthlyExpense: 50000,
            annualExpenseItems: [],
            inflationRate: 0.06,
            postRetirementReturn: 0.08,
          );

          expect(result.yearsToRetirement, equals(30));
          expect(result.retirementYears, equals(25));

          // Monthly expense at retirement: 50000 × (1.06^30) ≈ 287,175
          expect(
            result.monthlyExpenseAtRetirement,
            closeTo(287175, 5000),
          );

          // Corpus should exceed 5 crore (5,00,00,000)
          expect(result.requiredCorpus, greaterThan(5e7));
        },
      );
    });

    // -------------------------------------------------------------------------
    // Test 2: Annual expenses included / excluded
    // -------------------------------------------------------------------------
    group('annual expense items', () {
      test(
        'only included items inflate the corpus; excluded items ignored',
        () {
          final items = [
            const RetirementExpenseItem(
              name: 'Health Insurance',
              amount: 50000,
              frequency: 'annual',
              includeInRetirement: true,
            ),
            const RetirementExpenseItem(
              name: 'Term Life',
              amount: 30000,
              frequency: 'annual',
              includeInRetirement: false, // should be excluded
            ),
            const RetirementExpenseItem(
              name: 'Club Membership',
              amount: 5000,
              frequency: 'monthly',
              includeInRetirement: true,
            ),
          ];

          final result = RetirementCorpusCalculator.compute(
            currentAge: 30,
            retirementAge: 60,
            lifeExpectancy: 85,
            monthlyExpense: 50000,
            annualExpenseItems: items,
            inflationRate: 0.06,
            postRetirementReturn: 0.08,
          );

          // totalMonthlyNeed must be greater than inflated monthly alone
          expect(
            result.totalMonthlyNeedAtRetirement,
            greaterThan(result.monthlyExpenseAtRetirement),
          );

          // annualRetirementExpenses must reflect only included items:
          // health (50k annual) + club (5k/month = 60k/yr) = 110k/yr
          // Inflated over 30 years at 6%: 110000 × 1.06^30
          final expectedAnnualInflated = 110000 * (1.06 * 1.06 * 1.06 * 1.06 *
              1.06 * 1.06 * 1.06 * 1.06 * 1.06 * 1.06 *
              1.06 * 1.06 * 1.06 * 1.06 * 1.06 * 1.06 *
              1.06 * 1.06 * 1.06 * 1.06 * 1.06 * 1.06 *
              1.06 * 1.06 * 1.06 * 1.06 * 1.06 * 1.06 *
              1.06 * 1.06);
          expect(
            result.annualRetirementExpenses,
            closeTo(expectedAnnualInflated, expectedAnnualInflated * 0.01),
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    // Test 3: Already retired
    // -------------------------------------------------------------------------
    group('already retired', () {
      test(
        'age 62, retirement 60: yearsToRetirement=0, retirementYears=23, no inflation compounding',
        () {
          final result = RetirementCorpusCalculator.compute(
            currentAge: 62,
            retirementAge: 60,
            lifeExpectancy: 85,
            monthlyExpense: 80000,
            annualExpenseItems: [],
            inflationRate: 0.06,
            postRetirementReturn: 0.08,
          );

          expect(result.yearsToRetirement, equals(0));
          expect(result.retirementYears, equals(23));

          // No inflation compounding: expense stays at 80000
          expect(result.monthlyExpenseAtRetirement, closeTo(80000, 1));

          // Corpus must still be positive
          expect(result.requiredCorpus, greaterThan(0));
        },
      );
    });

    // -------------------------------------------------------------------------
    // Test 4: Zero monthly expense
    // -------------------------------------------------------------------------
    group('zero monthly expense', () {
      test('zero expense and no items → zero corpus', () {
        final result = RetirementCorpusCalculator.compute(
          currentAge: 30,
          retirementAge: 60,
          lifeExpectancy: 85,
          monthlyExpense: 0,
          annualExpenseItems: [],
          inflationRate: 0.06,
          postRetirementReturn: 0.08,
        );

        expect(result.requiredCorpus, closeTo(0, 0.01));
        expect(result.monthlyExpenseAtRetirement, closeTo(0, 0.01));
      });
    });

    // -------------------------------------------------------------------------
    // Test 5: Custom inflation — 7% produces larger corpus than 5%
    // -------------------------------------------------------------------------
    group('custom inflation rate', () {
      test('7% inflation produces larger corpus than 5%', () {
        final result5 = RetirementCorpusCalculator.compute(
          currentAge: 30,
          retirementAge: 60,
          lifeExpectancy: 85,
          monthlyExpense: 50000,
          annualExpenseItems: [],
          inflationRate: 0.05,
          postRetirementReturn: 0.08,
        );

        final result7 = RetirementCorpusCalculator.compute(
          currentAge: 30,
          retirementAge: 60,
          lifeExpectancy: 85,
          monthlyExpense: 50000,
          annualExpenseItems: [],
          inflationRate: 0.07,
          postRetirementReturn: 0.08,
        );

        expect(result7.requiredCorpus, greaterThan(result5.requiredCorpus));
        expect(
          result7.monthlyExpenseAtRetirement,
          greaterThan(result5.monthlyExpenseAtRetirement),
        );
      });
    });

    // -------------------------------------------------------------------------
    // Test 6: Present-value annuity check
    // -------------------------------------------------------------------------
    group('present-value annuity', () {
      test(
        'age 55, retire 60, 100k/month → inflated monthly ≈ 133,823; corpus > 15× annual need',
        () {
          final result = RetirementCorpusCalculator.compute(
            currentAge: 55,
            retirementAge: 60,
            lifeExpectancy: 85,
            monthlyExpense: 100000,
            annualExpenseItems: [],
            inflationRate: 0.06,
            postRetirementReturn: 0.08,
          );

          // Monthly need at retirement: 100000 × 1.06^5 ≈ 133,823
          expect(
            result.monthlyExpenseAtRetirement,
            closeTo(133823, 2000),
          );

          // Annual need at retirement
          final annualNeed = result.totalMonthlyNeedAtRetirement * 12;

          // Corpus should be > 15× annual need (PV discounting over 25 years)
          expect(result.requiredCorpus, greaterThan(annualNeed * 15));
        },
      );
    });

    // -------------------------------------------------------------------------
    // Test 7: Frequency-based annualised
    // -------------------------------------------------------------------------
    group('RetirementExpenseItem.annualised', () {
      test('monthly 1k → 12k, quarterly 5k → 20k, annual 100k → 100k; total = 132k', () {
        const monthlyItem = RetirementExpenseItem(
          name: 'Monthly',
          amount: 1000,
          frequency: 'monthly',
          includeInRetirement: true,
        );
        const quarterlyItem = RetirementExpenseItem(
          name: 'Quarterly',
          amount: 5000,
          frequency: 'quarterly',
          includeInRetirement: true,
        );
        const annualItem = RetirementExpenseItem(
          name: 'Annual',
          amount: 100000,
          frequency: 'annual',
          includeInRetirement: true,
        );

        expect(monthlyItem.annualised, closeTo(12000, 0.01));
        expect(quarterlyItem.annualised, closeTo(20000, 0.01));
        expect(annualItem.annualised, closeTo(100000, 0.01));

        final total = monthlyItem.annualised +
            quarterlyItem.annualised +
            annualItem.annualised;
        expect(total, closeTo(132000, 0.01));
      });
    });

    // -------------------------------------------------------------------------
    // Test 8: Short vs long retirement
    // -------------------------------------------------------------------------
    group('retirement duration effect', () {
      test('life expectancy 90 produces larger corpus than life expectancy 70', () {
        final resultLong = RetirementCorpusCalculator.compute(
          currentAge: 30,
          retirementAge: 60,
          lifeExpectancy: 90,
          monthlyExpense: 50000,
          annualExpenseItems: [],
          inflationRate: 0.06,
          postRetirementReturn: 0.08,
        );

        final resultShort = RetirementCorpusCalculator.compute(
          currentAge: 30,
          retirementAge: 60,
          lifeExpectancy: 70,
          monthlyExpense: 50000,
          annualExpenseItems: [],
          inflationRate: 0.06,
          postRetirementReturn: 0.08,
        );

        expect(resultLong.retirementYears, equals(30));
        expect(resultShort.retirementYears, equals(10));
        expect(resultLong.requiredCorpus, greaterThan(resultShort.requiredCorpus));
      });
    });
  });
}
