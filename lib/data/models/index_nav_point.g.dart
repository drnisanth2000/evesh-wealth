// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index_nav_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IndexNavPointImpl _$$IndexNavPointImplFromJson(Map<String, dynamic> json) =>
    _$IndexNavPointImpl(
      indexName: json['index_name'] as String,
      navDate: DateTime.parse(json['nav_date'] as String),
      nav: (json['nav'] as num).toDouble(),
    );

Map<String, dynamic> _$$IndexNavPointImplToJson(_$IndexNavPointImpl instance) =>
    <String, dynamic>{
      'index_name': instance.indexName,
      'nav_date': instance.navDate.toIso8601String(),
      'nav': instance.nav,
    };
