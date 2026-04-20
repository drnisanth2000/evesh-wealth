import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/usecases/run_data_audit.dart';
import 'alert_provider.dart';
import 'auth_provider.dart';
import 'family_provider.dart';
import 'portfolio_provider.dart';
import 'reconciliation_provider.dart';
import 'rebalance_provider.dart';
import 'tax_provider.dart';

part 'data_audit_provider.g.dart';

// ─── Data Audit Provider ──────────────────────────────────────────────────────

@riverpod
Future<DataAuditReport> dataAudit(DataAuditRef ref) async {
  final allTxs = await ref.watch(allTransactionsProvider.future);
  final folios = await ref.watch(folioDetailsProvider.future);

  // Tax data (may not be available)
  FifoTaxResult? taxResult;
  CamsTaxStatement? camsData;
  try {
    taxResult = await ref.watch(taxCalculationProvider.future);
  } catch (_) {}
  try {
    camsData = await ref.watch(camsTaxStatementProvider.future);
  } catch (_) {}

  // Build memberId → displayName map for issue labels
  final members = ref.watch(familyMembersProvider).valueOrNull ?? [];
  final memberNames = {for (final m in members) m.id: m.displayName};

  final checks = <AuditCheckResult>[];

  // Check 1: Cross-source duplicates
  checks.add(checkCrossSourceDuplicates(allTxs));

  // Check 2: Orphaned folios
  checks.add(checkOrphanedFolios(folios, allTxs, memberNames: memberNames));

  // Check 3: Unit balance mismatches
  checks.add(checkUnitBalanceMismatches(folios, allTxs, memberNames: memberNames));

  // Check 4: CAMS tax vs FIFO reconciliation
  // Use per-lot transaction_details (accurate) instead of XLSX summary sheets
  // (which can have column-mapping errors, e.g. inflated LTCG in SCHEMEWISE)
  if (taxResult != null) {
    final summaries = taxResult.memberSummaries;
    double fifoEqStcg = 0, fifoEqLtcg = 0, fifoNeStcg = 0, fifoNeLtcg = 0;
    for (final m in summaries) {
      fifoEqStcg += m.equityStcgGain - m.equityStcgLoss;
      fifoEqLtcg += m.equityLtcgGain - m.equityLtcgLoss;
      fifoNeStcg += (m.goldStcgGain - m.goldStcgLoss) + (m.debtSlabGain - m.debtSlabLoss);
      fifoNeLtcg += m.goldLtcgGain - m.goldLtcgLoss;
    }

    // Use per-lot gains (accurate) over XLSX summary (can have column errors)
    final camsGains = camsData?.perLotGains;

    checks.add(checkCamsFifoReconciliation(
      camsEqStcg: camsGains?.eqStcg ?? 0,
      camsEqLtcg: camsGains?.eqLtcg ?? 0,
      camsNeStcg: camsGains?.neStcg ?? 0,
      camsNeLtcg: camsGains?.neLtcg ?? 0,
      fifoEqStcg: fifoEqStcg,
      fifoEqLtcg: fifoEqLtcg,
      fifoNeStcg: fifoNeStcg,
      fifoNeLtcg: fifoNeLtcg,
      hasCamsData: camsData != null,
    ));
  }

  // Check 5: Missing AMFI mappings
  checks.add(checkMissingAmfiMappings(allTxs));

  // Check 6: Unmatched sell units
  if (taxResult != null) {
    final allFundBreakdowns = taxResult.memberSummaries
        .expand((m) => m.fundBreakdowns)
        .toList();
    checks.add(checkUnmatchedSellUnits(allFundBreakdowns, memberNames: memberNames, allTxs: allTxs));
  }

  // Check 7: Transaction type safety
  checks.add(checkTransactionTypeSafety(allTxs));

  // Check 8: Folio ISIN consistency
  checks.add(checkFolioIsinConsistency(folios, allTxs, memberNames: memberNames));

  return DataAuditReport(runAt: DateTime.now(), checks: checks);
}

// ─── Data Wipe Provider ───────────────────────────────────────────────────────

