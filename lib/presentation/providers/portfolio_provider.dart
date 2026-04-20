import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/asset_classes.dart';
import '../../data/models/amfi_category_model.dart';
import '../../data/models/portfolio_summary_model.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/usecases/calculate_xirr.dart';
import '../../domain/usecases/calculate_cagr.dart';
import 'amfi_category_provider.dart';
import 'auth_provider.dart';
import 'family_provider.dart';
import 'reconciliation_provider.dart';

part 'portfolio_provider.g.dart';

// ─── Transactions stream ──────────────────────────────────────────────────────
@riverpod
Future<List<TransactionModel>> allTransactions(AllTransactionsRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('transactions')
      .select('*, fund_master(fund_name, category, tax_category, latest_nav, fund_managers, crisil_rating, jan_31_nav, tax_period, exit_load, plan_type, expense_ratio, return_1y, amfi_category_id, benchmark_tier1, benchmark_tier2)')
      .eq('owner_id', userId)
      .order('tx_date', ascending: false)
      .limit(50000);

  return (response as List)
      .map((row) => TransactionModel.fromJson(row as Map<String, dynamic>))
      .toList();
}

// ─── NAV map (amfi_code → latest_nav) ────────────────────────────────────────
// Resolves via amfi_code first, then falls back to ISIN matching for
// transactions that have ISIN but no amfi_code.
@riverpod
Future<Map<int, double>> latestNavMap(LatestNavMapRef ref) async {
  final txs = await ref.watch(allTransactionsProvider.future);
  final amfiCodes = txs
      .where((t) => t.amfiCode != null)
      .map((t) => t.amfiCode!)
      .toSet()
      .toList();

  final client = ref.watch(supabaseClientProvider);
  final navMap = <int, double>{};

  // 1. Lookup by amfi_code (primary)
  if (amfiCodes.isNotEmpty) {
    final response = await client
        .from('fund_master')
        .select('amfi_code, latest_nav, prev_nav')
        .inFilter('amfi_code', amfiCodes);

    for (final row in (response as List)) {
      navMap[(row['amfi_code'] as int)] =
          (row['latest_nav'] as num?)?.toDouble() ?? 0.0;
    }
  }

  // 2. ISIN fallback: for transactions with ISIN but no amfi_code
  final isinsWithoutAmfi = txs
      .where((t) => t.amfiCode == null && t.isin != null && t.isin!.isNotEmpty)
      .map((t) => t.isin!)
      .toSet()
      .toList();

  if (isinsWithoutAmfi.isNotEmpty) {
    final isinResponse = await client
        .from('fund_master')
        .select('amfi_code, latest_nav, isin_growth')
        .inFilter('isin_growth', isinsWithoutAmfi);

    for (final row in (isinResponse as List)) {
      final code = row['amfi_code'] as int;
      navMap[code] = (row['latest_nav'] as num?)?.toDouble() ?? 0.0;
    }
  }

  return navMap;
}

// ─── Prev NAV map (amfi_code → prev_nav) for today's change ─────────────────
final prevNavMapProvider = FutureProvider.autoDispose<Map<int, double>>((ref) async {
  final txs = await ref.watch(allTransactionsProvider.future);
  final amfiCodes = txs
      .where((t) => t.amfiCode != null)
      .map((t) => t.amfiCode!)
      .toSet()
      .toList();

  if (amfiCodes.isEmpty) return {};

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('fund_master')
      .select('amfi_code, prev_nav')
      .inFilter('amfi_code', amfiCodes);

  return {
    for (final row in (response as List))
      (row['amfi_code'] as int): (row['prev_nav'] as num?)?.toDouble() ?? 0.0,
  };
});

// ─── Last NAV update timestamp ───────────────────────────────────────────────
final navLastUpdatedProvider = FutureProvider.autoDispose<DateTime?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('fund_master')
      .select('nav_updated_at')
      .not('nav_updated_at', 'is', null)
      .order('nav_updated_at', ascending: false)
      .limit(1);

  final rows = response as List;
  if (rows.isEmpty) return null;
  final ts = rows.first['nav_updated_at'] as String?;
  return ts != null ? DateTime.tryParse(ts) : null;
});

// ─── Portfolio summary provider (parameterised by memberId) ─────────────────
@riverpod
Future<PortfolioSummary> portfolioSummary(
  PortfolioSummaryRef ref,
  String? memberId, // null = family view
) async {
  // ── ALL view: aggregate individual member summaries ────────────────────
  if (memberId == null) {
    return _buildFamilySummary(ref);
  }

  // ── Individual member view ─────────────────────────────────────────────
  return _buildMemberSummary(ref, memberId);
}

