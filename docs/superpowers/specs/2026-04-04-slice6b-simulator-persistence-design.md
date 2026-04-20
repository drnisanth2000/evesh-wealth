# Slice 6b: Interactive Simulator + Action Persistence — Design Spec

## Goal

Transform the Action Center from a read-only recommendation view into an interactive planning tool where members can adjust fund allocations via sliders/text boxes, see real-time tax impact, health score changes, and bucket fill levels, then freeze their customized plan for persistent tracking. Also: fix the 3-bucket strategy to be dynamic (age/risk/life-stage aware), add per-member drift threshold settings, and add educational content about the bucket strategy.

## Scope

**In this slice:**
- Per-fund sliders + text boxes (₹ amounts, not %) with live recalculation
- Lumpsum + SIP input for new money
- Dynamic 3-bucket strategy engine (age/risk/life-stage)
- Vertical bucket visualization with asset class composition bands + overflow arrows
- Tax impact preview per sell (STCG/LTCG + exit load) using existing tax engine
- Freeze Plan → persist to Supabase `frozen_plans` table
- Reset → revert to eVesh recommendation
- Per-member drift threshold setting (slider + text box on settings page)
- Educational notes about 3-bucket strategy (context-sensitive)
- Member selector tabs on Action Center (ALL / Member1 / Member2...)
- Plan / Simulate tabs within Action Center
- Unify bucket targets across `compute_unified_actions.dart` and `run_rebalance_analysis.dart`

**Deferred:**
- CAS verification loop (Slice 7+)
- Drift notifications (email + push) — separate task
- Member tab audit across other screens — separate task
- Full tax harvesting planner page (already exists, no changes needed)

---

## Architecture

### Two Independent Frameworks (never conflate)

1. **3-Bucket (Time Horizon)** — How assets are structured by when you need them
2. **Core/Satellite** — How equity is split between stable anchors vs tactical bets

### 3-Bucket Definitions (Indian Context)

| Bucket | Time Horizon | Purpose | Instruments | Risk |
|--------|-------------|---------|-------------|------|
| **Bucket 1 — Liquidity** | 0–2 years | Immediate access, emergency fund, near-term expenses | Savings, Liquid funds, FD, Ultra-short duration, Money market | Nil |
| **Bucket 2 — Stability** | 3–7 years | Bridge bucket, moderate growth, refills Bucket 1 | Debt funds, Balanced Advantage, Hybrid funds, Gold, REITs | Low–Moderate |
| **Bucket 3 — Growth** | 7+ years | Wealth creation, tolerate volatility | Large/Mid/Small cap equity, Index funds, International, Direct stocks | High |

### Refill Waterfall

```
Bucket 3 (Growth)
   │ Gains (when available) — every 4-5 years
   ▼
Bucket 2 (Stability)
   │ Income (interest & dividends) — every 12-18 months
   ▼
Bucket 1 (Liquidity)
   │ Spend / Emergency
   ▼
  Life
```

### Dynamic Targets by Life Stage

**Scenario 1: Accumulation (Earning + SIP)**

| Age | B1 (Liquidity) | B2 (Stability) | B3 (Growth) | Core/Satellite |
|-----|---------------|----------------|-------------|----------------|
| 25–35 | 5–8% | 12–20% | 70–80% | 75/25 |
| 35–45 | 8–10% | 20–30% | 60–70% | 75/25 |
| 45–55 | 10–15% | 30–40% | 45–60% | 80/20 |
| 55–60 | 15–20% | 35–45% | 35–45% | 80/20 |

**Scenario 2: Distribution (Retired + SWP)**

| Age | B1 (Liquidity) | B2 (Stability) | B3 (Growth) | Core/Satellite |
|-----|---------------|----------------|-------------|----------------|
| 60+ | 20–30% | 40–50% | 20–30% | 80/20 |

Risk profile shifts within ranges: Conservative → higher B1/B2, Aggressive → higher B3.

Scenario detected via: `age >= retirementAge` (from family member profile). No new flag needed.

### Asset Class → Bucket Mapping

| Bucket | Asset Classes |
|--------|--------------|
| 1 (Liquidity) | liquid, debt |
| 2 (Stability) | hybrid, gold, alternate |
| 3 (Growth) | coreEquity, satelliteEquity |

---

## Data Architecture

### Simulation State (in-memory, Riverpod)

```dart
class SimulationState {
  final Map<int, double> fundAmounts;  // amfiCode → desired ₹
  final double additionalLumpsum;
  final double additionalSip;
  final bool isDirty;                  // user changed something?
}
```

