// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'projection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$projectionResultHash() => r'73ebc8f1322693f5177f75cd9782fbbd4980b11d';

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

/// See also [projectionResult].
@ProviderFor(projectionResult)
const projectionResultProvider = ProjectionResultFamily();

/// See also [projectionResult].
class ProjectionResultFamily extends Family<AsyncValue<ProjectionResult>> {
  /// See also [projectionResult].
  const ProjectionResultFamily();

  /// See also [projectionResult].
  ProjectionResultProvider call(
    String? memberId,
  ) {
    return ProjectionResultProvider(
      memberId,
    );
  }

  @override
  ProjectionResultProvider getProviderOverride(
    covariant ProjectionResultProvider provider,
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
  String? get name => r'projectionResultProvider';
}

/// See also [projectionResult].
class ProjectionResultProvider
    extends AutoDisposeFutureProvider<ProjectionResult> {
  /// See also [projectionResult].
  ProjectionResultProvider(
    String? memberId,
  ) : this._internal(
          (ref) => projectionResult(
            ref as ProjectionResultRef,
            memberId,
          ),
          from: projectionResultProvider,
          name: r'projectionResultProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$projectionResultHash,
          dependencies: ProjectionResultFamily._dependencies,
          allTransitiveDependencies:
              ProjectionResultFamily._allTransitiveDependencies,
          memberId: memberId,
        );

  ProjectionResultProvider._internal(
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
    FutureOr<ProjectionResult> Function(ProjectionResultRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProjectionResultProvider._internal(
        (ref) => create(ref as ProjectionResultRef),
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
  AutoDisposeFutureProviderElement<ProjectionResult> createElement() {
    return _ProjectionResultProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectionResultProvider && other.memberId == memberId;
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
mixin ProjectionResultRef on AutoDisposeFutureProviderRef<ProjectionResult> {
  /// The parameter `memberId` of this provider.
  String? get memberId;
}

class _ProjectionResultProviderElement
    extends AutoDisposeFutureProviderElement<ProjectionResult>
    with ProjectionResultRef {
  _ProjectionResultProviderElement(super.provider);

  @override
  String? get memberId => (origin as ProjectionResultProvider).memberId;
}

String _$projectionHorizonNotifierHash() =>
    r'4b69b5d8b0314d3661c2371d831d78d1d0357d1c';

/// See also [ProjectionHorizonNotifier].
@ProviderFor(ProjectionHorizonNotifier)
final projectionHorizonNotifierProvider =
    AutoDisposeNotifierProvider<ProjectionHorizonNotifier, int>.internal(
  ProjectionHorizonNotifier.new,
  name: r'projectionHorizonNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$projectionHorizonNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProjectionHorizonNotifier = AutoDisposeNotifier<int>;
String _$projectionSipNotifierHash() =>
    r'9aaf28242f3ee4bb6541df181c266c981fcfeaa3';

/// See also [ProjectionSipNotifier].
@ProviderFor(ProjectionSipNotifier)
final projectionSipNotifierProvider =
    AutoDisposeNotifierProvider<ProjectionSipNotifier, double>.internal(
  ProjectionSipNotifier.new,
  name: r'projectionSipNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$projectionSipNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProjectionSipNotifier = AutoDisposeNotifier<double>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
