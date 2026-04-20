# Watchlist + Drift Alerts — Design Spec

## Goal

Build a fund-level watchlist system where users configure per-fund alert rules (stop-loss, gain-harvest, price target, allocation drift), and a server-side detection engine that runs daily after NAV refresh to check all rules and generate alerts. Alerts flow through the existing email (Resend) + push (FCM) infrastructure.

## Scope

**In this slice:**
- `watchlist_rules` Supabase table with RLS
- Watchlist screen (dedicated, accessed from More menu or Portfolio)
- Per-fund alert controls on Fund Detail screen
- Supabase Edge Function `check-watchlist-rules` — server-side rule evaluation
- FCM token sync (client → Supabase `profiles.fcm_token`)
- FCM push sending from `send-alert-email` function
- Notification preferences UI in Settings
- pg_cron schedule for `check-watchlist-rules` (22:30 IST daily)

**Deferred:**
- Real-time intraday alerts (current system is daily)
- Alert suppression/snooze UI
- Watchlist sharing between family members

---

## Data Architecture

### watchlist_rules table (new)

```sql
CREATE TABLE watchlist_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES auth.users(id) NOT NULL,
  member_id UUID REFERENCES family_members(id),        -- nullable = family level
  amfi_code INT REFERENCES fund_master(amfi_code),     -- nullable for drift rules
  fund_name TEXT,                                       -- denormalized for display
  rule_type TEXT NOT NULL,                              -- 'stop_loss' | 'gain_harvest' | 'price_target' | 'allocation_drift'
  threshold_type TEXT NOT NULL,                         -- 'nav' | 'amount' | 'pct'
  threshold_value NUMERIC NOT NULL,                     -- the user's target number
  direction TEXT NOT NULL DEFAULT 'below',              -- 'below' | 'above'
  asset_class_key TEXT,                                 -- for allocation_drift rules only
  is_active BOOLEAN DEFAULT true,
  last_triggered_at TIMESTAMPTZ,                        -- cooldown: don't re-fire within 24h
  cooldown_hours INT DEFAULT 24,
  note TEXT,                                            -- optional user note
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE watchlist_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own rules" ON watchlist_rules
  FOR ALL USING (owner_id = auth.uid());

-- Index
CREATE INDEX idx_watchlist_active ON watchlist_rules (owner_id, is_active)
  WHERE is_active = true;
```

### Rule Types & Threshold Combinations

| rule_type | threshold_type | direction | What it checks |
|-----------|---------------|-----------|----------------|
| stop_loss | nav | below | fund_master.latest_nav < threshold_value |
| stop_loss | amount | below | holding current_value < threshold_value |
| stop_loss | pct | below | (current_value - invested) / invested * 100 < -threshold_value |
| gain_harvest | nav | above | fund_master.latest_nav > threshold_value |
| gain_harvest | amount | above | holding current_value > threshold_value |
| gain_harvest | pct | above | (current_value - invested) / invested * 100 > threshold_value |
| price_target | nav | above | fund_master.latest_nav > threshold_value (no holding needed) |
| allocation_drift | pct | above | abs(current_alloc% - target_alloc%) > threshold_value |

### Existing Tables Used

- `fund_master` — `amfi_code`, `latest_nav`, `prev_nav`, `nav_updated_at`
- `transactions` — `owner_id`, `member_id`, `amfi_code`, `amount`, `units`, `tx_type`, `tx_date`
- `family_members` — `drift_threshold_pct`, `risk_profile`, `date_of_birth`, `retirement_age`
- `alert_log` — `owner_id`, `alert_type`, `severity`, `title`, `body`, `dedup_key`, `member_id`, `amfi_code`
- `profiles` — `fcm_token` (new column), `notification_prefs` (existing JSONB)

### profiles table change

```sql
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;
```

---

## Server-Side Detection Engine

### Edge Function: check-watchlist-rules

**Trigger:** pg_cron daily at 22:30 IST (17:00 UTC), 30 minutes after NAV refresh.

**Algorithm:**

