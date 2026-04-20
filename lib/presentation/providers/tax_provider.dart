import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/asset_classes.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/usecases/run_fifo_tax_calculator.dart';
import 'auth_provider.dart';
import 'family_provider.dart';
import 'portfolio_provider.dart';
import 'reconciliation_provider.dart';

part 'tax_provider.g.dart';

// ─── Financial Year helper ──────────────────────────────────────────────────
String currentFyKey() {
  final now = DateTime.now();
  final fyYear = now.month >= 4 ? now.year : now.year - 1;
  return 'FY${(fyYear % 100).toString().padLeft(2, '0')}${((fyYear + 1) % 100).toString().padLeft(2, '0')}';
}

DateTime fyStart(String fyKey) {
  // "FY2526" → starts Apr 1, 2025
  final startYr = 2000 + int.parse(fyKey.substring(2, 4));
  return DateTime(startYr, 4, 1);
}

DateTime fyEnd(String fyKey) {
  final endYr = 2000 + int.parse(fyKey.substring(4, 6));
  return DateTime(endYr, 3, 31);
}

// ─── High-level tax result ──────────────────────────────────────────────────
class FifoTaxResult {
  const FifoTaxResult({
    required this.memberSummaries,
    required this.financialYear,
  });

  final List<MemberTaxSummary> memberSummaries;
  final String financialYear;

  double get totalEquityLtcg =>
      memberSummaries.fold(0, (s, m) => s + m.equityLtcgGain);
  double get totalEquityStcg =>
      memberSummaries.fold(0, (s, m) => s + m.equityStcgGain);
  double get totalGoldLtcg =>
      memberSummaries.fold(0, (s, m) => s + m.goldLtcgGain);
  double get totalGoldStcg =>
      memberSummaries.fold(0, (s, m) => s + m.goldStcgGain);
  double get totalDebtGain =>
      memberSummaries.fold(0, (s, m) => s + m.debtSlabGain);
  double get totalTaxLiability =>
      memberSummaries.fold(0, (s, m) => s + m.totalTax);
  double get totalGrandfatheringBenefit =>
      memberSummaries.fold(0, (s, m) => s + m.grandfatheringBenefit);
}

