// AMFI scraper
//
// Strategy:
//   1. Hand-curated catalog of SEBI 2018 categories with tier-1/tier-2
//      benchmarks (source of truth — survives any AMFI HTML changes).
//   2. If Playwright is installed, attempts to live-scrape the AMFI
//      benchmark indices page and overlays any updated benchmark names
//      onto the curated rows. Failures are non-fatal.
//   3. Writes out/amfi_categories.json.
//
// Run: `npx tsx scrape.ts`

import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = join(__dirname, "out");

export interface AmfiCategory {
  id: string;
  super_category: "Equity" | "Debt" | "Hybrid" | "Solution" | "Other";
  name: string;
  sebi_definition: string;
  match_patterns: string[];
  tier1_benchmark: string;
  tier2_benchmark: string;
  default_term: "shortTerm" | "mediumTerm" | "longTerm";
  default_asset_class:
    | "CoreEquity"
    | "SatelliteEquity"
    | "Hybrid"
    | "Debt"
    | "Liquid"
    | "Gold"
    | "Alternate";
  default_tax_category:
    | "equity"
    | "hybridE"
    | "hybridD"
    | "debt"
    | "international"
    | "goldEtf";
}

// Curated catalog: 41 SEBI categories (Equity 12 + Debt 16 + Hybrid 7 + Solution 2 + Other 5)
const CATEGORIES: AmfiCategory[] = [
  // ── EQUITY (12) ────────────────────────────────────────────────────────────
  {
    id: "equity_large_cap",
    super_category: "Equity",
    name: "Large Cap Fund",
    sebi_definition: "Min 80% in large cap stocks (top 100 by market cap).",
    match_patterns: ["large cap", "largecap", "bluechip"],
    tier1_benchmark: "NIFTY 100 TRI",
    tier2_benchmark: "S&P BSE 100 TRI",
    default_term: "longTerm",
    default_asset_class: "CoreEquity",
    default_tax_category: "equity",
  },
  {
    id: "equity_large_and_mid_cap",
    super_category: "Equity",
    name: "Large & Mid Cap Fund",
    sebi_definition: "Min 35% large cap + min 35% mid cap.",
    match_patterns: ["large & mid cap", "large and mid", "large mid"],
    tier1_benchmark: "NIFTY LargeMidcap 250 TRI",
    tier2_benchmark: "S&P BSE 250 LargeMidCap TRI",
    default_term: "longTerm",
    default_asset_class: "CoreEquity",
    default_tax_category: "equity",
  },
  {
    id: "equity_mid_cap",
    super_category: "Equity",
    name: "Mid Cap Fund",
    sebi_definition: "Min 65% in mid cap stocks (rank 101-250).",
    match_patterns: ["mid cap", "midcap"],
    tier1_benchmark: "NIFTY Midcap 150 TRI",
    tier2_benchmark: "S&P BSE 150 MidCap TRI",
    default_term: "longTerm",
    default_asset_class: "SatelliteEquity",
    default_tax_category: "equity",
  },
  {
    id: "equity_small_cap",
    super_category: "Equity",
    name: "Small Cap Fund",
    sebi_definition: "Min 65% in small cap stocks (rank 251 onwards).",
    match_patterns: ["small cap", "smallcap"],
    tier1_benchmark: "NIFTY Smallcap 250 TRI",
    tier2_benchmark: "S&P BSE 250 SmallCap TRI",
    default_term: "longTerm",
    default_asset_class: "SatelliteEquity",
    default_tax_category: "equity",
  },
  {
    id: "equity_multi_cap",
    super_category: "Equity",
    name: "Multi Cap Fund",
    sebi_definition: "Min 25% each in large, mid and small cap.",
    match_patterns: ["multi cap", "multicap"],
    tier1_benchmark: "NIFTY 500 Multicap 50:25:25 TRI",
    tier2_benchmark: "S&P BSE 500 TRI",
    default_term: "longTerm",
    default_asset_class: "CoreEquity",
    default_tax_category: "equity",
  },
  {
    id: "equity_flexi_cap",
    super_category: "Equity",
    name: "Flexi Cap Fund",
    sebi_definition: "Min 65% in equity, no market cap restriction.",
    match_patterns: ["flexi cap", "flexicap"],
    tier1_benchmark: "NIFTY 500 TRI",
    tier2_benchmark: "S&P BSE 500 TRI",
    default_term: "longTerm",
    default_asset_class: "CoreEquity",
    default_tax_category: "equity",
  },
  {
    id: "equity_focused",
    super_category: "Equity",
    name: "Focused Fund",
    sebi_definition: "Max 30 stocks; min 65% equity.",
    match_patterns: ["focused"],
    tier1_benchmark: "NIFTY 500 TRI",
    tier2_benchmark: "S&P BSE 500 TRI",
    default_term: "longTerm",
    default_asset_class: "CoreEquity",
    default_tax_category: "equity",
  },
  {
    id: "equity_dividend_yield",
    super_category: "Equity",
    name: "Dividend Yield Fund",
    sebi_definition: "Min 65% in dividend-yielding stocks.",
    match_patterns: ["dividend yield"],
    tier1_benchmark: "NIFTY 500 TRI",
    tier2_benchmark: "S&P BSE 500 TRI",
    default_term: "longTerm",
    default_asset_class: "CoreEquity",
    default_tax_category: "equity",
  },
  {
    id: "equity_value",
    super_category: "Equity",
    name: "Value Fund",
    sebi_definition: "Value investment strategy, min 65% equity.",
    match_patterns: ["value fund", "value scheme"],
    tier1_benchmark: "NIFTY 500 TRI",
    tier2_benchmark: "S&P BSE 500 TRI",
    default_term: "longTerm",
    default_asset_class: "SatelliteEquity",
    default_tax_category: "equity",
  },
  {
    id: "equity_contra",
    super_category: "Equity",
    name: "Contra Fund",
    sebi_definition: "Contrarian investment strategy, min 65% equity.",
    match_patterns: ["contra"],
    tier1_benchmark: "NIFTY 500 TRI",
    tier2_benchmark: "S&P BSE 500 TRI",
    default_term: "longTerm",
    default_asset_class: "SatelliteEquity",
    default_tax_category: "equity",
  },
  {
    id: "equity_elss",
    super_category: "Equity",
    name: "ELSS",
    sebi_definition: "Equity Linked Savings Scheme, 80C, 3-year lock-in.",
    match_patterns: ["elss", "tax saver", "tax saving"],
    tier1_benchmark: "NIFTY 500 TRI",
    tier2_benchmark: "S&P BSE 500 TRI",
    default_term: "longTerm",
    default_asset_class: "SatelliteEquity",
    default_tax_category: "equity",
  },
  {
    id: "equity_sectoral_thematic",
    super_category: "Equity",
    name: "Sectoral / Thematic Fund",
    sebi_definition: "Min 80% in stocks of a particular sector or theme.",
    match_patterns: ["sectoral", "thematic", "sector fund", "theme"],
    tier1_benchmark: "Sectoral / Thematic TRI",
    tier2_benchmark: "NIFTY 500 TRI",
    default_term: "longTerm",
    default_asset_class: "SatelliteEquity",
    default_tax_category: "equity",
  },

  // ── DEBT (16) ──────────────────────────────────────────────────────────────
  {
    id: "debt_overnight",
    super_category: "Debt",
    name: "Overnight Fund",
    sebi_definition: "Investment in overnight securities with 1-day maturity.",
    match_patterns: ["overnight"],
    tier1_benchmark: "NIFTY 1D Rate Index",
    tier2_benchmark: "CRISIL Overnight Index",
    default_term: "shortTerm",
    default_asset_class: "Liquid",
    default_tax_category: "debt",
  },
  {
    id: "debt_liquid",
    super_category: "Debt",
    name: "Liquid Fund",
    sebi_definition: "Investment in debt and money market securities up to 91 days maturity.",
    match_patterns: ["liquid fund", "liquid scheme", "liquid"],
    tier1_benchmark: "NIFTY Liquid Index",
    tier2_benchmark: "CRISIL Liquid Fund Index",
    default_term: "shortTerm",
    default_asset_class: "Liquid",
    default_tax_category: "debt",
  },
  {
    id: "debt_ultra_short",
    super_category: "Debt",
    name: "Ultra Short Duration Fund",
    sebi_definition: "Macaulay duration 3-6 months.",
    match_patterns: ["ultra short"],
    tier1_benchmark: "NIFTY Ultra Short Duration Debt Index",
    tier2_benchmark: "CRISIL Ultra Short Term Debt Index",
    default_term: "shortTerm",
    default_asset_class: "Liquid",
    default_tax_category: "debt",
  },
  {
    id: "debt_low_duration",
    super_category: "Debt",
    name: "Low Duration Fund",
    sebi_definition: "Macaulay duration 6-12 months.",
    match_patterns: ["low duration"],
    tier1_benchmark: "NIFTY Low Duration Debt Index",
    tier2_benchmark: "CRISIL Low Duration Debt Index",
    default_term: "mediumTerm",
    default_asset_class: "Debt",
    default_tax_category: "debt",
  },
  {
    id: "debt_money_market",
    super_category: "Debt",
    name: "Money Market Fund",
    sebi_definition: "Money market instruments, up to 1 year maturity.",
    match_patterns: ["money market"],
    tier1_benchmark: "NIFTY Money Market Index",
    tier2_benchmark: "CRISIL Money Market Index",
    default_term: "shortTerm",
    default_asset_class: "Liquid",
    default_tax_category: "debt",
  },
  {
    id: "debt_short_duration",
    super_category: "Debt",
    name: "Short Duration Fund",
    sebi_definition: "Macaulay duration 1-3 years.",
    match_patterns: ["short duration", "short term debt"],
    tier1_benchmark: "NIFTY Short Duration Debt Index",
    tier2_benchmark: "CRISIL Short Term Bond Index",
    default_term: "mediumTerm",
    default_asset_class: "Debt",
    default_tax_category: "debt",
  },
  {
    id: "debt_medium_duration",
    super_category: "Debt",
    name: "Medium Duration Fund",
    sebi_definition: "Macaulay duration 3-4 years.",
    match_patterns: ["medium duration"],
    tier1_benchmark: "NIFTY Medium Duration Debt Index",
    tier2_benchmark: "CRISIL Medium Term Bond Index",
    default_term: "mediumTerm",
    default_asset_class: "Debt",
    default_tax_category: "debt",
  },
  {
    id: "debt_medium_long_duration",
    super_category: "Debt",
    name: "Medium to Long Duration Fund",
    sebi_definition: "Macaulay duration 4-7 years.",
    match_patterns: ["medium to long", "medium long"],
    tier1_benchmark: "NIFTY Medium to Long Duration Debt Index",
    tier2_benchmark: "CRISIL Medium to Long Term Bond Index",
    default_term: "mediumTerm",
    default_asset_class: "Debt",
    default_tax_category: "debt",
  },
  {
    id: "debt_long_duration",
    super_category: "Debt",
    name: "Long Duration Fund",
    sebi_definition: "Macaulay duration > 7 years.",
    match_patterns: ["long duration"],
    tier1_benchmark: "NIFTY Long Duration Debt Index",
    tier2_benchmark: "CRISIL Long Term Bond Index",
    default_term: "mediumTerm",
    default_asset_class: "Debt",
    default_tax_category: "debt",
  },
  {
    id: "debt_dynamic_bond",
    super_category: "Debt",
    name: "Dynamic Bond Fund",
    sebi_definition: "Investment across duration.",
    match_patterns: ["dynamic bond", "dynamic asset"],
    tier1_benchmark: "NIFTY Composite Debt Index",
    tier2_benchmark: "CRISIL Composite Bond Index",
    default_term: "mediumTerm",
    default_asset_class: "Debt",
    default_tax_category: "debt",
  },
  {
    id: "debt_corporate_bond",
    super_category: "Debt",
    name: "Corporate Bond Fund",
    sebi_definition: "Min 80% in highest-rated corporate bonds.",
    match_patterns: ["corporate bond"],
    tier1_benchmark: "NIFTY Corporate Bond Index",
    tier2_benchmark: "CRISIL Corporate Bond Index",
    default_term: "mediumTerm",
    default_asset_class: "Debt",
    default_tax_category: "debt",
  },
  {
    id: "debt_credit_risk",
    super_category: "Debt",
    name: "Credit Risk Fund",
    sebi_definition: "Min 65% in below-highest-rated corporate bonds.",
    match_patterns: ["credit risk", "credit opportunities"],
    tier1_benchmark: "NIFTY Credit Risk Bond Index",
    tier2_benchmark: "CRISIL Credit Risk Bond Index",
    default_term: "mediumTerm",
    default_asset_class: "Debt",
    default_tax_category: "debt",
  },
  {
    id: "debt_banking_psu",
    super_category: "Debt",
    name: "Banking and PSU Fund",
    sebi_definition: "Min 80% in debt of banks/PSUs.",
    match_patterns: ["banking and psu", "banking psu", "banking & psu"],
    tier1_benchmark: "NIFTY Banking & PSU Debt Index",
    tier2_benchmark: "CRISIL Banking and PSU Debt Index",
    default_term: "mediumTerm",
    default_asset_class: "Debt",
    default_tax_category: "debt",
  },
  {
    id: "debt_gilt",
    super_category: "Debt",
    name: "Gilt Fund",
    sebi_definition: "Min 80% in government securities across maturities.",
    match_patterns: ["gilt"],
    tier1_benchmark: "NIFTY All Duration G-Sec Index",
    tier2_benchmark: "CRISIL Dynamic Gilt Index",
    default_term: "mediumTerm",
    default_asset_class: "Debt",
    default_tax_category: "debt",
  },
  {
    id: "debt_gilt_10yr",
    super_category: "Debt",
    name: "Gilt Fund with 10 Year Constant Duration",
    sebi_definition: "Min 80% in G-Secs with 10-year constant Macaulay duration.",
    match_patterns: ["gilt 10", "10 year constant", "constant maturity"],
    tier1_benchmark: "NIFTY 10 Yr Benchmark G-Sec Index",
    tier2_benchmark: "CRISIL 10 Year Gilt Index",
    default_term: "mediumTerm",
    default_asset_class: "Debt",
    default_tax_category: "debt",
  },
  {
    id: "debt_floater",
    super_category: "Debt",
    name: "Floater Fund",
    sebi_definition: "Min 65% in floating rate instruments.",
    match_patterns: ["floater", "floating rate"],
    tier1_benchmark: "NIFTY Composite Debt Index",
    tier2_benchmark: "CRISIL Composite Bond Index",
    default_term: "mediumTerm",
    default_asset_class: "Debt",
    default_tax_category: "debt",
  },

  // ── HYBRID (7) ─────────────────────────────────────────────────────────────
  {
    id: "hybrid_conservative",
    super_category: "Hybrid",
    name: "Conservative Hybrid Fund",
    sebi_definition: "10-25% equity, 75-90% debt.",
    match_patterns: ["conservative hybrid", "monthly income plan", "mip"],
    tier1_benchmark: "NIFTY 50 Hybrid Composite Debt 15:85 Index",
    tier2_benchmark: "CRISIL Hybrid 85+15 Conservative Index",
    default_term: "mediumTerm",
    default_asset_class: "Hybrid",
    default_tax_category: "hybridD",
  },
  {
    id: "hybrid_balanced",
    super_category: "Hybrid",
    name: "Balanced Hybrid Fund",
    sebi_definition: "40-60% equity, 40-60% debt.",
    match_patterns: ["balanced hybrid", "balanced fund"],
    tier1_benchmark: "NIFTY 50 Hybrid Composite Debt 50:50 Index",
    tier2_benchmark: "CRISIL Hybrid 50+50 Balanced Index",
    default_term: "longTerm",
    default_asset_class: "Hybrid",
    default_tax_category: "hybridE",
  },
  {
    id: "hybrid_aggressive",
    super_category: "Hybrid",
    name: "Aggressive Hybrid Fund",
    sebi_definition: "65-80% equity, 20-35% debt.",
    match_patterns: ["aggressive hybrid", "equity hybrid"],
    tier1_benchmark: "CRISIL Hybrid 35+65 Aggressive Index",
    tier2_benchmark: "NIFTY 50 Hybrid Composite Debt 65:35 Index",
    default_term: "longTerm",
    default_asset_class: "Hybrid",
    default_tax_category: "hybridE",
  },
  {
    id: "hybrid_dynamic_asset_allocation",
    super_category: "Hybrid",
    name: "Dynamic Asset Allocation / Balanced Advantage Fund",
    sebi_definition: "Dynamic management between equity and debt.",
    match_patterns: ["dynamic asset allocation", "balanced advantage", "baf"],
    tier1_benchmark: "NIFTY 50 Hybrid Composite Debt 50:50 Index",
    tier2_benchmark: "CRISIL Hybrid 50+50 Moderate Index",
    default_term: "longTerm",
    default_asset_class: "Hybrid",
    default_tax_category: "hybridE",
  },
  {
    id: "hybrid_multi_asset",
    super_category: "Hybrid",
    name: "Multi Asset Allocation Fund",
    sebi_definition: "Min 10% each in at least 3 asset classes.",
    match_patterns: ["multi asset", "multi-asset"],
    tier1_benchmark: "NIFTY 50 Hybrid Composite Debt 65:35 Index",
    tier2_benchmark: "CRISIL Hybrid 65+35 Aggressive Index",
    default_term: "longTerm",
    default_asset_class: "Hybrid",
    default_tax_category: "hybridE",
  },
  {
    id: "hybrid_arbitrage",
    super_category: "Hybrid",
    name: "Arbitrage Fund",
    sebi_definition: "Min 65% equity using arbitrage strategies.",
    match_patterns: ["arbitrage"],
    tier1_benchmark: "NIFTY 50 Arbitrage Index",
    tier2_benchmark: "CRISIL BSE Liquid Rate Index",
    default_term: "mediumTerm",
    default_asset_class: "Hybrid",
    default_tax_category: "hybridD",
  },
  {
    id: "hybrid_equity_savings",
    super_category: "Hybrid",
    name: "Equity Savings Fund",
    sebi_definition: "Min 65% equity (incl arbitrage), min 10% debt.",
    match_patterns: ["equity savings"],
    tier1_benchmark: "NIFTY Equity Savings Index",
    tier2_benchmark: "CRISIL Equity Savings Index",
    default_term: "mediumTerm",
    default_asset_class: "Hybrid",
    default_tax_category: "hybridD",
  },

  // ── SOLUTION (2) ───────────────────────────────────────────────────────────
  {
    id: "solution_retirement",
    super_category: "Solution",
    name: "Retirement Fund",
    sebi_definition: "5-year lock-in or till retirement age (whichever earlier).",
    match_patterns: ["retirement"],
    tier1_benchmark: "CRISIL Hybrid 35+65 Aggressive Index",
    tier2_benchmark: "NIFTY 50 Hybrid Composite Debt 65:35 Index",
    default_term: "longTerm",
    default_asset_class: "Hybrid",
    default_tax_category: "hybridE",
  },
  {
    id: "solution_children",
    super_category: "Solution",
    name: "Children's Fund",
    sebi_definition: "5-year lock-in or till child majority (whichever earlier).",
    match_patterns: ["children", "children's", "child gift"],
    tier1_benchmark: "CRISIL Hybrid 35+65 Aggressive Index",
    tier2_benchmark: "NIFTY 50 Hybrid Composite Debt 65:35 Index",
    default_term: "longTerm",
    default_asset_class: "Hybrid",
    default_tax_category: "hybridE",
  },

  // ── OTHER (5) ──────────────────────────────────────────────────────────────
  {
    id: "other_index_fund",
    super_category: "Other",
    name: "Index Fund",
    sebi_definition: "Min 95% in securities of a particular index.",
    match_patterns: ["index fund", "index scheme"],
    tier1_benchmark: "Underlying Index TRI",
    tier2_benchmark: "NIFTY 50 TRI",
    default_term: "longTerm",
    default_asset_class: "CoreEquity",
    default_tax_category: "equity",
  },
  {
    id: "other_etf",
    super_category: "Other",
    name: "ETF",
    sebi_definition: "Min 95% in securities of a particular index, listed on exchange.",
    match_patterns: ["etf", "exchange traded fund"],
    tier1_benchmark: "Underlying Index TRI",
    tier2_benchmark: "NIFTY 50 TRI",
    default_term: "longTerm",
    default_asset_class: "CoreEquity",
    default_tax_category: "equity",
  },
  {
    id: "other_fof_domestic",
    super_category: "Other",
    name: "FoF (Domestic)",
    sebi_definition: "Min 95% in domestic mutual fund units.",
    match_patterns: ["fof domestic", "fund of funds domestic"],
    tier1_benchmark: "NIFTY 50 Hybrid Composite Debt 65:35 Index",
    tier2_benchmark: "CRISIL Hybrid 65+35 Aggressive Index",
    default_term: "longTerm",
    default_asset_class: "Hybrid",
    default_tax_category: "hybridE",
  },
  {
    id: "other_fof_overseas",
    super_category: "Other",
    name: "FoF (Overseas)",
    sebi_definition: "Min 95% in overseas mutual fund units.",
    match_patterns: ["fof overseas", "international", "fund of funds overseas", "us equity", "global"],
    tier1_benchmark: "MSCI World Index",
    tier2_benchmark: "S&P 500 TRI",
    default_term: "longTerm",
    default_asset_class: "SatelliteEquity",
    default_tax_category: "international",
  },
  {
    id: "other_gold_etf",
    super_category: "Other",
    name: "Gold ETF / Gold Fund",
    sebi_definition: "Min 95% in gold or gold-linked instruments.",
    match_patterns: ["gold etf", "gold fund", "gold savings"],
    tier1_benchmark: "Domestic Price of Gold",
    tier2_benchmark: "MCX Gold",
    default_term: "mediumTerm",
    default_asset_class: "Gold",
    default_tax_category: "goldEtf",
  },
];

