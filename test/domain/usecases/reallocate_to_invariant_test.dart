import 'package:evesh_wealth/domain/usecases/reallocate_to_invariant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reallocateToInvariant — pro-rata scaling to class target', () {
    test('single fund in class absorbs the whole class target', () {
      final out = reallocateToInvariant(
        amfiCodes: const [1],
        currentValues: const {1: 50000},
        priorTargets: const {1: 50000},
        editedAmfi: 1,
        editedNewTarget: 80000,
        classTargetRupees: 100000,
      );

      expect(out.length, 1);
      expect(out[1], 100000);
    });

    test('editing up rescales peers DOWN pro-rata to their prior targets', () {
      // Class target ₹120k. Three funds, each at ₹40k. User bumps fund 1 to
      // ₹60k → remaining ₹60k splits equally between 2 and 3 (each prior 40k).
      final out = reallocateToInvariant(
        amfiCodes: const [1, 2, 3],
        currentValues: const {1: 40000, 2: 40000, 3: 40000},
        priorTargets: const {1: 40000, 2: 40000, 3: 40000},
        editedAmfi: 1,
        editedNewTarget: 60000,
        classTargetRupees: 120000,
      );

      expect(out[1], 60000);
      expect(out[2], closeTo(30000, 1));
      expect(out[3], closeTo(30000, 1));
      final sum = out.values.fold<double>(0, (s, v) => s + v);
      expect(sum, closeTo(120000, 1));
    });

    test('editing down rescales peers UP pro-rata to their prior targets', () {
      // Class target ₹120k. Funds at priors 40/30/50. User drops fund 1 to
      // ₹20k → remaining ₹100k. Peers priors sum = 80. Scale = 100/80 = 1.25.
      // Fund 2 → 30 × 1.25 = 37.5k. Fund 3 → 50 × 1.25 = 62.5k.
      final out = reallocateToInvariant(
        amfiCodes: const [1, 2, 3],
        currentValues: const {1: 40000, 2: 30000, 3: 50000},
        priorTargets: const {1: 40000, 2: 30000, 3: 50000},
        editedAmfi: 1,
        editedNewTarget: 20000,
        classTargetRupees: 120000,
      );

      expect(out[1], 20000);
      expect(out[2], closeTo(37500, 1));
      expect(out[3], closeTo(62500, 1));
      final sum = out.values.fold<double>(0, (s, v) => s + v);
      expect(sum, closeTo(120000, 1));
    });

    test('zeroing one fund redistributes its share pro-rata to peer priors',
        () {
      // Class target ₹100k. Funds priors 20/30/50. Zero fund 1 → peers absorb.
      // Peer priors sum = 80. Fund 2 → 30/80 × 100k = 37.5k, Fund 3 → 62.5k.
      final out = reallocateToInvariant(
        amfiCodes: const [1, 2, 3],
        currentValues: const {1: 20000, 2: 30000, 3: 50000},
        priorTargets: const {1: 20000, 2: 30000, 3: 50000},
        editedAmfi: 1,
        editedNewTarget: 0,
        classTargetRupees: 100000,
      );

      expect(out[1], 0);
      expect(out[2], closeTo(37500, 1));
      expect(out[3], closeTo(62500, 1));
    });

    test('edited target exceeds class target → others go to zero', () {
      final out = reallocateToInvariant(
        amfiCodes: const [1, 2],
        currentValues: const {1: 40000, 2: 60000},
        priorTargets: const {1: 40000, 2: 60000},
        editedAmfi: 1,
        editedNewTarget: 150000,
        classTargetRupees: 100000,
      );

      // Edited gets clamped to classTarget = 100000.
      expect(out[1], 100000);
      expect(out[2], 0);
    });

    test('no prior targets → fallback to current-value weights', () {
      final out = reallocateToInvariant(
        amfiCodes: const [1, 2, 3],
        currentValues: const {1: 0, 2: 20000, 3: 30000},
        priorTargets: const {1: 0, 2: 0, 3: 0},
        editedAmfi: 1,
        editedNewTarget: 0,
        classTargetRupees: 50000,
      );

      // ₹50k split 20:30 → fund 2: 20k, fund 3: 30k.
      expect(out[2], closeTo(20000, 1));
      expect(out[3], closeTo(30000, 1));
    });

    test('equal split when no prior targets and no current values', () {
      final out = reallocateToInvariant(
        amfiCodes: const [1, 2, 3],
        currentValues: const {},
        priorTargets: const {},
        editedAmfi: 1,
        editedNewTarget: 10000,
        classTargetRupees: 40000,
      );

      expect(out[1], 10000);
      // Remaining ₹30k / 2 = ₹15k each.
      expect(out[2], closeTo(15000, 1));
      expect(out[3], closeTo(15000, 1));
    });

    test('sum equals class target within ₹1 for mixed weights', () {
      final out = reallocateToInvariant(
        amfiCodes: const [1, 2, 3, 4],
        currentValues: const {1: 10000, 2: 20000, 3: 30000, 4: 40000},
        priorTargets: const {1: 10000, 2: 15000, 3: 25000, 4: 35000},
        editedAmfi: 1,
        editedNewTarget: 5000,
        classTargetRupees: 100000,
      );

      final sum = out.values.fold<double>(0, (s, v) => s + v);
      expect(sum, closeTo(100000, 1));
      expect(out[1], 5000);
    });
  });
}
