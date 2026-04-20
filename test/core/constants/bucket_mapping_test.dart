import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/core/constants/asset_classes.dart';
import 'package:evesh_wealth/core/constants/bucket_mapping.dart';

void main() {
  group('bucketFor (AssetClass + TaxCategory)', () {
    test('hybrid + hybridE → growth', () {
      expect(bucketFor(AssetClass.hybrid, TaxCategory.hybridE), Bucket.growth);
    });

    test('hybrid + hybridD → fixedIncome', () {
      expect(bucketFor(AssetClass.hybrid, TaxCategory.hybridD), Bucket.fixedIncome);
    });

    test('hybrid + null tax → fixedIncome (conservative default)', () {
      expect(bucketFor(AssetClass.hybrid, null), Bucket.fixedIncome);
    });

    test('liquid → liquid', () {
      expect(bucketFor(AssetClass.liquid), Bucket.liquid);
    });

    test('debt → fixedIncome', () {
      expect(bucketFor(AssetClass.debt), Bucket.fixedIncome);
    });

    for (final c in [
      AssetClass.coreEquity,
      AssetClass.satelliteEquity,
      AssetClass.gold,
      AssetClass.alternate,
    ]) {
      test('$c → growth', () => expect(bucketFor(c), Bucket.growth));
    }
  });

  group('bucketForAssetType', () {
    test('fd → fixedIncome', () {
      expect(bucketForAssetType(AssetType.fd), Bucket.fixedIncome);
    });

    test('ppf → fixedIncome', () {
      expect(bucketForAssetType(AssetType.ppf), Bucket.fixedIncome);
    });

    test('nps default → growth', () {
      expect(bucketForAssetType(AssetType.nps), Bucket.growth);
    });

    test('nps + TierIIDebt subType → fixedIncome', () {
      expect(bucketForAssetType(AssetType.nps, subType: 'TierIIDebt'), Bucket.fixedIncome);
    });

    test('nps + subType containing "debt" (any case) → fixedIncome', () {
      expect(bucketForAssetType(AssetType.nps, subType: 'Tier II Debt Fund'), Bucket.fixedIncome);
    });

    for (final t in [
      AssetType.realEstate,
      AssetType.sgb,
      AssetType.gold,
      AssetType.reit,
      AssetType.invIt,
      AssetType.aif,
      AssetType.sif,
      AssetType.pms,
      AssetType.stock,
      AssetType.other,
    ]) {
      test('$t → growth', () => expect(bucketForAssetType(t), Bucket.growth));
    }

    test('mf throws ArgumentError', () {
      expect(() => bucketForAssetType(AssetType.mf), throwsArgumentError);
    });
  });

  group('bucketFromOverride', () {
    test('"liquid" → liquid', () {
      expect(bucketFromOverride('liquid'), Bucket.liquid);
    });

    test('"fixedIncome" → fixedIncome', () {
      expect(bucketFromOverride('fixedIncome'), Bucket.fixedIncome);
    });

    test('"growth" → growth', () {
      expect(bucketFromOverride('growth'), Bucket.growth);
    });

    test('null → null', () {
      expect(bucketFromOverride(null), isNull);
    });

    test('unknown string → null', () {
      expect(bucketFromOverride('garbage'), isNull);
    });
  });

  group('BucketMeta', () {
    test('displayName', () {
      expect(Bucket.liquid.displayName, 'Liquid');
      expect(Bucket.fixedIncome.displayName, 'Fixed Income');
      expect(Bucket.growth.displayName, 'Growth');
    });

    test('shortLabel', () {
      expect(Bucket.liquid.shortLabel, 'LIQ');
      expect(Bucket.fixedIncome.shortLabel, 'FI');
      expect(Bucket.growth.shortLabel, 'GROW');
    });
  });
}
