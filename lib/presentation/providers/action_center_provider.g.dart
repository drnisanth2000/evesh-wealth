// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_center_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$actionCenterPlanHash() => r'0ed38bbab0497080f580a71c336a932b39bd6c4f';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [actionCenterPlan].
@ProviderFor(actionCenterPlan)
const actionCenterPlanProvider = ActionCenterPlanFamily();

/// See also [actionCenterPlan].
class ActionCenterPlanFamily extends Family<AsyncValue<RebalancePlan>> {
  /// See also [actionCenterPlan].
  const ActionCenterPlanFamily();

  /// See also [actionCenterPlan].
  ActionCenterPlanProvider call(
    String? memberId,
  ) {
    return ActionCenterPlanProvider(
      memberId,
    );
  }

  @override
  ActionCenterPlanProvider getProviderOverride(
    covariant ActionCenterPlanProvider provider,
  ) {
    return call(
      provider.memberId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'actionCenterPlanProvider';
}

/// See also [actionCenterPlan].
class ActionCenterPlanProvider
    extends AutoDisposeFutureProvider<RebalancePlan> {
  /// See also [actionCenterPlan].
  ActionCenterPlanProvider(
    String? memberId,
  ) : this._internal(
          (ref) => actionCenterPlan(
            ref as ActionCenterPlanRef,
            memberId,
          ),
          from: actionCenterPlanProvider,
          name: r'actionCenterPlanProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$actionCenterPlanHash,
          dependencies: ActionCenterPlanFamily._dependencies,
          allTransitiveDependencies:
              ActionCenterPlanFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  ActionCenterPlanProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.memberId,
  }) : super.internal();

  final String? memberId;

  @override
  Override overrideWith(
    FutureOr<RebalancePlan> Function(ActionCenterPlanRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActionCenterPlanProvider._internal(
        (ref) => create(ref as ActionCenterPlanRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        memberId: memberId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<RebalancePlan> createElement() {
    return _ActionCenterPlanProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActionCenterPlanProvider && other.memberId == memberId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, memberId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ActionCenterPlanRef on AutoDisposeFutureProviderRef<RebalancePlan> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _ActionCenterPlanProviderElement
    extends AutoDisposeFutureProviderElement<RebalancePlan>
    with ActionCenterPlanRef {
  _ActionCenterPlanProviderElement(super.provider);

  @override
  String? get memberId => (origin as ActionCenterPlanProvider).memberId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
