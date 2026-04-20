# AMFI Classification & Benchmark Upgrade

**Date:** 2026-04-07
**Status:** Drafted, ready for execution
**Owner:** eVesh

## Goal

Upgrade eVesh's mutual-fund classification and benchmark mapping to match the official AMFI / SEBI 2018 scheme categorization (41 canonical categories) and the AMFI list of benchmark indices (tier-1 + tier-2 per category). Use the canonical categories to drive:

1. Goal-term auto-attach (`classifyFundTerm`) — replace the current keyword heuristic with category-id lookup.
2. Asset-class derivation (`_taxCategoryToAssetClass`) — drive from category-id, not free-text keyword sniffing.
3. Per-fund benchmark comparison chart on the fund detail screen, using the tier-1 index NAV history.

## Sources to scrape

- https://www.amfiindia.com/investor/knowledge-center-info?zoneName=CategorizationOfMutualFundSchemes — narrative list of 41 categories across Equity (12), Debt (16), Hybrid (7), Solution (2), Other (5).
- https://www.amfiindia.com/otherdata/listofbenchmarkindices?tab=equitySchemes — Next.js client-rendered table mapping each category to a tier-1 and tier-2 benchmark index. Requires Playwright (chromium headless).

## Open questions resolved

- **Where to store category catalog?** Both — DB table `amfi_category` (source of truth, with benchmark FK) plus a generated Dart enum `AmfiCategory` (for compile-time safety in classifiers).
- **How to map existing `fund_master.category` (free text) → `amfi_category_id`?** Postgres function `match_amfi_category(text)` that lowercases + strips and matches against `amfi_category.match_patterns text[]`. Logged unmatched rows get manual review via the validation query.
- **Benchmark NAV source?** NSE Indices public CSV (https://www.niftyindices.com/reports/historical-data) — daily, free, no auth. Wrapped behind a small Edge Function `refresh-index-nav` so we can swap providers later.
- **Benchmark comparison chart math?** Normalize fund NAV and index NAV to 100 at the earliest common date, plot both lines, show CAGR delta in legend.

---

## Phase 0 — Setup

### Task 0.1 — Create worktree
- Use `git worktree add` to branch `feat/amfi-classification` off `main`.
- All file paths below are relative to the worktree root.

---

## Phase 1 — Scrape AMFI sources

### Task 1 — Scaffold scraper directory
- Create `tools/amfi_scraper/` with:
  - `package.json` (deps: `playwright`, `cheerio`, `tsx`, `typescript`)
  - `tsconfig.json` (target es2022, module nodenext, strict)
  - `.gitignore` (`node_modules/`, `out/`)
  - `README.md` describing how to run.
- Run `npm install` inside the directory.

### Task 2 — Write `tools/amfi_scraper/scrape.ts`
- Launch chromium headless via Playwright.
- Visit the categorization knowledge-center URL, extract all `<li>` and `<p>` text from the article body, run a regex parser to bucket lines into the 5 super-categories (Equity, Debt, Hybrid, Solution, Other) and 41 canonical category names.
- Visit the benchmark indices URL, wait for `table tbody tr` to render, extract `(category_name, tier1_index, tier2_index)` tuples from each tab (Equity, Debt, Hybrid, Other).
- Inner-join the two lists by fuzzy category name (lowercase, strip "fund"/"scheme"/punctuation).
- Write `out/amfi_categories.json` with shape:
  ```json
  [
    {
      "id": "equity_flexi_cap",
      "super_category": "Equity",
      "name": "Flexi Cap Fund",
      "sebi_definition": "...",
      "match_patterns": ["flexi cap", "flexicap"],
      "tier1_benchmark": "NIFTY 500 TRI",
      "tier2_benchmark": "S&P BSE 500 TRI",
      "default_term": "longTerm",
      "default_asset_class": "CoreEquity",
      "default_tax_category": "equity"
    }
  ]
  ```
- Hand-curate `default_term`, `default_asset_class`, `default_tax_category` per row using a static lookup table inside `scrape.ts`.

### Task 3 — Generate SQL seed
- Add `tools/amfi_scraper/gen_sql.ts` that reads `out/amfi_categories.json` and writes `out/019_seed_amfi_categories.sql` with one `INSERT … ON CONFLICT (id) DO UPDATE` per row.

### Task 4 — Generate Dart enum
- Add `tools/amfi_scraper/gen_dart.ts` that reads `out/amfi_categories.json` and writes `lib/core/constants/amfi_category.g.dart` containing an `enum AmfiCategory { … }` plus an extension exposing `id`, `superCategory`, `tier1Benchmark`, `defaultTerm`, `defaultAssetClass`, `defaultTaxCategory`.
- Mark file with `// GENERATED — do not edit by hand. Run tools/amfi_scraper/gen_dart.ts`.

---

## Phase 2 — Database schema & seed

### Task 5 — Migration `018_amfi_category_tables.sql`
```sql
CREATE TABLE IF NOT EXISTS amfi_category (
  id TEXT PRIMARY KEY,
  super_category TEXT NOT NULL,
  name TEXT NOT NULL,
  sebi_definition TEXT,
  match_patterns TEXT[] NOT NULL DEFAULT '{}',
  tier1_benchmark TEXT,
  tier2_benchmark TEXT,
  default_term TEXT NOT NULL,
  default_asset_class TEXT NOT NULL,
  default_tax_category TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE fund_master
  ADD COLUMN IF NOT EXISTS amfi_category_id TEXT REFERENCES amfi_category(id),
  ADD COLUMN IF NOT EXISTS benchmark_tier1 TEXT,
  ADD COLUMN IF NOT EXISTS benchmark_tier2 TEXT;

CREATE INDEX IF NOT EXISTS idx_fund_master_amfi_category
  ON fund_master(amfi_category_id);

CREATE TABLE IF NOT EXISTS index_nav_history (
  index_name TEXT NOT NULL,
  nav_date DATE NOT NULL,
  nav NUMERIC(18,4) NOT NULL,
  PRIMARY KEY (index_name, nav_date)
);
```

### Task 6 — Migration `019_seed_amfi_categories.sql`
- Drop the file generated by `gen_sql.ts` here.

### Task 7 — Migration `020_backfill_fund_amfi_category.sql`
```sql
CREATE OR REPLACE FUNCTION match_amfi_category(p_text TEXT)
RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
  v_id TEXT;
  v_norm TEXT := lower(coalesce(p_text, ''));
BEGIN
  SELECT id INTO v_id
  FROM amfi_category
  WHERE EXISTS (
    SELECT 1 FROM unnest(match_patterns) AS p
    WHERE v_norm LIKE '%' || p || '%'
  )
  ORDER BY array_length(match_patterns, 1) DESC
  LIMIT 1;
  RETURN v_id;
END;$$;

UPDATE fund_master fm
SET amfi_category_id = match_amfi_category(coalesce(fm.sub_category, fm.category)),
    benchmark_tier1 = ac.tier1_benchmark,
    benchmark_tier2 = ac.tier2_benchmark
FROM amfi_category ac
WHERE ac.id = match_amfi_category(coalesce(fm.sub_category, fm.category))
  AND fm.amfi_category_id IS NULL;
```

---

## Phase 3 — Edge Function for index NAV

### Task 8 — `supabase/functions/refresh-index-nav/index.ts`
- Deno + TypeScript Edge Function.
- Reads list of distinct `tier1_benchmark` from `amfi_category` plus `tier2_benchmark`.
- For each index, fetches the NSE Indices historical CSV via `fetch()`, parses last 90 days, upserts into `index_nav_history`.
- Returns `{ refreshed: count, errors: [...] }`.
- Add `supabase/functions/refresh-index-nav/deno.test.ts` with a unit test that stubs `fetch` and asserts the parser handles a 5-row CSV fixture (place fixture at `supabase/functions/refresh-index-nav/__fixtures__/nifty50_sample.csv`).

### Task 9 — Migration `021_schedule_refresh_index_nav.sql`
```sql
SELECT cron.schedule(
  'refresh_index_nav_daily',
  '30 19 * * 1-5',  -- 19:30 IST weekdays after market close
  $$ SELECT net.http_post(
       url := 'https://bewtjsjhdtwhrsshmigm.supabase.co/functions/v1/refresh-index-nav',
       headers := jsonb_build_object('Authorization', 'Bearer ' || current_setting('app.service_role_key', true))
     );$$
);
```

### Task 10 — Hook into existing `refresh-fund-metadata`
- Edit `supabase/functions/refresh-fund-metadata/index.ts` around line 435 so that after writing `sub_category`, the function also calls `match_amfi_category` via an RPC and sets `amfi_category_id`, `benchmark_tier1`, `benchmark_tier2` on the same upsert.

---

## Phase 4 — Dart models, providers, classifiers

### Task 11 — Add `lib/data/models/amfi_category_model.dart`
- Freezed model mirroring the DB row, with `fromJson`.

### Task 12 — Add `lib/presentation/providers/amfi_category_provider.dart`
- Riverpod codegen `@riverpod` provider that fetches all `amfi_category` rows once and caches them in a `Map<String, AmfiCategoryModel>` keyed by id.

### Task 13 — Extend `FundHoldingSummary`
- Edit `lib/data/models/portfolio_summary_model.dart` to add `amfiCategoryId`, `benchmarkTier1`, `benchmarkTier2` fields (all nullable). Update the join in `lib/presentation/providers/portfolio_provider.dart` line ~23 to select the new columns.
- Run `dart run build_runner build --delete-conflicting-outputs`.

### Task 14 — Update `classifyFundTerm` in `lib/data/models/goal_model.dart`
- New signature: `GoalTerm classifyFundTerm(FundHoldingSummary f, Map<String, AmfiCategoryModel> catalog)`.
- If `f.amfiCategoryId != null && catalog[f.amfiCategoryId] != null`, return `catalog[f.amfiCategoryId]!.defaultTerm`.
- Else fall back to the existing keyword heuristic.
- Update the lone caller in `goal_landing_screen.dart` `_MemberGoalsView` to pass the catalog from `ref.watch(amfiCategoryCatalogProvider)`.

### Task 15 — Update asset class derivation
- Edit `lib/presentation/providers/portfolio_provider.dart` `_taxCategoryToAssetClass` (~line 631): when `amfiCategoryId` is present, return `catalog[id].defaultAssetClass`. Otherwise keep the existing keyword path.

---

## Phase 5 — Benchmark comparison chart

### Task 16 — `lib/data/models/index_nav_point.dart`
- Tiny freezed model `{ String indexName; DateTime navDate; double nav; }`.

### Task 17 — `lib/presentation/providers/index_nav_provider.dart`
- `@riverpod` family provider `indexNavHistory(indexName, fromDate)` that selects from `index_nav_history` and returns a sorted list.

### Task 18 — `lib/presentation/widgets/funds/benchmark_comparison_chart.dart`
- StatelessWidget using `fl_chart` LineChart.
- Inputs: list of fund NAV points + list of index NAV points + a label.
- Logic: align by date, normalize both series to 100 at the earliest common date, plot two lines, compute CAGR for both, show legend `Fund 14.2% • NIFTY 500 TRI 12.8%`.
- Loading + empty + error states.

### Task 19 — Wire chart into `lib/presentation/screens/funds/fund_detail_screen.dart`
- Around line 91 (where `fund.category` is shown), add a new section card titled "vs Benchmark" that renders `BenchmarkComparisonChart` when `fund.benchmarkTier1 != null`.
- Pull index NAV from `indexNavHistoryProvider(fund.benchmarkTier1!, fromDate: oneYearAgo)`.

---

## Phase 6 — Validation & rollout

### Task 20 — Unmapped funds report
- Add `tools/amfi_scraper/check_unmapped.sql`:
  ```sql
  SELECT amfi_code, fund_name, category, sub_category
  FROM fund_master
  WHERE amfi_category_id IS NULL
  ORDER BY fund_name;
  ```
- Run via Supabase API; manually patch `match_patterns` in the seed for any leftovers.

### Task 21 — End-to-end smoke test
- Manually walk through (or scripted via Playwright on the deployed PWA):
  1. Open Goals → Hiya → confirm liquid funds now show under Short Term card with `amfi_category` displayed.
  2. Open Funds → Parag Parikh Liquid Fund → confirm "vs Benchmark" chart shows fund vs NIFTY Liquid Index, both lines visible, CAGR delta in legend.
  3. Open Asset Allocation pie → confirm liquid bucket non-zero.
- Capture screenshots into `docs/superpowers/plans/screenshots/2026-04-07-amfi/`.

### Task 22 — PR
- `git add -A && git commit` with message `feat: AMFI scheme categorization + benchmark mapping`.
- `gh pr create` with summary listing the migrations, new tables, new Edge Function, scraper tool, and screenshots.

---

## Files touched (summary)

| Area | Files |
|---|---|
| Scraper | `tools/amfi_scraper/{package.json,tsconfig.json,scrape.ts,gen_sql.ts,gen_dart.ts,check_unmapped.sql,README.md}` |
| Migrations | `supabase/migrations/{018,019,020,021}_*.sql` |
| Edge Functions | `supabase/functions/refresh-index-nav/{index.ts,deno.test.ts,__fixtures__/nifty50_sample.csv}`, edit `refresh-fund-metadata/index.ts` |
| Dart models | `lib/data/models/{amfi_category_model.dart,index_nav_point.dart}`, edit `portfolio_summary_model.dart`, `goal_model.dart` |
| Dart providers | `lib/presentation/providers/{amfi_category_provider.dart,index_nav_provider.dart}`, edit `portfolio_provider.dart` |
| Dart UI | `lib/presentation/widgets/funds/benchmark_comparison_chart.dart`, edit `screens/funds/fund_detail_screen.dart`, edit `screens/goals/goal_landing_screen.dart` |
| Generated | `lib/core/constants/amfi_category.g.dart` |

## Risk & rollback

- All migrations are additive (`ADD COLUMN IF NOT EXISTS`, new tables). Rollback = `DROP TABLE amfi_category, index_nav_history` and `ALTER TABLE fund_master DROP COLUMN amfi_category_id, …`.
- Edge Function failures don't break app — backfill SQL runs once and stays in place; the daily refresh only updates `index_nav_history`.
- Dart classifiers fall back to existing keyword heuristic when `amfi_category_id` is null, so the app keeps working through partial migration.
