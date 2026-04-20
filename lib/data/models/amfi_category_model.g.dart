// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'amfi_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AmfiCategoryModelImpl _$$AmfiCategoryModelImplFromJson(
        Map<String, dynamic> json) =>
    _$AmfiCategoryModelImpl(
      id: json['id'] as String,
      superCategory: json['super_category'] as String,
      name: json['name'] as String,
      sebiDefinition: json['sebi_definition'] as String?,
      matchPatterns: (json['match_patterns'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      tier1Benchmark: json['tier1_benchmark'] as String?,
      tier2Benchmark: json['tier2_benchmark'] as String?,
      defaultTerm: json['default_term'] as String,
      defaultAssetClass: json['default_asset_class'] as String,
      defaultTaxCategory: json['default_tax_category'] as String,
    );

Map<String, dynamic> _$$AmfiCategoryModelImplToJson(
        _$AmfiCategoryModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'super_category': instance.superCategory,
      'name': instance.name,
      'sebi_definition': instance.sebiDefinition,
      'match_patterns': instance.matchPatterns,
      'tier1_benchmark': instance.tier1Benchmark,
      'tier2_benchmark': instance.tier2Benchmark,
      'default_term': instance.defaultTerm,
      'default_asset_class': instance.defaultAssetClass,
      'default_tax_category': instance.defaultTaxCategory,
    };
