// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folio_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FolioDetailModelImpl _$$FolioDetailModelImplFromJson(
        Map<String, dynamic> json) =>
    _$FolioDetailModelImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      memberId: json['member_id'] as String?,
      folioNumber: json['folio_number'] as String,
      amcName: json['amc_name'] as String?,
      schemeName: json['scheme_name'] as String?,
      isin: json['isin'] as String?,
      pan: json['pan'] as String?,
      kycStatus: json['kyc_status'] as String?,
      panStatus: json['pan_status'] as String?,
      investorName: json['investor_name'] as String?,
      registrar: json['registrar'] as String?,
      advisorCode: json['advisor_code'] as String?,
      dematStatus: json['demat_status'] as String?,
      nominee1: json['nominee_1'] as String?,
      nominee2: json['nominee_2'] as String?,
      nominee3: json['nominee_3'] as String?,
      closingUnits: (json['closing_units'] as num?)?.toDouble(),
      closingNav: (json['closing_nav'] as num?)?.toDouble(),
      closingNavDate: json['closing_nav_date'] as String?,
      totalCostValue: (json['total_cost_value'] as num?)?.toDouble(),
      marketValue: (json['market_value'] as num?)?.toDouble(),
      exitLoadText: json['exit_load_text'] as String?,
      exitLoadDays: (json['exit_load_days'] as num?)?.toInt(),
      exitLoadPct: (json['exit_load_pct'] as num?)?.toDouble(),
      exitLoadFreePct: (json['exit_load_free_pct'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$$FolioDetailModelImplToJson(
        _$FolioDetailModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'member_id': instance.memberId,
      'folio_number': instance.folioNumber,
      'amc_name': instance.amcName,
      'scheme_name': instance.schemeName,
      'isin': instance.isin,
      'pan': instance.pan,
      'kyc_status': instance.kycStatus,
      'pan_status': instance.panStatus,
      'investor_name': instance.investorName,
      'registrar': instance.registrar,
      'advisor_code': instance.advisorCode,
      'demat_status': instance.dematStatus,
      'nominee_1': instance.nominee1,
      'nominee_2': instance.nominee2,
      'nominee_3': instance.nominee3,
      'closing_units': instance.closingUnits,
      'closing_nav': instance.closingNav,
      'closing_nav_date': instance.closingNavDate,
      'total_cost_value': instance.totalCostValue,
      'market_value': instance.marketValue,
      'exit_load_text': instance.exitLoadText,
      'exit_load_days': instance.exitLoadDays,
      'exit_load_pct': instance.exitLoadPct,
      'exit_load_free_pct': instance.exitLoadFreePct,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
