import 'package:evesh_wealth/data/models/rebalance_dismissal_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RebalanceDismissalModel JSON round-trip', () {
    test('minimal required fields round-trip', () {
      final json = <String, dynamic>{
        'id': 'd1',
        'owner_id': 'u1',
        'suggestion_hash': 'abc123',
        'dismissed_at': '2026-04-18T00:00:00Z',
      };

      final model = RebalanceDismissalModel.fromJson(json);
      final roundTripped = RebalanceDismissalModel.fromJson(model.toJson());

      expect(roundTripped, equals(model));
      expect(roundTripped.id, 'd1');
      expect(roundTripped.ownerId, 'u1');
      expect(roundTripped.suggestionHash, 'abc123');
      expect(roundTripped.dismissedAt, '2026-04-18T00:00:00Z');
      expect(roundTripped.familyId, isNull);
      expect(roundTripped.memberId, isNull);
      expect(roundTripped.fromAmfiCode, isNull);
      expect(roundTripped.toAmfiCode, isNull);
      expect(roundTripped.driftPct, isNull);
      expect(roundTripped.reason, isNull);
    });

    test('all fields round-trip', () {
      final json = <String, dynamic>{
        'id': 'd2',
        'owner_id': 'u1',
        'family_id': 'f1',
        'member_id': 'm1',
        'suggestion_hash': 'sha256-deadbeef',
        'from_amfi_code': 122639,
        'to_amfi_code': 118989,
        'drift_pct': 7.25,
        'reason': 'too aggressive for short-term goal',
        'dismissed_at': '2026-04-18T00:00:00Z',
      };

      final model = RebalanceDismissalModel.fromJson(json);
      final roundTripped = RebalanceDismissalModel.fromJson(model.toJson());

      expect(roundTripped, equals(model));
      expect(roundTripped.familyId, 'f1');
      expect(roundTripped.memberId, 'm1');
      expect(roundTripped.fromAmfiCode, 122639);
      expect(roundTripped.toAmfiCode, 118989);
      expect(roundTripped.driftPct, 7.25);
      expect(roundTripped.reason, 'too aggressive for short-term goal');
    });

    test('Exit suggestion: to_amfi_code null is preserved', () {
      final json = <String, dynamic>{
        'id': 'd3',
        'owner_id': 'u1',
        'suggestion_hash': 'exit-hash',
        'from_amfi_code': 122639,
        'to_amfi_code': null,
        'drift_pct': 12.5,
        'reason': 'exit underperformer',
        'dismissed_at': '2026-04-18T00:00:00Z',
      };

      final model = RebalanceDismissalModel.fromJson(json);
      final roundTripped = RebalanceDismissalModel.fromJson(model.toJson());

      expect(roundTripped, equals(model));
      expect(roundTripped.fromAmfiCode, 122639);
      expect(roundTripped.toAmfiCode, isNull);
    });
  });
}
