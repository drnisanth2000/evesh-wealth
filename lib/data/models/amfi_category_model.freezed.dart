// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'amfi_category_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AmfiCategoryModel _$AmfiCategoryModelFromJson(Map<String, dynamic> json) {
  return _AmfiCategoryModel.fromJson(json);
}

/// @nodoc
mixin _$AmfiCategoryModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'super_category')
  String get superCategory => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'sebi_definition')
  String? get sebiDefinition => throw _privateConstructorUsedError;
  @JsonKey(name: 'match_patterns')
  List<String> get matchPatterns => throw _privateConstructorUsedError;
  @JsonKey(name: 'tier1_benchmark')
  String? get tier1Benchmark => throw _privateConstructorUsedError;
  @JsonKey(name: 'tier2_benchmark')
  String? get tier2Benchmark => throw _privateConstructorUsedError;
  @JsonKey(name: 'default_term')
  String get defaultTerm => throw _privateConstructorUsedError;
  @JsonKey(name: 'default_asset_class')
  String get defaultAssetClass => throw _privateConstructorUsedError;
  @JsonKey(name: 'default_tax_category')
  String get defaultTaxCategory => throw _privateConstructorUsedError;

  /// Serializes this AmfiCategoryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AmfiCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AmfiCategoryModelCopyWith<AmfiCategoryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AmfiCategoryModelCopyWith<$Res> {
  factory $AmfiCategoryModelCopyWith(
          AmfiCategoryModel value, $Res Function(AmfiCategoryModel) then) =
      _$AmfiCategoryModelCopyWithImpl<$Res, AmfiCategoryModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'super_category') String superCategory,
      String name,
      @JsonKey(name: 'sebi_definition') String? sebiDefinition,
      @JsonKey(name: 'match_patterns') List<String> matchPatterns,
      @JsonKey(name: 'tier1_benchmark') String? tier1Benchmark,
      @JsonKey(name: 'tier2_benchmark') String? tier2Benchmark,
      @JsonKey(name: 'default_term') String defaultTerm,
      @JsonKey(name: 'default_asset_class') String defaultAssetClass,
      @JsonKey(name: 'default_tax_category') String defaultTaxCategory});
}

/// @nodoc
class _$AmfiCategoryModelCopyWithImpl<$Res, $Val extends AmfiCategoryModel>
    implements $AmfiCategoryModelCopyWith<$Res> {
  _$AmfiCategoryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AmfiCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? superCategory = null,
    Object? name = null,
    Object? sebiDefinition = freezed,
    Object? matchPatterns = null,
    Object? tier1Benchmark = freezed,
    Object? tier2Benchmark = freezed,
    Object? defaultTerm = null,
    Object? defaultAssetClass = null,
    Object? defaultTaxCategory = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      superCategory: null == superCategory
          ? _value.superCategory
          : superCategory // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sebiDefinition: freezed == sebiDefinition
          ? _value.sebiDefinition
          : sebiDefinition // ignore: cast_nullable_to_non_nullable
              as String?,
      matchPatterns: null == matchPatterns
          ? _value.matchPatterns
          : matchPatterns // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tier1Benchmark: freezed == tier1Benchmark
          ? _value.tier1Benchmark
          : tier1Benchmark // ignore: cast_nullable_to_non_nullable
              as String?,
      tier2Benchmark: freezed == tier2Benchmark
          ? _value.tier2Benchmark
          : tier2Benchmark // ignore: cast_nullable_to_non_nullable
              as String?,
      defaultTerm: null == defaultTerm
          ? _value.defaultTerm
          : defaultTerm // ignore: cast_nullable_to_non_nullable
              as String,
      defaultAssetClass: null == defaultAssetClass
          ? _value.defaultAssetClass
          : defaultAssetClass // ignore: cast_nullable_to_non_nullable
              as String,
      defaultTaxCategory: null == defaultTaxCategory
          ? _value.defaultTaxCategory
          : defaultTaxCategory // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AmfiCategoryModelImplCopyWith<$Res>
    implements $AmfiCategoryModelCopyWith<$Res> {
  factory _$$AmfiCategoryModelImplCopyWith(_$AmfiCategoryModelImpl value,
          $Res Function(_$AmfiCategoryModelImpl) then) =
      __$$AmfiCategoryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'super_category') String superCategory,
      String name,
      @JsonKey(name: 'sebi_definition') String? sebiDefinition,
      @JsonKey(name: 'match_patterns') List<String> matchPatterns,
      @JsonKey(name: 'tier1_benchmark') String? tier1Benchmark,
      @JsonKey(name: 'tier2_benchmark') String? tier2Benchmark,
      @JsonKey(name: 'default_term') String defaultTerm,
      @JsonKey(name: 'default_asset_class') String defaultAssetClass,
      @JsonKey(name: 'default_tax_category') String defaultTaxCategory});
}

