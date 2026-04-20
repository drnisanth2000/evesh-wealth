// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$familyMembersHash() => r'4db59d6fa1aee0ee47dec3bd35639abe09fd3e23';

/// See also [familyMembers].
@ProviderFor(familyMembers)
final familyMembersProvider =
    AutoDisposeFutureProvider<List<FamilyMemberModel>>.internal(
  familyMembers,
  name: r'familyMembersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$familyMembersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FamilyMembersRef
    = AutoDisposeFutureProviderRef<List<FamilyMemberModel>>;
String _$selfMemberHash() => r'50897dfaff589bf158795fa21eca02c0987f4616';

/// The family member with relationship 'Self' — the primary user / CEO.
///
/// Copied from [selfMember].
@ProviderFor(selfMember)
final selfMemberProvider =
    AutoDisposeFutureProvider<FamilyMemberModel?>.internal(
  selfMember,
  name: r'selfMemberProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selfMemberHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SelfMemberRef = AutoDisposeFutureProviderRef<FamilyMemberModel?>;
String _$familyHash() => r'0a121a56c4f8fbf353419223dce27bd1bdd09c20';

/// See also [family].
@ProviderFor(family)
final familyProvider = AutoDisposeFutureProvider<FamilyModel?>.internal(
  family,
  name: r'familyProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$familyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FamilyRef = AutoDisposeFutureProviderRef<FamilyModel?>;
String _$currentProfileHash() => r'113deb5b364441b591f9ffb4a9d08e661e1001d5';

/// See also [currentProfile].
@ProviderFor(currentProfile)
final currentProfileProvider =
    AutoDisposeFutureProvider<ProfileModel?>.internal(
  currentProfile,
  name: r'currentProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentProfileRef = AutoDisposeFutureProviderRef<ProfileModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
