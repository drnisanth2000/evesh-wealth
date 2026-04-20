import 'package:freezed_annotation/freezed_annotation.dart';

part 'fund_alert_model.freezed.dart';
part 'fund_alert_model.g.dart';

@freezed
class FundAlertModel with _$FundAlertModel {
  const factory FundAlertModel({
    required String id,
    @JsonKey(name: 'amfi_code') required int amfiCode,
    @JsonKey(name: 'alert_type') required String alertType,
    @JsonKey(name: 'old_value') String? oldValue,
    @JsonKey(name: 'new_value') String? newValue,
    @JsonKey(name: 'detected_at') required String detectedAt,
    Map<String, dynamic>? metadata,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _FundAlertModel;

  factory FundAlertModel.fromJson(Map<String, dynamic> json) =>
      _$FundAlertModelFromJson(json);

  const FundAlertModel._();

  /// Human-readable alert title
  String get title {
    switch (alertType) {
      case 'fund_manager_change':
        return 'Fund Manager Changed';
      case 'expense_ratio_change':
        return 'Expense Ratio Changed';
      case 'crisil_rating_change':
        return 'CRISIL Rating Changed';
      case 'fund_rating_change':
        return 'Fund Rating Changed';
      case 'aum_significant_drop':
        return 'Significant AUM Drop';
      default:
        return alertType.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Alert severity: high, medium, low
  String get severity {
    switch (alertType) {
      case 'fund_manager_change':
        return 'high';
      case 'expense_ratio_change':
        return 'medium';
      case 'aum_significant_drop':
        return 'high';
      case 'fund_rating_change':
        final dir = metadata?['direction'];
        return dir == 'downgraded' ? 'high' : 'low';
      case 'crisil_rating_change':
        return 'medium';
      default:
        return 'low';
    }
  }

  /// Human-readable description
  String get description {
    switch (alertType) {
      case 'fund_manager_change':
        final added = (metadata?['added'] as List?)?.cast<String>() ?? [];
        final removed = (metadata?['removed'] as List?)?.cast<String>() ?? [];
        final parts = <String>[];
        if (removed.isNotEmpty) parts.add('Removed: ${removed.join(", ")}');
        if (added.isNotEmpty) parts.add('Added: ${added.join(", ")}');
        return parts.join('. ');
      case 'expense_ratio_change':
        final dir = metadata?['direction'] ?? 'changed';
        return 'Expense ratio $dir from ${oldValue}% to ${newValue}%';
      case 'crisil_rating_change':
        return 'Rating changed from "$oldValue" to "$newValue"';
      case 'fund_rating_change':
        final dir = metadata?['direction'] ?? 'changed';
        return 'Fund rating $dir from $oldValue to $newValue stars';
      case 'aum_significant_drop':
        final pct = metadata?['drop_pct'] ?? '?';
        return 'AUM dropped ${pct}% from $oldValue to $newValue';
      default:
        return '$oldValue → $newValue';
    }
  }
}