/// @nodoc
class __$$AmfiCategoryModelImplCopyWithImpl<$Res>
    extends _$AmfiCategoryModelCopyWithImpl<$Res, _$AmfiCategoryModelImpl>
    implements _$$AmfiCategoryModelImplCopyWith<$Res> {
  __$$AmfiCategoryModelImplCopyWithImpl(_$AmfiCategoryModelImpl _value,
      $Res Function(_$AmfiCategoryModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AmfiCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? superCategory = null,
    Object? name = null,
    Object? sebiDefinition = freezed,
    Object? matchPatterns = null,
    Object? tier1Benchmark = freezed,
    Object? tier2Benchmark = freezed,
    Object? defaultTerm = null,
    Object? defaultAssetClass = null,
    Object? defaultTaxCategory = null,
  }) {
    return _then(_$AmfiCategoryModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      superCategory: null == superCategory
          ? _value.superCategory
          : superCategory // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sebiDefinition: freezed == sebiDefinition
          ? _value.sebiDefinition
          : sebiDefinition // ignore: cast_nullable_to_non_nullable
              as String?,
      matchPatterns: null == matchPatterns
          ? _value._matchPatterns
          : matchPatterns // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tier1Benchmark: freezed == tier1Benchmark
          ? _value.tier1Benchmark
          : tier1Benchmark // ignore: cast_nullable_to_non_nullable
              as String?,
      tier2Benchmark: freezed == tier2Benchmark
          ? _value.tier2Benchmark
          : tier2Benchmark // ignore: cast_nullable_to_non_nullable
              as String?,
      defaultTerm: null == defaultTerm
          ? _value.defaultTerm
          : defaultTerm // ignore: cast_nullable_to_non_nullable
              as String,
      defaultAssetClass: null == defaultAssetClass
          ? _value.defaultAssetClass
          : defaultAssetClass // ignore: cast_nullable_to_non_nullable
              as String,
      defaultTaxCategory: null == defaultTaxCategory
          ? _value.defaultTaxCategory
          : defaultTaxCategory // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AmfiCategoryModelImpl implements _AmfiCategoryModel {
  const _$AmfiCategoryModelImpl(
      {required this.id,
      @JsonKey(name: 'super_category') required this.superCategory,
      required this.name,
      @JsonKey(name: 'sebi_definition') this.sebiDefinition,
      @JsonKey(name: 'match_patterns')
      final List<String> matchPatterns = const <String>[],
      @JsonKey(name: 'tier1_benchmark') this.tier1Benchmark,
      @JsonKey(name: 'tier2_benchmark') this.tier2Benchmark,
      @JsonKey(name: 'default_term') required this.defaultTerm,
      @JsonKey(name: 'default_asset_class') required this.defaultAssetClass,
      @JsonKey(name: 'default_tax_category') required this.defaultTaxCategory})
      : _matchPatterns = matchPatterns;

  factory _$AmfiCategoryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AmfiCategoryModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'super_category')
  final String superCategory;
  @override
  final String name;
  @override
  @JsonKey(name: 'sebi_definition')
  final String? sebiDefinition;
  final List<String> _matchPatterns;
  @override
  @JsonKey(name: 'match_patterns')
  List<String> get matchPatterns {
    if (_matchPatterns is EqualUnmodifiableListView) return _matchPatterns;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_matchPatterns);
  }

  @override
  @JsonKey(name: 'tier1_benchmark')
  final String? tier1Benchmark;
  @override
  @JsonKey(name: 'tier2_benchmark')
  final String? tier2Benchmark;
  @override
  @JsonKey(name: 'default_term')
  final String defaultTerm;
  @override
  @JsonKey(name: 'default_asset_class')
  final String defaultAssetClass;
  @override
  @JsonKey(name: 'default_tax_category')
  final String defaultTaxCategory;

  @override
  String toString() {
    return 'AmfiCategoryModel(id: $id, superCategory: $superCategory, name: $name, sebiDefinition: $sebiDefinition, matchPatterns: $matchPatterns, tier1Benchmark: $tier1Benchmark, tier2Benchmark: $tier2Benchmark, defaultTerm: $defaultTerm, defaultAssetClass: $defaultAssetClass, defaultTaxCategory: $defaultTaxCategory)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AmfiCategoryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.superCategory, superCategory) ||
                other.superCategory == superCategory) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.sebiDefinition, sebiDefinition) ||
                other.sebiDefinition == sebiDefinition) &&
            const DeepCollectionEquality()
                .equals(other._matchPatterns, _matchPatterns) &&
            (identical(other.tier1Benchmark, tier1Benchmark) ||
                other.tier1Benchmark == tier1Benchmark) &&
            (identical(other.tier2Benchmark, tier2Benchmark) ||
                other.tier2Benchmark == tier2Benchmark) &&
            (identical(other.defaultTerm, defaultTerm) ||
                other.defaultTerm == defaultTerm) &&
            (identical(other.defaultAssetClass, defaultAssetClass) ||
                other.defaultAssetClass == defaultAssetClass) &&
            (identical(other.defaultTaxCategory, defaultTaxCategory) ||
                other.defaultTaxCategory == defaultTaxCategory));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      superCategory,
      name,
      sebiDefinition,
      const DeepCollectionEquality().hash(_matchPatterns),
      tier1Benchmark,
      tier2Benchmark,
      defaultTerm,
      defaultAssetClass,
      defaultTaxCategory);

  /// Create a copy of AmfiCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AmfiCategoryModelImplCopyWith<_$AmfiCategoryModelImpl> get copyWith =>
      __$$AmfiCategoryModelImplCopyWithImpl<_$AmfiCategoryModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AmfiCategoryModelImplToJson(
      this,
    );
  }
}

