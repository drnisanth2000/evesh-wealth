import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/folio_detail_model.dart';
import '../../data/models/transaction_model.dart';
import 'auth_provider.dart';
import 'portfolio_provider.dart';
import 'tax_provider.dart';

part 'reconciliation_provider.g.dart';

// ─── Folio Details provider ──────────────────────────────────────────────────
@riverpod
Future<List<FolioDetailModel>> folioDetails(FolioDetailsRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('folio_details')
      .select()
      .eq('owner_id', userId);

  return (response as List)
      .map((row) => FolioDetailModel.fromJson(row as Map<String, dynamic>))
      .toList();
}

// ─── Reconciliation result model ─────────────────────────────────────────────
class FolioReconciliation {
  const FolioReconciliation({
    required this.folioNumber,
    required this.schemeName,
    this.isin,
    this.memberId,
    required this.camsClosingUnits,
    required this.computedUnits,
    required this.camsMarketValue,
    this.computedMarketValue,
  });

  final String folioNumber;
  final String schemeName;
  final String? isin;
  final String? memberId;
  final double camsClosingUnits;
  final double computedUnits;
  final double camsMarketValue;
  final double? computedMarketValue;

  double get unitsDiff => computedUnits - camsClosingUnits;
  double get unitsDiffPct =>
      camsClosingUnits > 0 ? (unitsDiff / camsClosingUnits).abs() * 100 : 0;
  bool get isMatch => unitsDiffPct < 2.0; // within 2% tolerance
}

class ReconciliationSummary {
  const ReconciliationSummary({
    required this.items,
    required this.matchCount,
    required this.mismatchCount,
    required this.unmatchedFolios,
  });

  final List<FolioReconciliation> items;
  final int matchCount;
  final int mismatchCount;
  final List<FolioDetailModel> unmatchedFolios; // folios with no transactions

  bool get allMatch => mismatchCount == 0 && unmatchedFolios.isEmpty;
  int get totalChecked => matchCount + mismatchCount;
}

// ─── Post-import reconciliation provider ─────────────────────────────────────
// Compares computed holdings (from allTransactions) vs folio_details closing_units
@riverpod
Future<ReconciliationSummary> reconciliation(ReconciliationRef ref) async {
  final folios = await ref.watch(folioDetailsProvider.future);
  final txs = await ref.watch(allTransactionsProvider.future);

  if (folios.isEmpty) {
    return const ReconciliationSummary(
      items: [],
      matchCount: 0,
      mismatchCount: 0,
      unmatchedFolios: [],
    );
  }

  // Compute net units per (folio, isin) from transactions
  // A single folio can hold multiple schemes under one AMC
  final computedUnits = <String, double>{};
  for (final tx in txs) {
    final folio = tx.folioNumber;
    if (folio == null || folio.isEmpty) continue;
    final key = '$folio|${tx.isin ?? ''}';
    final txUnits = tx.units ??
        (tx.navAtTx != null && tx.navAtTx! > 0 ? tx.amount / tx.navAtTx! : 0.0);
    if (tx.isCashOnly) continue; // IDCW-Payout: no unit movement
    if (tx.isPurchase) {
      computedUnits[key] = (computedUnits[key] ?? 0) + txUnits;
    } else {
      computedUnits[key] = (computedUnits[key] ?? 0) - txUnits;
    }
  }

  final items = <FolioReconciliation>[];
  final unmatchedFolios = <FolioDetailModel>[];
  int matchCount = 0;
  int mismatchCount = 0;

  for (final folio in folios) {
    final key = '${folio.folioNumber}|${folio.isin ?? ''}';
    final computed = computedUnits[key];
    if (computed == null) {
      // No transactions found for this folio+isin
      if ((folio.closingUnits ?? 0) > 0.001) {
        unmatchedFolios.add(folio);
      }
      continue;
    }

    final recon = FolioReconciliation(
      folioNumber: folio.folioNumber,
      schemeName: folio.schemeName ?? 'Unknown',
      isin: folio.isin,
      memberId: folio.memberId,
      camsClosingUnits: folio.closingUnits ?? 0,
      computedUnits: computed,
      camsMarketValue: folio.marketValue ?? 0,
    );

    items.add(recon);
    if (recon.isMatch) {
      matchCount++;
    } else {
      mismatchCount++;
    }
  }

  // Sort: mismatches first, then by scheme name
  items.sort((a, b) {
    if (a.isMatch != b.isMatch) return a.isMatch ? 1 : -1;
    return a.schemeName.compareTo(b.schemeName);
  });

  return ReconciliationSummary(
    items: items,
    matchCount: matchCount,
    mismatchCount: mismatchCount,
    unmatchedFolios: unmatchedFolios,
  );
}

