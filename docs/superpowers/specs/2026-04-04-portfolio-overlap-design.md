# Portfolio Overlap & Concentration Analysis — Design Spec

## Goal

Build a portfolio intelligence system that detects fund overlap, stock concentration, and sector concentration across the user's mutual fund portfolio. Uses Groww as the data source for fund-level holdings (stock names, weights, sectors). Provides both passive monitoring (daily server-side checks with alerts) and active analysis (Analytics screen insights + pre-buy overlap check on Fund Detail).

## Scope

**In this slice:**
- `fund_holdings_cache` Supabase table for cached Groww holdings
- `fund_master.groww_slug` column for cached Groww URL slug
- `fetch-fund-holdings` Edge Function (Groww scraper + slug resolver)
- `compute_portfolio_overlap.dart` pure Dart computation engine
- Analytics screen — new Overlap tab (sector pie, top stocks, fund pair overlap matrix)
- Fund Detail screen — "Portfolio Fit" section for pre-buy analysis
- `check-portfolio-overlap` Edge Function (monthly batch detection)
- 3 new alert types through existing alert pipeline
- Educational content explaining SEBI rules and concentration risks

**Deferred:**
- Stock-level drill-down (tap a stock to see which funds hold it)
- Historical overlap trend (how overlap changed over time)
- Custom threshold configuration per user (using SEBI defaults for now)

---

## Data Architecture

### fund_holdings_cache table (new)

```sql
CREATE TABLE fund_holdings_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  amfi_code INT NOT NULL,
  company_name TEXT NOT NULL,
  sector_name TEXT,
  corpus_pct NUMERIC(8,4) NOT NULL,       -- % weight in fund portfolio
  instrument_name TEXT,                     -- ISIN or instrument identifier
  nature_name TEXT,                         -- Equity, Debt, etc.
  rating TEXT,                              -- credit rating if applicable
  market_value NUMERIC(18,2),              -- absolute value in fund
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_holding UNIQUE (amfi_code, company_name)
);

CREATE INDEX idx_holdings_amfi ON fund_holdings_cache (amfi_code);
CREATE INDEX idx_holdings_fetched ON fund_holdings_cache (fetched_at);
```

No RLS needed — this is public fund data, not user-specific.

### fund_master column addition

```sql
ALTER TABLE fund_master ADD COLUMN IF NOT EXISTS groww_slug TEXT;
```

### notification_prefs additions

Three new keys added to the existing `notification_prefs` JSONB:

```json
{
  "stock_concentration": true,
  "sector_concentration": true,
  "fund_overlap": true
}
```

Update the default prefs in migration to include these three keys as `true`.

---

## Data Source: Groww

### Slug Resolution

- Groww URLs: `https://groww.in/mutual-funds/{scheme-slug}`
- Slug is NOT derivable from AMFI code — requires search
- **Resolution strategy (hybrid):**
  1. Check `fund_master.groww_slug` — if populated, use it
  2. If null, call Groww search: `https://groww.in/v1/api/search/v1/entity?q={fund_name}&entity_type=mutual_fund`
  3. Match result by fund name similarity
  4. Cache resolved slug in `fund_master.groww_slug`

### Holdings Extraction

- Fetch: `https://groww.in/mutual-funds/{slug}`
- Parse: extract `<script id="__NEXT_DATA__">` JSON
- Data path: `props.pageProps.mfServerSideData.holdings[]`
- Each holding provides:
  - `company_name` — stock/instrument name
  - `corpus_per` — % weight in fund
  - `sector_name` — sector classification
  - `instrument_name` — ISIN or identifier
  - `rating` — credit rating (for debt)
  - `market_value` — absolute value
  - `nature_name` — Equity/Debt/etc.
- ~111 holdings per scheme, updated monthly by Groww

### Cache Freshness