Initialized from current holdings. Each slider/text change triggers recomputation.

### BucketStrategy (computed by engine)

```dart
class BucketStrategy {
  final String scenario;                    // 'accumulation' | 'distribution'
  final Map<int, double> bucketTargets;     // {1: 8.0, 2: 22.0, 3: 70.0}
  final Map<int, String> bucketNames;       // {1: 'Liquidity (0-2yr)', ...}
  final Map<int, List<String>> bucketInstruments;
  final double corePct;
  final double satellitePct;
  final List<String> educationNotes;
  final List<RefillRule> refillRules;
}

class RefillRule {
  final int fromBucket;
  final int toBucket;
  final String trigger;
  final String frequency;
  final String description;
}
```

### SimulationResult (recomputed on every change)

```dart
class SimulationResult {
  final Map<String, double> newAllocationPct;   // asset class → %
  final List<BucketComposition> bucketFills;     // per bucket: fill level + asset bands
  final int projectedHealthScore;
  final int healthDelta;                         // vs current
  final List<FundTaxImpact> taxImpacts;          // per fund being sold
  final double totalTaxCost;
  final double totalExitLoad;
  final double netRebalanceCost;
  final double totalPortfolioValue;              // including new money
}

class BucketComposition {
  final int bucketNumber;
  final String bucketName;
  final double currentPct;
  final double idealPct;
  final double currentValue;
  final String status;                           // overweight/underweight/balanced
  final List<AssetClassBand> bands;              // colored bands inside bucket
  final double overflowPct;                      // >0 if spilling
  final int? spillsIntoBucket;                   // which bucket to pour into
}

class AssetClassBand {
  final String assetClassKey;
  final String displayName;
  final double valuePct;                         // % of this bucket
  final double valueAmount;                      // ₹
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
}
```

### Frozen Plan Persistence (Supabase)

New table `frozen_plans`:

```sql
CREATE TABLE frozen_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES auth.users(id) NOT NULL,
  member_id UUID REFERENCES family_members(id),
  fund_allocations JSONB NOT NULL,       -- {amfiCode: amount, ...}
  additional_lumpsum NUMERIC DEFAULT 0,
  additional_sip NUMERIC DEFAULT 0,
  health_score INT,
  health_delta INT,
  total_tax_impact NUMERIC,
  total_exit_load NUMERIC,
  bucket_targets JSONB,                  -- {1: %, 2: %, 3: %}
  action_items JSONB,                    -- [{id, title, completed, ...}]
  status TEXT DEFAULT 'active',          -- 'active', 'completed', 'superseded'
  created_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ
);
```

RLS: `owner_id = auth.uid()`.

When a new plan is frozen, previous active plan is marked `superseded`.

### Drift Threshold (family_members update)

New column: `drift_threshold_pct NUMERIC DEFAULT 5.0`

Settings page gets a slider (range 3–15%) + text box input.

---

## Simulation Engine

### SimulationCalculator (pure Dart, no Supabase)

**Inputs:**
- Current holdings: `List<FundHoldingInput>`
- User's adjusted amounts: `Map<int, double>`
- Additional lumpsum & SIP
- `BucketStrategy` (from BucketStrategyCalculator)
- `UnrealizedExposure` data per fund (for tax)
- Exit load data per fund (from folio details)

**Computation (runs on every slider/textbox change):**

1. **New allocation** — Sum adjusted amounts by asset class → derive new %
2. **Bucket composition** — For each of 3 buckets, list asset classes with ₹ and % within that bucket. Calculate fill level vs ideal from BucketStrategy.
3. **Overflow detection** — If bucket exceeds ideal by >drift_threshold_pct, mark as spilling. Calculate spill amount and target bucket.
4. **Health score recalculation** — Reuse AllocationHealthResult logic with new allocation percentages and member's custom drift threshold.
5. **Tax impact per sell** — For each fund where new amount < current (selling):
   - Sell amount = current − new
   - Classify STCG vs LTCG from UnrealizedExposure holding period
   - Apply rates: equity LTCG 12.5% above ₹1.25L, equity STCG 20%, debt at slab
   - Calculate exit load from folio data
   - Net proceeds = sell − tax − exit load
6. **Summary metrics** — Total tax cost, exit load, net rebalance cost, health delta.

**Key design choice:** The simulator does NOT call RebalanceActionsCalculator. That engine produces eVesh's recommendation (Plan tab). The simulator takes user's manual adjustments and shows consequences. Two independent paths.

