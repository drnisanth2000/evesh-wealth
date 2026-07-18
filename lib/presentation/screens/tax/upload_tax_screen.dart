import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/family_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/tax_provider.dart';
import '../../router/route_names.dart';

/// Heuristic: returns true if scheme name suggests a non-equity fund.
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

// ─── Data extracted from XLSX metadata rows ─────────────────────────────────
class _XlsxMemberInfo {
  String? pan;
  String? name;
  String? email;
  String? mobile;
  String? panCellRef;

  @override
  String toString() =>
      'PAN=$pan ($panCellRef), Name=$name, Email=$email, Mobile=$mobile';
}

class UploadTaxScreen extends ConsumerStatefulWidget {
  const UploadTaxScreen({super.key});

  @override
  ConsumerState<UploadTaxScreen> createState() => _UploadTaxScreenState();
}

class _UploadTaxScreenState extends ConsumerState<UploadTaxScreen> {
  _UploadState _state = _UploadState.idle;
  String? _fileName;
  Uint8List? _fileBytes;
  String? _error;

  // Tax file type detection
  bool _isCAMSTaxXls = false;
  bool _isMFCTaxXlsx = false;
  bool _isAisPdf = false;
  _CamsTaxData? _camsTaxResult;
  Map<String, dynamic>? _aisResult;

  // AIS password
  final _passwordCtrl = TextEditingController();

  // Auto-match state
  _XlsxMemberInfo? _xlsxInfo;
  FamilyMemberModel? _matchedMember;
  bool _panDetectionDone = false;

  // New member form state
  bool _showNewMemberForm = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  String _relationship = 'Other';
  bool _savingMember = false;

  static final _panRegex = RegExp(r'[A-Z]{5}[0-9]{4}[A-Z]');

  static const _relationships = [
    'Self', 'Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'HUF', 'Other',
  ];
  static const _uniqueRelationships = {'Self', 'Spouse'};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Find sheet by case-insensitive name, with underscore/space normalization
  xl.Sheet? _findSheet(xl.Excel excel, String name) {
    // Exact match
    if (excel.tables.containsKey(name)) return excel.tables[name];
    // Case-insensitive match
    final nameLower = name.toLowerCase();
    for (final key in excel.tables.keys) {
      if (key.toLowerCase() == nameLower) return excel.tables[key];
    }
    // Normalized match: ignore underscores vs spaces, strip whitespace
    final nameNorm = nameLower.replaceAll(RegExp(r'[\s_]+'), '');
    for (final key in excel.tables.keys) {
      final keyNorm = key.toLowerCase().replaceAll(RegExp(r'[\s_]+'), '');
      if (keyNorm == nameNorm) return excel.tables[key];
    }
    return null;
  }

  static const int _maxUploadBytes = 20 * 1024 * 1024; // 20 MB

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;

    if (bytes != null && bytes.length > _maxUploadBytes) {
      setState(() {
        _state = _UploadState.error;
        _error = 'File too large (max 20 MB). Selected: '
            '${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB';
      });
      return;
    }

    setState(() {
      _fileName = file.name;
      _fileBytes = bytes;
      _state = _UploadState.picked;
      _error = null;
      _xlsxInfo = null;
      _matchedMember = null;
      _panDetectionDone = false;
      _showNewMemberForm = false;
      _isCAMSTaxXls = false;
      _isMFCTaxXlsx = false;
      _isAisPdf = false;
      _camsTaxResult = null;
      _aisResult = null;
    });

    if (bytes == null) return;

    // ── AIS PDF detection ──
    if (file.name.toLowerCase().endsWith('.pdf')) {
      debugPrint('TAX-DETECT: AIS PDF');
      setState(() {
        _isAisPdf = true;
        _panDetectionDone = false;
      });
      // Auto-suggest password from matched member's PAN + DOB
      _suggestAisPassword();
      return;
    }

    xl.Excel? excel;
    try {
      excel = xl.Excel.decodeBytes(bytes);
    } catch (e) {
      debugPrint('Excel decode error: $e');
    }

    // .xls format not supported on web
    if (excel == null && file.name.toLowerCase().endsWith('.xls')) {
      setState(() {
        _state = _UploadState.error;
        _error = '.xls format is not supported in the browser.\n\n'
            'Use one of these alternatives:\n'
            '• Download MF Central Capital Gains Tax (.xlsx) — covers all AMCs\n'
            '• Open this .xls in Excel/Numbers → Save As .xlsx';
        _panDetectionDone = true;
      });
      return;
    }

    if (excel == null) {
      setState(() {
        _state = _UploadState.error;
        _error = 'Could not read file. Please check format.';
        _panDetectionDone = true;
      });
      return;
    }

    final sheets = excel.tables.keys.toSet();
    final sheetsLower = sheets.map((s) => s.toLowerCase()).toSet();
    debugPrint('TAX-DETECT: Sheets: $sheets');

    // CAMS Tax XLS — has INVESTOR_DETAILS + TRXN_DETAILS
    if (sheetsLower.contains('investor_details') &&
        sheetsLower.contains('trxn_details')) {
      debugPrint('TAX-DETECT: CAMS Tax XLS');
      setState(() => _isCAMSTaxXls = true);
      _detectCamsTaxMember(excel);
      return;
    }

    // MF Central Tax XLSX — has Summary + TransactionDetails + Scheme_Level_Summary
    if (sheetsLower.contains('summary') &&
        sheetsLower.contains('transactiondetails') &&
        sheetsLower.contains('scheme_level_summary')) {
      debugPrint('TAX-DETECT: MFC Tax XLSX');
      setState(() => _isMFCTaxXlsx = true);
      _detectMfcTaxMember(excel);
      return;
    }

