import 'package:evesh_wealth/data/models/deployment_plan_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeploymentPlanModel JSON round-trip', () {
    test('minimal fields with empty plan_jsonb round-trip', () {
      final json = <String, dynamic>{
        'id': 'p1',
        'owner_id': 'u1',
        'lumpsum_rupees': 0.0,
        'sip_rupees': 0.0,
        'split_pct': 30.0,
        'plan_jsonb': <String, dynamic>{},
        'created_at': '2026-04-18T00:00:00Z',
      };

      final model = DeploymentPlanModel.fromJson(json);
      final roundTripped = DeploymentPlanModel.fromJson(model.toJson());

      expect(roundTripped, equals(model));
      expect(roundTripped.id, 'p1');
      expect(roundTripped.ownerId, 'u1');
      expect(roundTripped.lumpsumRupees, 0.0);
      expect(roundTripped.sipRupees, 0.0);
      expect(roundTripped.splitPct, 30.0);
      expect(roundTripped.planJson, isEmpty);
      expect(roundTripped.familyId, isNull);
      expect(roundTripped.memberId, isNull);
      expect(roundTripped.notes, isNull);
      expect(roundTripped.executedAt, isNull);
    });

    test('non-trivial nested plan_jsonb round-trips', () {
      final planJson = <String, dynamic>{
        'buckets': [
          {'bucket': 'liquid', 'amount': 50000},
          {'bucket': 'growth', 'amount': 200000},
        ],
        'split_pct': 25.0,
      };
      final json = <String, dynamic>{
        'id': 'p2',
        'owner_id': 'u1',
        'family_id': 'f1',
        'member_id': 'm1',
        'lumpsum_rupees': 250000.0,
        'sip_rupees': 25000.0,
        'split_pct': 25.0,
        'plan_jsonb': planJson,
        'notes': 'Q2 deployment',
        'created_at': '2026-04-18T00:00:00Z',
        'executed_at': '2026-04-19T00:00:00Z',
      };

      final model = DeploymentPlanModel.fromJson(json);
      final roundTripped = DeploymentPlanModel.fromJson(model.toJson());

      expect(roundTripped, equals(model));
      expect(roundTripped.familyId, 'f1');
      expect(roundTripped.memberId, 'm1');
      expect(roundTripped.lumpsumRupees, 250000.0);
      expect(roundTripped.sipRupees, 25000.0);
      expect(roundTripped.splitPct, 25.0);
      expect(roundTripped.planJson['buckets'], isA<List>());
      expect((roundTripped.planJson['buckets'] as List).length, 2);
      expect(roundTripped.notes, 'Q2 deployment');
      expect(roundTripped.executedAt, '2026-04-19T00:00:00Z');
    });

    test('defaults applied when lumpsum/sip/split missing from JSON', () {
      final json = <String, dynamic>{
        'id': 'p3',
        'owner_id': 'u1',
        'plan_jsonb': <String, dynamic>{},
        'created_at': '2026-04-18T00:00:00Z',
      };

      final model = DeploymentPlanModel.fromJson(json);

      expect(model.lumpsumRupees, 0.0);
      expect(model.sipRupees, 0.0);
      expect(model.splitPct, 30.0);
    });
  });
}
