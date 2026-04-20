/// SEBI Mutual Fund Scheme Categorization & Taxation Reference
/// Based on SEBI Circular SEBI/HO/IMD/DF3/CIR/P/2017/114 (Oct 6, 2017)
/// and subsequent amendments including Finance Act 2024 (new tax regime from 23-Jul-2024)
///
/// This file defines:
///  1. All 36 SEBI sub-categories with allocation rules
///  2. Mapping to fund_master.category, fund_type, tax_category columns
///  3. Capital gains tax rules per category (post Jul-2024 budget)

// ═══════════════════════════════════════════════════════════════════════════════
// SEBI DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════════════
//
// Large Cap : Top 100 companies by full market capitalisation
// Mid Cap   : 101st–250th companies by full market capitalisation
// Small Cap : 251st company onwards by full market capitalisation
//
// Macaulay Duration: Weighted average time to receive all cash flows from a bond.
// ═══════════════════════════════════════════════════════════════════════════════

/// SEBI-defined scheme sub-category with allocation rules and tax mapping.
enum SebiSchemeCategory {
  // ─────────────────────── GROUP 1: EQUITY SCHEMES ───────────────────────
  /// Min 80% in large-cap stocks
  largeCap,

  /// Min 65% in large-cap + mid-cap (min 25% each)
  largeAndMidCap,

  /// Min 65% in mid-cap stocks
  midCap,

  /// Min 65% in small-cap stocks
  smallCap,

  /// Min 75% each in large-cap, mid-cap, small-cap (min 25% each)
  multiCap,

  /// Min 65% in equity (flexible across market caps)
  flexiCap,

  /// Min 80% in equity following value investment strategy
  value,

  /// Min 80% in equity following contrarian investment strategy
  contra,

  /// Min 65% in equity, max 30 stocks (can be multi-cap or focused on a cap)
  focused,

  /// Min 65% in equity of a particular sector
  sectoral,

  /// Min 80% in equity of a particular theme
  thematic,

  /// Min 65% in dividend-yielding stocks
  dividendYield,

  /// Min 80% in equity, 3-year lock-in, Sec 80C deduction up to ₹1.5L
  elss,

  // ─────────────────────── GROUP 2: DEBT SCHEMES ─────────────────────────
  /// Securities with overnight maturity
  overnight,

  /// Debt & money market, maturity ≤ 91 days
  liquid,

  /// Macaulay duration 3–6 months
  ultraShortDuration,

  /// Macaulay duration 6–12 months
  lowDuration,

  /// Money market instruments, maturity ≤ 1 year
  moneyMarket,

  /// Macaulay duration 1–3 years
  shortDuration,

  /// Macaulay duration 3–4 years
  mediumDuration,

  /// Macaulay duration 4–7 years
  mediumToLongDuration,

  /// Macaulay duration > 7 years
  longDuration,

  /// Invest across duration (fund manager discretion)
  dynamicBond,

  /// Min 80% in AA+ and above rated corporate bonds
  corporateBond,

  /// Min 65% in AA and below rated corporate bonds
  creditRisk,

  /// Min 80% in banking, PSU, PFI debt instruments
  bankingAndPsu,

  /// Min 80% in G-Secs (across maturities)
  gilt,

  /// Min 80% in G-Secs with constant 10-year maturity
  giltWith10YrConstant,

  /// Min 65% in floating rate instruments
  floater,

  // ─────────────────────── GROUP 3: HYBRID SCHEMES ───────────────────────
  /// Equity 10–25%, Debt 75–90%
  conservativeHybrid,

  /// Equity 40–60%, Debt 40–60% (no arbitrage allowed)
  balancedHybrid,

  /// Equity 65–80%, Debt 20–35%
  aggressiveHybrid,

  /// Equity managed dynamically (0–100% equity via models/hedging)
  balancedAdvantage,

  /// Min 3 asset classes with min 10% each (equity, debt, gold, etc.)
  multiAssetAllocation,

  /// Min 65% in equity+arbitrage, arbitrage predominant
  arbitrage,

  /// Min 65% in equity (of which min 10% debt), uses derivatives
  equitySavings,

  // ──────────────────── GROUP 4: SOLUTION ORIENTED ───────────────────────
  /// Lock-in ≥ 5 years or till retirement
  retirement,

