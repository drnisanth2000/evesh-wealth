// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rebalance_dismissal_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RebalanceDismissalModelImpl _$$RebalanceDismissalModelImplFromJson(
        Map<String, dynamic> json) =>
    _$RebalanceDismissalModelImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      familyId: json['family_id'] as String?,
      memberId: json['member_id'] as String?,
      suggestionHash: json['suggestion_hash'] as String,
      fromAmfiCode: (json['from_amfi_code'] as num?)?.toInt(),
      toAmfiCode: (json['to_amfi_code'] as num?)?.toInt(),
      driftPct: (json['drift_pct'] as num?)?.toDouble(),
      reason: json['reason'] as String?,
      dismissedAt: json['dismissed_at'] as String,
    );

Map<String, dynamic> _$$RebalanceDismissalModelImplToJson(
        _$RebalanceDismissalModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'family_id': instance.familyId,
      'member_id': instance.memberId,
      'suggestion_hash': instance.suggestionHash,
      'from_amfi_code': instance.fromAmfiCode,
      'to_amfi_code': instance.toAmfiCode,
      'drift_pct': instance.driftPct,
      'reason': instance.reason,
      'dismissed_at': instance.dismissedAt,
    };