async function tryLiveScrape(): Promise<Map<string, { tier1?: string; tier2?: string }>> {
  const overrides = new Map<string, { tier1?: string; tier2?: string }>();
  try {
    // Dynamic import so the script still runs without playwright installed.
    // @ts-ignore optional dependency
    const pw: any = await import("playwright");
    const browser = await pw.chromium.launch({ headless: true });
    const page = await browser.newPage();
    const tabs = ["equitySchemes", "debtSchemes", "hybridSchemes", "otherSchemes"];
    for (const tab of tabs) {
      const url = `https://www.amfiindia.com/otherdata/listofbenchmarkindices?tab=${tab}`;
      await page.goto(url, { waitUntil: "domcontentloaded", timeout: 30000 });
      try {
        await page.waitForSelector("table tbody tr", { timeout: 20000 });
      } catch {
        console.warn(`No table for tab ${tab}, skipping.`);
        continue;
      }
      const handles = await page.$$("table tbody tr");
      const rows: string[][] = [];
      for (const tr of handles) {
        const cells = await tr.$$("td");
        const texts: string[] = [];
        for (const td of cells) {
          const t = await td.textContent();
          texts.push((t || "").trim());
        }
        rows.push(texts);
      }
      for (const row of rows) {
        if (row.length < 2) continue;
        const catName = row[0]?.toLowerCase().replace(/\s+/g, " ").trim();
        const tier1 = row[1] || undefined;
        const tier2 = row[2] || undefined;
        if (!catName) continue;
        for (const c of CATEGORIES) {
          if (c.name.toLowerCase().includes(catName) || catName.includes(c.name.toLowerCase())) {
            overrides.set(c.id, { tier1, tier2 });
            break;
          }
        }
      }
    }
    await browser.close();
  } catch (err) {
    console.warn("Live scrape skipped:", (err as Error).message);
  }
  return overrides;
}

async function main() {
  mkdirSync(OUT_DIR, { recursive: true });
  const overrides = await tryLiveScrape();
  const merged = CATEGORIES.map((c) => {
    const o = overrides.get(c.id);
    return {
      ...c,
      tier1_benchmark: o?.tier1 || c.tier1_benchmark,
      tier2_benchmark: o?.tier2 || c.tier2_benchmark,
    };
  });
  writeFileSync(join(OUT_DIR, "amfi_categories.json"), JSON.stringify(merged, null, 2));
  console.log(`Wrote ${merged.length} categories to out/amfi_categories.json`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
