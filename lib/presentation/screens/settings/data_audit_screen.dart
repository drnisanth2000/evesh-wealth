import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/usecases/run_data_audit.dart';
import '../../providers/data_audit_provider.dart';

class DataAuditScreen extends ConsumerWidget {
  const DataAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(dataAuditProvider);

    return Scaffold(
      backgroundColor: context.palette.bgBase,
      appBar: AppBar(
        title: const Text('Data Audit'),
        backgroundColor: context.palette.bgCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dataAuditProvider),
            tooltip: 'Re-run audit',
          ),
        ],
      ),
      body: auditAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Running 8 integrity checks...',
                  style: TextStyle(color: context.palette.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error running audit: $e',
                style: TextStyle(color: context.palette.loss)),
          ),
        ),
        data: (report) => _AuditResults(report: report),
      ),
    );
  }
}

class _AuditResults extends StatelessWidget {
  const _AuditResults({required this.report});
  final DataAuditReport report;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Overall status banner ──
        _StatusBanner(report: report),
        const SizedBox(height: 16),

        // ── Individual checks ──
        ...report.checks.map((check) => _CheckCard(check: check)),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.report});
  final DataAuditReport report;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    final String label;

    if (report.allPassed) {
      bg = context.palette.gain.withValues(alpha: 0.1);
      fg = context.palette.gain;
      icon = Icons.check_circle;
      label = 'All ${report.checks.length} checks passed';
    } else if (report.errorCount > 0) {
      bg = context.palette.loss.withValues(alpha: 0.1);
      fg = context.palette.loss;
      icon = Icons.error;
      label = '${report.errorCount} error(s), ${report.warningCount} warning(s)';
    } else {
      bg = AppColors.warning.withValues(alpha: 0.1);
      fg = AppColors.warning;
      icon = Icons.warning_amber;
      label = '${report.warningCount} warning(s)';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
                const SizedBox(height: 2),
                Text(
                  'Run at ${_formatTime(report.runAt)} \u2022 ${report.totalIssues} issue(s)',
                  style: TextStyle(
                      fontSize: 11, color: context.palette.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}

class _CheckCard extends StatefulWidget {
  const _CheckCard({required this.check});
  final AuditCheckResult check;

  @override
  State<_CheckCard> createState() => _CheckCardState();
}

class _CheckCardState extends State<_CheckCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final check = widget.check;
    final Color statusColor;
    final IconData statusIcon;
    switch (check.severity) {
      case AuditSeverity.pass:
        statusColor = context.palette.gain;
        statusIcon = Icons.check_circle_outline;
      case AuditSeverity.warning:
        statusColor = AppColors.warning;
        statusIcon = Icons.warning_amber_outlined;
      case AuditSeverity.error:
        statusColor = context.palette.loss;
        statusIcon = Icons.error_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.palette.bgDivider),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: check.issues.isNotEmpty
                ? () => setState(() => _expanded = !_expanded)
                : null,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(check.checkName,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.palette.textPrimary)),
                        Text(check.description,
                            style: TextStyle(
                                fontSize: 10,
                                color: context.palette.textTertiary)),
                      ],
                    ),
                  ),
                  Text(
                    '${check.issuesFound}/${check.itemsChecked}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                  if (check.issues.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: context.palette.textTertiary,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expanded issue details
          if (_expanded && check.issues.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.palette.bgDivider)),
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: check.issues.take(20).map((issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.circle, size: 5,
                            color: context.palette.textTertiary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(issue.title,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: context.palette.textPrimary)),
                            Text(issue.detail,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: context.palette.textSecondary)),
                            if (issue.remedy != null)
                              Text(issue.remedy!,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