// ─── Realized Gains (FIFO Tax Calculation) ──────────────────────────────────
@riverpod
Future<FifoTaxResult> taxCalculation(TaxCalculationRef ref) async {
  final allTxs = await ref.watch(allTransactionsProvider.future);
  final members = await ref.watch(familyMembersProvider.future);

  // Build member lookup for names and slab rates
  final memberNames = <String, String>{
    for (final m in members) m.id: m.displayName,
  };
  final memberSlabs = <String, double>{
    for (final m in members) m.id: m.taxSlabPct / 100.0, // stored as 30.0 → 0.30
  };

  final fyKey = currentFyKey();
  final start = fyStart(fyKey);
  final end = fyEnd(fyKey);

  // ── Auto-detect ISIN migrations (fund mergers/restructuring) ──────────
  // When the same folio+member has transactions under different amfi_codes
  // with sequential (non-overlapping) date ranges AND the same tax category,
  // it's the same fund that changed ISINs. Map old amfi_code → newest amfi_code
  // so FIFO can match.
  //
  // IMPORTANT: Multiple DIFFERENT funds under the same AMC can share a folio
  // number (e.g., Nippon Multi Cap & Nippon Money Market). These must NOT be
  // merged. We guard against this by requiring:
  //   1. Non-overlapping date ranges (true migration = old stops, new starts)
  //   2. Same tax category (equity→equity OK, equity→liquid = different fund)
  final amfiMigrationMap = <int, int>{}; // old_amfi → canonical_amfi
  {
    // Build amfi → taxCategory lookup from fund_master joins
    final amfiTaxCat = <int, String>{};
    for (final tx in allTxs) {
      if (tx.amfiCode != null && tx.fundMaster?.taxCategory != null) {
        amfiTaxCat.putIfAbsent(tx.amfiCode!, () => tx.fundMaster!.taxCategory!);
      }
    }

    // Collect (member, folio) → list of (amfi_code, first_date, last_date)
    final folioGroups = <String, List<({int amfi, DateTime first, DateTime last})>>{};
    for (final tx in allTxs) {
      if (tx.amfiCode == null || tx.folioNumber == null) continue;
      final key = '${tx.memberId ?? '_'}|${tx.folioNumber}';
      final group = folioGroups.putIfAbsent(key, () => []);
      final existing = group.where((g) => g.amfi == tx.amfiCode).firstOrNull;
      final date = tx.parsedDate;
      if (existing != null) {
        final idx = group.indexOf(existing);
        group[idx] = (
          amfi: existing.amfi,
          first: date.isBefore(existing.first) ? date : existing.first,
          last: date.isAfter(existing.last) ? date : existing.last,
        );
      } else {
        group.add((amfi: tx.amfiCode!, first: date, last: date));
      }
    }

    // For each folio group with multiple amfi_codes, only merge if:
    //   a) Date ranges are sequential (non-overlapping) — true fund migration
    //   b) Same tax category — rules out unrelated funds sharing a folio
    for (final entry in folioGroups.entries) {
      final codes = entry.value;
      if (codes.length < 2) continue;
      // Sort by first transaction date
      codes.sort((a, b) => a.first.compareTo(b.first));

      // Try to find genuine migration pairs (old fund stops, new fund starts)
      for (int i = 0; i < codes.length - 1; i++) {
        for (int j = i + 1; j < codes.length; j++) {
          final older = codes[i];
          final newer = codes[j];

          // Check 1: non-overlapping date ranges (old ends before new starts)
          // Allow 30-day overlap tolerance for transition processing delays
          final overlap = older.last.difference(newer.first).inDays;
          if (overlap > 30) continue; // overlapping = separate funds

          // Check 2: same tax category
          final catA = amfiTaxCat[older.amfi];
          final catB = amfiTaxCat[newer.amfi];
          if (catA != null && catB != null && catA != catB) continue;

          // This is a genuine migration: map old → new
          amfiMigrationMap[older.amfi] = newer.amfi;
        }
      }
    }
  }

  // Group transactions by (memberId, canonicalAmfiCode)
  final groups = <String, List<TransactionModel>>{};
  for (final tx in allTxs) {
    if (tx.amfiCode == null) continue;
    // Resolve through migration chain
    int canonical = tx.amfiCode!;
    int safety = 0;
    while (amfiMigrationMap.containsKey(canonical) && safety < 10) {
      canonical = amfiMigrationMap[canonical]!;
      safety++;
    }
    final key = '${tx.memberId ?? '_'}|$canonical';
    (groups[key] ??= []).add(tx);
  }

  // Accumulate per-member summaries
  final memberSummaries = <String, MemberTaxSummary>{};

  for (final entry in groups.entries) {
    final txs = entry.value..sort((a, b) => a.parsedDate.compareTo(b.parsedDate));
    final memberId = txs.first.memberId ?? 'Unknown';
    // Use latest transaction's fund metadata (handles merged funds correctly)
    final latestWithMaster = txs.lastWhere(
      (t) => t.fundMaster != null,
      orElse: () => txs.last,
    );
    final amfiCode = latestWithMaster.amfiCode ?? txs.first.amfiCode!;
    final taxCategory = _parseTaxCategory(latestWithMaster.fundMaster?.taxCategory);
    final taxSlabPct = memberSlabs[memberId] ?? 0.30;
    final jan31Nav = latestWithMaster.fundMaster?.jan31Nav;
    final fundName = latestWithMaster.fundMaster?.fundName ?? latestWithMaster.assetName ?? 'Fund $amfiCode';

    // Build open lots (buy transactions)
    // Use navAtTx as costPerUnit when available — this matches CAMS cost
    // basis (purchase NAV * units) and excludes stamp duty from cost.
    // Fall back to tx.amount / units if NAV not recorded.
    final openLots = <TaxLot>[];
    for (final tx in txs.where((t) => t.isPurchase)) {
      final units = tx.units ??
          (tx.navAtTx != null && tx.navAtTx! > 0
              ? tx.amount / tx.navAtTx!
              : 0.0);
      if (units <= 0) continue;
      final costPerUnit = tx.navAtTx != null && tx.navAtTx! > 0
          ? tx.navAtTx!
          : (units > 0 ? tx.amount / units : 0.0);
      openLots.add(TaxLot(
        txId: tx.id,
        date: tx.parsedDate,
        units: units,
        costPerUnit: costPerUnit,
        totalCost: costPerUnit * units,
      ));
    }

    // Build sell records — only sells within current FY
    // Use tx.amount / units as effective sell NAV — this captures exit load
    // deduction and matches CAMS's actual redemption proceeds.
    final sells = txs
        .where((t) => t.isRedemption)
        .where((t) =>
            !t.parsedDate.isBefore(start) &&
            !t.parsedDate.isAfter(end))
        .map((t) {
      final units = t.units ??
          (t.navAtTx != null && t.navAtTx! > 0
              ? t.amount / t.navAtTx!
              : 0.0);
      // Prefer actual amount/units (captures exit load, STT deductions)
      final nav = units > 0 ? t.amount / units : (t.navAtTx ?? 0.0);
      return (date: t.parsedDate, units: units, navAtSell: nav);
    }).toList();

    if (sells.isEmpty) continue;

    // Get existing LTCG gain for this member in this FY (from prior funds)
    final existing = memberSummaries[memberId];
    final existingLtcg = existing?.equityLtcgGain ?? 0.0;

    final result = FifoTaxCalculator.compute(
      openLots: openLots,
      sells: sells,
      taxCategory: taxCategory,
      taxSlabPct: taxSlabPct,
      existingLtcgGainInFy: existingLtcg,
      jan31Nav: jan31Nav,
    );

    // Accumulate into member summary
    final summary = memberSummaries.putIfAbsent(
      memberId,
      () => MemberTaxSummary(
        memberId: memberId,
        memberName: memberNames[memberId] ?? memberId,
        fy: fyKey,
        taxSlabPct: taxSlabPct,
      ),
    );

    // Create per-fund breakdown
    final fundBreakdown = FundTaxBreakdown(
      fundName: fundName,
      amfiCode: amfiCode,
      taxCategory: taxCategory,
      memberId: memberId,
    );
    fundBreakdown.equityLtcgGain = result.totalLtcgGain;
    fundBreakdown.equityStcgGain = result.totalStcgGain;
    fundBreakdown.goldLtcgGain = result.goldLtcgGain;
    fundBreakdown.goldStcgGain = result.goldStcgGain;
    fundBreakdown.debtGain = result.debtGain;
    fundBreakdown.totalGain = result.totalLtcgGain + result.totalStcgGain +
        result.goldLtcgGain + result.goldStcgGain + result.debtGain;
    fundBreakdown.equityLtcgLoss = result.totalLtcgLoss;
    fundBreakdown.equityStcgLoss = result.totalStcgLoss;
    fundBreakdown.goldLtcgLoss = result.goldLtcgLoss;
    fundBreakdown.goldStcgLoss = result.goldStcgLoss;
    fundBreakdown.debtLoss = result.debtLoss;
    fundBreakdown.totalLoss = result.totalLtcgLoss + result.totalStcgLoss +
        result.goldLtcgLoss + result.goldStcgLoss + result.debtLoss;
    fundBreakdown.grandfatheringBenefit = result.grandfatheringBenefit;
    fundBreakdown.sellCount = sells.length;
    fundBreakdown.buyLotCount = openLots.length;
    fundBreakdown.totalBuyUnits = openLots.fold(0.0, (s, l) => s + l.units);
    fundBreakdown.unmatchedSellUnits = result.unmatchedSellUnits;
    fundBreakdown.lotMatches = result.lotMatches;
    summary.fundBreakdowns.add(fundBreakdown);

    // Accumulate gains into member totals
    summary.equityLtcgGain += result.totalLtcgGain;
    summary.equityStcgGain += result.totalStcgGain;
    summary.goldLtcgGain += result.goldLtcgGain;
    summary.goldStcgGain += result.goldStcgGain;
    summary.debtSlabGain += result.debtGain;
    summary.equityLtcgExemptionUsed += result.ltcgExemptionUsed;
    summary.equityLtcgTax += result.ltcgTax;
    summary.equityStcgTax += result.stcgTax;
    summary.goldLtcgTax += result.goldLtcgTax;
    summary.goldStcgTax += result.goldStcgTax;
    summary.debtSlabTax += result.debtTax;
    summary.grandfatheringBenefit += result.grandfatheringBenefit;

    // Accumulate losses into member totals
    summary.equityLtcgLoss += result.totalLtcgLoss;
    summary.equityStcgLoss += result.totalStcgLoss;
    summary.goldLtcgLoss += result.goldLtcgLoss;
    summary.goldStcgLoss += result.goldStcgLoss;
    summary.debtSlabLoss += result.debtLoss;

    // Recompute totals
    summary.totalTaxBeforeCess = summary.equityLtcgTax +
        summary.equityStcgTax +
        summary.goldLtcgTax +
        summary.goldStcgTax +
        summary.debtSlabTax;
    summary.cess = summary.totalTaxBeforeCess * AppConstants.healthEducationCess;
    summary.totalTax = summary.totalTaxBeforeCess + summary.cess;
    summary.netGain = summary.equityLtcgGain +
        summary.equityStcgGain +
        summary.goldLtcgGain +
        summary.goldStcgGain +
        summary.debtSlabGain -
        summary.totalTax;
    summary.equityLtcgTaxableGain = (summary.equityLtcgGain -
            summary.equityLtcgExemptionUsed)
        .clamp(0.0, double.infinity);
    summary.unusedLtcgExemption =
        (AppConstants.ltcgExemptionPerPersonPerFy - summary.equityLtcgGain)
            .clamp(0.0, double.infinity);
  }

  // ── Apply capital loss offset rules (IT Act Sections 70-71) ──────────
  // Then RECOMPUTE tax on net gains (per-fund taxes don't cross-offset losses).
  for (final summary in memberSummaries.values) {
    // Total short-term losses (can offset both STCG and LTCG)
    final totalStLoss = summary.equityStcgLoss + summary.goldStcgLoss +
        summary.debtSlabLoss;
    // Total long-term losses (can only offset LTCG)
    final totalLtLoss = summary.equityLtcgLoss + summary.goldLtcgLoss;

    if (totalStLoss > 0 || totalLtLoss > 0) {
      // ST loss → offset STCG first, then LTCG
      final totalStcg = summary.equityStcgGain + summary.goldStcgGain +
          summary.debtSlabGain;
      summary.stLossOffsetVsStcg = totalStLoss.clamp(0.0, totalStcg);
      final remainingStLoss = totalStLoss - summary.stLossOffsetVsStcg;

      final totalLtcg = summary.equityLtcgTaxableGain + summary.goldLtcgGain;
      summary.stLossOffsetVsLtcg = remainingStLoss.clamp(0.0, totalLtcg);

      // LT loss → offset LTCG only
      final ltcgAfterStOffset = (totalLtcg - summary.stLossOffsetVsLtcg)
          .clamp(0.0, double.infinity);
      summary.ltLossOffsetVsLtcg = totalLtLoss.clamp(0.0, ltcgAfterStOffset);

      // Remaining loss → carry forward up to 8 assessment years
      summary.lossCarryForward = (totalStLoss + totalLtLoss) -
          summary.stLossOffsetVsStcg -
          summary.stLossOffsetVsLtcg -
          summary.ltLossOffsetVsLtcg;
    }

    // ── Recompute tax on NET gains after loss offset ──
    // Per-fund taxes don't cross-offset losses across funds (e.g. MO Flexi Cap
    // loss should reduce Kotak Multicap gain). Recompute at member level.
    // Net gains per category (gains - losses within same category)
    final netEqStcg = (summary.equityStcgGain - summary.equityStcgLoss)
        .clamp(0.0, double.infinity);
    final netGoldStcg = (summary.goldStcgGain - summary.goldStcgLoss)
        .clamp(0.0, double.infinity);
    final netDebt = (summary.debtSlabGain - summary.debtSlabLoss)
        .clamp(0.0, double.infinity);
    final netEqLtcg = (summary.equityLtcgGain - summary.equityLtcgLoss)
        .clamp(0.0, double.infinity);
    final netGoldLtcg = (summary.goldLtcgGain - summary.goldLtcgLoss)
        .clamp(0.0, double.infinity);

    // Apply LTCG exemption on net equity LTCG
    final exemption = AppConstants.ltcgExemptionPerPersonPerFy;
    final ltcgExemptUsed = netEqLtcg.clamp(0.0, exemption);
    final taxableEqLtcg = (netEqLtcg - ltcgExemptUsed)
        .clamp(0.0, double.infinity);

    // Recompute tax
    summary.equityLtcgExemptionUsed = ltcgExemptUsed;
    summary.equityLtcgTaxableGain = taxableEqLtcg;
    summary.equityLtcgTax = taxableEqLtcg * AppConstants.equityLtcgRate;
    summary.equityStcgTax = netEqStcg * AppConstants.equityStcgRate;
    summary.goldLtcgTax = netGoldLtcg * AppConstants.goldFofLtcgRate;
    summary.goldStcgTax = netGoldStcg * summary.taxSlabPct;
    summary.debtSlabTax = netDebt * summary.taxSlabPct;
    summary.totalTaxBeforeCess = summary.equityLtcgTax +
        summary.equityStcgTax +
        summary.goldLtcgTax +
        summary.goldStcgTax +
        summary.debtSlabTax;
    summary.cess =
        summary.totalTaxBeforeCess * AppConstants.healthEducationCess;
    summary.totalTax = summary.totalTaxBeforeCess + summary.cess;
    summary.unusedLtcgExemption =
        (exemption - netEqLtcg).clamp(0.0, exemption);
    summary.netGain = summary.equityLtcgGain +
        summary.equityStcgGain +
        summary.goldLtcgGain +
        summary.goldStcgGain +
        summary.debtSlabGain -
        summary.totalTax;
  }

  return FifoTaxResult(
    memberSummaries: memberSummaries.values.toList(),
    financialYear: fyKey,
  );
}

TaxCategory _parseTaxCategory(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'equity':
      return TaxCategory.equity;
    case 'hybrid-e':
      return TaxCategory.hybridE;
    case 'hybrid-d':
      return TaxCategory.hybridD;
    case 'gold':
    case 'gold etf':
      return TaxCategory.goldEtf;
    default:
      return TaxCategory.debt;
  }
}

// ─── Unrealized Tax Exposure ────────────────────────────────────────────────
class UnrealizedExposure {
  const UnrealizedExposure({
    required this.fundName,
    required this.memberId,
    required this.memberName,
    required this.amfiCode,
    required this.taxCategory,
    required this.holdingDays,
    required this.totalUnits,
    required this.costBasis,
    required this.currentValue,
    required this.unrealisedGain,
    required this.gainType,
    required this.estimatedTax,
    required this.ltcgDaysRemaining,
    // ── Investor details ──
    this.investedSince,
    this.planType,
    this.expenseRatio,
    this.return1y,
    // ── "What if I Redeemed Today?" fields ──
    this.stcgGain = 0,
    this.ltcgGain = 0,
    this.stcgTax = 0,
    this.ltcgTax = 0,
    this.stcgTaxRate = 0,
    this.ltcgTaxRate = 0,
    this.postTaxGain = 0,
    this.exitLoadText,
    this.exitLoadAmount = 0,
  });

