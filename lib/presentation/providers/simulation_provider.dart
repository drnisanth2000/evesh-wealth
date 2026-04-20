import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/simulation_models.dart';
import '../../domain/usecases/compute_bucket_strategy.dart';
import '../../domain/usecases/compute_rebalance_actions.dart';
import '../../domain/usecases/compute_simulation.dart';
import 'auth_provider.dart';
import 'family_provider.dart';
import 'portfolio_provider.dart';
import 'tax_provider.dart';
import 'wealth_planner_provider.dart';

part 'simulation_provider.g.dart';

// ─── Hive persistence helpers ──────────────────────────────────────────────
// Fund-tab targets survive page reloads by writing the SimulationState to
// the `user_prefs` Hive box under `fund_targets/{memberId|ALL}`. Same box
// already used by SuggestionEdits + selected_member_provider.

String _hiveKey(String? memberId) => 'fund_targets/${memberId ?? 'ALL'}';

Map<String, dynamic>? _readSavedStateRaw(String? memberId) {
  try {
    final box = Hive.box<dynamic>(AppConstants.hiveBoxUserPrefs);
    final raw = box.get(_hiveKey(memberId));
    if (raw is Map) return Map<String, dynamic>.from(raw);
  } catch (_) {
    // Hive not yet open or read failure — treat as no saved state.
  }
  return null;
}

SimulationState _simStateFromHiveOrDefault(String? memberId) {
  final raw = _readSavedStateRaw(memberId);
  if (raw == null) {
    return const SimulationState(
      fundAmounts: {},
      additionalLumpsum: 0,
      additionalSip: 0,
      isDirty: false,
    );
  }
  final fundMap = <int, double>{};
  final rawFunds = raw['fundAmounts'];
  if (rawFunds is Map) {
    for (final e in rawFunds.entries) {
      final k = e.key;
      final v = e.value;
      final parsedKey = k is int ? k : int.tryParse('$k');
      final parsedVal = v is num ? v.toDouble() : null;
      if (parsedKey != null && parsedVal != null) {
        fundMap[parsedKey] = parsedVal;
      }
    }
  }
  final allocMap = <String, double>{};
  final rawAlloc = raw['targetAllocations'];
  if (rawAlloc is Map) {
    for (final e in rawAlloc.entries) {
      final v = e.value;
      if (v is num) allocMap['${e.key}'] = v.toDouble();
    }
  }
  final bucketMap = <String, double>{};
  final rawBucket = raw['bucketTargets'];
  if (rawBucket is Map) {
    for (final e in rawBucket.entries) {
      final v = e.value;
      if (v is num) bucketMap['${e.key}'] = v.toDouble();
    }
  }
  final pendingSet = <int>{};
  final rawPending = raw['pendingDeployments'];
  if (rawPending is List) {
    for (final v in rawPending) {
      if (v is int) {
        pendingSet.add(v);
      } else {
        final parsed = int.tryParse('$v');
        if (parsed != null) pendingSet.add(parsed);
      }
    }
  }
  final pendingNames = <int, String>{};
  final rawNames = raw['pendingFundNames'];
  if (rawNames is Map) {
    for (final e in rawNames.entries) {
      final parsedKey = e.key is int ? e.key as int : int.tryParse('${e.key}');
      final parsedVal = e.value is String ? e.value as String : null;
      if (parsedKey != null && parsedVal != null) {
        pendingNames[parsedKey] = parsedVal;
      }
    }
  }
  final pendingClass = <int, String>{};
  final rawClass = raw['pendingFundAssetClass'];
  if (rawClass is Map) {
    for (final e in rawClass.entries) {
      final parsedKey = e.key is int ? e.key as int : int.tryParse('${e.key}');
      final parsedVal = e.value is String ? e.value as String : null;
      if (parsedKey != null && parsedVal != null) {
        pendingClass[parsedKey] = parsedVal;
      }
    }
  }
  final touchedSet = <int>{};
  final rawTouched = raw['touchedFundAmounts'];
  if (rawTouched is List) {
    for (final v in rawTouched) {
      if (v is int) {
        touchedSet.add(v);
      } else {
        final parsed = int.tryParse('$v');
        if (parsed != null) touchedSet.add(parsed);
      }
    }
  }
  return SimulationState(
    fundAmounts: fundMap,
    additionalLumpsum: (raw['additionalLumpsum'] as num?)?.toDouble() ?? 0,
    additionalSip: (raw['additionalSip'] as num?)?.toDouble() ?? 0,
    isDirty: raw['isDirty'] as bool? ?? false,
    targetAllocations: allocMap,
    bucketTargets: bucketMap,
    pendingDeployments: pendingSet,
    pendingFundNames: pendingNames,
    pendingFundAssetClass: pendingClass,
    touchedFundAmounts: touchedSet,
  );
}

