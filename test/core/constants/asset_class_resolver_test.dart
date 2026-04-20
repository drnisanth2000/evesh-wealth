import 'package:evesh_wealth/core/constants/asset_class_resolver.dart';
import 'package:evesh_wealth/core/constants/asset_classes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAssetClass', () {
    test('amfiCategoryId debt_liquid → liquid', () {
      expect(
        resolveAssetClass(amfiCategoryId: 'debt_liquid'),
        AssetClass.liquid,
      );
    });

    test('amfiCategoryId equity_flexi_cap → coreEquity', () {
      expect(
        resolveAssetClass(amfiCategoryId: 'equity_flexi_cap'),
        AssetClass.coreEquity,
      );
    });

    test('null amfiCategoryId + assetClassLabel "Liquid" → liquid', () {
      expect(
        resolveAssetClass(assetClassLabel: 'Liquid'),
        AssetClass.liquid,
      );
    });

    test('only category "Liquid Fund" (free-text) → alternate (legacy fromString)', () {
      // Documents existing fromString behaviour: free-text "Liquid Fund" is
      // not understood, so we degrade to Alternate. AMFI category ID is the
      // canonical fix.
      expect(
        resolveAssetClass(category: 'Liquid Fund'),
        AssetClass.alternate,
      );
    });

    test('all null → alternate', () {
      expect(resolveAssetClass(), AssetClass.alternate);
    });

    test('amfiCategoryId wins over conflicting label', () {
      expect(
        resolveAssetClass(
          amfiCategoryId: 'debt_liquid',
          assetClassLabel: 'Core Equity',
        ),
        AssetClass.liquid,
      );
    });

    test('unknown amfiCategoryId falls through to label', () {
      expect(
        resolveAssetClass(
          amfiCategoryId: 'bogus_id',
          assetClassLabel: 'Debt',
        ),
        AssetClass.debt,
      );
    });
  });
}
