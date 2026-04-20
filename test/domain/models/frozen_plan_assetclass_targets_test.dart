import 'package:evesh_wealth/domain/models/simulation_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FrozenPlan.assetClassTargets', () {
    test('round-trip JSON preserves the asset-class targets map', () {
      final plan = FrozenPlan(
        ownerId: 'owner-1',
        memberId: 'member-1',
        fundAllocations: const {100: 50000.0},
        additionalLumpsum: 0,
        additionalSip: 0,
        assetClassTargets: const {
          'coreEquity': 60.0,
          'hybrid': 0.0,
          'debt': 30.0,
          'liquid': 10.0,
        },
        status: 'active',
      );

      final round = FrozenPlan.fromJson(plan.toJson());

      expect(round.assetClassTargets, isNotNull);
      expect(round.assetClassTargets!['coreEquity'], 60.0);
      expect(round.assetClassTargets!['hybrid'], 0.0);
      expect(round.assetClassTargets!['debt'], 30.0);
      expect(round.assetClassTargets!['liquid'], 10.0);
    });

    test('JSON without assetClassTargets key → field is null (back-compat)',
        () {
      final json = <String, dynamic>{
        'ownerId': 'owner-1',
        'fundAllocations': <String, dynamic>{},
        'additionalLumpsum': 0,
        'additionalSip': 0,
        'status': 'active',
      };

      final plan = FrozenPlan.fromJson(json);
      expect(plan.assetClassTargets, isNull);

      // Toggling back to JSON should NOT introduce the key.
      expect(plan.toJson().containsKey('assetClassTargets'), isFalse);
    });
  });
}
