import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/family_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/reconciliation_provider.dart';
import '../../router/route_names.dart';

// ─── Data extracted from XLSX metadata rows ─────────────────────────────────
class _XlsxMemberInfo {
  String? pan;
  String? name;
  String? email;
  String? mobile;
  String? panCellRef; // e.g. "Row 3, Col B"

  @override
  String toString() =>
      'PAN=$pan ($panCellRef), Name=$name, Email=$email, Mobile=$mobile';
}

class UploadMfCentralScreen extends ConsumerStatefulWidget {
  const UploadMfCentralScreen({super.key});

  @override
  ConsumerState<UploadMfCentralScreen> createState() =>
      _UploadMfCentralScreenState();
}

class _UploadMfCentralScreenState
    extends ConsumerState<UploadMfCentralScreen> {
  _UploadState _state = _UploadState.idle;
  String? _fileName;
  Uint8List? _fileBytes;
  _ImportResult? _result;
  String? _error;

  // CAMS PDF state
  bool _isCAMSPdf = false;
  final _passwordCtrl = TextEditingController();


  // Auto-match state
  _XlsxMemberInfo? _xlsxInfo;
  FamilyMemberModel? _matchedMember;
  bool _panDetectionDone = false;

  // New member form state (shown when PAN unmatched)
  bool _showNewMemberForm = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  String _relationship = 'Other';
  bool _savingMember = false;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  static const int _maxUploadBytes = 20 * 1024 * 1024; // 20 MB

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
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
      _result = null;
      _error = null;
      _xlsxInfo = null;
      _matchedMember = null;
      _panDetectionDone = true;
      _showNewMemberForm = false;
      _isCAMSPdf = true;
      _passwordCtrl.clear();
    });
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

      // Refresh members provider
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

  Future<void> _clearImportedTransactions() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final memberId = _matchedMember?.id;
    final memberName = _matchedMember?.displayName ?? 'this member';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Imported Transactions'),
        content: Text(
          memberId != null
              ? 'This will delete all transactions for $memberName. '
                'Other members\u2019 data will not be affected.\n\n'
                'You can re-import them later. Are you sure?'
              : 'This will delete all transactions from this import. '
                'Are you sure?',
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
      if (memberId != null) {
        await client
            .from('transactions')
            .delete()
            .eq('owner_id', userId)
            .eq('member_id', memberId);
      } else {
        // Fallback: delete only transactions with null member_id for this owner
        await client
            .from('transactions')
            .delete()
            .eq('owner_id', userId)
            .isFilter('member_id', null);
      }

      ref.invalidate(allTransactionsProvider);
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(latestNavMapProvider);

      setState(() {
        _result = null;
        _state = _UploadState.idle;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transactions for $memberName cleared'),
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

  Future<void> _upload() async {
    if (_fileBytes == null || _fileName == null) return;

    setState(() {
      _state = _UploadState.uploading;
      _error = null;
    });

    try {
      final client = ref.read(supabaseClientProvider);

      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Not authenticated');

      final familyAsync = ref.read(familyProvider);
      final familyId = familyAsync.valueOrNull?.id;

      final batchRes = await client.from('import_batches').insert({
        'owner_id': userId,
        'file_name': _fileName,
        'status': 'processing',
      }).select('id').single();

      final batchId = batchRes['id'] as String;

      // CAMS CAS PDF → send raw bytes + password, server handles decryption.
      // functions.invoke() automatically attaches the authenticated user's JWT
      // as the Authorization header; the edge function verifies it and derives
      // owner_id from the JWT, so we do NOT send owner_id from the client.
      final fileBase64 = base64Encode(_fileBytes!);
      final response = await client.functions.invoke(
        'parse-cams-cas-pdf',
        body: {
          'batch_id': batchId,
          'family_id': familyId,
          'fallback_member_id': _matchedMember?.id,
          'file_base64': fileBase64,
          'password': _passwordCtrl.text.trim(),
        },
      );

      if (response.data == null) {
        throw Exception('Empty response from function');
      }

      final data = response.data as Map<String, dynamic>;
      if (data['error'] != null) throw Exception(data['error']);

      // ── Import ABORTED — PAN didn't match ──────────────────────────
      if (data['aborted'] == true) {
        final unmatchedPans =
            (data['unmatched_pan_values'] as List?)?.cast<String>() ?? [];
        final total = data['total'] as int? ?? 0;
        final pInfo = data['personal_info'] as Map<String, dynamic>?;

        // Extract personal info from the PDF response and show new member form
        final detectedPanValue = unmatchedPans.isNotEmpty
            ? unmatchedPans.first
            : (pInfo?['pan'] as String? ?? '');

        if (detectedPanValue.isNotEmpty) {
          // Pre-fill the new member form with personal info from the PDF
          final info = _XlsxMemberInfo();
          info.pan = detectedPanValue.toUpperCase();
          info.name = pInfo?['name'] as String? ?? '';
          info.email = pInfo?['email'] as String? ?? '';
          info.mobile = pInfo?['mobile'] as String? ?? '';

          _nameCtrl.text = info.name ?? '';
          _emailCtrl.text = info.email ?? '';
          _mobileCtrl.text = info.mobile ?? '';

          // Smart default: Self if none exists, otherwise Other
          final existingMembers =
              ref.read(familyMembersProvider).valueOrNull ?? [];
          final hasSelf =
              existingMembers.any((m) => m.relationship == 'Self');
          _relationship = hasSelf ? 'Other' : 'Self';

          setState(() {
            _state = _UploadState.picked;
            _result = null;
            _xlsxInfo = info;
            _panDetectionDone = true;
            _showNewMemberForm = true;
            _matchedMember = null;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$total transactions found. Add ${info.name ?? detectedPanValue} as a family member to import.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          // No PAN detected at all
          setState(() {
            _state = _UploadState.picked;
            _result = null;
          });

          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Import Skipped'),
              content: Text(
                '$total transaction${total == 1 ? '' : 's'} were NOT imported.\n\n'
                'Could not detect PAN from the PDF. Please add the member manually first.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // ── Successful import ─────────────────────────────────────────
      final importResult = _ImportResult(
        inserted: data['inserted'] as int? ?? 0,
        duplicates: data['duplicates'] as int? ?? 0,
        total: data['total'] as int? ?? 0,
        errors: (data['errors'] as List?)?.cast<String>() ?? [],
        validation: (data['validation'] as List?)
            ?.map((v) => Map<String, dynamic>.from(v as Map))
            .toList() ?? [],
        corrections: (data['corrections'] as List?)?.cast<String>() ?? [],
        partialHistoryFunds: (data['partial_history_funds'] as List?)
            ?.map((v) => Map<String, dynamic>.from(v as Map))
            .toList() ?? [],
        // CAMS-specific
        isCAMS: _isCAMSPdf,
        foliosParsed: data['folios_parsed'] as int? ?? 0,
        folioDetailsUpserted: data['folio_details_upserted'] as int? ?? 0,
        sttTotal: (data['stt_total'] as num?)?.toDouble() ?? 0,
        stampDutyTotal: (data['stamp_duty_total'] as num?)?.toDouble() ?? 0,
        personalInfo: data['personal_info'] as Map<String, dynamic>?,
        memberUpdated: data['member_updated'] as Map<String, dynamic>?,
        portfolioSummaryMatch: data['portfolio_summary_match'] as bool?,
        debugRawText: data['_debug_raw_text_sample'] as String?,
        isinSuggestions: (data['isin_suggestions'] as List?)
            ?.map((v) => Map<String, dynamic>.from(v as Map))
            .toList() ?? [],
      );

      ref.invalidate(allTransactionsProvider);
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(latestNavMapProvider);
      ref.invalidate(folioDetailsProvider);
      ref.invalidate(reconciliationProvider);

      setState(() {
        _state = _UploadState.done;
        _result = importResult;
      });

      if (!mounted) return;

      final msg = importResult.inserted > 0
          ? '${importResult.inserted} transaction${importResult.inserted == 1 ? '' : 's'} imported'
              '${importResult.duplicates > 0 ? ', ${importResult.duplicates} duplicates skipped' : ''}'
          : importResult.duplicates > 0
              ? 'All ${importResult.duplicates} transactions already imported (duplicates)'
              : 'No transactions found in file';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor:
              importResult.inserted > 0 ? context.palette.gain : context.palette.textSecondary,
          duration: const Duration(seconds: 4),
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
          content: Text('Import failed: $e'),
          backgroundColor: context.palette.loss,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _showIsinSuggestionDialog() async {
    final suggestions = _result?.isinSuggestions ?? [];
    if (suggestions.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_fix_high, color: Colors.orange.shade700, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('ISIN Suggestions', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${suggestions.fold<int>(0, (s, e) => s + (e['tx_count'] as int? ?? 0))} transactions across '
                '${suggestions.length} folio(s) have no ISIN in the CAS PDF. '
                'We found potential matches by scheme name:',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 20),
                  itemBuilder: (_, i) {
                    final s = suggestions[i];
                    final score = s['match_score'] as int? ?? 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Folio ${s['folio_number']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12,
                            color: context.palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s['scheme_name']}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${s['suggested_fund_name']}',
                                style: const TextStyle(fontSize: 12, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: score >= 80
                                    ? context.palette.gain.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Match: $score%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: score >= 80 ? context.palette.gain : Colors.orange.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ISIN: ${s['suggested_isin']}',
                              style: TextStyle(
                                fontSize: 11, color: context.palette.textTertiary,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${s['tx_count']} txns',
                              style: TextStyle(fontSize: 11, color: context.palette.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Skip'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _applyIsinSuggestions(suggestions);
  }

  Future<void> _applyIsinSuggestions(List<Map<String, dynamic>> suggestions) async {
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    int updated = 0;
    final errors = <String>[];

    for (final s in suggestions) {
      final folioNumber = s['folio_number'] as String?;
      final suggestedIsin = s['suggested_isin'] as String?;
      final suggestedAmfiCode = s['suggested_amfi_code'] as int?;
      if (folioNumber == null || suggestedIsin == null || suggestedAmfiCode == null) continue;

      try {
        // Update transactions: set isin + amfi_code where folio matches and isin is null
        final res = await client
            .from('transactions')
            .update({
              'isin': suggestedIsin,
              'amfi_code': suggestedAmfiCode,
            })
            .eq('owner_id', userId)
            .eq('folio_number', folioNumber)
            .isFilter('isin', null)
            .eq('asset_type', 'MF')
            .select('id');
        updated += (res as List).length;

        // Also update folio_details
        await client
            .from('folio_details')
            .update({'isin': suggestedIsin})
            .eq('owner_id', userId)
            .eq('folio_number', folioNumber)
            .or('isin.is.null,isin.eq.');
      } catch (e) {
        errors.add('Folio $folioNumber: $e');
      }
    }

    // Refresh providers
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(portfolioSummaryProvider);
    ref.invalidate(folioDetailsProvider);
    ref.invalidate(reconciliationProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errors.isEmpty
              ? '$updated transactions updated with ISIN mappings'
              : '$updated updated, ${errors.length} errors',
        ),
        backgroundColor: errors.isEmpty ? context.palette.gain : Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  bool get _canImport {
    if (_fileBytes == null || _state == _UploadState.uploading) return false;
    // CAMS PDF requires password
    if (_isCAMSPdf && _passwordCtrl.text.trim().isEmpty) return false;
    // If PAN detected but no member matched yet → block import
    // (for both Excel pre-detection and CAMS PDF post-abort detection)
    if (_panDetectionDone &&
        _xlsxInfo?.pan != null &&
        _matchedMember == null) {
      return false;
    }
    return true;
  }

  /// Route import to appropriate handler
  Future<void> _handleImport() {
    return _upload();
  }

  @override
  Widget build(BuildContext context) {
    final detectedPan = _xlsxInfo?.pan;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload CAMS CAS PDF')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Info card ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(
                'Upload your CAMS CAS PDF for full transaction history from inception.\n'
                'Includes ISINs, nominees, exit loads, STT & stamp duty.',
                style: TextStyle(fontSize: 13, color: context.palette.textSecondary),
              ),
            ),
            const SizedBox(height: 20),

            // ── File pick zone ────────────────────────────────────────────
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(
                            _fileBytes != null
                                ? '${(_fileBytes!.length / 1024).toStringAsFixed(1)} KB'
                                : '',
                            style: TextStyle(
                                fontSize: 12, color: context.palette.textTertiary),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 36, color: context.palette.textTertiary),
                          SizedBox(height: 8),
                          Text('Tap to select file',
                              style:
                                  TextStyle(color: context.palette.textSecondary)),
                          SizedBox(height: 4),
                          Text('CAMS CAS .pdf',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.palette.textTertiary)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // ── PAN matched banner ────────────────────────────────────────
            if (_panDetectionDone && detectedPan != null && _matchedMember != null)
              _MatchedBanner(
                pan: detectedPan,
                memberName: _matchedMember!.displayName,
                cellRef: _xlsxInfo?.panCellRef,
              ),

            // ── PAN unmatched — new member form ───────────────────────────
            if (_panDetectionDone &&
                detectedPan != null &&
                _matchedMember == null &&
                _showNewMemberForm) ...[
              _UnmatchedBanner(pan: detectedPan, cellRef: _xlsxInfo?.panCellRef),
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

            // ── CAMS PDF password field ────────────────────────────────
            if (_isCAMSPdf && _fileName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.picture_as_pdf, size: 18, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          'CAMS CAS PDF Detected',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Full transaction history from inception with ISINs, nominees, exit loads, STT & stamp duty.',
                      style: TextStyle(fontSize: 11, color: context.palette.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'PDF Password',
                        hintText: 'Enter CAMS CAS password',
                        isDense: true,
                        prefixIcon: Icon(Icons.lock_outline, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Import button ─────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _canImport ? _handleImport : null,
              icon: _state == _UploadState.uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.upload),
              label: Text(_state == _UploadState.uploading
                  ? 'Importing...'
                  : 'Import Transactions'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),

            const SizedBox(height: 20),

            // ── Result ────────────────────────────────────────────────────
            if (_state == _UploadState.done && _result != null) ...[
              // Validation warning banner
              if (_result!.validation.any((v) => v['match'] != true))
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.palette.loss.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.palette.loss.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: context.palette.loss, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_result!.validation.where((v) => v['match'] != true).length} folio(s) have unit balance discrepancies. '
                          'Check the validation details below — a re-upload with a newer CAS may fix this.',
                          style: TextStyle(fontSize: 12, color: context.palette.loss, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              // ── ISIN suggestion banner ──────────────────────────────
              if (_result!.isinSuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_fix_high, color: Colors.orange.shade700, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_result!.isinSuggestions.fold<int>(0, (s, e) => s + (e['tx_count'] as int? ?? 0))} transactions missing ISIN',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'We found potential matches by scheme name. Review and confirm to fix.',
                              style: TextStyle(fontSize: 11, color: Colors.orange.shade700, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _showIsinSuggestionDialog,
                        child: const Text('Review & Fix'),
                      ),
                    ],
                  ),
                ),
              _ResultCard(
                result: _result!,
                memberName: _matchedMember?.displayName,
                pan: detectedPan,
              ),
              const SizedBox(height: 12),
              // ── Reconciliation card ────────────────────────────────────
              Consumer(builder: (context, ref, _) {
                final reconAsync = ref.watch(reconciliationProvider);
                return reconAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (recon) {
                    if (recon.items.isEmpty && recon.unmatchedFolios.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _ReconciliationCard(recon: recon);
                  },
                );
              }),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.go(Routes.transactions),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('View Transactions'),
              ),
            ],

            if (_state == _UploadState.error && _error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.palette.loss.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.palette.loss.withOpacity(0.3)),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: context.palette.loss, fontSize: 13, height: 1.5),
                ),
              ),

            const SizedBox(height: 32),

            // ── Clear data ────────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: _clearImportedTransactions,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(
                _matchedMember != null
                    ? 'Clear ${_matchedMember!.displayName} Transactions'
                    : 'Clear Imported Transactions',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.palette.loss,
                side: BorderSide(color: context.palette.loss.withOpacity(0.4)),
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

class _ImportResult {
  const _ImportResult({
    required this.inserted,
    required this.duplicates,
    required this.total,
    required this.errors,
    this.validation = const [],
    this.corrections = const [],
    this.partialHistoryFunds = const [],
    this.isCAMS = false,
    this.foliosParsed = 0,
    this.folioDetailsUpserted = 0,
    this.sttTotal = 0,
    this.stampDutyTotal = 0,
    this.personalInfo,
    this.memberUpdated,
    this.portfolioSummaryMatch,
    this.debugRawText,
    this.isinSuggestions = const [],
  });
  final int inserted;
  final int duplicates;
  final int total;
  final List<String> errors;
  final List<Map<String, dynamic>> validation;
  final List<String> corrections;
  final List<Map<String, dynamic>> partialHistoryFunds;
  // CAMS-specific
  final bool isCAMS;
  final int foliosParsed;
  final int folioDetailsUpserted;
  final double sttTotal;
  final double stampDutyTotal;
  final Map<String, dynamic>? personalInfo;
  final Map<String, dynamic>? memberUpdated;
  final bool? portfolioSummaryMatch;
  final String? debugRawText;
  final List<Map<String, dynamic>> isinSuggestions;
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

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
          const Icon(Icons.person_add_alt_1, color: Colors.orange, size: 22),
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
    'Self',
    'Spouse',
    'Son',
    'Daughter',
    'Father',
    'Mother',
    'HUF',
    'Other',
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
          const Text(
            'Add New Member',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 14),

          // PAN — read-only
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

          // Name
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

          // Email
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Mobile
          TextFormField(
            controller: mobileCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Relationship
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

          // Save button
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    this.memberName,
    this.pan,
  });
  final _ImportResult result;
  final String? memberName;
  final String? pan;

  @override
  Widget build(BuildContext context) {
    final matched = result.validation.where((v) => v['match'] == true).length;
    final mismatched = result.validation.where((v) => v['match'] != true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Import summary ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.palette.gain.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.palette.gain.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Import Complete',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: context.palette.gain)),
              const SizedBox(height: 10),
              if (memberName != null)
                _Row('Member', '$memberName${pan != null ? ' ($pan)' : ''}'),
              _Row('Total parsed', '${result.total}'),
              _Row('Inserted', '${result.inserted}', color: context.palette.gain),
              if (result.duplicates > 0)
                _Row('Duplicates skipped', '${result.duplicates}',
                    color: context.palette.textTertiary),
              if (result.errors.isNotEmpty) ...[
                _Row('Errors', '${result.errors.length}', color: context.palette.loss),
                const SizedBox(height: 6),
                ...result.errors
                    .take(5)
                    .map((e) => Text('• $e',
                        style:
                            TextStyle(fontSize: 11, color: context.palette.loss))),
              ],
              if (result.isCAMS) ...[
                const Divider(height: 16),
                _Row('Folios parsed', '${result.foliosParsed}'),
                _Row('Folio details saved', '${result.folioDetailsUpserted}'),
                if (result.sttTotal > 0)
                  _Row('Total STT', '\u20b9${result.sttTotal.toStringAsFixed(2)}'),
                if (result.stampDutyTotal > 0)
                  _Row('Total Stamp Duty', '\u20b9${result.stampDutyTotal.toStringAsFixed(2)}'),
                if (result.portfolioSummaryMatch != null)
                  _Row(
                    'Portfolio summary',
                    result.portfolioSummaryMatch! ? 'Matched' : 'Mismatch',
                    color: result.portfolioSummaryMatch! ? context.palette.gain : context.palette.loss,
                  ),
              ],
            ],
          ),
        ),

        // ── CAMS: Member info updated ─────────────────────────────────
        if (result.isCAMS && result.memberUpdated != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.deepPurple),
                    SizedBox(width: 6),
                    Text(
                      'Member Details Updated',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (result.personalInfo?['name'] != null)
                  _Row('Name', result.personalInfo!['name'].toString()),
                if (result.memberUpdated?['email'] != null)
                  _Row('Email', result.memberUpdated!['email'].toString()),
                if (result.memberUpdated?['mobile'] != null)
                  _Row('Mobile', result.memberUpdated!['mobile'].toString()),
                if (result.memberUpdated?['address'] != null)
                  _Row('Address', result.memberUpdated!['address'].toString()),
              ],
            ),
          ),
        ],

        // ── Auto-corrections ──────────────────────────────────────────
        if (result.corrections.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_fix_high, size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      '${result.corrections.length} Auto-Correction${result.corrections.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...result.corrections.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $c',
                      style: TextStyle(fontSize: 11, color: context.palette.textSecondary)),
                )),
              ],
            ),
          ),
        ],

        // ── Partial history (Opening Balance) info ─────────────────────
        if (result.partialHistoryFunds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${result.partialHistoryFunds.length} fund${result.partialHistoryFunds.length == 1 ? '' : 's'} with pre-CAS history',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'These funds have purchases before the CAS date range (Jan 2023). Opening Balance transactions were created to match your CAS portfolio invested values.',
                  style: TextStyle(fontSize: 11, color: context.palette.textSecondary),
                ),
                const SizedBox(height: 8),
                ...result.partialHistoryFunds.map((f) {
                  final scheme = f['scheme'] as String? ?? '';
                  final gap = f['invested_gap'] as num? ?? 0;
                  final unitsGap = f['units_gap'] as num? ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $scheme — \u20b9${gap.toStringAsFixed(0)} invested, ${unitsGap.toStringAsFixed(4)} units',
                      style: TextStyle(fontSize: 11, color: context.palette.textSecondary),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // ── Portfolio validation ───────────────────────────────────────
        if (result.validation.isNotEmpty) ...[
          const SizedBox(height: 12),
          _PortfolioValidationCard(
            validation: result.validation,
            matched: matched,
            mismatched: mismatched,
          ),
        ],

        // ── DEBUG: Raw text sample ──────────────────────────────────────
        if (result.debugRawText != null && result.debugRawText!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DEBUG: Raw PDF Text (first 2000 chars)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                SelectableText(
                  result.debugRawText!,
                  style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: context.palette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Portfolio Validation Card (per-folio CAMS vs computed units) ────────────
class _PortfolioValidationCard extends StatelessWidget {
  const _PortfolioValidationCard({
    required this.validation,
    required this.matched,
    required this.mismatched,
  });

  final List<Map<String, dynamic>> validation;
  final int matched;
  final int mismatched;

  @override
  Widget build(BuildContext context) {
    final allMatch = mismatched == 0;
    final mismatches = validation.where((v) => v['match'] != true).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: allMatch
            ? context.palette.gain.withOpacity(0.08)
            : context.palette.loss.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allMatch
              ? context.palette.gain.withOpacity(0.3)
              : context.palette.loss.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Icon(
                allMatch ? Icons.verified : Icons.warning_amber_rounded,
                size: 18,
                color: allMatch ? context.palette.gain : context.palette.loss,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  allMatch
                      ? 'CAMS Statement Validation: All $matched funds match'
                      : 'CAMS Statement Validation: $mismatched of ${validation.length} funds have discrepancies',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: allMatch ? context.palette.gain : context.palette.loss,
                  ),
                ),
              ),
            ],
          ),

          // ── Matched summary (collapsed) ──
          if (matched > 0 && mismatched > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$matched fund(s) matched CAMS closing units',
              style: TextStyle(fontSize: 11, color: context.palette.gain.withOpacity(0.8)),
            ),
          ],

          // ── Mismatch details ──
          if (mismatches.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.palette.bgCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discrepancies found:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...mismatches.map((v) {
                    final scheme = v['scheme'] as String? ?? 'Unknown';
                    final shortScheme = scheme.length > 45
                        ? '${scheme.substring(0, 45)}...'
                        : scheme;
                    final folio = v['folio'] as String? ?? '';
                    final expected = (v['expected_closing'] as num?)?.toDouble() ?? 0;
                    final computed = (v['computed_closing'] as num?)?.toDouble() ?? 0;
                    final diff = computed - expected;
                    final diffLabel = diff > 0
                        ? '+${diff.toStringAsFixed(3)}'
                        : diff.toStringAsFixed(3);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shortScheme,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _UnitLabel(
                                label: 'CAMS (registrar)',
                                value: expected.toStringAsFixed(3),
                                color: context.palette.textPrimary,
                              ),
                              const SizedBox(width: 16),
                              _UnitLabel(
                                label: 'Computed (txns)',
                                value: computed.toStringAsFixed(3),
                                color: context.palette.textSecondary,
                              ),
                              const SizedBox(width: 16),
                              _UnitLabel(
                                label: 'Diff',
                                value: '$diffLabel units',
                                color: context.palette.loss,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Folio: $folio',
                            style: TextStyle(
                              fontSize: 10,
                              color: context.palette.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 28,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Navigate to transactions list with scheme name pre-searched
                                final searchTerm = (scheme.split('-').first)
                                    .split('(').first
                                    .trim();
                                context.push(
                                  Routes.transactions,
                                  extra: {'search': searchTerm},
                                );
                              },
                              icon: const Icon(Icons.edit_note, size: 14),
                              label: const Text('Review Transactions'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.palette.loss,
                                side: BorderSide(
                                  color: context.palette.loss.withOpacity(0.4),
                                ),
                                textStyle: const TextStyle(fontSize: 11),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Guidance text ──
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to fix:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\u2022 Tap "Review Transactions" to see all transactions for that fund\n'
                    '\u2022 Check if any BUY, SELL, or Switch transactions are missing\n'
                    '\u2022 Add missing transactions manually, or\n'
                    '\u2022 Re-upload with a CAS PDF that covers the full history (request from CAMS/KFintech with "Since Inception" date range)',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.palette.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnitLabel extends StatelessWidget {
  const _UnitLabel({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9, color: context.palette.textTertiary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
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

// ─── Reconciliation card ─────────────────────────────────────────────────────
class _ReconciliationCard extends StatelessWidget {
  const _ReconciliationCard({required this.recon});
  final ReconciliationSummary recon;

  @override
  Widget build(BuildContext context) {
    final color = recon.allMatch ? context.palette.gain : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                recon.allMatch ? Icons.verified : Icons.compare_arrows,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reconciliation: ${recon.matchCount}/${recon.totalChecked} funds match registrar data',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (recon.mismatchCount > 0) ...[
            const SizedBox(height: 10),
            ...recon.items.where((i) => !i.isMatch).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, size: 14, color: context.palette.loss),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.schemeName.length > 45
                              ? '${item.schemeName.substring(0, 45)}...'
                              : item.schemeName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Folio: ${item.folioNumber} | CAMS: ${item.camsClosingUnits.toStringAsFixed(3)} | eVesh: ${item.computedUnits.toStringAsFixed(3)} (${item.unitsDiffPct.toStringAsFixed(1)}% off)',
                          style: TextStyle(fontSize: 10, color: context.palette.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
          if (recon.unmatchedFolios.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${recon.unmatchedFolios.length} folio(s) in CAMS with no matching transactions',
              style: const TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ],
        ],
      ),
    );
  }
}
