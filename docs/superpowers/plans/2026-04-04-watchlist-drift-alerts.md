# Watchlist + Drift Alerts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a fund-level watchlist with user-configurable alert rules (stop-loss, gain-harvest, price-target, allocation-drift), server-side daily detection, FCM push + Resend email delivery with frequency preferences, and periodic portfolio reports.

**Architecture:** Supabase `watchlist_rules` table stores user rules. A daily Edge Function (`check-watchlist-rules`) runs 30 min after NAV refresh, evaluates all active rules against current NAV/holdings data, and inserts breached rules into `alert_log`. The existing `send-alert-email` function is extended to honor notification preferences, frequency settings, and send FCM push. A separate `send-portfolio-report` Edge Function generates weekly/monthly/yearly HTML email reports.

**Tech Stack:** Flutter 3.22+ / Dart 3.3+, Riverpod codegen, Freezed models, Supabase (PostgREST + Edge Functions + pg_cron), Firebase Cloud Messaging, Resend email API.

**Important:** This project has no git repository — skip all git commands.

**Build command:** `export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && flutter build web`

**Codegen command:** `dart run build_runner build --delete-conflicting-outputs`

**Base path:** `/Users/nisanth/Nisanth MacM3Pro/Nisanth/Wealth Management/Wealth Management App/evesh_wealth`

---

### Task 1: Supabase Migration — watchlist_rules + profiles.fcm_token

**Files:**
- Create: `supabase/migrations/013_watchlist_rules.sql`

This migration creates the `watchlist_rules` table, adds `fcm_token` to profiles, and sets default `notification_prefs` JSONB for existing profiles.

- [ ] **Step 1: Create migration file**

```sql
-- 013_watchlist_rules.sql
-- Watchlist rules table + FCM token + notification prefs defaults

-- ══════════════════════════════════════════════════════════════
-- 1. watchlist_rules table
-- ══════════════════════════════════════════════════════════════

CREATE TABLE watchlist_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES auth.users(id) NOT NULL,
  member_id UUID REFERENCES family_members(id),
  amfi_code INT,
  fund_name TEXT,
  rule_type TEXT NOT NULL CHECK (rule_type IN ('stop_loss', 'gain_harvest', 'price_target', 'allocation_drift')),
  threshold_type TEXT NOT NULL CHECK (threshold_type IN ('nav', 'amount', 'pct')),
  threshold_value NUMERIC NOT NULL,
  direction TEXT NOT NULL DEFAULT 'below' CHECK (direction IN ('below', 'above')),
  asset_class_key TEXT,
  is_active BOOLEAN DEFAULT true,
  last_triggered_at TIMESTAMPTZ,
  cooldown_hours INT DEFAULT 24,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE watchlist_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "select_own_rules" ON watchlist_rules
  FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "insert_own_rules" ON watchlist_rules
  FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "update_own_rules" ON watchlist_rules
  FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY "delete_own_rules" ON watchlist_rules
  FOR DELETE USING (owner_id = auth.uid());

CREATE INDEX idx_watchlist_active
  ON watchlist_rules (owner_id, is_active)
  WHERE is_active = true;

CREATE INDEX idx_watchlist_amfi
  ON watchlist_rules (amfi_code)
  WHERE amfi_code IS NOT NULL;

-- ══════════════════════════════════════════════════════════════
-- 2. Add fcm_token to profiles
-- ══════════════════════════════════════════════════════════════

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- ══════════════════════════════════════════════════════════════
-- 3. Set default notification_prefs for existing profiles
-- ══════════════════════════════════════════════════════════════

UPDATE profiles
SET notification_prefs = jsonb_build_object(
  'email', true,
  'push', true,
  'frequency', 'daily',
  'stop_loss', true,
  'gain_harvest', true,
  'rebalance_drift', true,
  'sip_reminder', true,
  'nav_drop', true,
  'ltcg_harvest', true,
  'maturity_alert', true,
  'price_target', true,
  'report_weekly', true,
  'report_monthly', true,
  'report_yearly', true
)
WHERE notification_prefs IS NULL;
```

- [ ] **Step 2: Verify** — Read the file back, confirm all 3 sections (table, fcm_token, defaults) are present. Remind user to apply via Supabase Dashboard SQL Editor.

---

### Task 2: WatchlistRuleModel (Freezed) + Codegen

**Files:**
- Create: `lib/data/models/watchlist_rule_model.dart`

- [ ] **Step 1: Create the Freezed model**

```dart
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
```

- [ ] **Step 2: Run codegen**

