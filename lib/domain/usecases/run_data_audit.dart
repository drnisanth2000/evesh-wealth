import '../../data/models/folio_detail_model.dart';
import '../../data/models/transaction_model.dart';
import 'run_fifo_tax_calculator.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

enum AuditSeverity { pass, warning, error }

class AuditIssue {
  const AuditIssue({
    required this.title,
    required this.detail,
    this.remedy,
    this.data,
  });

  final String title;
  final String detail;
  final String? remedy;
  final Map<String, dynamic>? data;
}

class AuditCheckResult {
  const AuditCheckResult({
    required this.checkName,
    required this.description,
    required this.severity,
    required this.itemsChecked,
    required this.issuesFound,
    this.issues = const [],
  });

  final String checkName;
  final String description;
  final AuditSeverity severity;
  final int itemsChecked;
  final int issuesFound;
  final List<AuditIssue> issues;
}

class DataAuditReport {
  const DataAuditReport({
    required this.runAt,
    required this.checks,
  });

  final DateTime runAt;
  final List<AuditCheckResult> checks;

  int get totalIssues => checks.fold(0, (s, c) => s + c.issuesFound);
  int get errorCount =>
      checks.where((c) => c.severity == AuditSeverity.error).length;
  int get warningCount =>
      checks.where((c) => c.severity == AuditSeverity.warning).length;
  bool get allPassed =>
      checks.every((c) => c.severity == AuditSeverity.pass);
}

// ─── Known transaction type sets ──────────────────────────────────────────────

const _purchaseTypes = {
  'BUY', 'SIP', 'Switch-In', 'STX-BUY', 'STP-In', 'Bonus', 'IDCW',
  'IDCW-Reinvest', 'Transfer-In', 'Opening Balance',
};
const _sellTypes = {
  'SELL', 'Switch-Out', 'STP-Out', 'SWP', 'STX-SELL', 'Transfer-Out',
};
const _cashOnlyTypes = {'IDCW-Payout'};

// ─── Check 1: Cross-source duplicate transactions ─────────────────────────────

AuditCheckResult checkCrossSourceDuplicates(List<TransactionModel> txs) {
  // Group by (isin ?? amfiCode, date, amount, txType, folio) ignoring source
  final groups = <String, List<TransactionModel>>{};
  for (final tx in txs) {
    final fundKey = tx.isin ?? tx.amfiCode?.toString() ?? tx.assetName ?? '';
    final key = '$fundKey|${tx.txDate}|${tx.amount.toStringAsFixed(2)}|${tx.txType}|${tx.folioNumber ?? ''}';
    (groups[key] ??= []).add(tx);
  }

  final issues = <AuditIssue>[];
  for (final entry in groups.entries) {
    final group = entry.value;
    if (group.length <= 1) continue;
    final sources = group.map((t) => t.importSource).toSet();
    if (sources.length > 1) {
      final tx = group.first;
      issues.add(AuditIssue(
        title: '${tx.assetName ?? tx.isin ?? 'Unknown'} on ${tx.txDate}',
        detail: '${group.length} records from sources: ${sources.join(', ')}. Amount: ${tx.amount}',
        remedy: 'Run data wipe and re-import from single CAS source',
        data: {'key': entry.key, 'count': group.length, 'sources': sources.toList()},
      ));
    }
  }

  return AuditCheckResult(
    checkName: 'Cross-Source Duplicates',
    description: 'Same transaction from different import sources',
    severity: issues.isEmpty ? AuditSeverity.pass : AuditSeverity.error,
    itemsChecked: groups.length,
    issuesFound: issues.length,
    issues: issues,
  );
}

// ─── Check 2: Orphaned folios ─────────────────────────────────────────────────