```
1. Fetch all active watchlist_rules (batch all users)
2. Group rules by owner_id
3. For each owner:
   a. Fetch their transactions → compute holdings per fund per member:
      - units (net buy - sell)
      - invested (cost basis, weighted average)
      - current_value = units * latest_nav
      - gain_pct = (current_value - invested) / invested * 100
   b. Fetch relevant fund_master rows for latest_nav
   c. For each active rule:
      - Skip if last_triggered_at + cooldown_hours > now()
      - Evaluate rule (see evaluation table above)
      - If breached:
        * Insert into alert_log with dedup_key = '{rule_type}|{rule_id}|{date}'
        * Update watchlist_rules.last_triggered_at = now()
4. For allocation_drift rules:
   a. Compute current allocation % per asset class (from holdings)
   b. Compute ideal allocation (from member risk profile + age)
   c. If abs(current - ideal) > threshold_value → insert alert
```

**Performance:** Batch all users in one query, batch all NAVs in one query. Per-user computation is in-memory. Expected: <5s for 1000 users.

### Alert Severity Assignment

| Rule Type | Condition | Severity |
|-----------|-----------|----------|
| stop_loss | Any breach | URGENT |
| gain_harvest | Any breach | MEDIUM |
| price_target | Any breach | MEDIUM |
| allocation_drift | drift > 15% | URGENT |
| allocation_drift | drift > threshold but < 15% | MEDIUM |

### Alert Title/Body Templates

- **Stop-Loss:** "{fund_name} has dropped below your stop-loss of {threshold}. Current: {current}."
- **Gain Harvest:** "{fund_name} has crossed your gain target of {threshold}%. Current gain: {current}%."
- **Price Target:** "{fund_name} NAV has reached {threshold}. Current NAV: {current}."
- **Allocation Drift:** "Your {asset_class} allocation has drifted {drift}% from target. Consider rebalancing."

### Dedup Strategy

`dedup_key = '{rule_type}|{rule_id}|{YYYY-MM-DD}'`

This ensures:
- Same rule doesn't fire twice on the same day
- Rule can fire again the next day if still breached (after cooldown)
- Different rules for same fund can fire independently

---

## Email + Push Delivery

### Existing send-alert-email function (modify)

Currently sends emails for URGENT alerts only. Changes:

1. **Honor notification_prefs JSONB** — check `prefs.rebalance_drift`, `prefs.stop_loss`, etc. before sending
2. **Send FCM push** — for URGENT alerts, also send push notification via FCM HTTP v1 API
3. **Send MEDIUM alerts** — include in email digest (not individual emails)
4. **Update timestamps** — set `emailed_at` and `push_sent_at` on alert_log rows

### FCM Push Integration

```typescript
// In send-alert-email function
async function sendPush(fcmToken: string, title: string, body: string) {
  const message = {
    message: {
      token: fcmToken,
      notification: { title, body },
      webpush: {
        fcm_options: { link: 'https://evesh.netlify.app/alerts' }
      }
    }
  };
  // Use FCM HTTP v1 API with service account
  await fetch(`https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(message),
  });
}
```

### FCM Token Sync (client-side)

In `NotificationService`, after obtaining FCM token:
```dart
await Supabase.instance.client
    .from('profiles')
    .update({'fcm_token': token})
    .eq('id', userId);
```

Also sync on token refresh.

---

## Screen Architecture

### Watchlist Screen (new)

```
┌─────────────────────────────────────┐
│ Watchlist                  [+ Add]  │
├─────────────────────────────────────┤
│ [All] [Stop-Loss] [Gain] [Drift]   │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ HDFC Midcap Opportunities       │ │
│ │ Stop-Loss · NAV < ₹120         │ │
│ │ Current NAV: ₹135.2  [toggle]  │ │
│ │ Status: Safe (₹15.2 buffer)    │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ SBI Bluechip                    │ │
│ │ Gain Harvest · >25% gain       │ │
│ │ Current: +18.3%  [toggle]      │ │
│ │ Status: 6.7% to target         │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Core Equity Allocation          │ │
│ │ Drift · >10% from target       │ │
│ │ Current drift: 15.5%  [toggle] │ │
│ │ Status: ⚠️ BREACHED            │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Features:**
- Filter tabs: All / Stop-Loss / Gain Harvest / Price Target / Drift
- Each rule card: fund name, rule description, current value, status indicator, active toggle
- Swipe to delete
- FAB or header button to add new rule
- Add Rule flow: pick fund (search) → pick rule type → pick threshold type → enter value → save