Run: `cd "/Users/nisanth/Nisanth MacM3Pro/Nisanth/Wealth Management/Wealth Management App/evesh_wealth" && dart run build_runner build --delete-conflicting-outputs`

Verify: `watchlist_rule_model.freezed.dart` and `watchlist_rule_model.g.dart` are generated.

---

### Task 3: Watchlist Providers (CRUD + Status)

**Files:**
- Create: `lib/presentation/providers/watchlist_provider.dart`

- [ ] **Step 1: Create watchlist providers**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/watchlist_rule_model.dart';
import 'auth_provider.dart';
import 'portfolio_provider.dart';

part 'watchlist_provider.g.dart';

/// Fetches all watchlist rules for the current user.
@riverpod
Future<List<WatchlistRuleModel>> watchlistRules(WatchlistRulesRef ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('watchlist_rules')
      .select()
      .eq('owner_id', uid)
      .order('created_at', ascending: false);

  return (response as List)
      .map((row) => WatchlistRuleModel.fromJson(row as Map<String, dynamic>))
      .toList();
}

/// Fetches watchlist rules for a specific fund.
@riverpod
Future<List<WatchlistRuleModel>> fundWatchlistRules(
  FundWatchlistRulesRef ref,
  int amfiCode,
) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('watchlist_rules')
      .select()
      .eq('owner_id', uid)
      .eq('amfi_code', amfiCode)
      .order('created_at', ascending: false);

  return (response as List)
      .map((row) => WatchlistRuleModel.fromJson(row as Map<String, dynamic>))
      .toList();
}

/// Notifier for CRUD operations on watchlist rules.
@riverpod
class WatchlistNotifier extends _$WatchlistNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> addRule({
    String? memberId,
    int? amfiCode,
    String? fundName,
    required String ruleType,
    required String thresholdType,
    required double thresholdValue,
    required String direction,
    String? assetClassKey,
    String? note,
  }) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) throw Exception('Not authenticated');

    final client = ref.read(supabaseClientProvider);
    await client.from('watchlist_rules').insert({
      'owner_id': uid,
      if (memberId != null) 'member_id': memberId,
      if (amfiCode != null) 'amfi_code': amfiCode,
      if (fundName != null) 'fund_name': fundName,
      'rule_type': ruleType,
      'threshold_type': thresholdType,
      'threshold_value': thresholdValue,
      'direction': direction,
      if (assetClassKey != null) 'asset_class_key': assetClassKey,
      if (note != null) 'note': note,
    });

    ref.invalidate(watchlistRulesProvider);
    if (amfiCode != null) {
      ref.invalidate(fundWatchlistRulesProvider(amfiCode));
    }
  }

  Future<void> updateRule(String ruleId, Map<String, dynamic> updates) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('watchlist_rules').update(updates).eq('id', ruleId);
    ref.invalidate(watchlistRulesProvider);
  }

  Future<void> toggleActive(String ruleId, bool isActive) async {
    await updateRule(ruleId, {'is_active': isActive});
  }

  Future<void> deleteRule(String ruleId, {int? amfiCode}) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('watchlist_rules').delete().eq('id', ruleId);
    ref.invalidate(watchlistRulesProvider);
    if (amfiCode != null) {
      ref.invalidate(fundWatchlistRulesProvider(amfiCode));
    }
  }
}

