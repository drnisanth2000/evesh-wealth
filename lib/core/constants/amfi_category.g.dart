// GENERATED -- do not edit by hand. Run tools/amfi_scraper/gen_dart.ts (or _gen.py)

import 'asset_classes.dart';
import '../../data/models/goal_model.dart' show GoalTerm;

enum AmfiCategory {
  equityLargeCap,
  equityLargeAndMidCap,
  equityMidCap,
  equitySmallCap,
  equityMultiCap,
  equityFlexiCap,
  equityFocused,
  equityDividendYield,
  equityValue,
  equityContra,
  equityElss,
  equitySectoralThematic,
  debtOvernight,
  debtLiquid,
  debtUltraShort,
  debtLowDuration,
  debtMoneyMarket,
  debtShortDuration,
  debtMediumDuration,
  debtMediumLongDuration,
  debtLongDuration,
  debtDynamicBond,
  debtCorporateBond,
  debtCreditRisk,
  debtBankingPsu,
  debtGilt,
  debtGilt10yr,
  debtFloater,
  hybridConservative,
  hybridBalanced,
  hybridAggressive,
  hybridDynamicAssetAllocation,
  hybridMultiAsset,
  hybridArbitrage,
  hybridEquitySavings,
  solutionRetirement,
  solutionChildren,
  otherIndexFund,
  otherEtf,
  otherFofDomestic,
  otherFofOverseas,
  otherGoldEtf,
}

extension AmfiCategoryX on AmfiCategory {
  String get id {
    switch (this) {
      case AmfiCategory.equityLargeCap: return 'equity_large_cap';
      case AmfiCategory.equityLargeAndMidCap: return 'equity_large_and_mid_cap';
      case AmfiCategory.equityMidCap: return 'equity_mid_cap';
      case AmfiCategory.equitySmallCap: return 'equity_small_cap';
      case AmfiCategory.equityMultiCap: return 'equity_multi_cap';
      case AmfiCategory.equityFlexiCap: return 'equity_flexi_cap';
      case AmfiCategory.equityFocused: return 'equity_focused';
      case AmfiCategory.equityDividendYield: return 'equity_dividend_yield';
      case AmfiCategory.equityValue: return 'equity_value';
      case AmfiCategory.equityContra: return 'equity_contra';
      case AmfiCategory.equityElss: return 'equity_elss';
      case AmfiCategory.equitySectoralThematic: return 'equity_sectoral_thematic';
      case AmfiCategory.debtOvernight: return 'debt_overnight';
      case AmfiCategory.debtLiquid: return 'debt_liquid';
      case AmfiCategory.debtUltraShort: return 'debt_ultra_short';
      case AmfiCategory.debtLowDuration: return 'debt_low_duration';
      case AmfiCategory.debtMoneyMarket: return 'debt_money_market';
      case AmfiCategory.debtShortDuration: return 'debt_short_duration';
      case AmfiCategory.debtMediumDuration: return 'debt_medium_duration';
      case AmfiCategory.debtMediumLongDuration: return 'debt_medium_long_duration';
      case AmfiCategory.debtLongDuration: return 'debt_long_duration';
      case AmfiCategory.debtDynamicBond: return 'debt_dynamic_bond';
      case AmfiCategory.debtCorporateBond: return 'debt_corporate_bond';
      case AmfiCategory.debtCreditRisk: return 'debt_credit_risk';
      case AmfiCategory.debtBankingPsu: return 'debt_banking_psu';
      case AmfiCategory.debtGilt: return 'debt_gilt';
      case AmfiCategory.debtGilt10yr: return 'debt_gilt_10yr';
      case AmfiCategory.debtFloater: return 'debt_floater';
      case AmfiCategory.hybridConservative: return 'hybrid_conservative';
      case AmfiCategory.hybridBalanced: return 'hybrid_balanced';
      case AmfiCategory.hybridAggressive: return 'hybrid_aggressive';
      case AmfiCategory.hybridDynamicAssetAllocation: return 'hybrid_dynamic_asset_allocation';
      case AmfiCategory.hybridMultiAsset: return 'hybrid_multi_asset';
      case AmfiCategory.hybridArbitrage: return 'hybrid_arbitrage';
      case AmfiCategory.hybridEquitySavings: return 'hybrid_equity_savings';
      case AmfiCategory.solutionRetirement: return 'solution_retirement';
      case AmfiCategory.solutionChildren: return 'solution_children';
      case AmfiCategory.otherIndexFund: return 'other_index_fund';
      case AmfiCategory.otherEtf: return 'other_etf';
      case AmfiCategory.otherFofDomestic: return 'other_fof_domestic';
      case AmfiCategory.otherFofOverseas: return 'other_fof_overseas';
      case AmfiCategory.otherGoldEtf: return 'other_gold_etf';
    }
  }

