import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../wealth_planner/sub/mf_buy_tab.dart';
import '../wealth_planner/sub/mf_order_status_tab.dart';
import 'transaction_list_screen.dart';

/// Host for the bottom-nav "Transactions" section. Wraps the legacy
/// [TransactionListScreen] with two extra sub-tabs that moved in from the
/// retired "My Mutual Funds" top tab:
///   • Transactions — the existing ledger (passes through [initialSearch])
///   • Buy — place SIP / Lumpsum / Switch / SWP / Sell / Gift orders
///   • Order Status — pending_orders list with status filters
///
/// All three sub-tabs share the global member chip up-chain (Dashboard
/// shell + per-screen member selector for Transactions).
class TransactionsHostScreen extends ConsumerStatefulWidget {
  const TransactionsHostScreen({super.key, this.initialSearch});

  final String? initialSearch;

  @override
  ConsumerState<TransactionsHostScreen> createState() =>
      _TransactionsHostScreenState();
}

class _TransactionsHostScreenState extends ConsumerState<TransactionsHostScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NOT a Scaffold here: the inner [TransactionListScreen] owns its own
    // Scaffold + AppBar + FAB, and the MainShell supplies the outer
    // bottom-nav Scaffold. Wrapping in another Scaffold would stack three
    // levels and duplicate backgrounds.
    return Column(
      children: [
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _controller,
            labelColor: AppColors.primary,
            unselectedLabelColor: context.palette.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Transactions'),
              Tab(text: 'Buy'),
              Tab(text: 'Order Status'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: [
              TransactionListScreen(initialSearch: widget.initialSearch),
              const MfBuyTab(),
              const MfOrderStatusTab(),
            ],
          ),
        ),
      ],
    );
  }
}