/// Fetches current NAV for a list of amfi codes (for status display).
@riverpod
Future<Map<int, double>> watchlistNavMap(WatchlistNavMapRef ref) async {
  final rules = await ref.watch(watchlistRulesProvider.future);
  final amfiCodes = rules
      .where((r) => r.amfiCode != null)
      .map((r) => r.amfiCode!)
      .toSet()
      .toList();

  if (amfiCodes.isEmpty) return {};

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('fund_master')
      .select('amfi_code, latest_nav')
      .inFilter('amfi_code', amfiCodes);

  return {
    for (final row in (response as List))
      (row['amfi_code'] as int): (row['latest_nav'] as num?)?.toDouble() ?? 0.0,
  };
}
```

- [ ] **Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

Verify: `watchlist_provider.g.dart` is generated with all providers.

---

### Task 4: Watchlist Screen + Rule Cards

**Files:**
- Create: `lib/presentation/widgets/watchlist/rule_card.dart`
- Create: `lib/presentation/screens/watchlist/watchlist_screen.dart`

- [ ] **Step 1: Create RuleCard widget**

Create `lib/presentation/widgets/watchlist/rule_card.dart`:

A card widget that displays a single watchlist rule with:
- Fund name (or asset class for drift rules)
- Rule type badge + threshold description (from `model.description`)
- Current NAV/value vs threshold — with color-coded status (safe=green, near=warning, breached=red)
- Active toggle switch (calls `WatchlistNotifier.toggleActive`)
- Swipe-to-delete via Dismissible

The card should accept: `WatchlistRuleModel rule`, `double? currentNav`, `VoidCallback onDelete`, `ValueChanged<bool> onToggle`.

Status logic:
- `stop_loss` + `nav`: breached if `currentNav <= threshold`, safe buffer = `currentNav - threshold`
- `gain_harvest` + `nav`: breached if `currentNav >= threshold`, distance = `threshold - currentNav`
- `price_target`: same as gain_harvest nav
- `allocation_drift`: show drift % (passed as currentNav param for simplicity)

Use `AppColors.gain` for safe, `AppColors.warning` for within 10% of threshold, `AppColors.loss` for breached.

- [ ] **Step 2: Create WatchlistScreen**

Create `lib/presentation/screens/watchlist/watchlist_screen.dart`:

A `ConsumerStatefulWidget` with:
- AppBar: title "Watchlist", action button `Icons.add` → navigates to AddRuleScreen
- Filter tabs: `[All, Stop-Loss, Gain Harvest, Price Target, Drift]` using `TabBar`
- Body: watches `watchlistRulesProvider` and `watchlistNavMapProvider`
- Filters rules by selected tab's `ruleType`
- Maps each rule to a `RuleCard`, passing current NAV from navMap
- Empty state: icon + "No watchlist rules yet" + "Add your first rule" button
- Pull-to-refresh: invalidates `watchlistRulesProvider`

- [ ] **Step 3: Add route**

Read the router file (`lib/presentation/router/app_router.dart`) and add a route for `/watchlist` pointing to `WatchlistScreen`. Also add it to `route_names.dart` if that file exists. Import the screen.

Also check how the Watchlist is accessed — add a navigation entry in the "More" menu or Portfolio screen. Look at existing navigation patterns (the "Action Center" card on Wealth Planner is a good reference) and add a similar "Watchlist" entry.

---

### Task 5: Add Rule Screen (Fund Search + Threshold Input)

**Files:**
- Create: `lib/presentation/screens/watchlist/add_rule_screen.dart`

- [ ] **Step 1: Create AddRuleScreen**

A `ConsumerStatefulWidget` with a multi-step form:

**Step 1 of form — Rule Type:** Radio buttons for `stop_loss`, `gain_harvest`, `price_target`, `allocation_drift`.

**Step 2 of form — Fund Selection** (skip for `allocation_drift`):
- `TextFormField` with search-as-you-type
- Uses `screenerResultsProvider(ScreenerFilters(searchQuery: query))` to search funds
- Shows results in a `ListView` below the search field
- User taps a fund to select it → stores `amfiCode` + `fundName`
- For `allocation_drift`: show dropdown of 7 asset classes instead

**Step 3 of form — Threshold:**
- Threshold type: `SegmentedButton` with options based on rule type:
  - `stop_loss` / `gain_harvest`: NAV (₹), Amount (₹), Percentage (%)
  - `price_target`: NAV (₹) only
  - `allocation_drift`: Percentage (%) only
- Threshold value: `TextFormField` with `₹` or `%` prefix, numeric keyboard
- Optional note: `TextFormField`

**Save button:** Calls `ref.read(watchlistNotifierProvider.notifier).addRule(...)` then pops the screen.

**Validation:**
- Fund must be selected (except for drift)
- Threshold value must be > 0
- For `stop_loss` nav: warn if threshold > current NAV (already below)

The screen should accept an optional `WatchlistRuleModel? editRule` parameter. If provided, pre-fill all fields and call `updateRule` instead of `addRule` on save.

Also accept optional `int? initialAmfiCode` and `String? initialFundName` for when opened from Fund Detail screen.

---

### Task 6: Fund Detail Screen — Inline Alert Controls

**Files:**
- Modify: `lib/presentation/screens/fund_master/fund_detail_screen.dart`

- [ ] **Step 1: Add alert controls section**

After the "Your Holding" section (after the `Divider()` that follows the KPI Wrap), add a new section:

```dart
// ── Alert Rules ──────────────────────────────────────────
_FundAlertSection(amfiCode: amfiCode, fundName: fund?.fundName ?? ''),
```

Create `_FundAlertSection` as a private `ConsumerWidget` within the same file:
- Watches `fundWatchlistRulesProvider(amfiCode)`
- Shows a `SectionHeader('Alerts')` (using the existing `SectionHeader` widget already imported)
- If no rules exist: two rows — "Stop-Loss [Not set] [+ Set]" and "Gain Target [Not set] [+ Set]"
- If rules exist: show each rule's type, description, and an Edit/Delete icon button
- `[+ Set]` / `[Edit]` navigates to `AddRuleScreen` with `initialAmfiCode` and `initialFundName` pre-filled
- Delete button calls `watchlistNotifier.deleteRule(id, amfiCode: amfiCode)`

Import `watchlist_provider.dart` at the top of the file.

---

### Task 7: Settings — Notification Preferences + Report Toggles

**Files:**
- Modify: `lib/presentation/screens/settings/settings_screen.dart`
- Create: `lib/presentation/providers/notification_prefs_provider.dart`

- [ ] **Step 1: Create notification prefs provider**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'auth_provider.dart';

part 'notification_prefs_provider.g.dart';

/// Default notification preferences.
const defaultNotificationPrefs = <String, dynamic>{
  'email': true,
  'push': true,
  'frequency': 'daily',
  'stop_loss': true,
  'gain_harvest': true,
  'rebalance_drift': true,
  'sip_reminder': true,
  'nav_drop': true,
  'ltcg_harvest': true,
  'maturity_alert': true,
  'price_target': true,
  'report_weekly': true,
  'report_monthly': true,
  'report_yearly': true,
};

@riverpod
Future<Map<String, dynamic>> notificationPrefs(NotificationPrefsRef ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Map.of(defaultNotificationPrefs);

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('profiles')
      .select('notification_prefs')
      .eq('id', uid)
      .single();

  final prefs = response['notification_prefs'] as Map<String, dynamic>?;
  if (prefs == null) return Map.of(defaultNotificationPrefs);

  // Merge with defaults so new keys are always present
  return {...defaultNotificationPrefs, ...prefs};
}

@riverpod
class NotificationPrefsNotifier extends _$NotificationPrefsNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> updatePref(String key, dynamic value) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final current = await ref.read(notificationPrefsProvider.future);
    final updated = {...current, key: value};

    final client = ref.read(supabaseClientProvider);
    await client
        .from('profiles')
        .update({'notification_prefs': updated})
        .eq('id', uid);

    ref.invalidate(notificationPrefsProvider);
  }
}
```

