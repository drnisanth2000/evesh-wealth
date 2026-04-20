// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionModelImpl _$$TransactionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$TransactionModelImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      familyId: json['family_id'] as String?,
      memberId: json['member_id'] as String?,
      amfiCode: (json['amfi_code'] as num?)?.toInt(),
      isin: json['isin'] as String?,
      symbol: json['symbol'] as String?,
      assetType: json['asset_type'] as String,
      assetName: json['asset_name'] as String?,
      txDate: json['tx_date'] as String,
      txType: json['tx_type'] as String,
      units: (json['units'] as num?)?.toDouble(),
      navAtTx: (json['nav_at_tx'] as num?)?.toDouble(),
      amount: (json['amount'] as num).toDouble(),
      folioNumber: json['folio_number'] as String?,
      broker: json['broker'] as String?,
      notes: json['notes'] as String?,
      targetAmount: (json['target_amount'] as num?)?.toDouble(),
      stoplossAmount: (json['stoploss_amount'] as num?)?.toDouble(),
      currentValue: (json['current_value'] as num?)?.toDouble(),
      dedupHash: json['dedup_hash'] as String?,
      stampDuty: (json['stamp_duty'] as num?)?.toDouble() ?? 0,
      sttAmount: (json['stt_amount'] as num?)?.toDouble() ?? 0,
      importSource: json['import_source'] as String? ?? 'manual',
      createdAt: json['created_at'] as String?,
      fundMaster: json['fund_master'] == null
          ? null
          : FundJoin.fromJson(json['fund_master'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$TransactionModelImplToJson(
        _$TransactionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'family_id': instance.familyId,
      'member_id': instance.memberId,
      'amfi_code': instance.amfiCode,
      'isin': instance.isin,
      'symbol': instance.symbol,
      'asset_type': instance.assetType,
      'asset_name': instance.assetName,
      'tx_date': instance.txDate,
      'tx_type': instance.txType,
      'units': instance.units,
      'nav_at_tx': instance.navAtTx,
      'amount': instance.amount,
      'folio_number': instance.folioNumber,
      'broker': instance.broker,
      'notes': instance.notes,
      'target_amount': instance.targetAmount,
      'stoploss_amount': instance.stoplossAmount,
      'current_value': instance.currentValue,
      'dedup_hash': instance.dedupHash,
      'stamp_duty': instance.stampDuty,
      'stt_amount': instance.sttAmount,
      'import_source': instance.importSource,
      'created_at': instance.createdAt,
      'fund_master': instance.fundMaster,
    };

_$FundJoinImpl _$$FundJoinImplFromJson(Map<String, dynamic> json) =>
    _$FundJoinImpl(
      fundName: json['fund_name'] as String,
      category: json['category'] as String?,
      taxCategory: json['tax_category'] as String?,
      latestNav: (json['latest_nav'] as num?)?.toDouble(),
      fundManagers: (json['fund_managers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      crisilRating: json['crisil_rating'] as String?,
      jan31Nav: (json['jan_31_nav'] as num?)?.toDouble(),
      taxPeriod: (json['tax_period'] as num?)?.toInt(),
      exitLoad: json['exit_load'] as String?,
      planType: json['plan_type'] as String?,
      expenseRatio: (json['expense_ratio'] as num?)?.toDouble(),
      return1y: (json['return_1y'] as num?)?.toDouble(),
      amfiCategoryId: json['amfi_category_id'] as String?,
      benchmarkTier1: json['benchmark_tier1'] as String?,
      benchmarkTier2: json['benchmark_tier2'] as String?,
    );

Map<String, dynamic> _$$FundJoinImplToJson(_$FundJoinImpl instance) =>
    <String, dynamic>{
      'fund_name': instance.fundName,
      'category': instance.category,
      'tax_category': instance.taxCategory,
      'latest_nav': instance.latestNav,
      'fund_managers': instance.fundManagers,
      'crisil_rating': instance.crisilRating,
      'jan_31_nav': instance.jan31Nav,
      'tax_period': instance.taxPeriod,
      'exit_load': instance.exitLoad,
      'plan_type': instance.planType,
      'expense_ratio': instance.expenseRatio,
      'return_1y': instance.return1y,
      'amfi_category_id': instance.amfiCategoryId,
      'benchmark_tier1': instance.benchmarkTier1,
      'benchmark_tier2': instance.benchmarkTier2,
    };