**Performance:** Synchronous computation, ~20 funds = trivial. No debouncing needed.

---

## Screen Architecture

### Action Center Screen — Member Selector + 2 Tabs

```
┌─────────────────────────────────────┐
│ Action Center              [refresh]│
├─────────────────────────────────────┤
│ [ALL] [Nisanth] [Priya]  ← member  │
├─────────────────────────────────────┤
│    [ Plan ]    [ Simulate ]  ← tabs │
├─────────────────────────────────────┤
│  (tab content below)                │
└─────────────────────────────────────┘
```

Member selector: ALL shows combined family view. Individual member filters to that member's portfolio.

Simulate tab when "ALL" is selected: disabled with message "Select a member to simulate their portfolio". Plan tab works for ALL (shows combined action items).

### Plan Tab (existing, enhanced)

- Health Snapshot Banner
- **Vertical Bucket Bars** (replaces horizontal) with asset class bands
- Money Movement Flow
- Action Items (grouped by source, persistent checkboxes if frozen plan exists)
- Summary Footer
- **Education Card** — context-sensitive bucket strategy tips

### Simulate Tab (new, disabled when "ALL" selected)

```
┌─────────────────────────────────────┐
│ NEW MONEY                           │
│ Lumpsum [₹ textbox]                 │
│ Monthly SIP [₹ textbox]             │
├─────────────────────────────────────┤
│ FUND ALLOCATIONS                    │
│                                     │
│ HDFC Midcap Opportunities           │
│ Core Equity · Current ₹3.5L         │
│ [====slider========] [₹ 3,50,000]  │
│ 12.4% of portfolio                  │
│ Tax if sold: ₹2,400 LTCG · No exit │
│                                     │
│ SBI Bluechip                        │
│ Core Equity · Current ₹2.1L         │
│ [====slider====] [₹ 2,10,000]      │
│ 7.5% of portfolio                   │
│ (... more funds ...)                │
├─────────────────────────────────────┤
│ 3 VERTICAL BUCKETS                  │
│                                     │
│  ┌───┐    ┌───┐    ┌───┐           │
│  │   │    │   │    │███│← overflow  │
│  │Liq│    │Gld│    │CEq│ ──→ spill │
│  │   │    │───│    │───│            │
│  │Dbt│    │Hyb│    │SEq│            │
│  └───┘    └───┘    └───┘           │
│ Liquidity Stability Growth          │
│  8%→8%   22%→22%   70%→60%         │
│                                     │
│ ── ideal line                       │
│ Bands = asset classes in bucket     │
│ Overflow arrow = spill to next      │
├─────────────────────────────────────┤
│ EDUCATION CARD                      │
│ 💡 "Bucket 1 is a one-time setup.  │
│ Every SIP goes to Buckets 2 & 3."  │
├─────────────────────────────────────┤
│ TAX IMPACT SUMMARY                  │
│ LTCG: ₹2,400 · STCG: ₹800         │
│ Exit Load: ₹0 · Net Cost: ₹3,200   │
│ Health: 55 → 78 (+23)              │
├─────────────────────────────────────┤
│ [  Reset  ]    [ Freeze Plan ✓ ]    │
│  ← sticky bottom bar               │
└─────────────────────────────────────┘
```

### Vertical Bucket Visualization

- Each bucket is a CustomPaint container, filled from bottom to top
- Fill color bands = asset classes (e.g., Bucket 1 has Debt band + Liquid band)
- Ideal level = dashed horizontal line across the bucket
- Overflow: when fill exceeds ideal by >drift_threshold, overflow ripple + arrow pointing to underweight bucket
- Labels below: bucket name, current% → ideal%, ₹ value
- Asset class legend below each bucket
- Colors: green=balanced, orange=underweight, red=overweight

### Freeze Flow

1. User taps "Freeze Plan"
2. Confirmation dialog: "Save this as your target allocation? eVesh will track your progress."
3. On confirm:
   - Save to `frozen_plans` table (previous active plan → superseded)
   - Action items generated from the frozen allocation
4. Plan tab shows frozen plan actions with persistent checkboxes
5. Badge on Action Center: "Frozen plan active · Created Apr 4"

### Reset

Reverts all sliders to current holding amounts, clears lumpsum/SIP, removes dirty state.

---

## Educational Content

### Context-Sensitive Notes

