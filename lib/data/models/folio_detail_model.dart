import 'package:freezed_annotation/freezed_annotation.dart';

part 'folio_detail_model.freezed.dart';
part 'folio_detail_model.g.dart';

@freezed
class FolioDetailModel with _$FolioDetailModel {
  const factory FolioDetailModel({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'member_id') String? memberId,
    @JsonKey(name: 'folio_number') required String folioNumber,
    @JsonKey(name: 'amc_name') String? amcName,
    @JsonKey(name: 'scheme_name') String? schemeName,
    String? isin,
    String? pan,
    @JsonKey(name: 'kyc_status') String? kycStatus,
    @JsonKey(name: 'pan_status') String? panStatus,
    @JsonKey(name: 'investor_name') String? investorName,
    String? registrar,
    @JsonKey(name: 'advisor_code') String? advisorCode,
    @JsonKey(name: 'demat_status') String? dematStatus,
    @JsonKey(name: 'nominee_1') String? nominee1,
    @JsonKey(name: 'nominee_2') String? nominee2,
    @JsonKey(name: 'nominee_3') String? nominee3,
    @JsonKey(name: 'closing_units') double? closingUnits,
    @JsonKey(name: 'closing_nav') double? closingNav,
    @JsonKey(name: 'closing_nav_date') String? closingNavDate,
    @JsonKey(name: 'total_cost_value') double? totalCostValue,
    @JsonKey(name: 'market_value') double? marketValue,
    @JsonKey(name: 'exit_load_text') String? exitLoadText,
    @JsonKey(name: 'exit_load_days') int? exitLoadDays,
    @JsonKey(name: 'exit_load_pct') double? exitLoadPct,
    @JsonKey(name: 'exit_load_free_pct') @Default(0) double exitLoadFreePct,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _FolioDetailModel;

  factory FolioDetailModel.fromJson(Map<String, dynamic> json) =>
      _$FolioDetailModelFromJson(json);
}
