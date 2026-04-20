// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_alert_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FundAlertModelImpl _$$FundAlertModelImplFromJson(Map<String, dynamic> json) =>
    _$FundAlertModelImpl(
      id: json['id'] as String,
      amfiCode: (json['amfi_code'] as num).toInt(),
      alertType: json['alert_type'] as String,
      oldValue: json['old_value'] as String?,
      newValue: json['new_value'] as String?,
      detectedAt: json['detected_at'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$FundAlertModelImplToJson(
        _$FundAlertModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amfi_code': instance.amfiCode,
      'alert_type': instance.alertType,
      'old_value': instance.oldValue,
      'new_value': instance.newValue,
      'detected_at': instance.detectedAt,
      'metadata': instance.metadata,
      'created_at': instance.createdAt,
    };
