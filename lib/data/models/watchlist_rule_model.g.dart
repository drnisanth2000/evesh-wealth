// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watchlist_rule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WatchlistRuleModelImpl _$$WatchlistRuleModelImplFromJson(
        Map<String, dynamic> json) =>
    _$WatchlistRuleModelImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      memberId: json['member_id'] as String?,
      amfiCode: (json['amfi_code'] as num?)?.toInt(),
      fundName: json['fund_name'] as String?,
      ruleType: json['rule_type'] as String,
      thresholdType: json['threshold_type'] as String,
      thresholdValue: (json['threshold_value'] as num).toDouble(),
      direction: json['direction'] as String? ?? 'below',
      assetClassKey: json['asset_class_key'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastTriggeredAt: json['last_triggered_at'] as String?,
      cooldownHours: (json['cooldown_hours'] as num?)?.toInt() ?? 24,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$WatchlistRuleModelImplToJson(
        _$WatchlistRuleModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'member_id': instance.memberId,
      'amfi_code': instance.amfiCode,
      'fund_name': instance.fundName,
      'rule_type': instance.ruleType,
      'threshold_type': instance.thresholdType,
      'threshold_value': instance.thresholdValue,
      'direction': instance.direction,
      'asset_class_key': instance.assetClassKey,
      'is_active': instance.isActive,
      'last_triggered_at': instance.lastTriggeredAt,
      'cooldown_hours': instance.cooldownHours,
      'note': instance.note,
      'created_at': instance.createdAt,
    };
