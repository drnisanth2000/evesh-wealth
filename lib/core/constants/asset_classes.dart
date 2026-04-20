/// Asset class and tax category enumerations
/// These mirror the fund_master.tax_category and fund_master.fund_type columns

enum AssetClass {
  coreEquity,
  satelliteEquity,
  hybrid,
  debt,
  liquid,
  gold,
  alternate;

  String get displayName {
    switch (this) {
      case AssetClass.coreEquity: return 'Core Equity';
      case AssetClass.satelliteEquity: return 'Satellite Equity';
      case AssetClass.hybrid: return 'Hybrid';
      case AssetClass.debt: return 'Debt';
      case AssetClass.liquid: return 'Liquid';
      case AssetClass.gold: return 'Gold';
      case AssetClass.alternate: return 'Alternate';
    }
  }

  /// Maps category string from DB to enum
  static AssetClass fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'core equity': return AssetClass.coreEquity;
      case 'satellite equity': return AssetClass.satelliteEquity;
      case 'hybrid': return AssetClass.hybrid;
      case 'debt': return AssetClass.debt;
      case 'liquid': return AssetClass.liquid;
      case 'gold': return AssetClass.gold;
      case 'alternate': return AssetClass.alternate;
      case 'coreequity': return AssetClass.coreEquity;
      case 'satelliteequity': return AssetClass.satelliteEquity;
      default: return AssetClass.alternate;
    }
  }
}

enum TaxCategory {
  equity,       // Equity MF >65% — LTCG 12.5% / STCG 20%
  hybridE,      // Equity-oriented hybrid — same as equity
  hybridD,      // Debt-oriented hybrid — slab rate
  debt,         // Pure debt MF — slab rate
  sgb,          // Sovereign Gold Bond maturity — tax-free; early STCG
  goldEtf,      // Gold ETF — treated as non-equity
  international,// International / FoF — slab rate
  exempt;       // PPF, EPF, Gratuity etc.

  bool get isEquityType => this == TaxCategory.equity || this == TaxCategory.hybridE;
  bool get isDebtType => this == TaxCategory.debt || this == TaxCategory.hybridD || this == TaxCategory.international;
  bool get isGoldFofType => this == TaxCategory.goldEtf;

  String get displayName {
    switch (this) {
      case TaxCategory.equity: return 'Equity';
      case TaxCategory.hybridE: return 'Hybrid-Equity';
      case TaxCategory.hybridD: return 'Hybrid-Debt';
      case TaxCategory.debt: return 'Debt';
      case TaxCategory.sgb: return 'SGB';
      case TaxCategory.goldEtf: return 'Gold ETF';
      case TaxCategory.international: return 'International';
      case TaxCategory.exempt: return 'Exempt';
    }
  }

  static TaxCategory fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'equity': return TaxCategory.equity;
      case 'hybrid-e': case 'hybrid-equity': return TaxCategory.hybridE;
      case 'hybrid-d': case 'hybrid-debt': return TaxCategory.hybridD;
      case 'debt': return TaxCategory.debt;
      case 'sgb': return TaxCategory.sgb;
      case 'gold': case 'gold etf': return TaxCategory.goldEtf;
      case 'international': return TaxCategory.international;
      case 'exempt': return TaxCategory.exempt;
      default: return TaxCategory.debt;
    }
  }
}

enum TransactionType {
  buy,
  sell,
  sip,
  swp,
  switchIn,
  switchOut,
  idcw,
  bonus,
  stxBuy,
  stxSell,
  stpIn,
  stpOut,
  transferIn,
  transferOut,
  idcwPayout,
  idcwReinvest,
  dividend,
  interest,
  maturity;

  bool get isPurchase => [buy, sip, switchIn, stxBuy, stpIn, bonus, idcw, idcwReinvest, transferIn].contains(this);
  bool get isRedemption => [sell, swp, switchOut, stxSell, stpOut, transferOut].contains(this);
  bool get isCashOnly => [idcwPayout].contains(this);

