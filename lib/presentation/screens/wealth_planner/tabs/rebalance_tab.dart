import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../sub/rebal_actions_tab.dart';
import '../sub/rebal_dismissed_tab.dart';

class RebalanceTab extends StatefulWidget {
  const RebalanceTab({super.key});

  @override
  State<RebalanceTab> createState() => _RebalanceTabState();
}

class _RebalanceTabState extends State<RebalanceTab>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _controller,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.palette.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Actions'),
            Tab(text: 'Dismissed'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: const [
              RebalActionsTab(),
              RebalDismissedTab(),
            ],
          ),
        ),
      ],
    );
  }
}
