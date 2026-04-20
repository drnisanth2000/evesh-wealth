import 'package:evesh_wealth/data/models/other_asset_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OtherAssetModel JSON round-trip', () {
    test('minimal required fields round-trip', () {
      final json = <String, dynamic>{
        'id': 'a1',
        'owner_id': 'u1',
        'asset_type': 'FD',
        'description': 'SBI 3-yr FD',
        'created_at': '2026-01-01T00:00:00Z',
      };

      final model = OtherAssetModel.fromJson(json);
      final roundTripped = OtherAssetModel.fromJson(model.toJson());

      expect(roundTripped, equals(model));
      expect(roundTripped.id, 'a1');
      expect(roundTripped.ownerId, 'u1');
      expect(roundTripped.assetType, 'FD');
      expect(roundTripped.description, 'SBI 3-yr FD');
      expect(roundTripped.createdAt, '2026-01-01T00:00:00Z');
      // Optional fields all null
      expect(roundTripped.familyId, isNull);
      expect(roundTripped.memberId, isNull);
      expect(roundTripped.quantity, isNull);
      expect(roundTripped.costValue, isNull);
      expect(roundTripped.currentValue, isNull);
      expect(roundTripped.bucketOverride, isNull);
    });

    test('all fields round-trip', () {
      final json = <String, dynamic>{
        'id': 'a2',
        'owner_id': 'u1',
        'family_id': 'f1',
        'member_id': 'm1',
        'asset_type': 'SGB',
        'description': 'SGB 2023-24 Series III',
        'isin_symbol': 'IN0020230123',
        'quantity': 50.0,
        'cost_value': 300000.0,
        'current_value': 375000.0,
        'current_price': 7500.0,
        'interest_rate': 2.5,
        'interest_frequency': 'SemiAnnual',
        'accrued_interest': 1500.25,
        'tax_category': 'Gold',
        'start_date': '2024-01-15',
        'maturity_date': '2032-01-15',
        'lock_in_end_date': '2029-01-15',
        'last_valuation_date': '2026-04-17',
        'broker_or_institution': 'RBI',
        'account_number': 'ACC-1234',
        'notes': 'Allocated to long-term bucket',
        'bucket_override': 'growth',
        'last_updated_at': '2026-04-17T10:00:00Z',
        'created_at': '2024-01-15T00:00:00Z',
      };

      final model = OtherAssetModel.fromJson(json);
      final roundTripped = OtherAssetModel.fromJson(model.toJson());

      expect(roundTripped, equals(model));
      expect(roundTripped.familyId, 'f1');
      expect(roundTripped.memberId, 'm1');
      expect(roundTripped.isinSymbol, 'IN0020230123');
      expect(roundTripped.quantity, 50.0);
      expect(roundTripped.costValue, 300000.0);
      expect(roundTripped.currentValue, 375000.0);
      expect(roundTripped.currentPrice, 7500.0);
      expect(roundTripped.interestRate, 2.5);
      expect(roundTripped.interestFrequency, 'SemiAnnual');
      expect(roundTripped.accruedInterest, 1500.25);
      expect(roundTripped.taxCategory, 'Gold');
      expect(roundTripped.startDate, '2024-01-15');
      expect(roundTripped.maturityDate, '2032-01-15');
      expect(roundTripped.lockInEndDate, '2029-01-15');
      expect(roundTripped.lastValuationDate, '2026-04-17');
      expect(roundTripped.brokerOrInstitution, 'RBI');
      expect(roundTripped.accountNumber, 'ACC-1234');
      expect(roundTripped.notes, 'Allocated to long-term bucket');
      expect(roundTripped.bucketOverride, 'growth');
      expect(roundTripped.lastUpdatedAt, '2026-04-17T10:00:00Z');
    });
  });

  group('OtherAssetBucket.effectiveValue', () {
    OtherAssetModel base({
      double? currentValue,
      double? quantity,
      double? currentPrice,
      double? costValue,
    }) {
      return OtherAssetModel(
        id: 'a1',
        ownerId: 'u1',
        assetType: 'FD',
        description: 'x',
        createdAt: '2026-01-01T00:00:00Z',
        currentValue: currentValue,
        quantity: quantity,
        currentPrice: currentPrice,
        costValue: costValue,
      );
    }

    test('returns currentValue when present', () {
      final m = base(currentValue: 12345.67, quantity: 10, currentPrice: 999, costValue: 1);
      expect(m.effectiveValue, 12345.67);
    });

    test('returns quantity * currentPrice when currentValue null', () {
      final m = base(quantity: 10, currentPrice: 250.5, costValue: 1);
      expect(m.effectiveValue, 2505.0);
    });

    test('returns costValue when currentValue and price/qty missing', () {
      final m = base(costValue: 4321.0);
      expect(m.effectiveValue, 4321.0);
    });

    test('returns 0 when all fallbacks are null', () {
      final m = base();
      expect(m.effectiveValue, 0.0);
    });
  });
}
