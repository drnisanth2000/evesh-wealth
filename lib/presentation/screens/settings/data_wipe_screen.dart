import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/data_audit_provider.dart';
import '../../router/route_names.dart';

class DataWipeScreen extends ConsumerStatefulWidget {
  const DataWipeScreen({super.key});

  @override
  ConsumerState<DataWipeScreen> createState() => _DataWipeScreenState();
}

class _DataWipeScreenState extends ConsumerState<DataWipeScreen> {
  final _confirmController = TextEditingController();
  bool _wiping = false;
  Map<String, int>? _result;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewAsync = ref.watch(dataWipePreviewProvider);

    return Scaffold(
      backgroundColor: context.palette.bgBase,
      appBar: AppBar(
        title: const Text('Wipe & Re-Import'),
        backgroundColor: context.palette.bgCard,
      ),
      body: _result != null
          ? _buildSuccess(context)
          : previewAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Error: $e',
                  style: TextStyle(color: context.palette.loss))),
              data: (counts) => _buildPreview(context, counts),
            ),
    );
  }

  Widget _buildPreview(BuildContext context, Map<String, int> counts) {
    final total = counts.values.fold(0, (s, v) => s + v);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Warning banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.palette.loss.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.palette.loss.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber, color: context.palette.loss, size: 20),
                  SizedBox(width: 8),
                  Text('Destructive Operation',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.palette.loss)),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'This will permanently delete ALL your financial data including manually entered transactions (stocks, SGBs, FDs). '
                'MF transactions can be restored by re-importing CAS PDF. Manual entries must be re-entered.',
                style: TextStyle(fontSize: 12, color: context.palette.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Data counts
        Text('Data to be deleted:',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.palette.textPrimary)),
        const SizedBox(height: 10),

        _CountRow('Transactions', counts['transactions'] ?? 0, Icons.swap_horiz),
        _CountRow('Folio Details', counts['folio_details'] ?? 0, Icons.folder_outlined),
        _CountRow('Tax Statements', counts['cams_tax_statements'] ?? 0, Icons.receipt_long),
        if ((counts['import_batches'] ?? 0) > 0)
          _CountRow('Import Batches', counts['import_batches']!, Icons.cloud_upload_outlined),
        if ((counts['alert_log'] ?? 0) > 0)
          _CountRow('Alerts', counts['alert_log']!, Icons.notifications_outlined),
        if ((counts['other_assets'] ?? 0) > 0)
          _CountRow('Other Assets', counts['other_assets']!, Icons.account_balance_outlined),
        if ((counts['goals'] ?? 0) > 0)
          _CountRow('Goals', counts['goals']!, Icons.flag_outlined),
        if ((counts['duplicate_families'] ?? 0) > 0)
          _CountRow('Duplicate Families', counts['duplicate_families']!, Icons.group_remove),

        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.palette.bgCardElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.summarize_outlined,
                  size: 16, color: context.palette.textSecondary),
              const SizedBox(width: 8),
              Text('Total: $total records',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.palette.textPrimary)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Confirmation
        Text('Type DELETE to confirm:',
            style: TextStyle(fontSize: 12, color: context.palette.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmController,
          style: TextStyle(
              fontSize: 14, color: context.palette.textPrimary, letterSpacing: 2),
          decoration: InputDecoration(
            hintText: 'DELETE',
            hintStyle: TextStyle(
                color: context.palette.textTertiary.withValues(alpha: 0.3)),
            filled: true,
            fillColor: context.palette.bgSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.palette.bgDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.palette.bgDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.palette.loss),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _confirmController.text == 'DELETE' && !_wiping
                ? _executeWipe
                : null,
            icon: _wiping
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.delete_sweep),
            label: Text(_wiping ? 'Wiping data...' : 'Wipe All Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.loss,
              foregroundColor: Colors.white,
              disabledBackgroundColor: context.palette.bgSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 40),
        // Success icon
        Center(
          child: Icon(Icons.check_circle, color: context.palette.gain, size: 64),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text('Data wiped successfully',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textPrimary)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('All financial data has been deleted.',
              style: TextStyle(fontSize: 13, color: context.palette.textSecondary)),
        ),
        const SizedBox(height: 32),

        // Next steps
        Text('Next Steps:',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.palette.textPrimary)),
        const SizedBox(height: 12),

        _ActionButton(
          icon: Icons.upload_file,
          label: 'Step 1: Import CAS PDF',
          subtitle: 'Upload CAMS CAS statement to rebuild transactions',
          onTap: () => context.go(Routes.uploadMfCentral),
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.receipt_long,
          label: 'Step 2: Import Tax Statement',
          subtitle: 'Upload CAMS/MFC Tax XLSX for realized gains',
          onTap: () => context.go(Routes.uploadTax),
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.fact_check_outlined,
          label: 'Step 3: Run Data Audit',
          subtitle: 'Verify data integrity after import',
          onTap: () => context.go(Routes.dataAudit),
        ),
      ],
    );
  }

  Future<void> _executeWipe() async {
    setState(() => _wiping = true);
    try {
      final notifier = ref.read(dataWipeNotifierProvider.notifier);
      await notifier.execute();
      if (mounted) setState(() => _result = {'done': 1});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wipe failed: $e'),
              backgroundColor: context.palette.loss),
        );
        setState(() => _wiping = false);
      }
    }
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow(this.label, this.count, this.icon);
  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.palette.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.palette.bgDivider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: context.palette.textTertiary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12, color: context.palette.textSecondary)),
            ),
            Text('$count',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.palette.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.palette.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.palette.bgDivider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.palette.textPrimary)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 10, color: context.palette.textTertiary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: context.palette.textTertiary),
          ],
        ),
      ),
    );
  }
}