AuditCheckResult checkOrphanedFolios(
  List<FolioDetailModel> folios,
  List<TransactionModel> txs, {
  Map<String, String> memberNames = const {},
}) {
  final txFolios = txs.map((t) => t.folioNumber).whereType<String>().toSet();
  final issues = <AuditIssue>[];

  for (final f in folios) {
    if ((f.closingUnits ?? 0) < 0.01) continue; // skip zero-unit folios
    if (!txFolios.contains(f.folioNumber)) {
      final memberLabel = memberNames[f.memberId ?? ''] ?? '';
      issues.add(AuditIssue(
        title: '${f.schemeName ?? f.folioNumber}${memberLabel.isNotEmpty ? ' ($memberLabel)' : ''}',
        detail: 'Folio ${f.folioNumber} has ${f.closingUnits?.toStringAsFixed(3)} units but no transactions',
        remedy: 'Re-import CAS PDF with full date range to capture historical transactions',
      ));
    }
  }

  return AuditCheckResult(
    checkName: 'Orphaned Folios',
    description: 'Folio records with holdings but no matching transactions',
    severity: issues.isEmpty ? AuditSeverity.pass : AuditSeverity.warning,
    itemsChecked: folios.where((f) => (f.closingUnits ?? 0) > 0.01).length,
    issuesFound: issues.length,
    issues: issues,
  );
}

// ─── Check 3: Unit balance mismatch ───────────────────────────────────────────

AuditCheckResult checkUnitBalanceMismatches(
  List<FolioDetailModel> folios,
  List<TransactionModel> txs, {
  Map<String, String> memberNames = const {},
}) {
  // Compute units per (folio, isin) — a single folio can hold multiple schemes
  final computedUnits = <String, double>{};
  for (final tx in txs) {
    final folio = tx.folioNumber;
    if (folio == null || folio.isEmpty) continue;
    final key = '${folio}|${tx.isin ?? ''}';
    final units = tx.units ?? (tx.navAtTx != null && tx.navAtTx! > 0
        ? tx.amount / tx.navAtTx!
        : 0.0);
    computedUnits[key] = (computedUnits[key] ?? 0) +
        (tx.isPurchase ? units : -units);
  }

  final issues = <AuditIssue>[];
  int checked = 0;

  for (final f in folios) {
    final camsUnits = f.closingUnits ?? 0;
    if (camsUnits.abs() < 0.01) continue;
    checked++;

    final key = '${f.folioNumber}|${f.isin ?? ''}';
    final computed = computedUnits[key] ?? 0;
    final diff = computed - camsUnits;
    final pct = camsUnits != 0 ? (diff / camsUnits * 100).abs() : 0.0;

    if (pct > 2.0) {
      final memberLabel = memberNames[f.memberId ?? ''] ?? '';
      issues.add(AuditIssue(
        title: '${f.schemeName ?? f.folioNumber}${memberLabel.isNotEmpty ? ' ($memberLabel)' : ''}',
        detail: 'CAMS: ${camsUnits.toStringAsFixed(3)}, Computed: ${computed.toStringAsFixed(3)}, Diff: ${diff.toStringAsFixed(3)} (${pct.toStringAsFixed(1)}%)',
        remedy: pct > 20
            ? 'Large mismatch — likely missing transactions. Re-import CAS with full date range.'
            : 'Minor mismatch — may be rounding. Check for partial transactions.',
        data: {'folio': f.folioNumber, 'cams': camsUnits, 'computed': computed, 'diffPct': pct},
      ));
    }
  }

  return AuditCheckResult(
    checkName: 'Unit Balance Mismatch',
    description: 'Computed units vs CAMS registrar closing units (>2% tolerance)',
    severity: issues.isEmpty ? AuditSeverity.pass : AuditSeverity.error,
    itemsChecked: checked,
    issuesFound: issues.length,
    issues: issues,
  );
}

// ─── Check 4: CAMS tax vs FIFO gain reconciliation ───────────────────────────