### Fund Detail Screen (inline addition)

Add a section after "Your Holding":

```
┌─────────────────────────────────────┐
│ 🔔 Alerts                          │
│                                     │
│ Stop-Loss  [Not set]  [+ Set]      │
│ Gain Target [Not set] [+ Set]      │
│                                     │
│ (or if set:)                        │
│ Stop-Loss  NAV < ₹120  [Edit] [×]  │
│ Gain Target +25%       [Edit] [×]  │
└─────────────────────────────────────┘
```

Tapping [+ Set] opens a bottom sheet with threshold type picker + value input.

### Notification Preferences (Settings)

Add section to existing Settings screen:

```
┌─────────────────────────────────────┐
│ Notification Preferences            │
│                                     │
│ Email Alerts          [toggle] ✅   │
│ Push Notifications    [toggle] ❌   │
│ ─────────────────────────────────── │
│ Alert Frequency                     │
│ (•) Instant  ( ) Daily Digest      │
│ ( ) Weekly Digest  ( ) Off         │
│ ─────────────────────────────────── │
│ Stop-Loss Alerts      [toggle] ✅   │
│ Gain Harvest Alerts   [toggle] ✅   │
│ Rebalance Drift       [toggle] ✅   │
│ SIP Reminders         [toggle] ✅   │
│ NAV Drop Alerts       [toggle] ✅   │
│ Tax Harvest Alerts    [toggle] ✅   │
│ Maturity Alerts       [toggle] ✅   │
└─────────────────────────────────────┘
```

Reads/writes `profiles.notification_prefs` JSONB.

**Frequency options:**
- **Instant** — URGENT alerts sent immediately when detected (default for stop-loss). Email + push per alert.
- **Daily Digest** — All alerts batched into a single email at 19:00 IST. Push only for URGENT.
- **Weekly Digest** — All alerts batched into a weekly email (Sunday 10:00 IST). Push only for URGENT.
- **Off** — No emails or push. Alerts still visible in-app on the Alerts screen.

**notification_prefs JSONB schema:**
```json
{
  "email": true,
  "push": true,
  "frequency": "daily",           // "instant" | "daily" | "weekly" | "off"
  "stop_loss": true,
  "gain_harvest": true,
  "rebalance_drift": true,
  "sip_reminder": true,
  "nav_drop": true,
  "ltcg_harvest": true,
  "maturity_alert": true,
  "price_target": true
}
```

The `send-alert-email` function checks `frequency` before sending:
- `instant` → send immediately for each new alert
- `daily` → batch all unsent alerts into one email at 19:00 IST cron
- `weekly` → batch into weekly email on Sunday cron
- `off` → skip email/push entirely

URGENT alerts (stop-loss) always send push notifications regardless of frequency setting (unless push is toggled off).

### Portfolio Reports (Scheduled Emails)

Separate from alert notifications — periodic portfolio summary reports sent via email.

```
┌─────────────────────────────────────┐
│ Portfolio Reports                   │
│                                     │
│ Weekly Report         [toggle] ✅   │
│  Every Sunday 10:00 AM              │
│                                     │
│ Monthly Report        [toggle] ✅   │
│  1st of every month                 │
│                                     │
│ Yearly Report         [toggle] ✅   │
│  1st January                        │
│                                     │
│ One-Time Report       [Generate]    │
│  Download / email current snapshot  │
└─────────────────────────────────────┘
```

**Report contents by type:**