  final String fundName;
  final String memberId;
  final String memberName;
  final int amfiCode;
  final TaxCategory taxCategory;
  final int holdingDays;
  final double totalUnits;
  final double costBasis;
  final double currentValue;
  final double unrealisedGain;
  final String gainType; // 'LTCG', 'STCG', 'Slab Rate'
  final double estimatedTax;
  final int ltcgDaysRemaining; // 0 if already LTCG, else days until LTCG

  // ── Investor details ──
  final DateTime? investedSince;  // earliest buy date
  final String? planType;         // 'Direct' or 'Regular'
  final double? expenseRatio;
  final double? return1y;

  // ── "What if I Redeemed Today?" ──
  final double stcgGain;       // short-term capital gain portion
  final double ltcgGain;       // long-term capital gain portion
  final double stcgTax;        // tax on STCG
  final double ltcgTax;        // tax on LTCG
  final double stcgTaxRate;    // e.g. 0.20 for equity
  final double ltcgTaxRate;    // e.g. 0.125 for equity
  final double postTaxGain;    // unrealisedGain - estimatedTax
  final String? exitLoadText;  // raw exit load clause from fund_master
  final double exitLoadAmount; // estimated exit load if redeemed today

  /// Formatted holding period like "2y 3m" or "45d"
  String get holdingPeriodFormatted {
    if (holdingDays >= 365) {
      final years = holdingDays ~/ 365;
      final months = (holdingDays % 365) ~/ 30;
      return months > 0 ? '${years}y ${months}m' : '${years}y';
    } else if (holdingDays >= 30) {
      return '${holdingDays ~/ 30}m ${holdingDays % 30}d';
    }
    return '${holdingDays}d';
  }

  /// Tax category display label
  String get taxCategoryLabel => taxCategory.displayName;
}

class UnrealizedExposureResult {
  const UnrealizedExposureResult({
    required this.exposures,
    required this.totalUnrealisedGain,
    required this.totalEstimatedTax,
    required this.stcgToLtcgSoonCount,
  });

  final List<UnrealizedExposure> exposures;
  final double totalUnrealisedGain;
  final double totalEstimatedTax;
  final int stcgToLtcgSoonCount; // holdings transitioning to LTCG within 90 days
}

@riverpod
Future<UnrealizedExposureResult> unrealizedExposure(
    UnrealizedExposureRef ref) async {
  final allTxs = await ref.watch(allTransactionsProvider.future);
  final navMap = await ref.watch(latestNavMapProvider.future);
  final members = await ref.watch(familyMembersProvider.future);
  final camsData = await ref.watch(camsTaxStatementProvider.future);

  final memberNames = <String, String>{
    for (final m in members) m.id: m.displayName,
  };
  final memberSlabs = <String, double>{
    for (final m in members) m.id: m.taxSlabPct / 100.0,
  };

  // ── Resolve CAMS-verified redemptions → amfi_code ──
  final client = ref.read(supabaseClientProvider);
  final camsRedeemedByAmfi =
      await _buildCamsRedeemedByAmfi(camsData, client, allTxs);

  // ── Registrar truth: aggregate folio_details by ISIN ──
  final folios = await ref.watch(folioDetailsProvider.future);
  final folioClosingByIsin = <String, double>{};
  final exitLoadByIsin = <String, ({int days, double pct, double freePct})>{};
  for (final f in folios) {
    if (f.isin != null) {
      folioClosingByIsin[f.isin!] =
          (folioClosingByIsin[f.isin!] ?? 0) + (f.closingUnits ?? 0);
      // Use first folio's exit load for each ISIN (all folios for same scheme have same load)
      if (f.exitLoadDays != null && f.exitLoadPct != null && !exitLoadByIsin.containsKey(f.isin!)) {
        exitLoadByIsin[f.isin!] = (days: f.exitLoadDays!, pct: f.exitLoadPct!, freePct: f.exitLoadFreePct);
      }
    }
  }

  final groups = <String, List<TransactionModel>>{};
  for (final tx in allTxs) {
    if (tx.amfiCode == null) continue;
    final key = '${tx.memberId ?? ""}|${tx.amfiCode}';
    (groups[key] ??= []).add(tx);
  }

  final exposures = <UnrealizedExposure>[];

  for (final entry in groups.entries) {
    final txs = entry.value..sort((a, b) => a.parsedDate.compareTo(b.parsedDate));
    final amfiCode = txs.first.amfiCode!;
    final nav = navMap[amfiCode] ?? 0.0;
    if (nav <= 0) continue;

    final memberId = txs.first.memberId ?? '';
    final taxCategory = _parseTaxCategory(txs.first.fundMaster?.taxCategory);
    final taxSlabPct = memberSlabs[memberId] ?? 0.30;

    // ── Build FIFO lots for accurate STCG/LTCG split ──
    // Purchase lots track (date, remainingUnits, costPerUnit)
    final fifoLots = <({DateTime date, double remainingUnits, double costPerUnit})>[];
    double units = 0;
    double totalCost = 0;
    DateTime? oldestBuyDate;

    for (final tx in txs) {
      final txUnits = tx.units ??
          (tx.navAtTx != null && tx.navAtTx! > 0
              ? tx.amount / tx.navAtTx!
              : 0.0);
      if (txUnits <= 0) continue;

      if (tx.isPurchase) {
        units += txUnits;
        totalCost += tx.amount;
        fifoLots.add((
          date: tx.parsedDate,
          remainingUnits: txUnits,
          costPerUnit: tx.amount / txUnits,
        ));
        if (oldestBuyDate == null || tx.parsedDate.isBefore(oldestBuyDate)) {
          oldestBuyDate = tx.parsedDate;
        }
      } else {
        // FIFO sell: consume oldest lots first
        double toSell = txUnits;
        for (int li = 0; li < fifoLots.length && toSell > 0; li++) {
          final lot = fifoLots[li];
          if (lot.remainingUnits <= 0) continue;
          final consumed = toSell.clamp(0.0, lot.remainingUnits);
          fifoLots[li] = (
            date: lot.date,
            remainingUnits: lot.remainingUnits - consumed,
            costPerUnit: lot.costPerUnit,
          );
          toSell -= consumed;
        }
        // Reduce cost proportionally
        if (units > 0 && txUnits > 0) {
          final sellRatio = (txUnits / units).clamp(0.0, 1.0);
          totalCost -= totalCost * sellRatio;
        }
        units -= txUnits;
      }
    }

    // ── Deduct CAMS-verified redemptions not in eVesh txn data ──
    if (camsRedeemedByAmfi.containsKey(amfiCode) && units > 0) {
      final redeemed = camsRedeemedByAmfi[amfiCode]!;
      final currentValue = units * nav;
      final costRatio =
          totalCost > 0 ? (redeemed.cost / totalCost) : 0.0;
      final amountRatio =
          currentValue > 0 ? (redeemed.amount / currentValue) : 0.0;
      final ratio =
          (costRatio > amountRatio ? costRatio : amountRatio).clamp(0.0, 1.0);
      if (ratio > 0.80) {
        units = 0;
        totalCost = 0;
        fifoLots.clear();
      } else {
        units *= (1 - ratio);
        totalCost *= (1 - ratio);
        // Scale down FIFO lots proportionally
        for (int li = 0; li < fifoLots.length; li++) {
          final lot = fifoLots[li];
          fifoLots[li] = (
            date: lot.date,
            remainingUnits: lot.remainingUnits * (1 - ratio),
            costPerUnit: lot.costPerUnit,
          );
        }
      }
    }

    if (units.abs() < 0.01 || oldestBuyDate == null) continue;

    // Registrar truth: if folio_details says closing_units ≈ 0, skip
    final groupIsin = txs.firstWhere(
      (t) => t.isin != null,
      orElse: () => txs.first,
    ).isin;
    if (groupIsin != null && folioClosingByIsin.containsKey(groupIsin)) {
      final registrarUnits = folioClosingByIsin[groupIsin]!;
      if (registrarUnits.abs() < 0.01) continue;
    }

    final positionValue = units * nav;
    final unrealisedGain = positionValue - totalCost;
    final holdingDays = DateTime.now().difference(oldestBuyDate).inDays;

    // ── FIFO-based STCG/LTCG split ("What if I Redeemed Today?") ──
    final int ltcgThresholdDays;
    final double stcgRate;
    final double ltcgRate;
    if (taxCategory.isEquityType) {
      ltcgThresholdDays = AppConstants.equityLtcgHoldingDays;
      stcgRate = AppConstants.equityStcgRate;
      ltcgRate = AppConstants.equityLtcgRate;
    } else if (taxCategory.isGoldFofType) {
      ltcgThresholdDays = AppConstants.goldFofLtcgHoldingDays;
      stcgRate = taxSlabPct;
      ltcgRate = AppConstants.goldFofLtcgRate;
    } else {
      ltcgThresholdDays = 0;
      stcgRate = taxSlabPct;
      ltcgRate = taxSlabPct;
    }

    // Resolve exit load from CAMS folio_details (per-ISIN)
    final fundIsin = txs.firstWhere(
      (t) => t.isin != null,
      orElse: () => txs.first,
    ).isin;
    final exitLoad = fundIsin != null ? exitLoadByIsin[fundIsin] : null;
    final exitLoadDays = exitLoad?.days ?? 365; // fallback: 1 year
    final exitLoadPctValue = exitLoad?.pct ?? 1.0; // fallback: 1%
    final exitLoadFreePct = exitLoad?.freePct ?? 0.0; // % of units free from exit load

    // Simulate selling all remaining lots at current NAV
    final now = DateTime.now();
    double stcgGain = 0, ltcgGain = 0;
    double exitLoadUnits = 0; // units still within exit load period
    double totalRemainingUnits = 0;
    for (final lot in fifoLots) {
      if (lot.remainingUnits <= 0.001) continue;
      totalRemainingUnits += lot.remainingUnits;
      final lotHoldingDays = now.difference(lot.date).inDays;
      final lotProceeds = lot.remainingUnits * nav;
      final lotCost = lot.remainingUnits * lot.costPerUnit;
      final lotGain = lotProceeds - lotCost;
      final isLtcg = taxCategory.isEquityType
          ? lotHoldingDays >= ltcgThresholdDays
          : taxCategory.isGoldFofType
              ? lotHoldingDays >= ltcgThresholdDays
              : false; // debt = always slab
      if (isLtcg) {
        ltcgGain += lotGain;
      } else {
        stcgGain += lotGain;
      }
      // Exit load: use CAMS-parsed days/pct from folio_details
      if (lotHoldingDays < exitLoadDays) {
        exitLoadUnits += lot.remainingUnits;
      }
    }

    // Tax calculation
    final stcgTax = stcgGain > 0 ? stcgGain * stcgRate : 0.0;
    final ltcgTax = ltcgGain > 0 ? ltcgGain * ltcgRate : 0.0;
    final estimatedTax = stcgTax + ltcgTax;
    final postTaxGain = unrealisedGain - estimatedTax;

    // Exit load: X% of units are free, remaining at Y% charge
    // e.g., 30% free means only 70% of exit-load-eligible units are charged
    final freeUnits = totalRemainingUnits * (exitLoadFreePct / 100);
    final chargeableUnits = (exitLoadUnits - freeUnits).clamp(0.0, exitLoadUnits);
    final exitLoadAmount = chargeableUnits * nav * (exitLoadPctValue / 100);

    // Exit load text: prefer CAMS folio_details (per-scheme) over fund_master
    final folioExitText = fundIsin != null
        ? folios.where((f) => f.isin == fundIsin).firstOrNull?.exitLoadText
        : null;
    final exitLoadText = folioExitText ?? txs.first.fundMaster?.exitLoad;

    // Dominant gain type for badge display
    final String gainType;
    if (taxCategory == TaxCategory.debt) {
      gainType = 'Slab Rate';
    } else if (ltcgGain.abs() >= stcgGain.abs()) {
      gainType = 'LTCG';
    } else {
      gainType = 'STCG';
    }

    final ltcgDaysRemaining = holdingDays >= ltcgThresholdDays
        ? 0
        : ltcgThresholdDays - holdingDays;

    exposures.add(UnrealizedExposure(
      fundName: txs.first.fundMaster?.fundName ?? txs.first.assetName ?? 'Fund',
      memberId: memberId,
      memberName: memberNames[memberId] ?? memberId,
      amfiCode: amfiCode,
      taxCategory: taxCategory,
      holdingDays: holdingDays,
      totalUnits: units,
      costBasis: totalCost,
      currentValue: positionValue,
      unrealisedGain: unrealisedGain,
      gainType: gainType,
      estimatedTax: estimatedTax,
      ltcgDaysRemaining: ltcgDaysRemaining,
      investedSince: oldestBuyDate,
      planType: txs.first.fundMaster?.planType,
      expenseRatio: txs.first.fundMaster?.expenseRatio,
      return1y: txs.first.fundMaster?.return1y,
      stcgGain: stcgGain,
      ltcgGain: ltcgGain,
      stcgTax: stcgTax,
      ltcgTax: ltcgTax,
      stcgTaxRate: stcgRate,
      ltcgTaxRate: ltcgRate,
      postTaxGain: postTaxGain,
      exitLoadText: exitLoadText,
      exitLoadAmount: exitLoadAmount,
    ));
  }

  exposures.sort((a, b) => b.unrealisedGain.compareTo(a.unrealisedGain));

  final totalGain = exposures.fold(0.0, (s, e) => s + e.unrealisedGain);
  final totalTax = exposures.fold(0.0, (s, e) => s + e.estimatedTax);
  final soonCount = exposures
      .where((e) => e.ltcgDaysRemaining > 0 && e.ltcgDaysRemaining <= 90)
      .length;

  return UnrealizedExposureResult(
    exposures: exposures,
    totalUnrealisedGain: totalGain,
    totalEstimatedTax: totalTax,
    stcgToLtcgSoonCount: soonCount,
  );
}