  /// Lock-in ≥ 5 years or till child turns 18
  children,

  // ──────────────────── GROUP 5: OTHER SCHEMES ───────────────────────────
  /// Tracks an equity/debt/commodity index (ETF or Index Fund)
  indexFundOrEtf,

  /// Invests in units of other MF schemes
  fundOfFunds,
}

/// Complete metadata for a SEBI scheme sub-category.
class SchemeDefinition {
  const SchemeDefinition({
    required this.sebiCategory,
    required this.group,
    required this.sebiName,
    required this.minEquity,
    required this.maxEquity,
    required this.minDebt,
    required this.maxDebt,
    this.macaulayDurationMin,
    this.macaulayDurationMax,
    this.maxStocks,
    this.lockInYears,
    this.otherAllocation,
    required this.dbFundType,
    required this.dbTaxCategory,
    required this.description,
  });

  final SebiSchemeCategory sebiCategory;
  final String group;           // "Equity", "Debt", "Hybrid", "Solution", "Other"
  final String sebiName;        // SEBI official name
  final double minEquity;       // Min equity allocation % (0–100)
  final double maxEquity;       // Max equity allocation %
  final double minDebt;         // Min debt allocation %
  final double maxDebt;         // Max debt allocation %
  final String? macaulayDurationMin; // e.g. "3 months", "1 year"
  final String? macaulayDurationMax; // e.g. "6 months", "3 years"
  final int? maxStocks;         // If capped (e.g. Focused = 30)
  final int? lockInYears;       // ELSS = 3, Retirement/Children = 5
  final String? otherAllocation; // Additional allocation rules
  final String dbFundType;      // Maps to fund_master.fund_type
  final String dbTaxCategory;   // Maps to fund_master.tax_category
  final String description;     // What it does
}