// ─── Family (All) summary: sum of individual member summaries ───────────────
Future<PortfolioSummary> _buildFamilySummary(PortfolioSummaryRef ref) async {
  final members = await ref.watch(familyMembersProvider.future);
  final allTxs = await ref.watch(allTransactionsProvider.future);

  double totalInvested = 0;
  double totalCurrentValue = 0;
  double totalTodayGain = 0;
  final allocationValue = <String, double>{};
  final holdingsByAmfi = <int, List<FundHoldingSummary>>{};
  final holdingsByName = <String, List<FundHoldingSummary>>{};

  // Track each member's active holdings for XIRR filtering
  final memberActiveAmfi = <String, Set<int>>{};
  final memberActiveNames = <String, Set<String>>{};

  for (final member in members) {
    final summary = await ref.watch(portfolioSummaryProvider(member.id).future);
    totalInvested += summary.totalInvested;
    totalCurrentValue += summary.currentValue;
    totalTodayGain += summary.todayGain;

    // Track this member's active fund identifiers
    memberActiveAmfi[member.id] = summary.fundHoldings
        .map((f) => f.amfiCode).where((c) => c != 0).toSet();
    memberActiveNames[member.id] = summary.fundHoldings
        .where((f) => f.amfiCode == 0).map((f) => f.fundName).toSet();

    for (final e in summary.allocationValue.entries) {
      allocationValue[e.key] = (allocationValue[e.key] ?? 0) + e.value;
    }

    for (final f in summary.fundHoldings) {
      if (f.amfiCode != 0) {
        (holdingsByAmfi[f.amfiCode] ??= []).add(f);
      } else {
        (holdingsByName[f.fundName] ??= []).add(f);
      }
    }
  }

  // Merge fund holdings that share amfiCode across members
  final fundHoldings = <FundHoldingSummary>[];

  for (final entry in holdingsByAmfi.entries) {
    final holdings = entry.value;
    if (holdings.length == 1) {
      fundHoldings.add(holdings.first);
    } else {
      fundHoldings.add(_mergeHoldings(entry.key, holdings, allTxs));
    }
  }

  for (final entry in holdingsByName.entries) {
    final holdings = entry.value;
    if (holdings.length == 1) {
      fundHoldings.add(holdings.first);
    } else {
      fundHoldings.add(_mergeHoldings(null, holdings, allTxs));
    }
  }

  fundHoldings.sort((a, b) => b.currentValue.compareTo(a.currentValue));

  final totalGain = totalCurrentValue - totalInvested;
  final gainPct = totalInvested > 0 ? (totalGain / totalInvested) * 100 : 0.0;
  final todayGainPct = totalCurrentValue > 0
      ? (totalTodayGain / (totalCurrentValue - totalTodayGain)) * 100
      : 0.0;

  // Overall XIRR — only include each member's active holding transactions
  final cashFlows = <CashFlow>[];
  DateTime? oldestActiveDate;
  for (final tx in allTxs) {
    final mid = tx.memberId ?? '';
    final amfis = memberActiveAmfi[mid] ?? {};
    final names = memberActiveNames[mid] ?? {};

    final bool isActive;
    if (tx.amfiCode != null) {
      isActive = amfis.contains(tx.amfiCode);
    } else {
      isActive = names.contains(tx.assetName ?? tx.fundMaster?.fundName ?? '');
    }
    if (!isActive) continue;

    cashFlows.add(CashFlow(
      amount: tx.isPurchase ? -tx.amount : tx.amount,
      date: tx.parsedDate,
    ));
    if (oldestActiveDate == null || tx.parsedDate.isBefore(oldestActiveDate)) {
      oldestActiveDate = tx.parsedDate;
    }
  }
  cashFlows.add(CashFlow(amount: totalCurrentValue, date: DateTime.now()));
  final overallXirr = XirrCalculator.compute(cashFlows);

  // Portfolio CAGR
  double? portfolioCagr;
  if (oldestActiveDate != null && totalInvested > 0 && totalCurrentValue > 0) {
    final days = DateTime.now().difference(oldestActiveDate).inDays;
    if (days > 0) {
      final c = CagrCalculator.fromHoldingDays(
        invested: totalInvested,
        currentValue: totalCurrentValue,
        holdingDays: days,
      );
      portfolioCagr = c.isNaN ? null : c * 100;
    }
  }

  // Allocation %
  final allocationPct = <String, double>{};
  if (totalCurrentValue > 0) {
    for (final e in allocationValue.entries) {
      allocationPct[e.key] = (e.value / totalCurrentValue) * 100;
    }
  }

  return PortfolioSummary(
    memberId: null,
    totalInvested: totalInvested,
    currentValue: totalCurrentValue,
    totalGain: totalGain,
    gainPct: gainPct,
    xirr: overallXirr.isNaN ? null : overallXirr * 100,
    cagr: portfolioCagr,
    todayGain: totalTodayGain,
    todayGainPct: todayGainPct,
    allocationPct: allocationPct,
    allocationValue: allocationValue,
    fundHoldings: fundHoldings,
    asOfDate: DateTime.now(),
  );
}