  String get superCategory {
    switch (this) {
      case AmfiCategory.equityLargeCap: return 'Equity';
      case AmfiCategory.equityLargeAndMidCap: return 'Equity';
      case AmfiCategory.equityMidCap: return 'Equity';
      case AmfiCategory.equitySmallCap: return 'Equity';
      case AmfiCategory.equityMultiCap: return 'Equity';
      case AmfiCategory.equityFlexiCap: return 'Equity';
      case AmfiCategory.equityFocused: return 'Equity';
      case AmfiCategory.equityDividendYield: return 'Equity';
      case AmfiCategory.equityValue: return 'Equity';
      case AmfiCategory.equityContra: return 'Equity';
      case AmfiCategory.equityElss: return 'Equity';
      case AmfiCategory.equitySectoralThematic: return 'Equity';
      case AmfiCategory.debtOvernight: return 'Debt';
      case AmfiCategory.debtLiquid: return 'Debt';
      case AmfiCategory.debtUltraShort: return 'Debt';
      case AmfiCategory.debtLowDuration: return 'Debt';
      case AmfiCategory.debtMoneyMarket: return 'Debt';
      case AmfiCategory.debtShortDuration: return 'Debt';
      case AmfiCategory.debtMediumDuration: return 'Debt';
      case AmfiCategory.debtMediumLongDuration: return 'Debt';
      case AmfiCategory.debtLongDuration: return 'Debt';
      case AmfiCategory.debtDynamicBond: return 'Debt';
      case AmfiCategory.debtCorporateBond: return 'Debt';
      case AmfiCategory.debtCreditRisk: return 'Debt';
      case AmfiCategory.debtBankingPsu: return 'Debt';
      case AmfiCategory.debtGilt: return 'Debt';
      case AmfiCategory.debtGilt10yr: return 'Debt';
      case AmfiCategory.debtFloater: return 'Debt';
      case AmfiCategory.hybridConservative: return 'Hybrid';
      case AmfiCategory.hybridBalanced: return 'Hybrid';
      case AmfiCategory.hybridAggressive: return 'Hybrid';
      case AmfiCategory.hybridDynamicAssetAllocation: return 'Hybrid';
      case AmfiCategory.hybridMultiAsset: return 'Hybrid';
      case AmfiCategory.hybridArbitrage: return 'Hybrid';
      case AmfiCategory.hybridEquitySavings: return 'Hybrid';
      case AmfiCategory.solutionRetirement: return 'Solution';
      case AmfiCategory.solutionChildren: return 'Solution';
      case AmfiCategory.otherIndexFund: return 'Other';
      case AmfiCategory.otherEtf: return 'Other';
      case AmfiCategory.otherFofDomestic: return 'Other';
      case AmfiCategory.otherFofOverseas: return 'Other';
      case AmfiCategory.otherGoldEtf: return 'Other';
    }
  }