AuditCheckResult checkCamsFifoReconciliation({
  required double camsEqStcg,
  required double camsEqLtcg,
  required double camsNeStcg,
  required double camsNeLtcg,
  required double fifoEqStcg,
  required double fifoEqLtcg,
  required double fifoNeStcg,
  required double fifoNeLtcg,
  required bool hasCamsData,
}) {
  if (!hasCamsData) {
    return const AuditCheckResult(
      checkName: 'CAMS Tax Reconciliation',
      description: 'Compare CAMS tax statement vs eVesh FIFO gains',
      severity: AuditSeverity.pass,
      itemsChecked: 0,
      issuesFound: 0,
      issues: [AuditIssue(title: 'Skipped', detail: 'No CAMS tax statement uploaded')],
    );
  }

  final issues = <AuditIssue>[];
  void _check(String label, double cams, double fifo) {
    final diff = (fifo - cams).abs();
    final pct = cams != 0 ? diff / cams.abs() * 100 : (fifo != 0 ? 100 : 0);
    if (diff > 1000 && pct > 10) {
      issues.add(AuditIssue(
        title: '$label differs by Rs ${diff.toStringAsFixed(0)}',
        detail: 'CAMS: Rs ${cams.toStringAsFixed(0)}, eVesh: Rs ${fifo.toStringAsFixed(0)} (${pct.toStringAsFixed(1)}%)',
        remedy: 'Check per-fund comparison card for fund-level differences',
      ));
    }
  }

  _check('Equity STCG', camsEqStcg, fifoEqStcg);
  _check('Equity LTCG', camsEqLtcg, fifoEqLtcg);
  _check('Non-Equity STCG', camsNeStcg, fifoNeStcg);
  _check('Non-Equity LTCG', camsNeLtcg, fifoNeLtcg);

  final totalCams = camsEqStcg + camsEqLtcg + camsNeStcg + camsNeLtcg;
  final totalFifo = fifoEqStcg + fifoEqLtcg + fifoNeStcg + fifoNeLtcg;
  _check('Total Gain', totalCams, totalFifo);

  return AuditCheckResult(
    checkName: 'CAMS Tax Reconciliation',
    description: 'Compare CAMS tax statement vs eVesh FIFO gains',
    severity: issues.isEmpty ? AuditSeverity.pass : AuditSeverity.warning,
    itemsChecked: 5,
    issuesFound: issues.length,
    issues: issues,
  );
}

// ─── Check 5: Missing AMFI code mappings ──────────────────────────────────────

AuditCheckResult checkMissingAmfiMappings(List<TransactionModel> txs) {
  final mfTxs = txs.where((t) => t.assetType == 'MF').toList();
  final missing = mfTxs.where((t) => t.amfiCode == null).toList();

  final byIsin = <String, int>{};
  for (final tx in missing) {
    final key = tx.isin ?? tx.assetName ?? 'Unknown';
    byIsin[key] = (byIsin[key] ?? 0) + 1;
  }

  final issues = byIsin.entries.map((e) => AuditIssue(
    title: e.key,
    detail: '${e.value} transactions without AMFI code mapping',
    remedy: 'These transactions cannot participate in FIFO or NAV lookups. Check fund_master for ISIN match.',
  )).toList();

  return AuditCheckResult(
    checkName: 'Missing AMFI Mappings',
    description: 'MF transactions without amfi_code (cannot compute tax)',
    severity: issues.isEmpty ? AuditSeverity.pass : AuditSeverity.warning,
    itemsChecked: mfTxs.length,
    issuesFound: missing.length,
    issues: issues,
  );
}

// ─── Check 6: Unmatched sell units ────────────────────────────────────────────

AuditCheckResult checkUnmatchedSellUnits(
  List<FundTaxBreakdown> fundBreakdowns, {
  Map<String, String> memberNames = const {},
  List<TransactionModel> allTxs = const [],
}) {
  final issues = <AuditIssue>[];
  int totalFunds = 0;

  for (final f in fundBreakdowns) {
    if (f.sellCount == 0) continue;
    totalFunds++;
    if (f.unmatchedSellUnits > 0.01) {
      final memberLabel = memberNames[f.memberId] ?? '';

      // Diagnostic: find all transactions for this fund's folios to understand the gap
      String diagnostic = '';
      if (allTxs.isNotEmpty) {
        // Get folios that have this amfiCode
        final fundTxs = allTxs.where((t) => t.amfiCode == f.amfiCode && t.memberId == f.memberId).toList();
        final folios = fundTxs.map((t) => t.folioNumber).whereType<String>().toSet();
        // Check all amfiCodes in those folios
        final folioTxs = allTxs.where((t) => folios.contains(t.folioNumber) && t.memberId == f.memberId).toList();
        final amfiCodes = folioTxs.map((t) => t.amfiCode).whereType<int>().toSet();
        if (amfiCodes.length > 1) {
          final otherCodes = amfiCodes.where((c) => c != f.amfiCode).toList();
          final otherBuys = folioTxs.where((t) => otherCodes.contains(t.amfiCode) && t.isPurchase).length;
          final otherBuyUnits = folioTxs.where((t) => otherCodes.contains(t.amfiCode) && t.isPurchase)
              .fold(0.0, (s, t) => s + (t.units ?? 0));
          diagnostic = ' | Same folio has ${amfiCodes.length} amfi_codes: $amfiCodes — $otherBuys buys (${otherBuyUnits.toStringAsFixed(1)} units) under other codes';
        }
      }

      issues.add(AuditIssue(
        title: '${f.fundName}${memberLabel.isNotEmpty ? ' ($memberLabel)' : ''}',
        detail: '${f.unmatchedSellUnits.toStringAsFixed(3)} units sold but not matched to any buy lot '
            '(${f.buyLotCount} buy lots with ${f.totalBuyUnits.toStringAsFixed(3)} total units)$diagnostic',
        remedy: 'Missing historical buy data. Re-import CAS with earlier start date.',
        data: {'amfiCode': f.amfiCode, 'unmatched': f.unmatchedSellUnits, 'memberId': f.memberId,
               'buyLotCount': f.buyLotCount, 'totalBuyUnits': f.totalBuyUnits},
      ));
    }
  }

  return AuditCheckResult(
    checkName: 'Unmatched Sell Units',
    description: 'Sell transactions without enough buy lots for FIFO matching',
    severity: issues.isEmpty ? AuditSeverity.pass : AuditSeverity.error,
    itemsChecked: totalFunds,
    issuesFound: issues.length,
    issues: issues,
  );
}

