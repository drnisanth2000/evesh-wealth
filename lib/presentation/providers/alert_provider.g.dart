// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$alertsHash() => r'3ec953904da6ea02bee729cf16f70f41c4b8ff7f';

/// See also [alerts].
@ProviderFor(alerts)
final alertsProvider = AutoDisposeFutureProvider<List<AlertModel>>.internal(
  alerts,
  name: r'alertsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$alertsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AlertsRef = AutoDisposeFutureProviderRef<List<AlertModel>>;
String _$alertNotifierHash() => r'1e87429ffd45e53484cb69f1d9dc95dd4bef987e';

/// See also [AlertNotifier].
@ProviderFor(AlertNotifier)
final alertNotifierProvider =
    AutoDisposeNotifierProvider<AlertNotifier, AsyncValue<void>>.internal(
  AlertNotifier.new,
  name: r'alertNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$alertNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AlertNotifier = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
