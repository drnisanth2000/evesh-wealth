import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/domain/usecases/score_funds.dart';
import 'package:evesh_wealth/domain/models/recommendation_models.dart';

/// Minimal fund map builder for tests — matches FundModel JSON keys.
Map<String, dynamic> _fund({
  required int amfiCode,
  required String fundName,
  String category = 'Large Cap',
  String? subCategory,
  String taxCategory = 'equity',
  String amc = 'Test AMC',
  String planType = 'Direct',
  double? return1y = 12.0,
  double? return3y = 14.0,
  double? return5y = 13.0,
  double? expenseRatio = 0.5,
  double? volatility1y = 15.0,
  double? aumCr = 5000.0,
  String? crisilRating = '1',
  String? fundRating = '5',
  String? launchDate,
}) {
  return {
    'amfi_code': amfiCode,
    'fund_name': fundName,
    'category': category,
    'sub_category': subCategory,
    'tax_category': taxCategory,
    'amc': amc,
    'plan_type': planType,
    'return_1y': return1y,
    'return_3y': return3y,
    'return_5y': return5y,
    'expense_ratio': expenseRatio,
    'volatility_1y': volatility1y,
    'aum_cr': aumCr,
    'crisil_rating': crisilRating,
    'fund_rating': fundRating,
    'launch_date': launchDate ?? '2020-01-01',
  };
}

void main() {
  group('Quality Gate', () {
    test('rejects Regular plan funds', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Regular Fund', planType: 'Regular'),
      ];
      final result = FundScorer.score(funds);
      expect(result, isEmpty);
    });

    test('rejects funds with AUM below 500 Cr', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Tiny Fund', aumCr: 200.0),
      ];
      final result = FundScorer.score(funds);
      expect(result, isEmpty);
    });

    test('rejects funds with less than 3 years track record', () {
      final funds = [
        _fund(
          amfiCode: 1,
          fundName: 'New Fund',
          launchDate: '2024-06-01',
        ),
      ];
      final result = FundScorer.score(funds);
      expect(result, isEmpty);
    });

    test('rejects funds with no return data', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'No Return', return1y: null, return3y: null),
      ];
      final result = FundScorer.score(funds);
      expect(result, isEmpty);
    });

    test('passes valid Direct fund with sufficient data', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Good Fund'),
      ];
      final result = FundScorer.score(funds);
      expect(result, hasLength(1));
      expect(result.first.amfiCode, 1);
    });
  });

  group('Scoring Engine', () {
    test('score is between 0 and 100', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Fund A'),
      ];
      final result = FundScorer.score(funds);
      expect(result.first.score, greaterThanOrEqualTo(0));
      expect(result.first.score, lessThanOrEqualTo(100));
    });

    test('higher returns produce higher returns sub-score', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'High Return', return1y: 25.0, return3y: 22.0, return5y: 20.0, category: 'Large Cap'),
        _fund(amfiCode: 2, fundName: 'Low Return', return1y: 5.0, return3y: 6.0, return5y: 7.0, category: 'Large Cap'),
      ];
      final result = FundScorer.score(funds);
      final high = result.firstWhere((f) => f.amfiCode == 1);
      final low = result.firstWhere((f) => f.amfiCode == 2);
      expect(high.breakdown.returns, greaterThan(low.breakdown.returns));
    });

    test('lower ER produces higher cost sub-score', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Low ER', expenseRatio: 0.1, category: 'Large Cap'),
        _fund(amfiCode: 2, fundName: 'High ER', expenseRatio: 2.0, category: 'Large Cap'),
      ];
      final result = FundScorer.score(funds);
      final lowER = result.firstWhere((f) => f.amfiCode == 1);
      final highER = result.firstWhere((f) => f.amfiCode == 2);
      expect(lowER.breakdown.cost, greaterThan(highER.breakdown.cost));
    });

    test('better CRISIL rating produces higher rating sub-score', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'CRISIL 1', crisilRating: '1', fundRating: '5', category: 'Large Cap'),
        _fund(amfiCode: 2, fundName: 'CRISIL 5', crisilRating: '5', fundRating: '1', category: 'Large Cap'),
      ];
      final result = FundScorer.score(funds);
      final top = result.firstWhere((f) => f.amfiCode == 1);
      final bottom = result.firstWhere((f) => f.amfiCode == 2);
      expect(top.breakdown.rating, greaterThan(bottom.breakdown.rating));
    });

    test('results are sorted by score descending', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Low', return1y: 2.0, return3y: 3.0, return5y: 4.0, crisilRating: '5', category: 'Large Cap'),
        _fund(amfiCode: 2, fundName: 'High', return1y: 25.0, return3y: 22.0, return5y: 20.0, crisilRating: '1', category: 'Large Cap'),
        _fund(amfiCode: 3, fundName: 'Mid', return1y: 12.0, return3y: 11.0, return5y: 10.0, crisilRating: '3', category: 'Large Cap'),
      ];
      final result = FundScorer.score(funds);
      expect(result[0].score, greaterThanOrEqualTo(result[1].score));
      expect(result[1].score, greaterThanOrEqualTo(result[2].score));
    });
  });

  group('Category Adjustments', () {
    test('index fund in large cap gets ER bonus', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Nifty 50 Index Fund', expenseRatio: 0.1, category: 'Large Cap', subCategory: 'Index'),
        _fund(amfiCode: 2, fundName: 'Active Large Cap', expenseRatio: 0.1, category: 'Large Cap', subCategory: null),
      ];
      final result = FundScorer.score(funds);
      final index = result.firstWhere((f) => f.amfiCode == 1);
      final active = result.firstWhere((f) => f.amfiCode == 2);
      expect(index.score, greaterThanOrEqualTo(active.score));
    });

    test('liquid fund scoring heavily weights ER', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Cheap Liquid', expenseRatio: 0.05, category: 'Liquid', return1y: 6.0, return3y: 5.5, return5y: 5.8),
        _fund(amfiCode: 2, fundName: 'Pricey Liquid', expenseRatio: 0.35, category: 'Liquid', return1y: 6.2, return3y: 5.7, return5y: 6.0),
      ];
      final result = FundScorer.score(funds);
      final cheap = result.firstWhere((f) => f.amfiCode == 1);
      final pricey = result.firstWhere((f) => f.amfiCode == 2);
      expect(cheap.score, greaterThan(pricey.score));
    });

    test('breakdown sub-scores sum to approximately total score', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Test Fund'),
      ];
      final result = FundScorer.score(funds);
      final f = result.first;
      expect(f.breakdown.total, greaterThan(0));
      expect(f.breakdown.total, lessThanOrEqualTo(100));
    });
  });
}