Future<void> _writeSimStateToHive(
  String? memberId,
  SimulationState s,
) async {
  try {
    final box = Hive.box<dynamic>(AppConstants.hiveBoxUserPrefs);
    await box.put(_hiveKey(memberId), {
      'fundAmounts':
          s.fundAmounts.map((k, v) => MapEntry(k.toString(), v)),
      'additionalLumpsum': s.additionalLumpsum,
      'additionalSip': s.additionalSip,
      'isDirty': s.isDirty,
      'targetAllocations': s.targetAllocations,
      'bucketTargets': s.bucketTargets,
      'pendingDeployments': s.pendingDeployments.toList(),
      'pendingFundNames':
          s.pendingFundNames.map((k, v) => MapEntry(k.toString(), v)),
      'pendingFundAssetClass':
          s.pendingFundAssetClass.map((k, v) => MapEntry(k.toString(), v)),
      'touchedFundAmounts': s.touchedFundAmounts.toList(),
    });
  } catch (_) {
    // Hive write failure is non-fatal; in-memory state still applies.
  }
}

// ─── Display name → asset class key mapping ────────────────────────────────
const _displayToAssetClassKey = <String, String>{
  'Core Equity': 'coreEquity',
  'Satellite Equity': 'satelliteEquity',
  'Hybrid': 'hybrid',
  'Debt': 'debt',
  'Liquid': 'liquid',
  'Gold': 'gold',
  'Alternate': 'alternate',
};

// ═══════════════════════════════════════════════════════════════════════════
// A. Manual Notifier — mutable simulation state (NOT codegen)
// ═══════════════════════════════════════════════════════════════════════════