// ─── Tax Harvest Opportunities ──────────────────────────────────────────────
class HarvestOpportunity {
  const HarvestOpportunity({
    required this.fundName,
    required this.memberId,
    required this.memberName,
    required this.amfiCode,
    required this.unrealisedGain,
    required this.holdingDays,
    required this.units,
    required this.currentNav,
    required this.potentialTaxSaving,
    required this.taxCategory,
    required this.investedAmount,
    required this.currentValue,
    required this.gainPct,
    required this.costPerUnit,
    required this.unitsToRedeem,
    required this.amountToRedeem,
    required this.ltcgGainToBook,
    this.exitLoadDays,
    this.exitLoadPct,
    this.exitLoadAmount = 0,
  });

  final String fundName;
  final String memberId;
  final String memberName;
  final int amfiCode;
  final double unrealisedGain;
  final int holdingDays;
  final double units;
  final double currentNav;
  final double potentialTaxSaving;
  final TaxCategory taxCategory;
  final double investedAmount;
  final double currentValue;
  final double gainPct;
  final double costPerUnit;
  final double unitsToRedeem;     // units to redeem to stay within exemption
  final double amountToRedeem;    // rupee value of those units
  final double ltcgGainToBook;    // gain amount from those units
  final int? exitLoadDays;        // CAMS: holding period before exit load applies
  final double? exitLoadPct;      // CAMS: exit load percentage
  final double exitLoadAmount;    // estimated exit load on amountToRedeem
}

/// Fund at a loss — can be booked to offset realized gains
class LossHarvestOpportunity {
  const LossHarvestOpportunity({
    required this.fundName,
    required this.memberId,
    required this.memberName,
    required this.amfiCode,
    required this.investedAmount,
    required this.currentValue,
    required this.unrealisedLoss,
    required this.lossPct,
    required this.holdingDays,
    required this.units,
    required this.currentNav,
    required this.isLongTerm,
    required this.taxCategory,
  });

  final String fundName;
  final String memberId;
  final String memberName;
  final int amfiCode;
  final double investedAmount;
  final double currentValue;
  final double unrealisedLoss; // positive number (absolute loss)
  final double lossPct;
  final int holdingDays;
  final double units;
  final double currentNav;
  final bool isLongTerm;
  final TaxCategory taxCategory;

  String get offsetAbility => isLongTerm
      ? 'Can offset LTCG only'
      : 'Can offset both STCG & LTCG';
}

class HarvestResult {
  const HarvestResult({
    required this.opportunities,
    this.totalPotentialSaving = 0,
    this.lossOpportunities = const [],
    this.totalOffsettableLoss = 0,
    this.unusedExemptionPerMember = const {},
  });
  final List<HarvestOpportunity> opportunities;
  final double totalPotentialSaving;
  final List<LossHarvestOpportunity> lossOpportunities;
  final double totalOffsettableLoss;
  final Map<String, double> unusedExemptionPerMember;
}

