import 'package:evesh_wealth/data/models/rebalance_dismissal_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RebalanceDismissals provider wiring', () {
    test('JSON list maps to RebalanceDismissalModel list', () {
      final rows = <Map<String, dynamic>>[
        {
          'id': 'd1',
          'owner_id': 'u1',
          'suggestion_hash': 'abc123',
          'from_amfi_code': 100,
          'to_amfi_code': 200,
          'drift_pct': 5.5,
          'reason': 'happy with allocation',
          'dismissed_at': '2026-04-18T00:00:00Z',
        },
      ];
      final list = rows.map(RebalanceDismissalModel.fromJson).toList();
      expect(list, hasLength(1));
      expect(list.first.suggestionHash, 'abc123');
      expect(list.first.fromAmfiCode, 100);
      expect(list.first.driftPct, 5.5);
    });
  });
}