class SimulationStateNotifier
    extends FamilyNotifier<SimulationState, String?> {
  @override
  SimulationState build(String? memberId) {
    // Without keepAlive, the notifier disposes when no widget watches it,
    // wiping the user's slider edits the moment they navigate from Asset →
    // Rebalance. Rebalance then falls back to family defaults and emits
    // phantom Buy suggestions for asset classes the user just zeroed out.
    ref.keepAlive();
    // Restore any previously-saved Fund-tab targets for this member so
    // targets survive page reloads — closes the "my slider edit vanished"
    // loop flagged by users.
    return _simStateFromHiveOrDefault(memberId);
  }

  void _persist() {
    // Fire-and-forget; Hive write is usually synchronous on web/mobile and
    // we don't need to block the UI thread.
    _writeSimStateToHive(arg, state);
  }

  void initFromHoldings(Map<int, double> currentAmounts) {
    // Preserve any previously-persisted custom targets if they exist — only
    // initialise untouched funds to their current values. Without this,
    // every AllocFundTab mount would wipe the user's saved edits.
    final existing = state.fundAmounts;
    final merged = <int, double>{...currentAmounts, ...existing};
    state = SimulationState(
      fundAmounts: merged,
      additionalLumpsum: state.additionalLumpsum,
      additionalSip: state.additionalSip,
      isDirty: state.isDirty,
      targetAllocations: state.targetAllocations,
      bucketTargets: state.bucketTargets,
      pendingDeployments: state.pendingDeployments,
      pendingFundNames: state.pendingFundNames,
      pendingFundAssetClass: state.pendingFundAssetClass,
      touchedFundAmounts: state.touchedFundAmounts,
    );
    _persist();
  }

  /// Bulk update of per-fund targets after a reallocation sweep (e.g. user
  /// zeroed a fund → helper proportionally redistributes into peers).
  /// Every amfi written here is also flagged as touched.
  void setFundAmounts(Map<int, double> updates) {
    if (updates.isEmpty) return;
    final merged = Map<int, double>.from(state.fundAmounts)..addAll(updates);
    final touched = {...state.touchedFundAmounts, ...updates.keys};
    state = state.copyWith(
      fundAmounts: merged,
      touchedFundAmounts: touched,
      isDirty: true,
    );
    _persist();
  }

  void markPendingDeployment(
    int amfiCode, {
    String? fundName,
    String? assetClassName,
  }) {
    final pendingUpdated = {...state.pendingDeployments, amfiCode};
    final namesUpdated = fundName == null
        ? state.pendingFundNames
        : {...state.pendingFundNames, amfiCode: fundName};
    final classUpdated = assetClassName == null
        ? state.pendingFundAssetClass
        : {...state.pendingFundAssetClass, amfiCode: assetClassName};
    state = state.copyWith(
      pendingDeployments: pendingUpdated,
      pendingFundNames: namesUpdated,
      pendingFundAssetClass: classUpdated,
      isDirty: true,
    );
    _persist();
  }

  void clearPendingDeployment(int amfiCode) {
    final hadPending = state.pendingDeployments.contains(amfiCode);
    final hadName = state.pendingFundNames.containsKey(amfiCode);
    final hadClass = state.pendingFundAssetClass.containsKey(amfiCode);
    if (!hadPending && !hadName && !hadClass) return;
    final pendingUpdated = {...state.pendingDeployments}..remove(amfiCode);
    final namesUpdated = {...state.pendingFundNames}..remove(amfiCode);
    final classUpdated = {...state.pendingFundAssetClass}..remove(amfiCode);
    state = state.copyWith(
      pendingDeployments: pendingUpdated,
      pendingFundNames: namesUpdated,
      pendingFundAssetClass: classUpdated,
    );
    _persist();
  }

  void setFundAmount(int amfiCode, double amount) {
    final updated = Map<int, double>.from(state.fundAmounts);
    updated[amfiCode] = amount;
    // Flag this fund as user-touched so the Fund tab stops serving it a
    // pro-rata suggestion and instead renders the user's value.
    final touched = {...state.touchedFundAmounts, amfiCode};
    state = state.copyWith(
      fundAmounts: updated,
      touchedFundAmounts: touched,
      isDirty: true,
    );
    _persist();
  }

  void setLumpsum(double amount) {
    state = state.copyWith(additionalLumpsum: amount, isDirty: true);
    _persist();
  }

  void setSip(double amount) {
    state = state.copyWith(additionalSip: amount, isDirty: true);
    _persist();
  }

  void setTargetAllocation(String assetClassKey, double pct) {
    final updated = Map<String, double>.from(state.targetAllocations);
    updated[assetClassKey] = pct;
    state = state.copyWith(targetAllocations: updated, isDirty: true);
    _persist();
  }

  /// Sets the user's custom target for one of the 3 buckets. Key is the
  /// `Bucket.name` string (liquid / fixedIncome / growth). Persists to Hive.
  void setBucketTarget(String bucketKey, double pct) {
    final updated = Map<String, double>.from(state.bucketTargets);
    updated[bucketKey] = pct.clamp(0, 100);
    state = state.copyWith(bucketTargets: updated, isDirty: true);
    _persist();
  }

  void initTargetsFromStrategy(Map<String, double> targets) {
    state = state.copyWith(targetAllocations: Map.of(targets));
    _persist();
  }

  void resetTargets() {
    state = state.copyWith(targetAllocations: {}, isDirty: true);
    _persist();
  }

  void reset(Map<int, double> currentAmounts) {
    state = SimulationState(
      fundAmounts: Map.of(currentAmounts),
      additionalLumpsum: 0,
      additionalSip: 0,
      isDirty: false,
      targetAllocations: {},
      bucketTargets: {},
      pendingDeployments: {},
      pendingFundNames: {},
      pendingFundAssetClass: {},
      touchedFundAmounts: {},
    );
    _persist();
  }
}