@riverpod
Future<HarvestResult> taxHarvestOpportunities(
    TaxHarvestOpportunitiesRef ref) async {
  final allTxs = await ref.watch(allTransactionsProvider.future);
  final navMap = await ref.watch(latestNavMapProvider.future);
  final members = await ref.watch(familyMembersProvider.future);
  final taxResult = await ref.watch(taxCalculationProvider.future);

  final memberNames = <String, String>{
    for (final m in members) m.id: m.displayName,
  };

  // Get unused LTCG exemption per member from realized gains calculation
  final unusedExemption = <String, double>{
    for (final m in taxResult.memberSummaries)
      m.memberId: m.unusedLtcgExemption,
  };
  // Members with no realized gains get full exemption
  for (final m in members) {
    unusedExemption.putIfAbsent(m.id, () => AppConstants.ltcgExemptionPerPersonPerFy);
  }

  // ── Override with CAMS/MFC verified booked LTCG if available ──
  // The registrar statement is the source of truth for already-booked gains.
  final camsData = await ref.watch(camsTaxStatementProvider.future);
  if (camsData != null && camsData.hasData && camsData.equityLtcg > 0) {
    // Match CAMS PAN → family member to apply to correct person
    String? matchedId;
    if (camsData.pan != null) {
      for (final m in members) {
        if (m.pan != null && m.pan == camsData.pan) {
          matchedId = m.id;
          break;
        }
      }
    }
    // If PAN match found, override that member; otherwise apply to first member
    matchedId ??= members.isNotEmpty ? members.first.id : null;
    if (matchedId != null) {
      final remaining = (AppConstants.ltcgExemptionPerPersonPerFy -
              camsData.equityLtcg)
          .clamp(0.0, AppConstants.ltcgExemptionPerPersonPerFy);
      unusedExemption[matchedId] = remaining;
    }
  }

  final opportunities = <HarvestOpportunity>[];
  final lossOpportunities = <LossHarvestOpportunity>[];

  // ── Resolve CAMS-verified redemptions → amfi_code ──
  final client = ref.read(supabaseClientProvider);
  final camsRedeemedByAmfi =
      await _buildCamsRedeemedByAmfi(camsData, client, allTxs);

  // ── Registrar truth: aggregate folio_details by ISIN ──
  final folios = await ref.watch(folioDetailsProvider.future);
  final folioClosingByIsin = <String, double>{};
  final exitLoadByIsin = <String, ({int days, double pct, double freePct})>{};
  for (final f in folios) {
    if (f.isin != null) {
      folioClosingByIsin[f.isin!] =
          (folioClosingByIsin[f.isin!] ?? 0) + (f.closingUnits ?? 0);
      if (f.exitLoadDays != null && f.exitLoadPct != null && !exitLoadByIsin.containsKey(f.isin!)) {
        exitLoadByIsin[f.isin!] = (days: f.exitLoadDays!, pct: f.exitLoadPct!, freePct: f.exitLoadFreePct);
      }
    }
  }

  final groups = <String, List<TransactionModel>>{};
  for (final tx in allTxs) {
    if (tx.amfiCode == null) continue;
    final key = '${tx.memberId ?? ""}|${tx.amfiCode}';
    (groups[key] ??= []).add(tx);
  }

  for (final entry in groups.entries) {
    final txs = entry.value;
    final amfiCode = txs.first.amfiCode!;
    final nav = navMap[amfiCode] ?? 0.0;
    if (nav <= 0) continue;

    final memberId = txs.first.memberId ?? '';
    final taxCategory = _parseTaxCategory(txs.first.fundMaster?.taxCategory);
    final fundName = txs.first.fundMaster?.fundName ?? txs.first.assetName ?? 'Fund';

    double units = 0;
    double totalCost = 0;
    DateTime? oldestDate;

    for (final tx in txs) {
      final txUnits = tx.units ??
          (tx.navAtTx != null && tx.navAtTx! > 0
              ? tx.amount / tx.navAtTx!
              : 0.0);
      if (tx.isPurchase) {
        units += txUnits;
        totalCost += tx.amount;
        if (oldestDate == null || tx.parsedDate.isBefore(oldestDate)) {
          oldestDate = tx.parsedDate;
        }
      } else {
        if (units > 0 && txUnits > 0) {
          final sellRatio = (txUnits / units).clamp(0.0, 1.0);
          totalCost -= totalCost * sellRatio;
        }
        units -= txUnits;
      }
    }

    // ── Deduct CAMS-verified redemptions not captured in eVesh txns ──
    // Uses max of cost-ratio and outflow-ratio to handle cases where
    // eVesh has historical buys from prior FYs that were already redeemed.
    if (camsRedeemedByAmfi.containsKey(amfiCode) && units > 0) {
      final redeemed = camsRedeemedByAmfi[amfiCode]!;
      final currentValue = units * nav;
      final costRatio =
          totalCost > 0 ? (redeemed.cost / totalCost) : 0.0;
      final amountRatio =
          currentValue > 0 ? (redeemed.amount / currentValue) : 0.0;
      final ratio =
          (costRatio > amountRatio ? costRatio : amountRatio).clamp(0.0, 1.0);
      // If >80% was redeemed, treat as fully redeemed — the residual is
      // from prior-FY sell transactions missing in eVesh's data.
      if (ratio > 0.80) {
        units = 0;
        totalCost = 0;
      } else {
        units *= (1 - ratio);
        totalCost *= (1 - ratio);
      }
    }

    if (units.abs() < 0.01 || oldestDate == null) continue;

    // Registrar truth: if folio_details says closing_units ≈ 0, skip
    final groupIsin = txs.firstWhere(
      (t) => t.isin != null,
      orElse: () => txs.first,
    ).isin;
    if (groupIsin != null && folioClosingByIsin.containsKey(groupIsin)) {
      final registrarUnits = folioClosingByIsin[groupIsin]!;
      if (registrarUnits.abs() < 0.01) continue;
    }

    // Skip tiny residual positions (< ₹500)
    final positionValue = units * nav;
    if (positionValue < 500) continue;

    final currentValue = positionValue;
    final unrealisedGain = currentValue - totalCost;
    final holdingDays = DateTime.now().difference(oldestDate).inDays;
    final costPerUnit = units > 0 ? totalCost / units : 0.0;
    final gainPct = totalCost > 0 ? (unrealisedGain / totalCost) * 100 : 0.0;
    final isEquity = taxCategory.isEquityType;

    // Determine if LTCG based on category
    final int ltcgThreshold;
    if (taxCategory.isEquityType) {
      ltcgThreshold = AppConstants.equityLtcgHoldingDays;
    } else if (taxCategory.isGoldFofType) {
      ltcgThreshold = AppConstants.goldFofLtcgHoldingDays;
    } else {
      ltcgThreshold = 0; // debt = always slab rate
    }
    final isLtcg = ltcgThreshold > 0 && holdingDays >= ltcgThreshold;

    // ── Loss Harvest: fund at unrealized loss ──
    if (unrealisedGain < -100) {
      // Meaningful loss (> ₹100)
      lossOpportunities.add(LossHarvestOpportunity(
        fundName: fundName,
        memberId: memberId,
        memberName: memberNames[memberId] ?? memberId,
        amfiCode: amfiCode,
        investedAmount: totalCost,
        currentValue: currentValue,
        unrealisedLoss: unrealisedGain.abs(),
        lossPct: gainPct.abs(),
        holdingDays: holdingDays,
        units: units,
        currentNav: nav,
        isLongTerm: isLtcg,
        taxCategory: taxCategory,
      ));
      continue;
    }

    // ── Gain Harvest: equity LTCG with unrealised gains ──
    if (!isEquity || !isLtcg || unrealisedGain <= 0) continue;

    // Calculate how much to redeem to stay within exemption
    final memberExemption = unusedExemption[memberId] ??
        AppConstants.ltcgExemptionPerPersonPerFy;
    final gainPerUnit = nav - costPerUnit;

    double unitsToRedeem = 0;
    double amountToRedeem = 0;
    double ltcgGainToBook = 0;

    if (gainPerUnit > 0 && memberExemption > 0) {
      unitsToRedeem = (memberExemption / gainPerUnit).clamp(0.0, units);
      amountToRedeem = unitsToRedeem * nav;
      ltcgGainToBook = unitsToRedeem * gainPerUnit;
    } else {
      // Redeem all if no exemption tracking possible
      unitsToRedeem = units;
      amountToRedeem = currentValue;
      ltcgGainToBook = unrealisedGain;
    }

    final potentialSaving = ltcgGainToBook.clamp(0.0, memberExemption) *
        AppConstants.equityLtcgRate;

    // Exit load from CAMS folio_details for this fund
    final harvestIsin = txs.firstWhere(
      (t) => t.isin != null,
      orElse: () => txs.first,
    ).isin;
    final harvestExitLoad = harvestIsin != null ? exitLoadByIsin[harvestIsin] : null;
    final harvestExitDays = harvestExitLoad?.days;
    final harvestExitPct = harvestExitLoad?.pct;
    final harvestFreePct = harvestExitLoad?.freePct ?? 0.0;
    // Exit load: X% of units free, remaining at Y%
    double harvestExitAmount = 0.0;
    if (harvestExitDays != null && harvestExitPct != null && holdingDays < harvestExitDays) {
      final freeUnits = units * (harvestFreePct / 100);
      final chargeableRedeem = (unitsToRedeem - freeUnits).clamp(0.0, unitsToRedeem);
      harvestExitAmount = chargeableRedeem * nav * (harvestExitPct / 100);
    }

    opportunities.add(HarvestOpportunity(
      fundName: fundName,
      memberId: memberId,
      memberName: memberNames[memberId] ?? memberId,
      amfiCode: amfiCode,
      unrealisedGain: unrealisedGain,
      holdingDays: holdingDays,
      units: units,
      currentNav: nav,
      potentialTaxSaving: potentialSaving,
      taxCategory: taxCategory,
      investedAmount: totalCost,
      currentValue: currentValue,
      gainPct: gainPct,
      costPerUnit: costPerUnit,
      unitsToRedeem: unitsToRedeem,
      amountToRedeem: amountToRedeem,
      ltcgGainToBook: ltcgGainToBook,
      exitLoadDays: harvestExitDays,
      exitLoadPct: harvestExitPct,
      exitLoadAmount: harvestExitAmount,
    ));
  }

  opportunities.sort(
      (a, b) => b.potentialTaxSaving.compareTo(a.potentialTaxSaving));
  lossOpportunities.sort(
      (a, b) => b.unrealisedLoss.compareTo(a.unrealisedLoss));

  final totalSaving = opportunities.fold(0.0, (s, o) => s + o.potentialTaxSaving);
  final totalLoss = lossOpportunities.fold(0.0, (s, l) => s + l.unrealisedLoss);

  return HarvestResult(
    opportunities: opportunities,
    totalPotentialSaving: totalSaving,
    lossOpportunities: lossOpportunities,
    totalOffsettableLoss: totalLoss,
    unusedExemptionPerMember: unusedExemption,
  );
}

/// Tracks both cost basis and outflow (redemption proceeds) for a redeemed
/// fund from the CAMS/MFC capital gains statement.
class _RedemptionInfo {
  double cost = 0;    // Net Value (invested cost basis of redeemed units)
  double amount = 0;  // Outflow Amount (redemption proceeds received)
}