  String get displayName {
    switch (this) {
      case AmfiCategory.equityLargeCap: return 'Large Cap Fund';
      case AmfiCategory.equityLargeAndMidCap: return 'Large & Mid Cap Fund';
      case AmfiCategory.equityMidCap: return 'Mid Cap Fund';
      case AmfiCategory.equitySmallCap: return 'Small Cap Fund';
      case AmfiCategory.equityMultiCap: return 'Multi Cap Fund';
      case AmfiCategory.equityFlexiCap: return 'Flexi Cap Fund';
      case AmfiCategory.equityFocused: return 'Focused Fund';
      case AmfiCategory.equityDividendYield: return 'Dividend Yield Fund';
      case AmfiCategory.equityValue: return 'Value Fund';
      case AmfiCategory.equityContra: return 'Contra Fund';
      case AmfiCategory.equityElss: return 'ELSS';
      case AmfiCategory.equitySectoralThematic: return 'Sectoral / Thematic Fund';
      case AmfiCategory.debtOvernight: return 'Overnight Fund';
      case AmfiCategory.debtLiquid: return 'Liquid Fund';
      case AmfiCategory.debtUltraShort: return 'Ultra Short Duration Fund';
      case AmfiCategory.debtLowDuration: return 'Low Duration Fund';
      case AmfiCategory.debtMoneyMarket: return 'Money Market Fund';
      case AmfiCategory.debtShortDuration: return 'Short Duration Fund';
      case AmfiCategory.debtMediumDuration: return 'Medium Duration Fund';
      case AmfiCategory.debtMediumLongDuration: return 'Medium to Long Duration Fund';
      case AmfiCategory.debtLongDuration: return 'Long Duration Fund';
      case AmfiCategory.debtDynamicBond: return 'Dynamic Bond Fund';
      case AmfiCategory.debtCorporateBond: return 'Corporate Bond Fund';
      case AmfiCategory.debtCreditRisk: return 'Credit Risk Fund';
      case AmfiCategory.debtBankingPsu: return 'Banking and PSU Fund';
      case AmfiCategory.debtGilt: return 'Gilt Fund';
      case AmfiCategory.debtGilt10yr: return 'Gilt Fund with 10 Year Constant Duration';
      case AmfiCategory.debtFloater: return 'Floater Fund';
      case AmfiCategory.hybridConservative: return 'Conservative Hybrid Fund';
      case AmfiCategory.hybridBalanced: return 'Balanced Hybrid Fund';
      case AmfiCategory.hybridAggressive: return 'Aggressive Hybrid Fund';
      case AmfiCategory.hybridDynamicAssetAllocation: return 'Dynamic Asset Allocation / Balanced Advantage Fund';
      case AmfiCategory.hybridMultiAsset: return 'Multi Asset Allocation Fund';
      case AmfiCategory.hybridArbitrage: return 'Arbitrage Fund';
      case AmfiCategory.hybridEquitySavings: return 'Equity Savings Fund';
      case AmfiCategory.solutionRetirement: return 'Retirement Fund';
      case AmfiCategory.solutionChildren: return 'Children\'s Fund';
      case AmfiCategory.otherIndexFund: return 'Index Fund';
      case AmfiCategory.otherEtf: return 'ETF';
      case AmfiCategory.otherFofDomestic: return 'FoF (Domestic)';
      case AmfiCategory.otherFofOverseas: return 'FoF (Overseas)';
      case AmfiCategory.otherGoldEtf: return 'Gold ETF / Gold Fund';
    }
  }

