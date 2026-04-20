import 'package:evesh_wealth/data/models/pending_order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PendingOrderModel JSON round-trip', () {
    test('minimal required fields round-trip', () {
      final json = <String, dynamic>{
        'id': 'o1',
        'owner_id': 'u1',
        'fund_name': 'Parag Parikh Flexi Cap',
        'order_kind': 'buy',
        'created_at': '2026-04-18T00:00:00Z',
      };

      final model = PendingOrderModel.fromJson(json);
      final roundTripped = PendingOrderModel.fromJson(model.toJson());

      expect(roundTripped, equals(model));
      expect(roundTripped.id, 'o1');
      expect(roundTripped.ownerId, 'u1');
      expect(roundTripped.fundName, 'Parag Parikh Flexi Cap');
      expect(roundTripped.orderKind, 'buy');
      expect(roundTripped.createdAt, '2026-04-18T00:00:00Z');
      // Defaults
      expect(roundTripped.assetType, 'MF');
      expect(roundTripped.status, 'placed');
      expect(roundTripped.source, 'manual');
      // Optional nulls
      expect(roundTripped.familyId, isNull);
      expect(roundTripped.memberId, isNull);
      expect(roundTripped.amfiCode, isNull);
      expect(roundTripped.switchToAmfi, isNull);
      expect(roundTripped.amount, isNull);
      expect(roundTripped.units, isNull);
      expect(roundTripped.sourceRef, isNull);
      expect(roundTripped.notes, isNull);
      expect(roundTripped.executedAt, isNull);
    });

    test('all fields round-trip', () {
      final json = <String, dynamic>{
        'id': 'o2',
        'owner_id': 'u1',
        'family_id': 'f1',
        'member_id': 'm1',
        'amfi_code': 122639,
        'fund_name': 'Parag Parikh Flexi Cap',
        'asset_type': 'MF',
        'order_kind': 'switch',
        'switch_to_amfi': 118989,
        'amount': 50000.0,
        'units': 123.4567,
        'status': 'executed',
        'source': 'rebalance',
        'source_ref': 'ref-uuid-1',
        'notes': 'switch into Nifty index fund',
        'created_at': '2026-04-18T00:00:00Z',
        'executed_at': '2026-04-19T00:00:00Z',
      };

      final model = PendingOrderModel.fromJson(json);
      final roundTripped = PendingOrderModel.fromJson(model.toJson());

      expect(roundTripped, equals(model));
      expect(roundTripped.familyId, 'f1');
      expect(roundTripped.memberId, 'm1');
      expect(roundTripped.amfiCode, 122639);
      expect(roundTripped.assetType, 'MF');
      expect(roundTripped.orderKind, 'switch');
      expect(roundTripped.switchToAmfi, 118989);
      expect(roundTripped.amount, 50000.0);
      expect(roundTripped.units, 123.4567);
      expect(roundTripped.status, 'executed');
      expect(roundTripped.source, 'rebalance');
      expect(roundTripped.sourceRef, 'ref-uuid-1');
      expect(roundTripped.notes, 'switch into Nifty index fund');
      expect(roundTripped.executedAt, '2026-04-19T00:00:00Z');
    });
  });

  group('PendingOrderHelpers extensions', () {
    PendingOrderModel build({String orderKind = 'buy', String status = 'placed'}) {
      return PendingOrderModel(
        id: 'o1',
        ownerId: 'u1',
        fundName: 'X',
        orderKind: orderKind,
        status: status,
        createdAt: '2026-04-18T00:00:00Z',
      );
    }

    test('kind converts "switch" to OrderKind.switchOrder', () {
      final m = build(orderKind: 'switch');
      expect(m.kind, OrderKind.switchOrder);
    });

    test('statusEnum converts "executed" to OrderStatus.executed', () {
      final m = build(status: 'executed');
      expect(m.statusEnum, OrderStatus.executed);
    });
  });

  group('OrderStatus.isOpen', () {
    test('draft is open', () {
      expect(OrderStatus.draft.isOpen, isTrue);
    });

    test('placed is open', () {
      expect(OrderStatus.placed.isOpen, isTrue);
    });

    test('executed is not open', () {
      expect(OrderStatus.executed.isOpen, isFalse);
    });

    test('cancelled is not open', () {
      expect(OrderStatus.cancelled.isOpen, isFalse);
    });
  });

  group('OrderKind.fromDb', () {
    test('parses all known values', () {
      expect(OrderKind.fromDb('buy'), OrderKind.buy);
      expect(OrderKind.fromDb('sip'), OrderKind.sip);
      expect(OrderKind.fromDb('lumpsum'), OrderKind.lumpsum);
      expect(OrderKind.fromDb('switch'), OrderKind.switchOrder);
      expect(OrderKind.fromDb('swp'), OrderKind.swp);
      expect(OrderKind.fromDb('sell'), OrderKind.sell);
      expect(OrderKind.fromDb('gift'), OrderKind.gift);
    });

    test('throws ArgumentError on unknown value', () {
      expect(() => OrderKind.fromDb('garbage'), throwsArgumentError);
    });
  });
}