// ─── Merge multiple FundHoldingSummary for same fund across members ──────────
FundHoldingSummary _mergeHoldings(
  int? amfiCode,
  List<FundHoldingSummary> holdings,
  List<TransactionModel> allTxs,
) {
  final totalInvested = holdings.fold(0.0, (s, h) => s + h.totalInvested);
  final totalCurrentValue = holdings.fold(0.0, (s, h) => s + h.currentValue);
  final totalUnits = holdings.fold(0.0, (s, h) => s + h.totalUnits);
  final gain = totalCurrentValue - totalInvested;
  final gainPct = totalInvested > 0 ? (gain / totalInvested) * 100 : 0.0;

  // Compute merged XIRR from all transactions for this fund
  final fundTxs = amfiCode != null
      ? allTxs.where((t) => t.amfiCode == amfiCode).toList()
      : allTxs.where((t) => t.assetName == holdings.first.fundName).toList();

  final cashFlows = <CashFlow>[];
  for (final tx in fundTxs) {
    cashFlows.add(CashFlow(
      amount: tx.isPurchase ? -tx.amount : tx.amount,
      date: tx.parsedDate,
    ));
  }
  cashFlows.add(CashFlow(amount: totalCurrentValue, date: DateTime.now()));
  final xirr = XirrCalculator.compute(cashFlows);

  final oldest = fundTxs.map((t) => t.parsedDate).reduce((a, b) => a.isBefore(b) ? a : b);
  final cagr = CagrCalculator.fromHoldingDays(
    invested: totalInvested,
    currentValue: totalCurrentValue,
    holdingDays: DateTime.now().difference(oldest).inDays,
  );

  // Combine all holder breakdowns
  final allHolders = holdings.expand((h) => h.holderBreakdown).toList();

  // Earliest invested date across all holders
  final earliestDate = holdings
      .where((h) => h.investedSince != null)
      .map((h) => h.investedSince!)
      .fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);

  return FundHoldingSummary(
    amfiCode: amfiCode ?? 0,
    fundName: holdings.first.fundName,
    assetType: holdings.first.assetType,
    category: holdings.first.category,
    taxCategory: holdings.first.taxCategory,
    assetClassLabel: holdings.first.assetClassLabel,
    amfiCategoryId: holdings.first.amfiCategoryId,
    benchmarkTier1: holdings.first.benchmarkTier1,
    benchmarkTier2: holdings.first.benchmarkTier2,
    totalUnits: totalUnits,
    totalInvested: totalInvested,
    currentValue: totalCurrentValue,
    gain: gain,
    gainPct: gainPct,
    cagr: cagr.isNaN ? null : cagr * 100,
    xirr: xirr.isNaN ? null : xirr * 100,
    latestNav: holdings.first.latestNav,
    holderBreakdown: allHolders,
    investedSince: earliestDate,
    planType: holdings.first.planType,
    expenseRatio: holdings.first.expenseRatio,
    return1y: holdings.first.return1y,
  );
}