// ─── Check 7: Transaction type safety ─────────────────────────────────────────

AuditCheckResult checkTransactionTypeSafety(List<TransactionModel> txs) {
  final allKnown = {..._purchaseTypes, ..._sellTypes};
  final unknown = txs.where((t) => !allKnown.contains(t.txType)).toList();

  final byType = <String, int>{};
  for (final tx in unknown) {
    byType[tx.txType] = (byType[tx.txType] ?? 0) + 1;
  }

  final issues = byType.entries.map((e) => AuditIssue(
    title: 'Type: "${e.key}"',
    detail: '${e.value} transactions with unrecognized type — ignored in FIFO and portfolio',
    remedy: 'Verify if these should be classified as buy or sell. Add to explicit type sets if needed.',
  )).toList();

  return AuditCheckResult(
    checkName: 'Transaction Type Safety',
    description: 'Transactions with types not in known BUY or SELL sets',
    severity: issues.isEmpty ? AuditSeverity.pass : AuditSeverity.warning,
    itemsChecked: txs.length,
    issuesFound: unknown.length,
    issues: issues,
  );
}

// ─── Check 8: Folio-transaction ISIN consistency ──────────────────────────────

AuditCheckResult checkFolioIsinConsistency(
  List<FolioDetailModel> folios,
  List<TransactionModel> txs, {
  Map<String, String> memberNames = const {},
}) {
  // Build folio → ISINs from transactions
  final txIsinsByFolio = <String, Set<String>>{};
  for (final tx in txs) {
    if (tx.folioNumber == null || tx.isin == null) continue;
    (txIsinsByFolio[tx.folioNumber!] ??= {}).add(tx.isin!);
  }

  final issues = <AuditIssue>[];
  int checked = 0;

  for (final f in folios) {
    if (f.isin == null || f.isin!.isEmpty) continue;
    checked++;
    final txIsins = txIsinsByFolio[f.folioNumber];
    if (txIsins == null) continue; // orphaned folio — caught by check 2
    if (!txIsins.contains(f.isin)) {
      final memberLabel = memberNames[f.memberId ?? ''] ?? '';
      issues.add(AuditIssue(
        title: 'Folio ${f.folioNumber}${memberLabel.isNotEmpty ? ' ($memberLabel)' : ''}',
        detail: 'Folio ISIN: ${f.isin}, Transaction ISINs: ${txIsins.join(', ')}',
        remedy: 'ISIN mismatch may indicate fund merger or migration. Verify in CAMS statement.',
      ));
    }
  }

  return AuditCheckResult(
    checkName: 'Folio ISIN Consistency',
    description: 'Folio ISIN matches transaction ISIN for the same folio number',
    severity: issues.isEmpty ? AuditSeverity.pass : AuditSeverity.warning,
    itemsChecked: checked,
    issuesFound: issues.length,
    issues: issues,
  );
}