final simulationStateProvider = NotifierProvider.family<
    SimulationStateNotifier, SimulationState, String?>(
  SimulationStateNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════
// B. Codegen providers (@riverpod)
// ═══════════════════════════════════════════════════════════════════════════

/// Computes [BucketStrategy] for a specific family member (or Self if null).
@riverpod
Future<BucketStrategy> memberBucketStrategy(
  MemberBucketStrategyRef ref,
  String? memberId,
) async {
  final members = await ref.watch(familyMembersProvider.future);

  final member = memberId != null
      ? members.where((m) => m.id == memberId).firstOrNull
      : members.where((m) => m.relationship == 'Self').firstOrNull;

  // Compute age from dateOfBirth, fallback 35
  final age = _ageFromDob(member?.dateOfBirth);
  final riskProfile = member?.riskProfile ?? 'Moderate';
  final retirementAge = member?.retirementAge ?? 60;

  return BucketStrategyCalculator.compute(
    age: age,
    riskProfile: riskProfile,
    retirementAge: retirementAge,
  );
}

/// Computes [SimulationResult] from the current [SimulationState].
/// Returns null when the user hasn't changed anything (not dirty, empty).
@riverpod
Future<SimulationResult?> simulationResult(
  SimulationResultRef ref,
  String? memberId,
) async {
  final simState = ref.watch(simulationStateProvider(memberId));

  // Nothing to simulate
  if (!simState.isDirty && simState.fundAmounts.isEmpty) return null;

  final portfolio = await ref.watch(portfolioSummaryProvider(memberId).future);
  final health = await ref.watch(allocationHealthProvider(memberId).future);
  final bucketStrategy =
      await ref.watch(memberBucketStrategyProvider(memberId).future);

  // Get member's drift threshold
  final members = await ref.watch(familyMembersProvider.future);
  final member = memberId != null
      ? members.where((m) => m.id == memberId).firstOrNull
      : members.where((m) => m.relationship == 'Self').firstOrNull;
  final driftThreshold = member?.driftThresholdPct ?? 5.0;

  // Build FundHoldingInput list from portfolio (same mapping as action_center_provider)
  final holdings = portfolio.fundHoldings.map((f) {
    final acLabel = f.assetClassLabel ?? f.taxCategory ?? 'Alternate';
    final acKey = _displayToAssetClassKey[acLabel] ?? 'alternate';
    return FundHoldingInput(
      amfiCode: f.amfiCode,
      fundName: f.fundName,
      assetClassKey: acKey,
      currentValue: f.currentValue,
      return3y: f.xirr,
      expenseRatio: f.expenseRatio,
    );
  }).toList();

  // Get unrealized exposures (try/catch — may fail if no tax data)
  List<UnrealizedExposure> exposures = [];
  try {
    final exposureResult =
        await ref.watch(unrealizedExposureProvider.future);
    exposures = exposureResult.exposures;
    // Filter by memberId if set
    if (memberId != null) {
      exposures =
          exposures.where((e) => e.memberId == memberId).toList();
    }
  } catch (_) {
    // No exposure data available — proceed with empty list
  }

  return SimulationCalculator.compute(
    holdings: holdings,
    adjustedAmounts: simState.fundAmounts,
    additionalLumpsum: simState.additionalLumpsum,
    additionalSip: simState.additionalSip,
    bucketStrategy: bucketStrategy,
    driftThreshold: driftThreshold,
    exposures: exposures,
    currentHealthScore: health.healthScore,
  );
}

/// Fetches the active frozen plan for a member (or self if null).
///
/// Swallows transient/optional errors (missing table, parse failure) and
/// returns null. The frozen-plan signal is non-essential for downstream
/// providers like `rebalanceAnalysisProvider`; an exception here would cascade
/// and blank out the whole Suggested tab.
@riverpod
Future<FrozenPlan?> activeFrozenPlan(
  ActiveFrozenPlanRef ref,
  String? memberId,
) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;

  final client = ref.watch(supabaseClientProvider);

  try {
    var query = client
        .from('frozen_plans')
        .select()
        .eq('owner_id', uid)
        .eq('status', 'active');

    if (memberId != null) {
      query = query.eq('member_id', memberId);
    } else {
      query = query.isFilter('member_id', null);
    }

    final response =
        await query.order('created_at', ascending: false).limit(1);
    final rows = response as List;
    if (rows.isEmpty) return null;
    return FrozenPlan.fromJson(rows.first as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

/// Derives age in whole years from an ISO date string (yyyy-MM-dd).
/// Returns 35 as a sensible default if DOB is absent or unparseable.
int _ageFromDob(String? dateOfBirth) {
  if (dateOfBirth == null || dateOfBirth.isEmpty) return 35;
  final dob = DateTime.tryParse(dateOfBirth);
  if (dob == null) return 35;
  final today = DateTime.now();
  int age = today.year - dob.year;
  if (today.month < dob.month ||
      (today.month == dob.month && today.day < dob.day)) {
    age--;
  }
  return age.clamp(18, 100);
}
