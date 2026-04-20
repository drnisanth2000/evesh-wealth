// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_matrix_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$decisionMatrixHash() => r'6e46f49341c941ea40dc5c66122109e6e4c512c3';

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

/// Computes the post-tax decision matrix for given input parameters.
///
/// Copied from [decisionMatrix].
@ProviderFor(decisionMatrix)
const decisionMatrixProvider = DecisionMatrixFamily();

/// Computes the post-tax decision matrix for given input parameters.
///
/// Copied from [decisionMatrix].
class DecisionMatrixFamily extends Family<DecisionMatrixResult> {
  /// Computes the post-tax decision matrix for given input parameters.
  ///
  /// Copied from [decisionMatrix].
  const DecisionMatrixFamily();

  /// Computes the post-tax decision matrix for given input parameters.
  ///
  /// Copied from [decisionMatrix].
  DecisionMatrixProvider call(
    DecisionMatrixInput input,
  ) {
    return DecisionMatrixProvider(
      input,
    );
  }

  @override
  DecisionMatrixProvider getProviderOverride(
    covariant DecisionMatrixProvider provider,
  ) {
    return call(
      provider.input,
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
  String? get name => r'decisionMatrixProvider';
}

/// Computes the post-tax decision matrix for given input parameters.
///
/// Copied from [decisionMatrix].
class DecisionMatrixProvider extends AutoDisposeProvider<DecisionMatrixResult> {
  /// Computes the post-tax decision matrix for given input parameters.
  ///
  /// Copied from [decisionMatrix].
  DecisionMatrixProvider(
    DecisionMatrixInput input,
  ) : this._internal(
          (ref) => decisionMatrix(
            ref as DecisionMatrixRef,
            input,
          ),
          from: decisionMatrixProvider,
          name: r'decisionMatrixProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$decisionMatrixHash,
          dependencies: DecisionMatrixFamily._dependencies,
          allTransitiveDependencies:
              DecisionMatrixFamily._allTransitiveDependencies,
          input: input,
        );

  DecisionMatrixProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.input,
  }) : super.internal();

  final DecisionMatrixInput input;

  @override
  Override overrideWith(
    DecisionMatrixResult Function(DecisionMatrixRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DecisionMatrixProvider._internal(
        (ref) => create(ref as DecisionMatrixRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        input: input,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<DecisionMatrixResult> createElement() {
    return _DecisionMatrixProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DecisionMatrixProvider && other.input == input;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, input.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DecisionMatrixRef on AutoDisposeProviderRef<DecisionMatrixResult> {
  /// The parameter `input` of this provider.
  DecisionMatrixInput get input;
}

class _DecisionMatrixProviderElement
    extends AutoDisposeProviderElement<DecisionMatrixResult>
    with DecisionMatrixRef {
  _DecisionMatrixProviderElement(super.provider);

  @override
  DecisionMatrixInput get input => (origin as DecisionMatrixProvider).input;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