| Report | Contents |
|--------|----------|
| **Weekly** | Portfolio value, week's gain/loss, top movers (best/worst 3 funds), any triggered alerts, SIP due this week |
| **Monthly** | Everything in weekly + month's XIRR, allocation drift summary, tax harvesting opportunities, SIP track record, health score trend |
| **Yearly** | Everything in monthly + annual XIRR vs benchmarks (Nifty 50, FD), asset class performance breakdown, total dividends/IDCW, tax summary (realized STCG/LTCG), year-over-year wealth growth chart |
| **One-Time** | Current portfolio snapshot — all holdings, allocation, health score, unrealized gains, XIRR. Generated on demand, emailed or downloaded as PDF |

**notification_prefs JSONB (updated):**
```json
{
  "email": true,
  "push": true,
  "frequency": "daily",
  "stop_loss": true,
  "gain_harvest": true,
  "rebalance_drift": true,
  "sip_reminder": true,
  "nav_drop": true,
  "ltcg_harvest": true,
  "maturity_alert": true,
  "price_target": true,
  "report_weekly": true,
  "report_monthly": true,
  "report_yearly": true
}
```

**Backend implementation:**
- **Weekly report:** New pg_cron job → Supabase Edge Function `send-portfolio-report` running Sundays 10:00 IST
- **Monthly report:** Same function, triggered 1st of month 10:00 IST
- **Yearly report:** Same function, triggered Jan 1 10:00 IST
- **One-Time report:** Client calls the Edge Function on-demand via Supabase `functions.invoke()`
- All reports use the same Edge Function with a `report_type` parameter (`weekly` | `monthly` | `yearly` | `onetime`)
- Report emails use HTML templates with inline portfolio data (no PDF generation for now — plain HTML email with tables and KPIs)
- One-Time also supports PDF download via existing `ExportService` on the client side

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `supabase/migrations/013_watchlist_rules.sql` | watchlist_rules table + RLS + profiles.fcm_token |
| Create | `supabase/functions/check-watchlist-rules/index.ts` | Server-side rule evaluation engine |
| Modify | `supabase/functions/send-alert-email/index.ts` | Add FCM push, honor notification_prefs, send MEDIUM alerts |
| Create | `lib/data/models/watchlist_rule_model.dart` | Freezed model for watchlist_rules |
| Create | `lib/presentation/providers/watchlist_provider.dart` | CRUD providers for watchlist rules |
| Create | `lib/presentation/screens/watchlist/watchlist_screen.dart` | Watchlist list + filter tabs |
| Create | `lib/presentation/screens/watchlist/add_rule_screen.dart` | Add/edit rule flow (fund search + threshold input) |
| Create | `lib/presentation/widgets/watchlist/rule_card.dart` | Watchlist rule card widget |
| Modify | `lib/presentation/screens/fund_master/fund_detail_screen.dart` | Add inline alert controls section |
| Modify | `lib/presentation/screens/settings/settings_screen.dart` | Add notification preferences section |
| Modify | `lib/services/notification_service.dart` | Sync FCM token to Supabase profiles |
| Modify | `lib/presentation/router/` | Add watchlist route |
| Create | `supabase/functions/send-portfolio-report/index.ts` | Weekly/monthly/yearly/one-time portfolio report email |
| Modify | `lib/presentation/screens/settings/settings_screen.dart` | Add report toggles alongside notification prefs |

## Task Sequence

1. Supabase migration (watchlist_rules table + profiles.fcm_token + notification_prefs defaults)
2. WatchlistRuleModel (Freezed) + codegen
3. Watchlist providers (CRUD + status computation)
4. Watchlist screen + rule cards
5. Add Rule screen (fund search + threshold input)
6. Fund Detail screen — inline alert controls
7. Settings — notification preferences UI + report frequency toggles
8. FCM token sync in NotificationService
9. Edge Function: check-watchlist-rules (server-side evaluation)
10. Modify send-alert-email (FCM push + notification_prefs + frequency logic + MEDIUM alerts)
11. Edge Function: send-portfolio-report (weekly/monthly/yearly/one-time HTML email)
12. pg_cron schedules (check-watchlist-rules 22:30 IST daily, reports Sunday/1st/Jan 1)
13. Build + Deploy
