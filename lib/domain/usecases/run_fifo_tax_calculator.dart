import '../../core/constants/app_constants.dart';
import '../../core/constants/asset_classes.dart';

export '../../core/constants/asset_classes.dart' show TaxCategory;

/// A single purchase lot (BUY/SIP/Switch-In) for FIFO matching
class TaxLot {
  const TaxLot({
    required this.txId,
    required this.date,
    required this.units,
    required this.costPerUnit,
    required this.totalCost,
  });

  final String txId;
  final DateTime date;
  final double units;
  final double costPerUnit;
  final double totalCost;
}

/// Result of FIFO tax calculation for one sell transaction
class TaxLotMatchResult {
  const TaxLotMatchResult({
    required this.unitsMatched,
    required this.costBasis,
    required this.adjustedCostBasis,
    required this.saleProceeds,
    required this.gain,
    required this.holdingDays,
    required this.isLtcg,
    required this.taxCategory,
    required this.gainType,
    this.wasGrandfathered = false,
  });

  final double unitsMatched;
  final double costBasis;       // original cost
  final double adjustedCostBasis; // after grandfathering adjustment
  final double saleProceeds;
  final double gain;            // proceeds - adjustedCostBasis
  final int holdingDays;
  final bool isLtcg;
  final TaxCategory taxCategory;
  final String gainType; // 'equity_ltcg', 'equity_stcg', 'gold_ltcg', 'gold_stcg', 'debt_slab'
  final bool wasGrandfathered;
}

/// Per-fund tax breakdown for the UI
class FundTaxBreakdown {
  FundTaxBreakdown({
    required this.fundName,
    required this.amfiCode,
    required this.taxCategory,
    required this.memberId,
  });

  final String fundName;
  final int amfiCode;
  final TaxCategory taxCategory;
  final String memberId;

  double equityLtcgGain = 0;
  double equityStcgGain = 0;
  double goldLtcgGain = 0;
  double goldStcgGain = 0;
  double debtGain = 0;
  double totalGain = 0;
  double equityLtcgLoss = 0;
  double equityStcgLoss = 0;
  double goldLtcgLoss = 0;
  double goldStcgLoss = 0;
  double debtLoss = 0;
  double totalLoss = 0;
  double grandfatheringBenefit = 0;
  int sellCount = 0;
  int buyLotCount = 0;
  double totalBuyUnits = 0;
  double unmatchedSellUnits = 0;
  List<TaxLotMatchResult> lotMatches = [];

  /// Total cost basis (invested) from all lot matches
  double get totalCostBasis =>
      lotMatches.fold(0.0, (s, m) => s + m.costBasis);

  /// Total sale proceeds (redeemed) from all lot matches
  double get totalSaleProceeds =>
      lotMatches.fold(0.0, (s, m) => s + m.saleProceeds);

  /// Net short-term gain/loss (equity STCG + gold STCG + debt slab)
  double get netStcg =>
      (equityStcgGain - equityStcgLoss) +
      (goldStcgGain - goldStcgLoss) +
      (debtGain - debtLoss);

  /// Net long-term gain/loss (equity LTCG + gold LTCG)
  double get netLtcg =>
      (equityLtcgGain - equityLtcgLoss) +
      (goldLtcgGain - goldLtcgLoss);

  /// Net total gain/loss
  double get netTotal => netStcg + netLtcg;
}

/// Per-member tax summary for a financial year
class MemberTaxSummary {
  MemberTaxSummary({
    required this.memberId,
    required this.memberName,
    required this.fy,
    this.taxSlabPct = 0.30,
  });

  final String memberId;
  final String memberName;
  final String fy; // "FY2526"
  final double taxSlabPct;

