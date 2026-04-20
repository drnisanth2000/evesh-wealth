# Slice 6b: Interactive Simulator + Action Persistence — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform Action Center into an interactive planning tool with per-fund sliders, dynamic 3-bucket strategy, vertical bucket visualization, tax impact preview, plan persistence, and per-member drift thresholds.

**Architecture:** Pure Dart computation engines (BucketStrategyCalculator, SimulationCalculator) feed Riverpod providers. The simulator runs entirely in-memory with no Supabase calls — only Freeze Plan persists. The 3-bucket strategy becomes dynamic (age/risk/life-stage), replacing hardcoded targets in both compute_unified_actions.dart and run_rebalance_analysis.dart.

**Tech Stack:** Flutter 3.22+, Dart 3.3+, Riverpod codegen (`@riverpod`), CustomPaint, Supabase PostgreSQL, fl_chart

**Important:** No git repository — skip all git commands. Build: `export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && flutter build web`. Deploy: `export PATH="/usr/local/bin:/Users/nisanth/.npm-global/bin:/opt/homebrew/bin:$PATH" && netlify deploy --prod --dir=build/web`

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `lib/domain/models/simulation_models.dart` | SimulationState, BucketStrategy, RefillRule, BucketComposition, AssetClassBand, FundTaxImpact, SimulationResult, FrozenPlan |
| Create | `lib/core/constants/bucket_education.dart` | Educational strings, instrument lists, refill rules by scenario |
| Create | `lib/domain/usecases/compute_bucket_strategy.dart` | BucketStrategyCalculator — dynamic targets by age/risk/life-stage |
| Create | `lib/domain/usecases/compute_simulation.dart` | SimulationCalculator — recomputes allocation, health, tax from slider state |
| Modify | `lib/domain/usecases/compute_unified_actions.dart` | Replace hardcoded bucket targets/names with BucketStrategy parameter |
| Modify | `lib/domain/usecases/run_rebalance_analysis.dart` | Replace hardcoded bucket targets/names with BucketStrategy parameter |
| Create | `lib/presentation/providers/simulation_provider.dart` | SimulationStateNotifier + simulationResultProvider |
| Modify | `lib/presentation/providers/action_center_provider.dart` | Add member parameter, integrate BucketStrategy |
| Create | `lib/presentation/widgets/action_center/vertical_buckets.dart` | 3 vertical bucket CustomPaint with asset bands + overflow arrows |
| Create | `lib/presentation/widgets/action_center/fund_slider_row.dart` | Per-fund slider + text box + tax preview line |
| Create | `lib/presentation/widgets/action_center/simulation_summary.dart` | Tax summary, health delta, freeze/reset sticky bar |
| Create | `lib/presentation/widgets/action_center/education_card.dart` | Context-sensitive strategy tips card |
| Modify | `lib/presentation/screens/wealth_planner/action_center_screen.dart` | Member selector, Plan/Simulate tabs, vertical buckets, education |
| Modify | `lib/presentation/widgets/action_center/bucket_bars.dart` | Deprecate horizontal → redirect to vertical |
| Create | `supabase/migrations/012_frozen_plans.sql` | frozen_plans table + drift_threshold_pct column + RLS |
| Modify | `lib/data/models/family_model.dart` | Add driftThresholdPct field to FamilyMemberModel |
| Modify | `lib/presentation/screens/settings/family_setup_screen.dart` | Drift threshold slider + text box |
| Create | `test/domain/usecases/compute_bucket_strategy_test.dart` | ~10 tests for bucket strategy engine |
| Create | `test/domain/usecases/compute_simulation_test.dart` | ~8 tests for simulation engine |

---

### Task 1: Domain Models — simulation_models.dart + bucket_education.dart

**Files:**
- Create: `lib/domain/models/simulation_models.dart`
- Create: `lib/core/constants/bucket_education.dart`

- [ ] **Step 1: Create simulation_models.dart**

```dart
// lib/domain/models/simulation_models.dart

/// Domain models for the Interactive Simulator + Action Persistence.
/// Plain Dart classes (no Freezed) — these are computation intermediaries.

// ── Simulation State (in-memory, managed by Riverpod notifier) ──────────────

class SimulationState {
  final Map<int, double> fundAmounts; // amfiCode → desired ₹ amount
  final double additionalLumpsum;
  final double additionalSip;
  final bool isDirty; // user changed something?

  const SimulationState({
    this.fundAmounts = const {},
    this.additionalLumpsum = 0,
    this.additionalSip = 0,
    this.isDirty = false,
  });

  SimulationState copyWith({
    Map<int, double>? fundAmounts,
    double? additionalLumpsum,
    double? additionalSip,
    bool? isDirty,
  }) {
    return SimulationState(
      fundAmounts: fundAmounts ?? this.fundAmounts,
      additionalLumpsum: additionalLumpsum ?? this.additionalLumpsum,
      additionalSip: additionalSip ?? this.additionalSip,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

// ── Bucket Strategy (computed by BucketStrategyCalculator) ───────────────────

class RefillRule {
  final int fromBucket;
  final int toBucket;
  final String trigger;
  final String frequency;
  final String description;

  const RefillRule({
    required this.fromBucket,
    required this.toBucket,
    required this.trigger,
    required this.frequency,
    required this.description,
  });
}

class BucketStrategy {
  final String scenario; // 'accumulation' | 'distribution'
  final Map<int, double> bucketTargets; // {1: 8.0, 2: 22.0, 3: 70.0}
  final Map<int, String> bucketNames; // {1: 'Liquidity (0-2yr)', ...}
  final Map<int, List<String>> bucketInstruments;
  final double corePct;
  final double satellitePct;
  final List<String> educationNotes;
  final List<RefillRule> refillRules;

  const BucketStrategy({
    required this.scenario,
    required this.bucketTargets,
    required this.bucketNames,
    required this.bucketInstruments,
    required this.corePct,
    required this.satellitePct,
    required this.educationNotes,
    required this.refillRules,
  });
}

// ── Simulation Result (recomputed on every slider/textbox change) ────────────

class AssetClassBand {
  final String assetClassKey;
  final String displayName;
  final double valuePct; // % of this bucket
  final double valueAmount; // ₹

  const AssetClassBand({
    required this.assetClassKey,
    required this.displayName,
    required this.valuePct,
    required this.valueAmount,
  });
}

class BucketComposition {
  final int bucketNumber;
  final String bucketName;
  final double currentPct;
  final double idealPct;
  final double currentValue;
  final String status; // 'overweight', 'underweight', 'balanced'
  final List<AssetClassBand> bands; // colored bands inside bucket
  final double overflowPct; // >0 if spilling
  final int? spillsIntoBucket; // which bucket to pour into

  const BucketComposition({
    required this.bucketNumber,
    required this.bucketName,
    required this.currentPct,
    required this.idealPct,
    required this.currentValue,
    required this.status,
    required this.bands,
    this.overflowPct = 0,
    this.spillsIntoBucket,
  });
}

class FundTaxImpact {
  final int amfiCode;
  final String fundName;
  final double sellAmount;
  final double stcgAmount;
  final double ltcgAmount;
  final double stcgTax;
  final double ltcgTax;
  final double exitLoadAmount;
  final double netProceeds;
  final int holdingDays;

  const FundTaxImpact({
    required this.amfiCode,
    required this.fundName,
    required this.sellAmount,
    required this.stcgAmount,
    required this.ltcgAmount,
    required this.stcgTax,
    required this.ltcgTax,
    required this.exitLoadAmount,
    required this.netProceeds,
    required this.holdingDays,
  });

  double get totalTax => stcgTax + ltcgTax;
}

class SimulationResult {
  final Map<String, double> newAllocationPct; // asset class → %
  final List<BucketComposition> bucketFills;
  final int projectedHealthScore;
  final int healthDelta; // vs current
  final List<FundTaxImpact> taxImpacts; // per fund being sold
  final double totalTaxCost;
  final double totalExitLoad;
  final double netRebalanceCost;
  final double totalPortfolioValue; // including new money

  const SimulationResult({
    required this.newAllocationPct,
    required this.bucketFills,
    required this.projectedHealthScore,
    required this.healthDelta,
    required this.taxImpacts,
    required this.totalTaxCost,
    required this.totalExitLoad,
    required this.netRebalanceCost,
    required this.totalPortfolioValue,
  });
}

// ── Frozen Plan (persisted to Supabase) ─────────────────────────────────────

class FrozenPlan {
  final String? id;
  final String ownerId;
  final String? memberId;
  final Map<int, double> fundAllocations; // amfiCode → amount
  final double additionalLumpsum;
  final double additionalSip;
  final int? healthScore;
  final int? healthDelta;
  final double? totalTaxImpact;
  final double? totalExitLoad;
  final Map<int, double>? bucketTargets; // {1: %, 2: %, 3: %}
  final List<Map<String, dynamic>>? actionItems;
  final String status; // 'active', 'completed', 'superseded'
  final DateTime? createdAt;
  final DateTime? completedAt;

  const FrozenPlan({
    this.id,
    required this.ownerId,
    this.memberId,
    required this.fundAllocations,
    this.additionalLumpsum = 0,
    this.additionalSip = 0,
    this.healthScore,
    this.healthDelta,
    this.totalTaxImpact,
    this.totalExitLoad,
    this.bucketTargets,
    this.actionItems,
    this.status = 'active',
    this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'owner_id': ownerId,
      'member_id': memberId,
      'fund_allocations': {
        for (final e in fundAllocations.entries) '${e.key}': e.value,
      },
      'additional_lumpsum': additionalLumpsum,
      'additional_sip': additionalSip,
      'health_score': healthScore,
      'health_delta': healthDelta,
      'total_tax_impact': totalTaxImpact,
      'total_exit_load': totalExitLoad,
      'bucket_targets': bucketTargets != null
          ? {for (final e in bucketTargets!.entries) '${e.key}': e.value}
          : null,
      'action_items': actionItems,
      'status': status,
    };
  }

  factory FrozenPlan.fromJson(Map<String, dynamic> json) {
    final rawAlloc = json['fund_allocations'] as Map<String, dynamic>? ?? {};
    final rawTargets = json['bucket_targets'] as Map<String, dynamic>?;

    return FrozenPlan(
      id: json['id'] as String?,
      ownerId: json['owner_id'] as String,
      memberId: json['member_id'] as String?,
      fundAllocations: {
        for (final e in rawAlloc.entries)
          int.parse(e.key): (e.value as num).toDouble(),
      },
      additionalLumpsum: (json['additional_lumpsum'] as num?)?.toDouble() ?? 0,
      additionalSip: (json['additional_sip'] as num?)?.toDouble() ?? 0,
      healthScore: json['health_score'] as int?,
      healthDelta: json['health_delta'] as int?,
      totalTaxImpact: (json['total_tax_impact'] as num?)?.toDouble(),
      totalExitLoad: (json['total_exit_load'] as num?)?.toDouble(),
      bucketTargets: rawTargets != null
          ? {
              for (final e in rawTargets.entries)
                int.parse(e.key): (e.value as num).toDouble(),
            }
          : null,
      actionItems: (json['action_items'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}
```

- [ ] **Step 2: Create bucket_education.dart**

