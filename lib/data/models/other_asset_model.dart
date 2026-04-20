import 'package:freezed_annotation/freezed_annotation.dart';

part 'other_asset_model.freezed.dart';
part 'other_asset_model.g.dart';

@freezed
class OtherAssetModel with _$OtherAssetModel {
  const factory OtherAssetModel({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'family_id') String? familyId,
    @JsonKey(name: 'member_id') String? memberId,
    @JsonKey(name: 'asset_type') required String assetType,
    required String description,
    @JsonKey(name: 'isin_symbol') String? isinSymbol,
    double? quantity,
    @JsonKey(name: 'cost_value') double? costValue,
    @JsonKey(name: 'current_value') double? currentValue,
    @JsonKey(name: 'current_price') double? currentPrice,
    @JsonKey(name: 'interest_rate') double? interestRate,
    @JsonKey(name: 'interest_frequency') String? interestFrequency,
    @JsonKey(name: 'accrued_interest') double? accruedInterest,
    @JsonKey(name: 'tax_category') String? taxCategory,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'maturity_date') String? maturityDate,
    @JsonKey(name: 'lock_in_end_date') String? lockInEndDate,
    @JsonKey(name: 'last_valuation_date') String? lastValuationDate,
    @JsonKey(name: 'broker_or_institution') String? brokerOrInstitution,
    @JsonKey(name: 'account_number') String? accountNumber,
    String? notes,
    @JsonKey(name: 'bucket_override') String? bucketOverride,
    @JsonKey(name: 'last_updated_at') String? lastUpdatedAt,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _OtherAssetModel;

  factory OtherAssetModel.fromJson(Map<String, dynamic> json) =>
      _$OtherAssetModelFromJson(json);
}

extension OtherAssetBucket on OtherAssetModel {
  /// Effective rupee value — prefer `currentValue`, then `quantity * currentPrice`,
  /// then `costValue`, then 0. The bucket composition provider relies on this
  /// single source of truth so stale/partial rows don't skew the 3-bucket view.
  double get effectiveValue {
    if (currentValue != null) return currentValue!;
    if (quantity != null && currentPrice != null) {
      return quantity! * currentPrice!;
    }
    return costValue ?? 0.0;
  }
}