- Holdings cached in `fund_holdings_cache` with `fetched_at` timestamp
- Stale threshold: **30 days** (matches Groww's monthly portfolio disclosure)
- On-demand refresh: when user opens overlap screen and cache is stale
- Batch refresh: during monthly `check-portfolio-overlap` cron

---

## Computation Engine

### Pure Dart: `compute_portfolio_overlap.dart`

All three computations are pure functions — no Supabase dependency. Input is portfolio holdings + fund holdings cache data.

### Input Structure

```dart
class FundWithHoldings {
  final int amfiCode;
  final String fundName;
  final double portfolioWeightPct;    // fund's weight in user's portfolio
  final List<StockHolding> holdings;  // from fund_holdings_cache
}

class StockHolding {
  final String companyName;
  final String? sectorName;
  final double corpusPct;             // weight within this fund
}
```

### Computation 1: Stock Concentration

For each stock across all held funds:

```
effectiveWeight = Σ (fund.portfolioWeightPct × holding.corpusPct / 100)
```

This gives the stock's effective % of total portfolio value.

**Output:** `List<StockExposure>` sorted by effective weight descending.

**Thresholds (SEBI-aligned):**
- `> 10%` → 🔴 HIGH — URGENT alert. SEBI 20/25 rule breach.
- `> 7%` → 🟡 MODERATE — worth watching
- `<= 7%` → 🟢 LOW — healthy

### Computation 2: Sector Concentration

Same weighted aggregation by `sectorName`:

```
sectorWeight = Σ (fund.portfolioWeightPct × Σ holdings_in_sector.corpusPct / 100)
```

**Output:** `List<SectorExposure>` sorted by weight descending.

**Thresholds (industry standard):**
- `> 25%` → 🔴 HIGH — MEDIUM alert. Over-concentrated.
- `> 20%` → 🟡 MODERATE — approaching concentration
- `<= 20%` → 🟢 LOW — diversified

### Computation 3: Fund Pair Overlap

For each pair of held funds (A, B):

```
overlap = Σ min(weightInA, weightInB) for all stocks present in BOTH funds
```

This is the standard overlap coefficient used by SEBI and Morningstar.

**Output:** `List<FundPairOverlap>` sorted by overlap % descending.

**Thresholds (SEBI Feb 2026 mandate):**
- `> 50%` → 🔴 HIGH — MEDIUM alert. Exceeds SEBI's overlap ceiling.
- `> 35%` → 🟡 MODERATE — significant overlap
- `<= 35%` → 🟢 LOW — distinct portfolios

### Pre-Buy Analysis

Same three computations, but temporarily inject the candidate fund into the portfolio:
- Assume candidate fund weight = user-specified amount / (portfolio value + amount), or default 10% if no amount specified
- Run all three checks
- Output includes **delta**: "Adding this fund changes Banking sector from 22% → 31% 🟡→🔴"

### Overall Portfolio Health Traffic Light

Composite score based on worst-case across all three checks:
- 🔴 HIGH — at least one RED flag in any check
- 🟡 MODERATE — at least one YELLOW, no RED
- 🟢 LOW — all checks green

---

## Edge Functions

### fetch-fund-holdings

**Purpose:** Fetch and cache fund holdings from Groww for a given AMFI code.

**Endpoint:** `POST /functions/v1/fetch-fund-holdings`

**Input:**
```json
{
  "amfi_code": 119551,
  "fund_name": "Axis Bluechip Fund Direct Plan Growth"  // for slug search fallback
}
```

**Algorithm:**
1. Look up `fund_master.groww_slug` for the AMFI code
2. If null → search Groww API: `GET https://groww.in/v1/api/search/v1/entity?q={fund_name}&entity_type=mutual_fund`
3. Extract best match slug from search results
4. Cache slug: `UPDATE fund_master SET groww_slug = '{slug}' WHERE amfi_code = {code}`
5. Fetch page: `GET https://groww.in/mutual-funds/{slug}`
6. Parse `__NEXT_DATA__` script tag → extract holdings array
7. Delete existing cache: `DELETE FROM fund_holdings_cache WHERE amfi_code = {code}`
8. Insert new holdings into `fund_holdings_cache`
9. Return holdings array

**Error handling:**
- Groww search returns no results → return empty, log warning
- Groww page has no `__NEXT_DATA__` → return empty, log warning
- Rate limiting → exponential backoff, max 3 retries
- Graceful degradation: if fetch fails, stale cache remains usable

**Response:**
```json
{
  "amfi_code": 119551,
  "holdings_count": 48,
  "fetched_at": "2026-04-04T17:00:00Z"
}
```

### check-portfolio-overlap

**Purpose:** Monthly batch check — refresh stale holdings, compute overlap for all users, generate alerts.

**Trigger:** pg_cron at 23:00 IST (17:30 UTC) on the 1st and 15th of each month (semi-monthly). Two cron entries with schedules `'30 17 1 * *'` and `'30 17 15 * *'`.

**Algorithm:**
1. Fetch all users with active MF holdings (distinct owner_ids from transactions where asset_type = 'MF')
3. Collect all unique AMFI codes across all users' holdings
4. For each AMFI code: check `fund_holdings_cache.fetched_at` — if >30 days stale, call `fetch-fund-holdings`
5. For each user:
   a. Compute portfolio weights per fund (current_value / total_value)
   b. Fetch cached holdings for each fund
   c. Run stock concentration check
   d. Run sector concentration check
   e. Run fund pair overlap check
   f. If any threshold breached → insert alert into `alert_log`
6. Alert dedup: `dedup_key = 'overlap|{check_type}|{owner_id}|{YYYY-MM}'` — monthly granularity

**Alert types and severity:**

| Check | Condition | alert_type | Severity |
|-------|-----------|------------|----------|
| Stock concentration | Any stock > 10% | STOCK_CONCENTRATION | URGENT |
| Sector concentration | Any sector > 25% | SECTOR_CONCENTRATION | MEDIUM |
| Fund pair overlap | Any pair > 50% | FUND_OVERLAP | MEDIUM |

**Alert templates:**
- **Stock:** "High stock concentration: {company_name} is {pct}% of your portfolio (SEBI limit: 10%). Consider diversifying."
- **Sector:** "Sector concentration: {sector_name} is {pct}% of your portfolio. SEBI recommends below 25%."
- **Overlap:** "{fund_A} and {fund_B} have {pct}% portfolio overlap (SEBI ceiling: 50%). These funds hold very similar stocks."

---

## Screen Architecture

### Analytics Screen — Overlap Tab (new tab)

Add a new tab to the existing Analytics screen (alongside any existing tabs).

```
┌─────────────────────────────────────┐
│ Analytics   [Returns] [Overlap]     │
├─────────────────────────────────────┤
│ Portfolio Health:  🟡 MODERATE  62% │
│ "2 issues need attention"           │
├─────────────────────────────────────┤
│                                     │
│ ── Sector Allocation ──────────────│
│ [Pie chart / horizontal bars]       │
│ Banking      28% 🔴                │
│ IT           18% 🟢                │
│ Auto          9% 🟢                │
│ Pharma        8% 🟢                │
│ ...                                 │
│                                     │
│ ── Top Stock Exposures ────────────│
│ HDFC Bank    11.2% 🔴              │
│ ICICI Bank    8.3% 🟡              │
│ Infosys       6.1% 🟢              │
│ Reliance      5.8% 🟢              │
│ TCS           4.9% 🟢              │
│ ... (top 20)                        │
│                                     │
│ ── Fund Overlap ───────────────────│
│ Axis Bluechip ↔ HDFC Top 100       │
│ 62% overlap 🔴                     │
│                                     │
│ SBI Flexi ↔ Parag Parikh Flexi     │
│ 28% overlap 🟢                     │
│ ...                                 │
│                                     │
│ ── Learn ──────────────────────────│
│ [▸] Why does fund overlap matter?   │
│ [▸] SEBI's 50% overlap rule (2026) │
│ [▸] Stock concentration risk        │
└─────────────────────────────────────┘
```

**Data flow:**
1. Screen loads → fetch portfolio holdings (existing `portfolioSummaryProvider`)
2. For each held fund → check `fund_holdings_cache` freshness via provider
3. If any fund stale → trigger `fetch-fund-holdings` (show loading indicator per fund)
4. Once all holdings loaded → run `compute_portfolio_overlap` computations
5. Display results with traffic light indicators (🟢🟡🔴 + percentage)

**Educational cards** (collapsible, at bottom):
- "Why does fund overlap matter?" — Explanation of how holding similar funds reduces diversification benefit. Mention SEBI's Feb 2026 circular mandating <50% overlap.
- "SEBI's 50% overlap rule" — AMCs must now ensure schemes don't exceed 50% overlap. As an investor, you should apply the same discipline.
- "Stock concentration risk" — SEBI's 20/25 rule limits single-stock exposure. If one stock dominates your portfolio, a company-specific event could disproportionately impact you.

### Fund Detail Screen — Portfolio Fit Section

Added to Fund Detail screen, shown **only when the fund is NOT currently held** by the selected member:

```
┌─────────────────────────────────────┐
│ Portfolio Fit                       │
│                                     │
│ Overall: 🟡 MODERATE               │
│ "This fund has significant overlap  │
│  with 1 fund in your portfolio"     │
│                                     │
│ Overlap with held funds:            │
│ ↔ Axis Bluechip: 58% 🔴           │
│ ↔ HDFC Mid-Cap: 12% 🟢            │
│                                     │
│ Sector impact:                      │
│ Banking: 22% → 28% 🟡→🔴          │
│ IT: 18% → 16% 🟢→🟢               │
│                                     │
│ New stock exposures:                │
│ +3 stocks not in portfolio          │
│ HDFC Bank: 8% → 11% 🟡→🔴         │
│                                     │
│ [▸] What does this mean?            │
└─────────────────────────────────────┘
```

**Pre-buy assumed weight:** Default 10% of portfolio. If the user has entered an amount in a buy simulation, use that instead.

### Alert Integration

Reuses existing alert infrastructure:
- Alerts inserted into `alert_log` with types: `STOCK_CONCENTRATION`, `SECTOR_CONCENTRATION`, `FUND_OVERLAP`
- Flows through `send-alert-email` (honors notification prefs for these three new keys)
- Push notifications for URGENT (stock concentration > 10%)
- Visible on Alerts screen with existing alert cards
- Monthly dedup — won't spam daily

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `supabase/migrations/015_fund_holdings_cache.sql` | fund_holdings_cache table + groww_slug column + notification_prefs update |
| Create | `supabase/functions/fetch-fund-holdings/index.ts` | Groww scraper + slug resolver + cache writer |
| Create | `supabase/functions/check-portfolio-overlap/index.ts` | Monthly batch overlap detection + alert generation |
| Create | `lib/domain/models/overlap_models.dart` | StockExposure, SectorExposure, FundPairOverlap, OverlapResult |
| Create | `lib/domain/usecases/compute_portfolio_overlap.dart` | Pure Dart computation engine |
| Create | `lib/presentation/providers/overlap_provider.dart` | Riverpod providers for holdings cache + overlap results |
| Create | `lib/presentation/widgets/overlap/sector_chart.dart` | Sector allocation horizontal bar chart |
| Create | `lib/presentation/widgets/overlap/stock_exposure_list.dart` | Top stock exposure list with traffic lights |
| Create | `lib/presentation/widgets/overlap/fund_overlap_list.dart` | Fund pair overlap list |
| Create | `lib/presentation/widgets/overlap/portfolio_fit_section.dart` | Pre-buy analysis widget for Fund Detail |
| Create | `lib/presentation/widgets/overlap/educational_cards.dart` | Collapsible SEBI/overlap explainer cards |
| Create | `lib/presentation/widgets/overlap/traffic_light.dart` | Reusable 🟢🟡🔴 indicator widget with % |
| Modify | `lib/presentation/screens/analytics/analytics_screen.dart` | Add Overlap tab |
| Modify | `lib/presentation/screens/fund_master/fund_detail_screen.dart` | Add Portfolio Fit section |
| Modify | `supabase/functions/send-alert-email/index.ts` | Map 3 new alert types to notification_prefs keys |
| Create | `supabase/migrations/016_overlap_cron.sql` | pg_cron for check-portfolio-overlap |

## Task Sequence

1. Supabase migration (fund_holdings_cache + groww_slug + notification_prefs update)
2. Overlap models (Freezed) + codegen
3. Edge Function: fetch-fund-holdings (Groww scraper)
4. Overlap providers (fetch cache + trigger refresh)
5. Computation engine (pure Dart: stock/sector/fund overlap)
6. Traffic light widget + common overlap UI components
7. Analytics screen — Overlap tab
8. Fund Detail screen — Portfolio Fit section
9. Educational cards
10. Edge Function: check-portfolio-overlap (monthly batch)
11. Modify send-alert-email (3 new alert type mappings)
12. pg_cron schedule
13. Build + Deploy
