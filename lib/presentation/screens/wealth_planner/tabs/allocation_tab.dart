import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../sub/alloc_bucket_tab.dart';
import '../sub/alloc_fund_tab.dart';

/// Host for the 2 allocation sub-tabs. Target-setting for each asset class
/// now lives inside [AllocFundTab] (class-level slider + per-fund sliders),
/// so the legacy Asset sub-tab was retired.
class AllocationTab extends ConsumerStatefulWidget {
  const AllocationTab({super.key});

  @override
  ConsumerState<AllocationTab> createState() => _AllocationTabState();
}

class _AllocationTabState extends ConsumerState<AllocationTab>
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
            Tab(text: 'Fund'),
            Tab(text: 'Bucket'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: const [
              AllocFundTab(),
              AllocBucketTab(),
            ],
          ),
        ),
      ],
    );
  }
}