// ─── Phase 3A: Tax XLSX ↔ Transaction reconciliation ─────────────────────────
class TaxReconciliationResult {
  const TaxReconciliationResult({
    required this.missingSells,
    required this.phantomSells,
    required this.matchedCount,
  });

  final List<Map<String, dynamic>> missingSells; // in XLSX but not in eVesh
  final List<TransactionModel> phantomSells; // in eVesh but not in XLSX
  final int matchedCount;

  bool get allMatch => missingSells.isEmpty && phantomSells.isEmpty;
}

@riverpod
Future<TaxReconciliationResult?> taxReconciliation(
    TaxReconciliationRef ref) async {
  final camsStatement = await ref.watch(camsTaxStatementProvider.future);
  if (camsStatement == null) return null;

  final allTxs = await ref.watch(allTransactionsProvider.future);
  final fyKey = camsStatement.financialYear;
  final start = fyStart(fyKey);
  final end = fyEnd(fyKey);

  // Get sell transactions from eVesh in this FY
  final eveshSells = allTxs.where((tx) {
    if (tx.isPurchase) return false;
    final date = tx.parsedDate;
    return !date.isBefore(start) && !date.isAfter(end);
  }).toList();

  // Get transaction details from MFC XLSX
  final xlsxTxs = camsStatement.transactionDetails;
  if (xlsxTxs.isEmpty) {
    return TaxReconciliationResult(
      missingSells: const [],
      phantomSells: const [],
      matchedCount: 0,
    );
  }

  // Build a set of "date|amount" keys from eVesh sells for matching
  final eveshKeys = <String>{};
  for (final tx in eveshSells) {
    eveshKeys.add('${tx.txDate}|${tx.amount.toStringAsFixed(2)}');
  }

  // Check each XLSX transaction against eVesh
  final missingSells = <Map<String, dynamic>>[];
  int matchedCount = 0;
  for (final xlsxTx in xlsxTxs) {
    final date = xlsxTx['date'] as String? ?? '';
    final amount = (xlsxTx['amount'] as num?)?.toDouble() ?? 0;
    final key = '$date|${amount.toStringAsFixed(2)}';
    if (eveshKeys.contains(key)) {
      matchedCount++;
      eveshKeys.remove(key); // consume the match
    } else {
      missingSells.add(xlsxTx);
    }
  }

  // Remaining unmatched eVesh sells are "phantom"
  final phantomSells = eveshSells.where((tx) {
    final key = '${tx.txDate}|${tx.amount.toStringAsFixed(2)}';
    return eveshKeys.contains(key);
  }).toList();

  return TaxReconciliationResult(
    missingSells: missingSells,
    phantomSells: phantomSells,
    matchedCount: matchedCount,
  );
}

// ─── Phase 3B: Unrealized Exposure ↔ Portfolio consistency ───────────────────
class ExposurePortfolioCheck {
  const ExposurePortfolioCheck({
    required this.portfolioTotal,
    required this.exposureTotal,
    required this.deviationPct,
  });

  final double portfolioTotal;
  final double exposureTotal;
  final double deviationPct;

  bool get isConsistent => deviationPct.abs() < 5.0; // within 5%
}

@riverpod
Future<ExposurePortfolioCheck?> exposurePortfolioCheck(
    ExposurePortfolioCheckRef ref) async {
  final portfolio = await ref.watch(portfolioSummaryProvider(null).future);
  final exposure = await ref.watch(unrealizedExposureProvider.future);

  if (portfolio.currentValue <= 0 || exposure.exposures.isEmpty) return null;

  final exposureTotal =
      exposure.exposures.fold(0.0, (s, e) => s + e.currentValue);
  final deviationPct = portfolio.currentValue > 0
      ? ((exposureTotal - portfolio.currentValue) / portfolio.currentValue) * 100
      : 0.0;

  return ExposurePortfolioCheck(
    portfolioTotal: portfolio.currentValue,
    exposureTotal: exposureTotal,
    deviationPct: deviationPct,
  );
}