  double equityLtcgGain = 0;
  double equityStcgGain = 0;
  double goldLtcgGain = 0;
  double goldStcgGain = 0;
  double debtSlabGain = 0;
  double equityLtcgExemptionUsed = 0;
  double equityLtcgTaxableGain = 0;
  double equityLtcgTax = 0;
  double equityStcgTax = 0;
  double goldLtcgTax = 0;
  double goldStcgTax = 0;
  double debtSlabTax = 0;
  double totalTaxBeforeCess = 0;
  double cess = 0;
  double totalTax = 0;
  double netGain = 0;
  double unusedLtcgExemption = AppConstants.ltcgExemptionPerPersonPerFy;
  double grandfatheringBenefit = 0;

  // Capital losses (for offset tracking per IT Act Sec 70-71)
  double equityLtcgLoss = 0;
  double equityStcgLoss = 0;
  double goldLtcgLoss = 0;
  double goldStcgLoss = 0;
  double debtSlabLoss = 0;

  // Loss offset amounts applied
  double stLossOffsetVsStcg = 0; // ST loss absorbed against STCG
  double stLossOffsetVsLtcg = 0; // ST loss absorbed against LTCG
  double ltLossOffsetVsLtcg = 0; // LT loss absorbed against LTCG
  double lossCarryForward = 0;   // remaining loss (carry forward up to 8 AYs)

  double get totalLoss => equityLtcgLoss + equityStcgLoss +
      goldLtcgLoss + goldStcgLoss + debtSlabLoss;
  double get totalLossOffset => stLossOffsetVsStcg +
      stLossOffsetVsLtcg + ltLossOffsetVsLtcg;

  /// Per-fund breakdown for detailed view
  List<FundTaxBreakdown> fundBreakdowns = [];
}

/// FIFO Tax Calculator
///
/// Rules (FY 2025-26, post July 2024 Budget):
/// - Equity MF LTCG (>365 days): 12.5% above Rs 1.25L exemption/person/FY
/// - Equity MF STCG (≤365 days): 20%
/// - Gold ETF / FoF LTCG (>730 days, post-Budget): 12.5%
/// - Gold ETF / FoF STCG (≤730 days): slab rate
/// - Debt MF (post-Apr 2023): always slab rate
/// - Debt MF (pre-Apr 2023, >36 months): 20% with indexation (not implemented yet)
/// - SGB maturity: tax-free
/// - 4% Health & Education Cess on all tax
/// - Grandfathering: Equity bought before Feb 1, 2018 uses adjusted cost basis
class FifoTaxCalculator {
  FifoTaxCalculator._();

