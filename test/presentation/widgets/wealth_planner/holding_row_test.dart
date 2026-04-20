import 'package:evesh_wealth/data/models/portfolio_summary_model.dart';
import 'package:evesh_wealth/presentation/widgets/wealth_planner/holding_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _holding = FundHoldingSummary(
  amfiCode: 120503,
  fundName: 'HDFC Flexi Cap Fund',
  category: 'Core Equity',
  assetClassLabel: 'Core Equity',
  totalUnits: 1234.567,
  currentValue: 123456,
  nav1dChangePct: 0.75,
);

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('renders fund name, value, and 1d change', (tester) async {
    await tester.pumpWidget(_wrap(
      const HoldingRow(holding: _holding, showRebalanceCta: false),
    ));
    await tester.pumpAndSettle();

    expect(find.text('HDFC Flexi Cap Fund'), findsOneWidget);
    expect(find.textContaining('1234.567 units'), findsOneWidget);
    expect(find.textContaining('Core Equity'), findsOneWidget);
    expect(find.text('+0.75%'), findsOneWidget);
  });

  testWidgets(
      'popup menu shows Move always; Rebalance only when showRebalanceCta',
      (tester) async {
    // Without CTA.
    await tester.pumpWidget(_wrap(
      const HoldingRow(holding: _holding, showRebalanceCta: false),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Move to another asset class'), findsOneWidget);
    expect(find.text('Rebalance'), findsNothing);

    // Dismiss menu.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // With CTA.
    await tester.pumpWidget(_wrap(
      const HoldingRow(holding: _holding, showRebalanceCta: true),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Move to another asset class'), findsOneWidget);
    expect(find.text('Rebalance'), findsOneWidget);
  });
}
