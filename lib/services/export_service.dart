import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../data/models/folio_detail_model.dart';
import '../data/models/portfolio_summary_model.dart';

/// Generates and downloads a CSV file of the user's portfolio.
class ExportService {
  ExportService._();

  /// Export portfolio holdings as CSV and trigger browser download.
  ///
  /// [holdings] — the list of fund holdings to export
  /// [folios] — folio details for enriching with nominee/KYC/exit-load data
  /// [memberName] — label for file name ("All", "Nisanth", etc.)
  static void exportPortfolioCsv({
    required List<FundHoldingSummary> holdings,
    required List<FolioDetailModel> folios,
    required String memberName,
  }) {
    // Build a lookup: amfiCode/fundName → best folio detail
    // (a fund may have multiple folios; pick the first match)
    final folioByIsin = <String, FolioDetailModel>{};
    final folioByName = <String, FolioDetailModel>{};
    for (final f in folios) {
      if (f.isin != null && f.isin!.isNotEmpty) {
        folioByIsin.putIfAbsent(f.isin!, () => f);
      }
      if (f.schemeName != null) {
        folioByName.putIfAbsent(f.schemeName!.toLowerCase(), () => f);
      }
    }

    FolioDetailModel? _findFolio(FundHoldingSummary h) {
      // Try ISIN from holder breakdown first
      for (final hb in h.holderBreakdown) {
        if (hb.folioNumber != null) {
          final match = folios.where((f) => f.folioNumber == hb.folioNumber).firstOrNull;
          if (match != null) return match;
        }
      }
      // Fallback: match by fund name
      return folioByName[h.fundName.toLowerCase()];
    }

    // CSV header
    final headers = [
      'Fund Name',
      'ISIN',
      'Folio Number',
      'AMC',
      'Category',
      'Tax Category',
      'Plan Type',
      'Units',
      'Invested (₹)',
      'Current Value (₹)',
      'Gain/Loss (₹)',
      'Gain %',
      'XIRR %',
      'CAGR %',
      'Latest NAV',
      "Today's Change (₹)",
      'NAV 1D Change %',
      'Invested Since',
      'Holding Period',
      'Expense Ratio %',
      '1Y Return %',
      'Exit Load',
      'Exit Load Days',
      'Exit Load %',
      'Nominee 1',
      'Nominee 2',
      'Nominee 3',
      'KYC Status',
      'Registrar',
      'Demat Status',
      // Per-holder breakdown
      'Holders',
    ];

    final rows = <List<String>>[];

    for (final h in holdings) {
      final folio = _findFolio(h);

      // Build holder breakdown string
      final holderStr = h.holderBreakdown
          .map((hb) =>
              '${hb.memberName}: ${hb.units.toStringAsFixed(3)} units / '
              '₹${hb.currentValue.toStringAsFixed(0)} '
              '(XIRR ${hb.xirr?.toStringAsFixed(1) ?? "N/A"}%)')
          .join(' | ');

      rows.add([
        _esc(h.fundName),
        _esc(folio?.isin ?? ''),
        _esc(folio?.folioNumber ?? h.holderBreakdown.firstOrNull?.folioNumber ?? ''),
        _esc(folio?.amcName ?? ''),
        _esc(h.category ?? ''),
        _esc(h.taxCategory ?? ''),
        _esc(h.planType ?? ''),
        h.totalUnits.toStringAsFixed(3),
        h.totalInvested.toStringAsFixed(2),
        h.currentValue.toStringAsFixed(2),
        h.gain.toStringAsFixed(2),
        h.gainPct.toStringAsFixed(2),
        h.xirr != null ? h.xirr!.toStringAsFixed(2) : '',
        h.cagr != null ? h.cagr!.toStringAsFixed(2) : '',
        h.latestNav?.toStringAsFixed(4) ?? '',
        h.todayGain.toStringAsFixed(2),
        h.nav1dChangePct?.toStringAsFixed(2) ?? '',
        h.investedSince?.toIso8601String().split('T').first ?? '',
        h.holdingPeriodFormatted ?? '',
        h.expenseRatio?.toStringAsFixed(2) ?? '',
        h.return1y?.toStringAsFixed(2) ?? '',
        _esc(folio?.exitLoadText ?? ''),
        folio?.exitLoadDays?.toString() ?? '',
        folio?.exitLoadPct?.toStringAsFixed(4) ?? '',
        _esc(folio?.nominee1 ?? ''),
        _esc(folio?.nominee2 ?? ''),
        _esc(folio?.nominee3 ?? ''),
        _esc(folio?.kycStatus ?? ''),
        _esc(folio?.registrar ?? ''),
        _esc(folio?.dematStatus ?? ''),
        _esc(holderStr),
      ]);
    }

    // Build CSV string
    final buffer = StringBuffer();
    buffer.writeln(headers.join(','));
    for (final row in rows) {
      buffer.writeln(row.join(','));
    }

    // Trigger browser download
    final csvContent = buffer.toString();
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final safeLabel = memberName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final date = DateTime.now().toIso8601String().split('T').first;
    final fileName = 'eVesh_Portfolio_${safeLabel}_$date.csv';

    // ignore: unused_local_variable
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  /// Escape a CSV field (quote if it contains comma, newline, or quote).
  static String _esc(String value) {
    if (value.contains(',') || value.contains('\n') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