@riverpod
Future<Map<String, int>> dataWipePreview(DataWipePreviewRef ref) async {
  final allTxs = await ref.watch(allTransactionsProvider.future);
  final folios = await ref.watch(folioDetailsProvider.future);
  CamsTaxStatement? cams;
  try { cams = await ref.watch(camsTaxStatementProvider.future); } catch (_) {}

  // Count additional tables via Supabase
  final userId = ref.watch(currentUserIdProvider);
  final client = ref.watch(supabaseClientProvider);
  int importBatches = 0, alerts = 0, otherAssets = 0, goals = 0, dupFamilies = 0;
  if (userId != null) {
    try {
      final ib = await client.from('import_batches').select('id').eq('owner_id', userId);
      importBatches = (ib as List).length;
    } catch (_) {}
    try {
      final al = await client.from('alert_log').select('id').eq('owner_id', userId);
      alerts = (al as List).length;
    } catch (_) {}
    try {
      final oa = await client.from('other_assets').select('id').eq('owner_id', userId);
      otherAssets = (oa as List).length;
    } catch (_) {}
    try {
      final gl = await client.from('goals').select('id').eq('owner_id', userId);
      goals = (gl as List).length;
    } catch (_) {}
    try {
      final fam = await client.from('families').select('id').eq('owner_id', userId);
      final famCount = (fam as List).length;
      if (famCount > 1) dupFamilies = famCount - 1;
    } catch (_) {}
  }

  return {
    'transactions': allTxs.length,
    'folio_details': folios.length,
    'cams_tax_statements': cams != null ? 1 : 0,
    if (importBatches > 0) 'import_batches': importBatches,
    if (alerts > 0) 'alert_log': alerts,
    if (otherAssets > 0) 'other_assets': otherAssets,
    if (goals > 0) 'goals': goals,
    if (dupFamilies > 0) 'duplicate_families': dupFamilies,
  };
}

@riverpod
class DataWipeNotifier extends _$DataWipeNotifier {
  @override
  AsyncValue<Map<String, int>?> build() => const AsyncData(null);

  Future<Map<String, int>> execute() async {
    state = const AsyncLoading();
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Not authenticated');

      final client = ref.read(supabaseClientProvider);
      final deleted = <String, int>{};

      // Delete in dependency order (children before parents)

      // 1. Tax statements
      await client.from('cams_tax_statements').delete().eq('owner_id', userId);
      deleted['cams_tax_statements'] = 1;

      // 2. Transactions (all import sources)
      await client.from('transactions').delete().eq('owner_id', userId);
      deleted['transactions'] = 1;

      // 3. Folio details
      await client.from('folio_details').delete().eq('owner_id', userId);
      deleted['folio_details'] = 1;

      // 4. Import batches
      try {
        await client.from('import_batches').delete().eq('owner_id', userId);
        deleted['import_batches'] = 1;
      } catch (_) {} // table may not exist

      // 5. Alert log
      try {
        await client.from('alert_log').delete().eq('owner_id', userId);
        deleted['alert_log'] = 1;
      } catch (_) {}

      // 6. Other assets (stocks, SGBs, FDs)
      try {
        await client.from('other_assets').delete().eq('owner_id', userId);
        deleted['other_assets'] = 1;
      } catch (_) {}

      // 7. Goals
      try {
        await client.from('goals').delete().eq('owner_id', userId);
        deleted['goals'] = 1;
      } catch (_) {}

      // 8. Deduplicate families — keep only the oldest, delete the rest
      try {
        final families = await client
            .from('families')
            .select('id')
            .eq('owner_id', userId)
            .order('created_at');
        final familyRows = families as List;
        if (familyRows.length > 1) {
          // Keep first (oldest), delete the rest
          final idsToDelete =
              familyRows.skip(1).map((r) => r['id'] as String).toList();
          // Reassign orphaned family_members to the canonical family
          final keepId = familyRows.first['id'] as String;
          await client
              .from('family_members')
              .update({'family_id': keepId})
              .eq('owner_id', userId)
              .inFilter('family_id', idsToDelete);
          // Delete duplicate families
          await client
              .from('families')
              .delete()
              .inFilter('id', idsToDelete);
          deleted['duplicate_families_removed'] = idsToDelete.length;
        }
      } catch (_) {}

      // Invalidate ALL dependent providers
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(folioDetailsProvider);
      ref.invalidate(camsTaxStatementProvider);
      ref.invalidate(taxCalculationProvider);
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(dataAuditProvider);
      ref.invalidate(dataWipePreviewProvider);
      ref.invalidate(alertsProvider);
      ref.invalidate(familyProvider);
      ref.invalidate(familyMembersProvider);
      ref.invalidate(rebalanceAnalysisProvider);
      ref.invalidate(latestNavMapProvider);
      ref.invalidate(reconciliationProvider);
      ref.invalidate(unrealizedExposureProvider);
      ref.invalidate(taxHarvestOpportunitiesProvider);

      state = AsyncData(deleted);
      return deleted;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