/// Complete SEBI scheme definitions — all 36 sub-categories.
const List<SchemeDefinition> sebiSchemeDefinitions = [
  // ═══════════════════════════════════════════════════════════════════════════
  // EQUITY SCHEMES (13 sub-categories)
  // fund_type = "Equity", tax_category = "Equity"
  // LTCG holding period: > 12 months | STCG: ≤ 12 months
  // ═══════════════════════════════════════════════════════════════════════════
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.largeCap,
    group: 'Equity',
    sebiName: 'Large Cap Fund',
    minEquity: 80, maxEquity: 100, minDebt: 0, maxDebt: 20,
    dbFundType: 'Equity', dbTaxCategory: 'Equity',
    description: 'Min 80% in large-cap stocks (top 100 by market cap)',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.largeAndMidCap,
    group: 'Equity',
    sebiName: 'Large & Mid Cap Fund',
    minEquity: 65, maxEquity: 100, minDebt: 0, maxDebt: 35,
    otherAllocation: 'Min 35% in large-cap, min 35% in mid-cap',
    dbFundType: 'Equity', dbTaxCategory: 'Equity',
    description: 'Min 35% each in large-cap and mid-cap stocks',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.midCap,
    group: 'Equity',
    sebiName: 'Mid Cap Fund',
    minEquity: 65, maxEquity: 100, minDebt: 0, maxDebt: 35,
    dbFundType: 'Equity', dbTaxCategory: 'Equity',
    description: 'Min 65% in mid-cap stocks (101st–250th by market cap)',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.smallCap,
    group: 'Equity',
    sebiName: 'Small Cap Fund',
    minEquity: 65, maxEquity: 100, minDebt: 0, maxDebt: 35,
    dbFundType: 'Equity', dbTaxCategory: 'Equity',
    description: 'Min 65% in small-cap stocks (251st onwards by market cap)',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.multiCap,
    group: 'Equity',
    sebiName: 'Multi Cap Fund',
    minEquity: 75, maxEquity: 100, minDebt: 0, maxDebt: 25,
    otherAllocation: 'Min 25% each in large-cap, mid-cap, small-cap',
    dbFundType: 'Equity', dbTaxCategory: 'Equity',
    description: 'Min 25% each in large, mid, and small-cap stocks',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.flexiCap,
    group: 'Equity',
    sebiName: 'Flexi Cap Fund',
    minEquity: 65, maxEquity: 100, minDebt: 0, maxDebt: 35,
    dbFundType: 'Equity', dbTaxCategory: 'Equity',
    description: 'Min 65% in equity, flexible across market caps',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.value,
    group: 'Equity',
    sebiName: 'Value Fund',
    minEquity: 65, maxEquity: 100, minDebt: 0, maxDebt: 35,
    dbFundType: 'Equity', dbTaxCategory: 'Equity',
    description: 'Min 65% in equity following value investment strategy',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.contra,
    group: 'Equity',
    sebiName: 'Contra Fund',
    minEquity: 65, maxEquity: 100, minDebt: 0, maxDebt: 35,
    dbFundType: 'Equity', dbTaxCategory: 'Equity',
    description: 'Min 65% in equity following contrarian strategy',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.focused,
    group: 'Equity',
    sebiName: 'Focused Fund',
    minEquity: 65, maxEquity: 100, minDebt: 0, maxDebt: 35,
    maxStocks: 30,
    dbFundType: 'Equity', dbTaxCategory: 'Equity',
    description: 'Min 65% in equity, max 30 stocks',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.sectoral,
    group: 'Equity',
    sebiName: 'Sectoral/Thematic Fund',
    minEquity: 80, maxEquity: 100, minDebt: 0, maxDebt: 20,
    dbFundType: 'Equity', dbTaxCategory: 'Equity',
    description: 'Min 80% in equity of a particular sector',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.thematic,
    group: 'Equity',
    sebiName: 'Thematic Fund',
    minEquity: 80, maxEquity: 100, minDebt: 0, maxDebt: 20,
    dbFundType: 'Equity', dbTaxCategory: 'Equity',
    description: 'Min 80% in equity of a particular theme',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.dividendYield,
    group: 'Equity',
    sebiName: 'Dividend Yield Fund',
    minEquity: 65, maxEquity: 100, minDebt: 0, maxDebt: 35,
    dbFundType: 'Equity', dbTaxCategory: 'Equity',
    description: 'Min 65% in dividend-yielding stocks',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.elss,
    group: 'Equity',
    sebiName: 'ELSS (Tax Savings)',
    minEquity: 80, maxEquity: 100, minDebt: 0, maxDebt: 20,
    lockInYears: 3,
    dbFundType: 'Equity', dbTaxCategory: 'Equity',
    description: 'Min 80% in equity, 3-year lock-in, Sec 80C eligible (₹1.5L)',
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // DEBT SCHEMES (16 sub-categories)
  // fund_type = "Debt", tax_category = "Debt"
  // Post Apr-2023: Gains taxed at slab rate (no LTCG benefit, no indexation)
  // ═══════════════════════════════════════════════════════════════════════════
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.overnight,
    group: 'Debt',
    sebiName: 'Overnight Fund',
    minEquity: 0, maxEquity: 0, minDebt: 100, maxDebt: 100,
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Invests in securities with overnight maturity',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.liquid,
    group: 'Debt',
    sebiName: 'Liquid Fund',
    minEquity: 0, maxEquity: 0, minDebt: 100, maxDebt: 100,
    macaulayDurationMax: '91 days',
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Debt & money market securities, maturity ≤ 91 days',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.ultraShortDuration,
    group: 'Debt',
    sebiName: 'Ultra Short Duration Fund',
    minEquity: 0, maxEquity: 0, minDebt: 100, maxDebt: 100,
    macaulayDurationMin: '3 months', macaulayDurationMax: '6 months',
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Macaulay duration 3–6 months',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.lowDuration,
    group: 'Debt',
    sebiName: 'Low Duration Fund',
    minEquity: 0, maxEquity: 0, minDebt: 100, maxDebt: 100,
    macaulayDurationMin: '6 months', macaulayDurationMax: '12 months',
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Macaulay duration 6–12 months',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.moneyMarket,
    group: 'Debt',
    sebiName: 'Money Market Fund',
    minEquity: 0, maxEquity: 0, minDebt: 100, maxDebt: 100,
    macaulayDurationMax: '1 year',
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Money market instruments with maturity ≤ 1 year',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.shortDuration,
    group: 'Debt',
    sebiName: 'Short Duration Fund',
    minEquity: 0, maxEquity: 0, minDebt: 100, maxDebt: 100,
    macaulayDurationMin: '1 year', macaulayDurationMax: '3 years',
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Macaulay duration 1–3 years',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.mediumDuration,
    group: 'Debt',
    sebiName: 'Medium Duration Fund',
    minEquity: 0, maxEquity: 0, minDebt: 100, maxDebt: 100,
    macaulayDurationMin: '3 years', macaulayDurationMax: '4 years',
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Macaulay duration 3–4 years',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.mediumToLongDuration,
    group: 'Debt',
    sebiName: 'Medium to Long Duration Fund',
    minEquity: 0, maxEquity: 0, minDebt: 100, maxDebt: 100,
    macaulayDurationMin: '4 years', macaulayDurationMax: '7 years',
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Macaulay duration 4–7 years',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.longDuration,
    group: 'Debt',
    sebiName: 'Long Duration Fund',
    minEquity: 0, maxEquity: 0, minDebt: 100, maxDebt: 100,
    macaulayDurationMin: '7 years',
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Macaulay duration > 7 years',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.dynamicBond,
    group: 'Debt',
    sebiName: 'Dynamic Bond Fund',
    minEquity: 0, maxEquity: 0, minDebt: 100, maxDebt: 100,
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Invest across duration — fund manager discretion',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.corporateBond,
    group: 'Debt',
    sebiName: 'Corporate Bond Fund',
    minEquity: 0, maxEquity: 0, minDebt: 80, maxDebt: 100,
    otherAllocation: 'Min 80% in AA+ and above rated corporate bonds',
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Min 80% in highest rated (AA+) corporate bonds',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.creditRisk,
    group: 'Debt',
    sebiName: 'Credit Risk Fund',
    minEquity: 0, maxEquity: 0, minDebt: 65, maxDebt: 100,
    otherAllocation: 'Min 65% in AA and below rated corporate bonds',
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Min 65% in below AA+ rated corporate bonds (higher risk)',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.bankingAndPsu,
    group: 'Debt',
    sebiName: 'Banking and PSU Fund',
    minEquity: 0, maxEquity: 0, minDebt: 80, maxDebt: 100,
    otherAllocation: 'Min 80% in banking, PSU, PFI debt',
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Min 80% in debt of banks, PSUs, public financial institutions',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.gilt,
    group: 'Debt',
    sebiName: 'Gilt Fund',
    minEquity: 0, maxEquity: 0, minDebt: 80, maxDebt: 100,
    otherAllocation: 'Min 80% in G-Secs across maturities',
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Min 80% in government securities across maturities',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.giltWith10YrConstant,
    group: 'Debt',
    sebiName: 'Gilt Fund with 10-year Constant Duration',
    minEquity: 0, maxEquity: 0, minDebt: 80, maxDebt: 100,
    macaulayDurationMin: '10 years', macaulayDurationMax: '10 years',
    otherAllocation: 'Min 80% in G-Secs with Macaulay duration = 10 years',
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Min 80% in G-Secs, portfolio Macaulay duration = 10 years',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.floater,
    group: 'Debt',
    sebiName: 'Floater Fund',
    minEquity: 0, maxEquity: 0, minDebt: 65, maxDebt: 100,
    otherAllocation: 'Min 65% in floating rate instruments',
    dbFundType: 'Debt', dbTaxCategory: 'Debt',
    description: 'Min 65% in floating rate instruments (incl. fixed-to-float swaps)',
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // HYBRID SCHEMES (7 sub-categories)
  // Tax treatment depends on equity allocation:
  //   ≥ 65% equity → taxed as equity (Hybrid-E)
  //   < 65% equity → taxed as debt (Hybrid-D / slab rate post Apr-2023)
  // ═══════════════════════════════════════════════════════════════════════════
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.conservativeHybrid,
    group: 'Hybrid',
    sebiName: 'Conservative Hybrid Fund',
    minEquity: 10, maxEquity: 25, minDebt: 75, maxDebt: 90,
    dbFundType: 'Hybrid', dbTaxCategory: 'Hybrid-D',
    description: 'Equity 10–25%, Debt 75–90% — debt-oriented hybrid',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.balancedHybrid,
    group: 'Hybrid',
    sebiName: 'Balanced Hybrid Fund',
    minEquity: 40, maxEquity: 60, minDebt: 40, maxDebt: 60,
    otherAllocation: 'No arbitrage permitted in this category',
    dbFundType: 'Hybrid', dbTaxCategory: 'Hybrid-D',
    description: 'Equity 40–60%, Debt 40–60%, no arbitrage allowed',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.aggressiveHybrid,
    group: 'Hybrid',
    sebiName: 'Aggressive Hybrid Fund',
    minEquity: 65, maxEquity: 80, minDebt: 20, maxDebt: 35,
    dbFundType: 'Hybrid', dbTaxCategory: 'Hybrid-E',
    description: 'Equity 65–80%, Debt 20–35% — equity-oriented hybrid',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.balancedAdvantage,
    group: 'Hybrid',
    sebiName: 'Dynamic Asset Allocation / Balanced Advantage Fund',
    minEquity: 0, maxEquity: 100, minDebt: 0, maxDebt: 100,
    otherAllocation: 'Dynamic equity allocation managed via models/hedging; '
        'most maintain ≥65% gross equity for equity taxation',
    dbFundType: 'Hybrid', dbTaxCategory: 'Hybrid-E',
    description: 'Dynamic equity/debt allocation; usually structured for equity tax',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.multiAssetAllocation,
    group: 'Hybrid',
    sebiName: 'Multi Asset Allocation Fund',
    minEquity: 10, maxEquity: 80, minDebt: 10, maxDebt: 80,
    otherAllocation: 'Min 3 asset classes, min 10% each. '
        'If equity ≥65% → Hybrid-E, else Hybrid-D',
    dbFundType: 'Hybrid', dbTaxCategory: 'Hybrid-E',
    description: 'Min 3 asset classes (equity, debt, gold/REIT) with min 10% each',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.arbitrage,
    group: 'Hybrid',
    sebiName: 'Arbitrage Fund',
    minEquity: 65, maxEquity: 100, minDebt: 0, maxDebt: 35,
    otherAllocation: 'Min 65% in equity & arbitrage positions',
    dbFundType: 'Hybrid', dbTaxCategory: 'Hybrid-E',
    description: 'Cash-futures arbitrage; min 65% equity for equity taxation',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.equitySavings,
    group: 'Hybrid',
    sebiName: 'Equity Savings Fund',
    minEquity: 65, maxEquity: 100, minDebt: 10, maxDebt: 35,
    otherAllocation: 'Min 65% equity (including hedged equity via derivatives), '
        'min 10% debt',
    dbFundType: 'Hybrid', dbTaxCategory: 'Hybrid-E',
    description: 'Equity + arbitrage + debt; min 65% gross equity',
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // SOLUTION ORIENTED SCHEMES (2 sub-categories)
  // Tax depends on actual allocation (mostly equity-oriented → Hybrid-E/Equity)
  // ═══════════════════════════════════════════════════════════════════════════
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.retirement,
    group: 'Solution',
    sebiName: 'Retirement Fund',
    minEquity: 0, maxEquity: 100, minDebt: 0, maxDebt: 100,
    lockInYears: 5,
    dbFundType: 'Hybrid', dbTaxCategory: 'Hybrid-E',
    description: 'Lock-in ≥ 5 years or till retirement age',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.children,
    group: 'Solution',
    sebiName: "Children's Fund",
    minEquity: 0, maxEquity: 100, minDebt: 0, maxDebt: 100,
    lockInYears: 5,
    dbFundType: 'Hybrid', dbTaxCategory: 'Hybrid-E',
    description: 'Lock-in ≥ 5 years or till child attains 18',
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // OTHER SCHEMES (2 sub-categories)
  // Tax depends on underlying: equity index → Equity, debt index → Debt,
  // gold ETF → Gold, international FoF → International
  // ═══════════════════════════════════════════════════════════════════════════
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.indexFundOrEtf,
    group: 'Other',
    sebiName: 'Index Fund / ETF',
    minEquity: 0, maxEquity: 100, minDebt: 0, maxDebt: 100,
    otherAllocation: 'Min 95% in securities of the tracked index. '
        'Tax depends on underlying: equity index → Equity, '
        'debt index → Debt, gold → Gold ETF',
    dbFundType: 'Index', dbTaxCategory: 'Equity',
    description: 'Passively tracks a market index; tax per underlying',
  ),
  SchemeDefinition(
    sebiCategory: SebiSchemeCategory.fundOfFunds,
    group: 'Other',
    sebiName: 'Fund of Funds',
    minEquity: 0, maxEquity: 100, minDebt: 0, maxDebt: 100,
    otherAllocation: 'Min 95% in underlying fund units. '
        'Domestic equity FoF → Equity tax; '
        'International FoF → slab rate; Gold FoF → Gold tax',
    dbFundType: 'FOF', dbTaxCategory: 'Equity',
    description: 'Invests in units of other MF schemes; tax per underlying',
  ),
];

