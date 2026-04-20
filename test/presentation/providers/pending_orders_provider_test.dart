import 'package:evesh_wealth/data/models/pending_order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PendingOrders provider wiring', () {
    test('OrderStatus.name matches DB string for all variants', () {
      expect(OrderStatus.draft.name, 'draft');
      expect(OrderStatus.placed.name, 'placed');
      expect(OrderStatus.executed.name, 'executed');
      expect(OrderStatus.cancelled.name, 'cancelled');
    });

    test('OrderKind.dbValue maps switchOrder to "switch"', () {
      expect(OrderKind.switchOrder.dbValue, 'switch');
      expect(OrderKind.buy.dbValue, 'buy');
      expect(OrderKind.sip.dbValue, 'sip');
    });

    test('JSON list maps to PendingOrderModel list', () {
      final rows = <Map<String, dynamic>>[
        {
          'id': 'p1',
          'owner_id': 'u1',
          'fund_name': 'Test Fund',
          'order_kind': 'sip',
          'created_at': '2026-04-18T00:00:00Z',
        },
      ];
      final list = rows.map(PendingOrderModel.fromJson).toList();
      expect(list, hasLength(1));
      expect(list.first.kind, OrderKind.sip);
      expect(list.first.statusEnum, OrderStatus.placed);
    });
  });
}
