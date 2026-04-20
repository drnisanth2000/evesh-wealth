// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'other_asset_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OtherAssetModelImpl _$$OtherAssetModelImplFromJson(
        Map<String, dynamic> json) =>
    _$OtherAssetModelImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      familyId: json['family_id'] as String?,
      memberId: json['member_id'] as String?,
      assetType: json['asset_type'] as String,
      description: json['description'] as String,
      isinSymbol: json['isin_symbol'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      costValue: (json['cost_value'] as num?)?.toDouble(),
      currentValue: (json['current_value'] as num?)?.toDouble(),
      currentPrice: (json['current_price'] as num?)?.toDouble(),
      interestRate: (json['interest_rate'] as num?)?.toDouble(),
      interestFrequency: json['interest_frequency'] as String?,
      accruedInterest: (json['accrued_interest'] as num?)?.toDouble(),
      taxCategory: json['tax_category'] as String?,
      startDate: json['start_date'] as String?,
      maturityDate: json['maturity_date'] as String?,
      lockInEndDate: json['lock_in_end_date'] as String?,
      lastValuationDate: json['last_valuation_date'] as String?,
      brokerOrInstitution: json['broker_or_institution'] as String?,
      accountNumber: json['account_number'] as String?,
      notes: json['notes'] as String?,
      bucketOverride: json['bucket_override'] as String?,
      lastUpdatedAt: json['last_updated_at'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$$OtherAssetModelImplToJson(
        _$OtherAssetModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'family_id': instance.familyId,
      'member_id': instance.memberId,
      'asset_type': instance.assetType,
      'description': instance.description,
      'isin_symbol': instance.isinSymbol,
      'quantity': instance.quantity,
      'cost_value': instance.costValue,
      'current_value': instance.currentValue,
      'current_price': instance.currentPrice,
      'interest_rate': instance.interestRate,
      'interest_frequency': instance.interestFrequency,
      'accrued_interest': instance.accruedInterest,
      'tax_category': instance.taxCategory,
      'start_date': instance.startDate,
      'maturity_date': instance.maturityDate,
      'lock_in_end_date': instance.lockInEndDate,
      'last_valuation_date': instance.lastValuationDate,
      'broker_or_institution': instance.brokerOrInstitution,
      'account_number': instance.accountNumber,
      'notes': instance.notes,
      'bucket_override': instance.bucketOverride,
      'last_updated_at': instance.lastUpdatedAt,
      'created_at': instance.createdAt,
    };