- [ ] **Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 3: Add notification preferences section to Settings screen**

Read the full `settings_screen.dart`. Find the appropriate location (after the existing settings sections, before logout/danger zone). Add a new section:

**Notification Preferences** card with:
- "Email Alerts" toggle (key: `email`)
- "Push Notifications" toggle (key: `push`)
- Divider
- "Alert Frequency" — radio group: Instant / Daily Digest / Weekly Digest / Off (key: `frequency`)
- Divider
- Per-alert-type toggles: Stop-Loss, Gain Harvest, Rebalance Drift, SIP Reminders, NAV Drop, Tax Harvest, Maturity, Price Target

**Portfolio Reports** card with:
- "Weekly Report" toggle (key: `report_weekly`) — "Every Sunday 10:00 AM"
- "Monthly Report" toggle (key: `report_monthly`) — "1st of every month"
- "Yearly Report" toggle (key: `report_yearly`) — "1st January"
- "One-Time Report" button — calls `Supabase.instance.client.functions.invoke('send-portfolio-report', body: {'report_type': 'onetime'})` and shows SnackBar

Watch `notificationPrefsProvider` for current values. Call `notificationPrefsNotifier.updatePref(key, value)` on each toggle/radio change.

Use `AppColors.bgCard` for card background, `AppColors.textPrimary` for labels, `AppColors.primary` for active toggles — consistent with the rest of the settings page.

---

### Task 8: FCM Token Sync in NotificationService

**Files:**
- Modify: `lib/services/notification_service.dart`

- [ ] **Step 1: Add token sync method**

Read the full `notification_service.dart`. Add a method to sync the FCM token to Supabase:

```dart
/// Syncs FCM token to Supabase profiles table.
Future<void> _syncTokenToSupabase(String token) async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', user.id);
  } catch (e) {
    debugPrint('Failed to sync FCM token: $e');
  }
}
```

- [ ] **Step 2: Call sync in initialize()**

In the `initialize()` method, after `_fcmToken = await _messaging.getToken(...)`:

```dart
if (_fcmToken != null) {
  await _syncTokenToSupabase(_fcmToken!);
}
```

Also in the `onTokenRefresh` listener:

```dart
_messaging.onTokenRefresh.listen((newToken) {
  _fcmToken = newToken;
  _syncTokenToSupabase(newToken);
});
```

