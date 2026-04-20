import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/domain/models/retirement_models.dart';
import 'package:evesh_wealth/domain/usecases/compute_retirement_corpus.dart';
import 'package:evesh_wealth/domain/usecases/compute_retirement_gap.dart';

void main() {
  group('RetirementGapCalculator', () {
    // -----------------------------------------------------------------------
    // Test 1: Gap when portfolio is insufficient
    // -----------------------------------------------------------------------
    group('gap when portfolio insufficient', () {
      test(
        'age 35, retire 60, 50k/month, 5L portfolio → gap > 0, fundedPct 0–100, requiredSIP > 0, surplus ≈ 50k',
        () {
          final corpus = RetirementCorpusCalculator.compute(
            currentAge: 35,
            retirementAge: 60,
            lifeExpectancy: 85,
            monthlyExpense: 50000,
            annualExpenseItems: [],
          );

          final gap = RetirementGapCalculator.compute(
            corpus: corpus,
            currentPortfolioValue: 500000, // 5 Lakh
            expectedReturn: 0.12,
            monthlyIncome: 100000, // 1 Lakh
            monthlyExpense: 50000,
            annualExpenseItems: [],
            expectedLumpsums: [],
            incomeType: 'steady',
            incomeVariabilityPct: null,
          );

          expect(gap.gap, greaterThan(0));
          expect(gap.fundedPct, greaterThan(0));
          expect(gap.fundedPct, lessThan(100));
          expect(gap.requiredMonthlySip, greaterThan(0));
          // Surplus = 1L - 50k = 50k
          expect(gap.investableSurplus, closeTo(50000, 1000));
        },
      );
    });

    // -----------------------------------------------------------------------
    // Test 2: No gap when over-funded
    // -----------------------------------------------------------------------
    group('no gap when over-funded', () {
      test(
        '10k/month expense, 10Cr portfolio → gap ≤ 0, fundedPct ≥ 100, requiredSIP = 0',
        () {
          final corpus = RetirementCorpusCalculator.compute(
            currentAge: 35,
            retirementAge: 60,
            lifeExpectancy: 85,
            monthlyExpense: 10000, // small expense
            annualExpenseItems: [],
          );

          final gap = RetirementGapCalculator.compute(
            corpus: corpus,
            currentPortfolioValue: 100000000, // 10 Crore
            expectedReturn: 0.12,
            monthlyIncome: 100000,
            monthlyExpense: 50000,
            annualExpenseItems: [],
            expectedLumpsums: [],
            incomeType: 'steady',
            incomeVariabilityPct: null,
          );

          expect(gap.gap, lessThanOrEqualTo(0));
          expect(gap.fundedPct, greaterThanOrEqualTo(100));
          expect(gap.requiredMonthlySip, equals(0));
        },
      );
    });

    // -----------------------------------------------------------------------
    // Test 3: Lumpsums reduce the gap
    // -----------------------------------------------------------------------
    group('lumpsums reduce gap', () {
      test(
        '2M confirmed + 1M tentative lumpsums → smaller gap and projectedLumpsumValue > 0',
        () {
          final corpus = RetirementCorpusCalculator.compute(
            currentAge: 35,
            retirementAge: 60,
            lifeExpectancy: 85,
            monthlyExpense: 50000,
            annualExpenseItems: [],
          );

          final withoutLumpsums = RetirementGapCalculator.compute(
            corpus: corpus,
            currentPortfolioValue: 500000,
            expectedReturn: 0.12,
            monthlyIncome: 100000,
            monthlyExpense: 50000,
            annualExpenseItems: [],
            expectedLumpsums: [],
            incomeType: 'steady',
            incomeVariabilityPct: null,
          );

          final withLumpsums = RetirementGapCalculator.compute(
            corpus: corpus,
            currentPortfolioValue: 500000,
            expectedReturn: 0.12,
            monthlyIncome: 100000,
            monthlyExpense: 50000,
            annualExpenseItems: [],
            expectedLumpsums: [
              const ExpectedLumpsum(
                amount: 2000000, // 20L confirmed
                confidence: 'confirmed',
              ),
              const ExpectedLumpsum(
                amount: 1000000, // 10L tentative
                confidence: 'tentative',
              ),
            ],
            incomeType: 'steady',
            incomeVariabilityPct: null,
          );

          expect(withLumpsums.gap, lessThan(withoutLumpsums.gap));
          expect(withLumpsums.projectedLumpsumValue, greaterThan(0));
        },
      );
    });

    // -----------------------------------------------------------------------
    // Test 4: Surplus accounts for annual expenses
    // -----------------------------------------------------------------------
    group('surplus accounts for annual expenses', () {
      test(
        'income 1L, expense 50k, insurance 60k/yr → surplus ≈ 45k',
        () {
          final corpus = RetirementCorpusCalculator.compute(
            currentAge: 35,
            retirementAge: 60,
            lifeExpectancy: 85,
            monthlyExpense: 50000,
            annualExpenseItems: [],
          );

          const annualInsurance = RetirementExpenseItem(
            name: 'Health Insurance',
            amount: 60000,
            frequency: 'annual',
            includeInRetirement: false,
          );

          final gap = RetirementGapCalculator.compute(
            corpus: corpus,
            currentPortfolioValue: 500000,
            expectedReturn: 0.12,
            monthlyIncome: 100000,
            monthlyExpense: 50000,
            annualExpenseItems: [annualInsurance],
            expectedLumpsums: [],
            incomeType: 'steady',
            incomeVariabilityPct: null,
          );

          // Surplus = 1L - 50k - (60k/12) = 1L - 50k - 5k = 45k
          expect(gap.investableSurplus, closeTo(45000, 1000));
        },
      );
    });

    // -----------------------------------------------------------------------
    // Test 5: Variable income conservative estimate
    // -----------------------------------------------------------------------
    group('variable income conservative estimate', () {
      test(
        'same income 1L: variable has lower surplus than steady',
        () {
          final corpus = RetirementCorpusCalculator.compute(
            currentAge: 35,
            retirementAge: 60,
            lifeExpectancy: 85,
            monthlyExpense: 50000,
            annualExpenseItems: [],
          );

          final steady = RetirementGapCalculator.compute(
            corpus: corpus,
            currentPortfolioValue: 500000,
            expectedReturn: 0.12,
            monthlyIncome: 100000,
            monthlyExpense: 50000,
            annualExpenseItems: [],
            expectedLumpsums: [],
            incomeType: 'steady',
            incomeVariabilityPct: null,
          );

          final variable = RetirementGapCalculator.compute(
            corpus: corpus,
            currentPortfolioValue: 500000,
            expectedReturn: 0.12,
            monthlyIncome: 100000,
            monthlyExpense: 50000,
            annualExpenseItems: [],
            expectedLumpsums: [],
            incomeType: 'variable',
            incomeVariabilityPct: 30,
          );

          expect(variable.investableSurplus, lessThan(steady.investableSurplus));
        },
      );
    });

    // -----------------------------------------------------------------------
    // Test 6: SIP affordability
    // -----------------------------------------------------------------------
    group('SIP affordability', () {
      test(
        'income 55k, expense 50k → surplus ≈ 5k; if requiredSIP > 5k then isSipAffordable = false',
        () {
          final corpus = RetirementCorpusCalculator.compute(
            currentAge: 35,
            retirementAge: 60,
            lifeExpectancy: 85,
            monthlyExpense: 50000,
            annualExpenseItems: [],
          );

          final gap = RetirementGapCalculator.compute(
            corpus: corpus,
            currentPortfolioValue: 500000,
            expectedReturn: 0.12,
            monthlyIncome: 55000,
            monthlyExpense: 50000,
            annualExpenseItems: [],
            expectedLumpsums: [],
            incomeType: 'steady',
            incomeVariabilityPct: null,
          );

          // Surplus = 55k - 50k = 5k
          expect(gap.investableSurplus, closeTo(5000, 500));

          if (gap.requiredMonthlySip > gap.investableSurplus) {
            expect(gap.isSipAffordable, isFalse);
          } else {
            expect(gap.isSipAffordable, isTrue);
          }
        },
      );
    });

    // -----------------------------------------------------------------------
    // Test 7: Zero income → zero surplus (clamped, not negative)
    // -----------------------------------------------------------------------
    group('zero income', () {
      test('income 0, expense 50k → surplus = 0 (clamped)', () {
        final corpus = RetirementCorpusCalculator.compute(
          currentAge: 35,
          retirementAge: 60,
          lifeExpectancy: 85,
          monthlyExpense: 50000,
          annualExpenseItems: [],
        );

        final gap = RetirementGapCalculator.compute(
          corpus: corpus,
          currentPortfolioValue: 500000,
          expectedReturn: 0.12,
          monthlyIncome: 0,
          monthlyExpense: 50000,
          annualExpenseItems: [],
          expectedLumpsums: [],
          incomeType: 'steady',
          incomeVariabilityPct: null,
        );

        expect(gap.investableSurplus, equals(0));
        expect(gap.investableSurplus, greaterThanOrEqualTo(0));
      });
    });

    // -----------------------------------------------------------------------
    // Test 8: Already retired — portfolio not compounded further
    // -----------------------------------------------------------------------
    group('already retired', () {
      test(
        'age 62, retire 60, portfolio 3Cr → projectedPortfolioValue ≈ currentPortfolioValue',
        () {
          final corpus = RetirementCorpusCalculator.compute(
            currentAge: 62,
            retirementAge: 60,
            lifeExpectancy: 85,
            monthlyExpense: 80000,
            annualExpenseItems: [],
          );

          final gap = RetirementGapCalculator.compute(
            corpus: corpus,
            currentPortfolioValue: 30000000, // 3 Crore
            expectedReturn: 0.12,
            monthlyIncome: 100000,
            monthlyExpense: 50000,
            annualExpenseItems: [],
            expectedLumpsums: [],
            incomeType: 'steady',
            incomeVariabilityPct: null,
          );

          // yearsToRetirement = 0 → no compounding
          expect(corpus.yearsToRetirement, equals(0));
          expect(
            gap.projectedPortfolioValue,
            closeTo(gap.currentPortfolioValue, 1),
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // Test 9: Distribution phase computed
    // -----------------------------------------------------------------------
    group('distribution phase', () {
      test('valid corpus with retirementYears > 0 produces valid DistributionPhase', () {
        final corpus = RetirementCorpusCalculator.compute(
          currentAge: 35,
          retirementAge: 60,
          lifeExpectancy: 85,
          monthlyExpense: 50000,
          annualExpenseItems: [],
        );

        expect(corpus.retirementYears, greaterThan(0));

        final dist = RetirementGapCalculator.computeDistributionPhase(
          corpus: corpus.requiredCorpus,
          retirementYears: corpus.retirementYears,
          inflationRate: corpus.inflationRate,
        );

        expect(dist.monthlyIncome, greaterThan(0));
        expect(dist.yearlyProjections, isNotEmpty);
        expect(dist.yearlyProjections.length, equals(corpus.retirementYears));
        expect(dist.sustainabilityLabel, isNotEmpty);

        // Allocation percentages must sum to 100
        final totalAlloc = dist.debtPct + dist.equityPct + dist.incomePct + dist.cashPct;
        expect(totalAlloc, closeTo(100, 0.01));
      });
    });
  });
}
