// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deployment_plan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DeploymentPlanModelImpl _$$DeploymentPlanModelImplFromJson(
        Map<String, dynamic> json) =>
    _$DeploymentPlanModelImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      familyId: json['family_id'] as String?,
      memberId: json['member_id'] as String?,
      lumpsumRupees: (json['lumpsum_rupees'] as num?)?.toDouble() ?? 0.0,
      sipRupees: (json['sip_rupees'] as num?)?.toDouble() ?? 0.0,
      splitPct: (json['split_pct'] as num?)?.toDouble() ?? 30.0,
      planJson: json['plan_jsonb'] as Map<String, dynamic>,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      executedAt: json['executed_at'] as String?,
    );

Map<String, dynamic> _$$DeploymentPlanModelImplToJson(
        _$DeploymentPlanModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'family_id': instance.familyId,
      'member_id': instance.memberId,
      'lumpsum_rupees': instance.lumpsumRupees,
      'sip_rupees': instance.sipRupees,
      'split_pct': instance.splitPct,
      'plan_jsonb': instance.planJson,
      'notes': instance.notes,
      'created_at': instance.createdAt,
      'executed_at': instance.executedAt,
    };