/// Build amfi_code → redemption info from CAMS/MFC verified scheme breakdowns.
/// Resolves ISINs via (1) transaction ISIN→amfi mapping first, then
/// (2) fund_master lookup as fallback.
Future<Map<int, _RedemptionInfo>> _buildCamsRedeemedByAmfi(
  CamsTaxStatement? camsData,
  SupabaseClient client,
  List<TransactionModel> allTxs,
) async {
  final result = <int, _RedemptionInfo>{};
  if (camsData == null || camsData.schemeBreakdowns.isEmpty) return result;

  // 1. Extract every ISIN + cost + amount from scheme names
  final isinToInfo = <String, _RedemptionInfo>{};
  for (final s in camsData.schemeBreakdowns) {
    final name = (s['scheme'] as String?) ?? '';
    final match = RegExp(r'[A-Z]{2}[A-Z0-9]{10}').firstMatch(name);
    if (match != null) {
      final isin = match.group(0)!;
      final cost = (s['cost'] as num?)?.toDouble() ?? 0;
      final amount = (s['amount'] as num?)?.toDouble() ?? 0;
      if (cost > 0 || amount > 0) {
        final info = isinToInfo.putIfAbsent(isin, () => _RedemptionInfo());
        info.cost += cost;
        info.amount += amount;
      }
    }
  }
  if (isinToInfo.isEmpty) return result;

  // 2. Build ISIN → amfi_code from existing transactions (most reliable —
  //    uses the user's own ISINs which definitely match their portfolio)
  final isinToAmfi = <String, int>{};
  for (final tx in allTxs) {
    if (tx.isin != null && tx.amfiCode != null) {
      isinToAmfi[tx.isin!] = tx.amfiCode!;
    }
  }

  // 3. For ISINs not resolved via transactions, try fund_master as fallback
  final unresolvedIsins = isinToInfo.keys
      .where((isin) => !isinToAmfi.containsKey(isin))
      .toList();
  if (unresolvedIsins.isNotEmpty) {
    final orFilter = unresolvedIsins
        .map((i) => 'isin_growth.eq.$i,isin_div_reinvest.eq.$i')
        .join(',');
    final response = await client
        .from('fund_master')
        .select('amfi_code, isin_growth, isin_div_reinvest')
        .or(orFilter);
    for (final row in response as List) {
      final amfi = row['amfi_code'] as int;
      final g = row['isin_growth'] as String?;
      final d = row['isin_div_reinvest'] as String?;
      if (g != null && !isinToAmfi.containsKey(g)) isinToAmfi[g] = amfi;
      if (d != null && !isinToAmfi.containsKey(d)) isinToAmfi[d] = amfi;
    }
  }

  // 4. Map amfi_code → total redemption info
  for (final entry in isinToInfo.entries) {
    final amfi = isinToAmfi[entry.key];
    if (amfi != null) {
      final existing = result.putIfAbsent(amfi, () => _RedemptionInfo());
      existing.cost += entry.value.cost;
      existing.amount += entry.value.amount;
    }
  }
  return result;
}

// ─── CAMS Tax Statement (from uploaded XLS) ─────────────────────────────────

/// Heuristic: returns true if scheme name suggests a non-equity (debt/liquid/
/// money-market) fund.  Used when the registrar file does not provide an
/// explicit `is_equity` flag (e.g. MF Central).
bool _isLikelyNonEquityScheme(String schemeName) {
  final l = schemeName.toLowerCase();
  return l.contains('liquid') ||
      l.contains('money market') ||
      l.contains('overnight') ||
      l.contains('ultra short') ||
      l.contains('low duration') ||
      l.contains('short duration') ||
      l.contains('medium duration') ||
      l.contains('gilt') ||
      l.contains('corporate bond') ||
      l.contains('banking') ||
      l.contains('credit risk') ||
      l.contains('dynamic bond') ||
      l.contains('floater') ||
      l.contains('fixed maturity') ||
      l.contains('debt fund') ||
      l.contains('income fund') ||
      l.contains('bond fund') ||
      l.contains('constant maturity');
}

class CamsTaxStatement {
  const CamsTaxStatement({
    required this.financialYear,
    this.investorName,
    this.pan,
    this.equityStcg = 0,
    this.equityLtcgWithIdx = 0,
    this.equityLtcgNoIdx = 0,
    this.nonEquityStcg = 0,
    this.nonEquityLtcgWithIdx = 0,
    this.nonEquityLtcgNoIdx = 0,
    this.totalStt = 0,
    this.schemeBreakdowns = const [],
    this.transactionDetails = const [],
    this.eqStcgQuarterly = const [],
    this.eqLtcgQuarterly = const [],
    this.neStcgQuarterly = const [],
    this.fundMasterEquityMap = const {},
  });

  final String financialYear;
  final String? investorName;
  final String? pan;
  final double equityStcg;
  final double equityLtcgWithIdx;
  final double equityLtcgNoIdx;
  final double nonEquityStcg;
  final double nonEquityLtcgWithIdx;
  final double nonEquityLtcgNoIdx;
  final double totalStt;
  final List<Map<String, dynamic>> schemeBreakdowns;
  final List<Map<String, dynamic>> transactionDetails;
  final List<double> eqStcgQuarterly;
  final List<double> eqLtcgQuarterly;
  final List<double> neStcgQuarterly;
  /// ISIN → isEquity from fund_master tax_category (authoritative classification)
  final Map<String, bool> fundMasterEquityMap;

  double get equityLtcg => equityLtcgWithIdx + equityLtcgNoIdx;
  double get nonEquityLtcg => nonEquityLtcgWithIdx + nonEquityLtcgNoIdx;

  double get totalGain => equityStcg + equityLtcg +
      nonEquityStcg + nonEquityLtcg;

  bool get hasData => totalGain != 0 || totalStt != 0;

  /// Gains computed from per-lot transaction details (more accurate than
  /// XLSX SCHEMEWISE/OVERALL_SUMMARY which can have column-mapping errors).
  /// Falls back to XLSX summary if no per-lot data.
  ({double eqStcg, double eqLtcg, double neStcg, double neLtcg}) get perLotGains {
    if (transactionDetails.isEmpty) {
      return (eqStcg: equityStcg, eqLtcg: equityLtcg,
          neStcg: nonEquityStcg, neLtcg: nonEquityLtcg);
    }
    // Build ISIN → isEquity: fund_master (authoritative) > schemeBreakdowns
    final isEquityByIsin = <String, bool>{};
    for (final bd in schemeBreakdowns) {
      final scheme = bd['scheme']?.toString() ?? '';
      final m = RegExp(r'INF[A-Z0-9]{9}').firstMatch(scheme);
      if (m != null) isEquityByIsin[m.group(0)!] = bd['is_equity'] == true;
    }
    // Override with fund_master classification (higher priority)
    isEquityByIsin.addAll(fundMasterEquityMap);

    double eqS = 0, eqL = 0, neS = 0, neL = 0;
    for (final txn in transactionDetails) {
      final isin = txn['isin']?.toString() ?? '';
      final isEq = isEquityByIsin[isin] ?? false;
      final st = (txn['st_gain'] as num?)?.toDouble() ?? 0;
      final lt = ((txn['lt_no_idx'] as num?)?.toDouble() ?? 0) +
          ((txn['lt_with_idx'] as num?)?.toDouble() ?? 0);
      if (isEq) { eqS += st; eqL += lt; } else { neS += st; neL += lt; }
    }
    return (eqStcg: eqS, eqLtcg: eqL, neStcg: neS, neLtcg: neL);
  }

  double get perLotTotalGain {
    final g = perLotGains;
    return g.eqStcg + g.eqLtcg + g.neStcg + g.neLtcg;
  }

  /// Return a filtered copy containing only schemes/txns for a specific member.
  /// If [memberId] is null, returns this (all members combined).
  CamsTaxStatement forMember(String? memberId) {
    if (memberId == null) return this;

    final filteredSchemes = schemeBreakdowns
        .where((s) => s['_member_id'] == memberId)
        .toList();
    final filteredTxns = transactionDetails
        .where((t) => t['_member_id'] == memberId)
        .toList();

    // Recompute totals from filtered schemes
    double eqS = 0, eqL = 0, neS = 0, neL = 0;
    for (final s in filteredSchemes) {
      final isEq = s['is_equity'] == true;
      final stcg = (s['short_term'] as num?)?.toDouble() ?? 0;
      final ltcg = ((s['lt_with_idx'] as num?)?.toDouble() ?? 0) +
          ((s['lt_no_idx'] as num?)?.toDouble() ?? 0);
      if (isEq) { eqS += stcg; eqL += ltcg; } else { neS += stcg; neL += ltcg; }
    }

    return CamsTaxStatement(
      financialYear: financialYear,
      investorName: investorName,
      pan: pan,
      equityStcg: eqS,
      equityLtcgNoIdx: eqL,
      nonEquityStcg: neS,
      nonEquityLtcgNoIdx: neL,
      totalStt: totalStt,
      schemeBreakdowns: filteredSchemes,
      transactionDetails: filteredTxns,
      eqStcgQuarterly: eqStcgQuarterly,
      eqLtcgQuarterly: eqLtcgQuarterly,
      neStcgQuarterly: neStcgQuarterly,
      fundMasterEquityMap: fundMasterEquityMap,
    );
  }

  /// Compute estimated tax on CAMS/MFC verified gains.
  /// [slabRate] is the member's income-tax slab rate (e.g. 0.30).
  ({
    double equityLtcgTax,
    double equityStcgTax,
    double nonEquityStcgTax,
    double nonEquityLtcgTax,
    double totalBeforeCess,
    double cess,
    double totalTax,
    double ltcgExemptionUsed,
  }) computeTax({double slabRate = 0.30}) {
    // Use per-lot gains (from transaction_details) when available — these are
    // more accurate than XLSX scheme-level summaries which can be inconsistent.
    final g = perLotGains;

    // Equity LTCG: 12.5% after ₹1.25L exemption
    final exemption = AppConstants.ltcgExemptionPerPersonPerFy;
    final ltcgExemptionUsed = g.eqLtcg.clamp(0.0, exemption);
    final taxableEqLtcg = (g.eqLtcg - ltcgExemptionUsed).clamp(0.0, double.infinity);
    final equityLtcgTax = taxableEqLtcg * AppConstants.equityLtcgRate;

    // Equity STCG: 20%
    final equityStcgTax = g.eqStcg.clamp(0.0, double.infinity) * AppConstants.equityStcgRate;

    // Non-Equity STCG: slab rate (debt post-Apr 2023 = always slab)
    final nonEquityStcgTax = g.neStcg.clamp(0.0, double.infinity) * slabRate;

    // Non-Equity LTCG: 12.5% (gold/FoF held >24m)
    final nonEquityLtcgTax = g.neLtcg.clamp(0.0, double.infinity) * AppConstants.goldFofLtcgRate;

    final totalBeforeCess = equityLtcgTax + equityStcgTax + nonEquityStcgTax + nonEquityLtcgTax;
    final cess = totalBeforeCess * AppConstants.healthEducationCess;

    return (
      equityLtcgTax: equityLtcgTax,
      equityStcgTax: equityStcgTax,
      nonEquityStcgTax: nonEquityStcgTax,
      nonEquityLtcgTax: nonEquityLtcgTax,
      totalBeforeCess: totalBeforeCess,
      cess: cess,
      totalTax: totalBeforeCess + cess,
      ltcgExemptionUsed: ltcgExemptionUsed,
    );
  }
}