  /// Compute tax for all sell transactions using FIFO lot matching.
  static ({
    List<TaxLotMatchResult> lotMatches,
    double totalLtcgGain,
    double totalStcgGain,
    double goldLtcgGain,
    double goldStcgGain,
    double debtGain,
    double totalLtcgLoss,
    double totalStcgLoss,
    double goldLtcgLoss,
    double goldStcgLoss,
    double debtLoss,
    double ltcgTax,
    double stcgTax,
    double goldLtcgTax,
    double goldStcgTax,
    double debtTax,
    double totalTax,
    double ltcgExemptionUsed,
    double unusedExemption,
    double grandfatheringBenefit,
    double unmatchedSellUnits,
  }) compute({
    required List<TaxLot> openLots,
    required List<({DateTime date, double units, double navAtSell})> sells,
    required TaxCategory taxCategory,
    required double taxSlabPct,
    double existingLtcgGainInFy = 0,
    bool isSgbMaturity = false,
    double? jan31Nav,       // NAV on Jan 31, 2018 for grandfathering
  }) {
    if (isSgbMaturity) {
      return (
        lotMatches: [],
        totalLtcgGain: 0,
        totalStcgGain: 0,
        goldLtcgGain: 0,
        goldStcgGain: 0,
        debtGain: 0,
        totalLtcgLoss: 0,
        totalStcgLoss: 0,
        goldLtcgLoss: 0,
        goldStcgLoss: 0,
        debtLoss: 0,
        ltcgTax: 0,
        stcgTax: 0,
        goldLtcgTax: 0,
        goldStcgTax: 0,
        debtTax: 0,
        totalTax: 0,
        ltcgExemptionUsed: 0,
        unusedExemption: AppConstants.ltcgExemptionPerPersonPerFy - existingLtcgGainInFy,
        grandfatheringBenefit: 0,
        unmatchedSellUnits: 0,
      );
    }

    // Mutable lot queue for FIFO matching
    final lots = openLots.map((l) => _MutableLot(
      txId: l.txId,
      date: l.date,
      remainingUnits: l.units,
      costPerUnit: l.costPerUnit,
    )).toList();

    final matches = <TaxLotMatchResult>[];
    double totalGrandfatheringBenefit = 0;
    double unmatchedSellUnits = 0;

    for (final sell in sells) {
      double remainingToSell = sell.units;

      for (final lot in lots) {
        if (remainingToSell <= 0) break;
        if (lot.remainingUnits <= 0) continue;

        final unitsFromLot = remainingToSell.clamp(0.0, lot.remainingUnits).toDouble();
        final holdingDays = sell.date.difference(lot.date).inDays;
        final isLtcg = _isLtcg(holdingDays, taxCategory);
        final gainType = _classifyGainType(taxCategory, isLtcg);

        final originalCostBasis = unitsFromLot * lot.costPerUnit;
        final proceeds = unitsFromLot * sell.navAtSell;

        // Apply grandfathering for equity lots bought before Feb 1, 2018
        double adjustedCostBasis = originalCostBasis;
        bool wasGrandfathered = false;

        if (taxCategory.isEquityType &&
            isLtcg &&
            lot.date.isBefore(AppConstants.grandfatheringCutoff) &&
            jan31Nav != null) {
          // Grandfathering: adjustedCost = max(actualCost, min(jan31Nav, saleNav))
          final jan31CostBasis = unitsFromLot * jan31Nav;
          final sellCostBasis = proceeds; // min(jan31Nav, saleNav) per unit
          final fairMarketValue = jan31CostBasis < sellCostBasis
              ? jan31CostBasis
              : sellCostBasis;
          if (fairMarketValue > originalCostBasis) {
            adjustedCostBasis = fairMarketValue;
            wasGrandfathered = true;
            totalGrandfatheringBenefit += (adjustedCostBasis - originalCostBasis);
          }
        }

        final gain = proceeds - adjustedCostBasis;

        matches.add(TaxLotMatchResult(
          unitsMatched: unitsFromLot,
          costBasis: originalCostBasis,
          adjustedCostBasis: adjustedCostBasis,
          saleProceeds: proceeds,
          gain: gain,
          holdingDays: holdingDays,
          isLtcg: isLtcg,
          taxCategory: taxCategory,
          gainType: gainType,
          wasGrandfathered: wasGrandfathered,
        ));

        lot.remainingUnits -= unitsFromLot;
        remainingToSell -= unitsFromLot;
      }

      // Track sells that couldn't be matched to any buy lot
      if (remainingToSell > 0.001) {
        unmatchedSellUnits += remainingToSell;
      }
    }

    // Aggregate gains and losses separately by type
    double totalLtcgGain = 0, totalLtcgLoss = 0;
    double totalStcgGain = 0, totalStcgLoss = 0;
    double goldLtcgGain = 0, goldLtcgLoss = 0;
    double goldStcgGain = 0, goldStcgLoss = 0;
    double totalDebtGain = 0, totalDebtLoss = 0;

    for (final m in matches) {
      switch (m.gainType) {
        case 'equity_ltcg':
          if (m.gain >= 0) {
            totalLtcgGain += m.gain;
          } else {
            totalLtcgLoss += m.gain.abs();
          }
          break;
        case 'equity_stcg':
          if (m.gain >= 0) {
            totalStcgGain += m.gain;
          } else {
            totalStcgLoss += m.gain.abs();
          }
          break;
        case 'gold_ltcg':
          if (m.gain >= 0) {
            goldLtcgGain += m.gain;
          } else {
            goldLtcgLoss += m.gain.abs();
          }
          break;
        case 'gold_stcg':
          if (m.gain >= 0) {
            goldStcgGain += m.gain;
          } else {
            goldStcgLoss += m.gain.abs();
          }
          break;
        case 'debt_slab':
          if (m.gain >= 0) {
            totalDebtGain += m.gain;
          } else {
            totalDebtLoss += m.gain.abs();
          }
          break;
      }
    }

    // Apply LTCG exemption (Rs 1.25L per FY, shared across all equity holdings)
    final exemption = AppConstants.ltcgExemptionPerPersonPerFy;
    final exemptionAlreadyUsed = existingLtcgGainInFy.clamp(0.0, exemption);
    final remainingExemption = (exemption - exemptionAlreadyUsed).clamp(0.0, exemption);
    final ltcgExemptionUsed = totalLtcgGain.clamp(0.0, remainingExemption);
    final taxableLtcgGain = (totalLtcgGain - ltcgExemptionUsed).clamp(0.0, double.infinity);
    final totalLtcgThisFy = existingLtcgGainInFy + totalLtcgGain;
    final unusedExemption = (exemption - totalLtcgThisFy).clamp(0.0, exemption);

    // Compute tax
    final ltcgTax = taxableLtcgGain * AppConstants.equityLtcgRate;
    final stcgTax = totalStcgGain.clamp(0.0, double.infinity) * AppConstants.equityStcgRate;
    final goldLtcgTax = goldLtcgGain.clamp(0.0, double.infinity) * AppConstants.goldFofLtcgRate;
    final goldStcgTax = goldStcgGain.clamp(0.0, double.infinity) * taxSlabPct;
    final debtTax = totalDebtGain.clamp(0.0, double.infinity) * taxSlabPct;

    final totalTaxBeforeCess = ltcgTax + stcgTax + goldLtcgTax + goldStcgTax + debtTax;
    final cess = totalTaxBeforeCess * AppConstants.healthEducationCess;
    final totalTax = totalTaxBeforeCess + cess;

    return (
      lotMatches: matches,
      totalLtcgGain: totalLtcgGain,
      totalStcgGain: totalStcgGain,
      goldLtcgGain: goldLtcgGain,
      goldStcgGain: goldStcgGain,
      debtGain: totalDebtGain,
      totalLtcgLoss: totalLtcgLoss,
      totalStcgLoss: totalStcgLoss,
      goldLtcgLoss: goldLtcgLoss,
      goldStcgLoss: goldStcgLoss,
      debtLoss: totalDebtLoss,
      ltcgTax: ltcgTax,
      stcgTax: stcgTax,
      goldLtcgTax: goldLtcgTax,
      goldStcgTax: goldStcgTax,
      debtTax: debtTax,
      totalTax: totalTax,
      ltcgExemptionUsed: ltcgExemptionUsed,
      unusedExemption: unusedExemption,
      grandfatheringBenefit: totalGrandfatheringBenefit,
      unmatchedSellUnits: unmatchedSellUnits,
    );
  }

  /// Determine if a holding qualifies for LTCG
  static bool _isLtcg(int holdingDays, TaxCategory category) {
    if (category.isEquityType) {
      return holdingDays >= AppConstants.equityLtcgHoldingDays;
    }
    if (category.isGoldFofType) {
      return holdingDays >= AppConstants.goldFofLtcgHoldingDays;
    }
    // Debt: post-Apr-2023 = always slab rate, no LTCG benefit
    // Pre-Apr-2023 debt with >36 months would get indexation benefit,
    // but we treat all debt as slab rate for simplicity
    return false;
  }

  /// Classify gain type for bucketing
  static String _classifyGainType(TaxCategory category, bool isLtcg) {
    if (category.isEquityType) {
      return isLtcg ? 'equity_ltcg' : 'equity_stcg';
    }
    if (category.isGoldFofType) {
      return isLtcg ? 'gold_ltcg' : 'gold_stcg';
    }
    return 'debt_slab';
  }
}

class _MutableLot {
  _MutableLot({
    required this.txId,
    required this.date,
    required this.remainingUnits,
    required this.costPerUnit,
  });

  final String txId;
  final DateTime date;
  double remainingUnits;
  final double costPerUnit;
}
