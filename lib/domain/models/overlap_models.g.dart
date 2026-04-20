// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overlap_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CachedFundHoldingImpl _$$CachedFundHoldingImplFromJson(
        Map<String, dynamic> json) =>
    _$CachedFundHoldingImpl(
      amfiCode: (json['amfiCode'] as num).toInt(),
      companyName: json['companyName'] as String,
      sectorName: json['sectorName'] as String?,
      corpusPct: (json['corpusPct'] as num).toDouble(),
      instrumentName: json['instrumentName'] as String?,
      natureName: json['natureName'] as String?,
      rating: json['rating'] as String?,
      marketValue: (json['marketValue'] as num?)?.toDouble(),
      fetchedAt: json['fetchedAt'] as String,
    );

Map<String, dynamic> _$$CachedFundHoldingImplToJson(
        _$CachedFundHoldingImpl instance) =>
    <String, dynamic>{
      'amfiCode': instance.amfiCode,
      'companyName': instance.companyName,
      'sectorName': instance.sectorName,
      'corpusPct': instance.corpusPct,
      'instrumentName': instance.instrumentName,
      'natureName': instance.natureName,
      'rating': instance.rating,
      'marketValue': instance.marketValue,
      'fetchedAt': instance.fetchedAt,
    };