// ═══════════════════════════════════════════════════════════════════════════════
// TAXATION RULES (Post Finance Act 2024 — effective 23-Jul-2024)
// ═══════════════════════════════════════════════════════════════════════════════
//
// ┌──────────────────────┬──────────────┬───────────┬────────────┬───────────────┐
// │ Category             │ LTCG Holding │ LTCG Rate │ STCG Rate  │ Exemption     │
// ├──────────────────────┼──────────────┼───────────┼────────────┼───────────────┤
// │ Equity MF (≥65% eq)  │ > 12 months  │ 12.5%     │ 20%        │ ₹1.25L LTCG  │
// │ Hybrid-E (≥65% eq)   │ > 12 months  │ 12.5%     │ 20%        │ ₹1.25L LTCG  │
// │ Hybrid-D (<65% eq)   │ > 24 months  │ 12.5%     │ Slab rate  │ ₹1.25L LTCG  │
// │ Debt MF (pure debt)  │ Always STCG  │ N/A       │ Slab rate  │ None          │
// │  (bought after       │              │           │            │               │
// │   01-Apr-2023)       │              │           │            │               │
// │ Gold ETF / Gold FoF  │ > 24 months  │ 12.5%     │ Slab rate  │ ₹1.25L LTCG  │
// │ International FoF    │ Always STCG  │ N/A       │ Slab rate  │ None          │
// │  (bought after       │              │           │            │               │
// │   01-Apr-2023)       │              │           │            │               │
// │ SGB (maturity)       │ > 12 months  │ Exempt    │ Slab rate  │ Full exempt   │
// │ SGB (early redeem)   │ > 12 months  │ 12.5%     │ Slab rate  │ ₹1.25L LTCG  │
// └──────────────────────┴──────────────┴───────────┴────────────┴───────────────┘
//
// GRANDFATHERING (Equity & Hybrid-E bought before 31-Jan-2018):
//   Cost basis = MAX(actual cost, MIN(Jan 31 2018 NAV, sale price))
//   This eliminates gains accrued before 31-Jan-2018 from LTCG taxation.
//
// SURCHARGE on capital gains:
//   LTCG — max surcharge capped at 15% (regardless of income level)
//   STCG — normal surcharge slabs apply
//
// CESS: 4% Health & Education Cess on tax + surcharge
//
// STT: 0.001% on equity MF redemption (paid by seller)
//
// TDS on MF redemptions: No TDS for resident individuals (except ≥₹10L IDCW)
//
// KEY NOTES:
// 1. Debt MFs bought BEFORE 01-Apr-2023 still get indexation benefit (20% LTCG
//    after 3 years holding). Only new purchases lose LTCG status.
// 2. ELSS has 3-year lock-in but same equity tax treatment.
// 3. Balanced Advantage / BAF: Most are structured to maintain ≥65% gross equity
//    (using arbitrage + derivatives) to get equity tax treatment.
// 4. Arbitrage funds: ≥65% equity → equity taxation despite low net equity.
// 5. Multi-asset with ≥65% equity → Hybrid-E. Check actual fund allocation.
// 6. Index funds/ETFs/FoFs: Tax depends on the underlying tracked asset.
// ═══════════════════════════════════════════════════════════════════════════════

