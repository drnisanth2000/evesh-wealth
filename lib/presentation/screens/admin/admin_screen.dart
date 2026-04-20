import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/admin_provider.dart';
import '../../providers/family_provider.dart';
import '../../widgets/common/kpi_card.dart';
import '../../widgets/common/section_header.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    // While the profile is resolving, show a spinner — don't fire the
    // admin metrics request (which the server would reject anyway for
    // non-admins) and don't flash the deny screen to real admins.
    if (profileAsync.isLoading || !profileAsync.hasValue) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Guard: non-admin sees access denied. The edge function also enforces
    // this server-side; this is defense-in-depth and prevents the UI from
    // even issuing the metrics request for non-admins.
    if (profileAsync.valueOrNull?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 56, color: context.palette.textTertiary),
              SizedBox(height: 12),
              Text('Admin access only',
                  style: TextStyle(
                      color: context.palette.textSecondary, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    // Safe to fetch metrics — role confirmed admin.
    final metricsAsync = ref.watch(adminMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminMetricsProvider),
          ),
        ],
      ),
      body: metricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.loss, size: 48),
              const SizedBox(height: 8),
              Text('Error: $e',
                  style: TextStyle(color: context.palette.textTertiary)),
            ],
          ),
        ),
        data: (m) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminMetricsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Last updated: ${DateFormat('dd MMM yyyy HH:mm').format(m.generatedAt)}',
                style: TextStyle(
                    fontSize: 11, color: context.palette.textTertiary),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),

              // ── Users ───────────────────────────────────────────────
              SectionHeader(title: 'Users'),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  KpiCard(
                      label: 'Total Users',
                      value: m.totalUsers.toString()),
                  KpiCard(label: 'DAU', value: m.dau.toString()),
                  KpiCard(label: 'WAU', value: m.wau.toString()),
                  KpiCard(label: 'MAU', value: m.mau.toString()),
                  KpiCard(
                      label: 'New This Week',
                      value: m.newUsersThisWeek.toString(),
                      valueColor: AppColors.gain),
                ],
              ),
              const SizedBox(height: 20),

              // ── Tier breakdown ──────────────────────────────────────
              SectionHeader(title: 'Subscription Tiers (Active)'),
              _TierBreakdown(tiers: m.tierBreakdown, total: m.totalUsers),
              const SizedBox(height: 20),

              // ── Revenue ─────────────────────────────────────────────
              SectionHeader(title: 'Revenue'),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  KpiCard(
                    label: 'MRR',
                    value: m.mrr.toINRCompact(),
                    valueColor: AppColors.gain,
                    tooltip: 'Monthly Recurring Revenue from active subscriptions',
                  ),
                  KpiCard(
                    label: 'ARR (est.)',
                    value: (m.mrr * 12).toINRCompact(),
                    valueColor: AppColors.gain,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Platform ─────────────────────────────────────────────
              SectionHeader(title: 'Platform'),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  KpiCard(
                      label: 'Total Transactions',
                      value: m.totalTransactions.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierBreakdown extends StatelessWidget {
  const _TierBreakdown({required this.tiers, required this.total});
  final Map<String, int> tiers;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = {
      'free': context.palette.textTertiary,
      'individual': AppColors.primary,
      'family': AppColors.gain,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.bgDivider),
      ),
      child: Column(
        children: ['free', 'individual', 'family'].map((tier) {
          final count = tiers[tier] ?? 0;
          final pct = total > 0 ? count / total : 0.0;
          final color = colors[tier] ?? context.palette.textTertiary;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      tier[0].toUpperCase() + tier.substring(1),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      '$count  (${(pct * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: context.palette.bgDivider,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