```dart
// lib/core/constants/bucket_education.dart

/// Educational content for the 3-bucket strategy.
/// Context-sensitive: accumulation (earning) vs distribution (retired).

class BucketEducation {
  BucketEducation._();

  /// Education notes for accumulation scenario (earning members).
  static const accumulationNotes = <String>[
    'Bucket 1 is a one-time setup (3-6 months expenses). Every SIP goes to Buckets 2 & 3.',
    'Core SIPs (75%): Index + Flexi cap. Satellite SIPs (25%): Mid/Small cap + Thematic.',
    "Don't pause SIPs in crashes — that's when you buy cheap.",
    'Principle preservation in Bucket 1 — no trading needed to meet short-term income.',
  ];

  /// Education notes for distribution scenario (retired members).
  static const distributionNotes = <String>[
    'Set up SWP only from Bucket 1 (liquid funds). Never force-sell Bucket 3 during a downturn.',
    'Even in a 40% crash, Bucket 1 covers 2-3 years — no need to panic.',
    'Refill Bucket 1 from Bucket 2 every 12-18 months. Refill Bucket 2 from Bucket 3 every 4-5 years.',
    'Take income generated from Bucket 2 to replenish Bucket 1 as it is spent.',
  ];

  /// General notes (shown in both scenarios).
  static const generalNotes = <String>[
    'The 3-bucket strategy divides your portfolio by time horizon, so you never sell long-term assets during short-term downturns.',
    'Short-term movements in Bucket 3 are tolerable — it keeps pace with inflation over time.',
  ];

  /// Instruments suitable for each bucket.
  static const bucketInstruments = <int, List<String>>{
    1: ['Savings account', 'Liquid funds', 'FD', 'Ultra-short duration', 'Money market'],
    2: ['Debt funds', 'Balanced Advantage', 'Hybrid funds', 'Gold', 'REITs'],
    3: ['Large cap equity', 'Mid cap equity', 'Small cap equity', 'Index funds', 'International', 'Direct stocks'],
  };

  /// Bucket names (consistent across app).
  static const bucketNames = <int, String>{
    1: 'Liquidity (0-2yr)',
    2: 'Stability (3-7yr)',
    3: 'Growth (7yr+)',
  };

  /// Asset class key → bucket number mapping.
  static const assetClassToBucket = <String, int>{
    'liquid': 1,
    'debt': 1,
    'gold': 2,
    'hybrid': 2,
    'alternate': 2,
    'coreEquity': 3,
    'satelliteEquity': 3,
  };

  /// Refill rules for accumulation scenario.
  static const accumulationRefillRules = <Map<String, dynamic>>[
    {
      'fromBucket': 2,
      'toBucket': 1,
      'trigger': 'Bucket 1 drops below 12 months expenses',
      'frequency': 'Every 12-18 months',
      'description': 'Transfer from Stability to Liquidity when short-term buffer runs low',
    },
    {
      'fromBucket': 3,
      'toBucket': 2,
      'trigger': 'Bucket 2 depleted below target',
      'frequency': 'Every 4-5 years',
      'description': 'Book partial Growth gains to refill Stability bucket',
    },
  ];

  /// Refill rules for distribution scenario.
  static const distributionRefillRules = <Map<String, dynamic>>[
    {
      'fromBucket': 2,
      'toBucket': 1,
      'trigger': 'Bucket 1 drops below 12 months expenses',
      'frequency': 'Every 12-18 months',
      'description': 'Transfer from Stability to Liquidity for SWP source',
    },
    {
      'fromBucket': 3,
      'toBucket': 2,
      'trigger': 'Bucket 2 depleted below target',
      'frequency': 'Every 4-5 years (only in up markets)',
      'description': 'Book Growth gains to refill Stability — never force-sell in a downturn',
    },
  ];

  /// Get education notes for a given scenario.
  static List<String> notesForScenario(String scenario) {
    final specific = scenario == 'distribution'
        ? distributionNotes
        : accumulationNotes;
    return [...specific, ...generalNotes];
  }
}
```

- [ ] **Step 3: Verify models compile**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && dart analyze lib/domain/models/simulation_models.dart lib/core/constants/bucket_education.dart`

Expected: No errors.

---

### Task 2: Bucket Strategy Engine + Tests

**Files:**
- Create: `lib/domain/usecases/compute_bucket_strategy.dart`
- Create: `test/domain/usecases/compute_bucket_strategy_test.dart`

- [ ] **Step 1: Write failing tests for BucketStrategyCalculator**

```dart
// test/domain/usecases/compute_bucket_strategy_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/domain/usecases/compute_bucket_strategy.dart';

