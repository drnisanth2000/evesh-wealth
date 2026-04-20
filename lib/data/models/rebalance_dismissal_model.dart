import 'package:freezed_annotation/freezed_annotation.dart';

part 'rebalance_dismissal_model.freezed.dart';
part 'rebalance_dismissal_model.g.dart';

@freezed
class RebalanceDismissalModel with _$RebalanceDismissalModel {
  const factory RebalanceDismissalModel({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'family_id') String? familyId,
    @JsonKey(name: 'member_id') String? memberId,
    @JsonKey(name: 'suggestion_hash') required String suggestionHash,
    @JsonKey(name: 'from_amfi_code') int? fromAmfiCode,
    @JsonKey(name: 'to_amfi_code') int? toAmfiCode,
    @JsonKey(name: 'drift_pct') double? driftPct,
    String? reason,
    @JsonKey(name: 'dismissed_at') required String dismissedAt,
  }) = _RebalanceDismissalModel;

  factory RebalanceDismissalModel.fromJson(Map<String, dynamic> json) =>
      _$RebalanceDismissalModelFromJson(json);
}