  String get displayName {
    switch (this) {
      case TransactionType.buy: return 'BUY';
      case TransactionType.sell: return 'SELL';
      case TransactionType.sip: return 'SIP';
      case TransactionType.swp: return 'SWP';
      case TransactionType.switchIn: return 'Switch-In';
      case TransactionType.switchOut: return 'Switch-Out';
      case TransactionType.idcw: return 'IDCW';
      case TransactionType.bonus: return 'Bonus';
      case TransactionType.stxBuy: return 'STX-BUY';
      case TransactionType.stxSell: return 'STX-SELL';
      case TransactionType.stpIn: return 'STP-In';
      case TransactionType.stpOut: return 'STP-Out';
      case TransactionType.transferIn: return 'Transfer-In';
      case TransactionType.transferOut: return 'Transfer-Out';
      case TransactionType.idcwPayout: return 'IDCW-Payout';
      case TransactionType.idcwReinvest: return 'IDCW-Reinvest';
      case TransactionType.dividend: return 'Dividend';
      case TransactionType.interest: return 'Interest';
      case TransactionType.maturity: return 'Maturity';
    }
  }

  static TransactionType fromString(String s) {
    switch (s.toUpperCase()) {
      case 'BUY': return TransactionType.buy;
      case 'SELL': return TransactionType.sell;
      case 'SIP': return TransactionType.sip;
      case 'SWP': return TransactionType.swp;
      case 'SWITCH-IN': return TransactionType.switchIn;
      case 'SWITCH-OUT': return TransactionType.switchOut;
      case 'IDCW': return TransactionType.idcw;
      case 'BONUS': return TransactionType.bonus;
      case 'STX-BUY': return TransactionType.stxBuy;
      case 'STX-SELL': return TransactionType.stxSell;
      case 'STP-IN': return TransactionType.stpIn;
      case 'STP-OUT': return TransactionType.stpOut;
      case 'TRANSFER-IN': return TransactionType.transferIn;
      case 'TRANSFER-OUT': return TransactionType.transferOut;
      case 'IDCW-PAYOUT': return TransactionType.idcwPayout;
      case 'IDCW-REINVEST': return TransactionType.idcwReinvest;
      case 'DIVIDEND': return TransactionType.dividend;
      case 'INTEREST': return TransactionType.interest;
      case 'MATURITY': return TransactionType.maturity;
      default: return TransactionType.buy;
    }
  }
}

enum AssetType {
  mf, stock, pms, gold, realEstate,
  sgb, reit, invIt, fd, ppf, nps, aif, sif, other;

  String get displayName {
    switch (this) {
      case AssetType.mf: return 'Mutual Fund';
      case AssetType.stock: return 'Stock';
      case AssetType.pms: return 'PMS';
      case AssetType.gold: return 'Gold';
      case AssetType.realEstate: return 'Real Estate';
      case AssetType.sgb: return 'SGB';
      case AssetType.reit: return 'REIT';
      case AssetType.invIt: return 'InvIT';
      case AssetType.fd: return 'Fixed Deposit';
      case AssetType.ppf: return 'PPF';
      case AssetType.nps: return 'NPS';
      case AssetType.aif: return 'AIF';
      case AssetType.sif: return 'SIF';
      case AssetType.other: return 'Other';
    }
  }

  /// True for asset types without live market NAV — user enters current value manually.
  bool get isManualValuation => this != AssetType.mf;

  String get dbValue {
    switch (this) {
      case AssetType.mf: return 'MF';
      case AssetType.stock: return 'Stock';
      case AssetType.pms: return 'PMS';
      case AssetType.gold: return 'Gold';
      case AssetType.realEstate: return 'RealEstate';
      case AssetType.sgb: return 'SGB';
      case AssetType.reit: return 'REIT';
      case AssetType.invIt: return 'InvIT';
      case AssetType.fd: return 'FD';
      case AssetType.ppf: return 'PPF';
      case AssetType.nps: return 'NPS';
      case AssetType.aif: return 'AIF';
      case AssetType.sif: return 'SIF';
      case AssetType.other: return 'Other';
    }
  }
}

enum SubscriptionTier {
  free, individual, family;

  String get displayName {
    switch (this) {
      case SubscriptionTier.free: return 'Free';
      case SubscriptionTier.individual: return 'Individual';
      case SubscriptionTier.family: return 'Family';
    }
  }

  bool get isPaid => this != SubscriptionTier.free;
  bool get isFamily => this == SubscriptionTier.family;

  static SubscriptionTier fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'individual': return SubscriptionTier.individual;
      case 'family': return SubscriptionTier.family;
      default: return SubscriptionTier.free;
    }
  }
}
