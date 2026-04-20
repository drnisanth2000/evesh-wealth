import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/watchlist/rule_card.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    (label: 'All', ruleType: null),
    (label: 'Stop-Loss', ruleType: 'stop_loss'),
    (label: 'Gain Harvest', ruleType: 'gain_harvest'),
    (label: 'Price Target', ruleType: 'price_target'),
    (label: 'Drift', ruleType: 'allocation_drift'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(watchlistRulesProvider);
    ref.invalidate(watchlistNavMapProvider);
    await ref.read(watchlistRulesProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(watchlistRulesProvider);
    final navMapAsync = ref.watch(watchlistNavMapProvider);
    final tabIndex = _tabController.index;
    final selectedRuleType = _tabs[tabIndex].ruleType;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Rule',
            onPressed: () => context.push('/wealth-planner/watchlist/add'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.palette.textSecondary,
          tabs: _tabs
              .map((t) => Tab(text: t.label))
              .toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: rulesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            message: e.toString(),
            onRetry: () {
              ref.invalidate(watchlistRulesProvider);
              ref.invalidate(watchlistNavMapProvider);
            },
          ),
          data: (allRules) {
            final navMap = navMapAsync.valueOrNull ?? {};
            final rules = selectedRuleType == null
                ? allRules
                : allRules.where((r) => r.ruleType == selectedRuleType).toList();

            if (rules.isEmpty) {
              return _EmptyState(
                onAdd: () => context.push('/wealth-planner/watchlist/add'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final rule = rules[index];
                final currentNav = rule.amfiCode != null
                    ? navMap[rule.amfiCode!]
                    : null;

                return RuleCard(
                  rule: rule,
                  currentNav: currentNav,
                  onTap: () {
                    // Detail/edit sheet — will be added in a later task
                  },
                  onDelete: () async {
                    await ref
                        .read(watchlistNotifierProvider.notifier)
                        .deleteRule(rule.id, amfiCode: rule.amfiCode);
                  },
                  onToggle: (isActive) async {
                    await ref
                        .read(watchlistNotifierProvider.notifier)
                        .toggleActive(rule.id, isActive);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_off_outlined,
            size: 64,
            color: context.palette.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No watchlist rules yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track NAV targets, stop-losses and allocation drift',
            style: TextStyle(
              fontSize: 13,
              color: context.palette.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add your first rule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.loss, size: 48),
            const SizedBox(height: 12),
            Text(
              'Error loading watchlist',
              style: TextStyle(color: context.palette.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                  color: context.palette.textTertiary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