  String get tier1Benchmark {
    switch (this) {
      case AmfiCategory.equityLargeCap: return 'NIFTY 100 TRI';
      case AmfiCategory.equityLargeAndMidCap: return 'NIFTY LargeMidcap 250 TRI';
      case AmfiCategory.equityMidCap: return 'NIFTY Midcap 150 TRI';
      case AmfiCategory.equitySmallCap: return 'NIFTY Smallcap 250 TRI';
      case AmfiCategory.equityMultiCap: return 'NIFTY 500 Multicap 50:25:25 TRI';
      case AmfiCategory.equityFlexiCap: return 'NIFTY 500 TRI';
      case AmfiCategory.equityFocused: return 'NIFTY 500 TRI';
      case AmfiCategory.equityDividendYield: return 'NIFTY 500 TRI';
      case AmfiCategory.equityValue: return 'NIFTY 500 TRI';
      case AmfiCategory.equityContra: return 'NIFTY 500 TRI';
      case AmfiCategory.equityElss: return 'NIFTY 500 TRI';
      case AmfiCategory.equitySectoralThematic: return 'Sectoral / Thematic TRI';
      case AmfiCategory.debtOvernight: return 'NIFTY 1D Rate Index';
      case AmfiCategory.debtLiquid: return 'NIFTY Liquid Index';
      case AmfiCategory.debtUltraShort: return 'NIFTY Ultra Short Duration Debt Index';
      case AmfiCategory.debtLowDuration: return 'NIFTY Low Duration Debt Index';
      case AmfiCategory.debtMoneyMarket: return 'NIFTY Money Market Index';
      case AmfiCategory.debtShortDuration: return 'NIFTY Short Duration Debt Index';
      case AmfiCategory.debtMediumDuration: return 'NIFTY Medium Duration Debt Index';
      case AmfiCategory.debtMediumLongDuration: return 'NIFTY Medium to Long Duration Debt Index';
      case AmfiCategory.debtLongDuration: return 'NIFTY Long Duration Debt Index';
      case AmfiCategory.debtDynamicBond: return 'NIFTY Composite Debt Index';
      case AmfiCategory.debtCorporateBond: return 'NIFTY Corporate Bond Index';
      case AmfiCategory.debtCreditRisk: return 'NIFTY Credit Risk Bond Index';
      case AmfiCategory.debtBankingPsu: return 'NIFTY Banking & PSU Debt Index';
      case AmfiCategory.debtGilt: return 'NIFTY All Duration G-Sec Index';
      case AmfiCategory.debtGilt10yr: return 'NIFTY 10 Yr Benchmark G-Sec Index';
      case AmfiCategory.debtFloater: return 'NIFTY Composite Debt Index';
      case AmfiCategory.hybridConservative: return 'NIFTY 50 Hybrid Composite Debt 15:85 Index';
      case AmfiCategory.hybridBalanced: return 'NIFTY 50 Hybrid Composite Debt 50:50 Index';
      case AmfiCategory.hybridAggressive: return 'CRISIL Hybrid 35+65 Aggressive Index';
      case AmfiCategory.hybridDynamicAssetAllocation: return 'NIFTY 50 Hybrid Composite Debt 50:50 Index';
      case AmfiCategory.hybridMultiAsset: return 'NIFTY 50 Hybrid Composite Debt 65:35 Index';
      case AmfiCategory.hybridArbitrage: return 'NIFTY 50 Arbitrage Index';
      case AmfiCategory.hybridEquitySavings: return 'NIFTY Equity Savings Index';
      case AmfiCategory.solutionRetirement: return 'CRISIL Hybrid 35+65 Aggressive Index';
      case AmfiCategory.solutionChildren: return 'CRISIL Hybrid 35+65 Aggressive Index';
      case AmfiCategory.otherIndexFund: return 'Underlying Index TRI';
      case AmfiCategory.otherEtf: return 'Underlying Index TRI';
      case AmfiCategory.otherFofDomestic: return 'NIFTY 50 Hybrid Composite Debt 65:35 Index';
      case AmfiCategory.otherFofOverseas: return 'MSCI World Index';
      case AmfiCategory.otherGoldEtf: return 'Domestic Price of Gold';
    }
  }

