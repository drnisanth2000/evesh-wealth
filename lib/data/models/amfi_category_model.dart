import 'package:freezed_annotation/freezed_annotation.dart';

part 'amfi_category_model.freezed.dart';
part 'amfi_category_model.g.dart';

/// Mirror of the `amfi_category` Postgres row.
///
/// Source of truth for the SEBI 2018 scheme categorisation. Used by goal-term
/// classification, asset-class derivation, and benchmark comparison charts.
@freezed
class AmfiCategoryModel with _$AmfiCategoryModel {
  const factory AmfiCategoryModel({
    required String id,
    @JsonKey(name: 'super_category') required String superCategory,
    required String name,
    @JsonKey(name: 'sebi_definition') String? sebiDefinition,
    @JsonKey(name: 'match_patterns') @Default(<String>[]) List<String> matchPatterns,
    @JsonKey(name: 'tier1_benchmark') String? tier1Benchmark,
    @JsonKey(name: 'tier2_benchmark') String? tier2Benchmark,
    @JsonKey(name: 'default_term') required String defaultTerm,
    @JsonKey(name: 'default_asset_class') required String defaultAssetClass,
    @JsonKey(name: 'default_tax_category') required String defaultTaxCategory,
  }) = _AmfiCategoryModel;

  factory AmfiCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$AmfiCategoryModelFromJson(json);
}