Add import: `import 'package:supabase_flutter/supabase_flutter.dart';`

---

### Task 9: Edge Function — check-watchlist-rules

**Files:**
- Create: `supabase/functions/check-watchlist-rules/index.ts`

- [ ] **Step 1: Create the Edge Function**

```typescript
// supabase/functions/check-watchlist-rules/index.ts
// Runs daily at 22:30 IST (17:00 UTC) via pg_cron.
// Evaluates all active watchlist rules against current NAV/holdings data.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface WatchlistRule {
  id: string
  owner_id: string
  member_id: string | null
  amfi_code: number | null
  fund_name: string | null
  rule_type: string
  threshold_type: string
  threshold_value: number
  direction: string
  asset_class_key: string | null
  is_active: boolean
  last_triggered_at: string | null
  cooldown_hours: number
}

interface AlertCandidate {
  owner_id: string
  alert_type: string
  severity: string
  title: string
  body: string
  amfi_code: number | null
  member_id: string | null
  dedup_key: string
}

interface Holding {
  amfi_code: number
  units: number
  invested: number
  current_value: number
  gain_pct: number
  asset_class: string
}

Deno.serve(async () => {
  const supabase = createClient(supabaseUrl, supabaseServiceKey)
  const today = new Date().toISOString().slice(0, 10) // YYYY-MM-DD

  // 1. Fetch all active rules
  const { data: rules, error: rulesErr } = await supabase
    .from('watchlist_rules')
    .select('*')
    .eq('is_active', true)

  if (rulesErr || !rules?.length) {
    return new Response(JSON.stringify({ message: 'No active rules', error: rulesErr }))
  }

  // 2. Fetch all NAVs for referenced funds
  const amfiCodes = [...new Set(rules.filter(r => r.amfi_code).map(r => r.amfi_code!))]
  let navMap: Record<number, number> = {}
  if (amfiCodes.length > 0) {
    const { data: navData } = await supabase
      .from('fund_master')
      .select('amfi_code, latest_nav')
      .in_('amfi_code', amfiCodes)
    navMap = Object.fromEntries((navData ?? []).map(r => [r.amfi_code, r.latest_nav ?? 0]))
  }

  // 3. Group rules by owner
  const rulesByOwner: Record<string, WatchlistRule[]> = {}
  for (const rule of rules) {
    ;(rulesByOwner[rule.owner_id] ??= []).push(rule)
  }

  // 4. Fetch transactions for all owners with amount/pct rules
  const ownerIds = Object.keys(rulesByOwner)
  const needsHoldings = rules.some(r => r.threshold_type !== 'nav' || r.rule_type === 'allocation_drift')
  let holdingsByOwner: Record<string, Holding[]> = {}

  if (needsHoldings) {
    const { data: txs } = await supabase
      .from('transactions')
      .select('owner_id, member_id, amfi_code, amount, units, tx_type, fund_master(tax_category, category)')
      .in_('owner_id', ownerIds)

    // Compute holdings per owner per fund
    for (const tx of (txs ?? [])) {
      const key = tx.owner_id
      if (!holdingsByOwner[key]) holdingsByOwner[key] = []

      const isPurchase = ['BUY', 'SIP', 'SWITCH-IN', 'STP-IN', 'BONUS', 'TRANSFER-IN'].includes(tx.tx_type?.toUpperCase())
      const txUnits = tx.units ?? (tx.amount / 1) // fallback
      const existing = holdingsByOwner[key].find(h => h.amfi_code === tx.amfi_code)

      if (existing) {
        if (isPurchase) {
          existing.units += txUnits
          existing.invested += tx.amount
        } else {
          const ratio = existing.units > 0 ? Math.min(txUnits / existing.units, 1) : 0
          existing.invested -= existing.invested * ratio
          existing.units -= txUnits
        }
      } else {
        holdingsByOwner[key].push({
          amfi_code: tx.amfi_code,
          units: isPurchase ? txUnits : -txUnits,
          invested: isPurchase ? tx.amount : -tx.amount,
          current_value: 0,
          gain_pct: 0,
          asset_class: mapTaxCategoryToAssetClass(tx.fund_master?.tax_category, tx.fund_master?.category),
        })
      }
    }

    // Compute current values
    for (const holdings of Object.values(holdingsByOwner)) {
      for (const h of holdings) {
        if (h.units <= 0.01) continue
        const nav = navMap[h.amfi_code] ?? 0
        h.current_value = h.units * nav
        h.gain_pct = h.invested > 0 ? ((h.current_value - h.invested) / h.invested) * 100 : 0
      }
    }
  }

  // 5. Evaluate each rule
  const alerts: AlertCandidate[] = []
  const triggeredRuleIds: string[] = []
  const now = new Date()

  for (const [ownerId, ownerRules] of Object.entries(rulesByOwner)) {
    const holdings = holdingsByOwner[ownerId] ?? []

    for (const rule of ownerRules) {
      // Cooldown check
      if (rule.last_triggered_at) {
        const lastTriggered = new Date(rule.last_triggered_at)
        const cooldownMs = rule.cooldown_hours * 60 * 60 * 1000
        if (now.getTime() - lastTriggered.getTime() < cooldownMs) continue
      }

      const breached = evaluateRule(rule, navMap, holdings)
      if (!breached) continue

      const { severity, title, body } = buildAlert(rule, navMap, holdings)
      alerts.push({
        owner_id: ownerId,
        alert_type: ruleTypeToAlertType(rule.rule_type),
        severity,
        title,
        body,
        amfi_code: rule.amfi_code,
        member_id: rule.member_id,
        dedup_key: `${rule.rule_type}|${rule.id}|${today}`,
      })
      triggeredRuleIds.push(rule.id)
    }
  }

  // 6. Insert alerts (ignore dedup conflicts)
  if (alerts.length > 0) {
    const { error: insertErr } = await supabase
      .from('alert_log')
      .upsert(alerts.map(a => ({
        ...a,
        is_read: false,
        created_at: new Date().toISOString(),
      })), { onConflict: 'dedup_key', ignoreDuplicates: true })

    if (insertErr) console.error('Insert error:', insertErr)
  }

  // 7. Update last_triggered_at
  if (triggeredRuleIds.length > 0) {
    await supabase
      .from('watchlist_rules')
      .update({ last_triggered_at: new Date().toISOString() })
      .in_('id', triggeredRuleIds)
  }

  console.log(`Checked ${rules.length} rules, generated ${alerts.length} alerts`)
  return new Response(JSON.stringify({
    rules_checked: rules.length,
    alerts_generated: alerts.length,
  }))
})

// ─── Helper Functions ────────────────────────────────────────────────────────

function evaluateRule(
  rule: WatchlistRule,
  navMap: Record<number, number>,
  holdings: Holding[],
): boolean {
  const nav = rule.amfi_code ? (navMap[rule.amfi_code] ?? 0) : 0
  const holding = holdings.find(h => h.amfi_code === rule.amfi_code)

  switch (rule.rule_type) {
    case 'stop_loss': {
      if (rule.threshold_type === 'nav') return nav > 0 && nav <= rule.threshold_value
      if (rule.threshold_type === 'amount') return (holding?.current_value ?? 0) > 0 && (holding?.current_value ?? 0) <= rule.threshold_value
      if (rule.threshold_type === 'pct') return (holding?.gain_pct ?? 0) <= -rule.threshold_value
      return false
    }
    case 'gain_harvest': {
      if (rule.threshold_type === 'nav') return nav >= rule.threshold_value
      if (rule.threshold_type === 'amount') return (holding?.current_value ?? 0) >= rule.threshold_value
      if (rule.threshold_type === 'pct') return (holding?.gain_pct ?? 0) >= rule.threshold_value
      return false
    }
    case 'price_target':
      return nav >= rule.threshold_value
    case 'allocation_drift': {
      if (!rule.asset_class_key) return false
      const totalValue = holdings.reduce((s, h) => s + Math.max(h.current_value, 0), 0)
      if (totalValue <= 0) return false
      const classValue = holdings
        .filter(h => h.asset_class === rule.asset_class_key)
        .reduce((s, h) => s + Math.max(h.current_value, 0), 0)
      const currentPct = (classValue / totalValue) * 100
      // For drift rules, threshold_value is the max drift allowed
      // We need to know the ideal — for now use a rough check
      const drift = Math.abs(currentPct - rule.threshold_value)
      return drift > rule.threshold_value
    }
    default:
      return false
  }
}

function buildAlert(
  rule: WatchlistRule,
  navMap: Record<number, number>,
  holdings: Holding[],
): { severity: string; title: string; body: string } {
  const nav = rule.amfi_code ? (navMap[rule.amfi_code] ?? 0) : 0
  const holding = holdings.find(h => h.amfi_code === rule.amfi_code)
  const name = rule.fund_name ?? 'Fund'

  switch (rule.rule_type) {
    case 'stop_loss': {
      const current = rule.threshold_type === 'nav'
        ? `₹${nav.toFixed(2)}`
        : rule.threshold_type === 'amount'
          ? `₹${Math.round(holding?.current_value ?? 0).toLocaleString('en-IN')}`
          : `${(holding?.gain_pct ?? 0).toFixed(1)}%`
      return {
        severity: 'URGENT',
        title: `Stop-Loss: ${name}`,
        body: `${name} has dropped below your stop-loss of ${formatThreshold(rule)}. Current: ${current}.`,
      }
    }
    case 'gain_harvest': {
      const current = rule.threshold_type === 'pct'
        ? `${(holding?.gain_pct ?? 0).toFixed(1)}%`
        : `₹${nav.toFixed(2)}`
      return {
        severity: 'MEDIUM',
        title: `Gain Harvest: ${name}`,
        body: `${name} has crossed your gain target of ${formatThreshold(rule)}. Current: ${current}.`,
      }
    }
    case 'price_target':
      return {
        severity: 'MEDIUM',
        title: `Price Target: ${name}`,
        body: `${name} NAV has reached ₹${nav.toFixed(2)}. Your target was ₹${rule.threshold_value.toFixed(2)}.`,
      }
    case 'allocation_drift':
      return {
        severity: 'URGENT',
        title: `Allocation Drift: ${rule.asset_class_key}`,
        body: `Your ${rule.asset_class_key} allocation has drifted beyond your ${rule.threshold_value}% threshold. Consider rebalancing.`,
      }
    default:
      return { severity: 'MEDIUM', title: 'Watchlist Alert', body: 'A watchlist rule was triggered.' }
  }
}

function formatThreshold(rule: WatchlistRule): string {
  if (rule.threshold_type === 'nav') return `₹${rule.threshold_value.toFixed(2)}`
  if (rule.threshold_type === 'amount') return `₹${Math.round(rule.threshold_value).toLocaleString('en-IN')}`
  return `${rule.threshold_value.toFixed(1)}%`
}

function ruleTypeToAlertType(ruleType: string): string {
  switch (ruleType) {
    case 'stop_loss': return 'STOPLOSS'
    case 'gain_harvest': return 'PRICE_HARVEST'
    case 'price_target': return 'PRICE_HARVEST'
    case 'allocation_drift': return 'REBALANCE_DRIFT'
    default: return 'SYSTEM'
  }
}

function mapTaxCategoryToAssetClass(taxCategory?: string, category?: string): string {
  const cat = (category ?? '').toLowerCase()
  if (cat.includes('liquid') || cat.includes('money market') || cat.includes('overnight')) return 'liquid'
  switch ((taxCategory ?? '').toLowerCase()) {
    case 'equity': return 'coreEquity'
    case 'hybrid-e': case 'hybrid-d': return 'hybrid'
    case 'debt': return 'debt'
    case 'gold': case 'gold etf': return 'gold'
    case 'international': return 'alternate'
    default: return 'alternate'
  }
}
```