  String get tier2Benchmark {
    switch (this) {
      case AmfiCategory.equityLargeCap: return 'S&P BSE 100 TRI';
      case AmfiCategory.equityLargeAndMidCap: return 'S&P BSE 250 LargeMidCap TRI';
      case AmfiCategory.equityMidCap: return 'S&P BSE 150 MidCap TRI';
      case AmfiCategory.equitySmallCap: return 'S&P BSE 250 SmallCap TRI';
      case AmfiCategory.equityMultiCap: return 'S&P BSE 500 TRI';
      case AmfiCategory.equityFlexiCap: return 'S&P BSE 500 TRI';
      case AmfiCategory.equityFocused: return 'S&P BSE 500 TRI';
      case AmfiCategory.equityDividendYield: return 'S&P BSE 500 TRI';
      case AmfiCategory.equityValue: return 'S&P BSE 500 TRI';
      case AmfiCategory.equityContra: return 'S&P BSE 500 TRI';
      case AmfiCategory.equityElss: return 'S&P BSE 500 TRI';
      case AmfiCategory.equitySectoralThematic: return 'NIFTY 500 TRI';
      case AmfiCategory.debtOvernight: return 'CRISIL Overnight Index';
      case AmfiCategory.debtLiquid: return 'CRISIL Liquid Fund Index';
      case AmfiCategory.debtUltraShort: return 'CRISIL Ultra Short Term Debt Index';
      case AmfiCategory.debtLowDuration: return 'CRISIL Low Duration Debt Index';
      case AmfiCategory.debtMoneyMarket: return 'CRISIL Money Market Index';
      case AmfiCategory.debtShortDuration: return 'CRISIL Short Term Bond Index';
      case AmfiCategory.debtMediumDuration: return 'CRISIL Medium Term Bond Index';
      case AmfiCategory.debtMediumLongDuration: return 'CRISIL Medium to Long Term Bond Index';
      case AmfiCategory.debtLongDuration: return 'CRISIL Long Term Bond Index';
      case AmfiCategory.debtDynamicBond: return 'CRISIL Composite Bond Index';
      case AmfiCategory.debtCorporateBond: return 'CRISIL Corporate Bond Index';
      case AmfiCategory.debtCreditRisk: return 'CRISIL Credit Risk Bond Index';
      case AmfiCategory.debtBankingPsu: return 'CRISIL Banking and PSU Debt Index';
      case AmfiCategory.debtGilt: return 'CRISIL Dynamic Gilt Index';
      case AmfiCategory.debtGilt10yr: return 'CRISIL 10 Year Gilt Index';
      case AmfiCategory.debtFloater: return 'CRISIL Composite Bond Index';
      case AmfiCategory.hybridConservative: return 'CRISIL Hybrid 85+15 Conservative Index';
      case AmfiCategory.hybridBalanced: return 'CRISIL Hybrid 50+50 Balanced Index';
      case AmfiCategory.hybridAggressive: return 'NIFTY 50 Hybrid Composite Debt 65:35 Index';
      case AmfiCategory.hybridDynamicAssetAllocation: return 'CRISIL Hybrid 50+50 Moderate Index';
      case AmfiCategory.hybridMultiAsset: return 'CRISIL Hybrid 65+35 Aggressive Index';
      case AmfiCategory.hybridArbitrage: return 'CRISIL BSE Liquid Rate Index';
      case AmfiCategory.hybridEquitySavings: return 'CRISIL Equity Savings Index';
      case AmfiCategory.solutionRetirement: return 'NIFTY 50 Hybrid Composite Debt 65:35 Index';
      case AmfiCategory.solutionChildren: return 'NIFTY 50 Hybrid Composite Debt 65:35 Index';
      case AmfiCategory.otherIndexFund: return 'NIFTY 50 TRI';
      case AmfiCategory.otherEtf: return 'NIFTY 50 TRI';
      case AmfiCategory.otherFofDomestic: return 'CRISIL Hybrid 65+35 Aggressive Index';
      case AmfiCategory.otherFofOverseas: return 'S&P 500 TRI';
      case AmfiCategory.otherGoldEtf: return 'MCX Gold';
    }
  }

  GoalTerm get defaultTerm {
    switch (this) {
      case AmfiCategory.equityLargeCap: return GoalTerm.longTerm;
      case AmfiCategory.equityLargeAndMidCap: return GoalTerm.longTerm;
      case AmfiCategory.equityMidCap: return GoalTerm.longTerm;
      case AmfiCategory.equitySmallCap: return GoalTerm.longTerm;
      case AmfiCategory.equityMultiCap: return GoalTerm.longTerm;
      case AmfiCategory.equityFlexiCap: return GoalTerm.longTerm;
      case AmfiCategory.equityFocused: return GoalTerm.longTerm;
      case AmfiCategory.equityDividendYield: return GoalTerm.longTerm;
      case AmfiCategory.equityValue: return GoalTerm.longTerm;
      case AmfiCategory.equityContra: return GoalTerm.longTerm;
      case AmfiCategory.equityElss: return GoalTerm.longTerm;
      case AmfiCategory.equitySectoralThematic: return GoalTerm.longTerm;
      case AmfiCategory.debtOvernight: return GoalTerm.shortTerm;
      case AmfiCategory.debtLiquid: return GoalTerm.shortTerm;
      case AmfiCategory.debtUltraShort: return GoalTerm.shortTerm;
      case AmfiCategory.debtLowDuration: return GoalTerm.mediumTerm;
      case AmfiCategory.debtMoneyMarket: return GoalTerm.shortTerm;
      case AmfiCategory.debtShortDuration: return GoalTerm.mediumTerm;
      case AmfiCategory.debtMediumDuration: return GoalTerm.mediumTerm;
      case AmfiCategory.debtMediumLongDuration: return GoalTerm.mediumTerm;
      case AmfiCategory.debtLongDuration: return GoalTerm.mediumTerm;
      case AmfiCategory.debtDynamicBond: return GoalTerm.mediumTerm;
      case AmfiCategory.debtCorporateBond: return GoalTerm.mediumTerm;
      case AmfiCategory.debtCreditRisk: return GoalTerm.mediumTerm;
      case AmfiCategory.debtBankingPsu: return GoalTerm.mediumTerm;
      case AmfiCategory.debtGilt: return GoalTerm.mediumTerm;
      case AmfiCategory.debtGilt10yr: return GoalTerm.mediumTerm;
      case AmfiCategory.debtFloater: return GoalTerm.mediumTerm;
      case AmfiCategory.hybridConservative: return GoalTerm.mediumTerm;
      case AmfiCategory.hybridBalanced: return GoalTerm.longTerm;
      case AmfiCategory.hybridAggressive: return GoalTerm.longTerm;
      case AmfiCategory.hybridDynamicAssetAllocation: return GoalTerm.longTerm;
      case AmfiCategory.hybridMultiAsset: return GoalTerm.longTerm;
      case AmfiCategory.hybridArbitrage: return GoalTerm.mediumTerm;
      case AmfiCategory.hybridEquitySavings: return GoalTerm.mediumTerm;
      case AmfiCategory.solutionRetirement: return GoalTerm.longTerm;
      case AmfiCategory.solutionChildren: return GoalTerm.longTerm;
      case AmfiCategory.otherIndexFund: return GoalTerm.longTerm;
      case AmfiCategory.otherEtf: return GoalTerm.longTerm;
      case AmfiCategory.otherFofDomestic: return GoalTerm.longTerm;
      case AmfiCategory.otherFofOverseas: return GoalTerm.longTerm;
      case AmfiCategory.otherGoldEtf: return GoalTerm.mediumTerm;
    }
  }