**Accumulation (earning members):**
- "Bucket 1 is a one-time setup (3-6 months expenses). Every SIP goes to Buckets 2 & 3."
- "Core SIPs (75%): Index + Flexi cap. Satellite SIPs (25%): Mid/Small cap + Thematic."
- "Don't pause SIPs in crashes — that's when you buy cheap."
- "Principle preservation in Bucket 1 — no trading needed to meet short-term income."

**Distribution (retired members):**
- "Set up SWP only from Bucket 1 (liquid funds). Never force-sell Bucket 3 during a downturn."
- "Even in a 40% crash, Bucket 1 covers 2-3 years — no need to panic."
- "Refill Bucket 1 from Bucket 2 every 12-18 months. Refill Bucket 2 from Bucket 3 every 4-5 years."
- "Take income generated from Bucket 2 to replenish Bucket 1 as it's spent."

**General:**
- "The 3-bucket strategy divides your portfolio by time horizon, so you never sell long-term assets during short-term downturns."
- "Short-term movements in Bucket 3 are tolerable — it keeps pace with inflation over time."

### Refill Rules (displayed in UI)

| From | To | Trigger | Frequency |
|------|----|---------|-----------|
| Bucket 2 → Bucket 1 | B1 drops below 12 months expenses | Every 12-18 months |
| Bucket 3 → Bucket 2 | B2 depleted below target | Every 4-5 years |

---

## Settings Page Changes

### Drift Threshold (per member)

- Slider: range 3% to 15%, step 1%
- Text box: allows precise entry
- Default: 5%
- Saved to `family_members.drift_threshold_pct`
- Used by: simulator health calculation, rebalance engine, future drift notifications

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `lib/domain/models/simulation_models.dart` | SimulationState, BucketStrategy, RefillRule, BucketComposition, AssetClassBand, FundTaxImpact, SimulationResult, FrozenPlan |
| Create | `lib/core/constants/bucket_education.dart` | Educational strings, instrument lists, refill rules by scenario |
| Create | `lib/domain/usecases/compute_bucket_strategy.dart` | BucketStrategyCalculator — dynamic targets by age/risk/life-stage |
| Create | `lib/domain/usecases/compute_simulation.dart` | SimulationCalculator — recomputes allocation, health, tax |
| Modify | `lib/domain/usecases/compute_unified_actions.dart` | Replace hardcoded bucket targets → BucketStrategyCalculator |
| Modify | `lib/domain/usecases/run_rebalance_analysis.dart` | Replace hardcoded bucket targets → BucketStrategyCalculator |
| Create | `lib/presentation/providers/simulation_provider.dart` | SimulationStateNotifier + simulation result provider |
| Modify | `lib/presentation/providers/action_center_provider.dart` | Add member parameter, integrate BucketStrategy |
| Create | `lib/presentation/widgets/action_center/vertical_buckets.dart` | 3 vertical bucket CustomPaint with asset bands, overflow arrows |
| Create | `lib/presentation/widgets/action_center/fund_slider_row.dart` | Per-fund slider + text box + tax preview |
| Create | `lib/presentation/widgets/action_center/simulation_summary.dart` | Tax summary, health delta, freeze/reset sticky bar |
| Create | `lib/presentation/widgets/action_center/education_card.dart` | Strategy tips card |
| Modify | `lib/presentation/screens/wealth_planner/action_center_screen.dart` | Member selector, Plan/Simulate tabs, vertical buckets, education |
| Modify | `lib/presentation/widgets/action_center/bucket_bars.dart` | Deprecate horizontal → redirect to vertical |
| Create | `supabase/migrations/0XX_frozen_plans.sql` | frozen_plans table + RLS |
| Modify | `lib/data/models/family_model.dart` | Add drift_threshold_pct field |
| Modify | `lib/presentation/screens/settings/family_setup_screen.dart` | Drift threshold slider + text box |
| Create | `test/domain/usecases/compute_bucket_strategy_test.dart` | ~10 tests |
| Create | `test/domain/usecases/compute_simulation_test.dart` | ~8 tests |

## Task Sequence

1. Models — simulation_models.dart + bucket_education.dart
2. Bucket Strategy Engine + Tests
3. Unify bucket targets — modify compute_unified_actions + run_rebalance_analysis
4. Simulation Engine + Tests
5. Supabase migration — frozen_plans table + drift_threshold_pct
6. Family settings — drift threshold slider + text box
7. Simulation Provider — Riverpod codegen
8. Vertical Buckets Widget — CustomPaint
9. Fund Slider Row + Simulation Summary widgets
10. Education Card widget
11. Action Center Screen overhaul — member tabs + Plan/Simulate tabs
12. Build + Deploy