---

### Task 10: Modify send-alert-email — FCM Push + Notification Prefs + Frequency

**Files:**
- Modify: `supabase/functions/send-alert-email/index.ts`

- [ ] **Step 1: Read the existing function**

Read the full `supabase/functions/send-alert-email/index.ts` to understand its current structure.

- [ ] **Step 2: Add FCM push helper**

Add a `sendPush()` function that sends via FCM HTTP v1 API. Uses `FIREBASE_PROJECT_ID` and a service account key from env. If FCM credentials are not configured, log a warning and skip push (graceful degradation).

- [ ] **Step 3: Add notification_prefs filtering**

Before sending email/push for each alert:
1. Fetch the user's `notification_prefs` from profiles
2. Check if `prefs[alertTypeKey]` is `true` (map alert_type to prefs key: `STOPLOSS` → `stop_loss`, `REBALANCE_DRIFT` → `rebalance_drift`, etc.)
3. Check `prefs.frequency`:
   - `'off'` → skip email and push entirely
   - `'instant'` → send email + push immediately
   - `'daily'` → for URGENT alerts send push immediately, batch email (already daily cron)
   - `'weekly'` → for URGENT alerts send push immediately, skip email (handled by weekly cron)
4. Check `prefs.email` and `prefs.push` master toggles