  AssetClass get defaultAssetClass {
    switch (this) {
      case AmfiCategory.equityLargeCap: return AssetClass.coreEquity;
      case AmfiCategory.equityLargeAndMidCap: return AssetClass.coreEquity;
      case AmfiCategory.equityMidCap: return AssetClass.satelliteEquity;
      case AmfiCategory.equitySmallCap: return AssetClass.satelliteEquity;
      case AmfiCategory.equityMultiCap: return AssetClass.coreEquity;
      case AmfiCategory.equityFlexiCap: return AssetClass.coreEquity;
      case AmfiCategory.equityFocused: return AssetClass.coreEquity;
      case AmfiCategory.equityDividendYield: return AssetClass.coreEquity;
      case AmfiCategory.equityValue: return AssetClass.satelliteEquity;
      case AmfiCategory.equityContra: return AssetClass.satelliteEquity;
      case AmfiCategory.equityElss: return AssetClass.satelliteEquity;
      case AmfiCategory.equitySectoralThematic: return AssetClass.satelliteEquity;
      case AmfiCategory.debtOvernight: return AssetClass.liquid;
      case AmfiCategory.debtLiquid: return AssetClass.liquid;
      case AmfiCategory.debtUltraShort: return AssetClass.liquid;
      case AmfiCategory.debtLowDuration: return AssetClass.debt;
      case AmfiCategory.debtMoneyMarket: return AssetClass.liquid;
      case AmfiCategory.debtShortDuration: return AssetClass.debt;
      case AmfiCategory.debtMediumDuration: return AssetClass.debt;
      case AmfiCategory.debtMediumLongDuration: return AssetClass.debt;
      case AmfiCategory.debtLongDuration: return AssetClass.debt;
      case AmfiCategory.debtDynamicBond: return AssetClass.debt;
      case AmfiCategory.debtCorporateBond: return AssetClass.debt;
      case AmfiCategory.debtCreditRisk: return AssetClass.debt;
      case AmfiCategory.debtBankingPsu: return AssetClass.debt;
      case AmfiCategory.debtGilt: return AssetClass.debt;
      case AmfiCategory.debtGilt10yr: return AssetClass.debt;
      case AmfiCategory.debtFloater: return AssetClass.debt;
      case AmfiCategory.hybridConservative: return AssetClass.hybrid;
      case AmfiCategory.hybridBalanced: return AssetClass.hybrid;
      case AmfiCategory.hybridAggressive: return AssetClass.hybrid;
      case AmfiCategory.hybridDynamicAssetAllocation: return AssetClass.hybrid;
      case AmfiCategory.hybridMultiAsset: return AssetClass.hybrid;
      case AmfiCategory.hybridArbitrage: return AssetClass.hybrid;
      case AmfiCategory.hybridEquitySavings: return AssetClass.hybrid;
      case AmfiCategory.solutionRetirement: return AssetClass.hybrid;
      case AmfiCategory.solutionChildren: return AssetClass.hybrid;
      case AmfiCategory.otherIndexFund: return AssetClass.coreEquity;
      case AmfiCategory.otherEtf: return AssetClass.coreEquity;
      case AmfiCategory.otherFofDomestic: return AssetClass.hybrid;
      case AmfiCategory.otherFofOverseas: return AssetClass.satelliteEquity;
      case AmfiCategory.otherGoldEtf: return AssetClass.gold;
    }
  }

