import 'package:freezed_annotation/freezed_annotation.dart';

part 'deployment_plan_model.freezed.dart';
part 'deployment_plan_model.g.dart';

@freezed
class DeploymentPlanModel with _$DeploymentPlanModel {
  const factory DeploymentPlanModel({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'family_id') String? familyId,
    @JsonKey(name: 'member_id') String? memberId,
    @JsonKey(name: 'lumpsum_rupees') @Default(0.0) double lumpsumRupees,
    @JsonKey(name: 'sip_rupees') @Default(0.0) double sipRupees,
    @JsonKey(name: 'split_pct') @Default(30.0) double splitPct,
    @JsonKey(name: 'plan_jsonb') required Map<String, dynamic> planJson,
    String? notes,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'executed_at') String? executedAt,
  }) = _DeploymentPlanModel;

  factory DeploymentPlanModel.fromJson(Map<String, dynamic> json) =>
      _$DeploymentPlanModelFromJson(json);
}