    // Not a tax file
    setState(() {
      _state = _UploadState.error;
      _error = 'This file does not appear to be a tax statement.\n\n'
          'Expected formats:\n'
          '• CAMS Capital Gains (.xls/.xlsx) — download from camsonline.com\n'
          '• MF Central Capital Gains (.xlsx) — download from mfcentral.com';
      _panDetectionDone = true;
    });
  }

  /// Detect PAN from CAMS Tax XLS and match to a member
  void _detectCamsTaxMember(xl.Excel excel) {
    final info = _XlsxMemberInfo();
    final invSheet = _findSheet(excel, 'INVESTOR_DETAILS');
    if (invSheet != null && invSheet.maxRows > 4) {
      final headerRow = invSheet.row(3);
      final dataRow = invSheet.row(4);
      final headers = <String>[];
      for (final cell in headerRow) {
        headers.add((cell?.value?.toString().trim() ?? '').toUpperCase());
      }
      for (int c = 0; c < headers.length && c < dataRow.length; c++) {
        final val = dataRow[c]?.value?.toString().trim() ?? '';
        if (val.isEmpty) continue;
        switch (headers[c]) {
          case 'INV_NAME':
            info.name = val;
            break;
          case 'EMAIL':
            info.email = val;
            break;
          case 'MOBILE_NO':
            info.mobile = val;
            break;
        }
      }
    }

    // Extract PAN from TRXN_DETAILS
    final trxnSheet = _findSheet(excel, 'TRXN_DETAILS');
    if (trxnSheet != null) {
      for (int r = 0; r < trxnSheet.maxRows && r < 10; r++) {
        final row = trxnSheet.row(r);
        for (int c = 0; c < row.length; c++) {
          final val = row[c]?.value?.toString().trim() ?? '';
          if (val == 'PAN') {
            for (int dr = r + 1; dr < trxnSheet.maxRows; dr++) {
              final dRow = trxnSheet.row(dr);
              if (c < dRow.length) {
                final panVal = dRow[c]?.value?.toString().trim() ?? '';
                if (_panRegex.hasMatch(panVal)) {
                  info.pan = panVal;
                  info.panCellRef = 'TRXN_DETAILS Row ${dr + 1}';
                  break;
                }
              }
            }
            break;
          }
        }
        if (info.pan != null) break;
      }
    }

    _matchPanToMember(info);
  }

  /// Detect PAN from MF Central Tax XLSX and match to a member
  void _detectMfcTaxMember(xl.Excel excel) {
    final info = _XlsxMemberInfo();
    final txnSheet = _findSheet(excel, 'TransactionDetails');
    if (txnSheet != null) {
      for (int r = 0; r < txnSheet.maxRows && r < 5; r++) {
        final row = txnSheet.row(r);
        for (final cell in row) {
          final val = cell?.value?.toString().trim() ?? '';
          if (val.isEmpty) continue;
          final nameMatch = RegExp(r'Name\s*:\s*(.+)', caseSensitive: false)
              .firstMatch(val);
          if (nameMatch != null && info.name == null) {
            info.name = nameMatch.group(1)!.trim();
          }
          final panMatch = RegExp(r'Pan\s*:\s*([A-Z]{5}[0-9]{4}[A-Z])',
                  caseSensitive: false)
              .firstMatch(val);
          if (panMatch != null && info.pan == null) {
            info.pan = panMatch.group(1)!.toUpperCase();
            info.panCellRef = 'TransactionDetails Row ${r + 1}';
          }
        }
      }
    }

    _matchPanToMember(info);
  }

  /// Match PAN to family member and update UI
  void _matchPanToMember(_XlsxMemberInfo info) {
    final members = ref.read(familyMembersProvider).valueOrNull ?? [];
    FamilyMemberModel? matched;
    if (info.pan != null) {
      matched = members
          .where((m) =>
              m.pan != null &&
              m.pan!.toUpperCase().trim() == info.pan!.toUpperCase().trim())
          .firstOrNull;
    }

    setState(() {
      _xlsxInfo = info;
      _matchedMember = matched;
      _panDetectionDone = true;
    });

    if (info.pan != null && matched == null) {
      _nameCtrl.text = info.name ?? '';
      _emailCtrl.text = info.email ?? '';
      _mobileCtrl.text = info.mobile ?? '';
      // Smart default: Self if none exists, otherwise Other
      final existingMembers =
          ref.read(familyMembersProvider).valueOrNull ?? [];
      final hasSelf =
          existingMembers.any((m) => m.relationship == 'Self');
      _relationship = hasSelf ? 'Other' : 'Self';
      setState(() => _showNewMemberForm = true);
    }
  }

  /// Parse CAMS Tax XLS and store in DB
  Future<void> _parseCamsTaxXls() async {
    if (_fileBytes == null) return;

    setState(() {
      _state = _UploadState.uploading;
      _error = null;
    });

    try {
      final excel = xl.Excel.decodeBytes(_fileBytes!);
      final data = _CamsTaxData();

      // ── Parse INVESTOR_DETAILS
      final invSheet = _findSheet(excel, 'INVESTOR_DETAILS');
      if (invSheet != null && invSheet.maxRows > 4) {
        final headers = invSheet
            .row(3)
            .map((c) => (c?.value?.toString().trim() ?? '').toUpperCase())
            .toList();
        final vals = invSheet.row(4);
        for (int c = 0; c < headers.length && c < vals.length; c++) {
          final v = vals[c]?.value?.toString().trim() ?? '';
          switch (headers[c]) {
            case 'INV_NAME':
              data.investorName = v;
              break;
            case 'EMAIL':
              data.email = v;
              break;
            case 'MOBILE_NO':
              data.mobile = v;
              break;
          }
        }
      }
      data.pan = _xlsxInfo?.pan ?? '';

      // ── Parse period from TRXN_DETAILS row 1
      final trxnSheet = _findSheet(excel, 'TRXN_DETAILS');
      if (trxnSheet != null) {
        for (int r = 0; r < 3 && r < trxnSheet.maxRows; r++) {
          final row = trxnSheet.row(r);
          for (final cell in row) {
            final val = cell?.value?.toString() ?? '';
            final periodMatch = RegExp(
                    r'For the Period (\d{2}-\w{3}-\d{4}) to (\d{2}-\w{3}-\d{4})')
                .firstMatch(val);
            if (periodMatch != null) {
              data.periodStr = val;
              break;
            }
          }
        }
      }

      // ── Parse TRXN_DETAILS (lot matches)
      if (trxnSheet != null) {
        int headerRowIdx = -1;
        List<String> headers = [];
        for (int r = 0; r < trxnSheet.maxRows && r < 10; r++) {
          final row = trxnSheet.row(r);
          final cellVals =
              row.map((c) => c?.value?.toString().trim() ?? '').toList();
          if (cellVals.contains('AMC Name') &&
              cellVals.contains('Scheme Name')) {
            headerRowIdx = r;
            headers = cellVals;
            break;
          }
        }

        if (headerRowIdx >= 0) {
          final colIdx = <String, int>{};
          for (int c = 0; c < headers.length; c++) {
            colIdx[headers[c]] = c;
          }

          for (int r = headerRowIdx + 1; r < trxnSheet.maxRows; r++) {
            final row = trxnSheet.row(r);
            String cellVal(String col) {
              final idx = colIdx[col];
              if (idx == null || idx >= row.length) return '';
              return row[idx]?.value?.toString().trim() ?? '';
            }

            double cellNum(String col) {
              final v = cellVal(col);
              return double.tryParse(v) ?? 0;
            }

            final amcName = cellVal('AMC Name');
            if (amcName.isEmpty) continue;

            final schemeName = cellVal('Scheme Name');
            String? isin;
            final isinMatch =
                RegExp(r'ISIN\s*:\s*([A-Z0-9]{12})').firstMatch(schemeName);
            if (isinMatch != null) isin = isinMatch.group(1);

            final txn = _CamsTaxTxn(
              amcName: amcName,
              folioNo: cellVal('Folio No'),
              assetClass: cellVal('ASSET CLASS'),
              schemeName: schemeName,
              isin: isin,
              pan: cellVal('PAN'),
              sellDesc: cellVal('Desc'),
              sellDate: cellVal('Date'),
              sellUnits: cellNum('Units'),
              sellAmount: cellNum('Amount'),
              sellNav: cellNum('Price'),
              stt: cellNum('STT'),
              buyDesc: cellVal('Desc_1'),
              buyDate: cellVal('Date_1'),
              buyUnits: cellNum('PurhUnit'),
              soldUnits: cellNum('RedUnits'),
              unitCost: cellNum('Unit Cost'),
              indexedCost: cellNum('Indexed Cost'),
              gfUnits: cellNum(
                  'Units As On 31/01/2018 (Grandfathered Units)'),
              gfNav: cellNum(
                  'NAV As On 31/01/2018 (Grandfathered NAV)'),
              gfValue: cellNum(
                  'Market Value As On 31/01/2018 (Grandfathered Value)'),
              shortTermGain: cellNum('Short Term'),
              longTermWithIdx: cellNum('Long Term With Index'),
              longTermNoIdx: cellNum('Long Term Without Index'),
              taxPerc: cellNum('Tax Perc'),
              taxDeduct: cellNum('Tax Deduct'),
              taxSurcharge: cellNum('Tax Surcharge'),
            );
            data.transactions.add(txn);
            data.totalStt += txn.stt;
          }
        }
      }

      // ── Parse SCHEMEWISE sheets
      // NOTE: CAMS uses 'SCHEMEWISE_EQUTIY' (typo), MF Central may use
      // correct spelling 'SCHEMEWISE_EQUITY'. Try both variants.
      bool parsedEquitySchemewise = false;
      for (final sheetName in [
        'SCHEMEWISE_EQUTIY',
        'SCHEMEWISE_EQUITY',
        'SCHEMEWISE_NONEQUITY',
      ]) {
        final sheet = _findSheet(excel, sheetName);
        if (sheet == null) continue;
        final isEquity =
            sheetName.toUpperCase().contains('EQUI') &&
            !sheetName.toUpperCase().contains('NON');
        // Skip duplicate equity sheet (typo variant resolves to same sheet)
        if (isEquity && parsedEquitySchemewise) continue;
        if (isEquity) parsedEquitySchemewise = true;

        for (int r = 0; r < sheet.maxRows && r < 10; r++) {
          final row = sheet.row(r);
          final vals =
              row.map((c) => c?.value?.toString().trim() ?? '').toList();
          if (vals.contains(
              'Redemption Scheme name/Switchout-Scheme Names')) {
            for (int dr = r + 1; dr < sheet.maxRows; dr++) {
              final dRow = sheet.row(dr);
              if (dRow.isEmpty ||
                  (dRow[0]?.value?.toString().trim() ?? '').isEmpty) {
                continue;
              }
              data.schemeBreakdowns.add({
                'scheme': dRow[0]?.value?.toString().trim() ?? '',
                'is_equity': isEquity,
                'count':
                    (dRow.length > 1 ? dRow[1]?.value : null) ?? 0,
                'amount':
                    (dRow.length > 2 ? dRow[2]?.value : null) ?? 0,
                'cost':
                    (dRow.length > 3 ? dRow[3]?.value : null) ?? 0,
                'indexed_cost':
                    (dRow.length > 4 ? dRow[4]?.value : null) ?? 0,
                'gf_value':
                    (dRow.length > 5 ? dRow[5]?.value : null) ?? 0,
                'short_term':
                    (dRow.length > 6 ? dRow[6]?.value : null) ?? 0,
                'lt_with_idx':
                    (dRow.length > 7 ? dRow[7]?.value : null) ?? 0,
                'lt_no_idx':
                    (dRow.length > 8 ? dRow[8]?.value : null) ?? 0,
                'tds':
                    (dRow.length > 9 ? dRow[9]?.value : null) ?? 0,
              });
            }
            break;
          }
        }
      }

      // ── Parse OVERALL_SUMMARY sheets
      for (final sheetName in [
        'OVERALL_SUMMARY_EQUITY',
        'OVERALL_SUMMARY_NONEQUITY'
      ]) {
        final sheet = _findSheet(excel, sheetName);
        if (sheet == null) continue;
        final isEquity =
            sheetName.contains('EQUITY') && !sheetName.contains('NON');

        for (int r = 0; r < sheet.maxRows && r < 10; r++) {
          final row = sheet.row(r);
          final vals =
              row.map((c) => c?.value?.toString().trim() ?? '').toList();
          if (vals.contains('Summary Of Capital Gains')) {
            for (int dr = r + 1; dr < sheet.maxRows; dr++) {
              final dRow = sheet.row(dr);
              final label = dRow.isNotEmpty
                  ? (dRow[0]?.value?.toString().trim() ?? '')
                  : '';
              if (label.isEmpty) continue;

              final total = dRow.length > 6
                  ? (double.tryParse(
                          dRow[6]?.value?.toString() ?? '') ??
                      0)
                  : 0.0;
              final q = <double>[];
              for (int qc = 1; qc <= 5; qc++) {
                q.add(dRow.length > qc
                    ? (double.tryParse(
                            dRow[qc]?.value?.toString() ?? '') ??
                        0)
                    : 0.0);
              }

              if (label == 'Short Term Capital Gain/Loss') {
                if (isEquity) {
                  data.equityStcg = total;
                  data.eqStcgQ = q;
                } else {
                  data.nonEquityStcg = total;
                  data.neStcgQ = q;
                }
              } else if (label ==
                  'LongTermWithIndex-CapitalGain/Loss') {
                if (isEquity) {
                  data.equityLtcgWithIdx = total;
                } else {
                  data.nonEquityLtcgWithIdx = total;
                }
              } else if (label ==
                  'LongTermWithOutIndex-CapitalGain/Loss') {
                if (isEquity) {
                  data.equityLtcgNoIdx = total;
                  data.eqLtcgQ = q;
                } else {
                  data.nonEquityLtcgNoIdx = total;
                }
              }
            }
            break;
          }
        }
      }

      // ── Derive FY key
      final periodMatch =
          RegExp(r'(\d{4})').allMatches(data.periodStr ?? '');
      String fyKey;
      if (periodMatch.length >= 2) {
        final startYear =
            int.parse(periodMatch.elementAt(0).group(0)!);
        final endYear =
            int.parse(periodMatch.elementAt(1).group(0)!);
        fyKey =
            'FY${(startYear % 100).toString().padLeft(2, '0')}${(endYear % 100).toString().padLeft(2, '0')}';
      } else {
        final now = DateTime.now();
        final y = now.month >= 4 ? now.year : now.year - 1;
        fyKey =
            'FY${(y % 100).toString().padLeft(2, '0')}${((y + 1) % 100).toString().padLeft(2, '0')}';
      }
      data.financialYear = fyKey;

      // ── Store in Supabase
      await _upsertTaxData(data);
    } catch (e) {
      setState(() {
        _state = _UploadState.error;
        _error = e.toString();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to parse tax file: $e'),
          backgroundColor: context.palette.loss,
        ),
      );
    }
  }

  /// Parse MF Central Tax XLSX and store in DB
  Future<void> _parseMfcTaxXlsx() async {
    if (_fileBytes == null) return;

    setState(() {
      _state = _UploadState.uploading;
      _error = null;
    });

    try {
      final excel = xl.Excel.decodeBytes(_fileBytes!);
      final data = _CamsTaxData();
      data.source = 'mfc';
      data.investorName = _xlsxInfo?.name ?? '';
      data.pan = _xlsxInfo?.pan ?? '';

      debugPrint('MFC-PARSE: All sheets: ${excel.tables.keys.toList()}');

      // ── Parse TransactionDetails
      final txnSheet = _findSheet(excel, 'TransactionDetails');
      if (txnSheet != null) {
        int headerRowIdx = -1;
        List<String> headers = [];
        for (int r = 0; r < txnSheet.maxRows && r < 10; r++) {
          final row = txnSheet.row(r);
          final cellVals =
              row.map((c) => c?.value?.toString().trim() ?? '').toList();
          if (cellVals.contains('Fund Name') &&
              cellVals.contains('Scheme Name')) {
            headerRowIdx = r;
            headers = cellVals;
            break;
          }
        }

        debugPrint('MFC-PARSE: TransactionDetails headerRowIdx=$headerRowIdx');
        if (headerRowIdx >= 0) {
          debugPrint('MFC-PARSE: TransactionDetails headers=$headers');
          int colOf(String name, {int occurrence = 0}) {
            int found = 0;
            for (int i = 0; i < headers.length; i++) {
              if (headers[i] == name) {
                if (found == occurrence) return i;
                found++;
              }
            }
            return -1;
          }

          final fundNameCol = colOf('Fund Name');
          final folioCol = colOf('Folio Number');
          final schemeCol = colOf('Scheme Name');
          final buyTypeCol = colOf('Trxn.Type', occurrence: 0);
          final buyDateCol = colOf('Date', occurrence: 0);
          final currentUnitsCol = colOf('Current Units');
          final gfNavCol = headers
              .indexWhere((h) => h.contains('Grandfathered NAV'));
          final gfCostCol = headers
              .indexWhere((h) => h.contains('GrandFathered Cost'));
          final sellTypeCol = colOf('Trxn.Type', occurrence: 1);
          final sellDateCol = colOf('Date', occurrence: 1);
          final unitsCol = colOf('Units');
          final amountCol = colOf('Amount');
          final priceCol = colOf('Price');
          final taxPercCol = colOf('Tax Perc');
          final taxCol = colOf('Tax');
          final stCol = colOf('Short Term');
          final idxCostCol = colOf('Indexed Cost');
          final ltWithCol = colOf('Long Term With Index');
          final ltNoCol = colOf('Long Term Without Index');

          // Track last non-empty values for merged cell handling.
          // Indian financial XLSX files use merged cells — the excel
          // library returns empty for merged cells, so we carry forward.
          String lastFundName = '';
          String lastFolioNo = '';
          String lastSchemeName = '';

          for (int r = headerRowIdx + 1; r < txnSheet.maxRows; r++) {
            final row = txnSheet.row(r);
            String cellVal(int col) {
              if (col < 0 || col >= row.length) return '';
              return row[col]?.value?.toString().trim() ?? '';
            }

            double cellNum(int col) {
              return double.tryParse(cellVal(col)) ?? 0;
            }

            // Handle merged cells: carry forward fund name, folio, scheme
            final rawFundName = cellVal(fundNameCol);
            final rawFolioNo = cellVal(folioCol);
            final rawSchemeName = cellVal(schemeCol);

            if (rawFundName.isNotEmpty) lastFundName = rawFundName;
            if (rawFolioNo.isNotEmpty) lastFolioNo = rawFolioNo;
            if (rawSchemeName.isNotEmpty) lastSchemeName = rawSchemeName;

            final fundName = rawFundName.isNotEmpty ? rawFundName : lastFundName;
            if (fundName.isEmpty) continue;

            final schemeName = rawSchemeName.isNotEmpty
                ? rawSchemeName
                : lastSchemeName;
            final folioNo = rawFolioNo.isNotEmpty
                ? rawFolioNo
                : lastFolioNo;
            String? isin;
            final isinMatch = RegExp(r'([A-Z]{2}[A-Z0-9]{10})')
                .firstMatch(schemeName);
            if (isinMatch != null) isin = isinMatch.group(1);

            final txn = _CamsTaxTxn(
              amcName: fundName,
              folioNo: folioNo,
              assetClass: '',
              schemeName: schemeName,
              isin: isin,
              pan: data.pan,
              sellDesc: cellVal(sellTypeCol),
              sellDate: cellVal(sellDateCol),
              sellUnits: cellNum(unitsCol),
              sellAmount: cellNum(amountCol),
              sellNav: cellNum(priceCol),
              stt: 0,
              buyDesc: cellVal(buyTypeCol),
              buyDate: cellVal(buyDateCol),
              buyUnits: cellNum(currentUnitsCol),
              soldUnits: 0,
              unitCost: 0,
              indexedCost: cellNum(idxCostCol),
              gfUnits: 0,
              gfNav: cellNum(gfNavCol),
              gfValue: cellNum(gfCostCol),
              shortTermGain: cellNum(stCol),
              longTermWithIdx: cellNum(ltWithCol),
              longTermNoIdx: cellNum(ltNoCol),
              taxPerc: cellNum(taxPercCol),
              taxDeduct: cellNum(taxCol),
              taxSurcharge: 0,
            );
            data.transactions.add(txn);
          }

          // Log unique fund names parsed
          final uniqueFunds = data.transactions
              .map((t) => t.amcName)
              .toSet();
          debugPrint(
              'MFC-PARSE: ${data.transactions.length} txns from ${uniqueFunds.length} funds');
          for (final f in uniqueFunds) {
            final count = data.transactions
                .where((t) => t.amcName == f)
                .length;
            debugPrint('MFC-PARSE:   $f → $count txns');
          }
        }
      }

      // ── Parse Summary sheet
      final summarySheet = _findSheet(excel, 'Summary');
      if (summarySheet != null) {
        int headerRowIdx = -1;
        for (int r = 0; r < summarySheet.maxRows && r < 10; r++) {
          final row = summarySheet.row(r);
          final vals =
              row.map((c) => c?.value?.toString().trim() ?? '').toList();
          if (vals.any((v) => v.contains('Summary Of Capital Gains'))) {
            headerRowIdx = r;
            break;
          }
        }

        if (headerRowIdx >= 0) {
          for (int r = headerRowIdx + 1;
              r < summarySheet.maxRows;
              r++) {
            final row = summarySheet.row(r);
            final label = row.isNotEmpty
                ? (row[0]?.value?.toString().trim() ?? '')
                : '';
            if (label.isEmpty) continue;

            final labelLower = label.toLowerCase();
            if (labelLower.contains('full value') ||
                labelLower.contains('cost of') ||
                labelLower.contains('fair market')) continue;

            final total = row.length > 6
                ? (double.tryParse(
                        row[6]?.value?.toString() ?? '') ??
                    0)
                : 0.0;
            final q = <double>[];
            for (int qc = 1; qc <= 5; qc++) {
              q.add(row.length > qc
                  ? (double.tryParse(
                          row[qc]?.value?.toString() ?? '') ??
                      0)
                  : 0.0);
            }

            if (labelLower.contains('short term')) {
              data.equityStcg = total;
              data.eqStcgQ = q;
            } else if (labelLower.contains('long term') &&
                labelLower.contains('without')) {
              data.equityLtcgNoIdx = total;
              data.eqLtcgQ = q;
            } else if (labelLower.contains('long term') &&
                labelLower.contains('with')) {
              data.equityLtcgWithIdx = total;
            }
          }
        }
      }

      // ── Parse Scheme_Level_Summary
      final schemeSheet = _findSheet(excel, 'Scheme_Level_Summary');
      if (schemeSheet != null) {
        int headerRowIdx = -1;
        List<String> headers = [];
        for (int r = 0; r < schemeSheet.maxRows && r < 10; r++) {
          final row = schemeSheet.row(r);
          final cellVals =
              row.map((c) => c?.value?.toString().trim() ?? '').toList();
          if (cellVals.contains('Scheme Name')) {
            headerRowIdx = r;
            headers = cellVals;
            break;
          }
        }
        if (headerRowIdx >= 0) {
          final colIdx = <String, int>{};
          for (int c = 0; c < headers.length; c++) {
            colIdx[headers[c]] = c;
          }
          final schemeNameCol = colIdx['Scheme Name'] ?? 0;
          debugPrint('MFC-PARSE: Scheme_Level_Summary headers=$headers');
          debugPrint('MFC-PARSE: schemeNameCol=$schemeNameCol');

          for (int dr = headerRowIdx + 1;
              dr < schemeSheet.maxRows;
              dr++) {
            final dRow = schemeSheet.row(dr);
            if (dRow.isEmpty) continue;
            final schemeName = dRow.length > schemeNameCol
                ? (dRow[schemeNameCol]?.value?.toString().trim() ?? '')
                : '';
            if (schemeName.isEmpty ||
                schemeName.toLowerCase() == 'total') continue;
            debugPrint('MFC-PARSE: Scheme breakdown: $schemeName');

            // Flexible column lookup: exact match first, then substring
            String cellVal(String col) {
              var idx = colIdx[col];
              if (idx == null) {
                // Try substring match
                final colLower = col.toLowerCase();
                for (final entry in colIdx.entries) {
                  if (entry.key.toLowerCase().contains(colLower) ||
                      colLower.contains(entry.key.toLowerCase())) {
                    idx = entry.value;
                    break;
                  }
                }
              }
              if (idx == null || idx >= dRow.length) return '0';
              return dRow[idx]?.value?.toString().trim() ?? '0';
            }

            data.schemeBreakdowns.add({
              'scheme': schemeName,
              'is_equity': null,
              'count': double.tryParse(cellVal('Count')) ?? 0,
              'amount':
                  double.tryParse(cellVal('Outflow Amount')) ?? 0,
              'cost': double.tryParse(cellVal('Net Value')) ?? 0,
              'indexed_cost': 0,
              'gf_value': double.tryParse(
                      cellVal('Fair Market Value')) ??
                  0,
              'short_term':
                  double.tryParse(cellVal('Short Gain')) ?? 0,
              'lt_with_idx': double.tryParse(
                      cellVal('Long Gain With Index')) ??
                  0,
              'lt_no_idx': double.tryParse(
                      cellVal('Long Gain Without Index')) ??
                  0,
              'tds': 0,
            });
          }
        }
      }

      debugPrint(
          'MFC-PARSE: ${data.schemeBreakdowns.length} scheme breakdowns found');
      for (final s in data.schemeBreakdowns) {
        debugPrint(
            'MFC-PARSE:   ${s['scheme']} → ST:${s['short_term']} LT:${s['lt_no_idx']}');
      }

      // ── Classify equity vs non-equity and recompute summary totals ──
      // The MFC Summary sheet doesn't reliably split equity/non-equity and
      // may miss LTCG entirely.  Recompute from per-scheme data.
      if (data.schemeBreakdowns.isNotEmpty) {
        double eqStcg = 0, eqLtcg = 0, neStcg = 0, neLtcg = 0;
        for (final s in data.schemeBreakdowns) {
          final name = (s['scheme'] as String?) ?? '';
          final isNonEq = _isLikelyNonEquityScheme(name);
          s['is_equity'] = !isNonEq;

          final stcg = (s['short_term'] as num?)?.toDouble() ?? 0;
          final ltcgIdx = (s['lt_with_idx'] as num?)?.toDouble() ?? 0;
          final ltcgNoIdx = (s['lt_no_idx'] as num?)?.toDouble() ?? 0;

          if (isNonEq) {
            neStcg += stcg;
            neLtcg += ltcgIdx + ltcgNoIdx;
          } else {
            eqStcg += stcg;
            eqLtcg += ltcgIdx + ltcgNoIdx;
          }
        }
        data.equityStcg = eqStcg;
        data.equityLtcgNoIdx = eqLtcg;
        data.equityLtcgWithIdx = 0;
        data.nonEquityStcg = neStcg;
        data.nonEquityLtcgNoIdx = neLtcg;
        data.nonEquityLtcgWithIdx = 0;
      }

      // ── Derive FY key
      final now = DateTime.now();
      final y = now.month >= 4 ? now.year : now.year - 1;
      data.financialYear =
          'FY${(y % 100).toString().padLeft(2, '0')}${((y + 1) % 100).toString().padLeft(2, '0')}';

      // ── Store in Supabase
      await _upsertTaxData(data);
    } catch (e) {
      setState(() {
        _state = _UploadState.error;
        _error = e.toString();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to parse MF Central tax file: $e'),
          backgroundColor: context.palette.loss,
        ),
      );
    }
  }

  /// Auto-suggest AIS password from member's PAN + DOB
  void _suggestAisPassword() {
    final members = ref.read(familyMembersProvider).valueOrNull ?? [];
    for (final m in members) {
      if (m.pan != null && m.dateOfBirth != null) {
        final pan = m.pan!.toLowerCase();
        // dateOfBirth is stored as 'YYYY-MM-DD' string
        final dobParts = m.dateOfBirth!.split('-');
        if (dobParts.length == 3) {
          final dobStr = '${dobParts[2]}${dobParts[1]}${dobParts[0]}'; // DDMMYYYY
          _passwordCtrl.text = '$pan$dobStr';
          setState(() {
            _matchedMember = m;
            _panDetectionDone = true;
          });
          return;
        }
      }
    }
    // No auto-match, let user type password
    setState(() => _panDetectionDone = true);
  }

  /// Parse AIS PDF via Edge Function
  Future<void> _parseAisPdf() async {
    if (_fileBytes == null || _passwordCtrl.text.isEmpty) return;

    setState(() {
      _state = _UploadState.uploading;
      _error = null;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Not authenticated');

      final fileBase64 = base64Encode(_fileBytes!);

      // owner_id is derived from the authenticated JWT server-side.
      final response = await client.functions.invoke(
        'parse-ais-pdf',
        body: {
          'file_base64': fileBase64,
          'password': _passwordCtrl.text.trim(),
          'member_id': _matchedMember?.id,
          'file_name': _fileName,
        },
      );

      if (response.status != 200) {
        final errorBody = response.data;
        throw Exception(
            errorBody is Map ? errorBody['error'] : 'Server error ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Parse failed');
      }

      // Invalidate tax providers
      ref.invalidate(camsTaxStatementProvider);

      setState(() {
        _state = _UploadState.done;
        _aisResult = data;
      });

      if (!mounted) return;

      final stockSales = data['stock_sales'] ?? 0;
      final mfSales = (data['equity_mf_sales'] ?? 0) + (data['debt_mf_sales'] ?? 0);
      final gains = data['gains'] as Map<String, dynamic>? ?? {};
      final stockGains = gains['stock'] as Map<String, dynamic>? ?? {};
      final eqMfGains = gains['equity_mf'] as Map<String, dynamic>? ?? {};

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'AIS imported: $stockSales stock sales, $mfSales MF sales for ${data['financial_year']}'),
          backgroundColor: context.palette.gain,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      setState(() {
        _state = _UploadState.error;
        _error = e.toString();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to parse AIS: $e'),
          backgroundColor: context.palette.loss,
        ),
      );
    }
  }

  /// Store tax data in Supabase (shared between CAMS & MFC)
  Future<void> _upsertTaxData(_CamsTaxData data) async {
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Not authenticated');

    final upsertData = {
      'owner_id': userId,
      'member_id': _matchedMember?.id,
      'financial_year': data.financialYear,
      'pan': data.pan,
      'investor_name': data.investorName,
      'equity_stcg': data.equityStcg,
      'equity_ltcg_with_idx': data.equityLtcgWithIdx,
      'equity_ltcg_no_idx': data.equityLtcgNoIdx,
      'non_equity_stcg': data.nonEquityStcg,
      'non_equity_ltcg_with_idx': data.nonEquityLtcgWithIdx,
      'non_equity_ltcg_no_idx': data.nonEquityLtcgNoIdx,
      'total_stt': data.totalStt,
      'eq_stcg_q1': data.eqStcgQ.length > 0 ? data.eqStcgQ[0] : 0,
      'eq_stcg_q2': data.eqStcgQ.length > 1 ? data.eqStcgQ[1] : 0,
      'eq_stcg_q3': data.eqStcgQ.length > 2 ? data.eqStcgQ[2] : 0,
      'eq_stcg_q4': data.eqStcgQ.length > 3 ? data.eqStcgQ[3] : 0,
      'eq_stcg_q5': data.eqStcgQ.length > 4 ? data.eqStcgQ[4] : 0,
      'eq_ltcg_q1': data.eqLtcgQ.length > 0 ? data.eqLtcgQ[0] : 0,
      'eq_ltcg_q2': data.eqLtcgQ.length > 1 ? data.eqLtcgQ[1] : 0,
      'eq_ltcg_q3': data.eqLtcgQ.length > 2 ? data.eqLtcgQ[2] : 0,
      'eq_ltcg_q4': data.eqLtcgQ.length > 3 ? data.eqLtcgQ[3] : 0,
      'eq_ltcg_q5': data.eqLtcgQ.length > 4 ? data.eqLtcgQ[4] : 0,
      'ne_stcg_q1': data.neStcgQ.length > 0 ? data.neStcgQ[0] : 0,
      'ne_stcg_q2': data.neStcgQ.length > 1 ? data.neStcgQ[1] : 0,
      'ne_stcg_q3': data.neStcgQ.length > 2 ? data.neStcgQ[2] : 0,
      'ne_stcg_q4': data.neStcgQ.length > 3 ? data.neStcgQ[3] : 0,
      'ne_stcg_q5': data.neStcgQ.length > 4 ? data.neStcgQ[4] : 0,
      'scheme_breakdowns': data.schemeBreakdowns,
      'transaction_details':
          data.transactions.map((t) => t.toJson()).toList(),
      'source_file': _fileName,
    };

    await client.from('cams_tax_statements').upsert(
      upsertData,
      onConflict: 'owner_id, member_id, financial_year',
    );

    // Invalidate tax provider so Tax screen picks up new data
    ref.invalidate(camsTaxStatementProvider);

    setState(() {
      _state = _UploadState.done;
      _camsTaxResult = data;
    });

    if (!mounted) return;
    final schemeCount = data.schemeBreakdowns.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${data.transactions.length} tax lot matches, $schemeCount schemes imported for ${data.financialYear}'),
        backgroundColor: context.palette.gain,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _addNewMember() async {
    final pan = _xlsxInfo?.pan;
    final name = _nameCtrl.text.trim();
    if (pan == null || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Name is required'),
          backgroundColor: context.palette.loss,
        ),
      );
      return;
    }

    setState(() => _savingMember = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Not authenticated');

      // Get or create family (check DB directly to avoid duplicates)
      final existingFamily = await client
          .from('families')
          .select('id')
          .eq('owner_id', userId)
          .order('created_at')
          .limit(1);
      String familyId;
      if ((existingFamily as List).isNotEmpty) {
        familyId = existingFamily.first['id'] as String;
      } else {
        final familyRes = await client.from('families').insert({
          'owner_id': userId,
          'family_name': 'My Family',
        }).select('id').single();
        familyId = familyRes['id'] as String;
        ref.invalidate(familyProvider);
      }

      final res = await client.from('family_members').insert({
        'owner_id': userId,
        'family_id': familyId,
        'display_name': name,
        'pan': pan,
        'relationship': _relationship,
      }).select().single();

      final newMember =
          FamilyMemberModel.fromJson(res as Map<String, dynamic>);
      ref.invalidate(familyMembersProvider);

      setState(() {
        _matchedMember = newMember;
        _showNewMemberForm = false;
        _savingMember = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name added as family member'),
          backgroundColor: context.palette.gain,
        ),
      );
    } catch (e) {
      setState(() => _savingMember = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add member: $e'),
          backgroundColor: context.palette.loss,
        ),
      );
    }
  }

  Future<void> _clearTaxData() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final memberId = _matchedMember?.id;
    final memberName = _matchedMember?.displayName ?? 'all members';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Tax Data'),
        content: Text(
          memberId != null
              ? 'This will delete the uploaded tax statement data for $memberName.\n\n'
                'Calculated tax from your transactions will not be affected.\n\n'
                'You can re-import the tax statement anytime.'
              : 'This will delete all uploaded tax statement data.\n\n'
                'Calculated tax from your transactions will not be affected.\n\n'
                'You can re-import the tax statement anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.palette.loss),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final client = ref.read(supabaseClientProvider);
      var query = client
          .from('cams_tax_statements')
          .delete()
          .eq('owner_id', userId);

      if (memberId != null) {
        query = query.eq('member_id', memberId);
      }

      await query;

      ref.invalidate(camsTaxStatementProvider);

      setState(() {
        _camsTaxResult = null;
        _state = _UploadState.idle;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tax data for $memberName cleared'),
          backgroundColor: context.palette.gain,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear: $e'),
          backgroundColor: context.palette.loss,
        ),
      );
    }
  }

  bool get _canImport {
    if (_fileBytes == null || _state == _UploadState.uploading) return false;
    if (_isAisPdf) return _passwordCtrl.text.trim().isNotEmpty;
    if (!_isCAMSTaxXls && !_isMFCTaxXlsx) return false;
    if (_panDetectionDone &&
        _xlsxInfo?.pan != null &&
        _matchedMember == null) {
      return false;
    }
    return true;
  }

  Future<void> _handleImport() {
    if (_isAisPdf) return _parseAisPdf();
    if (_isCAMSTaxXls) return _parseCamsTaxXls();
    return _parseMfcTaxXlsx();
  }

  @override
  Widget build(BuildContext context) {
    final detectedPan = _xlsxInfo?.pan;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isAisPdf
              ? 'Import AIS (Income Tax)'
              : _isCAMSTaxXls
                  ? 'Import CAMS Tax Statement'
                  : _isMFCTaxXlsx
                      ? 'Import MF Central Tax Statement'
                      : 'Import Tax Statement',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.tax),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Tax Statement Upload',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Upload AIS PDF (.pdf) from Income Tax portal, '
                    'CAMS Capital Gains (.xls/.xlsx), or '
                    'MF Central Tax (.xlsx).\n\n'
                    'AIS covers all assets (stocks, MFs, dividends). '
                    'Password: PAN(lowercase) + DOB (DDMMYYYY).',
                    style: TextStyle(
                        fontSize: 12, color: context.palette.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── File pick zone
            GestureDetector(
              onTap: _state == _UploadState.uploading ? null : _pickFile,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 130,
                decoration: BoxDecoration(
                  color: context.palette.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.palette.bgDivider),
                ),
                child: _fileName != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.description_outlined,
                              size: 32, color: AppColors.primary),
                          const SizedBox(height: 8),
                          Text(_fileName!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(
                            _fileBytes != null
                                ? '${(_fileBytes!.length / 1024).toStringAsFixed(1)} KB'
                                : '',
                            style: TextStyle(
                                fontSize: 12,
                                color: context.palette.textTertiary),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 36, color: context.palette.textTertiary),
                          SizedBox(height: 8),
                          Text('Tap to select tax statement',
                              style: TextStyle(
                                  color: context.palette.textSecondary)),
                          SizedBox(height: 4),
                          Text('.pdf (AIS) / .xlsx / .xls',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.palette.textTertiary)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // ── PAN matched banner
            if (_panDetectionDone &&
                detectedPan != null &&
                _matchedMember != null)
              _MatchedBanner(
                pan: detectedPan,
                memberName: _matchedMember!.displayName,
                cellRef: _xlsxInfo?.panCellRef,
              ),

            // ── PAN unmatched — new member form
            if (_panDetectionDone &&
                detectedPan != null &&
                _matchedMember == null &&
                _showNewMemberForm) ...[
              _UnmatchedBanner(
                  pan: detectedPan, cellRef: _xlsxInfo?.panCellRef),
              const SizedBox(height: 12),
              Consumer(builder: (context, ref, _) {
                final existingMembers =
                    ref.watch(familyMembersProvider).valueOrNull ?? [];
                return _NewMemberForm(
                  pan: detectedPan,
                  nameCtrl: _nameCtrl,
                  emailCtrl: _emailCtrl,
                  mobileCtrl: _mobileCtrl,
                  relationship: _relationship,
                  existingMembers: existingMembers,
                  onRelationshipChanged: (v) =>
                      setState(() => _relationship = v ?? 'Other'),
                  onSave: _addNewMember,
                  saving: _savingMember,
                );
              }),
            ],

            // ── CAMS Tax XLS detection banner
            if (_isCAMSTaxXls && _fileName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified,
                            size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'CAMS Capital Gains Statement',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Authoritative FIFO tax data from CAMS with exact cost basis, '
                      'grandfathering, STT, and quarterly breakdown for advance tax.',
                      style: TextStyle(
                          fontSize: 11, color: context.palette.textSecondary),
                    ),
                  ],
                ),
              ),
            ],

            // ── MF Central Tax XLSX detection banner
            if (_isMFCTaxXlsx && _fileName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified,
                            size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'MF Central Capital Gains Statement',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Complete FIFO tax data from MF Central covering all AMCs '
                      'with grandfathering, indexed cost, and quarterly breakdown.',
                      style: TextStyle(
                          fontSize: 11, color: context.palette.textSecondary),
                    ),
                  ],
                ),
              ),
            ],

            // ── AIS PDF detection banner
            if (_isAisPdf && _fileName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.palette.gain.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: context.palette.gain.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 18, color: context.palette.gain),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Annual Information Statement (AIS)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: context.palette.gain,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gold standard tax data from Income Tax Dept. Covers ALL assets: '
                      'stocks, MFs (all registrars), dividends, interest, and salary.',
                      style: TextStyle(
                          fontSize: 11, color: context.palette.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordCtrl,
                      decoration: InputDecoration(
                        labelText: 'AIS Password',
                        hintText: 'pan(lowercase) + dob e.g. adzpn9228p02101975',
                        hintStyle: const TextStyle(fontSize: 11),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        suffixIcon: const Icon(Icons.lock_outline, size: 18),
                      ),
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    ),
                    if (_matchedMember != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 14, color: context.palette.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Will import for: ${_matchedMember!.displayName}',
                            style: TextStyle(
                                fontSize: 11, color: context.palette.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Import button
            ElevatedButton.icon(
              onPressed: _canImport ? _handleImport : null,
              icon: _state == _UploadState.uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.receipt_long),
              label: Text(_state == _UploadState.uploading
                  ? 'Parsing Tax Data...'
                  : _isAisPdf
                      ? 'Import AIS Statement'
                      : 'Import Tax Statement'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),

            const SizedBox(height: 20),

            // ── CAMS/MFC Result
            if (_state == _UploadState.done &&
                _camsTaxResult != null) ...[
              _CamsTaxResultCard(
                data: _camsTaxResult!,
                memberName: _matchedMember?.displayName,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.go(Routes.tax),
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('View Tax Summary'),
              ),
            ],

            // ── AIS Result
            if (_state == _UploadState.done &&
                _aisResult != null) ...[
              _AisResultCard(data: _aisResult!),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.go(Routes.tax),
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('View Tax Summary'),
              ),
            ],

            if (_state == _UploadState.error && _error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.palette.loss.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: context.palette.loss.withOpacity(0.3)),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                      color: context.palette.loss,
                      fontSize: 13,
                      height: 1.5),
                ),
              ),

            const SizedBox(height: 32),

            // ── Clear tax data
            OutlinedButton.icon(
              onPressed: _clearTaxData,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(
                _matchedMember != null
                    ? 'Clear ${_matchedMember!.displayName} Tax Data'
                    : 'Clear Tax Data',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.palette.loss,
                side: BorderSide(
                    color: context.palette.loss.withOpacity(0.4)),
                minimumSize: const Size.fromHeight(44),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Enums & models ──────────────────────────────────────────────────────────

enum _UploadState { idle, picked, uploading, done, error }

class _CamsTaxTxn {
  _CamsTaxTxn({
    this.amcName = '',
    this.folioNo = '',
    this.assetClass = '',
    this.schemeName = '',
    this.isin,
    this.pan = '',
    this.sellDesc = '',
    this.sellDate = '',
    this.sellUnits = 0,
    this.sellAmount = 0,
    this.sellNav = 0,
    this.stt = 0,
    this.buyDesc = '',
    this.buyDate = '',
    this.buyUnits = 0,
    this.soldUnits = 0,
    this.unitCost = 0,
    this.indexedCost = 0,
    this.gfUnits = 0,
    this.gfNav = 0,
    this.gfValue = 0,
    this.shortTermGain = 0,
    this.longTermWithIdx = 0,
    this.longTermNoIdx = 0,
    this.taxPerc = 0,
    this.taxDeduct = 0,
    this.taxSurcharge = 0,
  });

  final String amcName, folioNo, assetClass, schemeName, pan;
  final String? isin;
  final String sellDesc, sellDate, buyDesc, buyDate;
  final double sellUnits, sellAmount, sellNav, stt;
  final double buyUnits, soldUnits, unitCost, indexedCost;
  final double gfUnits, gfNav, gfValue;
  final double shortTermGain, longTermWithIdx, longTermNoIdx;
  final double taxPerc, taxDeduct, taxSurcharge;

  Map<String, dynamic> toJson() => {
        'amc': amcName,
        'folio': folioNo,
        'asset_class': assetClass,
        'scheme': schemeName,
        'isin': isin,
        'pan': pan,
        'sell_desc': sellDesc,
        'sell_date': sellDate,
        'sell_units': sellUnits,
        'sell_amount': sellAmount,
        'sell_nav': sellNav,
        'stt': stt,
        'buy_desc': buyDesc,
        'buy_date': buyDate,
        'buy_units': buyUnits,
        'sold_units': soldUnits,
        'unit_cost': unitCost,
        'indexed_cost': indexedCost,
        'gf_units': gfUnits,
        'gf_nav': gfNav,
        'gf_value': gfValue,
        'st_gain': shortTermGain,
        'lt_with_idx': longTermWithIdx,
        'lt_no_idx': longTermNoIdx,
        'tax_perc': taxPerc,
        'tax_deduct': taxDeduct,
        'tax_surcharge': taxSurcharge,
      };
}

class _CamsTaxData {
  String source = 'cams';
  String? periodStr;
  String financialYear = '';
  String pan = '';
  String investorName = '';
  String? email;
  String? mobile;

  double equityStcg = 0;
  double equityLtcgWithIdx = 0;
  double equityLtcgNoIdx = 0;
  double nonEquityStcg = 0;
  double nonEquityLtcgWithIdx = 0;
  double nonEquityLtcgNoIdx = 0;
  double totalStt = 0;

  List<double> eqStcgQ = [];
  List<double> eqLtcgQ = [];
  List<double> neStcgQ = [];

  List<_CamsTaxTxn> transactions = [];
  List<Map<String, dynamic>> schemeBreakdowns = [];

  double get totalGain =>
      equityStcg +
      equityLtcgWithIdx +
      equityLtcgNoIdx +
      nonEquityStcg +
      nonEquityLtcgWithIdx +
      nonEquityLtcgNoIdx;
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _MatchedBanner extends StatelessWidget {
  const _MatchedBanner({
    required this.pan,
    required this.memberName,
    this.cellRef,
  });
  final String pan;
  final String memberName;
  final String? cellRef;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.gain.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.gain.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: context.palette.gain, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Matched to: $memberName',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'PAN: $pan${cellRef != null ? '  ($cellRef)' : ''}',
                  style: TextStyle(
                      fontSize: 12, color: context.palette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnmatchedBanner extends StatelessWidget {
  const _UnmatchedBanner({required this.pan, this.cellRef});
  final String pan;
  final String? cellRef;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_add_alt_1,
              color: Colors.orange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No member found with PAN: $pan',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.orange,
                  ),
                ),
                if (cellRef != null)
                  Text(
                    'Detected at $cellRef',
                    style: TextStyle(
                        fontSize: 11, color: context.palette.textTertiary),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Add them as a new member below to proceed with import.',
                  style: TextStyle(
                      fontSize: 12, color: context.palette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewMemberForm extends StatelessWidget {
  const _NewMemberForm({
    required this.pan,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.mobileCtrl,
    required this.relationship,
    required this.existingMembers,
    required this.onRelationshipChanged,
    required this.onSave,
    required this.saving,
  });

  final String pan;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController mobileCtrl;
  final String relationship;
  final List<FamilyMemberModel> existingMembers;
  final ValueChanged<String?> onRelationshipChanged;
  final VoidCallback onSave;
  final bool saving;

  static const _relationships = [
    'Self', 'Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'HUF', 'Other',
  ];
  static const _uniqueRelationships = {'Self', 'Spouse'};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.bgDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add New Member',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: pan,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'PAN',
              isDense: true,
              suffixIcon: Icon(Icons.lock_outline, size: 16),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name *',
              hintText: 'e.g. Rahul Sharma',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: mobileCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: relationship,
            decoration: const InputDecoration(
              labelText: 'Relationship *',
              isDense: true,
            ),
            items: _relationships.map((r) {
              final taken = _uniqueRelationships.contains(r) &&
                  existingMembers.any((m) => m.relationship == r);
              return DropdownMenuItem(
                value: r,
                enabled: !taken,
                child: Text(
                  taken ? '$r (already added)' : r,
                  style: TextStyle(
                      color: taken ? context.palette.textTertiary : null),
                ),
              );
            }).toList(),
            onChanged: onRelationshipChanged,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.person_add, size: 18),
              label: Text(saving ? 'Saving...' : 'Add Member & Continue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CamsTaxResultCard extends StatelessWidget {
  const _CamsTaxResultCard({required this.data, this.memberName});
  final _CamsTaxData data;
  final String? memberName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${data.source == 'mfc' ? 'MF Central' : 'CAMS'} Tax Statement — ${data.financialYear}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (memberName != null)
                _Row('Member', '$memberName (${data.pan})'),
              if (data.periodStr != null)
                _Row('Period', data.periodStr!),
              _Row('Lot matches', '${data.transactions.length}'),
              if (data.source == 'cams')
                _Row('STT paid',
                    '\u20b9${data.totalStt.toStringAsFixed(2)}'),
              const Divider(height: 16),
              Text(
                  data.source == 'mfc'
                      ? 'ALL FUNDS (Combined)'
                      : 'EQUITY',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
              if (data.source == 'mfc')
                Text(
                  'MF Central provides combined totals across all fund types.',
                  style: TextStyle(
                      fontSize: 10, color: context.palette.textTertiary),
                ),
              _Row(
                  'Short Term CG',
                  '\u20b9${data.equityStcg.toStringAsFixed(2)}',
                  color: data.equityStcg > 0
                      ? context.palette.gain
                      : context.palette.textSecondary),
              _Row(
                  'Long Term CG (w/o indexation)',
                  '\u20b9${data.equityLtcgNoIdx.toStringAsFixed(2)}',
                  color: data.equityLtcgNoIdx > 0
                      ? context.palette.gain
                      : context.palette.textSecondary),
              if (data.equityLtcgWithIdx > 0)
                _Row('Long Term CG (with indexation)',
                    '\u20b9${data.equityLtcgWithIdx.toStringAsFixed(2)}'),
              if (data.source == 'cams' &&
                  (data.nonEquityStcg != 0 ||
                      data.nonEquityLtcgWithIdx != 0 ||
                      data.nonEquityLtcgNoIdx != 0)) ...[
                const Divider(height: 16),
                Text('NON-EQUITY (Debt / Gold / FoF)',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.chartColors[4])),
                _Row(
                    'Short Term CG',
                    '\u20b9${data.nonEquityStcg.toStringAsFixed(2)}',
                    color: data.nonEquityStcg > 0
                        ? context.palette.gain
                        : context.palette.textSecondary),
                if (data.nonEquityLtcgNoIdx > 0)
                  _Row('Long Term CG',
                      '\u20b9${data.nonEquityLtcgNoIdx.toStringAsFixed(2)}'),
              ],
              const Divider(height: 16),
              _Row(
                  'Total Realized Gain',
                  '\u20b9${data.totalGain.toStringAsFixed(2)}',
                  color: data.totalGain > 0
                      ? context.palette.gain
                      : context.palette.loss),
            ],
          ),
        ),

        // ── Per-scheme breakdown
        if (data.schemeBreakdowns.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.palette.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.palette.bgDivider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Per-Scheme Breakdown',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                ...data.schemeBreakdowns.map((s) {
                  final scheme =
                      (s['scheme'] as String? ?? '').length > 50
                          ? '${(s['scheme'] as String).substring(0, 50)}...'
                          : s['scheme'] as String? ?? '';
                  final stcg =
                      (s['short_term'] as num?)?.toDouble() ?? 0;
                  final ltcg =
                      ((s['lt_with_idx'] as num?)?.toDouble() ??
                              0) +
                          ((s['lt_no_idx'] as num?)?.toDouble() ?? 0);
                  final total = stcg + ltcg;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scheme,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (stcg != 0)
                              Text(
                                  'STCG: \u20b9${stcg.toStringAsFixed(0)} ',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: stcg > 0
                                          ? context.palette.gain
                                          : context.palette.loss)),
                            if (ltcg != 0)
                              Text(
                                  'LTCG: \u20b9${ltcg.toStringAsFixed(0)} ',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: ltcg > 0
                                          ? context.palette.gain
                                          : context.palette.loss)),
                            const Spacer(),
                            Text(
                              'Total: \u20b9${total.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: total > 0
                                    ? context.palette.gain
                                    : context.palette.loss,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: context.palette.textSecondary)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color ?? context.palette.textPrimary)),
        ],
      ),
    );
  }
}

