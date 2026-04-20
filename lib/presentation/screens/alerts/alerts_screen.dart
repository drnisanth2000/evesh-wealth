import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/alert_provider.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final notifier = ref.read(alertNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          TextButton(
            onPressed: notifier.markAllRead,
            child: const Text('Mark all read',
                style: TextStyle(
                    color: AppColors.primary, fontSize: 13)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(alertsProvider),
        child: alertsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (alerts) {
            if (alerts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none,
                        size: 56, color: context.palette.textTertiary),
                    SizedBox(height: 12),
                    Text('No alerts',
                        style: TextStyle(
                            color: context.palette.textSecondary,
                            fontSize: 16)),
                  ],
                ),
              );
            }

            // Group by severity
            final urgent =
                alerts.where((a) => a.severity == 'URGENT').toList();
            final medium =
                alerts.where((a) => a.severity == 'MEDIUM').toList();
            final low =
                alerts.where((a) => a.severity == 'LOW').toList();

            return ListView(
              children: [
                if (urgent.isNotEmpty) ...[
                  _GroupHeader('URGENT', AppColors.loss),
                  ...urgent.map((a) => _AlertTile(
                        alert: a,
                        onRead: () => notifier.markRead(a.id),
                      )),
                ],
                if (medium.isNotEmpty) ...[
                  _GroupHeader('MEDIUM', AppColors.warning),
                  ...medium.map((a) => _AlertTile(
                        alert: a,
                        onRead: () => notifier.markRead(a.id),
                      )),
                ],
                if (low.isNotEmpty) ...[
                  _GroupHeader('LOW', context.palette.textTertiary),
                  ...low.map((a) => _AlertTile(
                        alert: a,
                        onRead: () => notifier.markRead(a.id),
                      )),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert, required this.onRead});
  final AlertModel alert;
  final VoidCallback onRead;

  static Color _severityColor(BuildContext context, String severity) {
    switch (severity) {
      case 'URGENT':
        return AppColors.loss;
      case 'MEDIUM':
        return AppColors.warning;
      case 'LOW':
      default:
        return context.palette.textTertiary;
    }
  }

  static const _typeIcons = {
    'nav_drop': Icons.trending_down,
    'price_target': Icons.flag_outlined,
    'stoploss': Icons.warning_outlined,
    'rebalance_drift': Icons.balance,
    'ltcg_harvest': Icons.eco_outlined,
    'sip_reminder': Icons.repeat,
    'maturity_alert': Icons.schedule,
  };

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(context, alert.severity);
    final icon = _typeIcons[alert.alertType] ?? Icons.notifications_outlined;
    final isUnread = !alert.isRead;

    return InkWell(
      onTap: isUnread ? onRead : null,
      child: Container(
        color: isUnread
            ? AppColors.primary.withOpacity(0.04)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isUnread
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.body,
                    style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(alert.createdAt),
                    style: TextStyle(
                        fontSize: 10, color: context.palette.textTertiary),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM').format(dt);
  }
}