@riverpod
Future<CamsTaxStatement?> camsTaxStatement(CamsTaxStatementRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final fyKey = currentFyKey();

  final rows = await client
      .from('cams_tax_statements')
      .select()
      .eq('owner_id', userId)
      .eq('financial_year', fyKey);

  if ((rows as List).isEmpty) return null;

  // Tag each scheme breakdown and txn detail with its parent member_id
  for (final r in rows) {
    final memberId = (r as Map<String, dynamic>)['member_id'] as String?;
    for (final s in ((r['scheme_breakdowns'] as List?) ?? [])) {
      if (s is Map) s['_member_id'] = memberId;
    }
    for (final t in ((r['transaction_details'] as List?) ?? [])) {
      if (t is Map) t['_member_id'] = memberId;
    }
  }

  // Merge multiple member statements into one combined view
  final Map<String, dynamic> row;
  if (rows.length == 1) {
    row = rows.first as Map<String, dynamic>;
  } else {
    // Combine: merge scheme_breakdowns, transaction_details, sum quarterlies
    final combined = Map<String, dynamic>.from(rows.first as Map);
    final allSchemes = <dynamic>[...((combined['scheme_breakdowns'] as List?) ?? [])];
    final allTxnDetails = <dynamic>[...((combined['transaction_details'] as List?) ?? [])];
    for (int i = 1; i < rows.length; i++) {
      final r = rows[i] as Map<String, dynamic>;
      allSchemes.addAll((r['scheme_breakdowns'] as List?) ?? []);
      allTxnDetails.addAll((r['transaction_details'] as List?) ?? []);
      // Sum quarterly fields
      for (final prefix in ['eq_stcg_q', 'eq_ltcg_q', 'ne_stcg_q']) {
        for (int q = 1; q <= 5; q++) {
          final key = '$prefix$q';
          combined[key] = ((combined[key] as num?)?.toDouble() ?? 0) +
              ((r[key] as num?)?.toDouble() ?? 0);
        }
      }
      combined['total_stt'] = ((combined['total_stt'] as num?)?.toDouble() ?? 0) +
          ((r['total_stt'] as num?)?.toDouble() ?? 0);
    }
    combined['scheme_breakdowns'] = allSchemes;
    combined['transaction_details'] = allTxnDetails;
    combined['investor_name'] = 'Family';
    row = combined;
  }

  // Parse scheme breakdowns first — we recompute summary totals from them
  final schemes = (row['scheme_breakdowns'] as List?)
      ?.map((e) => Map<String, dynamic>.from(e as Map))
      .toList() ?? [];

  // ── Fetch fund_master tax_category by ISIN for authoritative classification ──
  // CAMS XLSX classifies by sheet name (EQUITY/NONEQUITY) which can be wrong
  // for hybrid funds. Fund_master tax_category is the source of truth.
  final fundMasterIsEquity = <String, bool>{};
  {
    final allIsins = <String>{};
    for (final s in schemes) {
      final scheme = (s['scheme'] as String?) ?? '';
      final m = RegExp(r'INF[A-Z0-9]{9}').firstMatch(scheme);
      if (m != null) allIsins.add(m.group(0)!);
    }
    final txnDetails = (row['transaction_details'] as List?) ?? [];
    for (final txn in txnDetails) {
      final isin = (txn as Map)['isin']?.toString() ?? '';
      if (isin.isNotEmpty) allIsins.add(isin);
    }
    if (allIsins.isNotEmpty) {
      final isinList = allIsins.toList();
      // Check both isin_growth and isin_div_reinvest
      final fundRows = await client
          .from('fund_master')
          .select('isin_growth, isin_div_reinvest, tax_category')
          .inFilter('isin_growth', isinList);
      final fundRowsDivReinvest = await client
          .from('fund_master')
          .select('isin_growth, isin_div_reinvest, tax_category')
          .inFilter('isin_div_reinvest', isinList);
      for (final fr in [...fundRows, ...fundRowsDivReinvest]) {
        final tc = TaxCategory.fromString(fr['tax_category'] as String?);
        final isEq = tc.isEquityType;
        final ig = fr['isin_growth'] as String? ?? '';
        final id = fr['isin_div_reinvest'] as String? ?? '';
        if (ig.isNotEmpty) fundMasterIsEquity[ig] = isEq;
        if (id.isNotEmpty) fundMasterIsEquity[id] = isEq;
      }
    }
  }

  // ── Back-patch schemeBreakdowns with per-lot gains (accurate) ──
  // XLSX SCHEMEWISE sheets can have wrong STCG/LTCG column values.
  // Per-lot transaction_details are the source of truth for gains.
  final txnDetails = (row['transaction_details'] as List?)
      ?.map((e) => Map<String, dynamic>.from(e as Map))
      .toList() ?? [];

  if (txnDetails.isNotEmpty) {
    // Aggregate per-lot gains by ISIN
    final perLotByIsin = <String, ({double stcg, double ltcg})>{};
    for (final txn in txnDetails) {
      final isin = txn['isin']?.toString() ?? '';
      if (isin.isEmpty) continue;
      final existing = perLotByIsin[isin];
      final st = (txn['st_gain'] as num?)?.toDouble() ?? 0;
      final lt = ((txn['lt_no_idx'] as num?)?.toDouble() ?? 0) +
          ((txn['lt_with_idx'] as num?)?.toDouble() ?? 0);
      perLotByIsin[isin] = (
        stcg: (existing?.stcg ?? 0) + st,
        ltcg: (existing?.ltcg ?? 0) + lt,
      );
    }

    // Override scheme STCG/LTCG with per-lot values
    for (final s in schemes) {
      final name = (s['scheme'] as String?) ?? '';
      final m = RegExp(r'INF[A-Z0-9]{9}').firstMatch(name);
      if (m != null) {
        final isin = m.group(0)!;
        final perLot = perLotByIsin[isin];
        if (perLot != null) {
          s['short_term'] = perLot.stcg;
          s['lt_with_idx'] = 0.0;
          s['lt_no_idx'] = perLot.ltcg;
        }
      }
    }
  }

  // ── Recompute equity vs non-equity from per-scheme data ──
  // Use fund_master tax_category as source of truth, fall back to CAMS sheet
  // classification, then heuristic name matching.
  double eqStcg = 0, eqLtcg = 0, neStcg = 0, neLtcg = 0;
  if (schemes.isNotEmpty) {
    for (final s in schemes) {
      final name = (s['scheme'] as String?) ?? '';
      final isinMatch = RegExp(r'INF[A-Z0-9]{9}').firstMatch(name);
      final isin = isinMatch?.group(0);

      // Priority: fund_master > CAMS sheet flag > heuristic
      final fundMasterFlag = isin != null ? fundMasterIsEquity[isin] : null;
      final explicitFlag = s['is_equity'];
      final bool isEquity;
      if (fundMasterFlag != null) {
        isEquity = fundMasterFlag;
      } else if (explicitFlag != null) {
        isEquity = explicitFlag == true;
      } else {
        isEquity = !_isLikelyNonEquityScheme(name);
      }

      // Back-patch the flag so the UI can display labels
      s['is_equity'] = isEquity;

      final stcg = (s['short_term'] as num?)?.toDouble() ?? 0;
      final ltcgIdx = (s['lt_with_idx'] as num?)?.toDouble() ?? 0;
      final ltcgNoIdx = (s['lt_no_idx'] as num?)?.toDouble() ?? 0;

      if (isEquity) {
        eqStcg += stcg;
        eqLtcg += ltcgIdx + ltcgNoIdx;
      } else {
        neStcg += stcg;
        neLtcg += ltcgIdx + ltcgNoIdx;
      }
    }
  } else {
    // No per-scheme data — fall back to DB summary fields
    eqStcg = (row['equity_stcg'] as num?)?.toDouble() ?? 0;
    eqLtcg = ((row['equity_ltcg_with_idx'] as num?)?.toDouble() ?? 0) +
        ((row['equity_ltcg_no_idx'] as num?)?.toDouble() ?? 0);
    neStcg = (row['non_equity_stcg'] as num?)?.toDouble() ?? 0;
    neLtcg = ((row['non_equity_ltcg_with_idx'] as num?)?.toDouble() ?? 0) +
        ((row['non_equity_ltcg_no_idx'] as num?)?.toDouble() ?? 0);
  }

  return CamsTaxStatement(
    financialYear: row['financial_year'] as String? ?? fyKey,
    investorName: row['investor_name'] as String?,
    pan: row['pan'] as String?,
    equityStcg: eqStcg,
    equityLtcgWithIdx: 0,
    equityLtcgNoIdx: eqLtcg,
    nonEquityStcg: neStcg,
    nonEquityLtcgWithIdx: 0,
    nonEquityLtcgNoIdx: neLtcg,
    totalStt: (row['total_stt'] as num?)?.toDouble() ?? 0,
    schemeBreakdowns: schemes,
    fundMasterEquityMap: fundMasterIsEquity,
    transactionDetails: txnDetails,
    eqStcgQuarterly: [
      (row['eq_stcg_q1'] as num?)?.toDouble() ?? 0,
      (row['eq_stcg_q2'] as num?)?.toDouble() ?? 0,
      (row['eq_stcg_q3'] as num?)?.toDouble() ?? 0,
      (row['eq_stcg_q4'] as num?)?.toDouble() ?? 0,
      (row['eq_stcg_q5'] as num?)?.toDouble() ?? 0,
    ],
    eqLtcgQuarterly: [
      (row['eq_ltcg_q1'] as num?)?.toDouble() ?? 0,
      (row['eq_ltcg_q2'] as num?)?.toDouble() ?? 0,
      (row['eq_ltcg_q3'] as num?)?.toDouble() ?? 0,
      (row['eq_ltcg_q4'] as num?)?.toDouble() ?? 0,
      (row['eq_ltcg_q5'] as num?)?.toDouble() ?? 0,
    ],
    neStcgQuarterly: [
      (row['ne_stcg_q1'] as num?)?.toDouble() ?? 0,
      (row['ne_stcg_q2'] as num?)?.toDouble() ?? 0,
      (row['ne_stcg_q3'] as num?)?.toDouble() ?? 0,
      (row['ne_stcg_q4'] as num?)?.toDouble() ?? 0,
      (row['ne_stcg_q5'] as num?)?.toDouble() ?? 0,
    ],
  );
}