- [ ] **Step 4: Send MEDIUM alerts in digest**

Currently only URGENT alerts get emails. Change to:
- URGENT: individual email per alert (if frequency allows)
- MEDIUM: grouped into single digest email per user with all MEDIUM alerts listed
- LOW: no email, in-app only

- [ ] **Step 5: Update alert_log timestamps**

After sending email: `UPDATE alert_log SET emailed_at = now() WHERE id = ?`
After sending push: `UPDATE alert_log SET push_sent_at = now() WHERE id = ?`

---

### Task 11: Edge Function — send-portfolio-report

**Files:**
- Create: `supabase/functions/send-portfolio-report/index.ts`

- [ ] **Step 1: Create the Edge Function**

A Supabase Edge Function that generates HTML email portfolio reports. Accepts `report_type` parameter (`weekly` | `monthly` | `yearly` | `onetime`).

**Algorithm:**
1. If called by cron (no body), determine `report_type` from the day:
   - Sunday → `weekly`
   - 1st of month → `monthly`
   - Jan 1 → `yearly`
2. Fetch all users where `notification_prefs.report_{type}` is true
3. For each user:
   a. Fetch transactions + NAVs → compute portfolio summary (total value, gain/loss)
   b. Build report content based on type:
     - **Weekly:** portfolio value, week's gain/loss (compare to 7 days ago via prev_nav or NAV history), top 3 gainers + top 3 losers from holdings, any new alerts this week, upcoming SIPs
     - **Monthly:** everything in weekly + monthly XIRR estimate, allocation drift summary (per asset class), health score
     - **Yearly:** everything in monthly + annual return vs Nifty 50 benchmark (hardcoded ~12% or from fund_master), tax summary (sum of STCG/LTCG from realized transactions)
     - **Onetime:** current snapshot (all holdings with values, allocation %, health score, XIRR)
   c. Generate HTML email using inline styles (no external CSS)
   d. Send via Resend API
