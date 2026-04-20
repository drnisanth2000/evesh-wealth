import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/bucket_mapping.dart';

part 'pending_moves_provider.g.dart';

enum PendingMoveKind { reallocation, deployment }

/// Ephemeral in-memory record of a move/deployment that MoveCards register
/// while they are visible. Consumed by the Buckets sub-tab to render
/// faint-text "arriving ₹X from Y" rows on the destination bucket card.
///
/// Not persisted — lifecycle is MoveCard's initState/dispose. Surviving the
/// navigation into the Buckets tab relies on the TabBarView keeping children
/// mounted (default Flutter behavior).
class PendingMove {
  final String id; // unique per MoveCard; usually suggestion hash or deployment line id
  final int? fromAmfi;
  final String fromFundName;
  final Bucket fromBucket;
  final int? toAmfi;
  final String toFundName;
  final Bucket toBucket;
  final double amount;
  final PendingMoveKind kind;

  const PendingMove({
    required this.id,
    required this.fromAmfi,
    required this.fromFundName,
    required this.fromBucket,
    required this.toAmfi,
    required this.toFundName,
    required this.toBucket,
    required this.amount,
    required this.kind,
  });

  PendingMove copyWith({
    int? toAmfi,
    String? toFundName,
    Bucket? toBucket,
    double? amount,
  }) =>
      PendingMove(
        id: id,
        fromAmfi: fromAmfi,
        fromFundName: fromFundName,
        fromBucket: fromBucket,
        toAmfi: toAmfi ?? this.toAmfi,
        toFundName: toFundName ?? this.toFundName,
        toBucket: toBucket ?? this.toBucket,
        amount: amount ?? this.amount,
        kind: kind,
      );
}

@riverpod
class PendingMoves extends _$PendingMoves {
  @override
  List<PendingMove> build() => const [];

  void upsert(PendingMove move) {
    final existing = state.indexWhere((m) => m.id == move.id);
    if (existing < 0) {
      state = [...state, move];
    } else {
      final next = [...state];
      next[existing] = move;
      state = next;
    }
  }

  void remove(String id) {
    state = state.where((m) => m.id != id).toList();
  }

  void clearAll() => state = const [];
}

/// Convenience read: arrivals grouped by destination bucket. BucketCompositionCard
/// consumes this to render the faint-text "arriving" rows.
@riverpod
Map<Bucket, List<PendingMove>> arrivalsByBucket(ArrivalsByBucketRef ref) {
  final moves = ref.watch(pendingMovesProvider);
  final out = <Bucket, List<PendingMove>>{
    for (final b in Bucket.values) b: <PendingMove>[],
  };
  for (final m in moves) {
    out[m.toBucket]!.add(m);
  }
  return out;
}