/// Helper: look up a scheme definition by its SEBI category enum.
SchemeDefinition getSchemeDefinition(SebiSchemeCategory category) {
  return sebiSchemeDefinitions.firstWhere((d) => d.sebiCategory == category);
}

/// Helper: find all scheme definitions for a given group.
List<SchemeDefinition> getSchemesByGroup(String group) {
  return sebiSchemeDefinitions.where((d) => d.group == group).toList();
}

/// Maps a fund_master.category string (e.g. "Equity Scheme - Flexi Cap Fund")
/// to the closest SebiSchemeCategory. Returns null if no match.
SebiSchemeCategory? matchSebiCategory(String? categoryString) {
  if (categoryString == null) return null;
  final lower = categoryString.toLowerCase();

  // Equity categories
  if (lower.contains('large cap') && lower.contains('mid cap')) {
    return SebiSchemeCategory.largeAndMidCap;
  }
  if (lower.contains('large cap')) return SebiSchemeCategory.largeCap;
  if (lower.contains('mid cap')) return SebiSchemeCategory.midCap;
  if (lower.contains('small cap')) return SebiSchemeCategory.smallCap;
  if (lower.contains('multi cap')) return SebiSchemeCategory.multiCap;
  if (lower.contains('flexi cap')) return SebiSchemeCategory.flexiCap;
  if (lower.contains('value')) return SebiSchemeCategory.value;
  if (lower.contains('contra')) return SebiSchemeCategory.contra;
  if (lower.contains('focused')) return SebiSchemeCategory.focused;
  if (lower.contains('sectoral') || lower.contains('sector')) {
    return SebiSchemeCategory.sectoral;
  }
  if (lower.contains('thematic')) return SebiSchemeCategory.thematic;
  if (lower.contains('dividend yield')) return SebiSchemeCategory.dividendYield;
  if (lower.contains('elss') || lower.contains('tax sav')) {
    return SebiSchemeCategory.elss;
  }

  // Debt categories
  if (lower.contains('overnight')) return SebiSchemeCategory.overnight;
  if (lower.contains('liquid')) return SebiSchemeCategory.liquid;
  if (lower.contains('ultra short')) return SebiSchemeCategory.ultraShortDuration;
  if (lower.contains('low duration')) return SebiSchemeCategory.lowDuration;
  if (lower.contains('money market')) return SebiSchemeCategory.moneyMarket;
  if (lower.contains('short duration')) return SebiSchemeCategory.shortDuration;
  if (lower.contains('medium to long')) {
    return SebiSchemeCategory.mediumToLongDuration;
  }
  if (lower.contains('medium duration')) return SebiSchemeCategory.mediumDuration;
  if (lower.contains('long duration')) return SebiSchemeCategory.longDuration;
  if (lower.contains('dynamic bond') || lower.contains('dynamic debt')) {
    return SebiSchemeCategory.dynamicBond;
  }
  if (lower.contains('corporate bond')) return SebiSchemeCategory.corporateBond;
  if (lower.contains('credit risk')) return SebiSchemeCategory.creditRisk;
  if (lower.contains('banking') && lower.contains('psu')) {
    return SebiSchemeCategory.bankingAndPsu;
  }
  if (lower.contains('gilt') && lower.contains('10')) {
    return SebiSchemeCategory.giltWith10YrConstant;
  }
  if (lower.contains('gilt')) return SebiSchemeCategory.gilt;
  if (lower.contains('floater')) return SebiSchemeCategory.floater;

  // Hybrid categories
  if (lower.contains('conservative hybrid')) {
    return SebiSchemeCategory.conservativeHybrid;
  }
  if (lower.contains('aggressive hybrid')) {
    return SebiSchemeCategory.aggressiveHybrid;
  }
  if (lower.contains('balanced hybrid')) return SebiSchemeCategory.balancedHybrid;
  if (lower.contains('balanced advantage') || lower.contains('dynamic asset')) {
    return SebiSchemeCategory.balancedAdvantage;
  }
  if (lower.contains('multi asset')) {
    return SebiSchemeCategory.multiAssetAllocation;
  }
  if (lower.contains('arbitrage')) return SebiSchemeCategory.arbitrage;
  if (lower.contains('equity savings')) return SebiSchemeCategory.equitySavings;

  // Solution oriented
  if (lower.contains('retirement')) return SebiSchemeCategory.retirement;
  if (lower.contains('child')) return SebiSchemeCategory.children;

  // Other
  if (lower.contains('index') || lower.contains('etf') || lower.contains('nifty') || lower.contains('sensex')) {
    return SebiSchemeCategory.indexFundOrEtf;
  }
  if (lower.contains('fund of fund') || lower.contains('fof')) {
    return SebiSchemeCategory.fundOfFunds;
  }

  return null;
}