// ─── AIS (Annual Information Statement) ────────────────────────────────────

class AisStatement {
  const AisStatement({
    required this.financialYear,
    this.pan,
    this.investorName,
    this.memberId,
    // Stock capital gains (SFT-17-LES)
    this.stockStcg = 0,
    this.stockLtcg = 0,
    // Equity MF capital gains (SFT-17-EMF)
    this.eqMfStcg = 0,
    this.eqMfLtcg = 0,
    // Debt MF capital gains (SFT-18-OTU)
    this.debtMfStcg = 0,
    this.debtMfLtcg = 0,
    // Counts
    this.stockSaleCount = 0,
    this.mfSaleCount = 0,
    this.purchaseCount = 0,
    // TDS totals
    this.totalSalary = 0,
    this.totalDividends = 0,
    this.totalInterest = 0,
    this.totalTds = 0,
    // Raw entries
    this.stockSales = const [],
    this.equityMfSales = const [],
    this.debtMfSales = const [],
    this.taxPayments = const [],
  });

  final String financialYear;
  final String? pan;
  final String? investorName;
  final String? memberId;
  final double stockStcg;
  final double stockLtcg;
  final double eqMfStcg;
  final double eqMfLtcg;
  final double debtMfStcg;
  final double debtMfLtcg;
  final int stockSaleCount;
  final int mfSaleCount;
  final int purchaseCount;
  final double totalSalary;
  final double totalDividends;
  final double totalInterest;
  final double totalTds;
  final List<Map<String, dynamic>> stockSales;
  final List<Map<String, dynamic>> equityMfSales;
  final List<Map<String, dynamic>> debtMfSales;
  final List<Map<String, dynamic>> taxPayments;

  // ── Computed getters ──
  bool get hasData => stockSaleCount > 0 || mfSaleCount > 0;
  double get totalEquityStcg => stockStcg + eqMfStcg;
  double get totalEquityLtcg => stockLtcg + eqMfLtcg;
  double get totalStcg => stockStcg + eqMfStcg + debtMfStcg;
  double get totalLtcg => stockLtcg + eqMfLtcg + debtMfLtcg;
  double get totalGain => totalStcg + totalLtcg;

  /// Filter for a specific member. AIS is per-PAN so memberId check is direct.
  AisStatement forMember(String? memberId) {
    if (memberId == null) return this;
    if (this.memberId == memberId) return this;
    return AisStatement(financialYear: financialYear);
  }

  /// Compute estimated tax from AIS gains.
  ({
    double equityLtcgTax,
    double equityStcgTax,
    double debtStcgTax,
    double debtLtcgTax,
    double stockStcgTax,
    double stockLtcgTax,
    double totalBeforeCess,
    double cess,
    double totalTax,
    double ltcgExemptionUsed,
  }) computeTax({double slabRate = 0.30}) {
    // Equity LTCG: 12.5% after ₹1.25L exemption (stocks + equity MF)
    final exemption = AppConstants.ltcgExemptionPerPersonPerFy;
    final eqLtcg = stockLtcg + eqMfLtcg;
    final ltcgExemptionUsed = eqLtcg.clamp(0.0, exemption);
    final taxableEqLtcg = (eqLtcg - ltcgExemptionUsed).clamp(0.0, double.infinity);
    final equityLtcgTax = taxableEqLtcg * AppConstants.equityLtcgRate;

    // Equity STCG: 20% (stocks + equity MF)
    final eqStcg = stockStcg + eqMfStcg;
    final equityStcgTax = eqStcg.clamp(0.0, double.infinity) * AppConstants.equityStcgRate;

    // Debt STCG: slab rate
    final debtStcgTax = debtMfStcg.clamp(0.0, double.infinity) * slabRate;

    // Debt LTCG: slab rate (post-Apr 2023 debt funds)
    final debtLtcgTax = debtMfLtcg.clamp(0.0, double.infinity) * slabRate;

    final totalBeforeCess = equityLtcgTax + equityStcgTax + debtStcgTax + debtLtcgTax;
    final cess = totalBeforeCess * AppConstants.healthEducationCess;
    final totalTax = totalBeforeCess + cess;

    return (
      equityLtcgTax: equityLtcgTax,
      equityStcgTax: equityStcgTax,
      debtStcgTax: debtStcgTax,
      debtLtcgTax: debtLtcgTax,
      stockStcgTax: 0.0,
      stockLtcgTax: 0.0,
      totalBeforeCess: totalBeforeCess,
      cess: cess,
      totalTax: totalTax,
      ltcgExemptionUsed: ltcgExemptionUsed,
    );
  }
}

@riverpod
Future<AisStatement?> aisStatement(AisStatementRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final fyKey = currentFyKey();

  final rows = await client
      .from('ais_statements')
      .select()
      .eq('owner_id', userId)
      .eq('financial_year', fyKey);

  if ((rows as List).isEmpty) return null;

  // Merge multiple member AIS statements (one per family member)
  double stockStcg = 0, stockLtcg = 0;
  double eqMfStcg = 0, eqMfLtcg = 0;
  double debtMfStcg = 0, debtMfLtcg = 0;
  int stockSaleCount = 0, mfSaleCount = 0, purchaseCount = 0;
  double totalSalary = 0, totalDividends = 0, totalInterest = 0, totalTds = 0;
  final allStockSales = <Map<String, dynamic>>[];
  final allEqMfSales = <Map<String, dynamic>>[];
  final allDebtMfSales = <Map<String, dynamic>>[];
  final allTaxPayments = <Map<String, dynamic>>[];

  for (final r in rows) {
    final row = r as Map<String, dynamic>;
    stockStcg += (row['stock_stcg'] as num?)?.toDouble() ?? 0;
    stockLtcg += (row['stock_ltcg'] as num?)?.toDouble() ?? 0;
    eqMfStcg += (row['eq_mf_stcg'] as num?)?.toDouble() ?? 0;
    eqMfLtcg += (row['eq_mf_ltcg'] as num?)?.toDouble() ?? 0;
    debtMfStcg += (row['debt_mf_stcg'] as num?)?.toDouble() ?? 0;
    debtMfLtcg += (row['debt_mf_ltcg'] as num?)?.toDouble() ?? 0;
    stockSaleCount += (row['stock_sale_count'] as int?) ?? 0;
    mfSaleCount += (row['mf_sale_count'] as int?) ?? 0;
    purchaseCount += (row['purchase_count'] as int?) ?? 0;
    totalSalary += (row['total_salary'] as num?)?.toDouble() ?? 0;
    totalDividends += (row['total_dividends'] as num?)?.toDouble() ?? 0;
    totalInterest += (row['total_interest'] as num?)?.toDouble() ?? 0;
    totalTds += (row['total_tds'] as num?)?.toDouble() ?? 0;

    // Tag entries with member_id
    final memberId = row['member_id'] as String?;
    for (final s in ((row['stock_sales'] as List?) ?? [])) {
      if (s is Map) s['_member_id'] = memberId;
      allStockSales.add(Map<String, dynamic>.from(s as Map));
    }
    for (final s in ((row['equity_mf_sales'] as List?) ?? [])) {
      if (s is Map) s['_member_id'] = memberId;
      allEqMfSales.add(Map<String, dynamic>.from(s as Map));
    }
    for (final s in ((row['debt_mf_sales'] as List?) ?? [])) {
      if (s is Map) s['_member_id'] = memberId;
      allDebtMfSales.add(Map<String, dynamic>.from(s as Map));
    }
    for (final s in ((row['tax_payments'] as List?) ?? [])) {
      if (s is Map) s['_member_id'] = memberId;
      allTaxPayments.add(Map<String, dynamic>.from(s as Map));
    }
  }

  // For single member, use the first row's member_id
  final firstRow = rows.first as Map<String, dynamic>;

  return AisStatement(
    financialYear: firstRow['financial_year'] as String? ?? fyKey,
    pan: firstRow['pan'] as String?,
    investorName: firstRow['investor_name'] as String?,
    memberId: firstRow['member_id'] as String?,
    stockStcg: stockStcg,
    stockLtcg: stockLtcg,
    eqMfStcg: eqMfStcg,
    eqMfLtcg: eqMfLtcg,
    debtMfStcg: debtMfStcg,
    debtMfLtcg: debtMfLtcg,
    stockSaleCount: stockSaleCount,
    mfSaleCount: mfSaleCount,
    purchaseCount: purchaseCount,
    totalSalary: totalSalary,
    totalDividends: totalDividends,
    totalInterest: totalInterest,
    totalTds: totalTds,
    stockSales: allStockSales,
    equityMfSales: allEqMfSales,
    debtMfSales: allDebtMfSales,
    taxPayments: allTaxPayments,
  );
}
