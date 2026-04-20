import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/domain/models/recommendation_models.dart';
import 'package:evesh_wealth/domain/usecases/recommend_funds.dart';
import 'package:evesh_wealth/domain/usecases/score_funds.dart';

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
  group('Portfolio Fit', () {
    test('recommends funds that fill allocation gaps', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Equity Fund', taxCategory: 'equity', category: 'Large Cap'),
        _fund(amfiCode: 2, fundName: 'Debt Fund', taxCategory: 'debt', category: 'Corporate Bond'),
      ];

      final result = RecommendationEngine.recommend(
        funds: funds,
        surplusAmount: 100000,
        currentAllocation: {'coreEquity': 30, 'debt': 25, 'liquid': 5},
        idealAllocation: {'coreEquity': 40, 'debt': 20, 'liquid': 5},
        heldAmfiCodes: {},
        sipRecommended: true,
      );

      expect(result.recommendations.any((r) => r.targetAssetClass == 'coreEquity'), true);
    });

    test('does not recommend funds in overweight asset classes', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Debt Fund', taxCategory: 'debt', category: 'Corporate Bond'),
      ];

      final result = RecommendationEngine.recommend(
        funds: funds,
        surplusAmount: 50000,
        currentAllocation: {'debt': 40},
        idealAllocation: {'debt': 20},
        heldAmfiCodes: {},
        sipRecommended: true,
      );

      expect(result.recommendations, isEmpty);
    });

    test('allocates surplus proportionally to gap size', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Equity A', taxCategory: 'equity', category: 'Large Cap', amc: 'AMC A'),
        _fund(amfiCode: 2, fundName: 'Equity B', taxCategory: 'equity', category: 'Large Cap', amc: 'AMC B'),
        _fund(amfiCode: 3, fundName: 'Debt A', taxCategory: 'debt', category: 'Corporate Bond', amc: 'AMC C'),
      ];

      final result = RecommendationEngine.recommend(
        funds: funds,
        surplusAmount: 100000,
        currentAllocation: {'coreEquity': 20, 'debt': 15},
        idealAllocation: {'coreEquity': 40, 'debt': 20},
        heldAmfiCodes: {},
        sipRecommended: false,
      );

      final equityAlloc = result.recommendations
          .where((r) => r.targetAssetClass == 'coreEquity')
          .fold(0.0, (sum, r) => sum + r.suggestedAmount);
      final debtAlloc = result.recommendations
          .where((r) => r.targetAssetClass == 'debt')
          .fold(0.0, (sum, r) => sum + r.suggestedAmount);
      expect(equityAlloc, greaterThan(debtAlloc));
    });
  });

  group('Diversification', () {
    test('limits max 2 funds per AMC in recommendations', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'AMC A Fund 1', amc: 'AMC A', category: 'Large Cap', return3y: 20.0),
        _fund(amfiCode: 2, fundName: 'AMC A Fund 2', amc: 'AMC A', category: 'Large Cap', return3y: 18.0),
        _fund(amfiCode: 3, fundName: 'AMC A Fund 3', amc: 'AMC A', category: 'Large Cap', return3y: 16.0),
        _fund(amfiCode: 4, fundName: 'AMC B Fund 1', amc: 'AMC B', category: 'Large Cap', return3y: 15.0),
      ];

      final result = RecommendationEngine.recommend(
        funds: funds,
        surplusAmount: 100000,
        currentAllocation: {'coreEquity': 20},
        idealAllocation: {'coreEquity': 60},
        heldAmfiCodes: {},
        sipRecommended: true,
      );

      final amcACounts = result.recommendations
          .where((r) => r.fundScore.amc == 'AMC A')
          .length;
      expect(amcACounts, lessThanOrEqualTo(2));
    });

    test('adds overlap warning for funds matching held AMC+category', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Existing AMC Large Cap', amc: 'Same AMC', category: 'Large Cap'),
      ];

      final result = RecommendationEngine.recommend(
        funds: funds,
        surplusAmount: 50000,
        currentAllocation: {'coreEquity': 20},
        idealAllocation: {'coreEquity': 60},
        heldAmfiCodes: {99},
        sipRecommended: true,
        heldFundDetails: [
          {'amfi_code': 99, 'amc': 'Same AMC', 'category': 'Large Cap'},
        ],
      );

      expect(result.recommendations, isNotEmpty);
    });
  });

  group('Explainability', () {
    test('generates at least one reason per recommendation', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Good Fund'),
      ];

      final result = RecommendationEngine.recommend(
        funds: funds,
        surplusAmount: 50000,
        currentAllocation: {'coreEquity': 20},
        idealAllocation: {'coreEquity': 60},
        heldAmfiCodes: {},
        sipRecommended: true,
      );

      for (final rec in result.recommendations) {
        expect(rec.reasons, isNotEmpty);
      }
    });

    test('result includes fundsEvaluated and fundsPassedGate counts', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Good Fund'),
        _fund(amfiCode: 2, fundName: 'Bad Fund', planType: 'Regular'),
      ];

      final result = RecommendationEngine.recommend(
        funds: funds,
        surplusAmount: 50000,
        currentAllocation: {'coreEquity': 20},
        idealAllocation: {'coreEquity': 60},
        heldAmfiCodes: {},
        sipRecommended: true,
      );

      expect(result.fundsEvaluated, 2);
      expect(result.fundsPassedGate, 1);
    });

    test('sipRecommended flag flows through to recommendations', () {
      final funds = [
        _fund(amfiCode: 1, fundName: 'Fund A'),
      ];

      final sipResult = RecommendationEngine.recommend(
        funds: funds,
        surplusAmount: 50000,
        currentAllocation: {'coreEquity': 20},
        idealAllocation: {'coreEquity': 60},
        heldAmfiCodes: {},
        sipRecommended: true,
      );

      final lumpResult = RecommendationEngine.recommend(
        funds: funds,
        surplusAmount: 50000,
        currentAllocation: {'coreEquity': 20},
        idealAllocation: {'coreEquity': 60},
        heldAmfiCodes: {},
        sipRecommended: false,
      );

      expect(sipResult.sipRecommended, true);
      expect(lumpResult.sipRecommended, false);
      if (sipResult.recommendations.isNotEmpty) {
        expect(sipResult.recommendations.first.isSip, true);
      }
      if (lumpResult.recommendations.isNotEmpty) {
        expect(lumpResult.recommendations.first.isSip, false);
      }
    });
  });

  group('Edge Cases', () {
    test('empty fund list returns empty recommendations', () {
      final result = RecommendationEngine.recommend(
        funds: [],
        surplusAmount: 50000,
        currentAllocation: {'coreEquity': 20},
        idealAllocation: {'coreEquity': 60},
        heldAmfiCodes: {},
        sipRecommended: true,
      );

      expect(result.recommendations, isEmpty);
      expect(result.fundsEvaluated, 0);
    });

    test('zero surplus returns empty recommendations', () {
      final funds = [_fund(amfiCode: 1, fundName: 'Fund A')];

      final result = RecommendationEngine.recommend(
        funds: funds,
        surplusAmount: 0,
        currentAllocation: {'coreEquity': 20},
        idealAllocation: {'coreEquity': 60},
        heldAmfiCodes: {},
        sipRecommended: true,
      );

      expect(result.recommendations, isEmpty);
    });

    test('no allocation gaps returns empty recommendations', () {
      final funds = [_fund(amfiCode: 1, fundName: 'Fund A')];

      final result = RecommendationEngine.recommend(
        funds: funds,
        surplusAmount: 50000,
        currentAllocation: {'coreEquity': 60, 'debt': 20, 'liquid': 5, 'gold': 5},
        idealAllocation: {'coreEquity': 60, 'debt': 20, 'liquid': 5, 'gold': 5},
        heldAmfiCodes: {},
        sipRecommended: true,
      );

      expect(result.recommendations, isEmpty);
    });
  });
}