// ─── Individual member portfolio summary ────────────────────────────────────
Future<PortfolioSummary> _buildMemberSummary(
  PortfolioSummaryRef ref,
  String memberId,
) async {
  final allTxs = await ref.watch(allTransactionsProvider.future);
  final navMap = await ref.watch(latestNavMapProvider.future);
  final prevNavMap = await ref.watch(prevNavMapProvider.future);
  final amfiCatalog = await ref.watch(amfiCategoryCatalogProvider.future);

  // Build member name lookup for holder breakdown
  final members = await ref.watch(familyMembersProvider.future);
  final memberNames = <String, String>{
    for (final m in members) m.id: m.displayName,
  };

  final txs = allTxs.where((t) => t.memberId == memberId).toList();

  if (txs.isEmpty) {
    return PortfolioSummary(memberId: memberId, asOfDate: DateTime.now());
  }

  // ── Fetch folio_details (registrar truth) to filter redeemed funds ──────
  final folios = await ref.watch(folioDetailsProvider.future);
  // Aggregate closing_units by ISIN from registrar data
  final folioClosingByIsin = <String, double>{};
  for (final f in folios) {
    if (f.isin != null && (f.memberId == null || f.memberId == memberId)) {
      folioClosingByIsin[f.isin!] =
          (folioClosingByIsin[f.isin!] ?? 0) + (f.closingUnits ?? 0);
    }
  }

  // ── Group transactions by amfi_code or asset_name ────────────────────────
  final fundGroups = <int, List<TransactionModel>>{};
  final nameGroups = <String, List<TransactionModel>>{};

  for (final tx in txs) {
    if (tx.amfiCode != null) {
      (fundGroups[tx.amfiCode!] ??= []).add(tx);
    } else {
      final key = tx.assetName ?? tx.fundMaster?.fundName ?? 'Unknown';
      (nameGroups[key] ??= []).add(tx);
    }
  }

  double totalInvested = 0;
  double currentValue = 0;
  double todayGain = 0;
  final allocationValue = <String, double>{};
  final fundHoldings = <FundHoldingSummary>[];

  // ── Helper: process a group of transactions into a holding ──────────────
  void processGroup({
    required int? amfiCode,
    required List<TransactionModel> groupTxs,
    required double nav,
    required double prevNav,
  }) {
    double units = 0;
    double invested = 0;
    final cashFlows = <CashFlow>[];

    // Sort chronologically for correct cost basis tracking
    final sortedTxs = List<TransactionModel>.from(groupTxs)
      ..sort((a, b) => a.parsedDate.compareTo(b.parsedDate));

    for (final tx in sortedTxs) {
      if (tx.isCashOnly) continue; // IDCW-Payout: no unit movement
      final txUnits = tx.units ?? (tx.navAtTx != null && tx.navAtTx! > 0 ? tx.amount / tx.navAtTx! : 0.0);
      if (tx.isPurchase) {
        units += txUnits;
        invested += tx.amount;
        cashFlows.add(CashFlow(amount: -tx.amount, date: tx.parsedDate));
      } else {
        // Reduce cost basis proportionally (weighted average method)
        if (units > 0 && txUnits > 0) {
          final sellRatio = (txUnits / units).clamp(0.0, 1.0);
          invested -= invested * sellRatio;
        }
        units -= txUnits;
        cashFlows.add(CashFlow(amount: tx.amount, date: tx.parsedDate));
      }
    }

    if (units.abs() < 0.01) return; // skip fully redeemed holdings (FP tolerance)

    // ── Registrar truth: if folio_details says closing_units ≈ 0, skip ──────
    // This overrides computed units — CAMS registrar is the source of truth.
    final groupIsin = groupTxs.firstWhere(
      (t) => t.isin != null,
      orElse: () => groupTxs.first,
    ).isin;
    if (groupIsin != null && folioClosingByIsin.containsKey(groupIsin)) {
      final registrarUnits = folioClosingByIsin[groupIsin]!;
      if (registrarUnits.abs() < 0.01) return; // registrar says fully redeemed
    }

    if (invested <= 0) return;

    // Check for manually entered current_value (latest transaction wins)
    final manualCurrentValue = groupTxs
        .where((t) => t.currentValue != null && t.currentValue! > 0)
        .fold<double?>(null, (prev, t) {
      if (prev == null) return t.currentValue;
      return t.parsedDate.isAfter(groupTxs.first.parsedDate)
          ? t.currentValue
          : prev;
    });

    // Priority: manual current_value > NAV-based > invested fallback
    final double fundCurrentValue;
    if (manualCurrentValue != null) {
      fundCurrentValue = manualCurrentValue;
    } else if (nav > 0) {
      fundCurrentValue = units * nav;
    } else {
      fundCurrentValue = invested;
    }

    // Safety net: if amount/nav fallback produces small residual units, the
    // current value will also be negligible. Skip anything worth < ₹100.
    if (fundCurrentValue.abs() < 100) return;

    final fundGain = fundCurrentValue - invested;
    final fundGainPct = invested > 0 ? (fundGain / invested) * 100 : 0.0;

    final fundCashFlows = [...cashFlows, CashFlow(amount: fundCurrentValue, date: DateTime.now())];
    final xirr = XirrCalculator.compute(fundCashFlows);

    final oldestDate = groupTxs.map((t) => t.parsedDate).reduce((a, b) => a.isBefore(b) ? a : b);
    final cagr = CagrCalculator.fromHoldingDays(
      invested: invested,
      currentValue: fundCurrentValue,
      holdingDays: DateTime.now().difference(oldestDate).inDays,
    );

    // Today's change: use actual prev_nav from fund_master
    double fundTodayGain = 0;
    double? fundNav1dPct;
    if (amfiCode != null && nav > 0 && prevNav > 0) {
      fundTodayGain = units * (nav - prevNav);
      fundNav1dPct = ((nav - prevNav) / prevNav) * 100;
      todayGain += fundTodayGain;
    }

    final firstTx = groupTxs.first;
    final taxCategory = firstTx.fundMaster?.taxCategory ?? 'Debt';
    final assetClass = _taxCategoryToAssetClass(
      taxCategory,
      firstTx.fundMaster?.category,
      amfiCategoryId: firstTx.fundMaster?.amfiCategoryId,
      catalog: amfiCatalog,
    );
    allocationValue[assetClass] = (allocationValue[assetClass] ?? 0) + fundCurrentValue;

    totalInvested += invested;
    currentValue += fundCurrentValue;

    // ── Per-holder breakdown (single member in individual view) ────────────
    final holderBreakdown = <HolderFundSummary>[
      HolderFundSummary(
        memberId: memberId,
        memberName: memberNames[memberId] ?? 'Unknown',
        units: units,
        invested: invested,
        currentValue: fundCurrentValue,
        gain: fundGain,
        xirr: xirr.isNaN ? null : xirr * 100,
        cagr: cagr.isNaN ? null : cagr * 100,
        folioNumber: groupTxs.firstWhere(
          (t) => t.folioNumber != null,
          orElse: () => groupTxs.first,
        ).folioNumber,
      ),
    ];

    fundHoldings.add(FundHoldingSummary(
      amfiCode: amfiCode ?? 0,
      fundName: firstTx.fundMaster?.fundName ?? firstTx.assetName ?? 'Unknown',
      assetType: firstTx.assetType,
      category: firstTx.fundMaster?.category,
      taxCategory: taxCategory,
      assetClassLabel: assetClass,
      totalUnits: units,
      totalInvested: invested,
      currentValue: fundCurrentValue,
      gain: fundGain,
      gainPct: fundGainPct,
      cagr: cagr.isNaN ? null : cagr * 100,
      xirr: xirr.isNaN ? null : xirr * 100,
      latestNav: nav > 0 ? nav : null,
      nav1dChangePct: fundNav1dPct,
      todayGain: fundTodayGain,
      amfiCategoryId: firstTx.fundMaster?.amfiCategoryId,
      benchmarkTier1: firstTx.fundMaster?.benchmarkTier1,
      benchmarkTier2: firstTx.fundMaster?.benchmarkTier2,
      holderBreakdown: holderBreakdown,
      investedSince: oldestDate,
      planType: firstTx.fundMaster?.planType,
      expenseRatio: firstTx.fundMaster?.expenseRatio,
      return1y: firstTx.fundMaster?.return1y,
    ));
  }

  // ── Process groups with amfi_code (have market NAV) ─────────────────────
  for (final entry in fundGroups.entries) {
    processGroup(
      amfiCode: entry.key,
      groupTxs: entry.value,
      nav: navMap[entry.key] ?? 0.0,
      prevNav: prevNavMap[entry.key] ?? 0.0,
    );
  }

  // ── Process groups without amfi_code (use nav_at_tx as fallback) ────────
  for (final entry in nameGroups.entries) {
    final groupTxs = entry.value;
    final latestNav = groupTxs
        .where((t) => t.navAtTx != null && t.navAtTx! > 0)
        .fold<double>(0.0, (prev, t) {
      if (prev == 0.0) return t.navAtTx!;
      return t.parsedDate.isAfter(DateTime.tryParse(groupTxs.first.txDate) ?? DateTime.now())
          ? t.navAtTx!
          : prev;
    });
    processGroup(amfiCode: null, groupTxs: groupTxs, nav: latestNav, prevNav: 0.0);
  }

  // Sort by current value descending
  fundHoldings.sort((a, b) => b.currentValue.compareTo(a.currentValue));

  final totalGain = currentValue - totalInvested;
  final gainPct = totalInvested > 0 ? (totalGain / totalInvested) * 100 : 0.0;
  final todayGainPct = currentValue > 0 ? (todayGain / (currentValue - todayGain)) * 100 : 0.0;

  // Only include transactions for active holdings in portfolio XIRR & CAGR
  final activeAmfiCodes = fundHoldings.map((f) => f.amfiCode).where((c) => c != 0).toSet();
  final activeFundNames = fundHoldings.where((f) => f.amfiCode == 0).map((f) => f.fundName).toSet();

  final portfolioCashFlows = <CashFlow>[];
  DateTime? oldestActiveDate;
  for (final tx in txs) {
    final bool isActive;
    if (tx.amfiCode != null) {
      isActive = activeAmfiCodes.contains(tx.amfiCode);
    } else {
      isActive = activeFundNames.contains(tx.assetName ?? tx.fundMaster?.fundName ?? '');
    }
    if (!isActive) continue;

    portfolioCashFlows.add(CashFlow(
      amount: tx.isPurchase ? -tx.amount : tx.amount,
      date: tx.parsedDate,
    ));
    if (oldestActiveDate == null || tx.parsedDate.isBefore(oldestActiveDate)) {
      oldestActiveDate = tx.parsedDate;
    }
  }
  portfolioCashFlows.add(CashFlow(amount: currentValue, date: DateTime.now()));
  final overallXirr = XirrCalculator.compute(portfolioCashFlows);

  // Portfolio CAGR
  double? portfolioCagr;
  if (oldestActiveDate != null && totalInvested > 0 && currentValue > 0) {
    final days = DateTime.now().difference(oldestActiveDate).inDays;
    if (days > 0) {
      final c = CagrCalculator.fromHoldingDays(
        invested: totalInvested,
        currentValue: currentValue,
        holdingDays: days,
      );
      portfolioCagr = c.isNaN ? null : c * 100;
    }
  }

  // Allocation %
  final allocationPct = <String, double>{};
  if (currentValue > 0) {
    for (final e in allocationValue.entries) {
      allocationPct[e.key] = (e.value / currentValue) * 100;
    }
  }

  return PortfolioSummary(
    memberId: memberId,
    totalInvested: totalInvested,
    currentValue: currentValue,
    totalGain: totalGain,
    gainPct: gainPct,
    xirr: overallXirr.isNaN ? null : overallXirr * 100,
    cagr: portfolioCagr,
    todayGain: todayGain,
    todayGainPct: todayGainPct,
    allocationPct: allocationPct,
    allocationValue: allocationValue,
    fundHoldings: fundHoldings,
    asOfDate: DateTime.now(),
  );
}

