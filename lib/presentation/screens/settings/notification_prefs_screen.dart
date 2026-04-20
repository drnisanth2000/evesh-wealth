import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/notification_prefs_provider.dart';

class NotificationPrefsScreen extends ConsumerWidget {
  const NotificationPrefsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPrefsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (prefs) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // ── 1. General ──────────────────────────────────────────────────
            _SectionCard(
              title: 'General',
              children: [
                SwitchListTile(
                  title: const Text('Email Alerts'),
                  value: prefs['email'] as bool? ?? true,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => ref
                      .read(notificationPrefsNotifierProvider.notifier)
                      .updatePref('email', val),
                ),
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  value: prefs['push'] as bool? ?? true,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => ref
                      .read(notificationPrefsNotifierProvider.notifier)
                      .updatePref('push', val),
                ),
              ],
            ),

            // ── 2. Alert Frequency ──────────────────────────────────────────
            _SectionCard(
              title: 'Alert Frequency',
              children: [
                _FrequencyRadio(
                  label: 'Instant',
                  value: 'instant',
                  groupValue: prefs['frequency'] as String? ?? 'daily',
                  onChanged: (val) => ref
                      .read(notificationPrefsNotifierProvider.notifier)
                      .updatePref('frequency', val),
                ),
                _FrequencyRadio(
                  label: 'Daily Digest',
                  value: 'daily',
                  groupValue: prefs['frequency'] as String? ?? 'daily',
                  onChanged: (val) => ref
                      .read(notificationPrefsNotifierProvider.notifier)
                      .updatePref('frequency', val),
                ),
                _FrequencyRadio(
                  label: 'Weekly Digest',
                  value: 'weekly',
                  groupValue: prefs['frequency'] as String? ?? 'daily',
                  onChanged: (val) => ref
                      .read(notificationPrefsNotifierProvider.notifier)
                      .updatePref('frequency', val),
                ),
                _FrequencyRadio(
                  label: 'Off',
                  value: 'off',
                  groupValue: prefs['frequency'] as String? ?? 'daily',
                  onChanged: (val) => ref
                      .read(notificationPrefsNotifierProvider.notifier)
                      .updatePref('frequency', val),
                ),
              ],
            ),

            // ── 3. Alert Types ──────────────────────────────────────────────
            _SectionCard(
              title: 'Alert Types',
              children: [
                _AlertToggle(
                  label: 'Stop-Loss Alerts',
                  prefKey: 'stop_loss',
                  prefs: prefs,
                  ref: ref,
                ),
                _AlertToggle(
                  label: 'Gain Harvest Alerts',
                  prefKey: 'gain_harvest',
                  prefs: prefs,
                  ref: ref,
                ),
                _AlertToggle(
                  label: 'Rebalance Drift',
                  prefKey: 'rebalance_drift',
                  prefs: prefs,
                  ref: ref,
                ),
                _AlertToggle(
                  label: 'SIP Reminders',
                  prefKey: 'sip_reminder',
                  prefs: prefs,
                  ref: ref,
                ),
                _AlertToggle(
                  label: 'NAV Drop Alerts',
                  prefKey: 'nav_drop',
                  prefs: prefs,
                  ref: ref,
                ),
                _AlertToggle(
                  label: 'Tax Harvest Alerts',
                  prefKey: 'ltcg_harvest',
                  prefs: prefs,
                  ref: ref,
                ),
                _AlertToggle(
                  label: 'Maturity Alerts',
                  prefKey: 'maturity_alert',
                  prefs: prefs,
                  ref: ref,
                ),
                _AlertToggle(
                  label: 'Price Target',
                  prefKey: 'price_target',
                  prefs: prefs,
                  ref: ref,
                ),
              ],
            ),

            // ── 4. Portfolio Reports ────────────────────────────────────────
            _SectionCard(
              title: 'Portfolio Reports',
              children: [
                SwitchListTile(
                  title: const Text('Weekly Report'),
                  subtitle: Text(
                    'Every Sunday 10:00 AM',
                    style: TextStyle(
                        fontSize: 12, color: context.palette.textSecondary),
                  ),
                  value: prefs['report_weekly'] as bool? ?? true,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => ref
                      .read(notificationPrefsNotifierProvider.notifier)
                      .updatePref('report_weekly', val),
                ),
                SwitchListTile(
                  title: const Text('Monthly Report'),
                  subtitle: Text(
                    '1st of every month',
                    style: TextStyle(
                        fontSize: 12, color: context.palette.textSecondary),
                  ),
                  value: prefs['report_monthly'] as bool? ?? true,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => ref
                      .read(notificationPrefsNotifierProvider.notifier)
                      .updatePref('report_monthly', val),
                ),
                SwitchListTile(
                  title: const Text('Yearly Report'),
                  subtitle: Text(
                    '1st January',
                    style: TextStyle(
                        fontSize: 12, color: context.palette.textSecondary),
                  ),
                  value: prefs['report_yearly'] as bool? ?? true,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => ref
                      .read(notificationPrefsNotifierProvider.notifier)
                      .updatePref('report_yearly', val),
                ),
                ListTile(
                  title: const Text('One-Time Report'),
                  trailing: ElevatedButton(
                    onPressed: () => _generateOneTimeReport(context),
                    child: const Text('Generate'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _generateOneTimeReport(BuildContext context) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'send-portfolio-report',
        body: {'report_type': 'onetime'},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generation started. Check your email shortly.'),
            backgroundColor: AppColors.gain,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: AppColors.loss,
          ),
        );
      }
    }
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: context.palette.textTertiary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _FrequencyRadio extends StatelessWidget {
  const _FrequencyRadio({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : context.palette.textTertiary,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: selected ? AppColors.primary : context.palette.textPrimary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertToggle extends StatelessWidget {
  const _AlertToggle({
    required this.label,
    required this.prefKey,
    required this.prefs,
    required this.ref,
  });
  final String label;
  final String prefKey;
  final Map<String, dynamic> prefs;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label),
      value: prefs[prefKey] as bool? ?? true,
      activeThumbColor: AppColors.primary,
      onChanged: (val) => ref
          .read(notificationPrefsNotifierProvider.notifier)
          .updatePref(prefKey, val),
    );
  }
}
