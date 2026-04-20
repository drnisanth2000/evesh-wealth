import 'package:freezed_annotation/freezed_annotation.dart';

import 'amfi_category_model.dart';
import 'portfolio_summary_model.dart';

part 'goal_model.freezed.dart';
part 'goal_model.g.dart';

@freezed
class GoalModel with _$GoalModel {
  const factory GoalModel({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'family_id') required String familyId,
    @JsonKey(name: 'member_id') String? memberId,
    @JsonKey(name: 'goal_name') required String goalName,
    @JsonKey(name: 'target_amount') required double targetAmount,
    @JsonKey(name: 'target_date') required String targetDate,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _GoalModel;

  factory GoalModel.fromJson(Map<String, dynamic> json) =>
      _$GoalModelFromJson(json);
}

@freezed
class GoalFundLink with _$GoalFundLink {
  const factory GoalFundLink({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'goal_id') required String goalId,
    @JsonKey(name: 'amfi_code') required int amfiCode,
    @JsonKey(name: 'allocation_pct') @Default(100.0) double allocationPct,
  }) = _GoalFundLink;

  factory GoalFundLink.fromJson(Map<String, dynamic> json) =>
      _$GoalFundLinkFromJson(json);
}

/// Term classification based on years to target date.
enum GoalTerm {
  shortTerm, // < 3 years
  mediumTerm, // 3-7 years
  longTerm, // > 7 years
}

extension GoalTermLabel on GoalTerm {
  String get label {
    switch (this) {
      case GoalTerm.shortTerm:
        return 'Short Term Goals';
      case GoalTerm.mediumTerm:
        return 'Medium Term Goals';
      case GoalTerm.longTerm:
        return 'Long Term Goals';
    }
  }

  String get subtitle {
    switch (this) {
      case GoalTerm.shortTerm:
        return 'Less than 3 years';
      case GoalTerm.mediumTerm:
        return '3 to 7 years';
      case GoalTerm.longTerm:
        return 'More than 7 years';
    }
  }
}

extension GoalTermFromGoal on GoalModel {
  DateTime get targetDateTime => DateTime.parse(targetDate);

  GoalTerm get term {
    final now = DateTime.now();
    final years = targetDateTime.difference(now).inDays / 365.25;
    if (years < 3) return GoalTerm.shortTerm;
    if (years <= 7) return GoalTerm.mediumTerm;
    return GoalTerm.longTerm;
  }
}

/// Classify a fund holding into a goal term.
///
/// Preferred path: look up `f.amfiCategoryId` in the AMFI catalog and use
/// that row's `defaultTerm`. Falls back to the legacy keyword heuristic when
/// the catalog has no matching row (e.g. unmapped fund_master rows during
/// the rollout window).
GoalTerm classifyFundTerm(
  FundHoldingSummary f, [
  Map<String, AmfiCategoryModel> catalog = const {},
]) {
  final id = f.amfiCategoryId;
  if (id != null && catalog.containsKey(id)) {
    return _termFromString(catalog[id]!.defaultTerm);
  }
  final cat = (f.category ?? '').toLowerCase();
  final tax = (f.taxCategory ?? '').toLowerCase();
  final asset = (f.assetClassLabel ?? '').toLowerCase();
  final all = '$cat $tax $asset';

  if (all.contains('liquid') ||
      all.contains('ultra short') ||
      all.contains('overnight') ||
      all.contains('money market')) {
    return GoalTerm.shortTerm;
  }
  if (all.contains('hybrid-d') ||
      all.contains('hybrid-debt') ||
      all.contains('international') ||
      cat == 'debt' ||
      tax == 'debt' ||
      asset == 'debt') {
    return GoalTerm.mediumTerm;
  }
  // Equity / Hybrid-equity / Gold / fallback → long term
  return GoalTerm.longTerm;
}

GoalTerm _termFromString(String s) {
  switch (s) {
    case 'shortTerm':
      return GoalTerm.shortTerm;
    case 'mediumTerm':
      return GoalTerm.mediumTerm;
    default:
      return GoalTerm.longTerm;
  }
}

/// Build a deterministic mapping from fund (amfi_code) → goal id for one
/// member's view. Honours explicit `goal_funds` rows first, then falls back
/// to category-based auto-attach against the earliest goal in the matching
/// term. Funds with no matching term goal fall through to the long-term
/// default (or any goal if none exist).
Map<int, String> resolveFundGoalAssignments({
  required List<GoalModel> goals,
  required List<FundHoldingSummary> funds,
  required List<GoalFundLink> explicitLinks,
}) {
  final result = <int, String>{};
  if (goals.isEmpty) return result;

  // Earliest target_date goal per term acts as the "default" for that term.
  final sorted = [...goals]
    ..sort((a, b) => a.targetDateTime.compareTo(b.targetDateTime));
  final defaultByTerm = <GoalTerm, String>{};
  for (final g in sorted) {
    defaultByTerm.putIfAbsent(g.term, () => g.id);
  }
  // Ultimate fallback: first goal overall.
  final fallbackGoalId = sorted.first.id;

  // Pre-index explicit links by amfi_code → goal_id.
  final explicit = <int, String>{};
  for (final link in explicitLinks) {
    // Only consider links pointing at goals we know about.
    if (goals.any((g) => g.id == link.goalId)) {
      explicit[link.amfiCode] = link.goalId;
    }
  }

  for (final f in funds) {
    final pinned = explicit[f.amfiCode];
    if (pinned != null) {
      result[f.amfiCode] = pinned;
      continue;
    }
    final term = classifyFundTerm(f);
    result[f.amfiCode] =
        defaultByTerm[term] ?? defaultByTerm[GoalTerm.longTerm] ?? fallbackGoalId;
  }
  return result;
}