String _taxCategoryToAssetClass(
  String taxCategory,
  String? category, {
  String? amfiCategoryId,
  Map<String, AmfiCategoryModel> catalog = const {},
}) {
  // Prefer SEBI category mapping when available
  if (amfiCategoryId != null && catalog.containsKey(amfiCategoryId)) {
    final ac = catalog[amfiCategoryId]!.defaultAssetClass;
    return _assetClassFromString(ac).displayName;
  }
  final cat = (category ?? '').toLowerCase();
  if (cat.contains('liquid') || cat.contains('money market') || cat.contains('overnight')) {
    return AssetClass.liquid.displayName;
  }
  switch (taxCategory.toLowerCase()) {
    case 'equity': return AssetClass.coreEquity.displayName;
    case 'hybrid-e': return AssetClass.hybrid.displayName;
    case 'hybrid-d': return AssetClass.hybrid.displayName;
    case 'debt': return AssetClass.debt.displayName;
    case 'gold': case 'gold etf': return AssetClass.gold.displayName;
    case 'international': return AssetClass.alternate.displayName;
    default: return AssetClass.alternate.displayName;
  }
}

AssetClass _assetClassFromString(String s) {
  switch (s) {
    case 'CoreEquity': return AssetClass.coreEquity;
    case 'SatelliteEquity': return AssetClass.satelliteEquity;
    case 'Hybrid': return AssetClass.hybrid;
    case 'Debt': return AssetClass.debt;
    case 'Liquid': return AssetClass.liquid;
    case 'Gold': return AssetClass.gold;
    default: return AssetClass.alternate;
  }
}