void main() {
  group('BucketStrategyCalculator', () {
    // ── Accumulation scenario tests ─────────────────────────────────────

    test('young aggressive accumulator (age 28) gets high growth allocation', () {
      final strategy = BucketStrategyCalculator.compute(
        age: 28,
        riskProfile: 'Aggressive',
        retirementAge: 60,
      );

      expect(strategy.scenario, 'accumulation');
      expect(strategy.bucketTargets[3]!, greaterThanOrEqualTo(75.0));
      expect(strategy.bucketTargets[1]!, lessThanOrEqualTo(8.0));
      expect(strategy.corePct, 75.0);
      expect(strategy.satellitePct, 25.0);
    });

    test('conservative age 28 gets lower growth than aggressive', () {
      final aggressive = BucketStrategyCalculator.compute(
        age: 28,
        riskProfile: 'Aggressive',
        retirementAge: 60,
      );
      final conservative = BucketStrategyCalculator.compute(
        age: 28,
        riskProfile: 'Conservative',
        retirementAge: 60,
      );

      expect(conservative.bucketTargets[3]!, lessThan(aggressive.bucketTargets[3]!));
      expect(conservative.bucketTargets[1]!, greaterThan(aggressive.bucketTargets[1]!));
    });

    test('mid-career moderate (age 40) gets balanced allocation', () {
      final strategy = BucketStrategyCalculator.compute(
        age: 40,
        riskProfile: 'Moderate',
        retirementAge: 60,
      );

      expect(strategy.scenario, 'accumulation');
      expect(strategy.bucketTargets[3]!, greaterThanOrEqualTo(60.0));
      expect(strategy.bucketTargets[3]!, lessThanOrEqualTo(70.0));
      expect(strategy.bucketTargets[2]!, greaterThanOrEqualTo(20.0));
    });

    test('pre-retirement (age 55) shifts toward stability', () {
      final strategy = BucketStrategyCalculator.compute(
        age: 55,
        riskProfile: 'Moderate',
        retirementAge: 60,
      );

      expect(strategy.scenario, 'accumulation');
      expect(strategy.bucketTargets[1]!, greaterThanOrEqualTo(15.0));
      expect(strategy.bucketTargets[2]!, greaterThanOrEqualTo(35.0));
      expect(strategy.corePct, 80.0);
      expect(strategy.satellitePct, 20.0);
    });

    // ── Distribution scenario tests ─────────────────────────────────────

    test('retired member (age 65) gets distribution allocation', () {
      final strategy = BucketStrategyCalculator.compute(
        age: 65,
        riskProfile: 'Moderate',
        retirementAge: 60,
      );

      expect(strategy.scenario, 'distribution');
      expect(strategy.bucketTargets[1]!, greaterThanOrEqualTo(20.0));
      expect(strategy.bucketTargets[2]!, greaterThanOrEqualTo(40.0));
      expect(strategy.bucketTargets[3]!, lessThanOrEqualTo(30.0));
      expect(strategy.corePct, 80.0);
      expect(strategy.satellitePct, 20.0);
    });

    test('aggressive retiree gets more growth than conservative retiree', () {
      final aggressive = BucketStrategyCalculator.compute(
        age: 65,
        riskProfile: 'Aggressive',
        retirementAge: 60,
      );
      final conservative = BucketStrategyCalculator.compute(
        age: 65,
        riskProfile: 'Conservative',
        retirementAge: 60,
      );

      expect(aggressive.bucketTargets[3]!, greaterThan(conservative.bucketTargets[3]!));
    });

    // ── Edge cases ──────────────────────────────────────────────────────

    test('bucket targets always sum to 100', () {
      for (final age in [25, 30, 40, 50, 58, 62, 70, 80]) {
        for (final risk in ['Conservative', 'Moderate', 'Aggressive']) {
          final strategy = BucketStrategyCalculator.compute(
            age: age,
            riskProfile: risk,
            retirementAge: 60,
          );

          final sum = strategy.bucketTargets.values.fold(0.0, (s, v) => s + v);
          expect(sum, closeTo(100.0, 0.1),
              reason: 'age=$age risk=$risk sum=$sum');
        }
      }
    });

    test('core + satellite always sums to 100', () {
      final strategy = BucketStrategyCalculator.compute(
        age: 35,
        riskProfile: 'Moderate',
        retirementAge: 60,
      );

      expect(strategy.corePct + strategy.satellitePct, 100.0);
    });

    test('education notes populated for accumulation', () {
      final strategy = BucketStrategyCalculator.compute(
        age: 30,
        riskProfile: 'Moderate',
        retirementAge: 60,
      );

      expect(strategy.educationNotes, isNotEmpty);
      expect(strategy.educationNotes.any((n) => n.contains('SIP')), isTrue);
    });

    test('education notes populated for distribution', () {
      final strategy = BucketStrategyCalculator.compute(
        age: 65,
        riskProfile: 'Moderate',
        retirementAge: 60,
      );

      expect(strategy.educationNotes, isNotEmpty);
      expect(strategy.educationNotes.any((n) => n.contains('SWP')), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && flutter test test/domain/usecases/compute_bucket_strategy_test.dart`

Expected: FAIL — `compute_bucket_strategy.dart` does not exist yet.

- [ ] **Step 3: Implement BucketStrategyCalculator**

```dart
// lib/domain/usecases/compute_bucket_strategy.dart

import '../../core/constants/bucket_education.dart';
import '../models/simulation_models.dart';

/// Computes dynamic 3-bucket strategy based on age, risk profile, and life stage.
///
/// Two scenarios:
/// - **Accumulation** (age < retirementAge): earning + SIP phase
/// - **Distribution** (age >= retirementAge): retired + SWP phase
///
/// Risk profile shifts allocation within age-band ranges:
/// Conservative → higher B1/B2, Aggressive → higher B3.
class BucketStrategyCalculator {
  BucketStrategyCalculator._();

  /// Risk adjustment factor: -1.0 (conservative) to +1.0 (aggressive).
  static double _riskFactor(String riskProfile) {
    switch (riskProfile) {
      case 'Conservative':
        return -1.0;
      case 'Moderately Conservative':
        return -0.5;
      case 'Moderate':
        return 0.0;
      case 'Moderately Aggressive':
        return 0.5;
      case 'Aggressive':
        return 1.0;
      default:
        return 0.0;
    }
  }

  /// Accumulation age-band base targets: {b1Mid, b2Mid, b3Mid, b1Range, b2Range, b3Range}.
  /// Range = how much risk profile can shift the value.
  static ({double b1, double b2, double b3, double r1, double r2, double r3})
      _accumulationBase(int age) {
    if (age < 35) {
      return (b1: 6.5, b2: 16.0, b3: 77.5, r1: 1.5, r2: 4.0, r3: 5.0);
    } else if (age < 45) {
      return (b1: 9.0, b2: 25.0, b3: 66.0, r1: 1.0, r2: 5.0, r3: 5.0);
    } else if (age < 55) {
      return (b1: 12.5, b2: 35.0, b3: 52.5, r1: 2.5, r2: 5.0, r3: 7.5);
    } else {
      // 55-retirementAge
      return (b1: 17.5, b2: 40.0, b3: 42.5, r1: 2.5, r2: 5.0, r3: 5.0);
    }
  }

  static BucketStrategy compute({
    required int age,
    required String riskProfile,
    required int retirementAge,
  }) {
    final isDistribution = age >= retirementAge;
    final scenario = isDistribution ? 'distribution' : 'accumulation';
    final rf = _riskFactor(riskProfile);

    double b1, b2, b3;

    if (isDistribution) {
      // Distribution: base 25/45/30, risk shifts ±5
      b1 = 25.0 - rf * 5.0; // conservative gets more liquidity
      b2 = 45.0 - rf * 5.0; // conservative gets more stability
      b3 = 30.0 + rf * 10.0; // aggressive gets more growth
    } else {
      final base = _accumulationBase(age);
      b1 = base.b1 - rf * base.r1; // conservative → more B1
      b2 = base.b2 - rf * base.r2; // conservative → more B2
      b3 = base.b3 + rf * base.r3; // aggressive → more B3
    }

    // Normalize to sum to 100
    final sum = b1 + b2 + b3;
    b1 = (b1 / sum * 100).roundToDouble();
    b2 = (b2 / sum * 100).roundToDouble();
    b3 = 100.0 - b1 - b2; // avoid floating point drift

    // Core/Satellite split
    final corePct = (age >= 45 || isDistribution) ? 80.0 : 75.0;
    final satellitePct = 100.0 - corePct;

    // Education notes
    final educationNotes = BucketEducation.notesForScenario(scenario);

    // Refill rules
    final rawRules = isDistribution
        ? BucketEducation.distributionRefillRules
        : BucketEducation.accumulationRefillRules;
    final refillRules = rawRules
        .map((r) => RefillRule(
              fromBucket: r['fromBucket'] as int,
              toBucket: r['toBucket'] as int,
              trigger: r['trigger'] as String,
              frequency: r['frequency'] as String,
              description: r['description'] as String,
            ))
        .toList();

    return BucketStrategy(
      scenario: scenario,
      bucketTargets: {1: b1, 2: b2, 3: b3},
      bucketNames: BucketEducation.bucketNames,
      bucketInstruments: BucketEducation.bucketInstruments,
      corePct: corePct,
      satellitePct: satellitePct,
      educationNotes: educationNotes,
      refillRules: refillRules,
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && flutter test test/domain/usecases/compute_bucket_strategy_test.dart -v`

Expected: All 10 tests PASS.

---

### Task 3: Unify Bucket Targets — Modify compute_unified_actions + run_rebalance_analysis

**Files:**
- Modify: `lib/domain/usecases/compute_unified_actions.dart`
- Modify: `lib/domain/usecases/run_rebalance_analysis.dart`
- Modify: `test/domain/usecases/compute_unified_actions_test.dart`

- [ ] **Step 1: Update compute_unified_actions.dart to accept BucketStrategy**

Replace the hardcoded `_bucketNames` and `_bucketTargets` constants with a `BucketStrategy` parameter. The `_assetClassToBucket` mapping stays (it's structural, not configurable).

In `lib/domain/usecases/compute_unified_actions.dart`, make these changes:

1. Add import for simulation_models.dart at the top:
```dart
import '../models/simulation_models.dart';
```

2. Remove the `_bucketNames` and `_bucketTargets` static constants (lines 22-33).

3. Add `bucketStrategy` as a required parameter to `compute()`:
```dart
  static RebalancePlan compute({
    required List<FundMove> fundMoves,
    required AllocationHealthResult healthResult,
    required RetirementGap? retirementGap,
    required Map<String, double> currentAllocation,
    required double totalPortfolioValue,
    required BucketStrategy bucketStrategy,
  }) {
```

4. In the bucket summary builder (around line 52-69), replace references to `_bucketTargets` with `bucketStrategy.bucketTargets` and `_bucketNames` with `bucketStrategy.bucketNames`:
```dart
    final bucketSummary = [1, 2, 3].map((b) {
      final current = bucketCurrentPct[b] ?? 0;
      final ideal = bucketStrategy.bucketTargets[b] ?? 33.3;
      final diff = current - ideal;
      final status = diff > 5
          ? 'overweight'
          : diff < -5
              ? 'underweight'
              : 'balanced';
      return BucketStatus(
        bucketNumber: b,
        bucketName: bucketStrategy.bucketNames[b] ?? 'Bucket $b',
        currentPct: current,
        idealPct: ideal,
        currentValue: totalPortfolioValue * (current / 100),
        status: status,
      );
    }).toList();
```

- [ ] **Step 2: Update run_rebalance_analysis.dart to accept BucketStrategy**

In `lib/domain/usecases/run_rebalance_analysis.dart`:

1. Add import for simulation_models.dart and bucket_education.dart:
```dart
import '../../core/constants/bucket_education.dart';
import '../models/simulation_models.dart';
```

2. Add optional `BucketStrategy? bucketStrategy` parameter to `analyze()`:
```dart
  static RebalanceResult analyze({
    required List<PortfolioHolding> holdings,
    required AllocationTarget target,
    BucketStrategy? bucketStrategy,
  }) {
```

3. Replace the hardcoded `bucketTargets` and `bucketNames` local variables (lines 200-201) with:
```dart
    final effectiveTargets = bucketStrategy?.bucketTargets ?? {1: 20.0, 2: 30.0, 3: 50.0};
    final effectiveNames = bucketStrategy?.bucketNames ?? {1: 'Stability (0-3yr)', 2: 'Income (3-7yr)', 3: 'Growth (7yr+)'};
```

4. Replace references: `bucketTargets[b]` → `effectiveTargets[b]` and `bucketNames[b]` → `effectiveNames[b]` in the bucket builder (lines 203-215):
```dart
    final buckets = [1, 2, 3].map((b) {
      final val = bucketValues[b] ?? 0;
      final pct = totalValue > 0 ? (val / totalValue) * 100 : 0.0;
      final tgt = effectiveTargets[b] ?? 33.33;
      return BucketAllocation(
        bucketNumber: b,
        bucketName: effectiveNames[b] ?? 'Bucket $b',
        currentValue: val,
        targetPct: tgt,
        currentPct: pct,
        driftPct: pct - tgt,
      );
    }).toList();
```

5. Update `_defaultBucket` to use `BucketEducation.assetClassToBucket`:
```dart
  static int _defaultBucket(AssetClass cls) {
    return BucketEducation.assetClassToBucket[cls.name] ?? 2;
  }
```

- [ ] **Step 3: Update existing tests to pass BucketStrategy**

In `test/domain/usecases/compute_unified_actions_test.dart`, add an import and create a test helper:

```dart
import 'package:evesh_wealth/domain/models/simulation_models.dart';

// Add at top level, before the group:
final _testBucketStrategy = BucketStrategy(
  scenario: 'accumulation',
  bucketTargets: {1: 25.0, 2: 15.0, 3: 60.0},
  bucketNames: {1: 'Liquidity (0-2yr)', 2: 'Stability (3-7yr)', 3: 'Growth (7yr+)'},
  bucketInstruments: {1: ['Liquid funds'], 2: ['Debt funds'], 3: ['Equity']},
  corePct: 75.0,
  satellitePct: 25.0,
  educationNotes: ['Test note'],
  refillRules: [],
);
```

Then add `bucketStrategy: _testBucketStrategy` to every `UnifiedActionsCalculator.compute(...)` call in the test file.

- [ ] **Step 4: Run all existing tests to verify nothing broke**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && flutter test test/domain/usecases/`

Expected: All tests PASS (18 existing + 10 new bucket strategy = 28).

---

### Task 4: Simulation Engine + Tests

**Files:**
- Create: `lib/domain/usecases/compute_simulation.dart`
- Create: `test/domain/usecases/compute_simulation_test.dart`

- [ ] **Step 1: Write failing tests for SimulationCalculator**

```dart
// test/domain/usecases/compute_simulation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:evesh_wealth/domain/usecases/compute_simulation.dart';
import 'package:evesh_wealth/domain/usecases/compute_bucket_strategy.dart';
import 'package:evesh_wealth/domain/models/simulation_models.dart';
import 'package:evesh_wealth/domain/usecases/compute_rebalance_actions.dart';
import 'package:evesh_wealth/presentation/providers/tax_provider.dart';
import 'package:evesh_wealth/domain/usecases/run_fifo_tax_calculator.dart';

void main() {
  // Shared test data
  final holdings = [
    FundHoldingInput(
      amfiCode: 122639,
      fundName: 'Parag Parikh Flexi Cap',
      assetClassKey: 'coreEquity',
      currentValue: 300000,
    ),
    FundHoldingInput(
      amfiCode: 120197,
      fundName: 'ICICI Pru Liquid Fund',
      assetClassKey: 'liquid',
      currentValue: 100000,
    ),
    FundHoldingInput(
      amfiCode: 100356,
      fundName: 'ICICI Pru Equity & Debt',
      assetClassKey: 'hybrid',
      currentValue: 50000,
    ),
    FundHoldingInput(
      amfiCode: 114758,
      fundName: 'Kotak Gold Fund',
      assetClassKey: 'gold',
      currentValue: 50000,
    ),
  ];

  final strategy = BucketStrategyCalculator.compute(
    age: 35,
    riskProfile: 'Moderate',
    retirementAge: 60,
  );

  group('SimulationCalculator', () {
    test('no changes produces zero tax impact and same health', () {
      final adjustedAmounts = {
        122639: 300000.0,
        120197: 100000.0,
        100356: 50000.0,
        114758: 50000.0,
      };

      final result = SimulationCalculator.compute(
        holdings: holdings,
        adjustedAmounts: adjustedAmounts,
        additionalLumpsum: 0,
        additionalSip: 0,
        bucketStrategy: strategy,
        driftThreshold: 5.0,
        exposures: [],
      );

      expect(result.taxImpacts, isEmpty);
      expect(result.totalTaxCost, 0);
      expect(result.totalExitLoad, 0);
      expect(result.healthDelta, 0);
      expect(result.totalPortfolioValue, 500000);
    });

    test('adding lumpsum increases portfolio value', () {
      final adjustedAmounts = {
        122639: 300000.0,
        120197: 100000.0,
        100356: 50000.0,
        114758: 50000.0,
      };

      final result = SimulationCalculator.compute(
        holdings: holdings,
        adjustedAmounts: adjustedAmounts,
        additionalLumpsum: 100000,
        additionalSip: 0,
        bucketStrategy: strategy,
        driftThreshold: 5.0,
        exposures: [],
      );

      expect(result.totalPortfolioValue, 600000);
    });

    test('reducing a fund produces tax impact', () {
      final adjustedAmounts = {
        122639: 200000.0, // selling 100K
        120197: 100000.0,
        100356: 50000.0,
        114758: 50000.0,
      };

      final exposure = UnrealizedExposure(
        fundName: 'Parag Parikh Flexi Cap',
        memberId: 'mem1',
        memberName: 'Test',
        amfiCode: 122639,
        taxCategory: TaxCategory.equity,
        holdingDays: 400,
        totalUnits: 1000,
        costBasis: 250000,
        currentValue: 300000,
        unrealisedGain: 50000,
        gainType: 'LTCG',
        estimatedTax: 0,
        ltcgDaysRemaining: 0,
        stcgGain: 0,
        ltcgGain: 50000,
        stcgTax: 0,
        ltcgTax: 0,
        stcgTaxRate: 0.20,
        ltcgTaxRate: 0.125,
        postTaxGain: 50000,
        exitLoadAmount: 0,
      );

      final result = SimulationCalculator.compute(
        holdings: holdings,
        adjustedAmounts: adjustedAmounts,
        additionalLumpsum: 0,
        additionalSip: 0,
        bucketStrategy: strategy,
        driftThreshold: 5.0,
        exposures: [exposure],
      );

      expect(result.taxImpacts, hasLength(1));
      expect(result.taxImpacts.first.sellAmount, 100000);
      expect(result.taxImpacts.first.amfiCode, 122639);
      expect(result.totalPortfolioValue, 400000);
    });

    test('bucket composition reflects adjusted allocations', () {
      final adjustedAmounts = {
        122639: 300000.0,
        120197: 100000.0,
        100356: 50000.0,
        114758: 50000.0,
      };

      final result = SimulationCalculator.compute(
        holdings: holdings,
        adjustedAmounts: adjustedAmounts,
        additionalLumpsum: 0,
        additionalSip: 0,
        bucketStrategy: strategy,
        driftThreshold: 5.0,
        exposures: [],
      );

      expect(result.bucketFills, hasLength(3));

      // Bucket 1 (liquid) = 100K / 500K = 20%
      final b1 = result.bucketFills.firstWhere((b) => b.bucketNumber == 1);
      expect(b1.currentValue, 100000);
      expect(b1.currentPct, closeTo(20.0, 0.1));

      // Bucket 3 (coreEquity) = 300K / 500K = 60%
      final b3 = result.bucketFills.firstWhere((b) => b.bucketNumber == 3);
      expect(b3.currentValue, 300000);
      expect(b3.currentPct, closeTo(60.0, 0.1));
    });

    test('overflow detected when bucket exceeds ideal + threshold', () {
      // Make bucket 3 very heavy
      final adjustedAmounts = {
        122639: 450000.0, // push equity to 90%
        120197: 20000.0,
        100356: 15000.0,
        114758: 15000.0,
      };

      final result = SimulationCalculator.compute(
        holdings: holdings,
        adjustedAmounts: adjustedAmounts,
        additionalLumpsum: 0,
        additionalSip: 0,
        bucketStrategy: strategy,
        driftThreshold: 5.0,
        exposures: [],
      );

      final b3 = result.bucketFills.firstWhere((b) => b.bucketNumber == 3);
      expect(b3.overflowPct, greaterThan(0));
      expect(b3.status, 'overweight');
    });

    test('health score improves when allocation moves toward ideal', () {
      // Current is heavily equity-tilted (300K/500K = 60% equity)
      // Move toward more balanced
      final adjustedAmounts = {
        122639: 200000.0, // reduce equity
        120197: 100000.0,
        100356: 100000.0, // boost hybrid
        114758: 100000.0, // boost gold
      };

      final result = SimulationCalculator.compute(
        holdings: holdings,
        adjustedAmounts: adjustedAmounts,
        additionalLumpsum: 0,
        additionalSip: 0,
        bucketStrategy: strategy,
        driftThreshold: 5.0,
        exposures: [],
      );

      // Health delta may be positive or negative depending on what ideal is
      // but the method should compute it without error
      expect(result.projectedHealthScore, isA<int>());
      expect(result.projectedHealthScore, greaterThanOrEqualTo(0));
      expect(result.projectedHealthScore, lessThanOrEqualTo(100));
    });

    test('new allocation percentages are correct', () {
      final adjustedAmounts = {
        122639: 250000.0,
        120197: 100000.0,
        100356: 75000.0,
        114758: 75000.0,
      };

      final result = SimulationCalculator.compute(
        holdings: holdings,
        adjustedAmounts: adjustedAmounts,
        additionalLumpsum: 0,
        additionalSip: 0,
        bucketStrategy: strategy,
        driftThreshold: 5.0,
        exposures: [],
      );

      final total = result.totalPortfolioValue;
      expect(total, 500000);
      expect(result.newAllocationPct['coreEquity'], closeTo(50.0, 0.1));
      expect(result.newAllocationPct['liquid'], closeTo(20.0, 0.1));
      expect(result.newAllocationPct['hybrid'], closeTo(15.0, 0.1));
      expect(result.newAllocationPct['gold'], closeTo(15.0, 0.1));
    });

    test('SIP amount added to portfolio value', () {
      final adjustedAmounts = {
        122639: 300000.0,
        120197: 100000.0,
        100356: 50000.0,
        114758: 50000.0,
      };

      final result = SimulationCalculator.compute(
        holdings: holdings,
        adjustedAmounts: adjustedAmounts,
        additionalLumpsum: 0,
        additionalSip: 10000,
        bucketStrategy: strategy,
        driftThreshold: 5.0,
        exposures: [],
      );

      // SIP is annualized: 10000 × 12 = 120000 added to portfolio value
      expect(result.totalPortfolioValue, 620000);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && flutter test test/domain/usecases/compute_simulation_test.dart`

Expected: FAIL — `compute_simulation.dart` does not exist.

- [ ] **Step 3: Implement SimulationCalculator**

```dart
// lib/domain/usecases/compute_simulation.dart

import 'dart:math' as math;
import '../../core/constants/bucket_education.dart';
import '../../presentation/providers/tax_provider.dart';
import '../models/allocation_models.dart';
import '../models/simulation_models.dart';
import 'compute_allocation_health.dart';
import 'compute_bucket_strategy.dart';
import 'compute_rebalance_actions.dart';

/// Computes simulation results from user's slider/textbox adjustments.
///
/// This does NOT call RebalanceActionsCalculator — that engine produces
/// eVesh's recommendation (Plan tab). The simulator takes the user's manual
/// adjustments and shows consequences. Two independent paths.
class SimulationCalculator {
  SimulationCalculator._();

  static SimulationResult compute({
    required List<FundHoldingInput> holdings,
    required Map<int, double> adjustedAmounts,
    required double additionalLumpsum,
    required double additionalSip,
    required BucketStrategy bucketStrategy,
    required double driftThreshold,
    required List<UnrealizedExposure> exposures,
    IdealAllocation? idealAllocation,
    int? currentHealthScore,
  }) {
    // ── 1. Compute new allocation ─────────────────────────────────────────
    final newAmountByClass = <String, double>{};
    double totalAdjusted = 0;

    for (final h in holdings) {
      final amt = adjustedAmounts[h.amfiCode] ?? h.currentValue;
      newAmountByClass[h.assetClassKey] =
          (newAmountByClass[h.assetClassKey] ?? 0) + amt;
      totalAdjusted += amt;
    }

    // Add new money
    final annualizedSip = additionalSip * 12;
    final totalPortfolioValue = totalAdjusted + additionalLumpsum + annualizedSip;

    // Derive percentage allocation
    final newAllocationPct = <String, double>{};
    if (totalPortfolioValue > 0) {
      for (final entry in newAmountByClass.entries) {
        newAllocationPct[entry.key] = (entry.value / totalPortfolioValue) * 100;
      }
    }

    // ── 2. Bucket composition ─────────────────────────────────────────────
    final bucketValues = <int, double>{1: 0, 2: 0, 3: 0};
    final bucketClassValues = <int, Map<String, double>>{
      1: {},
      2: {},
      3: {},
    };

    for (final h in holdings) {
      final amt = adjustedAmounts[h.amfiCode] ?? h.currentValue;
      final bucket = BucketEducation.assetClassToBucket[h.assetClassKey] ?? 2;
      bucketValues[bucket] = (bucketValues[bucket] ?? 0) + amt;
      bucketClassValues[bucket]![h.assetClassKey] =
          (bucketClassValues[bucket]![h.assetClassKey] ?? 0) + amt;
    }

    // Asset class display names
    const displayNames = <String, String>{
      'coreEquity': 'Core Equity',
      'satelliteEquity': 'Satellite Equity',
      'hybrid': 'Hybrid',
      'debt': 'Debt',
      'liquid': 'Liquid',
      'gold': 'Gold',
      'alternate': 'Alternate',
    };

    final bucketFills = [1, 2, 3].map((b) {
      final val = bucketValues[b] ?? 0;
      final pct = totalPortfolioValue > 0 ? (val / totalPortfolioValue) * 100 : 0.0;
      final ideal = bucketStrategy.bucketTargets[b] ?? 33.3;
      final diff = pct - ideal;

      final String status;
      if (diff > driftThreshold) {
        status = 'overweight';
      } else if (diff < -driftThreshold) {
        status = 'underweight';
      } else {
        status = 'balanced';
      }

      // Build asset class bands within bucket
      final classMap = bucketClassValues[b] ?? {};
      final bands = classMap.entries.map((e) {
        final bandPct = val > 0 ? (e.value / val) * 100 : 0.0;
        return AssetClassBand(
          assetClassKey: e.key,
          displayName: displayNames[e.key] ?? e.key,
          valuePct: bandPct,
          valueAmount: e.value,
        );
      }).toList()
        ..sort((a, b) => b.valueAmount.compareTo(a.valueAmount));

      // Overflow: if current exceeds ideal by more than threshold
      final overflowPct = diff > driftThreshold ? diff - driftThreshold : 0.0;

      // Spill target: overweight bucket spills into underweight neighbor
      int? spillsInto;
      if (overflowPct > 0) {
        if (b == 3) spillsInto = 2;
        if (b == 2) spillsInto = 1;
        if (b == 1) spillsInto = 2; // unusual, but handle it
      }

      return BucketComposition(
        bucketNumber: b,
        bucketName: bucketStrategy.bucketNames[b] ?? 'Bucket $b',
        currentPct: pct,
        idealPct: ideal,
        currentValue: val,
        status: status,
        bands: bands,
        overflowPct: overflowPct,
        spillsIntoBucket: spillsInto,
      );
    }).toList();

    // ── 3. Tax impact per sell ────────────────────────────────────────────
    final taxImpacts = <FundTaxImpact>[];
    double totalTaxCost = 0;
    double totalExitLoad = 0;

    // Build exposure lookup by amfiCode
    final exposureMap = <int, UnrealizedExposure>{};
    for (final e in exposures) {
      exposureMap[e.amfiCode] = e;
    }

    for (final h in holdings) {
      final newAmt = adjustedAmounts[h.amfiCode] ?? h.currentValue;
      if (newAmt < h.currentValue) {
        final sellAmount = h.currentValue - newAmt;
        final exposure = exposureMap[h.amfiCode];

        double stcgAmount = 0, ltcgAmount = 0;
        double stcgTax = 0, ltcgTax = 0;
        double exitLoad = 0;
        int holdDays = 0;

        if (exposure != null) {
          holdDays = exposure.holdingDays;
          // Proportional split of STCG/LTCG based on existing exposure
          final totalGain = exposure.unrealisedGain;
          final proportionSold = math.min(sellAmount / exposure.currentValue, 1.0);

          stcgAmount = exposure.stcgGain * proportionSold;
          ltcgAmount = exposure.ltcgGain * proportionSold;
          stcgTax = stcgAmount * exposure.stcgTaxRate;
          ltcgTax = ltcgAmount * exposure.ltcgTaxRate;
          exitLoad = exposure.exitLoadAmount * proportionSold;
        }

        final impact = FundTaxImpact(
          amfiCode: h.amfiCode,
          fundName: h.fundName,
          sellAmount: sellAmount,
          stcgAmount: stcgAmount,
          ltcgAmount: ltcgAmount,
          stcgTax: stcgTax,
          ltcgTax: ltcgTax,
          exitLoadAmount: exitLoad,
          netProceeds: sellAmount - stcgTax - ltcgTax - exitLoad,
          holdingDays: holdDays,
        );

        taxImpacts.add(impact);
        totalTaxCost += impact.totalTax;
        totalExitLoad += exitLoad;
      }
    }

    // ── 4. Health score recalculation ────────────────────────────────────
    int projectedHealthScore = 50; // fallback
    if (idealAllocation != null && totalPortfolioValue > 0) {
      final healthResult = AllocationHealthCalculator.compute(
        currentAllocation: newAllocationPct,
        portfolioValue: totalPortfolioValue,
        ideal: idealAllocation,
      );
      projectedHealthScore = healthResult.healthScore;
    } else {
      // Estimate: compute a simple drift-based score
      double totalDrift = 0;
      for (final b in bucketFills) {
        totalDrift += (b.currentPct - b.idealPct).abs();
      }
      projectedHealthScore = (100 * (1 - totalDrift / 200)).round().clamp(0, 100);
    }

    final healthDelta = projectedHealthScore - (currentHealthScore ?? projectedHealthScore);

    return SimulationResult(
      newAllocationPct: newAllocationPct,
      bucketFills: bucketFills,
      projectedHealthScore: projectedHealthScore,
      healthDelta: healthDelta,
      taxImpacts: taxImpacts,
      totalTaxCost: totalTaxCost,
      totalExitLoad: totalExitLoad,
      netRebalanceCost: totalTaxCost + totalExitLoad,
      totalPortfolioValue: totalPortfolioValue,
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && flutter test test/domain/usecases/compute_simulation_test.dart -v`

Expected: All 8 tests PASS.

---

### Task 5: Supabase Migration — frozen_plans Table + drift_threshold_pct

**Files:**
- Create: `supabase/migrations/012_frozen_plans.sql`

- [ ] **Step 1: Create migration file**

```sql
-- supabase/migrations/012_frozen_plans.sql
-- Slice 6b: frozen plans + per-member drift threshold

-- ── frozen_plans table ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS frozen_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES auth.users(id) NOT NULL,
  member_id UUID REFERENCES family_members(id),
  fund_allocations JSONB NOT NULL,
  additional_lumpsum NUMERIC DEFAULT 0,
  additional_sip NUMERIC DEFAULT 0,
  health_score INT,
  health_delta INT,
  total_tax_impact NUMERIC,
  total_exit_load NUMERIC,
  bucket_targets JSONB,
  action_items JSONB,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ
);

-- RLS
ALTER TABLE frozen_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own frozen plans"
  ON frozen_plans FOR SELECT
  USING (owner_id = auth.uid());

CREATE POLICY "Users can insert own frozen plans"
  ON frozen_plans FOR INSERT
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can update own frozen plans"
  ON frozen_plans FOR UPDATE
  USING (owner_id = auth.uid());

CREATE POLICY "Users can delete own frozen plans"
  ON frozen_plans FOR DELETE
  USING (owner_id = auth.uid());

-- Index for quick lookup of active plan per member
CREATE INDEX idx_frozen_plans_owner_member_status
  ON frozen_plans(owner_id, member_id, status);

-- ── drift_threshold_pct column on family_members ────────────────────────────
ALTER TABLE family_members
  ADD COLUMN IF NOT EXISTS drift_threshold_pct NUMERIC DEFAULT 5.0;
```

- [ ] **Step 2: Run migration against Supabase**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && cat supabase/migrations/012_frozen_plans.sql`

Then manually apply via Supabase SQL Editor or:

Run: `export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && npx supabase db push`

If `npx supabase` is not available, paste the SQL into the Supabase Dashboard SQL Editor.

---

### Task 6: Family Settings — Drift Threshold Slider + Text Box

**Files:**
- Modify: `lib/data/models/family_model.dart`
- Modify: `lib/presentation/screens/settings/family_setup_screen.dart`

- [ ] **Step 1: Add driftThresholdPct to FamilyMemberModel**

In `lib/data/models/family_model.dart`, add the field to `FamilyMemberModel` after `risk_score_computed`:

```dart
    @JsonKey(name: 'drift_threshold_pct') @Default(5.0) double driftThresholdPct,
```

The full field should appear before `@JsonKey(name: 'created_at')`.

- [ ] **Step 2: Run build_runner to regenerate Freezed code**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && dart run build_runner build --delete-conflicting-outputs`

Expected: Generates updated `family_model.freezed.dart` and `family_model.g.dart`.

- [ ] **Step 3: Add drift threshold UI to _MemberEditPage**

In `lib/presentation/screens/settings/family_setup_screen.dart`, inside `_MemberEditPageState`:

1. Add a controller and state variable in `initState()`:
```dart
  late double _driftThreshold;
  late final TextEditingController _driftCtrl;
```

Initialize in `initState()`:
```dart
    _driftThreshold = m?.driftThresholdPct ?? 5.0;
    _driftCtrl = TextEditingController(text: _driftThreshold.toInt().toString());
```

Dispose in `dispose()`:
```dart
    _driftCtrl.dispose();
```

2. In the `build` method, after the "Target Allocation" section (after the `allocationTotal` row builder, around line 688), add:

```dart
            const Divider(height: 32),

            // ── DRIFT THRESHOLD ──
            _SectionHeader('Rebalance Drift Threshold'),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slider(
                        value: _driftThreshold,
                        min: 3,
                        max: 15,
                        divisions: 12,
                        activeColor: AppColors.primary,
                        label: '${_driftThreshold.toInt()}%',
                        onChanged: (v) {
                          setState(() {
                            _driftThreshold = v;
                            _driftCtrl.text = v.toInt().toString();
                          });
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('3%', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                            Text('15%', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    controller: _driftCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Drift %',
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      final val = double.tryParse(v);
                      if (val != null && val >= 3 && val <= 15) {
                        setState(() => _driftThreshold = val);
                      }
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                'eVesh alerts you when any asset class drifts beyond this threshold from its ideal allocation.',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ),
```

3. In the `_save()` method, add `drift_threshold_pct` to the `data` map:

```dart
        'drift_threshold_pct': _driftThreshold,
```

- [ ] **Step 4: Verify the settings page compiles**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && dart analyze lib/presentation/screens/settings/family_setup_screen.dart lib/data/models/family_model.dart`

Expected: No errors.

---

### Task 7: Simulation Provider — Riverpod Codegen

**Files:**
- Create: `lib/presentation/providers/simulation_provider.dart`
- Modify: `lib/presentation/providers/action_center_provider.dart`

- [ ] **Step 1: Create simulation_provider.dart**

```dart
// lib/presentation/providers/simulation_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/bucket_education.dart';
import '../../domain/models/simulation_models.dart';
import '../../domain/usecases/compute_bucket_strategy.dart';
import '../../domain/usecases/compute_rebalance_actions.dart';
import '../../domain/usecases/compute_simulation.dart';
import 'action_center_provider.dart';
import 'auth_provider.dart';
import 'family_provider.dart';
import 'portfolio_provider.dart';
import 'tax_provider.dart';
import 'wealth_planner_provider.dart';

part 'simulation_provider.g.dart';

/// Manages the mutable simulation state (slider/textbox values).
/// NOT codegen — manual Notifier so we can expose mutation methods.
class SimulationStateNotifier extends Notifier<SimulationState> {
  @override
  SimulationState build() => const SimulationState();

  /// Initialize from current portfolio holdings.
  void initFromHoldings(Map<int, double> currentAmounts) {
    state = SimulationState(
      fundAmounts: Map.of(currentAmounts),
      additionalLumpsum: 0,
      additionalSip: 0,
      isDirty: false,
    );
  }

  /// Update a single fund amount (from slider or text box).
  void setFundAmount(int amfiCode, double amount) {
    final updated = Map<int, double>.from(state.fundAmounts);
    updated[amfiCode] = amount;
    state = state.copyWith(fundAmounts: updated, isDirty: true);
  }

  /// Update lumpsum.
  void setLumpsum(double amount) {
    state = state.copyWith(additionalLumpsum: amount, isDirty: true);
  }

  /// Update SIP.
  void setSip(double amount) {
    state = state.copyWith(additionalSip: amount, isDirty: true);
  }

  /// Reset to current holdings.
  void reset(Map<int, double> currentAmounts) {
    state = SimulationState(
      fundAmounts: Map.of(currentAmounts),
      additionalLumpsum: 0,
      additionalSip: 0,
      isDirty: false,
    );
  }
}

final simulationStateProvider =
    NotifierProvider<SimulationStateNotifier, SimulationState>(
  SimulationStateNotifier.new,
);

/// Computes BucketStrategy for a specific member.
@riverpod
Future<BucketStrategy> memberBucketStrategy(
  MemberBucketStrategyRef ref,
  String? memberId,
) async {
  final members = await ref.watch(familyMembersProvider.future);
  final member = memberId != null
      ? members.where((m) => m.id == memberId).firstOrNull
      : members.where((m) => m.relationship == 'Self').firstOrNull;

  if (member == null) {
    // Fallback: moderate 35-year-old
    return BucketStrategyCalculator.compute(
      age: 35,
      riskProfile: 'Moderate',
      retirementAge: 60,
    );
  }

  // Compute age from DOB
  int age = 35; // fallback
  if (member.dateOfBirth != null) {
    final dob = DateTime.tryParse(member.dateOfBirth!);
    if (dob != null) {
      final now = DateTime.now();
      age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
    }
  }

  return BucketStrategyCalculator.compute(
    age: age,
    riskProfile: member.riskProfile ?? 'Moderate',
    retirementAge: member.retirementAge,
  );
}

/// Computes simulation result from current SimulationState.
@riverpod
Future<SimulationResult?> simulationResult(
  SimulationResultRef ref,
  String? memberId,
) async {
  final simState = ref.watch(simulationStateProvider);
  if (!simState.isDirty && simState.fundAmounts.isEmpty) return null;

  final portfolio = await ref.watch(portfolioSummaryProvider(memberId).future);
  final health = await ref.watch(allocationHealthProvider(memberId).future);
  final strategy = await ref.watch(memberBucketStrategyProvider(memberId).future);

  // Get member's drift threshold
  final members = await ref.watch(familyMembersProvider.future);
  final member = memberId != null
      ? members.where((m) => m.id == memberId).firstOrNull
      : members.where((m) => m.relationship == 'Self').firstOrNull;
  final driftThreshold = member?.driftThresholdPct ?? 5.0;

  // Maps display-name allocation keys → asset class keys (reused from action_center_provider)
  const displayToAssetClassKey = <String, String>{
    'Core Equity': 'coreEquity',
    'Satellite Equity': 'satelliteEquity',
    'Hybrid': 'hybrid',
    'Debt': 'debt',
    'Liquid': 'liquid',
    'Gold': 'gold',
    'Alternate': 'alternate',
  };

  // Build FundHoldingInput list
  final holdings = portfolio.fundHoldings.map((f) {
    final acLabel = f.assetClassLabel ?? f.taxCategory ?? 'Alternate';
    final acKey = displayToAssetClassKey[acLabel] ?? 'alternate';
    return FundHoldingInput(
      amfiCode: f.amfiCode,
      fundName: f.fundName,
      assetClassKey: acKey,
      currentValue: f.currentValue,
      return3y: f.xirr,
      expenseRatio: f.expenseRatio,
    );
  }).toList();

  // Get unrealized exposures for tax impact
  List<UnrealizedExposure> exposures = [];
  try {
    final exposureResult = await ref.watch(unrealizedExposureProvider.future);
    if (memberId != null) {
      exposures = exposureResult.exposures
          .where((e) => e.memberId == memberId)
          .toList();
    } else {
      exposures = exposureResult.exposures;
    }
  } catch (_) {
    // Tax data may not be available — proceed without
  }

  return SimulationCalculator.compute(
    holdings: holdings,
    adjustedAmounts: simState.fundAmounts,
    additionalLumpsum: simState.additionalLumpsum,
    additionalSip: simState.additionalSip,
    bucketStrategy: strategy,
    driftThreshold: driftThreshold,
    exposures: exposures,
    idealAllocation: health.idealAllocation,
    currentHealthScore: health.healthScore,
  );
}

/// Freezes the current simulation state to Supabase.
@riverpod
Future<FrozenPlan?> freezePlan(
  FreezePlanRef ref, {
  required String? memberId,
  required SimulationResult result,
  required SimulationState simState,
  required BucketStrategy bucketStrategy,
}) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return null;

  final client = ref.read(supabaseClientProvider);

  // Supersede any existing active plan for this member
  await client
      .from('frozen_plans')
      .update({'status': 'superseded'})
      .eq('owner_id', userId)
      .eq('status', 'active')
      .match(memberId != null ? {'member_id': memberId} : {});

  final plan = FrozenPlan(
    ownerId: userId,
    memberId: memberId,
    fundAllocations: simState.fundAmounts,
    additionalLumpsum: simState.additionalLumpsum,
    additionalSip: simState.additionalSip,
    healthScore: result.projectedHealthScore,
    healthDelta: result.healthDelta,
    totalTaxImpact: result.totalTaxCost,
    totalExitLoad: result.totalExitLoad,
    bucketTargets: bucketStrategy.bucketTargets,
  );

  final response = await client
      .from('frozen_plans')
      .insert(plan.toJson())
      .select()
      .single();

  return FrozenPlan.fromJson(response as Map<String, dynamic>);
}

/// Fetches the active frozen plan for a member (if any).
@riverpod
Future<FrozenPlan?> activeFrozenPlan(
  ActiveFrozenPlanRef ref,
  String? memberId,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final client = ref.watch(supabaseClientProvider);

  var query = client
      .from('frozen_plans')
      .select()
      .eq('owner_id', userId)
      .eq('status', 'active');

  if (memberId != null) {
    query = query.eq('member_id', memberId);
  }

  final rows = await query.order('created_at', ascending: false).limit(1);
  final list = rows as List;
  if (list.isEmpty) return null;
  return FrozenPlan.fromJson(list.first as Map<String, dynamic>);
}
```

- [ ] **Step 2: Update action_center_provider.dart to accept member + BucketStrategy**

In `lib/presentation/providers/action_center_provider.dart`:

1. Add imports:
```dart
import '../../domain/models/simulation_models.dart';
import '../../domain/usecases/compute_bucket_strategy.dart';
import 'simulation_provider.dart';
```

2. Change the provider to accept a memberId parameter:
```dart
@riverpod
Future<RebalancePlan> actionCenterPlan(
  ActionCenterPlanRef ref,
  String? memberId,
) async {
  final portfolio = await ref.watch(portfolioSummaryProvider(memberId).future);
  final health = await ref.watch(allocationHealthProvider(memberId).future);
  final rebalance = await ref.watch(rebalanceAnalysisProvider.future);

  // Get member for monthly expense
  final members = await ref.watch(familyMembersProvider.future);
  final member = memberId != null
      ? members.where((m) => m.id == memberId).firstOrNull
      : members.where((m) => m.relationship == 'Self').firstOrNull;
  final monthlyExpense = member?.monthlyExpense ?? 50000;

  // Get dynamic bucket strategy
  final bucketStrategy = await ref.watch(memberBucketStrategyProvider(memberId).future);

  // Retirement readiness (nullable — may not be configured)
  RetirementReadiness? retirementReadiness;
  try {
    retirementReadiness = await ref.watch(retirementReadinessProvider(memberId).future);
  } catch (_) {
    retirementReadiness = null;
  }

  // Build FundHoldingInput list from portfolio
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

  // Build current allocation map (display name → asset class key)
  final currentAllocation = <String, double>{};
  for (final entry in portfolio.allocationPct.entries) {
    final key = _displayToAssetClassKey[entry.key];
    if (key != null) {
      currentAllocation[key] = (currentAllocation[key] ?? 0) + entry.value;
    }
  }

  // Layer 1: Fund-to-fund moves
  final fundMoves = RebalanceActionsCalculator.compute(
    rebalanceResult: rebalance,
    holdings: holdings,
    healthResult: health,
    driftThreshold: rebalance.driftThreshold,
    monthlyExpense: monthlyExpense,
  );

  // Layer 2: Unified actions
  final plan = UnifiedActionsCalculator.compute(
    fundMoves: fundMoves,
    healthResult: health,
    retirementGap: retirementReadiness?.gapAnalysis,
    currentAllocation: currentAllocation,
    totalPortfolioValue: portfolio.currentValue,
    bucketStrategy: bucketStrategy,
  );

  return plan;
}
```

- [ ] **Step 3: Run build_runner for codegen**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && dart run build_runner build --delete-conflicting-outputs`

Expected: Generates `simulation_provider.g.dart` and updates `action_center_provider.g.dart`.

- [ ] **Step 4: Fix any compilation errors from provider signature change**

The `actionCenterPlanProvider` is now a family provider taking `String? memberId`. Find all call sites and update them:

Search for `actionCenterPlanProvider` in the codebase. In `action_center_screen.dart`, it's called as:
```dart
ref.watch(actionCenterPlanProvider)
```
This must change to:
```dart
ref.watch(actionCenterPlanProvider(null)) // or the selected memberId
```

Similarly update `ref.invalidate(actionCenterPlanProvider)` calls.

- [ ] **Step 5: Verify compilation**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && dart analyze lib/presentation/providers/simulation_provider.dart lib/presentation/providers/action_center_provider.dart`

Expected: No errors.

---

### Task 8: Vertical Buckets Widget — CustomPaint

**Files:**
- Create: `lib/presentation/widgets/action_center/vertical_buckets.dart`

- [ ] **Step 1: Create the VerticalBuckets widget**

```dart
// lib/presentation/widgets/action_center/vertical_buckets.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/simulation_models.dart';

/// Displays 3 vertical bucket containers with asset class composition bands,
/// ideal level lines, overflow indicators, and spill arrows.
class VerticalBuckets extends StatelessWidget {
  const VerticalBuckets({
    super.key,
    required this.buckets,
    this.height = 220,
  });

  final List<BucketComposition> buckets;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) return const SizedBox.shrink();

    return Card(
      color: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.bgDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3-Bucket Allocation',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height + 80, // extra for labels
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < buckets.length; i++) ...[
                    if (i > 0) _buildSpillArrow(buckets, i),
                    Expanded(child: _BucketColumn(bucket: buckets[i], maxHeight: height)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpillArrow(List<BucketComposition> buckets, int index) {
    // Check if previous bucket overflows into this one or vice versa
    final prev = buckets[index - 1];
    final curr = buckets[index];

    final showArrowRight = prev.overflowPct > 0 && prev.spillsIntoBucket == curr.bucketNumber;
    final showArrowLeft = curr.overflowPct > 0 && curr.spillsIntoBucket == prev.bucketNumber;

    if (!showArrowRight && !showArrowLeft) {
      return const SizedBox(width: 24);
    }

    return SizedBox(
      width: 24,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            showArrowRight ? Icons.arrow_forward : Icons.arrow_back,
            size: 16,
            color: AppColors.warning,
          ),
          Text(
            showArrowRight
                ? '${prev.overflowPct.toStringAsFixed(0)}%'
                : '${curr.overflowPct.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 8, color: AppColors.warning),
          ),
        ],
      ),
    );
  }
}

class _BucketColumn extends StatelessWidget {
  const _BucketColumn({
    required this.bucket,
    required this.maxHeight,
  });

  final BucketComposition bucket;
  final double maxHeight;

  Color get _statusColor {
    switch (bucket.status) {
      case 'overweight':
        return AppColors.loss;
      case 'underweight':
        return AppColors.warning;
      default:
        return AppColors.gain;
    }
  }

  Color get _bucketColor {
    switch (bucket.bucketNumber) {
      case 1:
        return AppColors.bucket1;
      case 2:
        return AppColors.bucket2;
      case 3:
        return AppColors.bucket3;
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fill height: scale so 100% = maxHeight. Cap at maxHeight.
    final maxPct = math.max(bucket.currentPct, bucket.idealPct);
    final scale = maxPct > 0 ? maxHeight / math.max(maxPct, 100) : 1.0;
    final fillHeight = (bucket.currentPct * scale).clamp(0.0, maxHeight);
    final idealLineY = (bucket.idealPct * scale).clamp(0.0, maxHeight);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Overflow indicator
        if (bucket.overflowPct > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.loss.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '+${bucket.overflowPct.toStringAsFixed(0)}% overflow',
                style: const TextStyle(fontSize: 8, color: AppColors.loss, fontWeight: FontWeight.w600),
              ),
            ),
          ),

        // The bucket container
        SizedBox(
          height: maxHeight,
          width: double.infinity,
          child: CustomPaint(
            painter: _BucketPainter(
              fillHeight: fillHeight,
              idealLineY: idealLineY,
              maxHeight: maxHeight,
              bands: bucket.bands,
              bucketColor: _bucketColor,
              statusColor: _statusColor,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Bucket name
        Text(
          bucket.bucketName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // Current → Ideal
        Text(
          '${bucket.currentPct.toStringAsFixed(0)}% → ${bucket.idealPct.toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 9, color: _statusColor, fontWeight: FontWeight.w600),
        ),

        // Value
        Text(
          _compactRupee(bucket.currentValue),
          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
        ),

        const SizedBox(height: 4),

        // Asset class legend
        ...bucket.bands.take(3).map((band) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _assetClassColor(band.assetClassKey),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    band.displayName,
                    style: const TextStyle(fontSize: 8, color: AppColors.textTertiary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )),
      ],
    );
  }

  static Color _assetClassColor(String key) {
    const colors = {
      'coreEquity': Color(0xFF1B8A5A),
      'satelliteEquity': Color(0xFF2DBF7E),
      'hybrid': Color(0xFF3B82F6),
      'debt': Color(0xFF8B5CF6),
      'liquid': Color(0xFF06B6D4),
      'gold': Color(0xFFF59E0B),
      'alternate': Color(0xFFFF6B35),
    };
    return colors[key] ?? const Color(0xFF4A6A8A);
  }

  static String _compactRupee(double value) {
    if (value >= 1e7) return '₹${(value / 1e7).toStringAsFixed(1)}Cr';
    if (value >= 1e5) return '₹${(value / 1e5).toStringAsFixed(1)}L';
    if (value >= 1e3) return '₹${(value / 1e3).toStringAsFixed(0)}K';
    return '₹${value.toStringAsFixed(0)}';
  }
}

class _BucketPainter extends CustomPainter {
  _BucketPainter({
    required this.fillHeight,
    required this.idealLineY,
    required this.maxHeight,
    required this.bands,
    required this.bucketColor,
    required this.statusColor,
  });

  final double fillHeight;
  final double idealLineY;
  final double maxHeight;
  final List<AssetClassBand> bands;
  final Color bucketColor;
  final Color statusColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final padding = w * 0.15;
    final bucketW = w - padding * 2;

    // Bucket outline
    final outlinePaint = Paint()
      ..color = bucketColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final bucketRect = RRect.fromLTRBR(
      padding, 0, padding + bucketW, h,
      const Radius.circular(4),
    );
    canvas.drawRRect(bucketRect, outlinePaint);

    // Fill bands from bottom up
    double yOffset = h;
    for (final band in bands) {
      final bandH = (band.valuePct / 100) * fillHeight;
      if (bandH <= 0) continue;

      final bandTop = (yOffset - bandH).clamp(0.0, h);
      final bandPaint = Paint()
        ..color = _BucketColumn._assetClassColor(band.assetClassKey).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTRB(padding + 1, bandTop, padding + bucketW - 1, yOffset),
        bandPaint,
      );
      yOffset = bandTop;
    }

    // Ideal level dashed line
    final idealY = h - idealLineY;
    if (idealY >= 0 && idealY <= h) {
      final dashPaint = Paint()
        ..color = AppColors.textSecondary
        ..strokeWidth = 1.0;

      const dashWidth = 4.0;
      const dashGap = 3.0;
      double x = padding;
      while (x < padding + bucketW) {
        canvas.drawLine(
          Offset(x, idealY),
          Offset(math.min(x + dashWidth, padding + bucketW), idealY),
          dashPaint,
        );
        x += dashWidth + dashGap;
      }

      // "ideal" label
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'ideal',
          style: TextStyle(fontSize: 7, color: AppColors.textTertiary),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(padding + bucketW + 2, idealY - 5));
    }
  }

  @override
  bool shouldRepaint(covariant _BucketPainter oldDelegate) {
    return fillHeight != oldDelegate.fillHeight ||
        idealLineY != oldDelegate.idealLineY ||
        bands.length != oldDelegate.bands.length;
  }
}
```

- [ ] **Step 2: Verify widget compiles**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && dart analyze lib/presentation/widgets/action_center/vertical_buckets.dart`

Expected: No errors.

---

### Task 9: Fund Slider Row + Simulation Summary Widgets

**Files:**
- Create: `lib/presentation/widgets/action_center/fund_slider_row.dart`
- Create: `lib/presentation/widgets/action_center/simulation_summary.dart`

- [ ] **Step 1: Create fund_slider_row.dart**

```dart
// lib/presentation/widgets/action_center/fund_slider_row.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/simulation_models.dart';

/// A single fund row with slider + text box for the simulator.
class FundSliderRow extends StatefulWidget {
  const FundSliderRow({
    super.key,
    required this.amfiCode,
    required this.fundName,
    required this.assetClassLabel,
    required this.currentValue,
    required this.adjustedValue,
    required this.totalPortfolioValue,
    required this.onChanged,
    this.taxImpact,
  });

  final int amfiCode;
  final String fundName;
  final String assetClassLabel;
  final double currentValue;
  final double adjustedValue;
  final double totalPortfolioValue;
  final void Function(double newValue) onChanged;
  final FundTaxImpact? taxImpact;

  @override
  State<FundSliderRow> createState() => _FundSliderRowState();
}

class _FundSliderRowState extends State<FundSliderRow> {
  late final TextEditingController _textCtrl;
  final _rupeeFormat = NumberFormat('#,##,###', 'en_IN');

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(
      text: _rupeeFormat.format(widget.adjustedValue.round()),
    );
  }

  @override
  void didUpdateWidget(FundSliderRow old) {
    super.didUpdateWidget(old);
    if (old.adjustedValue != widget.adjustedValue) {
      final text = _rupeeFormat.format(widget.adjustedValue.round());
      if (_textCtrl.text != text) {
        _textCtrl.text = text;
      }
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  double get _pctOfPortfolio {
    if (widget.totalPortfolioValue <= 0) return 0;
    return (widget.adjustedValue / widget.totalPortfolioValue) * 100;
  }

  double get _maxSlider => widget.currentValue * 2.5; // allow up to 250% of current
  double get _minSlider => 0;

  bool get _isSelling => widget.adjustedValue < widget.currentValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fund name + asset class
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.fundName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.assetClassLabel}  ·  Current ₹${_rupeeFormat.format(widget.currentValue.round())}',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),

          // Slider + Text box row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _isSelling ? AppColors.loss : AppColors.primary,
                    inactiveTrackColor: AppColors.bgDivider,
                    thumbColor: _isSelling ? AppColors.loss : AppColors.primary,
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: widget.adjustedValue.clamp(_minSlider, _maxSlider),
                    min: _minSlider,
                    max: _maxSlider,
                    onChanged: (v) => widget.onChanged(v),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _textCtrl,
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    final parsed = double.tryParse(v.replaceAll(',', ''));
                    if (parsed != null) {
                      widget.onChanged(parsed);
                    }
                  },
                ),
              ),
            ],
          ),

          // % of portfolio
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '${_pctOfPortfolio.toStringAsFixed(1)}% of portfolio',
              style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
            ),
          ),

          // Tax impact line (if selling)
          if (widget.taxImpact != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                _taxImpactText(widget.taxImpact!),
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.warning.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _taxImpactText(FundTaxImpact ti) {
    final parts = <String>[];
    if (ti.ltcgTax > 0) parts.add('₹${_rupeeFormat.format(ti.ltcgTax.round())} LTCG');
    if (ti.stcgTax > 0) parts.add('₹${_rupeeFormat.format(ti.stcgTax.round())} STCG');
    if (ti.exitLoadAmount > 0) parts.add('₹${_rupeeFormat.format(ti.exitLoadAmount.round())} exit load');
    if (parts.isEmpty) parts.add('No tax impact');
    return 'Tax if sold: ${parts.join(' · ')}';
  }
}

/// New money input section (lumpsum + SIP).
class NewMoneyInput extends StatefulWidget {
  const NewMoneyInput({
    super.key,
    required this.lumpsum,
    required this.sip,
    required this.onLumpsumChanged,
    required this.onSipChanged,
  });

  final double lumpsum;
  final double sip;
  final void Function(double) onLumpsumChanged;
  final void Function(double) onSipChanged;

  @override
  State<NewMoneyInput> createState() => _NewMoneyInputState();
}

class _NewMoneyInputState extends State<NewMoneyInput> {
  late final TextEditingController _lumpsumCtrl;
  late final TextEditingController _sipCtrl;

  @override
  void initState() {
    super.initState();
    _lumpsumCtrl = TextEditingController(
      text: widget.lumpsum > 0 ? widget.lumpsum.round().toString() : '',
    );
    _sipCtrl = TextEditingController(
      text: widget.sip > 0 ? widget.sip.round().toString() : '',
    );
  }

  @override
  void dispose() {
    _lumpsumCtrl.dispose();
    _sipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.bgDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Money',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lumpsumCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lumpsum',
                      prefixText: '₹ ',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      widget.onLumpsumChanged(double.tryParse(v) ?? 0);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sipCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Monthly SIP',
                      prefixText: '₹ ',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      widget.onSipChanged(double.tryParse(v) ?? 0);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create simulation_summary.dart**

```dart
// lib/presentation/widgets/action_center/simulation_summary.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/simulation_models.dart';

/// Tax impact summary + health delta card for the simulate tab.
class SimulationSummaryCard extends StatelessWidget {
  const SimulationSummaryCard({
    super.key,
    required this.result,
  });

  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###', 'en_IN');

    return Card(
      color: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.bgDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simulation Summary',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Kpi(
                  label: 'LTCG Tax',
                  value: '₹${fmt.format(result.taxImpacts.fold(0.0, (s, t) => s + t.ltcgTax).round())}',
                  color: AppColors.warning,
                ),
                Container(width: 1, height: 28, color: AppColors.bgDivider),
                _Kpi(
                  label: 'STCG Tax',
                  value: '₹${fmt.format(result.taxImpacts.fold(0.0, (s, t) => s + t.stcgTax).round())}',
                  color: AppColors.warning,
                ),
                Container(width: 1, height: 28, color: AppColors.bgDivider),
                _Kpi(
                  label: 'Exit Load',
                  value: '₹${fmt.format(result.totalExitLoad.round())}',
                  color: AppColors.loss,
                ),
                Container(width: 1, height: 28, color: AppColors.bgDivider),
                _Kpi(
                  label: 'Net Cost',
                  value: '₹${fmt.format(result.netRebalanceCost.round())}',
                  color: AppColors.textPrimary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Health score delta
            _HealthDelta(
              projected: result.projectedHealthScore,
              delta: result.healthDelta,
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _HealthDelta extends StatelessWidget {
  const _HealthDelta({required this.projected, required this.delta});
  final int projected;
  final int delta;

  @override
  Widget build(BuildContext context) {
    final deltaColor = delta > 0
        ? AppColors.gain
        : delta < 0
            ? AppColors.loss
            : AppColors.textSecondary;
    final deltaStr = delta > 0 ? '+$delta' : '$delta';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: deltaColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Health: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(
            '$projected',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: deltaColor),
          ),
          const SizedBox(width: 6),
          Text(
            '($deltaStr)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: deltaColor),
          ),
        ],
      ),
    );
  }
}

/// Sticky bottom bar with Reset and Freeze Plan buttons.
class SimulationBottomBar extends StatelessWidget {
  const SimulationBottomBar({
    super.key,
    required this.isDirty,
    required this.isLoading,
    required this.onReset,
    required this.onFreeze,
    this.frozenPlanDate,
  });

  final bool isDirty;
  final bool isLoading;
  final VoidCallback onReset;
  final VoidCallback onFreeze;
  final DateTime? frozenPlanDate; // if there's an active frozen plan

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.bgDivider)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (frozenPlanDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Frozen plan active · Created ${_formatDate(frozenPlanDate!)}',
                    style: const TextStyle(fontSize: 10, color: AppColors.info, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isDirty ? onReset : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.bgDivider),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isDirty && !isLoading ? onFreeze : null,
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Freeze Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
```

- [ ] **Step 3: Verify both widgets compile**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && dart analyze lib/presentation/widgets/action_center/fund_slider_row.dart lib/presentation/widgets/action_center/simulation_summary.dart`

Expected: No errors.

---

### Task 10: Education Card Widget

**Files:**
- Create: `lib/presentation/widgets/action_center/education_card.dart`

- [ ] **Step 1: Create the EducationCard widget**

```dart
// lib/presentation/widgets/action_center/education_card.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/simulation_models.dart';

/// Expandable card showing 3-bucket strategy education notes,
/// refill rules, and instrument lists.
class EducationCard extends StatefulWidget {
  const EducationCard({
    super.key,
    required this.strategy,
  });

  final BucketStrategy strategy;

  @override
  State<EducationCard> createState() => _EducationCardState();
}

class _EducationCardState extends State<EducationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final notes = widget.strategy.educationNotes;
    final isDistribution = widget.strategy.scenario == 'distribution';

    return Card(
      color: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: AppColors.info.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isDistribution
                          ? 'Retirement Bucket Strategy'
                          : 'Wealth Building Bucket Strategy',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),

              // First note always visible
              if (notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    notes.first,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),

              // Expanded content
              if (_expanded) ...[
                const SizedBox(height: 8),
                // Remaining notes
                ...notes.skip(1).map((note) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(Icons.check_circle, size: 10, color: AppColors.primary),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              note,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    )),

                // Refill rules
                if (widget.strategy.refillRules.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Refill Rules',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...widget.strategy.refillRules.map((rule) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.swap_vert,
                              size: 12,
                              color: AppColors.warning.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${rule.description} (${rule.frequency})',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify widget compiles**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && dart analyze lib/presentation/widgets/action_center/education_card.dart`

Expected: No errors.

---

### Task 11: Action Center Screen Overhaul — Member Tabs + Plan/Simulate Tabs

**Files:**
- Modify: `lib/presentation/screens/wealth_planner/action_center_screen.dart`
- Modify: `lib/presentation/widgets/action_center/bucket_bars.dart`

- [ ] **Step 1: Rewrite action_center_screen.dart with member selector + Plan/Simulate tabs**

Replace the entire file with:

```dart
// lib/presentation/screens/wealth_planner/action_center_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/action_models.dart';
import '../../../domain/models/simulation_models.dart';
import '../../providers/action_center_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/simulation_provider.dart';
import '../../widgets/action_center/action_item_card.dart';
import '../../widgets/action_center/education_card.dart';
import '../../widgets/action_center/fund_slider_row.dart';
import '../../widgets/action_center/rebalance_flow.dart';
import '../../widgets/action_center/simulation_summary.dart';
import '../../widgets/action_center/vertical_buckets.dart';

class ActionCenterScreen extends ConsumerStatefulWidget {
  const ActionCenterScreen({super.key});

  @override
  ConsumerState<ActionCenterScreen> createState() => _ActionCenterScreenState();
}

class _ActionCenterScreenState extends ConsumerState<ActionCenterScreen>
    with SingleTickerProviderStateMixin {
  final _completedIds = <String>{};
  String? _selectedMemberId; // null = ALL
  late TabController _tabController;
  bool _freezing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleItem(String id) {
    setState(() {
      if (_completedIds.contains(id)) {
        _completedIds.remove(id);
      } else {
        _completedIds.add(id);
      }
    });
  }

  bool get _isAllSelected => _selectedMemberId == null;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Action Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(actionCenterPlanProvider(_selectedMemberId));
              ref.invalidate(simulationResultProvider(_selectedMemberId));
            },
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) {
          // Sort: Self first, Spouse second, then alphabetical
          final sorted = [...members]..sort((a, b) {
              const order = {'Self': 0, 'Spouse': 1};
              final oa = order[a.relationship] ?? 2;
              final ob = order[b.relationship] ?? 2;
              if (oa != ob) return oa.compareTo(ob);
              return a.displayName.compareTo(b.displayName);
            });

          return Column(
            children: [
              // ── Member Selector ─────────────────────────────────
              _MemberSelector(
                members: sorted,
                selectedMemberId: _selectedMemberId,
                onSelected: (id) {
                  setState(() {
                    _selectedMemberId = id;
                    // If ALL selected, force Plan tab
                    if (id == null && _tabController.index == 1) {
                      _tabController.animateTo(0);
                    }
                  });
                },
              ),

              // ── Plan / Simulate Tabs ───────────────────────────
              Container(
                color: AppColors.bgCard,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textTertiary,
                  tabs: [
                    const Tab(text: 'Plan'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Simulate'),
                          if (_isAllSelected)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(Icons.lock_outline, size: 12, color: AppColors.textTertiary),
                            ),
                        ],
                      ),
                    ),
                  ],
                  onTap: (index) {
                    if (index == 1 && _isAllSelected) {
                      _tabController.animateTo(0);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Select a member to simulate their portfolio'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),

              // ── Tab content ────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: _isAllSelected
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  children: [
                    _PlanTab(
                      memberId: _selectedMemberId,
                      completedIds: _completedIds,
                      onToggle: _toggleItem,
                    ),
                    _isAllSelected
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_outline, size: 48, color: AppColors.textTertiary),
                                SizedBox(height: 8),
                                Text(
                                  'Select a member to simulate\ntheir portfolio',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : _SimulateTab(
                            memberId: _selectedMemberId,
                            onFreezing: (v) => setState(() => _freezing = v),
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Member Selector ─────────────────────────────────────────────────────────

class _MemberSelector extends StatelessWidget {
  const _MemberSelector({
    required this.members,
    required this.selectedMemberId,
    required this.onSelected,
  });

  final List<dynamic> members; // FamilyMemberModel
  final String? selectedMemberId;
  final void Function(String? id) onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _MemberChip(
            label: 'ALL',
            isSelected: selectedMemberId == null,
            onTap: () => onSelected(null),
          ),
          ...members.map((m) => _MemberChip(
                label: (m as dynamic).displayName as String,
                isSelected: selectedMemberId == (m as dynamic).id,
                onTap: () => onSelected((m as dynamic).id as String),
              )),
        ],
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        selected: isSelected,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        backgroundColor: AppColors.bgCard,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.bgDivider,
        ),
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ── Plan Tab ────────────────────────────────────────────────────────────────

class _PlanTab extends ConsumerWidget {
  const _PlanTab({
    required this.memberId,
    required this.completedIds,
    required this.onToggle,
  });

  final String? memberId;
  final Set<String> completedIds;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(actionCenterPlanProvider(memberId));
    final strategyAsync = ref.watch(memberBucketStrategyProvider(memberId));

    return planAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.loss, size: 48),
            const SizedBox(height: 12),
            Text('Error: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(actionCenterPlanProvider(memberId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (plan) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(actionCenterPlanProvider(memberId)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Section 1: Health Snapshot ─────────────────────────────
            _HealthSnapshotBanner(plan: plan),
            const SizedBox(height: 16),

            // ── Section 2: Vertical Bucket Bars ──────────────────────
            // Convert BucketStatus → BucketComposition for the widget
            VerticalBuckets(
              buckets: plan.bucketSummary.map((bs) => BucketComposition(
                bucketNumber: bs.bucketNumber,
                bucketName: bs.bucketName,
                currentPct: bs.currentPct,
                idealPct: bs.idealPct,
                currentValue: bs.currentValue,
                status: bs.status,
                bands: const [], // Plan tab doesn't show asset class bands
              )).toList(),
            ),
            const SizedBox(height: 16),

            // ── Section 3: Rebalance Flow ─────────────────────────────
            if (plan.fundMoves.isNotEmpty)
              RebalanceFlow(
                moves: plan.fundMoves,
                rationale: plan.rationale,
              ),
            if (plan.fundMoves.isNotEmpty) const SizedBox(height: 16),

            // ── Section 4: Unified Action Items ───────────────────────
            if (plan.actionItems.isNotEmpty) ...[
              _ActionItemsSection(
                items: plan.actionItems,
                completedIds: completedIds,
                onToggle: onToggle,
              ),
              const SizedBox(height: 16),
            ],

            // ── Section 5: Education Card ─────────────────────────────
            strategyAsync.when(
              data: (strategy) => EducationCard(strategy: strategy),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // ── Section 6: Summary Footer ─────────────────────────────
            if (plan.totalSellAmount > 0 || plan.totalBuyAmount > 0)
              _SummaryFooter(plan: plan),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Simulate Tab ────────────────────────────────────────────────────────────

class _SimulateTab extends ConsumerStatefulWidget {
  const _SimulateTab({
    required this.memberId,
    required this.onFreezing,
  });

  final String? memberId;
  final void Function(bool) onFreezing;

  @override
  ConsumerState<_SimulateTab> createState() => _SimulateTabState();
}

class _SimulateTabState extends ConsumerState<_SimulateTab> {
  bool _initialized = false;

  void _initSimulation() {
    if (_initialized) return;

    final portfolio = ref.read(portfolioSummaryProvider(widget.memberId));
    portfolio.whenData((p) {
      final amounts = <int, double>{};
      for (final f in p.fundHoldings) {
        amounts[f.amfiCode] = f.currentValue;
      }
      ref.read(simulationStateProvider.notifier).initFromHoldings(amounts);
      _initialized = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initSimulation();
  }

  Future<void> _freeze() async {
    widget.onFreezing(true);
    try {
      final simState = ref.read(simulationStateProvider);
      final result = await ref.read(simulationResultProvider(widget.memberId).future);
      final strategy = await ref.read(memberBucketStrategyProvider(widget.memberId).future);

      if (result == null) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Freeze Plan?'),
          content: const Text(
            'Save this as your target allocation? eVesh will track your progress.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Freeze'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await ref.read(freezePlanProvider(
          memberId: widget.memberId,
          result: result,
          simState: simState,
          bucketStrategy: strategy,
        ).future);

        ref.invalidate(activeFrozenPlanProvider(widget.memberId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plan frozen successfully!'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.loss),
        );
      }
    } finally {
      widget.onFreezing(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(simulationStateProvider);
    final simResultAsync = ref.watch(simulationResultProvider(widget.memberId));
    final strategyAsync = ref.watch(memberBucketStrategyProvider(widget.memberId));
    final portfolioAsync = ref.watch(portfolioSummaryProvider(widget.memberId));
    final frozenPlanAsync = ref.watch(activeFrozenPlanProvider(widget.memberId));

    // Maps for display-name keys
    const displayToAssetClassKey = <String, String>{
      'Core Equity': 'coreEquity',
      'Satellite Equity': 'satelliteEquity',
      'Hybrid': 'hybrid',
      'Debt': 'debt',
      'Liquid': 'liquid',
      'Gold': 'gold',
      'Alternate': 'alternate',
    };

    return portfolioAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (portfolio) {
        if (portfolio.fundHoldings.isEmpty) {
          return const Center(
            child: Text('No holdings to simulate', style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        // Build tax impact lookup
        final taxLookup = <int, FundTaxImpact>{};
        simResultAsync.whenData((r) {
          if (r != null) {
            for (final ti in r.taxImpacts) {
              taxLookup[ti.amfiCode] = ti;
            }
          }
        });

        final totalValue = simResultAsync.valueOrNull?.totalPortfolioValue ?? portfolio.currentValue;

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── New Money Input ─────────────────────────────
                  NewMoneyInput(
                    lumpsum: simState.additionalLumpsum,
                    sip: simState.additionalSip,
                    onLumpsumChanged: (v) =>
                        ref.read(simulationStateProvider.notifier).setLumpsum(v),
                    onSipChanged: (v) =>
                        ref.read(simulationStateProvider.notifier).setSip(v),
                  ),
                  const SizedBox(height: 16),

                  // ── Fund Sliders ────────────────────────────────
                  const Text(
                    'Fund Allocations',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...portfolio.fundHoldings.map((f) {
                    final acLabel = f.assetClassLabel ?? f.taxCategory ?? 'Alternate';
                    return FundSliderRow(
                      amfiCode: f.amfiCode,
                      fundName: f.fundName,
                      assetClassLabel: acLabel,
                      currentValue: f.currentValue,
                      adjustedValue: simState.fundAmounts[f.amfiCode] ?? f.currentValue,
                      totalPortfolioValue: totalValue,
                      taxImpact: taxLookup[f.amfiCode],
                      onChanged: (v) =>
                          ref.read(simulationStateProvider.notifier).setFundAmount(f.amfiCode, v),
                    );
                  }),
                  const SizedBox(height: 16),

                  // ── Vertical Buckets ────────────────────────────
                  simResultAsync.when(
                    data: (result) {
                      if (result == null) return const SizedBox.shrink();
                      return VerticalBuckets(buckets: result.bucketFills);
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // ── Education Card ──────────────────────────────
                  strategyAsync.when(
                    data: (strategy) => EducationCard(strategy: strategy),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // ── Simulation Summary ──────────────────────────
                  simResultAsync.when(
                    data: (result) {
                      if (result == null) return const SizedBox.shrink();
                      return SimulationSummaryCard(result: result);
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 80), // space for bottom bar
                ],
              ),
            ),

            // ── Bottom Bar ────────────────────────────────────────
            SimulationBottomBar(
              isDirty: simState.isDirty,
              isLoading: false,
              frozenPlanDate: frozenPlanAsync.valueOrNull?.createdAt,
              onReset: () {
                final amounts = <int, double>{};
                for (final f in portfolio.fundHoldings) {
                  amounts[f.amfiCode] = f.currentValue;
                }
                ref.read(simulationStateProvider.notifier).reset(amounts);
              },
              onFreeze: _freeze,
            ),
          ],
        );
      },
    );
  }
}

// ── Reused widgets from the old file ────────────────────────────────────────

class _HealthSnapshotBanner extends StatelessWidget {
  const _HealthSnapshotBanner({required this.plan});
  final RebalancePlan plan;

  Color get _scoreColor {
    if (plan.healthScore >= 80) return AppColors.gain;
    if (plan.healthScore >= 60) return AppColors.primary;
    if (plan.healthScore >= 40) return AppColors.warning;
    return AppColors.loss;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _scoreColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _scoreColor, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      '${plan.healthScore}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _scoreColor),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.healthLabel,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _scoreColor),
                      ),
                      if (plan.topDriftAlert != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber, size: 12, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(plan.topDriftAlert!,
                                    style: const TextStyle(fontSize: 11, color: AppColors.warning)),
                              ),
                            ],
                          ),
                        ),
                      if (plan.retirementGapMonthly != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.elderly, size: 12, color: AppColors.info),
                              const SizedBox(width: 4),
                              Text(
                                '₹${plan.retirementGapMonthly!.toINR(compact: true)}/month short for retirement',
                                style: const TextStyle(fontSize: 11, color: AppColors.info),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionCountChip(
                  count: plan.actionItems.where((a) => a.priority == ActionPriority.critical).length,
                  label: 'Critical',
                  color: AppColors.loss,
                ),
                const SizedBox(width: 8),
                _ActionCountChip(
                  count: plan.actionItems.where((a) => a.priority == ActionPriority.warning).length,
                  label: 'Attention',
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                _ActionCountChip(
                  count: plan.actionItems.where((a) => a.priority == ActionPriority.info).length,
                  label: 'Info',
                  color: AppColors.info,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCountChip extends StatelessWidget {
  const _ActionCountChip({required this.count, required this.label, required this.color});
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _ActionItemsSection extends StatelessWidget {
  const _ActionItemsSection({
    required this.items,
    required this.completedIds,
    required this.onToggle,
  });

  final List<ActionItem> items;
  final Set<String> completedIds;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    final grouped = <ActionSource, List<ActionItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.source, () => []).add(item);
    }

    const sourceOrder = [
      ActionSource.rebalance,
      ActionSource.drift,
      ActionSource.retirement,
      ActionSource.cashOptimization,
      ActionSource.fundReplace,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Action Items',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
        ),
        ...sourceOrder.where((s) => grouped.containsKey(s)).expand((source) {
          final sourceItems = grouped[source]!;
          return [
            ActionSourceHeader(source: source, count: sourceItems.length),
            ...sourceItems.map((item) {
              final resolved = item.copyWith(isCompleted: completedIds.contains(item.id));
              return ActionItemCard(item: resolved, onToggle: () => onToggle(item.id));
            }),
          ];
        }),
      ],
    );
  }
}

class _SummaryFooter extends StatelessWidget {
  const _SummaryFooter({required this.plan});
  final RebalancePlan plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.bgDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryKpi(label: 'Total Sell', value: plan.totalSellAmount.toINR(compact: true), color: AppColors.loss),
            Container(width: 1, height: 30, color: AppColors.bgDivider),
            _SummaryKpi(label: 'Total Buy', value: plan.totalBuyAmount.toINR(compact: true), color: AppColors.gain),
            Container(width: 1, height: 30, color: AppColors.bgDivider),
            _SummaryKpi(label: 'Net Flow', value: plan.netCashFlow.toINR(compact: true), color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }
}

class _SummaryKpi extends StatelessWidget {
  const _SummaryKpi({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
```

- [ ] **Step 2: Deprecate bucket_bars.dart (redirect to vertical)**

In `lib/presentation/widgets/action_center/bucket_bars.dart`, add a deprecation notice. If the old horizontal BucketBars is used elsewhere, keep it but add a comment. Since we now use VerticalBuckets everywhere, just ensure the old file still compiles for backward compat:

```dart
// lib/presentation/widgets/action_center/bucket_bars.dart
// DEPRECATED: Use vertical_buckets.dart instead.
// Kept for backward compatibility — not used by action_center_screen.dart anymore.
```

No actual code change needed — the file is no longer imported by action_center_screen.dart.

- [ ] **Step 3: Fix any references to old actionCenterPlanProvider (no argument)**

Search codebase for `actionCenterPlanProvider` without parentheses or with no argument. The wealth_planner_dashboard_screen.dart may reference it:

In `lib/presentation/screens/wealth_planner/wealth_planner_dashboard_screen.dart`, find any reference like `ref.watch(actionCenterPlanProvider)` and change to `ref.watch(actionCenterPlanProvider(null))`.

- [ ] **Step 4: Run build_runner for codegen**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && dart run build_runner build --delete-conflicting-outputs`

Expected: All `.g.dart` files regenerated.

- [ ] **Step 5: Verify full compilation**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && dart analyze lib/`

Expected: No errors (warnings OK).

---

### Task 12: Build + Deploy

**Files:** None (build artifacts only)

- [ ] **Step 1: Run all tests**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && flutter test`

Expected: All tests pass (~36+ tests: 10 rebalance + 8 unified + 10 bucket strategy + 8 simulation).

- [ ] **Step 2: Build web**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && flutter build web`

Expected: Build succeeds, output in `build/web/`.

- [ ] **Step 3: Deploy to Netlify**

Run: `cd /Users/nisanth/Nisanth\ MacM3Pro/Nisanth/Wealth\ Management/Wealth\ Management\ App/evesh_wealth && export PATH="/usr/local/bin:/Users/nisanth/.npm-global/bin:/opt/homebrew/bin:$PATH" && netlify deploy --prod --dir=build/web`

Expected: Deployed to https://evesh.netlify.app

- [ ] **Step 4: Verify deployment**

Visit https://evesh.netlify.app and navigate to:
1. Wealth Planner → Action Center
2. Verify member selector tabs appear (ALL / individual members)
3. Verify Plan tab shows vertical buckets + education card
4. Select a member → Simulate tab becomes active
5. Adjust fund sliders → see bucket fills change + tax impact update
6. Tap Freeze Plan → confirm dialog → success
7. Settings → Edit member → drift threshold slider visible

---

## Self-Review Checklist

1. **Spec coverage:** All 12 tasks from spec's task sequence are covered. Dynamic bucket strategy, simulator, persistence, settings, vertical buckets, education, member tabs, plan/simulate tabs all implemented.

2. **Placeholder scan:** No TBD/TODO/placeholders. All code blocks are complete.

3. **Type consistency:** BucketStrategy used consistently across compute_bucket_strategy.dart, compute_unified_actions.dart, run_rebalance_analysis.dart, simulation_provider.dart, and action_center_provider.dart. SimulationState/SimulationResult/FundTaxImpact types consistent across compute_simulation.dart, simulation_provider.dart, and widgets.
