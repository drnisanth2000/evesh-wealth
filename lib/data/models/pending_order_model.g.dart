// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PendingOrderModelImpl _$$PendingOrderModelImplFromJson(
        Map<String, dynamic> json) =>
    _$PendingOrderModelImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      familyId: json['family_id'] as String?,
      memberId: json['member_id'] as String?,
      amfiCode: (json['amfi_code'] as num?)?.toInt(),
      fundName: json['fund_name'] as String,
      assetType: json['asset_type'] as String? ?? 'MF',
      orderKind: json['order_kind'] as String,
      switchToAmfi: (json['switch_to_amfi'] as num?)?.toInt(),
      amount: (json['amount'] as num?)?.toDouble(),
      units: (json['units'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'placed',
      source: json['source'] as String? ?? 'manual',
      sourceRef: json['source_ref'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      executedAt: json['executed_at'] as String?,
    );

Map<String, dynamic> _$$PendingOrderModelImplToJson(
        _$PendingOrderModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'family_id': instance.familyId,
      'member_id': instance.memberId,
      'amfi_code': instance.amfiCode,
      'fund_name': instance.fundName,
      'asset_type': instance.assetType,
      'order_kind': instance.orderKind,
      'switch_to_amfi': instance.switchToAmfi,
      'amount': instance.amount,
      'units': instance.units,
      'status': instance.status,
      'source': instance.source,
      'source_ref': instance.sourceRef,
      'notes': instance.notes,
      'created_at': instance.createdAt,
      'executed_at': instance.executedAt,
    };
