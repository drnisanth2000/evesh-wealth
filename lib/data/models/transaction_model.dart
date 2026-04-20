import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

@freezed
class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'family_id') String? familyId,
    @JsonKey(name: 'member_id') String? memberId,
    @JsonKey(name: 'amfi_code') int? amfiCode,
    String? isin,
    String? symbol,
    @JsonKey(name: 'asset_type') required String assetType,
    @JsonKey(name: 'asset_name') String? assetName,
    @JsonKey(name: 'tx_date') required String txDate,
    @JsonKey(name: 'tx_type') required String txType,
    double? units,
    @JsonKey(name: 'nav_at_tx') double? navAtTx,
    required double amount,
    @JsonKey(name: 'folio_number') String? folioNumber,
    String? broker,
    String? notes,
    @JsonKey(name: 'target_amount') double? targetAmount,
    @JsonKey(name: 'stoploss_amount') double? stoplossAmount,
    @JsonKey(name: 'current_value') double? currentValue,
    @JsonKey(name: 'dedup_hash') String? dedupHash,
    @JsonKey(name: 'stamp_duty') @Default(0) double stampDuty,
    @JsonKey(name: 'stt_amount') @Default(0) double sttAmount,
    @JsonKey(name: 'import_source') @Default('manual') String importSource,
    @JsonKey(name: 'created_at') String? createdAt,
    // Joined from fund_master (optional)
    @JsonKey(name: 'fund_master') FundJoin? fundMaster,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  const TransactionModel._();

  DateTime get parsedDate => DateTime.parse(txDate);
  bool get isPurchase =>
      ['BUY', 'SIP', 'Switch-In', 'STX-BUY', 'STP-In', 'Bonus', 'IDCW', 'IDCW-Reinvest', 'Transfer-In', 'Opening Balance'].contains(txType);
  bool get isRedemption =>
      ['SELL', 'Switch-Out', 'STP-Out', 'SWP', 'STX-SELL', 'Transfer-Out'].contains(txType);
  bool get isCashOnly => txType == 'IDCW-Payout';
}

@freezed
class FundJoin with _$FundJoin {
  const factory FundJoin({
    @JsonKey(name: 'fund_name') required String fundName,
    String? category,
    @JsonKey(name: 'tax_category') String? taxCategory,
    @JsonKey(name: 'latest_nav') double? latestNav,
    @JsonKey(name: 'fund_managers') List<String>? fundManagers,
    @JsonKey(name: 'crisil_rating') String? crisilRating,
    @JsonKey(name: 'jan_31_nav') double? jan31Nav,
    @JsonKey(name: 'tax_period') int? taxPeriod,
    @JsonKey(name: 'exit_load') String? exitLoad,
    @JsonKey(name: 'plan_type') String? planType,
    @JsonKey(name: 'expense_ratio') double? expenseRatio,
    @JsonKey(name: 'return_1y') double? return1y,
    @JsonKey(name: 'amfi_category_id') String? amfiCategoryId,
    @JsonKey(name: 'benchmark_tier1') String? benchmarkTier1,
    @JsonKey(name: 'benchmark_tier2') String? benchmarkTier2,
  }) = _FundJoin;

  factory FundJoin.fromJson(Map<String, dynamic> json) =>
      _$FundJoinFromJson(json);
}