  TaxCategory get defaultTaxCategory {
    switch (this) {
      case AmfiCategory.equityLargeCap: return TaxCategory.equity;
      case AmfiCategory.equityLargeAndMidCap: return TaxCategory.equity;
      case AmfiCategory.equityMidCap: return TaxCategory.equity;
      case AmfiCategory.equitySmallCap: return TaxCategory.equity;
      case AmfiCategory.equityMultiCap: return TaxCategory.equity;
      case AmfiCategory.equityFlexiCap: return TaxCategory.equity;
      case AmfiCategory.equityFocused: return TaxCategory.equity;
      case AmfiCategory.equityDividendYield: return TaxCategory.equity;
      case AmfiCategory.equityValue: return TaxCategory.equity;
      case AmfiCategory.equityContra: return TaxCategory.equity;
      case AmfiCategory.equityElss: return TaxCategory.equity;
      case AmfiCategory.equitySectoralThematic: return TaxCategory.equity;
      case AmfiCategory.debtOvernight: return TaxCategory.debt;
      case AmfiCategory.debtLiquid: return TaxCategory.debt;
      case AmfiCategory.debtUltraShort: return TaxCategory.debt;
      case AmfiCategory.debtLowDuration: return TaxCategory.debt;
      case AmfiCategory.debtMoneyMarket: return TaxCategory.debt;
      case AmfiCategory.debtShortDuration: return TaxCategory.debt;
      case AmfiCategory.debtMediumDuration: return TaxCategory.debt;
      case AmfiCategory.debtMediumLongDuration: return TaxCategory.debt;
      case AmfiCategory.debtLongDuration: return TaxCategory.debt;
      case AmfiCategory.debtDynamicBond: return TaxCategory.debt;
      case AmfiCategory.debtCorporateBond: return TaxCategory.debt;
      case AmfiCategory.debtCreditRisk: return TaxCategory.debt;
      case AmfiCategory.debtBankingPsu: return TaxCategory.debt;
      case AmfiCategory.debtGilt: return TaxCategory.debt;
      case AmfiCategory.debtGilt10yr: return TaxCategory.debt;
      case AmfiCategory.debtFloater: return TaxCategory.debt;
      case AmfiCategory.hybridConservative: return TaxCategory.hybridD;
      case AmfiCategory.hybridBalanced: return TaxCategory.hybridE;
      case AmfiCategory.hybridAggressive: return TaxCategory.hybridE;
      case AmfiCategory.hybridDynamicAssetAllocation: return TaxCategory.hybridE;
      case AmfiCategory.hybridMultiAsset: return TaxCategory.hybridE;
      case AmfiCategory.hybridArbitrage: return TaxCategory.hybridD;
      case AmfiCategory.hybridEquitySavings: return TaxCategory.hybridD;
      case AmfiCategory.solutionRetirement: return TaxCategory.hybridE;
      case AmfiCategory.solutionChildren: return TaxCategory.hybridE;
      case AmfiCategory.otherIndexFund: return TaxCategory.equity;
      case AmfiCategory.otherEtf: return TaxCategory.equity;
      case AmfiCategory.otherFofDomestic: return TaxCategory.hybridE;
      case AmfiCategory.otherFofOverseas: return TaxCategory.international;
      case AmfiCategory.otherGoldEtf: return TaxCategory.goldEtf;
    }
  }

  static AmfiCategory? fromId(String id) {
    for (final v in AmfiCategory.values) {
      if (v.id == id) return v;
    }
    return null;
  }
}
