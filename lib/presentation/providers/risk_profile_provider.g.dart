// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'risk_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectedRiskMemberHash() =>
    r'79fb2ae538043380255db2a01af7b911ad531172';

/// Which member\'s risk profile is currently being viewed.
/// `null` → the family-level "ALL" tab.
///
/// Copied from [SelectedRiskMember].
@ProviderFor(SelectedRiskMember)
final selectedRiskMemberProvider =
    AutoDisposeNotifierProvider<SelectedRiskMember, String?>.internal(
  SelectedRiskMember.new,
  name: r'selectedRiskMemberProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedRiskMemberHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedRiskMember = AutoDisposeNotifier<String?>;
String _$riskProfileMutatorHash() =>
    r'6b9e16544a1c89ca1888e93eaacb68dc2a8b9b7d';

/// See also [RiskProfileMutator].
@ProviderFor(RiskProfileMutator)
final riskProfileMutatorProvider =
    AutoDisposeNotifierProvider<RiskProfileMutator, void>.internal(
  RiskProfileMutator.new,
  name: r'riskProfileMutatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$riskProfileMutatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RiskProfileMutator = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
