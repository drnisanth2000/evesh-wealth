import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screener_tab.dart';
import 'compare_tab.dart';
import 'decision_matrix_tab.dart';

class MFScreenerScreen extends ConsumerStatefulWidget {
  const MFScreenerScreen({super.key});

  @override
  ConsumerState<MFScreenerScreen> createState() => _MFScreenerScreenState();
}

class _MFScreenerScreenState extends ConsumerState<MFScreenerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Research'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Screener'),
            Tab(text: 'Compare'),
            Tab(text: 'Matrix'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ScreenerTab(),
          CompareTab(),
          DecisionMatrixTab(),
        ],
      ),
    );
  }
}
