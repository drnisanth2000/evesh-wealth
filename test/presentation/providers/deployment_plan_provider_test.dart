import 'package:evesh_wealth/data/models/deployment_plan_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeploymentPlans provider wiring', () {
    test('JSON list maps DeploymentPlanModel with nested plan_jsonb', () {
      final rows = <Map<String, dynamic>>[
        {
          'id': 'dp1',
          'owner_id': 'u1',
          'lumpsum_rupees': 100000.0,
          'sip_rupees': 25000.0,
          'split_pct': 30.0,
          'plan_jsonb': {
            'tranches': [
              {'month': 1, 'amount': 33333},
              {'month': 2, 'amount': 33333},
            ],
            'strategy': 'STP-12m',
          },
          'created_at': '2026-04-18T00:00:00Z',
        },
      ];
      final list = rows.map(DeploymentPlanModel.fromJson).toList();
      expect(list, hasLength(1));
      expect(list.first.lumpsumRupees, 100000.0);
      expect(list.first.planJson['strategy'], 'STP-12m');
      expect((list.first.planJson['tranches'] as List), hasLength(2));
    });
  });
}