// ─── AIS Result Card ──────────────────────────────────────────────────────

class _AisResultCard extends StatelessWidget {
  const _AisResultCard({required this.data});
  final Map<String, dynamic> data;

  String _fmt(num? v) {
    if (v == null) return '0';
    if (v.abs() >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final gains = data['gains'] as Map<String, dynamic>? ?? {};
    final stockGains = gains['stock'] as Map<String, dynamic>? ?? {};
    final eqMfGains = gains['equity_mf'] as Map<String, dynamic>? ?? {};
    final debtMfGains = gains['debt_mf'] as Map<String, dynamic>? ?? {};

    final totalGain = (data['total_gain'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.gain.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.gain.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: context.palette.gain),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AIS Imported — ${data['financial_year'] ?? ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.palette.gain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Counts
          _row(context, 'Stock sales', '${data['stock_sales'] ?? 0}'),
          _row(context, 'Equity MF sales', '${data['equity_mf_sales'] ?? 0}'),
          _row(context, 'Debt MF sales', '${data['debt_mf_sales'] ?? 0}'),
          _row(context, 'MF purchases', '${data['mf_purchases'] ?? 0}'),

          const Divider(height: 16),

          // Gains
          if ((stockGains['stcg'] as num?) != null)
            _row(context, 'Stock STCG', '\u20b9${_fmt(stockGains['stcg'])}',
                color: (stockGains['stcg'] as num) >= 0
                    ? context.palette.gain
                    : context.palette.loss),
          if ((stockGains['ltcg'] as num?) != null)
            _row(context, 'Stock LTCG', '\u20b9${_fmt(stockGains['ltcg'])}',
                color: (stockGains['ltcg'] as num) >= 0
                    ? context.palette.gain
                    : context.palette.loss),
          if ((eqMfGains['stcg'] as num?) != null)
            _row(context, 'Equity MF STCG', '\u20b9${_fmt(eqMfGains['stcg'])}',
                color: (eqMfGains['stcg'] as num) >= 0
                    ? context.palette.gain
                    : context.palette.loss),
          if ((eqMfGains['ltcg'] as num?) != null)
            _row(context, 'Equity MF LTCG', '\u20b9${_fmt(eqMfGains['ltcg'])}',
                color: (eqMfGains['ltcg'] as num) >= 0
                    ? context.palette.gain
                    : context.palette.loss),
          if ((debtMfGains['stcg'] as num?) != null)
            _row(context, 'Debt MF STCG', '\u20b9${_fmt(debtMfGains['stcg'])}'),
          if ((debtMfGains['ltcg'] as num?) != null)
            _row(context, 'Debt MF LTCG', '\u20b9${_fmt(debtMfGains['ltcg'])}'),

          const Divider(height: 16),
          _row(context, 'Total Gain', '\u20b9${_fmt(totalGain)}',
              color: totalGain >= 0 ? context.palette.gain : context.palette.loss),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: context.palette.textSecondary)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color ?? context.palette.textPrimary)),
        ],
      ),
    );
  }
}
