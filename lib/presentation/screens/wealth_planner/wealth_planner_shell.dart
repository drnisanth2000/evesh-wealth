import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../widgets/wealth_planner/global_member_header.dart';
import '../goals/goal_landing_screen.dart';
import 'tabs/allocation_tab.dart';
import 'tabs/rebalance_tab.dart';

/// Top-level Wealth Planner shell. Hosts three primary tabs:
///   • Goals — goal-first unified view
///   • Asset Allocation — per-class + per-fund allocator (default)
///   • Rebalance
///
/// The retired "My Mutual Funds" tab's responsibilities now live inside
/// Asset Allocation → Fund: holdings grouped by class, slider-driven target
/// setting, Add Fund for new deployments. Execute Deployment on a pending
/// fund sub-card writes to `pending_orders` (what the old Order Status tab
/// listed).
class WealthPlannerShell extends ConsumerStatefulWidget {
  const WealthPlannerShell({super.key, this.initialTab = 1});

  /// 0 = Goals, 1 = Asset Allocation, 2 = Rebalance.
  final int initialTab;

  @override
  ConsumerState<WealthPlannerShell> createState() => _WealthPlannerShellState();
}

class _WealthPlannerShellState extends ConsumerState<WealthPlannerShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wealth Planner'),
      ),
      body: Column(
        children: [
          const GlobalMemberHeader(),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: context.palette.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Goals'),
              Tab(text: 'Asset Allocation'),
              Tab(text: 'Rebalance'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                GoalsView(showMemberSelector: false),
                AllocationTab(),
                RebalanceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
