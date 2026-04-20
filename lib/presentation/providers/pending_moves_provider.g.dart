// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_moves_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$arrivalsByBucketHash() => r'3f676c9c082884550095672653a4e0b888453a24';

/// Convenience read: arrivals grouped by destination bucket. BucketCompositionCard
/// consumes this to render the faint-text "arriving" rows.
///
/// Copied from [arrivalsByBucket].
@ProviderFor(arrivalsByBucket)
final arrivalsByBucketProvider =
    AutoDisposeProvider<Map<Bucket, List<PendingMove>>>.internal(
  arrivalsByBucket,
  name: r'arrivalsByBucketProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$arrivalsByBucketHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ArrivalsByBucketRef
    = AutoDisposeProviderRef<Map<Bucket, List<PendingMove>>>;
String _$pendingMovesHash() => r'33b1fa6673b9d27eee02f488ab8a99fc49748815';

/// See also [PendingMoves].
@ProviderFor(PendingMoves)
final pendingMovesProvider =
    AutoDisposeNotifierProvider<PendingMoves, List<PendingMove>>.internal(
  PendingMoves.new,
  name: r'pendingMovesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$pendingMovesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PendingMoves = AutoDisposeNotifier<List<PendingMove>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
