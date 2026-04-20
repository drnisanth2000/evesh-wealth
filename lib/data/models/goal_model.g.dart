// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GoalModelImpl _$$GoalModelImplFromJson(Map<String, dynamic> json) =>
    _$GoalModelImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      familyId: json['family_id'] as String,
      memberId: json['member_id'] as String?,
      goalName: json['goal_name'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      targetDate: json['target_date'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$$GoalModelImplToJson(_$GoalModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'family_id': instance.familyId,
      'member_id': instance.memberId,
      'goal_name': instance.goalName,
      'target_amount': instance.targetAmount,
      'target_date': instance.targetDate,
      'notes': instance.notes,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

_$GoalFundLinkImpl _$$GoalFundLinkImplFromJson(Map<String, dynamic> json) =>
    _$GoalFundLinkImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      goalId: json['goal_id'] as String,
      amfiCode: (json['amfi_code'] as num).toInt(),
      allocationPct: (json['allocation_pct'] as num?)?.toDouble() ?? 100.0,
    );

Map<String, dynamic> _$$GoalFundLinkImplToJson(_$GoalFundLinkImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'goal_id': instance.goalId,
      'amfi_code': instance.amfiCode,
      'allocation_pct': instance.allocationPct,
    };
