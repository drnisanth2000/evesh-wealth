// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_member_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectedMemberHash() => r'723b9d6860003873bdaf617e73883c178876ca2f';

/// Persisted in `user_prefs` so it survives `go_router` rebuild events that
/// previously reset per-screen `_selectedMemberId` state. `null` means
/// "All members" (family aggregate view).
///
/// Copied from [SelectedMember].
@ProviderFor(SelectedMember)
final selectedMemberProvider =
    NotifierProvider<SelectedMember, String?>.internal(
  SelectedMember.new,
  name: r'selectedMemberProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedMemberHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedMember = Notifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
