import 'package:freezed_annotation/freezed_annotation.dart';

part 'watchlist_rule_model.freezed.dart';
part 'watchlist_rule_model.g.dart';

@freezed
class WatchlistRuleModel with _$WatchlistRuleModel {
  const factory WatchlistRuleModel({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'member_id') String? memberId,
    @JsonKey(name: 'amfi_code') int? amfiCode,
    @JsonKey(name: 'fund_name') String? fundName,
    @JsonKey(name: 'rule_type') required String ruleType,
    @JsonKey(name: 'threshold_type') required String thresholdType,
    @JsonKey(name: 'threshold_value') required double thresholdValue,
    @Default('below') String direction,
    @JsonKey(name: 'asset_class_key') String? assetClassKey,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'last_triggered_at') String? lastTriggeredAt,
    @JsonKey(name: 'cooldown_hours') @Default(24) int cooldownHours,
    String? note,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _WatchlistRuleModel;

  factory WatchlistRuleModel.fromJson(Map<String, dynamic> json) =>
      _$WatchlistRuleModelFromJson(json);

  const WatchlistRuleModel._();

  /// Human-readable rule description for display.
  String get description {
    switch (ruleType) {
      case 'stop_loss':
        if (thresholdType == 'nav') return 'NAV < ₹${thresholdValue.toStringAsFixed(2)}';
        if (thresholdType == 'amount') return 'Value < ₹${thresholdValue.round()}';
        return 'Drop > ${thresholdValue.toStringAsFixed(1)}%';
      case 'gain_harvest':
        if (thresholdType == 'nav') return 'NAV > ₹${thresholdValue.toStringAsFixed(2)}';
        if (thresholdType == 'amount') return 'Value > ₹${thresholdValue.round()}';
        return 'Gain > ${thresholdValue.toStringAsFixed(1)}%';
      case 'price_target':
        return 'NAV target ₹${thresholdValue.toStringAsFixed(2)}';
      case 'allocation_drift':
        return 'Drift > ${thresholdValue.toStringAsFixed(1)}%';
      default:
        return '$thresholdType $direction $thresholdValue';
    }
  }

  /// Display label for rule type.
  String get ruleTypeLabel {
    switch (ruleType) {
      case 'stop_loss': return 'Stop-Loss';
      case 'gain_harvest': return 'Gain Harvest';
      case 'price_target': return 'Price Target';
      case 'allocation_drift': return 'Allocation Drift';
      default: return ruleType;
    }
  }
}
