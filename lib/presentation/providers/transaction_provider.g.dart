// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionNotifierHash() =>
    r'42922dd9f525bdc58a10a5284760b2e566819f94';

/// Insert a single transaction; returns null on success or error message.
///
/// Copied from [TransactionNotifier].
@ProviderFor(TransactionNotifier)
final transactionNotifierProvider =
    AutoDisposeNotifierProvider<TransactionNotifier, AsyncValue<void>>.internal(
  TransactionNotifier.new,
  name: r'transactionNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transactionNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TransactionNotifier = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