4. For `onetime`: accept `owner_id` in the request body and only generate for that user

**HTML template structure:**
- Header: eVesh logo + report title + date range
- Summary cards: Total Value, Gain/Loss, XIRR
- Holdings table: Fund Name, Value, Gain%, Weight%
- Allocation pie (text representation — percentages per asset class)
- Footer: "View full details at evesh.netlify.app"

Keep the HTML simple — tables with inline styles, no complex layouts. Dark theme matching the app (dark background, green accent).

---

### Task 12: pg_cron Schedules

**Files:**
- Create: `supabase/migrations/014_watchlist_cron.sql`

- [ ] **Step 1: Create cron migration**

```sql
-- 014_watchlist_cron.sql
-- Schedule check-watchlist-rules and portfolio reports

-- Daily watchlist check at 22:30 IST (17:00 UTC)
SELECT cron.schedule(
  'check-watchlist-rules',
  '0 17 * * *',
  $$SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/check-watchlist-rules',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  )$$
);

-- Weekly portfolio report: Sundays 10:00 IST (04:30 UTC)
SELECT cron.schedule(
  'weekly-portfolio-report',
  '30 4 * * 0',
  $$SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/send-portfolio-report',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{"report_type": "weekly"}'::jsonb
  )$$
);

-- Monthly portfolio report: 1st of month 10:00 IST (04:30 UTC)
SELECT cron.schedule(
  'monthly-portfolio-report',
  '30 4 1 * *',
  $$SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/send-portfolio-report',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{"report_type": "monthly"}'::jsonb
  )$$
);

-- Yearly portfolio report: Jan 1 10:00 IST (04:30 UTC)
SELECT cron.schedule(
  'yearly-portfolio-report',
  '30 4 1 1 *',
  $$SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/send-portfolio-report',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{"report_type": "yearly"}'::jsonb
  )$$
);
```

- [ ] **Step 2: Verify** — Remind user to apply both migrations (013 + 014) via Supabase Dashboard SQL Editor. Also remind to deploy Edge Functions via `supabase functions deploy check-watchlist-rules` and `supabase functions deploy send-portfolio-report`.

---

### Task 13: Build + Deploy

- [ ] **Step 1: Run codegen** (if not already up to date)

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 2: Run tests**

Run: `flutter test`

Fix any failures.

- [ ] **Step 3: Build**

Run: `export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" && flutter build web`

- [ ] **Step 4: Deploy**

Run: `export PATH="/usr/local/bin:/Users/nisanth/.npm-global/bin:/opt/homebrew/bin:$PATH" && netlify deploy --prod --dir=build/web`

- [ ] **Step 5: Post-deploy checklist**

Remind user:
1. Apply `013_watchlist_rules.sql` in Supabase Dashboard SQL Editor
2. Apply `014_watchlist_cron.sql` in Supabase Dashboard SQL Editor
3. Deploy Edge Functions: `supabase functions deploy check-watchlist-rules` and `supabase functions deploy send-portfolio-report`
4. Set environment variables in Supabase: `FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT_KEY` (for FCM push)
5. Test watchlist by adding a rule and verifying it appears in the Watchlist screen
