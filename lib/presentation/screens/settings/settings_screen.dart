import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../services/export_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/reconciliation_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../../router/route_names.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.valueOrNull;
    final selfAsync = ref.watch(selfMemberProvider);
    final self = selfAsync.valueOrNull;
    final displayName = self?.displayName ?? profile?.fullName ?? 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Profile header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (self != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('CEO',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${profile?.subscriptionTier ?? 'free'} plan',
                        style: TextStyle(
                            fontSize: 12, color: context.palette.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (profile?.subscriptionTier ?? 'free').toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Appearance ────────────────────────────────────────────────
          _SettingsGroup(title: 'Appearance', tiles: const [
            _ThemeModePicker(),
          ]),

          // ── Account ───────────────────────────────────────────────────
          _SettingsGroup(title: 'Account', tiles: [
            _SettingsTile(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () => context.push(Routes.profile),
            ),
            _SettingsTile(
              icon: Icons.security,
              label: 'MFA / 2-Factor Auth',
              onTap: () => context.push(Routes.mfaEnroll),
            ),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              label: 'Notification Preferences',
              onTap: () => context.push(Routes.notificationPrefs),
            ),
          ]),

          // ── Family ─────────────────────────────────────────────────────
          _SettingsGroup(title: 'Family', tiles: [
            _SettingsTile(
              icon: Icons.people_outline,
              label: 'Family Members',
              onTap: () => context.push(Routes.familySetup),
            ),
            _SettingsTile(
              icon: Icons.tune,
              label: 'Allocation Targets',
              onTap: () => _showAllocationSheet(context, ref),
            ),
          ]),

          // ── Subscription ──────────────────────────────────────────────
          _SettingsGroup(title: 'Subscription', tiles: [
            _SettingsTile(
              icon: Icons.workspace_premium_outlined,
              label: 'Upgrade Plan',
              valueLabel: 'View plans',
              onTap: () => context.push(Routes.subscription),
            ),
            // Billing History tile intentionally omitted until Razorpay
            // integration ships (see memory/project_evesh_status.md).
          ]),

          // ── Data ──────────────────────────────────────────────────────
          _SettingsGroup(title: 'Data', tiles: [
            _SettingsTile(
              icon: Icons.upload_file,
              label: 'Import Transactions (CAS)',
              valueLabel: 'MF Central / CAMS',
              onTap: () => context.push(Routes.uploadMfCentral),
            ),
            _SettingsTile(
              icon: Icons.receipt_long,
              label: 'Import Tax Statement',
              valueLabel: 'CAMS / MF Central',
              onTap: () => context.push(Routes.uploadTax),
            ),
            _SettingsTile(
              icon: Icons.download_outlined,
              label: 'Export Portfolio (CSV)',
              valueLabel: 'Holdings + details',
              onTap: () => _showExportSheet(context, ref),
            ),
            _SettingsTile(
              icon: Icons.fact_check_outlined,
              label: 'Data Audit',
              valueLabel: 'Run integrity checks',
              onTap: () => context.push(Routes.dataAudit),
            ),
            _SettingsTile(
              icon: Icons.delete_sweep_outlined,
              label: 'Wipe & Re-Import',
              valueLabel: 'Clean slate',
              onTap: () => context.push(Routes.dataWipe),
            ),
          ]),

          // ── Admin ─────────────────────────────────────────────────────
          if (profile?.role == 'admin')
            _SettingsGroup(title: 'Admin', tiles: [
              _SettingsTile(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Admin Dashboard',
                onTap: () => context.push(Routes.admin),
              ),
            ]),

          // ── Sign out ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref
                    .read(authNotifierProvider.notifier)
                    .signOut();
              },
              icon: const Icon(Icons.logout, color: AppColors.loss),
              label: const Text('Sign Out',
                  style: TextStyle(color: AppColors.loss)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.loss),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Center(
            child: Text('eVesh Wealth Manager v1.0.0',
                style: TextStyle(
                    fontSize: 11, color: context.palette.textTertiary)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showExportSheet(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.read(familyMembersProvider);
    final members = membersAsync.valueOrNull ?? [];

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Export Portfolio',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Download a CSV with holdings, NAV, gains, nominees, exit load, KYC and more.',
              style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
            ),
            const SizedBox(height: 16),

            // "All Members" option
            _ExportOption(
              icon: Icons.group_outlined,
              label: 'All Members (Family)',
              onTap: () {
                Navigator.pop(context);
                _runExport(context, ref, null, 'All');
              },
            ),

            // Individual members
            ...members.map((m) => _ExportOption(
                  icon: Icons.person_outline,
                  label: m.displayName,
                  onTap: () {
                    Navigator.pop(context);
                    _runExport(context, ref, m.id, m.displayName);
                  },
                )),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _runExport(
    BuildContext context,
    WidgetRef ref,
    String? memberId,
    String memberName,
  ) async {
    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Preparing export...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final portfolio =
          await ref.read(portfolioSummaryProvider(memberId).future);
      final folios = await ref.read(folioDetailsProvider.future);

      ExportService.exportPortfolioCsv(
        holdings: portfolio.fundHoldings,
        folios: folios,
        memberName: memberName,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Exported ${portfolio.fundHoldings.length} funds for $memberName'),
            backgroundColor: AppColors.gain,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.loss,
          ),
        );
      }
    }
  }

  void _showAllocationSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Allocation Targets',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(
              'Configure target % for each asset class in the Rebalancing screen. '
              'Navigate to Rebalance → set your targets.',
              style: TextStyle(
                  fontSize: 13, color: context.palette.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(Routes.rebalance);
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('Go to Rebalance'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.tiles});
  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
        ...tiles,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.valueLabel,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (valueLabel != null)
            Text(valueLabel!,
                style: TextStyle(
                    fontSize: 12, color: context.palette.textTertiary)),
          Icon(Icons.chevron_right,
              size: 18, color: context.palette.textTertiary),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Segmented control for switching Light / Dark / System theme.
/// State is persisted to the `user_prefs` Hive box via `themeModeProvider`.
class _ThemeModePicker extends ConsumerWidget {
  const _ThemeModePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final options = <_ThemeOption>[
      _ThemeOption(ThemeMode.light, 'Light', Icons.light_mode_outlined),
      _ThemeOption(ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
      _ThemeOption(ThemeMode.system, 'System', Icons.brightness_auto_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Theme', style: TextStyle(fontSize: 14)),
          ),
          LayoutBuilder(builder: (ctx, constraints) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: options.map((opt) {
                  final isActive = mode == opt.mode;
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setMode(opt.mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              opt.icon,
                              size: 16,
                              color: isActive
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isActive
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ThemeOption {
  const _ThemeOption(this.mode, this.label, this.icon);
  final ThemeMode mode;
  final String label;
  final IconData icon;
}

class _ExportOption extends StatelessWidget {
  const _ExportOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              Icon(Icons.download_outlined,
                  size: 18, color: context.palette.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
