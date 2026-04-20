// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_prefs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationPrefsHash() => r'2ff021a4ff44643be624485ee743afb8df767133';

/// See also [notificationPrefs].
@ProviderFor(notificationPrefs)
final notificationPrefsProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
  notificationPrefs,
  name: r'notificationPrefsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationPrefsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationPrefsRef
    = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$notificationPrefsNotifierHash() =>
    r'ff6502b185d5c50f2654d8536569519623933b22';

/// See also [NotificationPrefsNotifier].
@ProviderFor(NotificationPrefsNotifier)
final notificationPrefsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<NotificationPrefsNotifier, void>.internal(
  NotificationPrefsNotifier.new,
  name: r'notificationPrefsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationPrefsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotificationPrefsNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