abstract class _AmfiCategoryModel implements AmfiCategoryModel {
  const factory _AmfiCategoryModel(
      {required final String id,
      @JsonKey(name: 'super_category') required final String superCategory,
      required final String name,
      @JsonKey(name: 'sebi_definition') final String? sebiDefinition,
      @JsonKey(name: 'match_patterns') final List<String> matchPatterns,
      @JsonKey(name: 'tier1_benchmark') final String? tier1Benchmark,
      @JsonKey(name: 'tier2_benchmark') final String? tier2Benchmark,
      @JsonKey(name: 'default_term') required final String defaultTerm,
      @JsonKey(name: 'default_asset_class')
      required final String defaultAssetClass,
      @JsonKey(name: 'default_tax_category')
      required final String defaultTaxCategory}) = _$AmfiCategoryModelImpl;

  factory _AmfiCategoryModel.fromJson(Map<String, dynamic> json) =
      _$AmfiCategoryModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'super_category')
  String get superCategory;
  @override
  String get name;
  @override
  @JsonKey(name: 'sebi_definition')
  String? get sebiDefinition;
  @override
  @JsonKey(name: 'match_patterns')
  List<String> get matchPatterns;
  @override
  @JsonKey(name: 'tier1_benchmark')
  String? get tier1Benchmark;
  @override
  @JsonKey(name: 'tier2_benchmark')
  String? get tier2Benchmark;
  @override
  @JsonKey(name: 'default_term')
  String get defaultTerm;
  @override
  @JsonKey(name: 'default_asset_class')
  String get defaultAssetClass;
  @override
  @JsonKey(name: 'default_tax_category')
  String get defaultTaxCategory;

  /// Create a copy of AmfiCategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AmfiCategoryModelImplCopyWith<_$AmfiCategoryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
